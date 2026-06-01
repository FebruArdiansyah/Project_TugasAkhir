import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'app_bottom_nav.dart';

class StokBarangScreen extends StatefulWidget {
  const StokBarangScreen({super.key});

  @override
  State<StokBarangScreen> createState() => _StokBarangScreenState();
}

class _StokBarangScreenState extends State<StokBarangScreen> {
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
        final item = raw as Map<String, dynamic>;

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

      setState(() {
        stokItems = mappedItems;
        _resetPage();

        if (!availableGudang.contains(selectedGudang)) {
          selectedGudang = 'Semua Gudang';
        }
      });
    } on ApiException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
      _showSnackBar(e.message, isError: true);
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final items = filteredItems;
    final visibleItems = paginatedItems;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF7),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 2),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStocks,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              if (isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: const LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: Color(0xFFE5E7EB),
                        color: Color(0xFF0D5BFF),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  child: Column(
                    children: [
                      _buildSearchAndFilterRow(),
                      const SizedBox(height: 10),
                      _buildGudangDropdown(),
                      const SizedBox(height: 10),
                      _buildStockDisplay(),
                      const SizedBox(height: 10),
                      _buildStatusFilter(),
                      const SizedBox(height: 14),
                      _buildSectionTitle(items.length),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              if (errorMessage != null && stokItems.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    child: _buildErrorState(),
                  ),
                )
              else if (items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    child: _buildEmptyState(),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildStockCard(visibleItems[index]),
                        );
                      },
                      childCount: visibleItems.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    child: _buildPagination(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1677FF),
            Color(0xFF0D5BFF),
            Color(0xFF2F47B7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x260D5BFF),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stok Gudang',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Cari dan pantau stok barang secara cepat',
            style: TextStyle(
              color: Color(0xFFEAF1FF),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
        InkWell(
          onTap: _showAdvancedFilterSheet,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: _softBoxDecoration(),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF0D5BFF),
                  size: 22,
                ),
              ),
              if (isAdvancedFilterActive)
                Positioned(
                  right: 8,
                  top: 8,
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
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _softBoxDecoration(),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF6B7280),
            size: 21,
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
              decoration: const InputDecoration(
                hintText: 'Cari barang, kode, atau gudang',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
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
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _softBoxDecoration(),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warehouse_outlined,
              color: Color(0xFF0D5BFF),
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
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF6B7280),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
                items: gudangList.map((gudang) {
                  return DropdownMenuItem(
                    value: gudang,
                    child: Text(gudang),
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
      padding: const EdgeInsets.all(12),
      decoration: _softBoxDecoration(
        radius: 18,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF0D5BFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Stok Tersedia',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatQty(totalQty)} PCS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$totalItem Barang',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF0D5BFF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(13),
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
              fontSize: 13,
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
                fontWeight: FontWeight.w800,
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
            color: const Color(0xFF0D5BFF),
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

    return InkWell(
      onTap: () {
        setState(() {
          selectedFilter = value;
          _resetPage();
        });
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? color : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? color : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: active ? color.withOpacity(0.18) : const Color(0x0D000000),
              blurRadius: active ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : const Color(0xFF374151),
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
            color: Color(0xFF111827),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            '$count barang',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B7280),
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

    return InkWell(
      onTap: () {
        _showStockDetail(item);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _softBoxDecoration(radius: 18),
        child: Row(
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item['code'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['warehouse'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Update: ${_formatDate(updatedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatQty(qty),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _formatQty(qty).length > 4 ? 15 : 20,
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    item['unit'].toString(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _statusBadge(status, statusColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandInitial(String brand) {
    final String initial = brand.isNotEmpty ? brand[0] : '-';

    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Color(0xFF0D5BFF),
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Row(
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
        ...List.generate(totalPages, (index) {
          final page = index + 1;
          final active = currentPage == page;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () {
                setState(() {
                  currentPage = page;
                });
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF2F47B7) : Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF2F47B7)
                        : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$page',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : const Color(0xFF374151),
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
            if (currentPage < totalPages) {
              setState(() {
                currentPage++;
              });
            }
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
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? const Color(0xFF2F47B7) : const Color(0xFFB8C0CC),
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
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Filter Stok Barang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Filter berdasarkan tanggal update dan jumlah stok.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tanggal Update Stok',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 14),
                      const Text(
                        'Rentang Jumlah Stok',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
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
                                  size: 17,
                                ),
                                label: const Text('Reset'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6B7280),
                                  side: const BorderSide(
                                    color: Color(0xFFD1D5DB),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
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
                                  size: 17,
                                ),
                                label: const Text('Terapkan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D5BFF),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
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
                      : const Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: Color(0xFF0D5BFF),
            ),
          ],
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
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF111827),
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 12.5,
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF0D5BFF),
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
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(22),
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
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        _statusBadge(
                          item['status'].toString(),
                          statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF111827),
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
        vertical: 34,
        horizontal: 16,
      ),
      decoration: _softBoxDecoration(radius: 18),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 44,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 10),
          Text(
            'Barang tidak ditemukan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Coba ubah pencarian, gudang, atau filter stok.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
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
      decoration: _softBoxDecoration(radius: 18),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 44,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 10),
          const Text(
            'Gagal memuat stok',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            errorMessage ?? 'Terjadi kesalahan saat memuat data.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _loadStocks,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D5BFF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _softBoxDecoration({
    double radius = 16,
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: const Color(0xFFE5E7EB),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF0D5BFF),
      ),
    );
  }
}