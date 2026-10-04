<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('complaints', function (Blueprint $table) {
    $table->id();

    $table->foreignId('user_id')
        ->nullable()
        ->constrained()
        ->nullOnDelete();

    $table->string('title');

    $table->string('category');

    $table->text('description');

    $table->string('line')->nullable();

    $table->string('stop')->nullable();

    $table->string('status')->default('Beklemede');

    $table->timestamps();
});
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('complaints');
    }
};
