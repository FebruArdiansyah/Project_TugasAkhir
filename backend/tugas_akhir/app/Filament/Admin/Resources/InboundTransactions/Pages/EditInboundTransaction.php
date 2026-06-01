<?php

namespace App\Filament\Admin\Resources\InboundTransactions\Pages;

use App\Filament\Admin\Resources\InboundTransactions\InboundTransactionResource;
use App\Services\InventoryTransactionTotalService;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;
use Filament\Support\Enums\Width;

class EditInboundTransaction extends EditRecord
{
    protected static string $resource = InboundTransactionResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;

    protected function afterSave(): void
    {
        if ($this->record->status === 'pending') {
            app(InventoryTransactionTotalService::class)->recalculateInbound($this->record);
        }
    }

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make()
                ->visible(fn (): bool => $this->record->status === 'pending'),
        ];
    }
}