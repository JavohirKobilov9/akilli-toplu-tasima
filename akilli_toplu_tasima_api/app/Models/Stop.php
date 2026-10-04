<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Stop extends Model
{
    protected $fillable = [
        'code',
        'name',
        'district',
        'latitude',
        'longitude',
        'is_active',
    ];

    public function lines()
    {
        return $this->belongsToMany(Line::class, 'line_stop')
            ->withPivot('stop_order')
            ->withTimestamps();
    }
}