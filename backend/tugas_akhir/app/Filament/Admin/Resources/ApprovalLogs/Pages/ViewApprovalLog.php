<?php

namespace App\Filament\Admin\Resources\ApprovalLogs\Pages;

use App\Filament\Admin\Resources\ApprovalLogs\ApprovalLogResource;
use Filament\Resources\Pages\ViewRecord;
use Filament\Support\Enums\Width;

class ViewApprovalLog extends ViewRecord
{
    protected static string $resource = ApprovalLogResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;
}