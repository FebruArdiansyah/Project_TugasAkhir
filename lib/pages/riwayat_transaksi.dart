import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'app_bottom_nav.dart';
import 'detail_barang_keluar.dart';
import 'detail_barang_masuk.dart';

class RiwayatTransaksiScreen extends StatefulWidget {
  const RiwayatTransaksiScreen({super.key});

  @override
  State<RiwayatTransaksiScreen> createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  int selectedTab = 0;
  bool _isArgumentLoaded = false;

  DateTime? dariTanggal;
  DateTime? sampaiTanggal;

  final TextEditingController searchController = TextEditingController();

  int currentPage = 1;
  final int itemsPerPage = 5;

  bool isLoading = false;
  String? errorMessage;

  List<Map<String, dynamic>> transaksiList = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isArgumentLoaded) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map && args['selectedTab'] is int) {
      selectedTab = args['selectedTab'] as int;
    }

    _isArgumentLoaded = true;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.get('/transactions/history');

      if (response is! Map<String, dynamic>) {
        throw ApiException(message: 'Response riwayat transaksi tidak valid.');
      }

      final data = response['data'];

      if (data is! List) {
        throw ApiException(message: 'Data riwayat transaksi tidak valid.');
      }

      final mapped = data.map<Map<String, dynamic>>((raw) {
        final item = raw as Map<String, dynamic>;

        final type = item['type']?.toString() ?? '';
        final isMasuk = type == 'inbound';

        final tanggal = _parseDate(item['transaction_date']) ?? DateTime.now();
        final createdAt = _parseDateTime(item['created_at']) ?? tanggal;

        return {
          'id': item['id'],
          'type': type,
          'isMasuk': isMasuk,
          'tanggal': tanggal,
          'createdAt': createdAt,
          'supplier': item['partner_name']?.toString() ?? '-',
          'partnerLabel': item['partner_label']?.toString() ??
              (isMasuk ? 'Supplier' : 'Customer / Tujuan'),
          'warehouse': item['warehouse_name']?.toString() ?? '-',
          'totalBarang': '${_formatQty(_toDouble(item['total_qty']))} PCS',
          'totalQty': _toDouble(item['total_qty']),
          'totalItems': int.tryParse(item['total_items'].toString()) ?? 0,
          'kode': item['transaction_number']?.toString() ?? '-',
          'referenceNumber': item['reference_number']?.toString(),
          'nama': item['type_label']?.toString() ??
              (isMasuk ? 'Barang Masuk' : 'Barang Keluar'),
          'status': _formatStatus(item['status']?.toString()),
          'inputOleh': item['submitted_by_name']?.toString() ?? 'User Mobile',
          'alasan': item['rejection_reason']?.toString(),
          'note': item['note']?.toString(),
          'grandTotal': _toDouble(item['grand_total']),
          'submittedAt': item['submitted_at']?.toString(),
          'approvedAt': item['approved_at']?.toString(),
          'rejectedAt': item['rejected_at']?.toString(),
        };
      }).toList();

      mapped.sort((a, b) {
        final dateA = a['createdAt'] as DateTime;
        final dateB = b['createdAt'] as DateTime;

        return dateB.compareTo(dateA);
      });

      setState(() {
        transaksiList = mapped;
        _resetPage();
      });
    } on ApiException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat riwayat transaksi: $e';
      });
      _showSnackBar('Gagal memuat riwayat transaksi: $e', isError: true);
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

  DateTime? _parseDateTime(dynamic value) {
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

  String formatDate(DateTime date) {
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

  List<Map<String, dynamic>> get filteredList {
    final query = searchController.text.trim().toLowerCase();

    final result = transaksiList.where((item) {
      final bool isMasuk = item['isMasuk'] as bool;
      final DateTime tanggal = item['tanggal'] as DateTime;
      final String status = item['status'].toString().toLowerCase();

      if (selectedTab == 1 && !isMasuk) return false;
      if (selectedTab == 2 && isMasuk) return false;
      if (selectedTab == 3 && status != 'pending') return false;
      if (selectedTab == 4 && status != 'disetujui') return false;
      if (selectedTab == 5 && status != 'ditolak') return false;

      if (dariTanggal != null) {
        final startDate = DateTime(
          dariTanggal!.year,
          dariTanggal!.month,
          dariTanggal!.day,
        );

        if (tanggal.isBefore(startDate)) return false;
      }

      if (sampaiTanggal != null) {
        final endDate = DateTime(
          sampaiTanggal!.year,
          sampaiTanggal!.month,
          sampaiTanggal!.day,
          23,
          59,
          59,
        );

        if (tanggal.isAfter(endDate)) return false;
      }

      if (query.isNotEmpty) {
        final kode = item['kode'].toString().toLowerCase();
        final nama = item['nama'].toString().toLowerCase();
        final supplier = item['supplier'].toString().toLowerCase();
        final warehouse = item['warehouse'].toString().toLowerCase();
        final statusText = item['status'].toString().toLowerCase();
        final reference = item['referenceNumber']?.toString().toLowerCase() ?? '';

        final matched = kode.contains(query) ||
            nama.contains(query) ||
            supplier.contains(query) ||
            warehouse.contains(query) ||
            statusText.contains(query) ||
            reference.contains(query);

        if (!matched) return false;
      }

      return true;
    }).toList();

    result.sort((a, b) {
      final dateA = a['createdAt'] as DateTime;
      final dateB = b['createdAt'] as DateTime;

      return dateB.compareTo(dateA);
    });

    return result;
  }

  List<Map<String, dynamic>> get paginatedList {
    final items = filteredList;

    if (items.isEmpty) return [];

    final safePage = currentPage > totalPages ? totalPages : currentPage;
    final start = (safePage - 1) * itemsPerPage;
    final end = start + itemsPerPage;

    return items.sublist(
      start,
      end > items.length ? items.length : end,
    );
  }

  int get totalPages {
    if (filteredList.isEmpty) return 1;

    return (filteredList.length / itemsPerPage).ceil();
  }

  void _resetPage() {
    currentPage = 1;
  }

  void _openDetail(Map<String, dynamic> item) {
    final bool isMasuk = item['isMasuk'] as bool;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isMasuk
            ? const DetailBarangMasukScreen()
            : const DetailBarangKeluarScreen(),
        settings: RouteSettings(
          arguments: {
            'id': item['id'],
            'type': item['type'],
            'kode': item['kode'],
          },
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Filter Tanggal',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _filterDateBox(
                    label: 'Dari',
                    value: dariTanggal != null
                        ? formatDate(dariTanggal!)
                        : 'Pilih tanggal',
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dariTanggal ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2035),
                      );

                      if (picked != null) {
                        setDialogState(() {
                          dariTanggal = picked;
                        });
                        setState(() {
                          _resetPage();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _filterDateBox(
                    label: 'Sampai',
                    value: sampaiTanggal != null
                        ? formatDate(sampaiTanggal!)
                        : 'Pilih tanggal',
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: sampaiTanggal ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2035),
                      );

                      if (picked != null) {
                        setDialogState(() {
                          sampaiTanggal = picked;
                        });
                        setState(() {
                          _resetPage();
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      dariTanggal = null;
                      sampaiTanggal = null;
                      _resetPage();
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Reset'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _resetPage();
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F47B7),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 20),
          onPressed: currentPage > 1
              ? () {
                  setState(() {
                    currentPage--;
                  });
                }
              : null,
        ),
        ...List.generate(totalPages, (i) {
          final pageNum = i + 1;
          final isActive = pageNum == currentPage;

          return GestureDetector(
            onTap: () {
              setState(() {
                currentPage = pageNum;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF2F47B7)
                    : const Color(0xFFF1F2F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$pageNum',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
          onPressed: currentPage < totalPages
              ? () {
                  setState(() {
                    currentPage++;
                  });
                }
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = paginatedList;

    return Scaffold(
      backgroundColor: const Color(0xFFDCE3F1),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTransactions,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 10),
                      _buildMainTabs(),
                      const SizedBox(height: 10),
                      _buildStatusFilter(),
                      const SizedBox(height: 12),
                      _buildActiveFilterInfo(),
                      if (isLoading) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: const LinearProgressIndicator(
                            minHeight: 4,
                            backgroundColor: Color(0xFFE5E7EB),
                            color: Color(0xFF2F47B7),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      _buildSectionTitle(),
                      const SizedBox(height: 10),
                      if (errorMessage != null && transaksiList.isEmpty)
                        _buildErrorState()
                      else if (filteredList.isEmpty)
                        _buildEmptyState()
                      else
                        ...visibleItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final globalIndex =
                              (currentPage - 1) * itemsPerPage + index + 1;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RiwayatApprovalCard(
                              nomor: '$globalIndex',
                              isMasuk: item['isMasuk'] as bool,
                              tanggal: formatDate(item['tanggal'] as DateTime),
                              supplier: item['supplier'].toString(),
                              partnerLabel: item['partnerLabel'].toString(),
                              warehouse: item['warehouse'].toString(),
                              totalBarang: item['totalBarang'].toString(),
                              kode: item['kode'].toString(),
                              nama: item['nama'].toString(),
                              status: item['status'].toString(),
                              inputOleh: item['inputOleh'].toString(),
                              alasan: item['alasan']?.toString(),
                              onTap: () => _openDetail(item),
                            ),
                          );
                        }),
                      const SizedBox(height: 10),
                      _buildPagination(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            const AppBottomNav(selectedIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: const Color(0xFF2F47B7),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Riwayat Transaksi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _loadTransactions,
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

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) {
                      setState(() {
                        _resetPage();
                      });
                    },
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Cari kode, barang, supplier, status...',
                      hintStyle: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF9CA3AF),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (searchController.text.trim().isNotEmpty)
                  InkWell(
                    onTap: () {
                      searchController.clear();
                      setState(() {
                        _resetPage();
                      });
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _showFilterDialog,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 18,
                  color: Color(0xFF2F47B7),
                ),
                SizedBox(width: 5),
                Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 11.5,
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

  Widget _filterDateBox({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Color(0xFF2F47B7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabs() {
    return Row(
      children: [
        Expanded(child: _tabButton('Semua', 0)),
        const SizedBox(width: 8),
        Expanded(child: _tabButton('Masuk', 1)),
        const SizedBox(width: 8),
        Expanded(child: _tabButton('Keluar', 2)),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Row(
      children: [
        Expanded(child: _statusButton('Pending', 3)),
        const SizedBox(width: 8),
        Expanded(child: _statusButton('Disetujui', 4)),
        const SizedBox(width: 8),
        Expanded(child: _statusButton('Ditolak', 5)),
      ],
    );
  }

  Widget _tabButton(String text, int value) {
    final bool active = selectedTab == value;

    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = value;
          _resetPage();
        });
      },
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2F3192) : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: active ? const Color(0xFF2F3192) : const Color(0xFFD1D5DB),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            color: active ? Colors.white : const Color(0xFF4B5563),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _statusButton(String text, int value) {
    final bool active = selectedTab == value;

    Color activeColor;
    Color bgColor;

    if (value == 3) {
      activeColor = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFFFF7ED);
    } else if (value == 4) {
      activeColor = const Color(0xFF16A34A);
      bgColor = const Color(0xFFEFFDF5);
    } else {
      activeColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFFE4E6);
    }

    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = value;
          _resetPage();
        });
      },
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: active ? activeColor : const Color(0xFFD1D5DB),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10.8,
            color: active ? activeColor : const Color(0xFF6B7280),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterInfo() {
    final bool hasDateFilter = dariTanggal != null || sampaiTanggal != null;

    if (!hasDateFilter) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 15,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '${dariTanggal == null ? 'Awal' : formatDate(dariTanggal!)} - ${sampaiTanggal == null ? 'Akhir' : formatDate(sampaiTanggal!)}',
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                dariTanggal = null;
                sampaiTanggal = null;
                _resetPage();
              });
            },
            child: const Icon(
              Icons.close_rounded,
              size: 17,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    String title;

    if (selectedTab == 1) {
      title = 'Riwayat Barang Masuk';
    } else if (selectedTab == 2) {
      title = 'Riwayat Barang Keluar';
    } else if (selectedTab == 3) {
      title = 'Menunggu Approval';
    } else if (selectedTab == 4) {
      title = 'Transaksi Disetujui';
    } else if (selectedTab == 5) {
      title = 'Transaksi Ditolak';
    } else {
      title = 'Semua Transaksi';
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF374151),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Text(
            '${filteredList.length} data',
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF6B7280),
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
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 40,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 8),
          Text(
            'Tidak ada transaksi',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 42,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gagal memuat riwayat',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            errorMessage ?? 'Terjadi kesalahan saat memuat data.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadTransactions,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F47B7),
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
            isError ? const Color(0xFFEF4444) : const Color(0xFF2F47B7),
      ),
    );
  }
}

class _RiwayatApprovalCard extends StatelessWidget {
  final String nomor;
  final bool isMasuk;
  final String tanggal;
  final String supplier;
  final String partnerLabel;
  final String warehouse;
  final String totalBarang;
  final String kode;
  final String nama;
  final String status;
  final String inputOleh;
  final String? alasan;
  final VoidCallback onTap;

  const _RiwayatApprovalCard({
    required this.nomor,
    required this.isMasuk,
    required this.tanggal,
    required this.supplier,
    required this.partnerLabel,
    required this.warehouse,
    required this.totalBarang,
    required this.kode,
    required this.nama,
    required this.status,
    required this.inputOleh,
    required this.onTap,
    this.alasan,
  });

  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Disetujui';
  bool get isRejected => status == 'Ditolak';

  @override
  Widget build(BuildContext context) {
    final Color typeColor =
        isMasuk ? const Color(0xFF16A34A) : const Color(0xFFEF4444);

    final Color typeSoftColor =
        isMasuk ? const Color(0xFFD8F3DC) : const Color(0xFFFDE2E2);

    final Color statusColor = isPending
        ? const Color(0xFFF59E0B)
        : isApproved
            ? const Color(0xFF16A34A)
            : const Color(0xFFEF4444);

    final Color statusSoftColor = isPending
        ? const Color(0xFFFFF7ED)
        : isApproved
            ? const Color(0xFFEFFDF5)
            : const Color(0xFFFFE4E6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPending ? const Color(0xFFFFFBEB) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isPending ? const Color(0xFFFCD34D) : const Color(0xFFE5E7EB),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: typeSoftColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isMasuk ? Icons.download_rounded : Icons.upload_rounded,
                    color: typeColor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            kode,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: typeColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          _smallBadge(
                            text: isMasuk ? 'Barang Masuk' : 'Barang Keluar',
                            color: typeColor,
                            bgColor: typeSoftColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$partnerLabel: $supplier',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(
                  text: status,
                  color: statusColor,
                  bgColor: statusSoftColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _detailMini(
                      icon: Icons.calendar_today_outlined,
                      label: 'Tanggal',
                      value: tanggal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _detailMini(
                      icon: Icons.inventory_2_outlined,
                      label: 'Jumlah',
                      value: totalBarang,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _detailMini(
                      icon: Icons.warehouse_outlined,
                      label: 'Gudang',
                      value: warehouse,
                    ),
                  ),
                ],
              ),
            ),
            if (isRejected && alasan != null && alasan!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'Alasan ditolak: $alasan',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _smallBadge({
    required String text,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statusBadge({
    required String text,
    required Color color,
    required Color bgColor,
  }) {
    IconData icon;

    if (text == 'Pending') {
      icon = Icons.schedule_rounded;
    } else if (text == 'Disetujui') {
      icon = Icons.check_circle_outline_rounded;
    } else {
      icon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailMini({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9.5,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}