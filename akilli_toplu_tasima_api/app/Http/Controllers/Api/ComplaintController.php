<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Complaint;
use App\Models\Line;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class ComplaintController extends Controller
{
    // Kullanıcı yalnızca kendisine ait şikayeti silebilir.
    public function destroy(Request $request, Complaint $complaint)
    {
        if ((int) $complaint->user_id !== (int) $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Bu şikayeti silme yetkiniz yok.',
            ], 403);
        }

        $mediaPath = $complaint->media_path;
        $complaint->delete();

        if (is_string($mediaPath) && str_starts_with($mediaPath, 'complaints/')) {
            Storage::disk('public')->delete($mediaPath);
        }

        return response()->json([
            'success' => true,
            'message' => 'Şikayet başarıyla silindi.',
        ]);
    }

    
public function index()
{
    $complaints = Complaint::with([
        'line',
        'stop',
        'user:id,name',
    ])
        ->latest()
        ->get();

    $data = $complaints->map(function (Complaint $complaint) {
        $item = $complaint->toArray();

        if ($complaint->user_id === null) {
            $item['user_display_name'] = 'Misafir Kullanıcı';
        } else {
            $item['user_display_name'] =
                $complaint->user?->name ?? 'Silinmiş Kullanıcı';
        }

        // Kişisel iletişim bilgilerini topluluğa göndermiyoruz.
        unset(
            $item['user'],
            $item['guest_email'],
            $item['guest_phone'],
            $item['guest_email_verified_at'],
            $item['guest_phone_verified_at']
        );

        return $item;
    });

    return response()->json([
        'success' => true,
        'data' => $data,
    ]);
}


    public function myComplaints(Request $request)
    {
        $complaints = Complaint::with(['line', 'stop'])
            ->where('user_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $complaints,
        ]);
    }

    // Giriş yapan kullanıcı için mevcut şikayet oluşturma adresi.
    public function store(Request $request)
    {
        return $this->createComplaint($request, (int) $request->user()->id);
    }

    // Hem kayıtlı kullanıcı hem e-posta doğrulamış misafir için ortak kayıt işlemi.
    // Misafir çağrısında userId null, guestEmail doğrulanmış e-posta olur.
    protected function createComplaint(
        Request $request,
        ?int $userId,
        ?string $guestEmail = null,
        ?string $guestPhone = null
    ) {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'category' => 'required|string|max:100',
            'description' => 'required|string|min:10',
            'line_id' => 'required|integer|exists:lines,id',
            'stop_id' => 'nullable|integer|exists:stops,id',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'media' => 'nullable|file|mimes:jpg,jpeg,png,webp,heic,heif,mp4,mov,3gp|max:51200',
        ]);

        $title = $this->formatTitle($validated['title']);
        $description = trim($validated['description']);

        if (
            $this->containsForbiddenLanguage($title) ||
            $this->containsForbiddenLanguage($description)
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Şikayet metninde uygun olmayan ifadeler bulunmaktadır. Lütfen metni düzenleyiniz.',
            ], 422);
        }

        $line = Line::findOrFail($validated['line_id']);
        if (!empty($validated['stop_id'])) {
            $stopBelongsToLine = $line->stops()
                ->where('stops.id', $validated['stop_id'])
                ->exists();

            if (!$stopBelongsToLine) {
                throw ValidationException::withMessages([
                    'stop_id' => ['Seçilen durak, seçilen hatta ait değildir.'],
                ]);
            }
        }

        $mediaPath = null;
        $mediaType = null;
        if ($request->hasFile('media')) {
            $file = $request->file('media');
            $mediaType = str_starts_with((string) $file->getMimeType(), 'video/')
                ? 'video'
                : 'photo';

            $mediaPath = $file->store('complaints', 'public');
            if (!$mediaPath) {
                throw ValidationException::withMessages([
                    'media' => ['Medya dosyası yüklenemedi. Lütfen tekrar deneyin.'],
                ]);
            }
        }

        try {
            $complaint = new Complaint();
            $complaint->fill([
                'user_id' => $userId,
                'title' => $title,
                'category' => $validated['category'],
                'description' => $description,
                'line_id' => $validated['line_id'],
                'stop_id' => $validated['stop_id'] ?? null,
                'latitude' => $validated['latitude'] ?? null,
                'longitude' => $validated['longitude'] ?? null,
                'status' => 'Beklemede',
            ]);
            // Model fillable alanlarına güvenmeden misafir bilgilerini açıkça ata.
            $complaint->user_id = $userId;
            $complaint->guest_email = $guestEmail;
            $complaint->guest_email_verified_at = $guestEmail !== null ? now() : null;
            $complaint->guest_phone = $guestPhone;
            $complaint->guest_phone_verified_at = $guestPhone !== null ? now() : null;
            $complaint->media_path = $mediaPath;
            $complaint->media_type = $mediaType;
            $complaint->save();
        } catch (\Throwable $e) {
            if ($mediaPath) {
                Storage::disk('public')->delete($mediaPath);
            }
            throw $e;
        }

        $complaint->load(['line', 'stop']);

        return response()->json([
            'success' => true,
            'message' => 'Şikayet başarıyla oluşturuldu.',
            'data' => $complaint,
        ], 201);
    }

    public function show(Complaint $complaint)
    {
        $complaint->load(['line', 'stop']);
        return response()->json([
            'success' => true,
            'data' => $complaint,
        ]);
    }

    public function updateStatus(Request $request, Complaint $complaint)
    {
        $validated = $request->validate([
            'status' => 'required|in:Beklemede,İnceleniyor,Çözüldü',
        ]);

        $complaint->update([
            'status' => $validated['status'],
        ]);
        $complaint->load(['line', 'stop']);

        return response()->json([
            'success' => true,
            'message' => 'Şikayet durumu güncellendi.',
            'data' => $complaint,
        ]);
    }

    private function normalizeText(string $text): string
    {
        $text = mb_strtolower($text, 'UTF-8');
        $text = str_replace(
            ['ç', 'ğ', 'ı', 'ö', 'ş', 'ü'],
            ['c', 'g', 'i', 'o', 's', 'u'],
            $text
        );
        $text = preg_replace('/[^a-z0-9\s]/u', ' ', $text);
        $text = preg_replace('/\s+/u', ' ', $text);
        return trim($text);
    }

    private function containsForbiddenLanguage(string $text): bool
    {
        $normalizedText = $this->normalizeText($text);
        $searchableText = ' ' . $normalizedText . ' ';

        foreach (config('profanity.words', []) as $forbiddenWord) {
            $normalizedForbidden = $this->normalizeText($forbiddenWord);
            if ($normalizedForbidden === '') {
                continue;
            }
            if (str_contains($searchableText, ' ' . $normalizedForbidden . ' ')) {
                return true;
            }
        }
        return false;
    }

    private function formatTitle(string $title): string
    {
        $title = trim($title);
        if ($title === '') {
            return $title;
        }

        return preg_replace_callback(
            '/\p{L}/u',
            function ($matches) {
                $firstLetter = $matches[0];
                $turkishUppercase = [
                    'i' => 'İ',
                    'ı' => 'I',
                    'ş' => 'Ş',
                    'ğ' => 'Ğ',
                    'ü' => 'Ü',
                    'ö' => 'Ö',
                    'ç' => 'Ç',
                ];
                return $turkishUppercase[$firstLetter]
                    ?? mb_strtoupper($firstLetter, 'UTF-8');
            },
            $title,
            1
        );
    }
}
