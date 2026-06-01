<?php

namespace App\Filament\Admin\Resources\InboundTransactions\Pages;

use App\Filament\Admin\Resources\InboundTransactions\InboundTransactionResource;
use Filament\Resources\Pages\ViewRecord;
use Filament\Support\Enums\Width;

class ViewInboundTransaction extends ViewRecord
{
    protected static string $resource = InboundTransactionResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;
}