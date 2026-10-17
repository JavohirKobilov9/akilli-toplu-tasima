<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CommentController;
use App\Http\Controllers\Api\ComplaintController;
use App\Http\Controllers\Api\LineController;
use App\Http\Controllers\Api\SuperAdminController;
use App\Http\Controllers\Api\AdminComplaintController;
use App\Http\Controllers\Api\GuestComplaintController;

// ----------------------------------------------------
// AUTH - Giriş gerektirmeyen işlemler
// ----------------------------------------------------

Route::post('/register', [
    AuthController::class,
    'register'
]);

Route::post('/login', [
    AuthController::class,
    'login'
]);

Route::post(
    '/forgot-password/request-code',
    [
        AuthController::class,
        'requestResetCode'
    ]
);

Route::post(
    '/forgot-password/reset',
    [
        AuthController::class,
        'resetPassword'
    ]
);

// ----------------------------------------------------
// MİSAFİR - Yalnızca e-posta doğrulamasıyla şikayet
// Bu işlemler için kullanıcı hesabı / oturum gerekmez.
// ----------------------------------------------------
Route::post('/guest/complaints/request-code', [
    GuestComplaintController::class, 'requestCode'
])->middleware('throttle:5,1');

Route::post('/guest/complaints/verify-code', [
    GuestComplaintController::class, 'verifyCode'
])->middleware('throttle:10,1');

Route::post('/guest/complaints', [
    GuestComplaintController::class, 'store'
])->middleware('throttle:5,1');

// ----------------------------------------------------
// ŞİKAYETLER - Herkesin görebildiği işlemler
// ----------------------------------------------------

Route::get('/complaints', [
    ComplaintController::class,
    'index'
]);

Route::get('/complaints/{complaint}', [
    ComplaintController::class,
    'show'
]);

// ----------------------------------------------------
// HATLAR / DURAKLAR / SEFERLER
// ----------------------------------------------------

Route::get('/lines', [
    LineController::class,
    'index'
]);

Route::get('/lines/{line}/stops', [
    LineController::class,
    'stops'
]);

Route::get('/lines/{line}/schedules', [
    LineController::class,
    'schedules'
]);

// ----------------------------------------------------
// GİRİŞ YAPMIŞ KULLANICI İŞLEMLERİ
// ----------------------------------------------------

Route::middleware('auth:sanctum')->group(function () {

    // Kullanıcı bilgisi
    Route::get('/me', [
        AuthController::class,
        'me'
    ]);

    // Çıkış
    Route::post('/logout', [
        AuthController::class,
        'logout'
    ]);

    // Hesabı dondur
    Route::post('/account/freeze', [
        AuthController::class,
        'freezeAccount'
    ]);

    // Hesabı tamamen sil
    Route::delete('/account', [
        AuthController::class,
        'deleteAccount'
    ]);

    // Profil bilgilerini güncelle
    Route::patch('/profile', [
        AuthController::class,
        'updateProfile'
    ]);

    // Profil fotoğrafını güncelle
    Route::post('/profile/photo', [
        AuthController::class,
        'updateProfilePhoto'
    ]);

    // Profil fotoğrafını sil
    Route::delete('/profile/photo', [
        AuthController::class,
        'deleteProfilePhoto'
    ]);

    // E-posta değiştirme kodu iste
    Route::post('/profile/email/request-code', [
        AuthController::class,
        'requestEmailChangeCode'
    ]);

    // E-posta değiştirmeyi onayla
    Route::post('/profile/email/confirm', [
        AuthController::class,
        'confirmEmailChange'
    ]);

    // Şifre değiştir
    Route::post('/change-password', [
        AuthController::class,
        'changePassword'
    ]);

    // Giriş yapan kullanıcının şikayetleri
    Route::get('/my-complaints', [
        ComplaintController::class,
        'myComplaints'
    ]);

    // Yeni şikayet oluştur
    Route::post('/complaints', [
        ComplaintController::class,
        'store'
    ]);

    // Kendi şikayetini sil
    Route::delete('/complaints/{complaint}', [
        ComplaintController::class,
        'destroy'
    ]);

    // Şikayetin yorumlarını getir
    Route::get(
        '/complaints/{complaint}/comments',
        [CommentController::class, 'index']
    );

    // Şikayete yorum ekle
    Route::post(
        '/complaints/{complaint}/comments',
        [CommentController::class, 'store']
    );

    // Yoruma Like / Dislike
    Route::post(
        '/comments/{comment}/reaction',
        [CommentController::class, 'react']
    );

    // Kendi yorumunu sil
    Route::delete(
        '/comments/{comment}',
        [CommentController::class, 'destroy']
    );

    // Yalnızca süper yöneticinin yardımcı adminleri listelemesi
    Route::get('/super-admin/admins', [
        SuperAdminController::class,
        'admins'
    ]);

    // Süper yönetici yeni yardımcı admin oluşturur.
    Route::post('/super-admin/admins', [
        SuperAdminController::class,
        'store'
    ]);

    // Süper yönetici yardımcı admin bilgilerini düzenler.
    Route::patch('/super-admin/admins/{admin}', [
        SuperAdminController::class,
        'update'
    ]);

    // Hesabı silmeden sadece admin yetkisini kaldırır.
    Route::patch('/super-admin/admins/{admin}/revoke', [
        SuperAdminController::class,
        'revoke'
    ]);

    // Aktif normal kullanıcıları listele (önceden yetkisi kaldırılanlar dahil).
    Route::get('/super-admin/users', [
        SuperAdminController::class,
        'users'
    ]);

    // Seçilen normal kullanıcıya yeniden admin yetkisi ver.
    Route::patch('/super-admin/users/{user}/promote', [
        SuperAdminController::class,
        'promote'
    ]);
});

// ----------------------------------------------------
// YÖNETİCİYE ÖZEL ŞİKAYET LİSTESİ - AD VE E-POSTA
// Anonim ve normal kullanıcılar bu veriye erişemez.
// ----------------------------------------------------
Route::get('/admin/complaints', [
    AdminComplaintController::class,
    'index'
])->middleware([
    'auth:sanctum',
    \App\Http\Middleware\EnsureAdmin::class,
]);

// ----------------------------------------------------
// ŞİKAYET DURUM GÜNCELLEME (YÖNETİCİ YETKİSİ GEREKİR)
// ----------------------------------------------------

Route::patch('/complaints/{complaint}/status', [
    ComplaintController::class,
    'updateStatus'
])->middleware([
    'auth:sanctum',
    \App\Http\Middleware\EnsureAdmin::class,
]);
