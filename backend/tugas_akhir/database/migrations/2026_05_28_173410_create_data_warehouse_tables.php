<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dw_dim_dates', function (Blueprint $table) {
            $table->unsignedInteger('date_key')->primary(); // format: 20260529
            $table->date('full_date')->unique();

            $table->unsignedTinyInteger('day');
            $table->unsignedTinyInteger('month');
            $table->string('month_name');
            $table->unsignedTinyInteger('quarter');
            $table->unsignedSmallInteger('year');
            $table->string('day_name');
            $table->boolean('is_weekend')->default(false);

            $table->timestamps();

            $table->index(['year', 'month'], 'dw_date_year_month_idx');
        });

        Schema::create('dw_dim_products', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('source_product_id')->unique();
            $table->string('code')->nullable();
            $table->string('name');
            $table->string('full_name')->nullable();

            $table->string('type_name')->nullable();
            $table->string('density_name')->nullable();
            $table->string('category_name')->nullable();
            $table->string('unit_name')->nullable();

            $table->decimal('default_purchase_price', 18, 2)->default(0);
            $table->decimal('default_selling_price', 18, 2)->default(0);

            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index('code', 'dw_product_code_idx');
            $table->index('name', 'dw_product_name_idx');
            $table->index('type_name', 'dw_product_type_idx');
            $table->index('category_name', 'dw_product_category_idx');
        });

        Schema::create('dw_dim_warehouses', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('source_warehouse_id')->unique();
            $table->string('code')->nullable();
            $table->string('name');
            $table->text('address')->nullable();
            $table->string('phone')->nullable();

            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index('code', 'dw_warehouse_code_idx');
            $table->index('name', 'dw_warehouse_name_idx');
        });

        Schema::create('dw_dim_suppliers', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('source_supplier_id')->unique();
            $table->string('code')->nullable();
            $table->string('name');
            $table->string('phone')->nullable();
            $table->text('address')->nullable();

            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index('code', 'dw_supplier_code_idx');
            $table->index('name', 'dw_supplier_name_idx');
        });

        Schema::create('dw_dim_customers', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('source_customer_id')->unique();
            $table->string('code')->nullable();
            $table->string('name');
            $table->string('phone')->nullable();
            $table->text('address')->nullable();
            $table->string('customer_type')->nullable();

            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index('code', 'dw_customer_code_idx');
            $table->index('name', 'dw_customer_name_idx');
            $table->index('customer_type', 'dw_customer_type_idx');
        });

        Schema::create('dw_dim_users', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('source_user_id')->unique();
            $table->string('name');
            $table->string('email')->nullable();

            $table->string('username')->nullable();
            $table->string('employee_code')->nullable();
            $table->string('position')->nullable();
            $table->string('warehouse_name')->nullable();

            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index('name', 'dw_user_name_idx');
            $table->index('email', 'dw_user_email_idx');
        });

        Schema::create('dw_fact_inventory_movements', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('source_stock_movement_id')->unique();
            $table->string('movement_number')->nullable();
            $table->string('movement_type');

            $table->unsignedInteger('date_key')->index();
            $table->unsignedBigInteger('product_dim_id')->index();
            $table->unsignedBigInteger('warehouse_dim_id')->index();
            $table->unsignedBigInteger('user_dim_id')->nullable()->index();

            $table->decimal('qty_in', 18, 2)->default(0);
            $table->decimal('qty_out', 18, 2)->default(0);
            $table->decimal('stock_before', 18, 2)->default(0);
            $table->decimal('stock_after', 18, 2)->default(0);

            $table->string('reference_type')->nullable();
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->text('description')->nullable();

            $table->timestamp('movement_created_at')->nullable();
            $table->timestamps();

            $table->index(['date_key', 'movement_type'], 'dw_move_date_type_idx');
            $table->index(['product_dim_id', 'date_key'], 'dw_move_product_date_idx');
            $table->index(['warehouse_dim_id', 'date_key'], 'dw_move_warehouse_date_idx');
        });

        Schema::create('dw_fact_inbound_transactions', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('source_inbound_id')->unique();
            $table->string('transaction_number');
            $table->string('invoice_number')->nullable();

            $table->unsignedInteger('date_key')->index();
            $table->unsignedBigInteger('warehouse_dim_id')->index();
            $table->unsignedBigInteger('supplier_dim_id')->nullable()->index();
            $table->unsignedBigInteger('submitted_user_dim_id')->nullable()->index();
            $table->unsignedBigInteger('approved_user_dim_id')->nullable()->index();

            $table->unsignedInteger('total_items')->default(0);
            $table->decimal('total_qty', 18, 2)->default(0);
            $table->decimal('sub_total', 18, 2)->default(0);
            $table->decimal('discount_amount', 18, 2)->default(0);
            $table->decimal('other_cost', 18, 2)->default(0);
            $table->decimal('grand_total', 18, 2)->default(0);

            $table->string('status')->default('pending');
            $table->string('source')->nullable();

            $table->timestamp('submitted_at')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('transaction_created_at')->nullable();
            $table->timestamps();

            $table->index(['date_key', 'status'], 'dw_inbound_date_status_idx');
            $table->index(['warehouse_dim_id', 'date_key'], 'dw_inbound_wh_date_idx');
            $table->index(['supplier_dim_id', 'date_key'], 'dw_inbound_sup_date_idx');
        });

        Schema::create('dw_fact_outbound_transactions', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('source_outbound_id')->unique();
            $table->string('transaction_number');
            $table->string('reference_number')->nullable();
            $table->string('outbound_type')->nullable();

            $table->unsignedInteger('date_key')->index();
            $table->unsignedBigInteger('warehouse_dim_id')->index();
            $table->unsignedBigInteger('customer_dim_id')->nullable()->index();
            $table->unsignedBigInteger('submitted_user_dim_id')->nullable()->index();
            $table->unsignedBigInteger('approved_user_dim_id')->nullable()->index();

            $table->unsignedInteger('total_items')->default(0);
            $table->decimal('total_qty', 18, 2)->default(0);
            $table->decimal('sub_total', 18, 2)->default(0);
            $table->decimal('discount_amount', 18, 2)->default(0);
            $table->decimal('vat_amount', 18, 2)->default(0);
            $table->decimal('other_cost', 18, 2)->default(0);
            $table->decimal('grand_total', 18, 2)->default(0);
            $table->decimal('paid_amount', 18, 2)->default(0);
            $table->decimal('remaining_amount', 18, 2)->default(0);

            $table->string('status')->default('pending');
            $table->string('source')->nullable();

            $table->timestamp('submitted_at')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('transaction_created_at')->nullable();
            $table->timestamps();

            $table->index(['date_key', 'status'], 'dw_outbound_date_status_idx');
            $table->index(['warehouse_dim_id', 'date_key'], 'dw_outbound_wh_date_idx');
            $table->index(['customer_dim_id', 'date_key'], 'dw_outbound_cust_date_idx');
            $table->index(['outbound_type', 'date_key'], 'dw_outbound_type_date_idx');
        });

        Schema::create('dw_fact_stock_snapshots', function (Blueprint $table) {
            $table->id();

            $table->unsignedInteger('date_key')->index();
            $table->unsignedBigInteger('product_dim_id')->index();
            $table->unsignedBigInteger('warehouse_dim_id')->index();

            $table->decimal('qty_on_hand', 18, 2)->default(0);
            $table->decimal('qty_reserved', 18, 2)->default(0);
            $table->decimal('qty_available', 18, 2)->default(0);
            $table->decimal('minimum_stock', 18, 2)->default(0);

            $table->string('stock_status')->default('aman');

            $table->timestamp('snapshot_at')->nullable();
            $table->timestamps();

            $table->unique(['date_key', 'product_dim_id', 'warehouse_dim_id'], 'dw_stock_snapshot_unique');
            $table->index(['date_key', 'stock_status'], 'dw_stock_snapshot_status_idx');
            $table->index(['warehouse_dim_id', 'stock_status'], 'dw_stock_wh_status_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('dw_fact_stock_snapshots');
        Schema::dropIfExists('dw_fact_outbound_transactions');
        Schema::dropIfExists('dw_fact_inbound_transactions');
        Schema::dropIfExists('dw_fact_inventory_movements');

        Schema::dropIfExists('dw_dim_users');
        Schema::dropIfExists('dw_dim_customers');
        Schema::dropIfExists('dw_dim_suppliers');
        Schema::dropIfExists('dw_dim_warehouses');
        Schema::dropIfExists('dw_dim_products');
        Schema::dropIfExists('dw_dim_dates');
    }
};