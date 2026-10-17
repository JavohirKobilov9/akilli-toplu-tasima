<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        if (!Schema::hasColumn('users', 'frozen_at')) {
            Schema::table('users', function (Blueprint $table) {
                $table
                    ->timestamp('frozen_at')
                    ->nullable()
                    ->after('must_reset_password');
            });
        }
    }

    public function down()
    {
        if (Schema::hasColumn('users', 'frozen_at')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('frozen_at');
            });
        }
    }
};