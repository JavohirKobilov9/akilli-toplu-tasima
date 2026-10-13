<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Support\Facades\Storage;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $appends = [
    'profile_photo_url',
];

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
            'Profil fotoğrafı güncellendi.',
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
            'Profil fotoğrafı silindi.',
        'user' => $user->fresh(),
    ]);
}

public function getProfilePhotoUrlAttribute()
{
    if (!$this->profile_photo_path) {
        return null;
    }

    return asset(
        'storage/' . $this->profile_photo_path
    );
}

    protected $fillable = [
        'name',
        'email',
        'phone',
        'profile_photo_path',
        'password',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
    ];

    public function complaints()
    {
        return $this->hasMany(Complaint::class);
    }

    public function comments()
    {
        return $this->hasMany(ComplaintComment::class);
    }

    public function commentReactions()
    {
        return $this->hasMany(CommentReaction::class);
    }
}