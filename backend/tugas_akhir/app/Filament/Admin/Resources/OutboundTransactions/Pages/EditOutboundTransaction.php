<?php

namespace App\Filament\Admin\Resources\OutboundTransactions\Pages;

use App\Filament\Admin\Resources\OutboundTransactions\OutboundTransactionResource;
use App\Services\InventoryTransactionTotalService;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;
use Filament\Support\Enums\Width;

class EditOutboundTransaction extends EditRecord
{
    protected static string $resource = OutboundTransactionResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;

    protected function afterSave(): void
    {
        if ($this->record->status === 'pending') {
            app(InventoryTransactionTotalService::class)->recalculateOutbound($this->record);
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