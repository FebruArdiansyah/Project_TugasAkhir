<?php

namespace App\Filament\Admin\Resources\StockMovements\Schemas;

use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class StockMovementInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Mutasi')
                    ->schema([
                        Grid::make(3)
                            ->schema([
                                TextEntry::make('movement_number')
                                    ->label('No. Mutasi')
                                    ->badge(),

                                TextEntry::make('movement_type')
                                    ->label('Tipe Mutasi')
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
                                    }),

                                TextEntry::make('created_at')
                                    ->label('Tanggal')
                                    ->dateTime('d M Y H:i'),
                            ]),

                        Grid::make(2)
                            ->schema([
                                TextEntry::make('product.code')
                                    ->label('Kode Produk')
                                    ->badge(),

                                TextEntry::make('product.name')
                                    ->label('Nama Produk')
                                    ->weight('bold'),

                                TextEntry::make('product.full_name')
                                    ->label('Nama Lengkap')
                                    ->placeholder('-'),

                                TextEntry::make('warehouse.name')
                                    ->label('Gudang')
                                    ->badge(),
                            ]),
                    ]),

                Section::make('Perubahan Stok')
                    ->schema([
                        Grid::make(4)
                            ->schema([
                                TextEntry::make('qty_in')
                                    ->label('Qty Masuk')
                                    ->numeric(decimalPlaces: 0)
                                    ->suffix(' PCS')
                                    ->color('success'),

                                TextEntry::make('qty_out')
                                    ->label('Qty Keluar')
                                    ->numeric(decimalPlaces: 0)
                                    ->suffix(' PCS')
                                    ->color('danger'),

                                TextEntry::make('stock_before')
                                    ->label('Stok Sebelum')
                                    ->numeric(decimalPlaces: 0)
                                    ->suffix(' PCS'),

                                TextEntry::make('stock_after')
                                    ->label('Stok Sesudah')
                                    ->numeric(decimalPlaces: 0)
                                    ->suffix(' PCS')
                                    ->weight('bold'),
                            ]),
                    ]),

                Section::make('Referensi dan Catatan')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextEntry::make('reference_type')
                                    ->label('Tipe Referensi')
                                    ->formatStateUsing(fn (?string $state): string => $state ? class_basename($state) : '-')
                                    ->placeholder('-'),

                                TextEntry::make('reference_id')
                                    ->label('ID Referensi')
                                    ->placeholder('-'),

                                TextEntry::make('creator.name')
                                    ->label('Dibuat Oleh')
                                    ->placeholder('-'),

                                TextEntry::make('description')
                                    ->label('Deskripsi')
                                    ->placeholder('-')
                                    ->columnSpanFull(),
                            ]),
                    ])
                    ->collapsible(),
            ]);
    }
}