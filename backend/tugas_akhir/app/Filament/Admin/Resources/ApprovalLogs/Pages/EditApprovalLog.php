<?php

namespace App\Filament\Admin\Resources\ApprovalLogs\Pages;

use App\Filament\Admin\Resources\ApprovalLogs\ApprovalLogResource;
use Filament\Actions\DeleteAction;
use Filament\Actions\ViewAction;
use Filament\Resources\Pages\EditRecord;

class EditApprovalLog extends EditRecord
{
    protected static string $resource = ApprovalLogResource::class;

    protected function getHeaderActions(): array
    {
        return [
            ViewAction::make(),
            DeleteAction::make(),
        ];
    }
}
