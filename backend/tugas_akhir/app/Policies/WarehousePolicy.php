<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\Warehouse;
use Illuminate\Auth\Access\HandlesAuthorization;

class WarehousePolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:Warehouse');
    }

    public function view(AuthUser $authUser, Warehouse $warehouse): bool
    {
        return $authUser->can('View:Warehouse');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:Warehouse');
    }

    public function update(AuthUser $authUser, Warehouse $warehouse): bool
    {
        return $authUser->can('Update:Warehouse');
    }

    public function delete(AuthUser $authUser, Warehouse $warehouse): bool
    {
        return $authUser->can('Delete:Warehouse');
    }

}