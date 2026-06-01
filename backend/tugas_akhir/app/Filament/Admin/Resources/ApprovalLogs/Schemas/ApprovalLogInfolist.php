<?php

namespace App\Filament\Admin\Resources\ApprovalLogs\Schemas;

use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class ApprovalLogInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Approval')
                    ->schema([
                        Grid::make(3)
                            ->schema([
                                TextEntry::make('action')
                                    ->label('Aksi')
                                    ->badge()
                                    ->formatStateUsing(fn (string $state): string => match ($state) {
                                        'submitted' => 'Submitted',
                                        'approved' => 'Approved',
                                        'rejected' => 'Rejected',
                                        'cancelled' => 'Cancelled',
                                        default => ucfirst($state),
                                    })
                                    ->color(fn (string $state): string => match ($state) {
                                        'submitted' => 'info',
                                        'approved' => 'success',
                                        'rejected' => 'danger',
                                        'cancelled' => 'gray',
                                        default => 'gray',
                                    }),

                                TextEntry::make('old_status')
                                    ->label('Status Lama')
                                    ->badge()
                                    ->placeholder('-'),

                                TextEntry::make('new_status')
                                    ->label('Status Baru')
                                    ->badge()
                                    ->placeholder('-')
                                    ->color(fn (?string $state): string => match ($state) {
                                        'pending' => 'warning',
                                        'approved' => 'success',
                                        'rejected' => 'danger',
                                        'cancelled' => 'gray',
                                        default => 'gray',
                                    }),
                            ]),

                        Grid::make(3)
                            ->schema([
                                TextEntry::make('approvable_type')
                                    ->label('Tipe Transaksi')
                                    ->formatStateUsing(fn (?string $state): string => $state ? class_basename($state) : '-')
                                    ->badge(),

                                TextEntry::make('approvable_id')
                                    ->label('ID Transaksi'),

                                TextEntry::make('actor.name')
                                    ->label('Dilakukan Oleh')
                                    ->placeholder('-'),

                                TextEntry::make('acted_at')
                                    ->label('Waktu Aksi')
                                    ->dateTime('d M Y H:i')
                                    ->placeholder('-'),

                                TextEntry::make('created_at')
                                    ->label('Dicatat Pada')
                                    ->dateTime('d M Y H:i'),
                            ]),

                        TextEntry::make('note')
                            ->label('Catatan')
                            ->placeholder('-')
                            ->columnSpanFull(),
                    ]),
            ]);
    }
}