<?php

namespace App\Filament\Admin\Resources\OutboundTransactions\Pages;

use App\Filament\Admin\Resources\OutboundTransactions\OutboundTransactionResource;
use App\Services\InventorySubmissionService;
use App\Services\InventoryTransactionTotalService;
use Filament\Resources\Pages\CreateRecord;
use Filament\Support\Enums\Width;

class CreateOutboundTransaction extends CreateRecord
{
    protected static string $resource = OutboundTransactionResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $data['submitted_by'] = auth()->id();
        $data['submitted_at'] = now();
        $data['status'] = 'pending';

        return $data;
    }

    protected function afterCreate(): void
    {
        app(InventoryTransactionTotalService::class)->recalculateOutbound($this->record);

        app(InventorySubmissionService::class)->submitOutbound($this->record);
    }
}