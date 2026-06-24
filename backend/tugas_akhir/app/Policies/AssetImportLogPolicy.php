<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\AssetImportLog;
use Illuminate\Auth\Access\HandlesAuthorization;

class AssetImportLogPolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:AssetImportLog');
    }

    public function view(AuthUser $authUser, AssetImportLog $assetImportLog): bool
    {
        return $authUser->can('View:AssetImportLog');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:AssetImportLog');
    }

    public function update(AuthUser $authUser, AssetImportLog $assetImportLog): bool
    {
        return $authUser->can('Update:AssetImportLog');
    }

    public function delete(AuthUser $authUser, AssetImportLog $assetImportLog): bool
    {
        return $authUser->can('Delete:AssetImportLog');
    }

}