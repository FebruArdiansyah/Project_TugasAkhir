<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\AssetCategory;
use Illuminate\Auth\Access\HandlesAuthorization;

class AssetCategoryPolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:AssetCategory');
    }

    public function view(AuthUser $authUser, AssetCategory $assetCategory): bool
    {
        return $authUser->can('View:AssetCategory');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:AssetCategory');
    }

    public function update(AuthUser $authUser, AssetCategory $assetCategory): bool
    {
        return $authUser->can('Update:AssetCategory');
    }

    public function delete(AuthUser $authUser, AssetCategory $assetCategory): bool
    {
        return $authUser->can('Delete:AssetCategory');
    }

}