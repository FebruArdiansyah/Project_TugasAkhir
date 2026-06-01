<?php

namespace App\Filament\Admin\Resources\OutboundTransactions\Pages;

use App\Filament\Admin\Resources\OutboundTransactions\OutboundTransactionResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Filament\Support\Enums\Width;

class ListOutboundTransactions extends ListRecords
{
    protected static string $resource = OutboundTransactionResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()
                ->label('Tambah Barang Keluar')
                ->icon('heroicon-o-plus'),
        ];
    }
}