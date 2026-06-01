<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('asset_categories', function (Blueprint $table) {
            $table->id();

            $table->string('code')->nullable()->unique();
            $table->string('name');
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);

            $table->timestamps();

            $table->index('name');
            $table->index('is_active');
        });

        Schema::create('asset_locations', function (Blueprint $table) {
            $table->id();

            $table->string('code')->nullable()->unique();
            $table->string('name');
            $table->text('address')->nullable();
            $table->boolean('is_active')->default(true);

            $table->timestamps();

            $table->index('name');
            $table->index('is_active');
        });

        Schema::create('assets', function (Blueprint $table) {
            $table->id();

            $table->foreignId('asset_category_id')
                ->nullable()
                ->constrained('asset_categories')
                ->nullOnDelete();

            $table->foreignId('asset_location_id')
                ->nullable()
                ->constrained('asset_locations')
                ->nullOnDelete();

            $table->string('asset_code')->unique();
            $table->string('name');

            // khusus kendaraan, contoh: A 9233 VM
            $table->string('license_plate')->nullable();

            $table->string('brand')->nullable();
            $table->string('model')->nullable();
            $table->string('serial_number')->nullable();

            $table->year('acquisition_year')->nullable();
            $table->date('acquisition_date')->nullable();

            $table->decimal('acquisition_price', 18, 2)->default(0);

            $table->enum('condition', [
                'baik',
                'rusak_ringan',
                'rusak_berat',
            ])->default('baik');

            $table->enum('status', [
                'aktif',
                'maintenance',
                'dipinjam',
                'rusak',
                'tidak_aktif',
            ])->default('aktif');

            $table->text('description')->nullable();

            $table->foreignId('created_by')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            $table->timestamps();

            $table->index('asset_category_id');
            $table->index('asset_location_id');
            $table->index('asset_code');
            $table->index('name');
            $table->index('license_plate');
            $table->index('acquisition_year');
            $table->index('condition');
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('assets');
        Schema::dropIfExists('asset_locations');
        Schema::dropIfExists('asset_categories');
    }
};