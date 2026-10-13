<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Line extends Model
{
    protected $fillable = [
        'code',
        'name',
        'transport_type',
        'start_point',
        'end_point',
        'is_active',
    ];

    public function stops()
    {
        return $this->belongsToMany(Stop::class, 'line_stop')
            ->withPivot('stop_order')
            ->withTimestamps()
            ->orderBy('line_stop.stop_order');
    }
    
    public function schedules()
{
    return $this->hasMany(LineSchedule::class)
        ->orderBy('departure_time');
}
}