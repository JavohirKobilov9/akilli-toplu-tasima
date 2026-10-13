<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CommentReaction extends Model
{
    protected $fillable = [
        'comment_id',
        'user_id',
        'reaction',
    ];

    public function comment()
    {
        return $this->belongsTo(
            ComplaintComment::class,
            'comment_id'
        );
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}