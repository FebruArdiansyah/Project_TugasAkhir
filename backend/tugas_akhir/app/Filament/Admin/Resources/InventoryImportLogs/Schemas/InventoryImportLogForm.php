<?php

namespace App\Filament\Admin\Resources\InventoryImportLogs\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Schemas\Schema;

class InventoryImportLogForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('file_name')
                    ->default(null),
                TextInput::make('transaction_type')
                    ->required(),
                TextInput::make('import_mode')
                    ->required()
                    ->default('historical'),
                TextInput::make('total_rows')
                    ->required()
                    ->numeric()
                    ->default(0),
                TextInput::make('imported_rows')
                    ->required()
                    ->numeric()
                    ->default(0),
                TextInput::make('skipped_rows')
                    ->required()
                    ->numeric()
                    ->default(0),
                TextInput::make('status')
                    ->required()
                    ->default('processing'),
                Textarea::make('message')
                    ->default(null)
                    ->columnSpanFull(),
                Textarea::make('error_message')
                    ->default(null)
                    ->columnSpanFull(),
                TextInput::make('warehouse_id')
                    ->numeric()
                    ->default(null),
                TextInput::make('imported_by')
                    ->numeric()
                    ->default(null),
                DateTimePicker::make('started_at'),
                DateTimePicker::make('finished_at'),
            ]);
    }
}
