<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OutboundTransactionItem extends Model
{
    protected $fillable = [
        'outbound_transaction_id',
        'product_id',
        'warehouse_id',
        'unit_id',
        'qty',
        'unit_price',
        'discount_amount',
        'subtotal',
        'stock_before_submit',
        'stock_after_submit',
        'product_code_snapshot',
        'product_name_snapshot',
        'unit_name_snapshot',
        'note',
    ];

    protected $casts = [
        'qty' => 'decimal:2',
        'unit_price' => 'decimal:2',
        'discount_amount' => 'decimal:2',
        'subtotal' => 'decimal:2',
        'stock_before_submit' => 'decimal:2',
        'stock_after_submit' => 'decimal:2',
    ];

    public function transaction(): BelongsTo
    {
        return $this->belongsTo(OutboundTransaction::class, 'outbound_transaction_id');
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function warehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class);
    }

    public function unit(): BelongsTo
    {
        return $this->belongsTo(Unit::class);
    }
}