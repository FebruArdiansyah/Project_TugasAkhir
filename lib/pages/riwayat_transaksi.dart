import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/api_service.dart';
import '../widgets/history/history_filter_sheet.dart';
import '../widgets/history/history_pagination.dart';
import '../widgets/history/history_search_bar.dart';
import '../widgets/history/history_tab_filter.dart';
import '../widgets/history/history_transaction_card.dart';
import 'app_bottom_nav.dart';
import 'detail_barang_keluar.dart';
import 'detail_barang_masuk.dart';

class RiwayatTransaksiScreen extends StatefulWidget {
  const RiwayatTransaksiScreen({super.key});

  @override
  State<RiwayatTransaksiScreen> createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  static const Color _bgColor = Color(0xFFF8FBFF);
  static const Color _primaryBlue = Color(0xFF005BEA);
  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF667085);
  static const Color _borderColor = Color(0xFFE5EAF2);

  int selectedTypeFilter = 0;
  String selectedStatusFilter = 'all';

  bool _isArgumentLoaded = false;
  bool isLoading = false;

  DateTime? dariTanggal;
  DateTime? sampaiTanggal;

  String? errorMessage;

  final TextEditingController searchController = TextEditingController();

  int currentPage = 1;
  final int itemsPerPage = 5;

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
      final tab = args['selectedTab'] as int;

      if (tab == 1 || tab == 2) {
        selectedTypeFilter = tab;
      } else if (tab == 3) {
        selectedStatusFilter = 'pending';
      } else if (tab == 4) {
        selectedStatusFilter = 'approved';
      } else if (tab == 5) {
        selectedStatusFilter = 'rejected';
      }
    }

    if (args is Map && args['selectedTypeFilter'] is int) {
      selectedTypeFilter = args['selectedTypeFilter'] as int;
    }

    if (args is Map && args['selectedStatusFilter'] is String) {
      selectedStatusFilter = args['selectedStatusFilter'] as String;
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
        final item = raw is Map<String, dynamic>
            ? raw
            : raw is Map
                ? Map<String, dynamic>.from(raw)
                : <String, dynamic>{};

        final type = item['type']?.toString() ?? '';
        final isMasuk = type == 'inbound';

        final tanggal = _parseDate(item['transaction_date']) ?? DateTime.now();
        final createdAt = _parseDateTime(item['created_at']) ?? tanggal;

        final inputOleh = _firstNonEmpty([
          item['submitted_by_name'],
          item['submitted_by'],
          item['created_by_name'],
          item['created_by'],
          item['user_name'],
          item['admin_name'],
          item['input_by_name'],
          item['input_by'],
        ]);

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
          'totalItems':
              int.tryParse(item['total_items']?.toString() ?? '0') ?? 0,
          'kode': item['transaction_number']?.toString() ?? '-',
          'referenceNumber': item['reference_number']?.toString(),
          'nama': item['type_label']?.toString() ??
              (isMasuk ? 'Barang Masuk' : 'Barang Keluar'),
          'status': _formatStatus(item['status']?.toString()),
          'inputOleh': inputOleh,
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

      if (!mounted) return;

      setState(() {
        transaksiList = mapped;
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

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = _readDisplayName(value);

      if (text.isNotEmpty && text != '-' && text.toLowerCase() != 'null') {
        return text;
      }
    }

    return '-';
  }

  String _readDisplayName(dynamic value) {
    if (value == null) return '';

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      final candidates = [
        map['name'],
        map['full_name'],
        map['nama'],
        map['nama_lengkap'],
        map['username'],
        map['email'],
      ];

      for (final candidate in candidates) {
        final text = candidate?.toString().trim() ?? '';

        if (text.isNotEmpty && text != '-' && text.toLowerCase() != 'null') {
          return text;
        }
      }

      return '';
    }

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '';
    }

    return text;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().trim();

    if (raw.isEmpty) return null;

    return DateTime.tryParse(raw);
  }

  DateTime? _parseDateTime(dynamic value) {
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

      if (selectedTypeFilter == 1 && !isMasuk) return false;
      if (selectedTypeFilter == 2 && isMasuk) return false;

      if (selectedStatusFilter == 'pending' && status != 'pending') {
        return false;
      }

      if (selectedStatusFilter == 'approved' && status != 'disetujui') {
        return false;
      }

      if (selectedStatusFilter == 'rejected' && status != 'ditolak') {
        return false;
      }

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
        final reference =
            item['referenceNumber']?.toString().toLowerCase() ?? '';

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

  bool get hasDateFilter => dariTanggal != null || sampaiTanggal != null;

  void _resetPage() {
    currentPage = 1;
  }

  Future<void> _openDetail(Map<String, dynamic> item) async {
    final type = item['type']?.toString();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          if (type == 'inbound' || type == 'masuk') {
            return const DetailBarangMasukScreen();
          }

          return const DetailBarangKeluarScreen();
        },
        settings: RouteSettings(
          arguments: {
            'id': item['id'],
          },
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadTransactions();
    }
  }

  void _showFilterDialog() {
    showHistoryDateFilterSheet(
      context: context,
      initialStartDate: dariTanggal,
      initialEndDate: sampaiTanggal,
      formatDate: formatDate,
      onApply: (startDate, endDate) {
        setState(() {
          dariTanggal = startDate;
          sampaiTanggal = endDate;
          _resetPage();
        });
      },
      onReset: () {
        setState(() {
          dariTanggal = null;
          sampaiTanggal = null;
          _resetPage();
        });
      },
    );
  }

  Widget _buildPagination() {
    return HistoryPagination(
      currentPage: currentPage,
      totalPages: totalPages,
      onPageChanged: (page) {
        setState(() {
          currentPage = page;
        });
      },
    );
  }

  Widget _animatedBox({
    required Widget child,
    required int index,
  }) {
    return child
        .animate()
        .fadeIn(
          delay: (70 * index).ms,
          duration: 500.ms,
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.045,
          end: 0,
          delay: (70 * index).ms,
          duration: 540.ms,
          curve: Curves.easeOutCubic,
        );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = paginatedList;

    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _HistoryBackgroundPainter(),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: _primaryBlue,
              backgroundColor: Colors.white,
              onRefresh: _loadTransactions,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _animatedBox(
                      index: 0,
                      child: _buildHeader(),
                    ),
                    const SizedBox(height: 16),
                    _animatedBox(
                      index: 1,
                      child: _buildSearchBar(),
                    ),
                    const SizedBox(height: 11),
                    _animatedBox(
                      index: 2,
                      child: _buildMainTabs(),
                    ),
                    const SizedBox(height: 11),
                    _animatedBox(
                      index: 3,
                      child: _buildStatusFilter(),
                    ),
                    _buildActiveFilterInfo(),
                    if (isLoading) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: const LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: Color(0xFFE5EAF2),
                          color: _primaryBlue,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildSectionTitle(),
                    const SizedBox(height: 11),
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
                          padding: const EdgeInsets.only(bottom: 11),
                          child: HistoryTransactionCard(
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
                          )
                              .animate()
                              .fadeIn(
                                delay: (45 * index).ms,
                                duration: 420.ms,
                                curve: Curves.easeOut,
                              )
                              .slideY(
                                begin: 0.04,
                                end: 0,
                                delay: (45 * index).ms,
                                duration: 460.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        );
                      }),
                    const SizedBox(height: 10),
                    _buildPagination(),
                    const SizedBox(height: 6),
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0EA5E9),
            Color(0xFF0062F5),
            Color(0xFF2F3192),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -34,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: -48,
            child: Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Transaksi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Pantau transaksi barang masuk dan keluar',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFEAF1FF),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: _loadTransactions,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return HistorySearchBar(
      controller: searchController,
      hasActiveFilter: hasDateFilter,
      onChanged: (_) {
        setState(() {
          _resetPage();
        });
      },
      onClear: () {
        searchController.clear();

        setState(() {
          _resetPage();
        });
      },
      onFilterTap: _showFilterDialog,
    );
  }

  Widget _buildMainTabs() {
    return HistoryMainTabs(
      selectedTypeFilter: selectedTypeFilter,
      onChanged: (value) {
        setState(() {
          selectedTypeFilter = value;
          _resetPage();
        });
      },
    );
  }

  Widget _buildStatusFilter() {
    return HistoryStatusTabs(
      selectedStatusFilter: selectedStatusFilter,
      onChanged: (value) {
        setState(() {
          selectedStatusFilter = value;
          _resetPage();
        });
      },
    );
  }

  Widget _buildActiveFilterInfo() {
    if (!hasDateFilter) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 11),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFBFDBFE),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.045),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: _primaryBlue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${dariTanggal == null ? 'Awal' : formatDate(dariTanggal!)} - ${sampaiTanggal == null ? 'Akhir' : formatDate(sampaiTanggal!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: _primaryBlue,
                  fontWeight: FontWeight.w800,
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
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(3),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: _primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    String typeTitle;

    if (selectedTypeFilter == 1) {
      typeTitle = 'Barang Masuk';
    } else if (selectedTypeFilter == 2) {
      typeTitle = 'Barang Keluar';
    } else {
      typeTitle = 'Semua Transaksi';
    }

    String statusTitle;

    if (selectedStatusFilter == 'pending') {
      statusTitle = 'Pending';
    } else if (selectedStatusFilter == 'approved') {
      statusTitle = 'Disetujui';
    } else if (selectedStatusFilter == 'rejected') {
      statusTitle = 'Ditolak';
    } else {
      statusTitle = '';
    }

    final title = statusTitle.isEmpty ? typeTitle : '$typeTitle - $statusTitle';

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _darkText,
              letterSpacing: -0.2,
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
            '${filteredList.length} data',
            style: const TextStyle(
              fontSize: 12,
              color: _softText,
              fontWeight: FontWeight.w900,
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
        vertical: 36,
        horizontal: 16,
      ),
      decoration: _softBoxDecoration(
        radius: 22,
        shadow: true,
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 46,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 11),
          Text(
            'Tidak ada transaksi',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Coba ubah pencarian, jenis transaksi, status, atau tanggal.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: _softText,
              fontWeight: FontWeight.w600,
              height: 1.28,
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
        vertical: 36,
        horizontal: 16,
      ),
      decoration: _softBoxDecoration(
        radius: 22,
        shadow: true,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 46,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 11),
          const Text(
            'Gagal memuat riwayat',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            errorMessage ?? 'Terjadi kesalahan saat memuat data.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: _softText,
              fontWeight: FontWeight.w600,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _loadTransactions,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _softBoxDecoration({
    double radius = 16,
    bool shadow = false,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: _borderColor,
      ),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.055),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ]
          : null,
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
        backgroundColor: isError ? const Color(0xFFEF4444) : _primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _HistoryBackgroundPainter extends CustomPainter {
  const _HistoryBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF8FBFF),
          Color(0xFFEFF6FF),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, basePaint);

    final Paint topGlow = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.05,
        colors: [
          const Color(0xFFD9EAFF).withValues(alpha: 0.88),
          const Color(0xFFEAF4FF).withValues(alpha: 0.38),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(
        Rect.fromLTWH(
          -size.width * 0.42,
          -size.height * 0.18,
          size.width * 1.12,
          size.height * 0.58,
        ),
      );

    canvas.drawOval(
      Rect.fromLTWH(
        -size.width * 0.42,
        -size.height * 0.18,
        size.width * 1.12,
        size.height * 0.58,
      ),
      topGlow,
    );

    final Paint rightGlow = Paint()
      ..shader = RadialGradient(
        center: Alignment.centerRight,
        radius: 0.95,
        colors: [
          const Color(0xFFD8EAFF).withValues(alpha: 0.58),
          const Color(0xFFEAF4FF).withValues(alpha: 0.26),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.60, 1.0],
      ).createShader(
        Rect.fromLTWH(
          size.width * 0.48,
          size.height * 0.20,
          size.width * 0.70,
          size.height * 0.55,
        ),
      );

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.50,
        size.height * 0.20,
        size.width * 0.76,
        size.height * 0.58,
      ),
      rightGlow,
    );

    final Paint bottomGlow = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomRight,
        radius: 1.02,
        colors: [
          const Color(0xFFD8EAFF).withValues(alpha: 0.72),
          const Color(0xFFEAF4FF).withValues(alpha: 0.36),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.62, 1.0],
      ).createShader(
        Rect.fromLTWH(
          size.width * 0.38,
          size.height * 0.68,
          size.width * 0.90,
          size.height * 0.48,
        ),
      );

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.38,
        size.height * 0.68,
        size.width * 0.90,
        size.height * 0.48,
      ),
      bottomGlow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}