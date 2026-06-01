<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\ProductCategory;
use Illuminate\Auth\Access\HandlesAuthorization;

class ProductCategoryPolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:ProductCategory');
    }

    public function view(AuthUser $authUser, ProductCategory $productCategory): bool
    {
        return $authUser->can('View:ProductCategory');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:ProductCategory');
    }

    public function update(AuthUser $authUser, ProductCategory $productCategory): bool
    {
        return $authUser->can('Update:ProductCategory');
    }

    public function delete(AuthUser $authUser, ProductCategory $productCategory): bool
    {
        return $authUser->can('Delete:ProductCategory');
    }

}