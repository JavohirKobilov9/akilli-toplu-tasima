<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CommentController;
use App\Http\Controllers\Api\ComplaintController;
use App\Http\Controllers\Api\LineController;


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

Route::post('/profile/photo', [
    AuthController::class,
    'updateProfilePhoto'
]);

Route::delete('/profile/photo', [
    AuthController::class,
    'deleteProfilePhoto'
]);

Route::patch('/profile', [
    AuthController::class,
    'updateProfile'
]);

Route::post('/profile/email/request-code', [
    AuthController::class,
    'requestEmailChangeCode'
]);

Route::post('/profile/email/confirm', [
    AuthController::class,
    'confirmEmailChange'
]);
  
Route::delete('/complaints/{complaint}', [
    ComplaintController::class,
    'destroy'
]);

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

    Route::get('/my-complaints', [
    ComplaintController::class,
    'myComplaints'
]);
    
    Route::post('/change-password', [
        AuthController::class,
        'changePassword'
    ]);

    // Yeni şikayet oluştur
    Route::post('/complaints', [
        ComplaintController::class,
        'store'
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
});


// ----------------------------------------------------
// ŞİKAYET DURUM GÜNCELLEME
// Şimdilik mevcut sistem için burada.
// React admin oluştururken admin yetkisine bağlayacağız.
// ----------------------------------------------------

Route::patch('/complaints/{complaint}/status', [
    ComplaintController::class,
    'updateStatus'
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