    <?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Projenin PostgreSQL veritabanında user_id artık misafirler için NULL olabilir.
        DB::statement('ALTER TABLE complaints ALTER COLUMN user_id DROP NOT NULL');

        Schema::table('complaints', function (Blueprint $table) {
            $table->string('guest_email')->nullable();
            $table->timestamp('guest_email_verified_at')->nullable();
        });

        Schema::create('guest_complaint_verifications', function (Blueprint $table) {
            $table->id();
            $table->string('email');
            $table->string('code_hash');
            $table->unsignedTinyInteger('attempts')->default(0);
            $table->timestamp('expires_at');
            $table->timestamp('verified_at')->nullable();
            $table->timestamp('used_at')->nullable();
            $table->string('token_hash', 64)->nullable()->unique();
            $table->timestamps();
            $table->index(['email', 'created_at']);
        });
    }

    public function down(): void
    {
        // Misafir şikayetleri varsa kayıtları silmeden geri alma yapılamaz.
        if (DB::table('complaints')->whereNull('user_id')->exists()) {
            throw new RuntimeException(
                'Misafir şikayetleri bulunduğu için migration geri alınmadı. Verileri koruyun.'
            );
        }

        Schema::dropIfExists('guest_complaint_verifications');
        Schema::table('complaints', function (Blueprint $table) {
            $table->dropColumn(['guest_email', 'guest_email_verified_at']);
        });
        DB::statement('ALTER TABLE complaints ALTER COLUMN user_id SET NOT NULL');
    }
};
