<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up()
    {
        DB::statement(
            'ALTER TABLE users ALTER COLUMN email DROP NOT NULL'
        );
    }

    public function down()
    {
        DB::statement(
            'ALTER TABLE users ALTER COLUMN email SET NOT NULL'
        );
    }
};