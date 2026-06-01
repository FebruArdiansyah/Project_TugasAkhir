<?php

namespace App\Filament\Admin\Resources\Customers\Schemas;

use Filament\Infolists\Components\IconEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class CustomerInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Customer')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextEntry::make('code')
                                    ->label('Kode Customer')
                                    ->badge(),

                                TextEntry::make('name')
                                    ->label('Nama Customer')
                                    ->weight('bold'),

                                TextEntry::make('phone')
                                    ->label('No. Telepon')
                                    ->placeholder('-'),

                                TextEntry::make('customer_type')
                                    ->label('Tipe Customer')
                                    ->badge()
                                    ->formatStateUsing(fn (string $state): string => match ($state) {
                                        'customer' => 'Customer',
                                        'internal' => 'Internal',
                                        'project' => 'Project',
                                        'other' => 'Lainnya',
                                        default => ucfirst($state),
                                    }),

                                TextEntry::make('address')
                                    ->label('Alamat')
                                    ->placeholder('-')
                                    ->columnSpanFull(),

                                IconEntry::make('is_active')
                                    ->label('Status Aktif')
                                    ->boolean(),
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