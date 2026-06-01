<?php

namespace App\Filament\Admin\Resources\Warehouses\Schemas;

use Filament\Infolists\Components\IconEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class WarehouseInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Gudang')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextEntry::make('code')
                                    ->label('Kode Gudang')
                                    ->badge(),

                                TextEntry::make('name')
                                    ->label('Nama Gudang')
                                    ->weight('bold'),

                                TextEntry::make('phone')
                                    ->label('No. Telepon')
                                    ->placeholder('-'),

                                IconEntry::make('is_active')
                                    ->label('Status Aktif')
                                    ->boolean(),

                                TextEntry::make('address')
                                    ->label('Alamat')
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