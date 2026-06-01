<?php

namespace App\Filament\Admin\Widgets;

use App\Models\StockBalance;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;
use Illuminate\Database\Eloquent\Builder;

class CriticalStockWidget extends TableWidget
{
    protected static ?string $heading = 'Stok Kritis dan Habis';

    protected static ?int $sort = 3;

    protected int|string|array $columnSpan = 'full';

    public function table(Table $table): Table
    {
        return $table
            ->query(
                StockBalance::query()
                    ->with(['product', 'warehouse'])
                    ->whereRaw('(qty_on_hand - qty_reserved) <= minimum_stock')
                    ->orderByRaw('(qty_on_hand - qty_reserved) asc')
            )
            ->columns([
                TextColumn::make('product.code')
                    ->label('Kode')
                    ->badge()
                    ->searchable(),

                TextColumn::make('product.name')
                    ->label('Produk')
                    ->searchable()
                    ->weight('bold')
                    ->description(fn ($record): ?string => $record->product?->full_name),

                TextColumn::make('warehouse.name')
                    ->label('Gudang')
                    ->badge()
                    ->searchable(),

                TextColumn::make('qty_on_hand')
                    ->label('Stok Fisik')
                    ->numeric(decimalPlaces: 0)
                    ->suffix(' PCS')
                    ->sortable(),

                TextColumn::make('qty_reserved')
                    ->label('Reserved')
                    ->numeric(decimalPlaces: 0)
                    ->suffix(' PCS')
                    ->color('warning')
                    ->sortable(),

                TextColumn::make('qty_available')
                    ->label('Stok Tersedia')
                    ->state(fn ($record): float => (float) $record->qty_on_hand - (float) $record->qty_reserved)
                    ->numeric(decimalPlaces: 0)
                    ->suffix(' PCS')
                    ->weight('bold')
                    ->color(fn ($state): string => (float) $state <= 0 ? 'danger' : 'warning')
                    ->sortable(query: function (Builder $query, string $direction): Builder {
                        return $query->orderByRaw('(qty_on_hand - qty_reserved) ' . $direction);
                    }),

                TextColumn::make('minimum_stock')
                    ->label('Minimum')
                    ->numeric(decimalPlaces: 0)
                    ->suffix(' PCS')
                    ->sortable(),

                TextColumn::make('status_stok')
                    ->label('Status')
                    ->state(function ($record): string {
                        $available = (float) $record->qty_on_hand - (float) $record->qty_reserved;

                        if ($available <= 0) {
                            return 'Habis';
                        }

                        return 'Menipis';
                    })
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'Habis' => 'danger',
                        'Menipis' => 'warning',
                        default => 'gray',
                    }),
            ])
            ->paginated([5, 10, 25])
            ->defaultPaginationPageOption(5);
    }
}