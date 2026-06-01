<?php

namespace App\Filament\Admin\Resources\ApprovalLogs\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Schemas\Schema;

class ApprovalLogForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('approvable_type')
                    ->required(),
                TextInput::make('approvable_id')
                    ->required()
                    ->numeric(),
                TextInput::make('action')
                    ->required(),
                TextInput::make('old_status')
                    ->default(null),
                TextInput::make('new_status')
                    ->default(null),
                Textarea::make('note')
                    ->default(null)
                    ->columnSpanFull(),
                TextInput::make('acted_by')
                    ->numeric()
                    ->default(null),
                DateTimePicker::make('acted_at'),
            ]);
    }
}
