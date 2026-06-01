<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Unit extends Model
{
    protected $fillable = [
        'code',
        'name',
    ];

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    public function inboundTransactionItems(): HasMany
    {
        return $this->hasMany(InboundTransactionItem::class);
    }

    public function outboundTransactionItems(): HasMany
    {
        return $this->hasMany(OutboundTransactionItem::class);
    }
}