<?php

namespace App\Filament\Admin\Resources\Profiles\Pages;

use App\Filament\Admin\Resources\Profiles\ProfileResource;
use Filament\Resources\Pages\CreateRecord;
use Filament\Support\Enums\Width;

class CreateProfile extends CreateRecord
{
    protected static string $resource = ProfileResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;
}