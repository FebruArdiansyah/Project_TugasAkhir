<?php

namespace App\Filament\Admin\Resources\Suppliers\Pages;

use App\Filament\Admin\Resources\Suppliers\SupplierResource;
use Filament\Resources\Pages\CreateRecord;
use Filament\Support\Enums\Width;

class CreateSupplier extends CreateRecord
{
    protected static string $resource = SupplierResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;
}