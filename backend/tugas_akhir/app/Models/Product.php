<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Product extends Model
{
    protected $fillable = [
        'code',
        'name',
        'product_type_id',
        'product_density_id',
        'product_category_id',
        'unit_id',
        'length',
        'width',
        'thickness',
        'size_text',
        'full_name',
        'default_purchase_price',
        'default_selling_price',
        'last_purchase_price',
        'last_selling_price',
        'description',
        'is_active',
    ];

    protected $casts = [
        'length' => 'decimal:2',
        'width' => 'decimal:2',
        'thickness' => 'decimal:2',
        'default_purchase_price' => 'decimal:2',
        'default_selling_price' => 'decimal:2',
        'last_purchase_price' => 'decimal:2',
        'last_selling_price' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    public function type(): BelongsTo
    {
        return $this->belongsTo(ProductType::class, 'product_type_id');
    }

    public function density(): BelongsTo
    {
        return $this->belongsTo(ProductDensity::class, 'product_density_id');
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(ProductCategory::class, 'product_category_id');
    }

    public function unit(): BelongsTo
    {
        return $this->belongsTo(Unit::class, 'unit_id');
    }

    /**
     * Alias untuk kebutuhan Data Warehouse command.
     */
    public function productType(): BelongsTo
    {
        return $this->type();
    }

    /**
     * Alias untuk kebutuhan Data Warehouse command.
     */
    public function productDensity(): BelongsTo
    {
        return $this->density();
    }

    /**
     * Alias untuk kebutuhan Data Warehouse command.
     */
    public function productCategory(): BelongsTo
    {
        return $this->category();
    }

    public function getDisplayNameAttribute(): string
    {
        return $this->full_name ?: $this->name;
    }

    public function getSizeLabelAttribute(): ?string
    {
        if ($this->size_text) {
            return $this->size_text;
        }

        if ($this->length && $this->width && $this->thickness) {
            return "{$this->length} x {$this->width} x {$this->thickness} CM";
        }

        return null;
    }
}