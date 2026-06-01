<?php

namespace App\Filament\Admin\Resources\StockBalances\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class StockBalancesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('product.code')
                    ->label('Kode')
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

                TextColumn::make('qty_on_hand')
                    ->label('Stok Fisik')
                    ->numeric(decimalPlaces: 0)
                    ->suffix(' PCS')
                    ->sortable(),

                TextColumn::make('qty_reserved')
                    ->label('Pending / Reserved')
                    ->numeric(decimalPlaces: 0)
                    ->suffix(' PCS')
                    ->sortable()
                    ->color('warning'),

                TextColumn::make('qty_available')
                    ->label('Stok Tersedia')
                    ->numeric(decimalPlaces: 0)
                    ->suffix(' PCS')
                    ->sortable(query: function (Builder $query, string $direction): Builder {
                        return $query->orderByRaw('(qty_on_hand - qty_reserved) ' . $direction);
                    })
                    ->weight('bold'),

                TextColumn::make('minimum_stock')
                    ->label('Minimum')
                    ->numeric(decimalPlaces: 0)
                    ->suffix(' PCS')
                    ->sortable(),

                TextColumn::make('stock_status')
                    ->label('Status')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'aman' => 'Aman',
                        'menipis' => 'Menipis',
                        'habis' => 'Habis',
                        default => ucfirst($state),
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'aman' => 'success',
                        'menipis' => 'warning',
                        'habis' => 'danger',
                        default => 'gray',
                    }),

                TextColumn::make('updated_at')
                    ->label('Update Terakhir')
                    ->dateTime('d M Y H:i')
                    ->sortable()
                    ->toggleable(),

                TextColumn::make('created_at')
                    ->label('Dibuat')
                    ->dateTime('d M Y H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
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

                Filter::make('stok_aman')
                    ->label('Stok Aman')
                    ->query(fn (Builder $query): Builder => $query->whereRaw('(qty_on_hand - qty_reserved) > minimum_stock')),

                Filter::make('stok_menipis')
                    ->label('Stok Menipis')
                    ->query(fn (Builder $query): Builder => $query->whereRaw('(qty_on_hand - qty_reserved) > 0 AND (qty_on_hand - qty_reserved) <= minimum_stock')),

                Filter::make('stok_habis')
                    ->label('Stok Habis')
                    ->query(fn (Builder $query): Builder => $query->whereRaw('(qty_on_hand - qty_reserved) <= 0')),
            ])
            ->recordActions([
                ViewAction::make()
                    ->label('Lihat'),

                EditAction::make()
                    ->label('Edit Minimum'),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make()
                        ->label('Hapus Terpilih'),
                ]),
            ])
            ->defaultSort('updated_at', 'desc');
    }
}