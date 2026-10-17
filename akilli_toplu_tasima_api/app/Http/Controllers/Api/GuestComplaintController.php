<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Validation\ValidationException;

class GuestComplaintController extends ComplaintController
{
    // 05XXXXXXXXX, 5XXXXXXXXX, 905XXXXXXXXX ve +905XXXXXXXXX kabul edilir.
    private function normalizePhone(string $raw): ?string
    {
        $digits = preg_replace('/\D+/', '', $raw);
        if (preg_match('/^05\d{9}$/', $digits)) {
            $digits = '9' . $digits;
        } elseif (preg_match('/^5\d{9}$/', $digits)) {
            $digits = '90' . $digits;
        }
        return preg_match('/^905\d{9}$/', $digits) ? $digits : null;
    }

    private function contact(Request $request): array
    {
        $data = $request->validate([
            'email' => 'nullable|required_without:phone|string|email|max:255|missing_with:phone',
            'phone' => 'nullable|required_without:email|string|max:30|missing_with:email',
        ]);
        if (!empty($data['email'])) {
            return ['email', strtolower(trim($data['email']))];
        }
        $phone = $this->normalizePhone($data['phone'] ?? '');
        if ($phone === null) {
            throw ValidationException::withMessages([
                'phone' => ['Geçerli bir Türkiye cep telefonu numarası girin (05XXXXXXXXX).'],
            ]);
        }
        return ['phone', $phone];
    }

    public function requestCode(Request $request)
    {
        [$kind, $contact] = $this->contact($request);

        // SMS servisi henüz bağlı değil. Yerel ortam dışındaki telefon isteğini reddet.
        if ($kind === 'phone' && !app()->environment('local')) {
            return response()->json([
                'success' => false,
                'message' => 'Telefon doğrulaması henüz kullanıma açık değil.',
            ], 503);
        }

        $ipKey = 'guest-otp-ip:' . hash('sha256', (string) $request->ip());
        $contactKey = 'guest-otp-contact:' . hash('sha256', $kind . ':' . $contact);
        if (RateLimiter::tooManyAttempts($ipKey, 10) || RateLimiter::tooManyAttempts($contactKey, 3)) {
            return response()->json([
                'success' => false,
                'message' => 'Çok fazla kod istendi. Lütfen 15 dakika sonra tekrar deneyin.',
            ], 429);
        }
        RateLimiter::hit($ipKey, 900);
        RateLimiter::hit($contactKey, 900);

        $code = (string) random_int(100000, 999999);
        $id = DB::table('guest_complaint_verifications')->insertGetId([
            'email' => $kind === 'email' ? $contact : null,
            'phone' => $kind === 'phone' ? $contact : null,
            'code_hash' => Hash::make($code),
            'attempts' => 0,
            'expires_at' => now()->addMinutes(10),
            'verified_at' => null,
            'used_at' => null,
            'token_hash' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        if ($kind === 'phone') {
            // Yalnızca geliştirme amaçlı. Gerçek SMS GÖNDERİLMEZ.
            Log::info('YEREL TEST - Misafir telefon doğrulama kodu', [
                'phone' => $contact,
                'code' => $code,
            ]);
            return response()->json([
                'success' => true,
                'message' => 'Yerel test kodu Laravel log dosyasına yazıldı; SMS gönderilmedi.',
            ]);
        }

        try {
            Mail::raw(
                "Akıllı Toplu Taşıma Platformu misafir şikayet doğrulama kodunuz: {$code}\n\n"
                . 'Kod 10 dakika geçerlidir. Bu işlemi siz başlatmadıysanız e-postayı dikkate almayın.',
                function ($message) use ($contact) {
                    $message->to($contact)->subject('Misafir Şikayet Doğrulama Kodu');
                }
            );
        } catch (\Throwable $e) {
            DB::table('guest_complaint_verifications')->where('id', $id)->delete();
            report($e);
            return response()->json([
                'success' => false,
                'message' => 'Doğrulama e-postası gönderilemedi. Daha sonra tekrar deneyin.',
            ], 503);
        }

        return response()->json([
            'success' => true,
            'message' => 'Doğrulama kodu e-posta adresinize gönderildi.',
        ]);
    }

    public function verifyCode(Request $request)
    {
        [$kind, $contact] = $this->contact($request);
        $validated = $request->validate([
            'code' => ['required', 'string', 'regex:/^[0-9]{6}$/'],
        ]);

        $result = DB::transaction(function () use ($kind, $contact, $validated) {
            $record = DB::table('guest_complaint_verifications')
                ->where($kind, $contact)
                ->orderByDesc('id')
                ->lockForUpdate()
                ->first();

            if (!$record || $record->used_at !== null || $record->verified_at !== null || Carbon::parse($record->expires_at)->isPast()) {
                return ['error' => 'Kod bulunamadı veya süresi doldu. Yeni kod isteyin.'];
            }
            if ((int) $record->attempts >= 5) {
                return ['error' => 'Çok fazla yanlış deneme. Yeni kod isteyin.'];
            }
            DB::table('guest_complaint_verifications')
                ->where('id', $record->id)
                ->increment('attempts');
            if (!Hash::check($validated['code'], $record->code_hash)) {
                return ['error' => 'Doğrulama kodu hatalı.'];
            }

            $token = bin2hex(random_bytes(32));
            DB::table('guest_complaint_verifications')
                ->where('id', $record->id)
                ->update([
                    'verified_at' => now(),
                    'token_hash' => hash('sha256', $token),
                    'expires_at' => now()->addMinutes(20),
                    'updated_at' => now(),
                ]);
            return ['token' => $token];
        });

        if (isset($result['error'])) {
            return response()->json(['success' => false, 'message' => $result['error']], 422);
        }
        return response()->json([
            'success' => true,
            'message' => 'Doğrulama başarılı. Şikayetinizi gönderebilirsiniz.',
            'verification_token' => $result['token'],
            'expires_in_seconds' => 1200,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'verification_token' => 'required|string|size:64',
        ]);
        $tokenHash = hash('sha256', $validated['verification_token']);

        return DB::transaction(function () use ($request, $tokenHash) {
            $record = DB::table('guest_complaint_verifications')
                ->where('token_hash', $tokenHash)
                ->whereNotNull('verified_at')
                ->whereNull('used_at')
                ->lockForUpdate()
                ->first();

            if (!$record || Carbon::parse($record->expires_at)->isPast()) {
                throw ValidationException::withMessages([
                    'verification_token' => ['Doğrulama süresi dolmuş veya kod daha önce kullanılmış. Yeniden doğrulayın.'],
                ]);
            }

            if ($record->phone !== null && !app()->environment('local')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Test telefon doğrulaması gerçek ortamda kullanılamaz.',
                ], 403);
            }

            $response = $this->createComplaint($request, null, $record->email, $record->phone);
            if ($response->getStatusCode() === 201) {
                DB::table('guest_complaint_verifications')
                    ->where('id', $record->id)
                    ->update(['used_at' => now(), 'updated_at' => now()]);
            }
            return $response;
        });
    }
}
