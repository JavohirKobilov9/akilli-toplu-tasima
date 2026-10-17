<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Complaint extends Model
{
    protected $fillable = [
        'user_id',
        'title',
        'category',
        'description',
        'line_id',
        'stop_id',
        'latitude',
        'longitude',
        'line',
        'stop',
        'status',
    ];

    // Misafir iletişim bilgileri JSON çıktısında gizlenir.
    protected $hidden = [
        'guest_email',
        'guest_email_verified_at',
        'guest_phone',
        'guest_phone_verified_at',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function line()
    {
        return $this->belongsTo(Line::class);
    }

    public function stop()
    {
        return $this->belongsTo(Stop::class);
    }

    public function comments()
    {
        return $this->hasMany(ComplaintComment::class);
    }
}
