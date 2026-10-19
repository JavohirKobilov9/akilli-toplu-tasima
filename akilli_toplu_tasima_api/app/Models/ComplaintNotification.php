<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ComplaintNotification extends Model
{
    protected $guarded = ['id'];

    protected $casts = ['read_at' => 'datetime'];
}
