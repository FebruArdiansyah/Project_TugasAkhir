<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AssetImportLog extends Model
{
    protected $fillable = [
        'file_name',
        'total_rows',
        'imported_rows',
        'skipped_rows',
        'status',
        'message',
        'error_message',
        'imported_by',
        'started_at',
        'finished_at',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'finished_at' => 'datetime',
    ];
}