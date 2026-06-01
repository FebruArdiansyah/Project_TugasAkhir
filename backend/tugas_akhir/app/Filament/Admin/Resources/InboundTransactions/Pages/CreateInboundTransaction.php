<?php

namespace App\Filament\Admin\Resources\InboundTransactions\Pages;

use App\Filament\Admin\Resources\InboundTransactions\InboundTransactionResource;
use App\Services\InventorySubmissionService;
use App\Services\InventoryTransactionTotalService;
use Filament\Resources\Pages\CreateRecord;
use Filament\Support\Enums\Width;

class CreateInboundTransaction extends CreateRecord
{
    protected static string $resource = InboundTransactionResource::class;

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
        app(InventoryTransactionTotalService::class)->recalculateInbound($this->record);

        app(InventorySubmissionService::class)->submitInbound($this->record);
    }
}