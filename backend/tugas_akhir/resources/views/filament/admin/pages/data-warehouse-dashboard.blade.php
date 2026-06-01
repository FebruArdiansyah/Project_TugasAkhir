<x-filament-panels::page>
    <style>
        .dw-page {
            display: flex;
            flex-direction: column;
            gap: 1.5rem;
        }

        .dw-hero {
            position: relative;
            overflow: hidden;
            border-radius: 28px;
            border: 1px solid rgba(148, 163, 184, .25);
            background:
                radial-gradient(circle at top left, rgba(59, 130, 246, .20), transparent 36%),
                radial-gradient(circle at bottom right, rgba(16, 185, 129, .18), transparent 32%),
                linear-gradient(135deg, #ffffff, #f8fafc);
            padding: 28px;
            box-shadow: 0 18px 45px rgba(15, 23, 42, .08);
        }

        .dw-hero-inner {
            position: relative;
            z-index: 2;
            display: grid;
            grid-template-columns: minmax(0, 1fr) auto;
            gap: 24px;
            align-items: center;
        }

        .dw-badge {
            display: inline-flex;
            width: fit-content;
            align-items: center;
            gap: 8px;
            border-radius: 999px;
            background: rgba(37, 99, 235, .10);
            color: #1d4ed8;
            padding: 7px 12px;
            font-size: 12px;
            font-weight: 700;
            letter-spacing: .02em;
        }

        .dw-title {
            margin-top: 14px;
            font-size: 30px;
            line-height: 1.15;
            font-weight: 900;
            color: #0f172a;
        }

        .dw-description {
            margin-top: 10px;
            max-width: 760px;
            color: #64748b;
            font-size: 14px;
            line-height: 1.7;
        }

        .dw-meta {
            margin-top: 18px;
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
        }

        .dw-meta-item {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            border-radius: 14px;
            background: rgba(255, 255, 255, .78);
            border: 1px solid rgba(226, 232, 240, .9);
            padding: 10px 12px;
            color: #334155;
            font-size: 13px;
            font-weight: 600;
            box-shadow: 0 8px 24px rgba(15, 23, 42, .05);
        }

        .dw-actions {
            display: flex;
            flex-direction: column;
            gap: 10px;
            min-width: 220px;
        }

        .dw-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            border: 0;
            border-radius: 16px;
            padding: 12px 16px;
            font-size: 14px;
            font-weight: 800;
            cursor: pointer;
            transition: transform .18s ease, box-shadow .18s ease, opacity .18s ease;
        }

        .dw-btn:hover {
            transform: translateY(-1px);
        }

        .dw-btn:disabled {
            opacity: .65;
            cursor: wait;
        }

        .dw-btn-primary {
            color: #ffffff;
            background: linear-gradient(135deg, #2563eb, #1d4ed8);
            box-shadow: 0 14px 28px rgba(37, 99, 235, .28);
        }

        .dw-btn-secondary {
            color: #334155;
            background: #ffffff;
            border: 1px solid #e2e8f0;
            box-shadow: 0 10px 24px rgba(15, 23, 42, .06);
        }

        .dw-filter-card {
            border-radius: 24px;
            border: 1px solid rgba(226, 232, 240, .95);
            background: #ffffff;
            padding: 22px;
            box-shadow: 0 12px 34px rgba(15, 23, 42, .06);
        }

        .dw-filter-header {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 16px;
            margin-bottom: 18px;
        }

        .dw-section-title {
            font-size: 18px;
            font-weight: 900;
            color: #0f172a;
        }

        .dw-section-subtitle {
            margin-top: 4px;
            font-size: 13px;
            color: #64748b;
        }

        .dw-active-filter {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            justify-content: flex-end;
        }

        .dw-chip {
            display: inline-flex;
            align-items: center;
            border-radius: 999px;
            background: #eff6ff;
            color: #1d4ed8;
            padding: 7px 11px;
            font-size: 12px;
            font-weight: 800;
        }

        .dw-filter-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 16px;
        }

        .dw-field {
            border-radius: 18px;
            border: 1px solid #e2e8f0;
            background: #f8fafc;
            padding: 14px;
        }

        .dw-label {
            display: block;
            margin-bottom: 8px;
            color: #334155;
            font-size: 13px;
            font-weight: 800;
        }

        .dw-select {
            width: 100%;
            border-radius: 14px;
            border: 1px solid #cbd5e1;
            background: #ffffff;
            padding: 11px 12px;
            color: #0f172a;
            font-size: 14px;
            font-weight: 700;
            outline: none;
            transition: border-color .18s ease, box-shadow .18s ease;
        }

        .dw-select:focus {
            border-color: #2563eb;
            box-shadow: 0 0 0 4px rgba(37, 99, 235, .12);
        }

        .dw-widget-wrap {
            border-radius: 24px;
            overflow: hidden;
        }

        .dark .dw-hero {
            border-color: rgba(51, 65, 85, .8);
            background:
                radial-gradient(circle at top left, rgba(59, 130, 246, .24), transparent 36%),
                radial-gradient(circle at bottom right, rgba(16, 185, 129, .20), transparent 32%),
                linear-gradient(135deg, #0f172a, #111827);
        }

        .dark .dw-title,
        .dark .dw-section-title {
            color: #f8fafc;
        }

        .dark .dw-description,
        .dark .dw-section-subtitle {
            color: #94a3b8;
        }

        .dark .dw-meta-item,
        .dark .dw-filter-card {
            background: #111827;
            border-color: #334155;
            color: #e5e7eb;
        }

        .dark .dw-btn-secondary {
            background: #0f172a;
            border-color: #334155;
            color: #e5e7eb;
        }

        .dark .dw-field {
            background: #0f172a;
            border-color: #334155;
        }

        .dark .dw-label {
            color: #e5e7eb;
        }

        .dark .dw-select {
            background: #111827;
            border-color: #334155;
            color: #f8fafc;
        }

        @media (max-width: 1024px) {
            .dw-hero-inner {
                grid-template-columns: 1fr;
            }

            .dw-actions {
                min-width: 0;
                flex-direction: row;
                flex-wrap: wrap;
            }

            .dw-btn {
                flex: 1;
            }
        }

        @media (max-width: 768px) {
            .dw-filter-grid {
                grid-template-columns: 1fr;
            }

            .dw-filter-header {
                flex-direction: column;
            }

            .dw-active-filter {
                justify-content: flex-start;
            }

            .dw-title {
                font-size: 24px;
            }
        }
    </style>

    <div class="dw-page">
        <section class="dw-hero">
            <div class="dw-hero-inner">
                <div>
                    <span class="dw-badge">
                        📊 Data Warehouse Analytics
                    </span>

                    <h2 class="dw-title">
                        Dashboard Analitik Data Warehouse
                    </h2>

                    <p class="dw-description">
                        Pantau performa inventory dari tabel <strong>dw_*</strong>. Data di halaman ini berasal dari proses ETL,
                        bukan langsung dari tabel operasional, sehingga lebih cocok untuk analisis dan laporan manajemen.
                    </p>

                    <div class="dw-meta">
                        <span class="dw-meta-item">
                            ⚙️ Auto sync setiap 5 menit
                        </span>

                        <span class="dw-meta-item">
                            🧭 Periode: {{ $this->getPeriodLabel() }}
                        </span>

                        <span class="dw-meta-item">
                            🏭 Gudang: {{ $this->getWarehouseLabel() }}
                        </span>
                    </div>
                </div>

                <div class="dw-actions">
                    <button
                        type="button"
                        wire:click="syncNow"
                        wire:loading.attr="disabled"
                        wire:target="syncNow"
                        class="dw-btn dw-btn-primary"
                    >
                        <span wire:loading.remove wire:target="syncNow">🔄 Sync DW Sekarang</span>
                        <span wire:loading wire:target="syncNow">Memproses Sync...</span>
                    </button>

                    <button
                        type="button"
                        wire:click="resetFilters"
                        class="dw-btn dw-btn-secondary"
                    >
                        ↩ Reset Filter
                    </button>
                </div>
            </div>
        </section>

        <section class="dw-filter-card">
            <div class="dw-filter-header">
                <div>
                    <h3 class="dw-section-title">
                        Filter Analitik
                    </h3>

                    <p class="dw-section-subtitle">
                        Gunakan filter untuk melihat ringkasan berdasarkan periode dan gudang tertentu.
                    </p>
                </div>

                <div class="dw-active-filter">
                    <span class="dw-chip">
                        {{ $this->getPeriodLabel() }}
                    </span>

                    <span class="dw-chip">
                        {{ $this->getWarehouseLabel() }}
                    </span>
                </div>
            </div>

            <div class="dw-filter-grid">
                <div class="dw-field">
                    <label class="dw-label">
                        Periode Analitik
                    </label>

                    <select wire:model.live="period" class="dw-select">
                        <option value="day">Hari ini</option>
                        <option value="week">Minggu ini</option>
                        <option value="month">Bulan ini</option>
                        <option value="year">Tahun ini</option>
                        <option value="all">Semua Data</option>
                    </select>
                </div>

                <div class="dw-field">
                    <label class="dw-label">
                        Gudang
                    </label>

                    <select wire:model.live="warehouseId" class="dw-select">
                        <option value="">Semua Gudang</option>

                        @foreach ($this->getWarehouses() as $id => $name)
                            <option value="{{ $id }}">
                                {{ $name }}
                            </option>
                        @endforeach
                    </select>
                </div>
            </div>
        </section>

        <div class="dw-widget-wrap">
            @livewire(
                \App\Filament\Admin\Widgets\DataWarehouseOverviewWidget::class,
                [
                    'period' => $period,
                    'warehouseId' => $warehouseId,
                ],
                key('dw-overview-' . $period . '-' . $warehouseId)
            )
        </div>
    </div>
</x-filament-panels::page>