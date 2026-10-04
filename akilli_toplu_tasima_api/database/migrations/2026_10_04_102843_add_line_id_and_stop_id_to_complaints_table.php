<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('complaints', function (Blueprint $table) {
            $table->foreignId('line_id')
                ->nullable()
                ->after('description')
                ->constrained('lines')
                ->nullOnDelete();

            $table->foreignId('stop_id')
                ->nullable()
                ->after('line_id')
                ->constrained('stops')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('complaints', function (Blueprint $table) {
            $table->dropForeign(['line_id']);
            $table->dropForeign(['stop_id']);

            $table->dropColumn([
                'line_id',
                'stop_id',
            ]);
        });
    }
};