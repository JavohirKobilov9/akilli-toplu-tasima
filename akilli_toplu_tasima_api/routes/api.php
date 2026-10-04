<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ComplaintController;
use App\Http\Controllers\Api\LineController;


// ŞİKAYET API'LERİ

Route::get(
    '/complaints',
    [ComplaintController::class, 'index']
);

Route::post(
    '/complaints',
    [ComplaintController::class, 'store']
);

Route::get(
    '/complaints/{complaint}',
    [ComplaintController::class, 'show']
);


// HAT API'LERİ

Route::get(
    '/lines',
    [LineController::class, 'index']
);


// SEÇİLEN HATTIN DURAKLARI

Route::get(
    '/lines/{line}/stops',
    [LineController::class, 'stops']
);