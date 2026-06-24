<?php

namespace App\Filament\Admin\Resources\InventoryImportLogs\Schemas;

use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Schema;

class InventoryImportLogInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextEntry::make('file_name')
                    ->placeholder('-'),
                TextEntry::make('transaction_type'),
                TextEntry::make('import_mode'),
                TextEntry::make('total_rows')
                    ->numeric(),
                TextEntry::make('imported_rows')
                    ->numeric(),
                TextEntry::make('skipped_rows')
                    ->numeric(),
                TextEntry::make('status'),
                TextEntry::make('message')
                    ->placeholder('-')
                    ->columnSpanFull(),
                TextEntry::make('error_message')
                    ->placeholder('-')
                    ->columnSpanFull(),
                TextEntry::make('warehouse_id')
                    ->numeric()
                    ->placeholder('-'),
                TextEntry::make('imported_by')
                    ->numeric()
                    ->placeholder('-'),
                TextEntry::make('started_at')
                    ->dateTime()
                    ->placeholder('-'),
                TextEntry::make('finished_at')
                    ->dateTime()
                    ->placeholder('-'),
                TextEntry::make('created_at')
                    ->dateTime()
                    ->placeholder('-'),
                TextEntry::make('updated_at')
                    ->dateTime()
                    ->placeholder('-'),
            ]);
    }
}
