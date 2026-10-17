<?php



namespace App\Http\Controllers\Api;



use App\Models\EmailChangeCode;

use App\Http\Controllers\Controller;

use App\Models\PasswordResetCode;

use App\Models\User;

use App\Models\CommentReaction;

use App\Models\ComplaintComment;

use App\Models\Complaint;

use Illuminate\Http\Request;

use Illuminate\Support\Facades\Hash;

use Illuminate\Support\Carbon;

use Illuminate\Support\Facades\DB;

use Illuminate\Support\Facades\Mail;

use Illuminate\Validation\ValidationException;

use Illuminate\Support\Facades\Storage;





class AuthController extends Controller

{

    private function normalizePhone(?string $phone): ?string

    {

        if ($phone === null || trim($phone) === '') {

            return null;

        }



        $phone = preg_replace('/\D+/', '', $phone);



        // +90 555 123 45 67 -> 5551234567

        if (

            strlen($phone) === 12 &&

            str_starts_with($phone, '90')

        ) {

            $phone = substr($phone, 2);

        }



        // 0555 123 45 67 -> 5551234567

        if (

            strlen($phone) === 11 &&

            str_starts_with($phone, '0')

        ) {

            $phone = substr($phone, 1);

        }



        return $phone;

    }



    private function findUserByIdentifier(

        string $identifier

    ): ?User {

        $identifier = trim($identifier);



        if (

            filter_var(

                $identifier,

                FILTER_VALIDATE_EMAIL

            )

        ) {

            return User::where(

                'email',

                strtolower($identifier)

            )->first();

        }



        $phone = $this->normalizePhone(

            $identifier

        );



        return User::where(

            'phone',

            $phone

        )->first();

    }



    public function register(Request $request)

    {

        if ($request->filled('phone')) {

            $request->merge([

                'phone' => $this->normalizePhone(

                    $request->input('phone')

                ),

            ]);

        }



        if ($request->filled('email')) {

            $request->merge([

                'email' => strtolower(

                    trim($request->input('email'))

                ),

            ]);

        }



        $validated = $request->validate([

            'name' =>

                'required|string|max:255',



            'email' =>

                'nullable|required_without:phone|email|max:255|unique:users,email',



            'phone' =>

                [

                    'nullable',

                    'required_without:email',

                    'regex:/^5[0-9]{9}$/',

                    'unique:users,phone',

                ],



            'password' =>

                'required|string|min:6',

        ]);



        $user = User::create([

            'name' => $validated['name'],



            'email' =>

                $validated['email'] ?? null,



            'phone' =>

                $validated['phone'] ?? null,



            'password' => Hash::make(

                $validated['password']

            ),

        ]);



        $token = $user

            ->createToken('flutter-token')

            ->plainTextToken;



        return response()->json([

            'success' => true,

            'message' =>

                'Kullanıcı başarıyla oluşturuldu.',

            'token' => $token,

            'user' => $user,

        ], 201);

    }



    public function login(Request $request)

{

    $validated = $request->validate([

        'identifier' => 'required|string',

        'password' => 'required|string',

    ]);



    $user = $this->findUserByIdentifier(

        $validated['identifier']

    );



    if (!$user) {

        throw ValidationException::withMessages([

            'identifier' => [

                'E-posta/telefon veya şifre hatalı.',

            ],

        ]);

    }



    if ($user->must_reset_password) {

        return response()->json([

            'success' => false,

            'must_reset_password' => true,

            'message' =>

                'Güvenlik nedeniyle şifrenizi yenilemeniz gerekiyor.',

        ], 423);

    }



    if (

        !Hash::check(

            $validated['password'],

            $user->password

        )

    ) {

        $user->failed_login_attempts =

            $user->failed_login_attempts + 1;



        if ($user->failed_login_attempts >= 3) {

            $user->must_reset_password = true;

        }



        $user->save();



        if ($user->must_reset_password) {

            return response()->json([

                'success' => false,

                'must_reset_password' => true,

                'message' =>

                    '3 kez hatalı şifre girdiniz. '

                    . 'Güvenlik nedeniyle şifrenizi '

                    . 'yenilemeniz gerekiyor.',

            ], 423);

        }



        $remaining =

            3 - $user->failed_login_attempts;



        return response()->json([

            'success' => false,

            'message' =>

                'E-posta/telefon veya şifre hatalı. '

                . "Kalan deneme: {$remaining}",

        ], 422);

    }



    // Hesap dondurulmuşsa doğru şifreyle girişte yeniden aktifleştir.
    // 90 günlük süre aşılmışsa girişe izin verme.
    $accountReactivated = false;

    if ($user->frozen_at) {
        $frozenAt = Carbon::parse(
            $user->frozen_at
        );

        if (
            $frozenAt->lte(
                now()->subDays(90)
            )
        ) {
            return response()->json([
                'success' => false,
                'message' =>
                    'Hesabınız 90 günlük dondurma süresini aştığı için artık kullanılamaz.',
            ], 410);
        }

        $user->frozen_at = null;
        $accountReactivated = true;
    }

    // Doğru şifre girildiyse sayaç sıfırlanır.

    $user->failed_login_attempts = 0;

    $user->must_reset_password = false;

    $user->save();



    $user->tokens()->delete();



    $token = $user

        ->createToken('flutter-token')

        ->plainTextToken;



    return response()->json([

        'success' => true,

        'message' => $accountReactivated
            ? 'Hesabınız yeniden aktifleştirildi. Giriş başarılı.'
            : 'Giriş başarılı.',

        'token' => $token,

        'user' => $user,

    ]);

}



    public function me(Request $request)

    {

        return response()->json([

            'success' => true,

            'user' => $request->user(),

        ]);

    }



    public function logout(Request $request)

    {

        $request->user()

            ->currentAccessToken()

            ?->delete();



        return response()->json([

            'success' => true,

            'message' => 'Çıkış yapıldı.',

        ]);

    }



    public function changePassword(Request $request)

{

    $validated = $request->validate([

        'current_password' => 'required|string',

        'password' => 'required|string|min:6|confirmed',

    ]);



    $user = $request->user();



    if (!Hash::check(

        $validated['current_password'],

        $user->password

    )) {

        return response()->json([

            'success' => false,

            'message' => 'Mevcut şifreniz yanlış.',

        ], 422);

    }



    if (Hash::check(

        $validated['password'],

        $user->password

    )) {

        return response()->json([

            'success' => false,

            'message' =>

                'Yeni şifre mevcut şifrenizle aynı olamaz.',

        ], 422);

    }



    $user->update([

        'password' => Hash::make(

            $validated['password']

        ),

    ]);



    return response()->json([

        'success' => true,

        'message' =>

            'Şifreniz başarıyla değiştirildi.',

    ]);

}



    public function requestResetCode(

        Request $request

    ) {

        $validated = $request->validate([

            'identifier' =>

                'required|string',

        ]);



        $identifier =

            $validated['identifier'];



        $user =

            $this->findUserByIdentifier(

                $identifier

            );



        if (!$user) {

            throw ValidationException::withMessages([

                'identifier' => [

                    'Bu bilgilerle kayıtlı kullanıcı bulunamadı.',

                ],

            ]);

        }



        $isEmail = filter_var(

            trim($identifier),

            FILTER_VALIDATE_EMAIL

        );



        $channel =

            $isEmail ? 'email' : 'phone';



        /*

         * Telefon SMS gönderimi için gerçek

         * SMS sağlayıcısını sonraki adımda

         * bağlayacağız.

         */

        if ($channel === 'phone') {

            return response()->json([

                'success' => false,

                'message' =>

                    'Telefon ile SMS gönderimi için SMS servisi henüz yapılandırılmadı.',

            ], 501);

        }



        $code = (string) random_int(

            100000,

            999999

        );



        // Eski kullanılmamış kodları iptal et.

        PasswordResetCode::where(

            'user_id',

            $user->id

        )

            ->whereNull('used_at')

            ->delete();



        $resetCode =

            PasswordResetCode::create([

                'user_id' => $user->id,

                'channel' => $channel,

                'code_hash' =>

                    Hash::make($code),

                'expires_at' =>

                    now()->addMinutes(10),

                'attempt_count' => 0,

            ]);



        try {

            Mail::raw(

                "Şifre sıfırlama kodunuz: {$code}\n\n"

                . 'Bu kod 10 dakika geçerlidir.',

                function ($message) use ($user) {

                    $message

                        ->to($user->email)

                        ->subject(

                            'Şifre Sıfırlama Kodu'

                        );

                }

            );

        } catch (\Throwable $e) {

    report($e);



    $resetCode->delete();



    return response()->json([

        'success' => false,

        'message' =>

            'Doğrulama kodu e-posta ile gönderilemedi. Mail ayarlarını kontrol edin.',

    ], 500);

}



        return response()->json([

            'success' => true,

            'message' =>

                '6 haneli doğrulama kodu gönderildi.',

        ]);

    }



    public function resetPassword(

        Request $request

    ) {

        $validated = $request->validate([

            'identifier' =>

                'required|string',



            'code' =>

                'required|digits:6',



            'password' =>

                'required|string|min:6|confirmed',

        ]);



        $user =

            $this->findUserByIdentifier(

                $validated['identifier']

            );



        if (!$user) {

            throw ValidationException::withMessages([

                'identifier' => [

                    'Kullanıcı bulunamadı.',

                ],

            ]);

        }



        $resetCode =

            PasswordResetCode::where(

                'user_id',

                $user->id

            )

                ->whereNull('used_at')

                ->where(

                    'expires_at',

                    '>',

                    now()

                )

                ->latest()

                ->first();



        if (!$resetCode) {

            throw ValidationException::withMessages([

                'code' => [

                    'Kod geçersiz veya süresi dolmuş.',

                ],

            ]);

        }



        if (

            $resetCode->attempt_count >= 5

        ) {

            throw ValidationException::withMessages([

                'code' => [

                    'Çok fazla hatalı deneme yapıldı. Yeni kod isteyin.',

                ],

            ]);

        }



        if (

            !Hash::check(

                $validated['code'],

                $resetCode->code_hash

            )

        ) {

            $resetCode->increment(

                'attempt_count'

            );



            throw ValidationException::withMessages([

                'code' => [

                    'Doğrulama kodu hatalı.',

                ],

            ]);

        }



       $user->password = Hash::make(

    $validated['password']

);



$user->failed_login_attempts = 0;

$user->must_reset_password = false;



$user->save();



        $resetCode->update([

            'used_at' => now(),

        ]);



        // Eski oturumları kapat.

        $user->tokens()->delete();



        return response()->json([

            'success' => true,

            'message' =>

                'Şifreniz başarıyla yenilendi.',

        ]);

    }



    public function updateProfile(Request $request)

{

    $validated = $request->validate([

        'name' => 'required|string|min:2|max:255',

    ]);



    $user = $request->user();



    $user->update([

        'name' => trim($validated['name']),

    ]);



    return response()->json([

        'success' => true,

        'message' => 'Profil bilgileri güncellendi.',

        'user' => $user->fresh(),

    ]);

  }



  public function requestEmailChangeCode(Request $request)

{

    $validated = $request->validate([

        'email' => 'required|email|max:255|unique:users,email',

        'current_password' => 'required|string',

    ]);



    $user = $request->user();



    if (!Hash::check(

        $validated['current_password'],

        $user->password

    )) {

        return response()->json([

            'success' => false,

            'message' => 'Mevcut şifreniz yanlış.',

        ], 422);

    }



    $newEmail = strtolower(

        trim($validated['email'])

    );



    $code = (string) random_int(

        100000,

        999999

    );



    EmailChangeCode::where(

        'user_id',

        $user->id

    )->delete();



    $emailChangeCode =

        EmailChangeCode::create([

            'user_id' => $user->id,

            'new_email' => $newEmail,

            'code_hash' => Hash::make($code),

            'expires_at' => now()->addMinutes(10),

            'attempt_count' => 0,

        ]);



    try {

        Mail::raw(

            "E-posta değiştirme doğrulama kodunuz: {$code}\n\n"

            . 'Bu kod 10 dakika geçerlidir.',

            function ($message) use ($newEmail) {

                $message

                    ->to($newEmail)

                    ->subject(

                        'E-posta Değiştirme Kodu'

                    );

            }

        );

    } catch (\Throwable $e) {

        report($e);



        $emailChangeCode->delete();



        return response()->json([

            'success' => false,

            'message' =>

                'Doğrulama kodu gönderilemedi.',

        ], 500);

    }



    return response()->json([

        'success' => true,

        'message' =>

            'Yeni e-posta adresinize 6 haneli kod gönderildi.',

    ]);

}



public function confirmEmailChange(Request $request)

{

    $validated = $request->validate([

        'code' => 'required|digits:6',

    ]);



    $user = $request->user();



    $emailChangeCode =

        EmailChangeCode::where(

            'user_id',

            $user->id

        )

            ->where(

                'expires_at',

                '>',

                now()

            )

            ->latest()

            ->first();



    if (!$emailChangeCode) {

        return response()->json([

            'success' => false,

            'message' =>

                'Kod geçersiz veya süresi dolmuş.',

        ], 422);

    }



    if (

        $emailChangeCode->attempt_count >= 5

    ) {

        $emailChangeCode->delete();



        return response()->json([

            'success' => false,

            'message' =>

                'Çok fazla hatalı deneme yapıldı. Yeni kod isteyin.',

        ], 422);

    }



    if (

        !Hash::check(

            $validated['code'],

            $emailChangeCode->code_hash

        )

    ) {

        $emailChangeCode->increment(

            'attempt_count'

        );



        return response()->json([

            'success' => false,

            'message' =>

                'Doğrulama kodu hatalı.',

        ], 422);

    }



    $emailAlreadyUsed =

        User::where(

            'email',

            $emailChangeCode->new_email

        )

            ->where(

                'id',

                '!=',

                $user->id

            )

            ->exists();



    if ($emailAlreadyUsed) {

        $emailChangeCode->delete();



        return response()->json([

            'success' => false,

            'message' =>

                'Bu e-posta adresi başka bir hesap tarafından kullanılıyor.',

        ], 422);

    }



    $user->update([

        'email' =>

            $emailChangeCode->new_email,

    ]);



    $emailChangeCode->delete();



    return response()->json([

        'success' => true,

        'message' =>

            'E-posta adresiniz başarıyla değiştirildi.',

        'user' => $user->fresh(),

    ]);

}





  public function updateProfilePhoto(Request $request)

{

    $request->validate([

        'photo' => [

            'required',

            'image',

            'mimes:jpg,jpeg,png,webp',

            'max:2048',

        ],

    ]);



    $user = $request->user();



    if ($user->profile_photo_path) {

        Storage::disk('public')->delete(

            $user->profile_photo_path

        );

    }



    $path = $request

        ->file('photo')

        ->store(

            'profile_photos',

            'public'

        );



    $user->profile_photo_path = $path;

    $user->save();



    return response()->json([

        'success' => true,

        'message' =>

            'Profil fotoğrafı başarıyla güncellendi.',

        'user' => $user->fresh(),

    ]);

}



public function deleteProfilePhoto(Request $request)

{

    $user = $request->user();



    if ($user->profile_photo_path) {

        Storage::disk('public')->delete(

            $user->profile_photo_path

        );

    }



    $user->profile_photo_path = null;

    $user->save();



    return response()->json([

        'success' => true,

        'message' =>

            'Profil fotoğrafı başarıyla silindi.',

        'user' => $user->fresh(),

    ]);

}


    // Giriş yapan kullanıcının hesabını dondurur.
    public function freezeAccount(Request $request)
    {
        $validated = $request->validate([
            'password' => 'required|string',
        ]);

        $user = $request->user();

        if (
            !Hash::check(
                $validated['password'],
                $user->password
            )
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Şifreniz yanlış.',
            ], 422);
        }

        $user->frozen_at = now();
        $user->save();

        // Dondurulan hesabın açık oturumlarını kapat.
        $user->tokens()->delete();

        return response()->json([
            'success' => true,
            'message' =>
                'Hesabınız donduruldu. 90 gün içinde tekrar giriş yaparsanız hesabınız yeniden aktifleştirilir.',
        ]);
    }

    // Giriş yapan kullanıcının hesabını ve kullanıcıya bağlı verileri tamamen siler.
    
public function deleteAccount(Request $request)
{
    $validated = $request->validate([
        'password' => 'required|string',
    ]);

    $user = $request->user();

    if (
        !Hash::check(
            $validated['password'],
            $user->password
        )
    ) {
        return response()->json([
            'success' => false,
            'message' => 'Şifreniz yanlış.',
        ], 422);
    }

    // Hesabı ve bağlı verileri ortak servis üzerinden sil.
    app(\App\Services\AccountDeletionService::class)
        ->delete($user);

    return response()->json([
        'success' => true,
        'message' =>
            'Hesabınız ve hesabınıza bağlı veriler tamamen silindi.',
    ]);
}

        
}
