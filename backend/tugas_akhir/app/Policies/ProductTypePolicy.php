<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\ProductType;
use Illuminate\Auth\Access\HandlesAuthorization;

class ProductTypePolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:ProductType');
    }

    public function view(AuthUser $authUser, ProductType $productType): bool
    {
        return $authUser->can('View:ProductType');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:ProductType');
    }

    public function update(AuthUser $authUser, ProductType $productType): bool
    {
        return $authUser->can('Update:ProductType');
    }

    public function delete(AuthUser $authUser, ProductType $productType): bool
    {
        return $authUser->can('Delete:ProductType');
    }

}