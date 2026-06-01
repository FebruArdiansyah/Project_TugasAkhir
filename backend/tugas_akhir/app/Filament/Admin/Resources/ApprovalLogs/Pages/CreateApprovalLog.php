<?php

namespace App\Filament\Admin\Resources\ApprovalLogs\Pages;

use App\Filament\Admin\Resources\ApprovalLogs\ApprovalLogResource;
use Filament\Resources\Pages\CreateRecord;

class CreateApprovalLog extends CreateRecord
{
    protected static string $resource = ApprovalLogResource::class;
}
