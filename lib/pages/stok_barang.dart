import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/api_service.dart';
import 'app_bottom_nav.dart';

class StokBarangScreen extends StatefulWidget {
  const StokBarangScreen({super.key});

  @override
  State<StokBarangScreen> createState() => _StokBarangScreenState();
}

class _StokBarangScreenState extends State<StokBarangScreen> {
  static const Color _bgColor = Color(0xFFF8FBFF);
  static const Color _primaryBlue = Color(0xFF005BEA);
  static const Color _darkBlue = Color(0xFF2F3192);
  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF667085);
  static const Color _borderColor = Color(0xFFE5EAF2);

  String selectedGudang = 'Semua Gudang';
  String selectedFilter = 'Semua';

  DateTime? filterTanggalDari;
  DateTime? filterTanggalSampai;

  int currentPage = 1;
  final int itemsPerPage = 4;

  bool isLoading = false;
  String? errorMessage;

  final TextEditingController searchController = TextEditingController();
  final TextEditingController minStokController = TextEditingController();
  final TextEditingController maxStokController = TextEditingController();

  List<Map<String, dynamic>> stokItems = [];

  @override
  void initState() {
    super.initState();
    _loadStocks();
  }

  @override
  void dispose() {
    searchController.dispose();
    minStokController.dispose();
    maxStokController.dispose();
    super.dispose();
  }

  Future<void> _loadStocks() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.get('/stocks');

      if (response is! Map<String, dynamic>) {
        throw ApiException(message: 'Response stok tidak valid.');
      }

      final data = response['data'];

      if (data is! List) {
        throw ApiException(message: 'Data stok tidak valid.');
      }

      final mappedItems = data.map<Map<String, dynamic>>((raw) {
        final Map<String, dynamic> item = raw is Map<String, dynamic>
            ? raw
            : raw is Map
                ? Map<String, dynamic>.from(raw)
                : {};

        final productName =
            item['product_display_name']?.toString().trim().isNotEmpty == true
                ? item['product_display_name'].toString()
                : item['product_name']?.toString() ?? '-';

        final qty = _toDouble(item['available_qty']);
        final minimumStock = _toDouble(item['minimum_stock']);
        final isLowStock = item['is_low_stock'] == true;

        return {
          'id': item['id'],
          'product_id': item['product_id'],
          'warehouse_id': item['warehouse_id'],
          'brand': _getBrandName(productName),
          'name': productName,
          'code': item['product_code']?.toString() ?? '-',
          'qty': qty,
          'unit': item['unit_name']?.toString() ?? 'PCS',
          'status': _getStockStatus(
            qty: qty,
            minimumStock: minimumStock,
            isLowStock: isLowStock,
          ),
          'warehouse': item['warehouse_name']?.toString() ?? '-',
          'warehouse_code': item['warehouse_code']?.toString() ?? '-',
          'size_text': _cleanText(item['product_size_text']),
          'qty_on_hand': _toDouble(item['qty_on_hand']),
          'qty_reserved': _toDouble(item['qty_reserved']),
          'minimum_stock': minimumStock,
          'updatedAt': DateTime.now(),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        stokItems = mappedItems;
        _resetPage();

        if (!availableGudang.contains(selectedGudang)) {
          selectedGudang = 'Semua Gudang';
        }
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
        errorMessage = 'Gagal memuat stok: $e';
      });

      _showSnackBar('Gagal memuat stok: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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

  String _cleanText(dynamic value) {
    if (value == null) return '';

    return value
        .toString()
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _getBrandName(String productName) {
    final cleaned = productName.trim();

    if (cleaned.isEmpty || cleaned == '-') return '-';

    if (cleaned.contains('-')) {
      return cleaned.split('-').first.trim();
    }

    final parts = cleaned.split(' ');

    return parts.first.trim();
  }

  String _getStockStatus({
    required double qty,
    required double minimumStock,
    required bool isLowStock,
  }) {
    if (qty <= 0) return 'Habis';
    if (isLowStock || qty <= minimumStock) return 'Menipis';

    return 'Aman';
  }

  List<String> get availableGudang {
    final warehouses = stokItems
        .map((item) => item['warehouse'].toString())
        .where((warehouse) => warehouse.trim().isNotEmpty && warehouse != '-')
        .toSet()
        .toList();

    warehouses.sort();

    return [
      'Semua Gudang',
      ...warehouses,
    ];
  }

  List<Map<String, dynamic>> get filteredItems {
    List<Map<String, dynamic>> result = List.from(stokItems);

    if (selectedGudang != 'Semua Gudang') {
      result = result.where((item) {
        return item['warehouse'] == selectedGudang;
      }).toList();
    }

    if (selectedFilter != 'Semua') {
      result = result.where((item) {
        return item['status'] == selectedFilter;
      }).toList();
    }

    if (filterTanggalDari != null) {
      final startDate = DateTime(
        filterTanggalDari!.year,
        filterTanggalDari!.month,
        filterTanggalDari!.day,
      );

      result = result.where((item) {
        final updatedAt = item['updatedAt'] as DateTime;
        return !updatedAt.isBefore(startDate);
      }).toList();
    }

    if (filterTanggalSampai != null) {
      final endDate = DateTime(
        filterTanggalSampai!.year,
        filterTanggalSampai!.month,
        filterTanggalSampai!.day,
        23,
        59,
        59,
      );

      result = result.where((item) {
        final updatedAt = item['updatedAt'] as DateTime;
        return !updatedAt.isAfter(endDate);
      }).toList();
    }

    final minStok = double.tryParse(minStokController.text.trim());
    final maxStok = double.tryParse(maxStokController.text.trim());

    if (minStok != null) {
      result = result.where((item) {
        return _toDouble(item['qty']) >= minStok;
      }).toList();
    }

    if (maxStok != null) {
      result = result.where((item) {
        return _toDouble(item['qty']) <= maxStok;
      }).toList();
    }

    final query = searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((item) {
        final brand = item['brand'].toString().toLowerCase();
        final name = item['name'].toString().toLowerCase();
        final code = item['code'].toString().toLowerCase();
        final warehouse = item['warehouse'].toString().toLowerCase();

        return brand.contains(query) ||
            name.contains(query) ||
            code.contains(query) ||
            warehouse.contains(query);
      }).toList();
    }

    result.sort((a, b) {
      final priorityA = _statusPriority(a['status'].toString());
      final priorityB = _statusPriority(b['status'].toString());

      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }

      return _toDouble(a['qty']).compareTo(_toDouble(b['qty']));
    });

    return result;
  }

  int get totalPages {
    if (filteredItems.isEmpty) return 1;
    return (filteredItems.length / itemsPerPage).ceil();
  }

  List<Map<String, dynamic>> get paginatedItems {
    final items = filteredItems;

    if (items.isEmpty) return [];

    final safePage = currentPage > totalPages ? totalPages : currentPage;
    final startIndex = (safePage - 1) * itemsPerPage;
    final rawEndIndex = startIndex + itemsPerPage;
    final endIndex = rawEndIndex > items.length ? items.length : rawEndIndex;

    return items.sublist(startIndex, endIndex);
  }

  int get totalItem => stokItems.length;

  double get totalQty {
    return stokItems.fold<double>(
      0,
      (total, item) => total + _toDouble(item['qty']),
    );
  }

  int get stokAman {
    return stokItems.where((item) => item['status'] == 'Aman').length;
  }

  int get stokMenipis {
    return stokItems.where((item) => item['status'] == 'Menipis').length;
  }

  int get stokHabis {
    return stokItems.where((item) => item['status'] == 'Habis').length;
  }

  bool get isAdvancedFilterActive {
    return filterTanggalDari != null ||
        filterTanggalSampai != null ||
        minStokController.text.trim().isNotEmpty ||
        maxStokController.text.trim().isNotEmpty;
  }

  void _resetPage() {
    currentPage = 1;
  }

  int _statusPriority(String status) {
    switch (status) {
      case 'Habis':
        return 0;
      case 'Menipis':
        return 1;
      case 'Aman':
        return 2;
      default:
        return 3;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aman':
        return const Color(0xFF16A34A);
      case 'Menipis':
        return const Color(0xFFF59E0B);
      case 'Habis':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Aman':
        return const Color(0xFFEFFDF5);
      case 'Menipis':
        return const Color(0xFFFFF7ED);
      case 'Habis':
        return const Color(0xFFFFECEC);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  String _formatDate(DateTime date) {
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
    final items = filteredItems;
    final visibleItems = paginatedItems;

    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: const AppBottomNav(selectedIndex: 2),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _StockBackgroundPainter(),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: _primaryBlue,
              backgroundColor: Colors.white,
              onRefresh: _loadStocks,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _animatedBox(
                      index: 0,
                      child: _buildHeader(),
                    ),
                  ),
                  if (isLoading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: const LinearProgressIndicator(
                            minHeight: 4,
                            backgroundColor: Color(0xFFE5EAF2),
                            color: _primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        children: [
                          _animatedBox(
                            index: 1,
                            child: _buildSearchAndFilterRow(),
                          ),
                          const SizedBox(height: 11),
                          _animatedBox(
                            index: 2,
                            child: _buildGudangDropdown(),
                          ),
                          const SizedBox(height: 13),
                          _animatedBox(
                            index: 3,
                            child: _buildStockDisplay(),
                          ),
                          const SizedBox(height: 13),
                          _animatedBox(
                            index: 4,
                            child: _buildStatusFilter(),
                          ),
                          const SizedBox(height: 16),
                          _buildSectionTitle(items.length),
                          const SizedBox(height: 11),
                        ],
                      ),
                    ),
                  ),
                  if (errorMessage != null && stokItems.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                        child: _buildErrorState(),
                      ),
                    )
                  else if (items.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                        child: _buildEmptyState(),
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 11),
                              child: _buildStockCard(visibleItems[index])
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
                          },
                          childCount: visibleItems.length,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                        child: _buildPagination(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
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
                    Icons.inventory_2_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stok Gudang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Cari dan pantau stok barang secara cepat',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSearchBox(),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: _showAdvancedFilterSheet,
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: _softBoxDecoration(
                    radius: 17,
                    shadow: true,
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: _primaryBlue,
                    size: 22,
                  ),
                ),
                if (isAdvancedFilterActive)
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _softBoxDecoration(
        radius: 17,
        shadow: true,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF8B96A8),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: (_) {
                setState(() {
                  _resetPage();
                });
              },
              cursorColor: _primaryBlue,
              decoration: const InputDecoration(
                hintText: 'Cari barang, kode, atau gudang',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: _darkText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (searchController.text.isNotEmpty)
            InkWell(
              onTap: () {
                searchController.clear();
                setState(() {
                  _resetPage();
                });
              },
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGudangDropdown() {
    final gudangList = availableGudang;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _softBoxDecoration(
        radius: 17,
        shadow: true,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.warehouse_outlined,
              color: _primaryBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: gudangList.contains(selectedGudang)
                    ? selectedGudang
                    : 'Semua Gudang',
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: Colors.white,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF8B96A8),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: _darkText,
                  fontWeight: FontWeight.w800,
                ),
                items: gudangList.map((gudang) {
                  return DropdownMenuItem(
                    value: gudang,
                    child: Text(
                      gudang,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedGudang = value;
                    _resetPage();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _softBoxDecoration(
        radius: 22,
        shadow: true,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: _primaryBlue,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Stok Tersedia',
                      style: TextStyle(
                        fontSize: 12,
                        color: _softText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatQty(totalQty)} PCS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        color: _darkText,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$totalItem Barang',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _primaryBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniStatusBox(
                  label: 'Aman',
                  value: '$stokAman',
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStatusBox(
                  label: 'Menipis',
                  value: '$stokMenipis',
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStatusBox(
                  label: 'Habis',
                  value: '$stokHabis',
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStatusBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Row(
      children: [
        Expanded(
          child: _statusChip(
            label: 'Semua',
            value: 'Semua',
            color: _primaryBlue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statusChip(
            label: 'Aman',
            value: 'Aman',
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statusChip(
            label: 'Menipis',
            value: 'Menipis',
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statusChip(
            label: 'Habis',
            value: 'Habis',
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _statusChip({
    required String label,
    required String value,
    required Color color,
  }) {
    final bool active = selectedFilter == value;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedFilter = value;
            _resetPage();
          });
        },
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 41,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? color : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? color : _borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? color.withValues(alpha: 0.20)
                    : const Color(0xFF1E3A8A).withValues(alpha: 0.05),
                blurRadius: active ? 12 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: active ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(int count) {
    return Row(
      children: [
        const Text(
          'Daftar Stok',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _darkText,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Text(
            '$count barang',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: _softText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockCard(Map<String, dynamic> item) {
    final status = item['status'].toString();
    final statusColor = _getStatusColor(status);
    final updatedAt = item['updatedAt'] as DateTime;
    final qty = _toDouble(item['qty']);
    final unit = item['unit'].toString();

    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () {
          _showStockDetail(item);
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: _softBoxDecoration(
            radius: 22,
            shadow: true,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _brandInitial(item['brand'].toString()),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'].toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.4,
                            fontWeight: FontWeight.w900,
                            color: _darkText,
                            height: 1.22,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['code'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.2,
                            color: _softText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 50,
                      maxWidth: 74,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatQty(qty),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: _formatQty(qty).length > 4 ? 16 : 22,
                            color: _darkText,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: _softText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _stockInfoPill(
                      icon: Icons.warehouse_outlined,
                      text: item['warehouse'].toString(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusBadge(status, statusColor),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  const Icon(
                    Icons.update_rounded,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Update: ${_formatDate(updatedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.8,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w800,
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
  }

  Widget _stockInfoPill({
    required IconData icon,
    required String text,
  }) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.8,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandInitial(String brand) {
    final cleanBrand = brand.trim();
    final String initial = cleanBrand.isNotEmpty && cleanBrand != '-'
        ? cleanBrand.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: 45,
      height: 45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDBEAFE),
        ),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: _primaryBlue,
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _getStatusBgColor(status),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'Aman'
                ? Icons.check_circle_rounded
                : status == 'Menipis'
                    ? Icons.warning_rounded
                    : Icons.cancel_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final pageItems = _visiblePaginationItems();

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.055),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _paginationArrow(
                icon: Icons.chevron_left_rounded,
                enabled: currentPage > 1,
                onTap: () {
                  if (currentPage > 1) {
                    setState(() {
                      currentPage--;
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ...pageItems.map((page) {
                if (page == null) {
                  return _paginationDots();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _paginationNumber(page),
                );
              }),
              const SizedBox(width: 8),
              _paginationArrow(
                icon: Icons.chevron_right_rounded,
                enabled: currentPage < totalPages,
                onTap: () {
                  if (currentPage < totalPages) {
                    setState(() {
                      currentPage++;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<int?> _visiblePaginationItems() {
    if (totalPages <= 5) {
      return List.generate(totalPages, (index) => index + 1);
    }

    final List<int?> pages = [];

    pages.add(1);

    int start = currentPage - 1;
    int end = currentPage + 1;

    if (start < 2) start = 2;
    if (end > totalPages - 1) end = totalPages - 1;

    if (start > 2) {
      pages.add(null);
    }

    for (int page = start; page <= end; page++) {
      pages.add(page);
    }

    if (end < totalPages - 1) {
      pages.add(null);
    }

    pages.add(totalPages);

    return pages;
  }

  Widget _paginationNumber(int page) {
    final active = currentPage == page;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: () {
          setState(() {
            currentPage = page;
          });
        },
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: active ? 35 : 31,
          height: 31,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? _darkBlue : Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: active ? _darkBlue : _borderColor,
            ),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: active ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paginationDots() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '...',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  Widget _paginationArrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled ? Colors.white : const Color(0xFFF3F4F6),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 31,
          height: 31,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? _darkBlue : const Color(0xFFB8C0CC),
          ),
        ),
      ),
    );
  }

  void _showAdvancedFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.86,
                ),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5EAF2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),
                      Row(
                        children: [
                          Container(
                            width: 39,
                            height: 39,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: _primaryBlue,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 11),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Filter Stok Barang',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: _darkText,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Atur tanggal update dan rentang jumlah stok.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: _softText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 17),
                      const Text(
                        'Tanggal Update Stok',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: _darkText,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                            child: _dateFilterBox(
                              label: 'Dari',
                              value: filterTanggalDari,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      filterTanggalDari ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );

                                if (picked != null) {
                                  setModalState(() {
                                    filterTanggalDari = picked;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _dateFilterBox(
                              label: 'Sampai',
                              value: filterTanggalSampai,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      filterTanggalSampai ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );

                                if (picked != null) {
                                  setModalState(() {
                                    filterTanggalSampai = picked;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Rentang Jumlah Stok',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: _darkText,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                            child: _numberFilterInput(
                              hint: 'Min',
                              controller: minStokController,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _numberFilterInput(
                              hint: 'Max',
                              controller: maxStokController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 19),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setModalState(() {
                                    filterTanggalDari = null;
                                    filterTanggalSampai = null;
                                    minStokController.clear();
                                    maxStokController.clear();
                                  });

                                  setState(() {
                                    _resetPage();
                                  });
                                },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                ),
                                label: const Text('Reset'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _softText,
                                  side: const BorderSide(
                                    color: Color(0xFFD1D5DB),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w900,
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

                                  Navigator.pop(context);
                                },
                                icon: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 18,
                                ),
                                label: const Text('Terapkan'),
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

  Widget _dateFilterBox({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 49,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value == null ? label : _formatDate(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: value == null
                        ? const Color(0xFF9CA3AF)
                        : _darkText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: _primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberFilterInput({
    required String hint,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      cursorColor: _primaryBlue,
      style: const TextStyle(
        fontSize: 13,
        color: _darkText,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 12.5,
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: _borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: _borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: _primaryBlue,
          ),
        ),
      ),
    );
  }

  void _showStockDetail(Map<String, dynamic> item) {
    final Color statusColor = _getStatusColor(item['status'].toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.84,
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5EAF2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _brandInitial(item['brand'].toString()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['name'].toString(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: _darkText,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusBadge(
                          item['status'].toString(),
                          statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    _detailRow('Kode Barang', item['code'].toString()),
                    _detailRow(
                      'Stok Tersedia',
                      '${_formatQty(_toDouble(item['qty']))} ${item['unit']}',
                    ),
                    _detailRow(
                      'Stok Fisik',
                      '${_formatQty(_toDouble(item['qty_on_hand']))} ${item['unit']}',
                    ),
                    _detailRow(
                      'Stok Reserved',
                      '${_formatQty(_toDouble(item['qty_reserved']))} ${item['unit']}',
                    ),
                    _detailRow(
                      'Minimum Stok',
                      '${_formatQty(_toDouble(item['minimum_stock']))} ${item['unit']}',
                    ),
                    if (_cleanText(item['size_text']).isNotEmpty)
                      _detailRow(
                        'Ukuran',
                        _cleanText(item['size_text']),
                      ),
                    _detailRow('Gudang', item['warehouse'].toString()),
                    _detailRow(
                      'Update Terakhir',
                      _formatDate(item['updatedAt'] as DateTime),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _softText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                color: _darkText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
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
            Icons.inventory_2_outlined,
            size: 46,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 11),
          Text(
            'Barang tidak ditemukan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Coba ubah pencarian, gudang, atau filter stok.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: _softText,
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
            'Gagal memuat stok',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF374151),
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
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _loadStocks,
            icon: const Icon(Icons.refresh_rounded, size: 18),
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

class _StockBackgroundPainter extends CustomPainter {
  const _StockBackgroundPainter();

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