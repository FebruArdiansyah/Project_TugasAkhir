<?php

namespace App\Filament\Admin\Resources\InboundTransactions\Pages;

use App\Filament\Admin\Resources\InboundTransactions\InboundTransactionResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Filament\Support\Enums\Width;

class ListInboundTransactions extends ListRecords
{
    protected static string $resource = InboundTransactionResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()
                ->label('Tambah Barang Masuk')
                ->icon('heroicon-o-plus'),
        ];
    }
}