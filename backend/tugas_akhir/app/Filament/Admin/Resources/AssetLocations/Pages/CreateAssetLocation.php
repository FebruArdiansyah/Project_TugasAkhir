<?php

namespace App\Filament\Admin\Resources\AssetLocations\Pages;

use App\Filament\Admin\Resources\AssetLocations\AssetLocationResource;
use Filament\Resources\Pages\CreateRecord;
use Filament\Support\Enums\Width;
use App\Services\AssetCodeService;

class CreateAssetLocation extends CreateRecord
{
    protected static string $resource = AssetLocationResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;
    protected function mutateFormDataBeforeCreate(array $data): array
    {
        if (empty($data['code'])) {
            $data['code'] = app(AssetCodeService::class)->nextAssetLocationCode();
        }

        return $data;
    }
}