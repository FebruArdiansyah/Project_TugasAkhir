<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dw_dim_asset_categories', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('source_asset_category_id')->unique();
            $table->string('code')->nullable();
            $table->string('name');
            $table->boolean('is_active')->default(true);

            $table->timestamps();

            $table->index('code', 'dw_asset_category_code_idx');
            $table->index('name', 'dw_asset_category_name_idx');
        });

        Schema::create('dw_dim_asset_locations', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('source_asset_location_id')->unique();
            $table->string('code')->nullable();
            $table->string('name');
            $table->text('address')->nullable();
            $table->boolean('is_active')->default(true);

            $table->timestamps();

            $table->index('code', 'dw_asset_location_code_idx');
            $table->index('name', 'dw_asset_location_name_idx');
        });

        Schema::create('dw_dim_assets', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('source_asset_id')->unique();

            $table->unsignedBigInteger('asset_category_dim_id')->nullable()->index();
            $table->unsignedBigInteger('asset_location_dim_id')->nullable()->index();

            $table->string('asset_code')->nullable();
            $table->string('name');
            $table->string('license_plate')->nullable();

            $table->string('brand')->nullable();
            $table->string('model')->nullable();
            $table->string('serial_number')->nullable();

            $table->unsignedSmallInteger('acquisition_year')->nullable();
            $table->date('acquisition_date')->nullable();
            $table->decimal('acquisition_price', 18, 2)->default(0);

            $table->string('condition')->nullable();
            $table->string('status')->nullable();

            $table->timestamps();

            $table->index('asset_code', 'dw_asset_code_idx');
            $table->index('name', 'dw_asset_name_idx');
            $table->index('license_plate', 'dw_asset_license_plate_idx');
            $table->index('acquisition_year', 'dw_asset_acquisition_year_idx');
            $table->index('condition', 'dw_asset_condition_idx');
            $table->index('status', 'dw_asset_status_idx');
        });

        Schema::create('dw_fact_asset_snapshots', function (Blueprint $table) {
            $table->id();

            $table->unsignedInteger('date_key')->index();

            $table->unsignedBigInteger('asset_dim_id')->index();
            $table->unsignedBigInteger('asset_category_dim_id')->nullable()->index();
            $table->unsignedBigInteger('asset_location_dim_id')->nullable()->index();

            $table->decimal('acquisition_price', 18, 2)->default(0);

            $table->string('condition')->nullable();
            $table->string('status')->nullable();

            $table->boolean('is_active')->default(true);

            $table->timestamp('snapshot_at')->nullable();
            $table->timestamps();

            $table->unique(['date_key', 'asset_dim_id'], 'dw_asset_snapshot_unique');
            $table->index(['date_key', 'status'], 'dw_asset_snapshot_status_idx');
            $table->index(['date_key', 'condition'], 'dw_asset_snapshot_condition_idx');
            $table->index(['asset_category_dim_id', 'status'], 'dw_asset_category_status_idx');
            $table->index(['asset_location_dim_id', 'status'], 'dw_asset_location_status_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('dw_fact_asset_snapshots');
        Schema::dropIfExists('dw_dim_assets');
        Schema::dropIfExists('dw_dim_asset_locations');
        Schema::dropIfExists('dw_dim_asset_categories');
    }
};