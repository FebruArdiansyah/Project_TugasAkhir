<?php

namespace App\Filament\Admin\Resources\OutboundTransactions;

use App\Filament\Admin\Resources\OutboundTransactions\Pages\CreateOutboundTransaction;
use App\Filament\Admin\Resources\OutboundTransactions\Pages\EditOutboundTransaction;
use App\Filament\Admin\Resources\OutboundTransactions\Pages\ListOutboundTransactions;
use App\Filament\Admin\Resources\OutboundTransactions\Pages\ViewOutboundTransaction;
use App\Filament\Admin\Resources\OutboundTransactions\Schemas\OutboundTransactionForm;
use App\Filament\Admin\Resources\OutboundTransactions\Schemas\OutboundTransactionInfolist;
use App\Filament\Admin\Resources\OutboundTransactions\Tables\OutboundTransactionsTable;
use App\Models\OutboundTransaction;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class OutboundTransactionResource extends Resource
{
    protected static ?string $model = OutboundTransaction::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedArrowUpTray;

    protected static ?string $navigationLabel = 'Barang Keluar';

    protected static ?string $modelLabel = 'Barang Keluar';

    protected static ?string $pluralModelLabel = 'Barang Keluar';

    protected static string|\UnitEnum|null $navigationGroup = 'Transaksi Inventory';

    protected static ?int $navigationSort = 20;

    protected static ?string $recordTitleAttribute = 'transaction_number';

    public static function form(Schema $schema): Schema
    {
        return OutboundTransactionForm::configure($schema);
    }

    public static function infolist(Schema $schema): Schema
    {
        return OutboundTransactionInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return OutboundTransactionsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListOutboundTransactions::route('/'),
            'create' => CreateOutboundTransaction::route('/create'),
            'view' => ViewOutboundTransaction::route('/{record}'),
            'edit' => EditOutboundTransaction::route('/{record}/edit'),
        ];
    }
}