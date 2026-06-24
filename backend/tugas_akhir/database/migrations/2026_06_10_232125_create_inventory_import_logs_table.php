<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventory_import_logs', function (Blueprint $table) {
            $table->id();

            $table->string('file_name')->nullable();

            $table->string('transaction_type');
            // inbound / outbound

            $table->string('import_mode')->default('historical');
            // historical / operational

            $table->unsignedInteger('total_rows')->default(0);
            $table->unsignedInteger('imported_rows')->default(0);
            $table->unsignedInteger('skipped_rows')->default(0);

            $table->string('status')->default('processing');
            // processing, success, failed, success_with_warning

            $table->longText('message')->nullable();
            $table->longText('error_message')->nullable();

            $table->unsignedBigInteger('warehouse_id')->nullable();
            $table->unsignedBigInteger('imported_by')->nullable();

            $table->timestamp('started_at')->nullable();
            $table->timestamp('finished_at')->nullable();

            $table->timestamps();

            $table->index('transaction_type');
            $table->index('import_mode');
            $table->index('status');
            $table->index('warehouse_id');
            $table->index('imported_by');
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_import_logs');
    }
};