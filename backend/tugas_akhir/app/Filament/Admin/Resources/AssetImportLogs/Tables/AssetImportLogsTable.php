<?php

namespace App\Filament\Admin\Resources\AssetImportLogs\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class AssetImportLogsTable
{
    public static function table(Table $table): Table
{
    return $table
        ->columns([
            Tables\Columns\TextColumn::make('file_name')
                ->label('Nama File')
                ->searchable(),

            Tables\Columns\TextColumn::make('status')
                ->label('Status')
                ->badge()
                ->color(fn (string $state): string => match ($state) {
                    'processing' => 'warning',
                    'success' => 'success',
                    'failed' => 'danger',
                    'success_with_warning' => 'gray',
                    default => 'gray',
                }),

            Tables\Columns\TextColumn::make('total_rows')
                ->label('Total'),

            Tables\Columns\TextColumn::make('imported_rows')
                ->label('Berhasil'),

            Tables\Columns\TextColumn::make('skipped_rows')
                ->label('Dilewati'),

            Tables\Columns\TextColumn::make('started_at')
                ->label('Mulai')
                ->dateTime('d M Y H:i'),

            Tables\Columns\TextColumn::make('finished_at')
                ->label('Selesai')
                ->dateTime('d M Y H:i'),
        ])
        ->defaultSort('created_at', 'desc');
}
}
