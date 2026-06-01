<?php

namespace App\Filament\Admin\Resources\ApprovalLogs;

use App\Filament\Admin\Resources\ApprovalLogs\Pages\ListApprovalLogs;
use App\Filament\Admin\Resources\ApprovalLogs\Pages\ViewApprovalLog;
use App\Filament\Admin\Resources\ApprovalLogs\Schemas\ApprovalLogInfolist;
use App\Filament\Admin\Resources\ApprovalLogs\Tables\ApprovalLogsTable;
use App\Models\ApprovalLog;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class ApprovalLogResource extends Resource
{
    protected static ?string $model = ApprovalLog::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedRectangleStack;

    protected static ?string $navigationLabel = 'Approval Logs';

    protected static ?string $modelLabel = 'Approval Log';

    protected static ?string $pluralModelLabel = 'Approval Logs';

    protected static string|\UnitEnum|null $navigationGroup = 'Transaksi Inventory';

    protected static ?int $navigationSort = 30;

    protected static ?string $recordTitleAttribute = 'action';

    public static function infolist(Schema $schema): Schema
    {
        return ApprovalLogInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return ApprovalLogsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListApprovalLogs::route('/'),
            'view' => ViewApprovalLog::route('/{record}'),
        ];
    }
}