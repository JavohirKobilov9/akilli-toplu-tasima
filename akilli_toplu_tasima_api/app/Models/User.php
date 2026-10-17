<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

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
        'frozen_at' => 'datetime',
        'failed_login_attempts' => 'integer',
        'must_reset_password' => 'boolean',
    ];

    // Kullanıcı normal yönetici veya süper yönetici mi?
    public function isAdmin(): bool
    {
        return in_array(
            $this->role,
            ['admin', 'super_admin'],
            true
        );
    }

    // Kullanıcı süper yönetici mi?
    public function isSuperAdmin(): bool
    {
        return $this->role === 'super_admin';
    }
}