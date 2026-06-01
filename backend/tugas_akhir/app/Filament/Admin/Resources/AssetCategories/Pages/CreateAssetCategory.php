<?php

namespace App\Filament\Admin\Resources\AssetCategories\Pages;

use App\Filament\Admin\Resources\AssetCategories\AssetCategoryResource;
use Filament\Resources\Pages\CreateRecord;
use Filament\Support\Enums\Width;
use App\Services\AssetCodeService;

class CreateAssetCategory extends CreateRecord
{
    protected static string $resource = AssetCategoryResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        if (empty($data['code'])) {
            $data['code'] = app(AssetCodeService::class)->nextAssetCategoryCode();
        }

        return $data;
    }
}