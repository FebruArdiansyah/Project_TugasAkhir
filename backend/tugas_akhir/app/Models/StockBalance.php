<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StockBalance extends Model
{
    protected $fillable = [
        'product_id',
        'warehouse_id',
        'qty_on_hand',
        'qty_reserved',
        'minimum_stock',
    ];

    protected $casts = [
        'qty_on_hand' => 'decimal:2',
        'qty_reserved' => 'decimal:2',
        'minimum_stock' => 'decimal:2',
    ];

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function warehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class);
    }

    public function getQtyAvailableAttribute(): float
    {
        return (float) $this->qty_on_hand - (float) $this->qty_reserved;
    }

    public function getStockStatusAttribute(): string
    {
        $available = $this->qty_available;

        if ($available <= 0) {
            return 'habis';
        }

        if ($available <= (float) $this->minimum_stock) {
            return 'menipis';
        }

        return 'aman';
    }
}