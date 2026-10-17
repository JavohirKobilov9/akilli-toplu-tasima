<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // PostgreSQL'de doğrudan değiştirerek Doctrine DBAL ihtiyacını kaldırır.
        DB::statement('ALTER TABLE guest_complaint_verifications ALTER COLUMN email DROP NOT NULL');

        if (!Schema::hasColumn('guest_complaint_verifications', 'phone')) {
            Schema::table('guest_complaint_verifications', function (Blueprint $table) {
                $table->string('phone', 20)->nullable();
            });
        }

        DB::statement('CREATE INDEX IF NOT EXISTS guest_verifications_phone_created_index ON guest_complaint_verifications (phone, created_at)');

        Schema::table('complaints', function (Blueprint $table) {
            if (!Schema::hasColumn('complaints', 'guest_phone')) {
                $table->string('guest_phone', 20)->nullable();
            }
            if (!Schema::hasColumn('complaints', 'guest_phone_verified_at')) {
                $table->timestamp('guest_phone_verified_at')->nullable();
            }
        });
    }

    public function down(): void
    {
        if (
            DB::table('complaints')->whereNotNull('guest_phone')->exists() ||
            DB::table('guest_complaint_verifications')->whereNotNull('phone')->exists()
        ) {
            throw new RuntimeException('Telefon doğrulama verileri mevcut; geri alma durduruldu.');
        }

        Schema::table('complaints', function (Blueprint $table) {
            $table->dropColumn(['guest_phone', 'guest_phone_verified_at']);
        });

        DB::statement('DROP INDEX IF EXISTS guest_verifications_phone_created_index');
        Schema::table('guest_complaint_verifications', function (Blueprint $table) {
            $table->dropColumn('phone');
        });
        DB::statement('ALTER TABLE guest_complaint_verifications ALTER COLUMN email SET NOT NULL');
    }
};
