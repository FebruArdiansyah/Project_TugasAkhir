<?php

namespace App\Filament\Admin\Resources\Profiles\Schemas;

use Filament\Infolists\Components\IconEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class ProfileInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Akun')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextEntry::make('user.name')
                                    ->label('Nama User')
                                    ->weight('bold'),

                                TextEntry::make('user.email')
                                    ->label('Email'),

                                TextEntry::make('username')
                                    ->label('Username')
                                    ->badge()
                                    ->placeholder('-'),

                                TextEntry::make('employee_code')
                                    ->label('Kode Karyawan')
                                    ->placeholder('-'),

                                TextEntry::make('position')
                                    ->label('Jabatan')
                                    ->placeholder('-'),

                                TextEntry::make('warehouse.name')
                                    ->label('Gudang / Area Tugas')
                                    ->badge()
                                    ->placeholder('-'),
                            ]),
                    ]),

                Section::make('Kontak dan Status')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextEntry::make('phone')
                                    ->label('No. Telepon')
                                    ->placeholder('-'),

                                IconEntry::make('is_active')
                                    ->label('Status Aktif')
                                    ->boolean(),

                                TextEntry::make('last_login_at')
                                    ->label('Login Terakhir')
                                    ->dateTime('d M Y H:i')
                                    ->placeholder('-'),

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