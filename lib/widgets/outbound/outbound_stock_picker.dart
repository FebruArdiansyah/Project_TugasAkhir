import 'package:flutter/material.dart';

typedef StockTextGetter = String Function(Map<String, dynamic> item);
typedef StockQtyGetter = double Function(Map<String, dynamic> item);
typedef StockKeyGetter = String Function(Map<String, dynamic> item);
typedef StockSelectedCallback = void Function(Map<String, dynamic> item);

typedef StockLogoBuilder = Widget Function(
  Map<String, dynamic> item, {
  double size,
  bool selected,
});

void showOutboundStockPicker({
  required BuildContext context,
  required TextEditingController searchController,
  required List<Map<String, dynamic>> stocks,
  required String? selectedStockKey,
  required StockKeyGetter stockKey,
  required StockTextGetter stockProductName,
  required StockTextGetter stockProductCode,
  required StockTextGetter stockWarehouseName,
  required StockTextGetter stockSize,
  required StockTextGetter stockUnit,
  required StockTextGetter stockType,
  required StockTextGetter stockDensity,
  required StockTextGetter stockCategory,
  required StockQtyGetter availableQty,
  required StockSelectedCallback onSelected,
  StockLogoBuilder? stockLogoBuilder,
}) {
  searchController.clear();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      List<Map<String, dynamic>> filtered = List.from(stocks);

      String selectedType = 'Semua';
      String selectedDensity = 'Semua';
      String selectedCategory = 'Semua';
      String selectedUnit = 'Semua';

      final typeOptions = _buildOptions(stocks, stockType);
      final densityOptions = _buildOptions(stocks, stockDensity);
      final categoryOptions = _buildOptions(stocks, stockCategory);
      final unitOptions = _buildOptions(stocks, stockUnit);

      return StatefulBuilder(
        builder: (context, setModalState) {
          void runFilter() {
            final query = searchController.text.trim().toLowerCase();

            setModalState(() {
              filtered = stocks.where((item) {
                final code = _safeText(stockProductCode(item)).toLowerCase();
                final name = _safeText(stockProductName(item)).toLowerCase();
                final gudang = _safeText(stockWarehouseName(item)).toLowerCase();
                final ukuran = _safeText(stockSize(item)).toLowerCase();

                final type = _safeText(stockType(item));
                final density = _safeText(stockDensity(item));
                final category = _safeText(stockCategory(item));
                final unit = _safeText(stockUnit(item));

                final matchSearch = query.isEmpty ||
                    code.contains(query) ||
                    name.contains(query) ||
                    gudang.contains(query) ||
                    ukuran.contains(query);

                final matchType =
                    selectedType == 'Semua' || type == selectedType;
                final matchDensity =
                    selectedDensity == 'Semua' || density == selectedDensity;
                final matchCategory =
                    selectedCategory == 'Semua' || category == selectedCategory;
                final matchUnit =
                    selectedUnit == 'Semua' || unit == selectedUnit;

                return matchSearch &&
                    matchType &&
                    matchDensity &&
                    matchCategory &&
                    matchUnit;
              }).toList();
            });
          }

          void resetFilter() {
            selectedType = 'Semua';
            selectedDensity = 'Semua';
            selectedCategory = 'Semua';
            selectedUnit = 'Semua';
            runFilter();
          }

          final activeFilterCount = _activeFilterCount(
            selectedType: selectedType,
            selectedDensity: selectedDensity,
            selectedCategory: selectedCategory,
            selectedUnit: selectedUnit,
          );

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sheetHeader(totalStock: stocks.length),
                    const SizedBox(height: 14),
                    _searchField(
                      controller: searchController,
                      onChanged: (_) => runFilter(),
                      onClear: () {
                        searchController.clear();
                        runFilter();
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _dropdownFilter(
                            label: 'Tipe',
                            value: selectedType,
                            items: typeOptions,
                            onChanged: (value) {
                              selectedType = value ?? 'Semua';
                              runFilter();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dropdownFilter(
                            label: 'Density',
                            value: selectedDensity,
                            items: densityOptions,
                            onChanged: (value) {
                              selectedDensity = value ?? 'Semua';
                              runFilter();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _dropdownFilter(
                            label: 'Kategori',
                            value: selectedCategory,
                            items: categoryOptions,
                            onChanged: (value) {
                              selectedCategory = value ?? 'Semua';
                              runFilter();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dropdownFilter(
                            label: 'Satuan',
                            value: selectedUnit,
                            items: unitOptions,
                            onChanged: (value) {
                              selectedUnit = value ?? 'Semua';
                              runFilter();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    _resultSummary(
                      total: filtered.length,
                      activeFilterCount: activeFilterCount,
                      onReset: resetFilter,
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: filtered.isEmpty
                            ? const _EmptyOutboundStockState()
                            : ListView.separated(
                                key: ValueKey(filtered.length),
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 4),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  final isSelected =
                                      selectedStockKey == stockKey(item);
                                  final qty = availableQty(item);
                                  final isEmpty = qty <= 0;
                                  final unitText = _safeText(stockUnit(item));

                                  return _OutboundStockOption(
                                    item: item,
                                    isSelected: isSelected,
                                    title: stockProductName(item),
                                    code: stockProductCode(item),
                                    warehouse: stockWarehouseName(item),
                                    sizeText: stockSize(item),
                                    unit: unitText,
                                    typeName: stockType(item),
                                    densityName: stockDensity(item),
                                    categoryName: stockCategory(item),
                                    qtyText: isEmpty
                                        ? 'Habis'
                                        : '${_formatQty(qty)} $unitText',
                                    isEmpty: isEmpty,
                                    stockLogoBuilder: stockLogoBuilder,
                                    onTap: () {
                                      onSelected(item);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                      ),
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

Widget _sheetHeader({
  required int totalStock,
}) {
  return Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFECACA),
          ),
        ),
        child: const Icon(
          Icons.outbox_outlined,
          color: Color(0xFFEF4444),
          size: 21,
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Barang Keluar',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$totalStock stok tersedia di daftar outbound',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _searchField({
  required TextEditingController controller,
  required ValueChanged<String> onChanged,
  required VoidCallback onClear,
}) {
  return Container(
    height: 46,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0xFFE5E7EB),
      ),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.search_rounded,
          size: 20,
          color: Color(0xFF6B7280),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Cari nama, kode, gudang, ukuran...',
              border: InputBorder.none,
              isCollapsed: true,
              hintStyle: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (controller.text.isNotEmpty)
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _resultSummary({
  required int total,
  required int activeFilterCount,
  required VoidCallback onReset,
}) {
  return Row(
    children: [
      Expanded(
        child: Row(
          children: [
            Flexible(
              child: Text(
                '$total barang ditemukan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (activeFilterCount > 0) ...[
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFFFECACA),
                  ),
                ),
                child: Text(
                  '$activeFilterCount filter aktif',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      if (activeFilterCount > 0)
        TextButton(
          onPressed: onReset,
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: const Color(0xFFEF4444),
          ),
          child: const Text(
            'Reset',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
    ],
  );
}

List<String> _buildOptions(
  List<Map<String, dynamic>> items,
  String Function(Map<String, dynamic>) getter,
) {
  final values = <String>{};

  for (final item in items) {
    final value = getter(item).trim();

    if (value.isNotEmpty && value != '-') {
      values.add(value);
    }
  }

  final sorted = values.toList()..sort();

  return ['Semua', ...sorted];
}

Widget _dropdownFilter({
  required String label,
  required String value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
}) {
  return Container(
    height: 46,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: const Color(0xFFE5E7EB),
      ),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        borderRadius: BorderRadius.circular(14),
        dropdownColor: Colors.white,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF6B7280),
        ),
        style: const TextStyle(
          fontSize: 12.3,
          color: Color(0xFF111827),
          fontWeight: FontWeight.w700,
        ),
        hint: Text(
          label,
          overflow: TextOverflow.ellipsis,
        ),
        items: items.map((item) {
          final isDefault = item == 'Semua';

          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              isDefault ? label : item,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.2,
                color: isDefault
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF111827),
                fontWeight: isDefault ? FontWeight.w600 : FontWeight.w800,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

String _formatQty(num value) {
  final doubleValue = value.toDouble();

  if (doubleValue % 1 == 0) {
    return doubleValue.toInt().toString();
  }

  return doubleValue.toStringAsFixed(2);
}

String _safeText(String value, {String fallback = '-'}) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

int _activeFilterCount({
  required String selectedType,
  required String selectedDensity,
  required String selectedCategory,
  required String selectedUnit,
}) {
  int count = 0;

  if (selectedType != 'Semua') count++;
  if (selectedDensity != 'Semua') count++;
  if (selectedCategory != 'Semua') count++;
  if (selectedUnit != 'Semua') count++;

  return count;
}

class _EmptyOutboundStockState extends StatelessWidget {
  const _EmptyOutboundStockState();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('empty-outbound-stock'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF9CA3AF),
                size: 30,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Barang tidak ditemukan',
              style: TextStyle(
                fontSize: 13.3,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Coba ubah kata kunci atau reset filter pencarian.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutboundStockOption extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelected;
  final String title;
  final String code;
  final String warehouse;
  final String sizeText;
  final String unit;
  final String typeName;
  final String densityName;
  final String categoryName;
  final String qtyText;
  final bool isEmpty;
  final VoidCallback onTap;
  final StockLogoBuilder? stockLogoBuilder;

  const _OutboundStockOption({
    required this.item,
    required this.isSelected,
    required this.title,
    required this.code,
    required this.warehouse,
    required this.sizeText,
    required this.unit,
    required this.typeName,
    required this.densityName,
    required this.categoryName,
    required this.qtyText,
    required this.isEmpty,
    required this.onTap,
    this.stockLogoBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final safeTitle = _safeText(title, fallback: 'Barang keluar');
    final safeCode = _safeText(code);
    final safeWarehouse = _safeText(warehouse);
    final safeSize = _safeText(sizeText);
    final safeUnit = _safeText(unit);
    final safeType = _safeText(typeName);
    final safeDensity = _safeText(densityName);
    final safeCategory = _safeText(categoryName);

    return InkWell(
      onTap: isEmpty ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Opacity(
        opacity: isEmpty ? 0.58 : 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFFFFECEC) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFE5E7EB),
              width: isSelected ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              stockLogoBuilder == null
                  ? _fallbackIcon(safeTitle)
                  : Stack(
                      clipBehavior: Clip.none,
                      children: [
                        stockLogoBuilder!(
                          item,
                          size: 44,
                          selected: isSelected,
                        ),
                        if (isSelected)
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Container(
                              width: 17,
                              height: 17,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      safeTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.9,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                        height: 1.16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.qr_code_2_rounded,
                          size: 13,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            safeCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.8,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _miniChip(Icons.location_on_outlined, safeWarehouse),
                        _miniChip(Icons.straighten_rounded, safeSize),
                        _miniChip(Icons.inventory_2_outlined, safeUnit),
                        _miniChip(Icons.category_outlined, safeType),
                        _miniChip(Icons.label_outline_rounded, safeDensity),
                        _miniChip(Icons.sell_outlined, safeCategory),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _qtyBadge(),
                  if (isSelected) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFDF5),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFFBBF7D0),
                        ),
                      ),
                      child: const Text(
                        'Dipilih',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isEmpty ? const Color(0xFFFFECEC) : const Color(0xFFEFFDF5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isEmpty ? const Color(0xFFFCA5A5) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Text(
        qtyText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.8,
          color: isEmpty ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _fallbackIcon(String safeTitle) {
    final initial = safeTitle.trim().isNotEmpty
        ? safeTitle.trim()[0].toUpperCase()
        : 'B';

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? const Color(0xFFFCA5A5) : const Color(0xFFFECACA),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 16,
          color: isSelected ? Colors.white : const Color(0xFFEF4444),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String text) {
    final safeText = _safeText(text);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 108),
            child: Text(
              safeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.3,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}