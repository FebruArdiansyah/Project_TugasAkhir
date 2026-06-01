<?php

namespace App\Filament\Admin\Resources\StockBalances\Schemas;

use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class StockBalanceInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Produk dan Gudang')
                    ->schema([
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

                Section::make('Informasi Stok')
                    ->schema([
                        Grid::make(4)
                            ->schema([
                                TextEntry::make('qty_on_hand')
                                    ->label('Stok Fisik')
                                    ->numeric(decimalPlaces: 0)
                                    ->suffix(' PCS'),

                                TextEntry::make('qty_reserved')
                                    ->label('Pending / Reserved')
                                    ->numeric(decimalPlaces: 0)
                                    ->suffix(' PCS'),

                                TextEntry::make('qty_available')
                                    ->label('Stok Tersedia')
                                    ->numeric(decimalPlaces: 0)
                                    ->suffix(' PCS')
                                    ->weight('bold'),

                                TextEntry::make('minimum_stock')
                                    ->label('Minimum Stok')
                                    ->numeric(decimalPlaces: 0)
                                    ->suffix(' PCS'),
                            ]),

                        TextEntry::make('stock_status')
                            ->label('Status Stok')
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
                    ]),

                Section::make('Waktu Data')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextEntry::make('created_at')
                                    ->label('Dibuat')
                                    ->dateTime('d M Y H:i'),

                                TextEntry::make('updated_at')
                                    ->label('Terakhir Diupdate')
                                    ->dateTime('d M Y H:i'),
                            ]),
                    ])
                    ->collapsible(),
            ]);
    }
}