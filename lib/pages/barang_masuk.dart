import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'app_bottom_nav.dart';
import 'detail_barang_masuk.dart';
import 'riwayat_transaksi.dart';
import 'tambah_barang_masuk.dart';

class BarangMasukScreen extends StatefulWidget {
  const BarangMasukScreen({super.key});

  @override
  State<BarangMasukScreen> createState() => _BarangMasukScreenState();
}

class _BarangMasukScreenState extends State<BarangMasukScreen> {
  static const Color _bgColor = Color(0xFFF7FAFC);
  static const Color _primaryGreen = Color(0xFF16A34A);
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);

  int currentPage = 1;
  final int perPage = 5;

  DateTime? tanggalDari;
  DateTime? tanggalSampai;

  bool isLoading = false;
  String? errorMessage;

  final TextEditingController quickSearchController = TextEditingController();
  final TextEditingController supplierController = TextEditingController();
  final TextEditingController nomorSuratController = TextEditingController();
  final TextEditingController barangController = TextEditingController();

  List<Map<String, dynamic>> allItems = [];

  @override
  void initState() {
    super.initState();
    _loadInbounds();
  }

  @override
  void dispose() {
    quickSearchController.dispose();
    supplierController.dispose();
    nomorSuratController.dispose();
    barangController.dispose();
    super.dispose();
  }

  Future<void> _loadInbounds() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.get('/inbounds');

      if (response is! Map<String, dynamic>) {
        throw ApiException(message: 'Response barang masuk tidak valid.');
      }

      final data = response['data'];

      if (data is! List) {
        throw ApiException(message: 'Data barang masuk tidak valid.');
      }

      final mappedItems = data.map<Map<String, dynamic>>((raw) {
        final item = raw is Map<String, dynamic>
            ? raw
            : raw is Map
                ? Map<String, dynamic>.from(raw)
                : <String, dynamic>{};

        final supplier = _asMap(item['supplier']);
        final warehouse = _asMap(item['warehouse']);

        final totalItems =
            int.tryParse(item['total_items']?.toString() ?? '0') ?? 0;

        final totalQty = _toDouble(item['total_qty']);

        final transactionDate =
            _parseDate(item['transaction_date']) ?? DateTime.now();

        return {
          'id': item['id'],
          'tanggal': transactionDate,
          'supplier': _safeText(supplier['name'], fallback: '-'),
          'warehouse': _safeText(warehouse['name'], fallback: '-'),
          'totalBarang': '${_formatQty(totalQty)} PCS',
          'totalQty': totalQty,
          'totalItems': totalItems,
          'kode': _safeText(item['transaction_number'], fallback: '-'),
          'invoice': _safeText(item['invoice_number'], fallback: '-'),
          'barang': totalItems > 0 ? '$totalItems item barang' : 'Barang masuk',
          'status': _formatStatus(item['status']?.toString()),
          'note': item['note']?.toString(),
          'submittedAt': item['submitted_at']?.toString(),
          'approvedAt': item['approved_at']?.toString(),
          'rejectedAt': item['rejected_at']?.toString(),
          'rejectionReason': item['rejection_reason']?.toString(),
          'grandTotal': _toDouble(item['grand_total']),
        };
      }).toList();

      mappedItems.sort((a, b) {
        final dateA = a['tanggal'] as DateTime;
        final dateB = b['tanggal'] as DateTime;

        return dateB.compareTo(dateA);
      });

      if (!mounted) return;

      setState(() {
        allItems = mappedItems;
        _resetPage();
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.message;
      });

      _showSnackBar(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Gagal memuat barang masuk: $e';
      });

      _showSnackBar('Gagal memuat barang masuk: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    return <String, dynamic>{};
  }

  String _safeText(dynamic value, {String fallback = '-'}) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().trim();

    if (raw.isEmpty) return null;

    return DateTime.tryParse(raw);
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatQty(num value) {
    final doubleValue = value.toDouble();

    if (doubleValue % 1 == 0) {
      return doubleValue.toInt().toString();
    }

    return doubleValue.toStringAsFixed(2);
  }

  String _formatNumber(num value) {
    final raw = _formatQty(value);
    final parts = raw.split('.');
    final number = parts.first;
    final buffer = StringBuffer();

    for (int i = 0; i < number.length; i++) {
      final reverseIndex = number.length - i;

      buffer.write(number[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    if (parts.length > 1) {
      return '${buffer.toString()},${parts.last}';
    }

    return buffer.toString();
  }

  String _formatStatus(String? status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status ?? '-';
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';

    const bulan = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${bulan[date.month]} ${date.year}';
  }

  Future<void> _pickDate({
    required bool isStart,
    required void Function(void Function()) setSheetState,
  }) async {
    final initialDate = isStart
        ? (tanggalDari ?? DateTime.now())
        : (tanggalSampai ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryGreen,
              onPrimary: Colors.white,
              onSurface: _darkText,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setSheetState(() {
        if (isStart) {
          tanggalDari = picked;
        } else {
          tanggalSampai = picked;
        }
      });
    }
  }

  List<Map<String, dynamic>> get filteredItems {
    final quickQuery = quickSearchController.text.trim().toLowerCase();
    final supplierQuery = supplierController.text.trim().toLowerCase();
    final nomorQuery = nomorSuratController.text.trim().toLowerCase();
    final barangQuery = barangController.text.trim().toLowerCase();

    final result = allItems.where((item) {
      final itemDate = item['tanggal'] as DateTime;
      final supplier = item['supplier'].toString().toLowerCase();
      final kode = item['kode'].toString().toLowerCase();
      final invoice = item['invoice'].toString().toLowerCase();
      final barang = item['barang'].toString().toLowerCase();
      final warehouse = item['warehouse'].toString().toLowerCase();
      final status = item['status'].toString().toLowerCase();
      final totalBarang = item['totalBarang'].toString().toLowerCase();

      if (tanggalDari != null) {
        final startDate = DateTime(
          tanggalDari!.year,
          tanggalDari!.month,
          tanggalDari!.day,
        );

        if (itemDate.isBefore(startDate)) return false;
      }

      if (tanggalSampai != null) {
        final endDate = DateTime(
          tanggalSampai!.year,
          tanggalSampai!.month,
          tanggalSampai!.day,
          23,
          59,
          59,
        );

        if (itemDate.isAfter(endDate)) return false;
      }

      if (quickQuery.isNotEmpty) {
        final matchedQuick = supplier.contains(quickQuery) ||
            kode.contains(quickQuery) ||
            invoice.contains(quickQuery) ||
            barang.contains(quickQuery) ||
            warehouse.contains(quickQuery) ||
            status.contains(quickQuery) ||
            totalBarang.contains(quickQuery);

        if (!matchedQuick) return false;
      }

      if (supplierQuery.isNotEmpty && !supplier.contains(supplierQuery)) {
        return false;
      }

      if (nomorQuery.isNotEmpty &&
          !kode.contains(nomorQuery) &&
          !invoice.contains(nomorQuery)) {
        return false;
      }

      if (barangQuery.isNotEmpty &&
          !barang.contains(barangQuery) &&
          !warehouse.contains(barangQuery) &&
          !status.contains(barangQuery)) {
        return false;
      }

      return true;
    }).toList();

    result.sort((a, b) {
      final dateA = a['tanggal'] as DateTime;
      final dateB = b['tanggal'] as DateTime;

      return dateB.compareTo(dateA);
    });

    return result;
  }

  List<Map<String, dynamic>> get pagedItems {
    final items = filteredItems;

    if (items.isEmpty) return [];

    final safePage = currentPage > totalPages ? totalPages : currentPage;
    final start = (safePage - 1) * perPage;
    final end =
        (start + perPage) > items.length ? items.length : start + perPage;

    if (start >= items.length) return [];

    return items.sublist(start, end);
  }

  int get totalPages {
    if (filteredItems.isEmpty) return 1;

    return (filteredItems.length / perPage).ceil();
  }

  List<Map<String, dynamic>> get thisMonthItems {
    final now = DateTime.now();

    return allItems.where((item) {
      final date = item['tanggal'] as DateTime;

      return date.year == now.year && date.month == now.month;
    }).toList();
  }

  int get totalMasukBulanIni => thisMonthItems.length;

  double get totalQtyBulanIni {
    return thisMonthItems.fold<double>(
      0,
      (total, item) => total + _toDouble(item['totalQty']),
    );
  }

  bool get hasActiveFilter {
    return tanggalDari != null ||
        tanggalSampai != null ||
        supplierController.text.trim().isNotEmpty ||
        nomorSuratController.text.trim().isNotEmpty ||
        barangController.text.trim().isNotEmpty;
  }

  void _resetPage() {
    currentPage = 1;
  }

  void _clearFilter({
    required void Function(void Function()) setSheetState,
  }) {
    setSheetState(() {
      tanggalDari = null;
      tanggalSampai = null;
      supplierController.clear();
      nomorSuratController.clear();
      barangController.clear();
    });

    setState(() {
      _resetPage();
    });
  }

  Future<void> _openDetail(Map<String, dynamic> item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DetailBarangMasukScreen(),
        settings: RouteSettings(
          arguments: {
            'id': item['id'],
            'kode': item['kode'],
          },
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadInbounds();
    }
  }

  void _showFilterSheet() {
    FocusManager.instance.primaryFocus?.unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _bottomSheetContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 16),
                  _sheetHeader(
                    icon: Icons.tune_rounded,
                    title: 'Filter Barang Masuk',
                    subtitle:
                        'Cari transaksi berdasarkan tanggal, supplier, nomor, atau barang.',
                    color: _primaryGreen,
                    bgColor: const Color(0xFFEFFDF5),
                  ),
                  const SizedBox(height: 16),
                  _filterTitle(
                    icon: Icons.calendar_today_outlined,
                    title: 'Tanggal Masuk',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _dateField(
                          label: 'Dari',
                          value: formatDate(tanggalDari),
                          onTap: () => _pickDate(
                            isStart: true,
                            setSheetState: setSheetState,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _dateField(
                          label: 'Sampai',
                          value: formatDate(tanggalSampai),
                          onTap: () => _pickDate(
                            isStart: false,
                            setSheetState: setSheetState,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _filterTitle(
                    icon: Icons.business_outlined,
                    title: 'Supplier',
                  ),
                  const SizedBox(height: 8),
                  _filterInput(
                    hint: 'Cari supplier...',
                    controller: supplierController,
                    icon: Icons.storefront_outlined,
                  ),
                  const SizedBox(height: 12),
                  _filterTitle(
                    icon: Icons.description_outlined,
                    title: 'Nomor Transaksi / Invoice',
                  ),
                  const SizedBox(height: 8),
                  _filterInput(
                    hint: 'Masukkan nomor transaksi atau invoice...',
                    controller: nomorSuratController,
                    icon: Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 12),
                  _filterTitle(
                    icon: Icons.inventory_2_outlined,
                    title: 'Barang / Gudang / Status',
                  ),
                  const SizedBox(height: 8),
                  _filterInput(
                    hint: 'Cari barang, gudang, atau status...',
                    controller: barangController,
                    icon: Icons.search_rounded,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: () => _clearFilter(
                              setSheetState: setSheetState,
                            ),
                            icon: const Icon(
                              Icons.refresh_rounded,
                              size: 16,
                            ),
                            label: const Text('Reset'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _softText,
                              side: const BorderSide(
                                color: Color(0xFFD1D5DB),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _resetPage();
                              });
                              Navigator.pop(sheetContext);
                            },
                            icon: const Icon(
                              Icons.check_rounded,
                              size: 16,
                            ),
                            label: const Text('Terapkan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _bottomSheetContainer({
    required Widget child,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.86,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _sheetHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  color: _darkText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _softText,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: _primaryGreen,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12.5,
            color: _darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.isEmpty ? label : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: value.isEmpty ? const Color(0xFF9CA3AF) : _darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: _primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterInput({
    required String hint,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      cursorColor: _primaryGreen,
      style: const TextStyle(
        fontSize: 13,
        color: _darkText,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        prefixIcon: Icon(
          icon,
          size: 19,
          color: const Color(0xFF8B96A8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryGreen),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = pagedItems;

    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: const AppBottomNav(selectedIndex: 0),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _InboundBackgroundPainter(),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: _primaryGreen,
              backgroundColor: Colors.white,
              onRefresh: _loadInbounds,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    if (isLoading) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: const LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: Color(0xFFE5E7EB),
                          color: _primaryGreen,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _buildActionCards(),
                    const SizedBox(height: 12),
                    _buildSummaryCards(),
                    const SizedBox(height: 12),
                    _buildSearchAndFilter(),
                    const SizedBox(height: 16),
                    _buildSectionHeader(),
                    const SizedBox(height: 10),
                    if (errorMessage != null && allItems.isEmpty)
                      _buildErrorState()
                    else if (visibleItems.isEmpty)
                      _buildEmptyState()
                    else
                      ...visibleItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final globalIndex =
                            (currentPage - 1) * perPage + index + 1;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InboundItemCard(
                            nomor: '$globalIndex',
                            tanggal: formatDate(item['tanggal'] as DateTime),
                            kode: item['kode'].toString(),
                            supplier: item['supplier'].toString(),
                            barang: item['barang'].toString(),
                            totalBarang: item['totalBarang'].toString(),
                            status: item['status'].toString(),
                            warehouse: item['warehouse'].toString(),
                            invoice: item['invoice'].toString(),
                            onTap: () => _openDetail(item),
                          ),
                        );
                      }),
                    const SizedBox(height: 4),
                    _buildPagination(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF22C55E),
            Color(0xFF16A34A),
            Color(0xFF15803D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Barang Masuk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola penerimaan barang',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFEFFDF5),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _HeaderIconButton(
            icon: Icons.refresh_rounded,
            onTap: _loadInbounds,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            title: 'Tambah',
            subtitle: 'Barang Masuk',
            icon: Icons.add_circle_outline_rounded,
            color: _primaryGreen,
            bgColor: const Color(0xFFEFFDF5),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TambahBarangMasukScreen(),
                ),
              );

              if (!mounted) return;
              await _loadInbounds();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            title: 'Riwayat',
            subtitle: 'Barang Masuk',
            icon: Icons.receipt_long_rounded,
            color: _primaryBlue,
            bgColor: const Color(0xFFEFF6FF),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const RiwayatTransaksiScreen(),
                  settings: const RouteSettings(
                    arguments: {
                      'selectedTab': 1,
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.move_to_inbox_outlined,
            title: totalMasukBulanIni.toString(),
            label: 'Total Masuk',
            color: _primaryGreen,
            bgColor: const Color(0xFFEFFDF5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.inventory_2_outlined,
            title: _formatNumber(totalQtyBulanIni),
            label: 'Qty Masuk',
            color: _primaryBlue,
            bgColor: const Color(0xFFEFF6FF),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: _cardDecoration(radius: 15),
            child: TextField(
              controller: quickSearchController,
              cursorColor: _primaryGreen,
              onChanged: (_) {
                setState(() {
                  _resetPage();
                });
              },
              style: const TextStyle(
                fontSize: 12.8,
                color: _darkText,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Cari kode, supplier, gudang...',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF8B96A8),
                  size: 19,
                ),
                suffixIcon: quickSearchController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          quickSearchController.clear();
                          setState(() {
                            _resetPage();
                          });
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF8B96A8),
                          size: 18,
                        ),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: _showFilterSheet,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: _cardDecoration(
              radius: 15,
              color: hasActiveFilter ? const Color(0xFFEFFDF5) : Colors.white,
              borderColor: hasActiveFilter ? _primaryGreen : _borderColor,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: hasActiveFilter ? _primaryGreen : _primaryBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: hasActiveFilter ? _primaryGreen : _primaryBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Penerimaan Terbaru',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: _darkText,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Text(
            '${filteredItems.length} data',
            style: const TextStyle(
              fontSize: 11.8,
              color: _softText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 34,
        horizontal: 16,
      ),
      decoration: _cardDecoration(radius: 20),
      child: const Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 44,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 10),
          Text(
            'Data barang masuk tidak ditemukan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Coba ubah pencarian atau filter transaksi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _softText,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 34,
        horizontal: 16,
      ),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 44,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 10),
          const Text(
            'Gagal memuat barang masuk',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            errorMessage ?? 'Terjadi kesalahan saat memuat data.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: _softText,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _loadInbounds,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 17,
            ),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();

    final pages = _visiblePages();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _paginationButton(
            icon: Icons.chevron_left_rounded,
            enabled: currentPage > 1,
            onTap: () {
              setState(() {
                currentPage--;
              });
            },
          ),
          const SizedBox(width: 8),
          ...pages.map((page) {
            final active = currentPage == page;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: () {
                  setState(() {
                    currentPage = page;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 32),
                  height: 32,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: active ? _primaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active ? _primaryGreen : _borderColor,
                    ),
                  ),
                  child: Text(
                    '$page',
                    style: TextStyle(
                      fontSize: 12,
                      color: active ? Colors.white : _softText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          _paginationButton(
            icon: Icons.chevron_right_rounded,
            enabled: currentPage < totalPages,
            onTap: () {
              setState(() {
                currentPage++;
              });
            },
          ),
        ],
      ),
    );
  }

  List<int> _visiblePages() {
    if (totalPages <= 5) {
      return List.generate(totalPages, (index) => index + 1);
    }

    int start = currentPage - 2;

    if (start < 1) start = 1;

    if (start > totalPages - 4) {
      start = totalPages - 4;
    }

    final end = start + 4;

    return List.generate(
      end - start + 1,
      (index) => start + index,
    );
  }

  Widget _paginationButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: _borderColor,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? _primaryGreen : const Color(0xFFCBD5E1),
          size: 20,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 16,
    Color? color,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? _borderColor,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFEF4444) : _primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: Colors.white,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 72,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: color.withValues(alpha: 0.14),
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.2,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.2,
                        color: color,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String label;
  final Color color;
  final Color bgColor;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: color.withValues(alpha: 0.10),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 19,
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InboundItemCard extends StatelessWidget {
  final String nomor;
  final String tanggal;
  final String kode;
  final String supplier;
  final String barang;
  final String totalBarang;
  final String status;
  final String warehouse;
  final String invoice;
  final VoidCallback onTap;

  const _InboundItemCard({
    required this.nomor,
    required this.tanggal,
    required this.kode,
    required this.supplier,
    required this.barang,
    required this.totalBarang,
    required this.status,
    required this.warehouse,
    required this.invoice,
    required this.onTap,
  });

  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Disetujui';
  bool get isRejected => status == 'Ditolak';

  Color get statusColor {
    if (isPending) return const Color(0xFFF59E0B);
    if (isApproved) return const Color(0xFF16A34A);
    if (isRejected) return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }

  Color get statusBgColor {
    if (isPending) return const Color(0xFFFFF7ED);
    if (isApproved) return const Color(0xFFEFFDF5);
    if (isRejected) return const Color(0xFFFFE4E6);
    return const Color(0xFFF3F4F6);
  }

  IconData get statusIcon {
    if (isPending) return Icons.schedule_rounded;
    if (isApproved) return Icons.check_circle_outline_rounded;
    if (isRejected) return Icons.cancel_outlined;
    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopRow(),
                      const SizedBox(height: 10),
                      _buildBadges(),
                      const SizedBox(height: 10),
                      _buildTitleArea(),
                      const SizedBox(height: 12),
                      _buildInfoGrid(),
                      if (invoice != '-' && invoice.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildInvoiceRow(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEFFDF5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF16A34A).withValues(alpha: 0.18),
            ),
          ),
          child: const Icon(
            Icons.download_rounded,
            color: Color(0xFF16A34A),
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            kode,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.2,
              color: Color(0xFF16A34A),
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _statusBadge(),
      ],
    );
  }

  Widget _buildBadges() {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _smallBadge(
          text: 'Barang Masuk',
          color: const Color(0xFF16A34A),
          bgColor: const Color(0xFFEFFDF5),
          borderColor: const Color(0xFF16A34A).withValues(alpha: 0.16),
        ),
        _smallBadge(
          text: 'No. $nomor',
          color: const Color(0xFF6B7280),
          bgColor: const Color(0xFFF3F4F6),
          borderColor: const Color(0xFFE5E7EB),
        ),
      ],
    );
  }

  Widget _buildTitleArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Penerimaan Barang',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.5,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 15,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Supplier: $supplier',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    return Row(
      children: [
        Expanded(
          child: _infoBox(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal',
            value: tanggal,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _infoBox(
            icon: Icons.inventory_2_outlined,
            label: 'Jumlah',
            value: totalBarang,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _infoBox(
            icon: Icons.warehouse_outlined,
            label: 'Gudang',
            value: warehouse,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            size: 16,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 8),
          const Text(
            'Invoice',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              invoice,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.8,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.8,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallBadge({
    required String text,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.3,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: statusBgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 12,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 10.3,
              color: statusColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InboundBackgroundPainter extends CustomPainter {
  const _InboundBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF7FAFC),
          Color(0xFFF0FDF4),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);

    final topCircle = Paint()
      ..color = const Color(0xFFEFFDF5).withValues(alpha: 0.65);

    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.10),
      size.width * 0.35,
      topCircle,
    );

    final bottomCircle = Paint()
      ..color = const Color(0xFFEFF6FF).withValues(alpha: 0.55);

    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.88),
      size.width * 0.40,
      bottomCircle,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}