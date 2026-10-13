<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('comment_reactions', function (Blueprint $table) {
            $table->id();

            $table->foreignId('comment_id')
                ->constrained('complaint_comments')
                ->cascadeOnDelete();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('reaction');

            $table->timestamps();

            $table->unique([
                'comment_id',
                'user_id',
            ]);
        });
    }

    public function down()
    {
        Schema::dropIfExists('comment_reactions');
    }
};