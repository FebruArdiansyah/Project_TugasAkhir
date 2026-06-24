<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\InventoryImportLog;
use Illuminate\Auth\Access\HandlesAuthorization;

class InventoryImportLogPolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:InventoryImportLog');
    }

    public function view(AuthUser $authUser, InventoryImportLog $inventoryImportLog): bool
    {
        return $authUser->can('View:InventoryImportLog');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:InventoryImportLog');
    }

    public function update(AuthUser $authUser, InventoryImportLog $inventoryImportLog): bool
    {
        return $authUser->can('Update:InventoryImportLog');
    }

    public function delete(AuthUser $authUser, InventoryImportLog $inventoryImportLog): bool
    {
        return $authUser->can('Delete:InventoryImportLog');
    }

}