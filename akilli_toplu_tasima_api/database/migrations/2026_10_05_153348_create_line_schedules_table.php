<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('line_schedules', function (Blueprint $table) {
            $table->id();

            $table->foreignId('line_id')
                ->constrained('lines')
                ->cascadeOnDelete();

            // Hafta İçi, Cumartesi, Pazar,
            // KPSS, Kurban Bayramı, 15 Temmuz vb.
            $table->string('service_period');

            // Gidiş / Dönüş
            // Bazı resmi tablolarda yön açıkça belirtilmediği için nullable.
            $table->string('direction')->nullable();

            // Örn: 07:30
            $table->time('departure_time');

            // Örn: "Dallıca TOKİ'den çıkış"
            // veya "Öğretmenler Sitesi giriş saati"
            $table->text('note')->nullable();

            $table->timestamps();

            $table->index([
                'line_id',
                'service_period',
            ]);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('line_schedules');
    }
};