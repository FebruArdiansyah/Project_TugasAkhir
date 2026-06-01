<?php

namespace App\Filament\Admin\Resources\Assets\Schemas;

use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class AssetInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Identitas Aset')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextEntry::make('asset_code')
                                    ->label('Kode Aset')
                                    ->badge(),

                                TextEntry::make('name')
                                    ->label('Nama Aset')
                                    ->weight('bold'),

                                TextEntry::make('category.name')
                                    ->label('Kategori')
                                    ->badge()
                                    ->placeholder('-'),

                                TextEntry::make('location.name')
                                    ->label('Lokasi')
                                    ->badge()
                                    ->placeholder('-'),
                            ]),
                    ]),

                Section::make('Detail Aset')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextEntry::make('license_plate')
                                    ->label('No Polisi / Kendaraan')
                                    ->placeholder('-'),

                                TextEntry::make('brand')
                                    ->label('Merk')
                                    ->placeholder('-'),

                                TextEntry::make('model')
                                    ->label('Model / Tipe')
                                    ->placeholder('-'),

                                TextEntry::make('serial_number')
                                    ->label('Serial Number')
                                    ->placeholder('-'),

                                TextEntry::make('acquisition_year')
                                    ->label('Tahun Perolehan')
                                    ->placeholder('-'),

                                TextEntry::make('acquisition_date')
                                    ->label('Tanggal Perolehan')
                                    ->date('d M Y')
                                    ->placeholder('-'),

                                TextEntry::make('acquisition_price')
                                    ->label('Harga Perolehan')
                                    ->money('IDR'),
                            ]),
                    ]),

                Section::make('Kondisi dan Status')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextEntry::make('condition')
                                    ->label('Kondisi')
                                    ->badge()
                                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                                        'baik' => 'Baik',
                                        'rusak_ringan' => 'Rusak Ringan',
                                        'rusak_berat' => 'Rusak Berat',
                                        default => '-',
                                    })
                                    ->color(fn (?string $state): string => match ($state) {
                                        'baik' => 'success',
                                        'rusak_ringan' => 'warning',
                                        'rusak_berat' => 'danger',
                                        default => 'gray',
                                    }),

                                TextEntry::make('status')
                                    ->label('Status')
                                    ->badge()
                                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                                        'aktif' => 'Aktif',
                                        'maintenance' => 'Maintenance',
                                        'dipinjam' => 'Dipinjam',
                                        'rusak' => 'Rusak',
                                        'tidak_aktif' => 'Tidak Aktif',
                                        default => '-',
                                    })
                                    ->color(fn (?string $state): string => match ($state) {
                                        'aktif' => 'success',
                                        'maintenance' => 'warning',
                                        'dipinjam' => 'info',
                                        'rusak' => 'danger',
                                        'tidak_aktif' => 'gray',
                                        default => 'gray',
                                    }),

                                TextEntry::make('description')
                                    ->label('Keterangan')
                                    ->placeholder('-')
                                    ->columnSpanFull(),
                            ]),
                    ]),

                Section::make('Waktu Data')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextEntry::make('created_at')
                                    ->label('Dibuat')
                                    ->dateTime('d M Y H:i'),

                                TextEntry::make('updated_at')
                                    ->label('Diupdate')
                                    ->dateTime('d M Y H:i'),
                            ]),
                    ])
                    ->collapsible(),
            ]);
    }
}