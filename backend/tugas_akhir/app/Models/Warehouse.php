<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Warehouse extends Model
{
     protected $fillable = [
        'code',
        'name',
        'address',
        'phone',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function profiles(): HasMany
    {
        return $this->hasMany(Profile::class);
    }
}
