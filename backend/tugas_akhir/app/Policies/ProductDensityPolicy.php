<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\ProductDensity;
use Illuminate\Auth\Access\HandlesAuthorization;

class ProductDensityPolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:ProductDensity');
    }

    public function view(AuthUser $authUser, ProductDensity $productDensity): bool
    {
        return $authUser->can('View:ProductDensity');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:ProductDensity');
    }

    public function update(AuthUser $authUser, ProductDensity $productDensity): bool
    {
        return $authUser->can('Update:ProductDensity');
    }

    public function delete(AuthUser $authUser, ProductDensity $productDensity): bool
    {
        return $authUser->can('Delete:ProductDensity');
    }

}