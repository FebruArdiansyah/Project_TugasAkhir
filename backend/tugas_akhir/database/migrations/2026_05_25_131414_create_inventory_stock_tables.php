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
        | Stock Balances
        |--------------------------------------------------------------------------
        | Menyimpan saldo stok produk per gudang.
        */
        Schema::create('stock_balances', function (Blueprint $table) {
            $table->id();

            $table->foreignId('product_id')
                ->constrained('products')
                ->cascadeOnDelete();

            $table->foreignId('warehouse_id')
                ->constrained('warehouses')
                ->cascadeOnDelete();

            $table->decimal('qty_on_hand', 15, 2)->default(0);
            $table->decimal('qty_reserved', 15, 2)->default(0);
            $table->decimal('minimum_stock', 15, 2)->default(0);

            $table->timestamps();

            $table->unique(
                ['product_id', 'warehouse_id'],
                'stock_balance_product_warehouse_unique'
            );

            $table->index('product_id', 'stock_balance_product_idx');
            $table->index('warehouse_id', 'stock_balance_warehouse_idx');
        });

        /*
        |--------------------------------------------------------------------------
        | Stock Movements
        |--------------------------------------------------------------------------
        | Mencatat mutasi stok final setelah transaksi approved.
        */
        Schema::create('stock_movements', function (Blueprint $table) {
            $table->id();

            $table->string('movement_number')->unique();

            $table->foreignId('product_id')
                ->constrained('products')
                ->cascadeOnDelete();

            $table->foreignId('warehouse_id')
                ->constrained('warehouses')
                ->cascadeOnDelete();

            $table->string('movement_type');
            // IN, OUT, ADJUSTMENT, TRANSFER_IN, TRANSFER_OUT

            $table->string('reference_type')->nullable();
            $table->unsignedBigInteger('reference_id')->nullable();

            $table->decimal('qty_in', 15, 2)->default(0);
            $table->decimal('qty_out', 15, 2)->default(0);

            $table->decimal('stock_before', 15, 2)->default(0);
            $table->decimal('stock_after', 15, 2)->default(0);

            $table->text('description')->nullable();

            $table->foreignId('created_by')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            $table->timestamps();

            $table->index(
                ['reference_type', 'reference_id'],
                'stock_movement_reference_idx'
            );

            $table->index(
                ['product_id', 'warehouse_id', 'movement_type'],
                'stock_movement_filter_idx'
            );

            $table->index('created_by', 'stock_movement_created_by_idx');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('stock_movements');
        Schema::dropIfExists('stock_balances');
    }
};