<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\StockBalance;
use Illuminate\Auth\Access\HandlesAuthorization;

class StockBalancePolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:StockBalance');
    }

    public function view(AuthUser $authUser, StockBalance $stockBalance): bool
    {
        return $authUser->can('View:StockBalance');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:StockBalance');
    }

    public function update(AuthUser $authUser, StockBalance $stockBalance): bool
    {
        return $authUser->can('Update:StockBalance');
    }

    public function delete(AuthUser $authUser, StockBalance $stockBalance): bool
    {
        return $authUser->can('Delete:StockBalance');
    }

}