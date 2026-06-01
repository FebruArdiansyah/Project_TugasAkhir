<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InboundTransactionItem extends Model
{
    protected $fillable = [
        'inbound_transaction_id',
        'product_id',
        'warehouse_id',
        'unit_id',
        'qty',
        'unit_cost',
        'subtotal',
        'product_code_snapshot',
        'product_name_snapshot',
        'unit_name_snapshot',
        'note',
    ];

    protected $casts = [
        'qty' => 'decimal:2',
        'unit_cost' => 'decimal:2',
        'subtotal' => 'decimal:2',
    ];

    public function transaction(): BelongsTo
    {
        return $this->belongsTo(InboundTransaction::class, 'inbound_transaction_id');
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