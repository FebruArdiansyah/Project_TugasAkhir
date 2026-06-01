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
        | Inbound Transactions
        |--------------------------------------------------------------------------
        | Header transaksi barang masuk.
        */
        Schema::create('inbound_transactions', function (Blueprint $table) {
            $table->id();

            $table->string('transaction_number')->unique();
            $table->date('transaction_date');

            $table->string('invoice_number')->nullable();

            $table->foreignId('supplier_id')->nullable();
            $table->foreignId('warehouse_id');

            $table->text('note')->nullable();

            $table->string('status')->default('pending');
            // pending, approved, rejected, cancelled

            $table->decimal('sub_total', 15, 2)->default(0);
            $table->decimal('discount_amount', 15, 2)->default(0);
            $table->decimal('other_cost', 15, 2)->default(0);
            $table->decimal('grand_total', 15, 2)->default(0);

            $table->foreignId('submitted_by')->nullable();
            $table->timestamp('submitted_at')->nullable();

            $table->foreignId('approved_by')->nullable();
            $table->timestamp('approved_at')->nullable();

            $table->foreignId('rejected_by')->nullable();
            $table->timestamp('rejected_at')->nullable();

            $table->text('rejection_reason')->nullable();
            $table->text('approval_note')->nullable();

            $table->string('source')->default('mobile');
            // mobile / admin

            $table->timestamps();

            $table->foreign('supplier_id', 'in_trx_supplier_fk')
                ->references('id')
                ->on('suppliers')
                ->nullOnDelete();

            $table->foreign('warehouse_id', 'in_trx_warehouse_fk')
                ->references('id')
                ->on('warehouses')
                ->cascadeOnDelete();

            $table->foreign('submitted_by', 'in_trx_submitted_by_fk')
                ->references('id')
                ->on('users')
                ->nullOnDelete();

            $table->foreign('approved_by', 'in_trx_approved_by_fk')
                ->references('id')
                ->on('users')
                ->nullOnDelete();

            $table->foreign('rejected_by', 'in_trx_rejected_by_fk')
                ->references('id')
                ->on('users')
                ->nullOnDelete();

            $table->index(['status', 'transaction_date'], 'in_trx_status_date_idx');
            $table->index(['warehouse_id', 'status'], 'in_trx_warehouse_status_idx');
        });

        /*
        |--------------------------------------------------------------------------
        | Inbound Transaction Items
        |--------------------------------------------------------------------------
        | Detail produk yang masuk.
        */
        Schema::create('inbound_transaction_items', function (Blueprint $table) {
            $table->id();

            $table->foreignId('inbound_transaction_id');
            $table->foreignId('product_id');
            $table->foreignId('warehouse_id');
            $table->foreignId('unit_id')->nullable();

            $table->decimal('qty', 15, 2);

            $table->decimal('unit_cost', 15, 2)->default(0);
            $table->decimal('subtotal', 15, 2)->default(0);

            $table->string('product_code_snapshot')->nullable();
            $table->string('product_name_snapshot')->nullable();
            $table->string('unit_name_snapshot')->nullable();

            $table->text('note')->nullable();

            $table->timestamps();

            $table->foreign('inbound_transaction_id', 'in_item_trx_fk')
                ->references('id')
                ->on('inbound_transactions')
                ->cascadeOnDelete();

            $table->foreign('product_id', 'in_item_product_fk')
                ->references('id')
                ->on('products')
                ->cascadeOnDelete();

            $table->foreign('warehouse_id', 'in_item_warehouse_fk')
                ->references('id')
                ->on('warehouses')
                ->cascadeOnDelete();

            $table->foreign('unit_id', 'in_item_unit_fk')
                ->references('id')
                ->on('units')
                ->nullOnDelete();

            $table->index(['product_id', 'warehouse_id'], 'in_item_product_warehouse_idx');
        });

        /*
        |--------------------------------------------------------------------------
        | Inbound Transaction Attachments
        |--------------------------------------------------------------------------
        | Foto bukti barang masuk.
        */
        Schema::create('inbound_transaction_attachments', function (Blueprint $table) {
            $table->id();

            $table->foreignId('inbound_transaction_id');

            $table->string('file_path');
            $table->string('file_name')->nullable();
            $table->string('mime_type')->nullable();
            $table->unsignedBigInteger('file_size')->nullable();

            $table->foreignId('uploaded_by')->nullable();

            $table->timestamps();

            $table->foreign('inbound_transaction_id', 'in_att_trx_fk')
                ->references('id')
                ->on('inbound_transactions')
                ->cascadeOnDelete();

            $table->foreign('uploaded_by', 'in_att_uploaded_by_fk')
                ->references('id')
                ->on('users')
                ->nullOnDelete();
        });

        /*
        |--------------------------------------------------------------------------
        | Outbound Transactions
        |--------------------------------------------------------------------------
        | Header transaksi barang keluar / invoice keluar.
        */
        Schema::create('outbound_transactions', function (Blueprint $table) {
            $table->id();

            $table->string('transaction_number')->unique();
            $table->date('transaction_date');

            $table->string('outbound_type')->default('penjualan');
            // penjualan, sample, transfer, rusak, lainnya

            $table->string('reference_number')->nullable();

            $table->foreignId('customer_id')->nullable();
            $table->foreignId('warehouse_id');

            $table->string('sales_name')->nullable();
            $table->string('driver_name')->nullable();
            $table->date('due_date')->nullable();

            $table->text('note')->nullable();

            $table->string('status')->default('pending');
            // pending, approved, rejected, cancelled

            $table->decimal('sub_total', 15, 2)->default(0);
            $table->decimal('discount_amount', 15, 2)->default(0);
            $table->decimal('vat_percent', 5, 2)->default(0);
            $table->decimal('vat_amount', 15, 2)->default(0);
            $table->decimal('other_cost', 15, 2)->default(0);
            $table->decimal('grand_total', 15, 2)->default(0);
            $table->decimal('paid_amount', 15, 2)->default(0);
            $table->decimal('remaining_amount', 15, 2)->default(0);

            $table->foreignId('submitted_by')->nullable();
            $table->timestamp('submitted_at')->nullable();

            $table->foreignId('approved_by')->nullable();
            $table->timestamp('approved_at')->nullable();

            $table->foreignId('rejected_by')->nullable();
            $table->timestamp('rejected_at')->nullable();

            $table->text('rejection_reason')->nullable();
            $table->text('approval_note')->nullable();

            $table->string('source')->default('mobile');
            // mobile / admin

            $table->timestamps();

            $table->foreign('customer_id', 'out_trx_customer_fk')
                ->references('id')
                ->on('customers')
                ->nullOnDelete();

            $table->foreign('warehouse_id', 'out_trx_warehouse_fk')
                ->references('id')
                ->on('warehouses')
                ->cascadeOnDelete();

            $table->foreign('submitted_by', 'out_trx_submitted_by_fk')
                ->references('id')
                ->on('users')
                ->nullOnDelete();

            $table->foreign('approved_by', 'out_trx_approved_by_fk')
                ->references('id')
                ->on('users')
                ->nullOnDelete();

            $table->foreign('rejected_by', 'out_trx_rejected_by_fk')
                ->references('id')
                ->on('users')
                ->nullOnDelete();

            $table->index(['status', 'transaction_date'], 'out_trx_status_date_idx');
            $table->index(['warehouse_id', 'status'], 'out_trx_warehouse_status_idx');
            $table->index('outbound_type', 'out_trx_type_idx');
        });

        /*
        |--------------------------------------------------------------------------
        | Outbound Transaction Items
        |--------------------------------------------------------------------------
        | Detail produk yang keluar.
        */
        Schema::create('outbound_transaction_items', function (Blueprint $table) {
            $table->id();

            $table->foreignId('outbound_transaction_id');
            $table->foreignId('product_id');
            $table->foreignId('warehouse_id');
            $table->foreignId('unit_id')->nullable();

            $table->decimal('qty', 15, 2);

            $table->decimal('unit_price', 15, 2)->default(0);
            $table->decimal('discount_amount', 15, 2)->default(0);
            $table->decimal('subtotal', 15, 2)->default(0);

            $table->decimal('stock_before_submit', 15, 2)->default(0);
            $table->decimal('stock_after_submit', 15, 2)->default(0);

            $table->string('product_code_snapshot')->nullable();
            $table->string('product_name_snapshot')->nullable();
            $table->string('unit_name_snapshot')->nullable();

            $table->text('note')->nullable();

            $table->timestamps();

            $table->foreign('outbound_transaction_id', 'out_item_trx_fk')
                ->references('id')
                ->on('outbound_transactions')
                ->cascadeOnDelete();

            $table->foreign('product_id', 'out_item_product_fk')
                ->references('id')
                ->on('products')
                ->cascadeOnDelete();

            $table->foreign('warehouse_id', 'out_item_warehouse_fk')
                ->references('id')
                ->on('warehouses')
                ->cascadeOnDelete();

            $table->foreign('unit_id', 'out_item_unit_fk')
                ->references('id')
                ->on('units')
                ->nullOnDelete();

            $table->index(['product_id', 'warehouse_id'], 'out_item_product_warehouse_idx');
        });

        /*
        |--------------------------------------------------------------------------
        | Outbound Transaction Attachments
        |--------------------------------------------------------------------------
        | Foto bukti barang keluar.
        */
        Schema::create('outbound_transaction_attachments', function (Blueprint $table) {
            $table->id();

            $table->foreignId('outbound_transaction_id');

            $table->string('file_path');
            $table->string('file_name')->nullable();
            $table->string('mime_type')->nullable();
            $table->unsignedBigInteger('file_size')->nullable();

            $table->foreignId('uploaded_by')->nullable();

            $table->timestamps();

            $table->foreign('outbound_transaction_id', 'out_att_trx_fk')
                ->references('id')
                ->on('outbound_transactions')
                ->cascadeOnDelete();

            $table->foreign('uploaded_by', 'out_att_uploaded_by_fk')
                ->references('id')
                ->on('users')
                ->nullOnDelete();
        });

        /*
        |--------------------------------------------------------------------------
        | Approval Logs
        |--------------------------------------------------------------------------
        | Audit trail approval transaksi.
        */
        Schema::create('approval_logs', function (Blueprint $table) {
            $table->id();

            $table->string('approvable_type');
            $table->unsignedBigInteger('approvable_id');

            $table->string('action');
            // submitted, approved, rejected, cancelled

            $table->string('old_status')->nullable();
            $table->string('new_status')->nullable();

            $table->text('note')->nullable();

            $table->foreignId('acted_by')->nullable();
            $table->timestamp('acted_at')->nullable();

            $table->timestamps();

            $table->foreign('acted_by', 'approval_logs_acted_by_fk')
                ->references('id')
                ->on('users')
                ->nullOnDelete();

            $table->index(
                ['approvable_type', 'approvable_id'],
                'approval_logs_approvable_idx'
            );

            $table->index(['action', 'acted_at'], 'approval_logs_action_time_idx');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('approval_logs');

        Schema::dropIfExists('outbound_transaction_attachments');
        Schema::dropIfExists('outbound_transaction_items');
        Schema::dropIfExists('outbound_transactions');

        Schema::dropIfExists('inbound_transaction_attachments');
        Schema::dropIfExists('inbound_transaction_items');
        Schema::dropIfExists('inbound_transactions');
    }
};