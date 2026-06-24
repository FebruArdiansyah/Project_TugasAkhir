<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('asset_import_logs', function (Blueprint $table) {
            $table->id();

            $table->string('file_name')->nullable();
            $table->unsignedInteger('total_rows')->default(0);
            $table->unsignedInteger('imported_rows')->default(0);
            $table->unsignedInteger('skipped_rows')->default(0);

            $table->string('status')->default('processing');
            // processing, success, failed, success_with_warning

            $table->longText('message')->nullable();
            $table->longText('error_message')->nullable();

            $table->unsignedBigInteger('imported_by')->nullable();

            $table->timestamp('started_at')->nullable();
            $table->timestamp('finished_at')->nullable();

            $table->timestamps();

            $table->index('status');
            $table->index('imported_by');
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('asset_import_logs');
    }
};