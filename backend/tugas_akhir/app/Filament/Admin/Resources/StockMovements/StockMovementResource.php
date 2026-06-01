<?php

namespace App\Filament\Admin\Resources\StockMovements;

use App\Filament\Admin\Resources\StockMovements\Pages\ListStockMovements;
use App\Filament\Admin\Resources\StockMovements\Pages\ViewStockMovement;
use App\Filament\Admin\Resources\StockMovements\Schemas\StockMovementInfolist;
use App\Filament\Admin\Resources\StockMovements\Tables\StockMovementsTable;
use App\Models\StockMovement;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class StockMovementResource extends Resource
{
    protected static ?string $model = StockMovement::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedArrowPath;

    protected static ?string $navigationLabel = 'Mutasi Stok';

    protected static ?string $modelLabel = 'Mutasi Stok';

    protected static ?string $pluralModelLabel = 'Mutasi Stok';

    protected static string|\UnitEnum|null $navigationGroup = 'Inventory Management';

    protected static ?int $navigationSort = 30;

    protected static ?string $recordTitleAttribute = 'movement_number';

    public static function infolist(Schema $schema): Schema
    {
        return StockMovementInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return StockMovementsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListStockMovements::route('/'),
            'view' => ViewStockMovement::route('/{record}'),
        ];
    }
}