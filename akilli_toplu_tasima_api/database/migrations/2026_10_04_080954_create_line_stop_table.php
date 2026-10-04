<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('line_stop', function (Blueprint $table) {
            $table->id();

            $table->foreignId('line_id')
                ->constrained('lines')
                ->cascadeOnDelete();

            $table->foreignId('stop_id')
                ->constrained('stops')
                ->cascadeOnDelete();

            $table->unsignedInteger('stop_order');

            $table->timestamps();

            $table->unique(['line_id', 'stop_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('line_stop');
    }
};