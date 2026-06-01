<?php

namespace App\Filament\Admin\Resources\Assets\Pages;

use App\Filament\Admin\Resources\Assets\AssetResource;
use Filament\Resources\Pages\CreateRecord;
use Filament\Support\Enums\Width;
use App\Services\AssetCodeService;

class CreateAsset extends CreateRecord
{
    protected static string $resource = AssetResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        if (empty($data['asset_code'])) {
            $data['asset_code'] = app(AssetCodeService::class)->nextAssetCode();
        }

        $data['created_by'] = auth()->id();

        return $data;
    }
}