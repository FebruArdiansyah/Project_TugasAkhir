<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\InboundTransaction;
use Illuminate\Auth\Access\HandlesAuthorization;

class InboundTransactionPolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:InboundTransaction');
    }

    public function view(AuthUser $authUser, InboundTransaction $inboundTransaction): bool
    {
        return $authUser->can('View:InboundTransaction');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:InboundTransaction');
    }

    public function update(AuthUser $authUser, InboundTransaction $inboundTransaction): bool
    {
        return $authUser->can('Update:InboundTransaction');
    }

    public function delete(AuthUser $authUser, InboundTransaction $inboundTransaction): bool
    {
        return $authUser->can('Delete:InboundTransaction');
    }

}