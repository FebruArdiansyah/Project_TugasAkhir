<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class InventoryImportLog extends Model
{
    protected $fillable = [
        'file_name',
        'transaction_type',
        'import_mode',
        'total_rows',
        'imported_rows',
        'skipped_rows',
        'status',
        'message',
        'error_message',
        'warehouse_id',
        'imported_by',
        'started_at',
        'finished_at',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'finished_at' => 'datetime',
    ];
}