<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\OutboundTransaction;
use Illuminate\Auth\Access\HandlesAuthorization;

class OutboundTransactionPolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:OutboundTransaction');
    }

    public function view(AuthUser $authUser, OutboundTransaction $outboundTransaction): bool
    {
        return $authUser->can('View:OutboundTransaction');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:OutboundTransaction');
    }

    public function update(AuthUser $authUser, OutboundTransaction $outboundTransaction): bool
    {
        return $authUser->can('Update:OutboundTransaction');
    }

    public function delete(AuthUser $authUser, OutboundTransaction $outboundTransaction): bool
    {
        return $authUser->can('Delete:OutboundTransaction');
    }

}