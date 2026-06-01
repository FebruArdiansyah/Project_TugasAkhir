<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        /*
        |--------------------------------------------------------------------------
        | Units
        |--------------------------------------------------------------------------
        | Satuan produk: PCS, KG, ROLL, PACK, dll.
        */
        Schema::create('units', function (Blueprint $table) {
            $table->id();

            $table->string('code')->unique();
            $table->string('name');

            $table->timestamps();
        });

        /*
        |--------------------------------------------------------------------------
        | Product Types
        |--------------------------------------------------------------------------
        | Type produk jadi: EON, ROYAL, SUPREME, EFV, dll.
        */
        Schema::create('product_types', function (Blueprint $table) {
            $table->id();

            $table->string('name')->unique();
            $table->boolean('is_active')->default(true);

            $table->timestamps();

            $table->index('is_active', 'product_types_active_idx');
        });

        /*
        |--------------------------------------------------------------------------
        | Product Densities
        |--------------------------------------------------------------------------
        | Density / grade produk: D-22, D-23, D-24, D-16, dll.
        */
        Schema::create('product_densities', function (Blueprint $table) {
            $table->id();

            $table->string('name')->unique();
            $table->boolean('is_active')->default(true);

            $table->timestamps();

            $table->index('is_active', 'product_densities_active_idx');
        });

        /*
        |--------------------------------------------------------------------------
        | Product Categories
        |--------------------------------------------------------------------------
        | Kategori produk: LG++, VACUM, KARUNG, LIGHT GREEN, dll.
        */
        Schema::create('product_categories', function (Blueprint $table) {
            $table->id();

            $table->string('name')->unique();
            $table->boolean('is_active')->default(true);

            $table->timestamps();

            $table->index('is_active', 'product_categories_active_idx');
        });

        /*
        |--------------------------------------------------------------------------
        | Products
        |--------------------------------------------------------------------------
        | Master produk jadi.
        */
        Schema::create('products', function (Blueprint $table) {
            $table->id();

            $table->string('code')->unique();
            $table->string('name');

            $table->foreignId('product_type_id')
                ->nullable()
                ->constrained('product_types')
                ->nullOnDelete();

            $table->foreignId('product_density_id')
                ->nullable()
                ->constrained('product_densities')
                ->nullOnDelete();

            $table->foreignId('product_category_id')
                ->nullable()
                ->constrained('product_categories')
                ->nullOnDelete();

            $table->foreignId('unit_id')
                ->nullable()
                ->constrained('units')
                ->nullOnDelete();

            $table->decimal('length', 12, 2)->nullable();
            $table->decimal('width', 12, 2)->nullable();
            $table->decimal('thickness', 12, 2)->nullable();

            $table->string('size_text')->nullable();
            $table->string('full_name')->nullable();

            /*
            |--------------------------------------------------------------------------
            | Harga Produk
            |--------------------------------------------------------------------------
            | Harga di master hanya sebagai harga default / referensi.
            | Harga asli invoice tetap akan disimpan lagi di detail transaksi.
            */
            $table->decimal('default_purchase_price', 15, 2)->default(0);
            $table->decimal('default_selling_price', 15, 2)->default(0);
            $table->decimal('last_purchase_price', 15, 2)->default(0);
            $table->decimal('last_selling_price', 15, 2)->default(0);

            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);

            $table->timestamps();

            /*
            |--------------------------------------------------------------------------
            | Index
            |--------------------------------------------------------------------------
            | Nama index dibuat pendek agar tidak error di MySQL:
            | SQLSTATE[42000] 1059 Identifier name is too long.
            */
            $table->index(
                ['product_type_id', 'product_density_id', 'product_category_id'],
                'products_master_filter_idx'
            );

            $table->index('unit_id', 'products_unit_idx');
            $table->index('is_active', 'products_active_idx');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('products');
        Schema::dropIfExists('product_categories');
        Schema::dropIfExists('product_densities');
        Schema::dropIfExists('product_types');
        Schema::dropIfExists('units');
    }
};