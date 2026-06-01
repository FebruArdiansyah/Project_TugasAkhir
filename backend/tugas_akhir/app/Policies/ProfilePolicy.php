<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\Profile;
use Illuminate\Auth\Access\HandlesAuthorization;

class ProfilePolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:Profile');
    }

    public function view(AuthUser $authUser, Profile $profile): bool
    {
        return $authUser->can('View:Profile');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:Profile');
    }

    public function update(AuthUser $authUser, Profile $profile): bool
    {
        return $authUser->can('Update:Profile');
    }

    public function delete(AuthUser $authUser, Profile $profile): bool
    {
        return $authUser->can('Delete:Profile');
    }

}