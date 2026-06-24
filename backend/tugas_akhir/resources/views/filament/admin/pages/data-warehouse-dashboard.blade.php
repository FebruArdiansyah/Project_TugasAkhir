<x-filament-panels::page>
    <style>
        .dw-page {
            width: 100%;
            max-width: 1280px;
            margin: 0 auto;
            display: flex;
            flex-direction: column;
            gap: 28px;
            padding: 14px 12px 44px;
            overflow: visible;
        }

        .dw-hero {
            position: relative;
            overflow: visible;
            border-radius: 24px;
            border: 1px solid rgba(148, 163, 184, .28);
            background:
                radial-gradient(circle at top left, rgba(59, 130, 246, .18), transparent 36%),
                radial-gradient(circle at bottom right, rgba(16, 185, 129, .16), transparent 34%),
                linear-gradient(135deg, #ffffff, #f8fafc);
            padding: 24px;
            box-shadow: 0 14px 34px rgba(15, 23, 42, .07);
        }

        .dw-hero-inner {
            display: grid;
            grid-template-columns: minmax(0, 1fr) 210px;
            gap: 24px;
            align-items: center;
        }

        .dw-badge,
        .dw-section-kicker {
            display: inline-flex;
            width: fit-content;
            align-items: center;
            gap: 8px;
            border-radius: 999px;
            background: #eff6ff;
            color: #1d4ed8;
            padding: 7px 12px;
            font-size: 12px;
            font-weight: 900;
            letter-spacing: .02em;
        }

        .dw-title {
            margin-top: 14px;
            font-size: 28px;
            line-height: 1.2;
            font-weight: 900;
            color: #0f172a;
        }

        .dw-description {
            margin-top: 10px;
            max-width: 760px;
            color: #64748b;
            font-size: 14px;
            line-height: 1.65;
        }

        .dw-meta {
            margin-top: 18px;
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
        }

        .dw-meta-item,
        .dw-chip {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            border-radius: 999px;
            background: rgba(255, 255, 255, .82);
            border: 1px solid rgba(226, 232, 240, .9);
            padding: 9px 12px;
            color: #334155;
            font-size: 12px;
            font-weight: 800;
            box-shadow: 0 8px 20px rgba(15, 23, 42, .04);
            white-space: nowrap;
        }

        .dw-chip {
            background: #eff6ff;
            color: #1d4ed8;
            border-color: #dbeafe;
            box-shadow: none;
        }

        .dw-actions {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .dw-btn {
            width: 100%;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            border-radius: 14px;
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
            border: 0;
            background: linear-gradient(135deg, #2563eb, #1d4ed8);
            box-shadow: 0 12px 24px rgba(37, 99, 235, .26);
        }

        .dw-btn-secondary {
            color: #334155;
            background: #ffffff;
            border: 1px solid #e2e8f0;
            box-shadow: 0 8px 20px rgba(15, 23, 42, .05);
        }

        .dw-section-block {
            display: flex;
            flex-direction: column;
            gap: 16px;
            padding: 2px 0;
            overflow: visible;
        }

        .dw-section-heading {
            display: flex;
            align-items: flex-end;
            justify-content: space-between;
            gap: 16px;
            padding-left: 2px;
            padding-right: 2px;
        }

        .dw-section-heading-main {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .dw-section-title {
            margin: 0;
            font-size: 20px;
            font-weight: 900;
            color: #0f172a;
        }

        .dw-section-subtitle,
        .dw-section-caption {
            margin: 0;
            color: #64748b;
            font-size: 13px;
            line-height: 1.6;
        }

        .dw-filter-card {
            border-radius: 24px;
            border: 1px solid rgba(226, 232, 240, .95);
            background: #ffffff;
            padding: 22px;
            box-shadow: 0 12px 30px rgba(15, 23, 42, .06);
            overflow: visible;
        }

        .dw-filter-header {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 16px;
            margin-bottom: 18px;
        }

        .dw-active-filter {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            justify-content: flex-end;
        }

        .dw-filter-grid-calendar {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 16px;
            align-items: stretch;
        }

        .dw-chart-filter-grid {
            display: grid;
            grid-template-columns: 260px 1fr;
            gap: 16px;
            align-items: stretch;
        }

        .dw-source-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 16px;
            align-items: stretch;
        }

        .dw-field {
            border-radius: 18px;
            border: 1px solid #e2e8f0;
            background: #f8fafc;
            padding: 14px;
        }

        .dw-label {
            display: block;
            margin-bottom: 10px;
            color: #334155;
            font-size: 13px;
            font-weight: 800;
        }

        .dw-select,
        .dw-input {
            width: 100%;
            height: 46px;
            border-radius: 14px;
            border: 1px solid #cbd5e1;
            background-color: #ffffff;
            color: #0f172a;
            font-size: 14px;
            font-weight: 700;
            outline: none;
            transition: border-color .18s ease, box-shadow .18s ease, background-color .18s ease;
        }

        .dw-select {
            appearance: none;
            padding: 0 42px 0 14px;
            background-image:
                linear-gradient(45deg, transparent 50%, #64748b 50%),
                linear-gradient(135deg, #64748b 50%, transparent 50%);
            background-position:
                calc(100% - 20px) 19px,
                calc(100% - 15px) 19px;
            background-size: 5px 5px, 5px 5px;
            background-repeat: no-repeat;
        }

        .dw-input {
            padding: 0 14px;
        }

        .dw-select:focus,
        .dw-input:focus {
            border-color: #2563eb;
            box-shadow: 0 0 0 4px rgba(37, 99, 235, .12);
        }

        .dw-filter-actions {
            display: flex;
            gap: 10px;
            margin-top: 16px;
            justify-content: flex-end;
            flex-wrap: wrap;
        }

        .dw-small-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            border-radius: 12px;
            border: 1px solid #dbeafe;
            background: #eff6ff;
            color: #1d4ed8;
            padding: 9px 13px;
            font-size: 13px;
            font-weight: 800;
            cursor: pointer;
            transition: all .18s ease;
        }

        .dw-small-btn:hover {
            background: #dbeafe;
            transform: translateY(-1px);
        }

        .dw-widget-wrap {
            border-radius: 24px;
            overflow: visible;
            padding: 4px;
        }

        .dw-widget-wrap > * {
            overflow: visible !important;
        }

        .dw-chart-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 24px;
            align-items: start;
        }

        .dw-source-list {
            margin: 0;
            color: #475569;
            font-size: 13px;
            line-height: 1.7;
        }

        .dark .dw-hero {
            border-color: rgba(51, 65, 85, .8);
            background:
                radial-gradient(circle at top left, rgba(59, 130, 246, .24), transparent 36%),
                radial-gradient(circle at bottom right, rgba(16, 185, 129, .20), transparent 34%),
                linear-gradient(135deg, #0f172a, #111827);
        }

        .dark .dw-title,
        .dark .dw-section-title {
            color: #f8fafc;
        }

        .dark .dw-description,
        .dark .dw-section-subtitle,
        .dark .dw-section-caption,
        .dark .dw-source-list {
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

        .dark .dw-chip,
        .dark .dw-section-kicker,
        .dark .dw-badge {
            background: rgba(37, 99, 235, .18);
            color: #bfdbfe;
            border-color: #1d4ed8;
        }

        .dark .dw-select,
        .dark .dw-input {
            background-color: #111827;
            border-color: #334155;
            color: #f8fafc;
        }

        .dark .dw-small-btn {
            background: rgba(37, 99, 235, .18);
            border-color: #1d4ed8;
            color: #bfdbfe;
        }

        .dark .dw-small-btn:hover {
            background: rgba(37, 99, 235, .28);
        }

        @media (max-width: 1200px) {
            .dw-filter-grid-calendar,
            .dw-source-grid {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
        }

        @media (max-width: 1024px) {
            .dw-page {
                max-width: 100%;
            }

            .dw-hero-inner {
                grid-template-columns: 1fr;
            }

            .dw-actions {
                flex-direction: row;
                flex-wrap: wrap;
            }

            .dw-btn {
                flex: 1;
                min-width: 180px;
            }

            .dw-chart-filter-grid {
                grid-template-columns: 1fr;
            }
        }

        @media (max-width: 768px) {
            .dw-page {
                padding-left: 4px;
                padding-right: 4px;
            }

            .dw-hero {
                padding: 20px;
                border-radius: 20px;
            }

            .dw-title {
                font-size: 24px;
            }

            .dw-filter-header,
            .dw-section-heading {
                flex-direction: column;
                align-items: flex-start;
            }

            .dw-active-filter {
                justify-content: flex-start;
            }

            .dw-filter-grid-calendar,
            .dw-source-grid {
                grid-template-columns: 1fr;
            }

            .dw-actions {
                flex-direction: column;
            }

            .dw-btn {
                min-width: 0;
            }

            .dw-filter-actions {
                justify-content: flex-start;
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
                        bukan langsung dari tabel operasional, sehingga lebih cocok untuk analisis historis dan laporan manajemen.
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

                        <span class="dw-meta-item">
                            📦 Produk: {{ $this->getProductLabel() }}
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
                        <span wire:loading.remove wire:target="syncNow">
                            🔄 Sync DW Sekarang
                        </span>

                        <span wire:loading wire:target="syncNow">
                            Memproses Sync...
                        </span>
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

        <section class="dw-section-block">
            <div class="dw-section-heading">
                <div class="dw-section-heading-main">
                    <span class="dw-section-kicker">
                        ETL MONITORING
                    </span>

                    <h3 class="dw-section-title">
                        Informasi Sinkronisasi ETL
                    </h3>

                    <p class="dw-section-caption">
                        Menampilkan waktu sinkronisasi terakhir, status ETL, tanggal data terbaru, dan jumlah baris fact movement
                        yang telah terbentuk pada data warehouse.
                    </p>
                </div>
            </div>

            <div class="dw-widget-wrap">
                @livewire(
                    \App\Filament\Admin\Widgets\DataWarehouseEtlInfoWidget::class,
                    [],
                    key('dw-etl-info')
                )
            </div>
        </section>

        <section class="dw-filter-card">
            <div class="dw-filter-header">
                <div>
                    <h3 class="dw-section-title">
                        Filter Analitik
                    </h3>

                    <p class="dw-section-subtitle">
                        Gunakan dimensi waktu, gudang, produk, dan kategori produk untuk melihat data historis dari berbagai sudut pandang.
                    </p>
                </div>

                <div class="dw-active-filter">
                    <span class="dw-chip">
                        {{ $this->getPeriodLabel() }}
                    </span>

                    <span class="dw-chip">
                        {{ $this->getWarehouseLabel() }}
                    </span>

                    <span class="dw-chip">
                        {{ $this->getProductLabel() }}
                    </span>

                    <span class="dw-chip">
                        {{ $this->getProductCategoryLabel() }}
                    </span>
                </div>
            </div>

            <div class="dw-filter-grid-calendar">
                <div class="dw-field">
                    <label class="dw-label">
                        Periode Cepat
                    </label>

                    <select wire:model.live="period" class="dw-select">
                        @foreach ($this->getPeriodOptions() as $value => $label)
                            <option value="{{ $value }}">
                                {{ $label }}
                            </option>
                        @endforeach
                    </select>
                </div>

                <div class="dw-field">
                    <label class="dw-label">
                        Tanggal Mulai
                    </label>

                    <input
                        type="date"
                        wire:model.live="startDate"
                        class="dw-input"
                    >
                </div>

                <div class="dw-field">
                    <label class="dw-label">
                        Tanggal Selesai
                    </label>

                    <input
                        type="date"
                        wire:model.live="endDate"
                        class="dw-input"
                    >
                </div>

                <div class="dw-field">
                    <label class="dw-label">
                        Gudang
                    </label>

                    <select wire:model.live="warehouseId" class="dw-select">
                        <option value="">
                            Semua Gudang
                        </option>

                        @foreach ($this->getWarehouses() as $id => $name)
                            <option value="{{ $id }}">
                                {{ $name }}
                            </option>
                        @endforeach
                    </select>
                </div>

                <div class="dw-field">
                    <label class="dw-label">
                        Produk
                    </label>

                    <select wire:model.live="productId" class="dw-select">
                        <option value="">
                            Semua Produk
                        </option>

                        @foreach ($this->getProducts() as $id => $name)
                            <option value="{{ $id }}">
                                {{ \Illuminate\Support\Str::limit($name, 70) }}
                            </option>
                        @endforeach
                    </select>
                </div>

                <div class="dw-field">
                    <label class="dw-label">
                        Kategori Produk
                    </label>

                    <select wire:model.live="productCategory" class="dw-select">
                        <option value="">
                            Semua Kategori
                        </option>

                        @foreach ($this->getProductCategories() as $value => $label)
                            <option value="{{ $value }}">
                                {{ $label }}
                            </option>
                        @endforeach
                    </select>
                </div>
            </div>

            <div class="dw-filter-actions">
                <button
                    type="button"
                    wire:click="clearCustomDate"
                    class="dw-small-btn"
                >
                    🗓️ Kosongkan Tanggal
                </button>
            </div>
        </section>

        <section class="dw-section-block">
            <div class="dw-section-heading">
                <div class="dw-section-heading-main">
                    <span class="dw-section-kicker">
                        RINGKASAN DATA WAREHOUSE
                    </span>

                    <h3 class="dw-section-title">
                        Ringkasan Kinerja Persediaan
                    </h3>

                    <p class="dw-section-caption">
                        Ringkasan jumlah produk, gudang, transaksi, nilai transaksi, kuantitas, dan kondisi stok
                        berdasarkan hasil sinkronisasi data warehouse.
                    </p>
                </div>
            </div>

            <div class="dw-widget-wrap">
                @livewire(
                    \App\Filament\Admin\Widgets\DataWarehouseOverviewWidget::class,
                    [
                        'period' => $period,
                        'startDate' => $startDate,
                        'endDate' => $endDate,
                        'warehouseId' => $warehouseId,
                    ],
                    key('dw-overview-' . $period . '-' . $startDate . '-' . $endDate . '-' . $warehouseId)
                )
            </div>
        </section>

        <section class="dw-section-block">
            <div class="dw-section-heading">
                <div class="dw-section-heading-main">
                    <span class="dw-section-kicker">
                        ANALISIS PERGERAKAN STOK
                    </span>

                    <h3 class="dw-section-title">
                        Grafik Analitik Persediaan
                    </h3>

                    <p class="dw-section-caption">
                        Grafik ini menunjukkan tren kuantitas barang masuk dan keluar per bulan serta produk dengan
                        pergerakan keluar tertinggi.
                    </p>
                </div>
            </div>

            <div class="dw-chart-filter-grid">
                <div class="dw-field">
                    <label class="dw-label">
                        Tahun Grafik
                    </label>

                    <select wire:model.live="chartYear" class="dw-select">
                        <option value="">
                            Ikuti Filter Utama
                        </option>

                        @foreach ($this->getChartYearOptions() as $year => $label)
                            <option value="{{ $year }}">
                                {{ $label }}
                            </option>
                        @endforeach
                    </select>
                </div>
            </div>

            <div class="dw-chart-grid">
                <div class="dw-widget-wrap">
                    @livewire(
                        \App\Filament\Admin\Widgets\DataWarehouseMovementTrendChart::class,
                        [
                            'period' => $period,
                            'startDate' => $startDate,
                            'endDate' => $endDate,
                            'warehouseId' => $warehouseId,
                            'chartYear' => $this->chartYear,
                            'productId' => $this->productId,
                            'productCategory' => $this->productCategory,
                        ],
                        key('dw-movement-trend-' . $period . '-' . $startDate . '-' . $endDate . '-' . $warehouseId . '-' . $this->chartYear . '-' . $this->productId . '-' . $this->productCategory)
                    )
                </div>

                <div class="dw-widget-wrap">
                    @livewire(
                        \App\Filament\Admin\Widgets\DataWarehouseTopProductMovementChart::class,
                        [
                            'period' => $period,
                            'startDate' => $startDate,
                            'endDate' => $endDate,
                            'warehouseId' => $warehouseId,
                            'chartYear' => $this->chartYear,
                            'productId' => $this->productId,
                            'productCategory' => $this->productCategory,
                        ],
                        key('dw-top-product-movement-' . $period . '-' . $startDate . '-' . $endDate . '-' . $warehouseId . '-' . $this->chartYear . '-' . $this->productId . '-' . $this->productCategory)
                    )
                </div>
            </div>
        </section>

        <section class="dw-filter-card">
            <div class="dw-filter-header">
                <div>
                    <h3 class="dw-section-title">
                        Keterangan Sumber Data Warehouse
                    </h3>

                    <p class="dw-section-subtitle">
                        Data pada dashboard ini berasal dari tabel data warehouse yang telah melalui proses ETL,
                        bukan langsung dari tabel operasional.
                    </p>
                </div>
            </div>

            <div class="dw-source-grid">
                <div class="dw-field">
                    <label class="dw-label">
                        Tabel Fakta
                    </label>

                    <p class="dw-source-list">
                        dw_fact_inbound_transactions<br>
                        dw_fact_outbound_transactions<br>
                        dw_fact_inventory_movements<br>
                        dw_fact_stock_snapshots
                    </p>
                </div>

                <div class="dw-field">
                    <label class="dw-label">
                        Tabel Dimensi
                    </label>

                    <p class="dw-source-list">
                        dw_dim_products<br>
                        dw_dim_warehouses<br>
                        dw_dim_dates
                    </p>
                </div>

                <div class="dw-field">
                    <label class="dw-label">
                        Alur ETL
                    </label>

                    <p class="dw-source-list">
                        Data operasional → proses ETL → tabel dimensi dan fakta → dashboard analitik.
                    </p>
                </div>

                <div class="dw-field">
                    <label class="dw-label">
                        Fungsi Analitik
                    </label>

                    <p class="dw-source-list">
                        Mendukung analisis historis persediaan, pergerakan stok, status stok, dan pengambilan keputusan manajemen.
                    </p>
                </div>
            </div>
        </section>
    </div>
</x-filament-panels::page>