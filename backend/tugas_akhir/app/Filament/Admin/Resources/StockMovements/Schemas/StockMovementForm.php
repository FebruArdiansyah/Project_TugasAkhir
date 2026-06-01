<?php

namespace App\Filament\Admin\Resources\StockMovements\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Schemas\Schema;

class StockMovementForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('movement_number')
                    ->required(),
                Select::make('product_id')
                    ->relationship('product', 'name')
                    ->required(),
                Select::make('warehouse_id')
                    ->relationship('warehouse', 'name')
                    ->required(),
                TextInput::make('movement_type')
                    ->required(),
                TextInput::make('reference_type')
                    ->default(null),
                TextInput::make('reference_id')
                    ->numeric()
                    ->default(null),
                TextInput::make('qty_in')
                    ->required()
                    ->numeric()
                    ->default(0.0),
                TextInput::make('qty_out')
                    ->required()
                    ->numeric()
                    ->default(0.0),
                TextInput::make('stock_before')
                    ->required()
                    ->numeric()
                    ->default(0.0),
                TextInput::make('stock_after')
                    ->required()
                    ->numeric()
                    ->default(0.0),
                Textarea::make('description')
                    ->default(null)
                    ->columnSpanFull(),
                TextInput::make('created_by')
                    ->numeric()
                    ->default(null),
            ]);
    }
}
