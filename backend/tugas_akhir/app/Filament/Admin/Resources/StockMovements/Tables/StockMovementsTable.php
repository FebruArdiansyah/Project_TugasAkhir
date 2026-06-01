<?php

namespace App\Filament\Admin\Resources\StockMovements\Tables;

use Filament\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class StockMovementsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('movement_number')
                    ->label('No. Mutasi')
                    ->searchable()
                    ->sortable()
                    ->badge(),

                TextColumn::make('movement_type')
                    ->label('Tipe')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'IN' => 'Masuk',
                        'OUT' => 'Keluar',
                        'ADJUSTMENT' => 'Adjustment',
                        'TRANSFER_IN' => 'Transfer Masuk',
                        'TRANSFER_OUT' => 'Transfer Keluar',
                        default => $state,
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'IN', 'TRANSFER_IN' => 'success',
                        'OUT', 'TRANSFER_OUT' => 'danger',
                        'ADJUSTMENT' => 'warning',
                        default => 'gray',
                    })
                    ->sortable(),

                TextColumn::make('product.code')
                    ->label('Kode Produk')
                    ->badge()
                    ->searchable()
                    ->sortable(),

                TextColumn::make('product.name')
                    ->label('Produk')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->description(fn ($record): ?string => $record->product?->full_name),

                TextColumn::make('warehouse.name')
                    ->label('Gudang')
                    ->badge()
                    ->searchable()
                    ->sortable(),

                TextColumn::make('qty_in')
                    ->label('Masuk')
                    ->numeric(decimalPlaces: 0)
                    ->suffix(' PCS')
                    ->color('success')
                    ->sortable(),

                TextColumn::make('qty_out')
                    ->label('Keluar')
                    ->numeric(decimalPlaces: 0)
                    ->suffix(' PCS')
                    ->color('danger')
                    ->sortable(),

                TextColumn::make('stock_before')
                    ->label('Stok Sebelum')
                    ->numeric(decimalPlaces: 0)
                    ->suffix(' PCS')
                    ->sortable()
                    ->toggleable(),

                TextColumn::make('stock_after')
                    ->label('Stok Sesudah')
                    ->numeric(decimalPlaces: 0)
                    ->suffix(' PCS')
                    ->weight('bold')
                    ->sortable(),

                TextColumn::make('reference_type')
                    ->label('Sumber')
                    ->formatStateUsing(fn (?string $state): string => $state ? class_basename($state) : '-')
                    ->badge()
                    ->toggleable(),

                TextColumn::make('creator.name')
                    ->label('Dibuat Oleh')
                    ->placeholder('-')
                    ->searchable()
                    ->toggleable(),

                TextColumn::make('created_at')
                    ->label('Tanggal')
                    ->dateTime('d M Y H:i')
                    ->sortable(),
            ])
            ->filters([
                SelectFilter::make('movement_type')
                    ->label('Tipe Mutasi')
                    ->options([
                        'IN' => 'Masuk',
                        'OUT' => 'Keluar',
                        'ADJUSTMENT' => 'Adjustment',
                        'TRANSFER_IN' => 'Transfer Masuk',
                        'TRANSFER_OUT' => 'Transfer Keluar',
                    ]),

                SelectFilter::make('warehouse_id')
                    ->label('Gudang')
                    ->relationship('warehouse', 'name')
                    ->searchable()
                    ->preload(),

                SelectFilter::make('product_id')
                    ->label('Produk')
                    ->relationship('product', 'name')
                    ->searchable()
                    ->preload(),
            ])
            ->recordActions([
                ViewAction::make()
                    ->label('Lihat'),
            ])
            ->defaultSort('created_at', 'desc');
    }
}