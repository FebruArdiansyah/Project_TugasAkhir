<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\ApprovalLog;
use Illuminate\Auth\Access\HandlesAuthorization;

class ApprovalLogPolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:ApprovalLog');
    }

    public function view(AuthUser $authUser, ApprovalLog $approvalLog): bool
    {
        return $authUser->can('View:ApprovalLog');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:ApprovalLog');
    }

    public function update(AuthUser $authUser, ApprovalLog $approvalLog): bool
    {
        return $authUser->can('Update:ApprovalLog');
    }

    public function delete(AuthUser $authUser, ApprovalLog $approvalLog): bool
    {
        return $authUser->can('Delete:ApprovalLog');
    }

}