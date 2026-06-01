<?php

namespace App\Filament\Admin\Resources\Customers\Pages;

use App\Filament\Admin\Resources\Customers\CustomerResource;
use Filament\Resources\Pages\ViewRecord;
use Filament\Support\Enums\Width;

class ViewCustomer extends ViewRecord
{
    protected static string $resource = CustomerResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;
}