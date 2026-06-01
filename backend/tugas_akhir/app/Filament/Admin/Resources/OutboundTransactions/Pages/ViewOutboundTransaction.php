<?php

namespace App\Filament\Admin\Resources\OutboundTransactions\Pages;

use App\Filament\Admin\Resources\OutboundTransactions\OutboundTransactionResource;
use Filament\Resources\Pages\ViewRecord;
use Filament\Support\Enums\Width;

class ViewOutboundTransaction extends ViewRecord
{
    protected static string $resource = OutboundTransactionResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;
}