<?php

namespace App\Filament\Admin\Resources\Profiles;

use App\Filament\Admin\Resources\Profiles\Pages\CreateProfile;
use App\Filament\Admin\Resources\Profiles\Pages\EditProfile;
use App\Filament\Admin\Resources\Profiles\Pages\ListProfiles;
use App\Filament\Admin\Resources\Profiles\Pages\ViewProfile;
use App\Filament\Admin\Resources\Profiles\Schemas\ProfileForm;
use App\Filament\Admin\Resources\Profiles\Schemas\ProfileInfolist;
use App\Filament\Admin\Resources\Profiles\Tables\ProfilesTable;
use App\Models\Profile;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class ProfileResource extends Resource
{
    protected static ?string $model = Profile::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedUserCircle;

    protected static ?string $navigationLabel = 'Profile Staff';

    protected static ?string $modelLabel = 'Profile Staff';

    protected static ?string $pluralModelLabel = 'Profile Staff';

    protected static string|\UnitEnum|null $navigationGroup = 'Master Data';

    protected static ?int $navigationSort = 90;

    protected static ?string $recordTitleAttribute = 'username';

    public static function form(Schema $schema): Schema
    {
        return ProfileForm::configure($schema);
    }

    public static function infolist(Schema $schema): Schema
    {
        return ProfileInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return ProfilesTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListProfiles::route('/'),
            'create' => CreateProfile::route('/create'),
            'view' => ViewProfile::route('/{record}'),
            'edit' => EditProfile::route('/{record}/edit'),
        ];
    }
}