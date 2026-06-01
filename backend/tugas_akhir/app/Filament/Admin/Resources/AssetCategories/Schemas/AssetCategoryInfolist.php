<?php

namespace App\Filament\Admin\Resources\AssetCategories\Schemas;

use Filament\Infolists\Components\IconEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class AssetCategoryInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Kategori Aset')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextEntry::make('code')
                                    ->label('Kode')
                                    ->badge()
                                    ->placeholder('-'),

                                TextEntry::make('name')
                                    ->label('Nama Kategori')
                                    ->weight('bold'),

                                TextEntry::make('assets_count')
                                    ->label('Jumlah Aset')
                                    ->state(fn ($record): int => $record->assets()->count())
                                    ->badge(),

                                IconEntry::make('is_active')
                                    ->label('Aktif')
                                    ->boolean(),

                                TextEntry::make('description')
                                    ->label('Deskripsi')
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