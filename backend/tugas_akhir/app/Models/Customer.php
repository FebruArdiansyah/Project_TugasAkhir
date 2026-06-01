<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Customer extends Model
{
    protected $fillable = [
        'code',
        'name',
        'phone',
        'address',
        'customer_type',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];
}
