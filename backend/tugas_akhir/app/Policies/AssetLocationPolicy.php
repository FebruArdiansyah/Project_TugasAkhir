<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\AssetLocation;
use Illuminate\Auth\Access\HandlesAuthorization;

class AssetLocationPolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:AssetLocation');
    }

    public function view(AuthUser $authUser, AssetLocation $assetLocation): bool
    {
        return $authUser->can('View:AssetLocation');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:AssetLocation');
    }

    public function update(AuthUser $authUser, AssetLocation $assetLocation): bool
    {
        return $authUser->can('Update:AssetLocation');
    }

    public function delete(AuthUser $authUser, AssetLocation $assetLocation): bool
    {
        return $authUser->can('Delete:AssetLocation');
    }

}