<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LineSchedule extends Model
{
    protected $fillable = [
        'line_id',
        'service_period',
        'direction',
        'departure_time',
        'note',
    ];

    protected $casts = [
        'departure_time' => 'datetime:H:i',
    ];

    public function line()
    {
        return $this->belongsTo(Line::class);
    }
}