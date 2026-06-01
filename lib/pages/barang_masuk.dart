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
  int currentPage = 1;
  final int perPage = 4;

  DateTime? tanggalDari;
  DateTime? tanggalSampai;

  bool isLoading = false;
  String? errorMessage;

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
        final item = raw as Map<String, dynamic>;

        final supplier = item['supplier'] as Map<String, dynamic>? ?? {};
        final warehouse = item['warehouse'] as Map<String, dynamic>? ?? {};

        final totalItems = int.tryParse(item['total_items'].toString()) ?? 0;
        final totalQty = _toDouble(item['total_qty']);

        final transactionDate =
            _parseDate(item['transaction_date']) ?? DateTime.now();

        return {
          'id': item['id'],
          'tanggal': transactionDate,
          'supplier': supplier['name']?.toString() ?? '-',
          'warehouse': warehouse['name']?.toString() ?? '-',
          'totalBarang': '${_formatQty(totalQty)} PCS',
          'totalQty': totalQty,
          'totalItems': totalItems,
          'kode': item['transaction_number']?.toString() ?? '-',
          'invoice': item['invoice_number']?.toString() ?? '-',
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

      setState(() {
        allItems = mappedItems;
        _resetPage();
      });
    } on ApiException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
      _showSnackBar(e.message, isError: true);
    } catch (e) {
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

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final raw = value.toString();

    if (raw.trim().isEmpty) return null;

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
    required void Function(void Function()) setDialogState,
  }) async {
    final initialDate = isStart
        ? (tanggalDari ?? DateTime.now())
        : (tanggalSampai ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setDialogState(() {
        if (isStart) {
          tanggalDari = picked;
        } else {
          tanggalSampai = picked;
        }
      });
    }
  }

  List<Map<String, dynamic>> get filteredItems {
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

      if (tanggalDari != null) {
        final startDate = DateTime(
          tanggalDari!.year,
          tanggalDari!.month,
          tanggalDari!.day,
        );

        if (itemDate.isBefore(startDate)) {
          return false;
        }
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

        if (itemDate.isAfter(endDate)) {
          return false;
        }
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
    final end = (start + perPage) > items.length ? items.length : start + perPage;

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

  int get totalMasukBulanIni {
    return thisMonthItems.length;
  }

  double get totalQtyBulanIni {
    return thisMonthItems.fold<double>(
      0,
      (total, item) => total + _toDouble(item['totalQty']),
    );
  }

  void _resetPage() {
    currentPage = 1;
  }

  void _resetFilter() {
    setState(() {
      tanggalDari = null;
      tanggalSampai = null;
      supplierController.clear();
      nomorSuratController.clear();
      barangController.clear();
      _resetPage();
    });

    Navigator.pop(context);
  }

  void _openDetail(Map<String, dynamic> item) {
    Navigator.push(
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
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 18,
                            color: Color(0xFF4B5563),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Filter Barang Masuk',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _filterSectionTitle(
                        Icons.calendar_today_outlined,
                        'Tanggal Masuk',
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _dateField(
                              label: 'Dari Tanggal',
                              value: formatDate(tanggalDari),
                              onTap: () => _pickDate(
                                isStart: true,
                                setDialogState: setDialogState,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _dateField(
                              label: 'Sampai Tanggal',
                              value: formatDate(tanggalSampai),
                              onTap: () => _pickDate(
                                isStart: false,
                                setDialogState: setDialogState,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _filterSectionTitle(
                        Icons.business_outlined,
                        'Supplier',
                      ),
                      const SizedBox(height: 6),
                      _filterPlainInput(
                        'Cari supplier...',
                        supplierController,
                      ),
                      const SizedBox(height: 12),
                      _filterSectionTitle(
                        Icons.description_outlined,
                        'Nomor Transaksi / Invoice',
                      ),
                      const SizedBox(height: 6),
                      _filterPlainInput(
                        'Masukkan nomor transaksi atau invoice...',
                        nomorSuratController,
                      ),
                      const SizedBox(height: 12),
                      _filterSectionTitle(
                        Icons.inventory_2_outlined,
                        'Barang / Gudang / Status',
                      ),
                      const SizedBox(height: 6),
                      _filterPlainInput(
                        'Cari barang, gudang, atau status...',
                        barangController,
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 42,
                                  child: OutlinedButton.icon(
                                    onPressed: _resetFilter,
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Reset',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          const Color(0xFF6B7280),
                                      side: const BorderSide(
                                        color: Color(0xFFD1D5DB),
                                      ),
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 42,
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Batal',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          const Color(0xFF16A34A),
                                      side: const BorderSide(
                                        color: Color(0xFF16A34A),
                                      ),
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _resetPage();
                                });

                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Terapkan Filter',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF16A34A),
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w600,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFD1D5DB),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Pilih tanggal' : value,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Color(0xFF16A34A),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterPlainInput(
    String hint,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 11.5,
          color: Color(0xFF9CA3AF),
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFD1D5DB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFD1D5DB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF16A34A),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF7),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadInbounds,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopMenu(),
                      if (isLoading) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: const LinearProgressIndicator(
                            minHeight: 4,
                            backgroundColor: Color(0xFFE5E7EB),
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _buildSummaryCards(),
                      const SizedBox(height: 16),
                      _buildSectionHeader(),
                      const SizedBox(height: 10),
                      if (errorMessage != null && allItems.isEmpty)
                        _buildErrorState()
                      else if (pagedItems.isEmpty)
                        _buildEmptyState()
                      else
                        ...pagedItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _BarangMasukItemCard(
                              tanggal: formatDate(item['tanggal'] as DateTime),
                              kode: item['kode'] as String,
                              supplier: item['supplier'] as String,
                              barang: item['barang'] as String,
                              totalBarang: item['totalBarang'] as String,
                              status: item['status'] as String,
                              warehouse: item['warehouse'] as String,
                              invoice: item['invoice'] as String,
                              onTap: () => _openDetail(item),
                            ),
                          ),
                        ),
                      const SizedBox(height: 2),
                      _buildPagination(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PENERIMAAN TERBARU',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Daftar transaksi barang masuk terbaru',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: _showFilterDialog,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: Color(0xFF2F47B7),
                ),
                SizedBox(width: 5),
                Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2F47B7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
        horizontal: 16,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 36,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 10),
          Text(
            'Data barang masuk tidak ditemukan',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Coba ubah filter pencarian Anda.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
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
        horizontal: 16,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 36,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 10),
          const Text(
            'Gagal memuat barang masuk',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            errorMessage ?? 'Terjadi kesalahan saat memuat data.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _loadInbounds,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF2F47B7),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Barang Masuk',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _loadInbounds,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMenu() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TambahBarangMasukScreen(),
                ),
              );

              _loadInbounds();
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 96,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1677FF),
                    Color(0xFF0D6EFD),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x241677FF),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopIconBubble(
                    icon: Icons.add_circle_outline_rounded,
                    iconColor: Colors.white,
                    backgroundColor: Color(0x26FFFFFF),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tambah\nBarang Masuk',
                          maxLines: 2,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
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
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 96,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFD9E3F7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFC7D4F0),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopIconBubble(
                    icon: Icons.receipt_long_rounded,
                    iconColor: Color(0xFF2F47B7),
                    backgroundColor: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Riwayat\nBarang Masuk',
                          maxLines: 2,
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 12,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            backgroundColor: const Color(0xFFEFFDF5),
            iconBgColor: const Color(0xFFDDFBEA),
            iconColor: const Color(0xFF16A34A),
            icon: Icons.move_to_inbox_outlined,
            title: totalMasukBulanIni.toString(),
            subtitle1: 'Total Masuk',
            subtitle2: 'Bulan ini',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            backgroundColor: const Color(0xFFEAF2FF),
            iconBgColor: const Color(0xFFDCE8FF),
            iconColor: const Color(0xFF2F47B7),
            icon: Icons.inventory_2_outlined,
            title: _formatNumber(totalQtyBulanIni),
            subtitle1: 'Qty Masuk',
            subtitle2: '(PCS)',
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();

    final pages = List.generate(
      totalPages,
      (index) => index + 1,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _paginationArrow(
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
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF2F47B7) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF2F47B7)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  '$page',
                  style: TextStyle(
                    fontSize: 11,
                    color: active ? Colors.white : const Color(0xFF4B5563),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        _paginationArrow(
          icon: Icons.chevron_right_rounded,
          enabled: currentPage < totalPages,
          onTap: () {
            setState(() {
              currentPage++;
            });
          },
        ),
      ],
    );
  }

  Widget _paginationArrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFF2F47B7) : const Color(0xFF9CA3AF),
          size: 18,
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
      ),
    );
  }
}

class _TopIconBubble extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const _TopIconBubble({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 17,
        color: iconColor,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Color backgroundColor;
  final Color iconBgColor;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle1;
  final String subtitle2;

  const _SummaryCard({
    required this.backgroundColor,
    required this.iconBgColor,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle1,
    required this.subtitle2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
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
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle1,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4B5563),
                    height: 1.1,
                  ),
                ),
                Text(
                  subtitle2,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4B5563),
                    height: 1.1,
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

class _BarangMasukItemCard extends StatelessWidget {
  final String tanggal;
  final String kode;
  final String supplier;
  final String barang;
  final String totalBarang;
  final String status;
  final String warehouse;
  final String invoice;
  final VoidCallback onTap;

  const _BarangMasukItemCard({
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

  Color get statusColor {
    switch (status) {
      case 'Disetujui':
        return const Color(0xFF16A34A);
      case 'Ditolak':
        return const Color(0xFFEF4444);
      case 'Pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color get statusBgColor {
    switch (status) {
      case 'Disetujui':
        return const Color(0xFFEFFDF5);
      case 'Ditolak':
        return const Color(0xFFFFE4E6);
      case 'Pending':
        return const Color(0xFFFFF7ED);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEFFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF16A34A),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tanggal,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _StatusTag(
                        text: status,
                        textColor: statusColor,
                        bgColor: statusBgColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _GreenTag(text: kode),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _infoRow('Supplier', supplier),
                  const SizedBox(height: 5),
                  _infoRow('Gudang', warehouse),
                  const SizedBox(height: 5),
                  _infoRow('Total Barang', '$totalBarang • $barang'),
                  if (invoice != '-' && invoice.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    _infoRow('Invoice', invoice),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF9CA3AF),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _GreenTag extends StatelessWidget {
  final String text;

  const _GreenTag({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F8EE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9.5,
            color: Color(0xFF15803D),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color bgColor;

  const _StatusTag({
    required this.text,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: textColor.withOpacity(0.25),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          color: textColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}