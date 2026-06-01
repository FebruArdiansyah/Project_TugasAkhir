<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Asset extends Model
{
    protected $fillable = [
        'asset_category_id',
        'asset_location_id',
        'asset_code',
        'name',
        'license_plate',
        'brand',
        'model',
        'serial_number',
        'acquisition_year',
        'acquisition_date',
        'acquisition_price',
        'condition',
        'status',
        'description',
        'created_by',
    ];

    protected $casts = [
        'acquisition_date' => 'date',
        'acquisition_price' => 'decimal:2',
        'acquisition_year' => 'integer',
    ];

    public function category(): BelongsTo
    {
        return $this->belongsTo(AssetCategory::class, 'asset_category_id');
    }

    public function location(): BelongsTo
    {
        return $this->belongsTo(AssetLocation::class, 'asset_location_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function getConditionLabelAttribute(): string
    {
        return match ($this->condition) {
            'baik' => 'Baik',
            'rusak_ringan' => 'Rusak Ringan',
            'rusak_berat' => 'Rusak Berat',
            default => '-',
        };
    }

    public function getStatusLabelAttribute(): string
    {
        return match ($this->status) {
            'aktif' => 'Aktif',
            'maintenance' => 'Maintenance',
            'dipinjam' => 'Dipinjam',
            'rusak' => 'Rusak',
            'tidak_aktif' => 'Tidak Aktif',
            default => '-',
        };
    }

    public function getFormattedAcquisitionPriceAttribute(): string
    {
        return 'Rp ' . number_format((float) $this->acquisition_price, 0, ',', '.');
    }

    public function getDisplayNameAttribute(): string
    {
        if ($this->asset_code) {
            return "{$this->asset_code} - {$this->name}";
        }

        return $this->name;
    }
}