import 'package:flutter/material.dart';

typedef ProductTextGetter = String Function(Map<String, dynamic> item);
typedef ProductIdGetter = int Function(dynamic value);
typedef ProductSelectedCallback = void Function(Map<String, dynamic> item);

typedef ProductLogoBuilder = Widget Function(
  Map<String, dynamic> item, {
  double size,
  bool selected,
});

void showMasterProductPicker({
  required BuildContext context,
  required TextEditingController searchController,
  required List<Map<String, dynamic>> products,
  required int? selectedProductId,
  required ProductIdGetter toInt,
  required ProductTextGetter productDisplayName,
  required ProductTextGetter productCode,
  required ProductTextGetter productUnit,
  required ProductTextGetter productType,
  required ProductTextGetter productDensity,
  required ProductTextGetter productCategory,
  required ProductTextGetter productSize,
  required ProductLogoBuilder productLogoBuilder,
  required ProductSelectedCallback onSelected,
  required VoidCallback onRequestNewProduct,
}) {
  searchController.clear();

  String selectedType = 'Semua';
  String selectedDensity = 'Semua';
  String selectedCategory = 'Semua';
  String selectedUnit = 'Semua';

  final typeOptions = _productFilterOptions(
    products: products,
    getter: productType,
  );
  final densityOptions = _productFilterOptions(
    products: products,
    getter: productDensity,
  );
  final categoryOptions = _productFilterOptions(
    products: products,
    getter: productCategory,
  );
  final unitOptions = _productFilterOptions(
    products: products,
    getter: productUnit,
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = _filteredMasterProducts(
            products: products,
            keyword: searchController.text,
            type: selectedType,
            density: selectedDensity,
            category: selectedCategory,
            unit: selectedUnit,
            productDisplayName: productDisplayName,
            productCode: productCode,
            productType: productType,
            productDensity: productDensity,
            productCategory: productCategory,
            productUnit: productUnit,
            productSize: productSize,
          );

          final activeFilterCount = _activeFilterCount(
            selectedType: selectedType,
            selectedDensity: selectedDensity,
            selectedCategory: selectedCategory,
            selectedUnit: selectedUnit,
          );

          void resetFilter() {
            setModalState(() {
              selectedType = 'Semua';
              selectedDensity = 'Semua';
              selectedCategory = 'Semua';
              selectedUnit = 'Semua';
            });
          }

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
                    _pickerHeader(
                      totalProduct: products.length,
                      onRequestNewProduct: () {
                        Navigator.pop(context);
                        onRequestNewProduct();
                      },
                    ),
                    const SizedBox(height: 14),
                    _searchField(
                      controller: searchController,
                      onChanged: (_) {
                        setModalState(() {});
                      },
                      onClear: () {
                        searchController.clear();
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ProductFilterDropdown(
                            label: 'Tipe',
                            value: selectedType,
                            items: typeOptions,
                            onChanged: (value) {
                              setModalState(() {
                                selectedType = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ProductFilterDropdown(
                            label: 'Density',
                            value: selectedDensity,
                            items: densityOptions,
                            onChanged: (value) {
                              setModalState(() {
                                selectedDensity = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ProductFilterDropdown(
                            label: 'Kategori',
                            value: selectedCategory,
                            items: categoryOptions,
                            onChanged: (value) {
                              setModalState(() {
                                selectedCategory = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ProductFilterDropdown(
                            label: 'Satuan',
                            value: selectedUnit,
                            items: unitOptions,
                            onChanged: (value) {
                              setModalState(() {
                                selectedUnit = value;
                              });
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
                            ? const _EmptyProductPickerState()
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
                                      selectedProductId == toInt(item['id']);

                                  return _ProductPickerOption(
                                    item: item,
                                    isSelected: isSelected,
                                    title: productDisplayName(item),
                                    code: productCode(item),
                                    unit: productUnit(item),
                                    typeName: productType(item),
                                    densityName: productDensity(item),
                                    categoryName: productCategory(item),
                                    sizeText: productSize(item),
                                    productLogoBuilder: productLogoBuilder,
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

Widget _pickerHeader({
  required int totalProduct,
  required VoidCallback onRequestNewProduct,
}) {
  return Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFBFDBFE),
          ),
        ),
        child: const Icon(
          Icons.inventory_2_outlined,
          color: Color(0xFF0D5BFF),
          size: 21,
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Barang Master',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$totalProduct barang tersedia di master produk',
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
      const SizedBox(width: 8),
      InkWell(
        onTap: onRequestNewProduct,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFFED7AA),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 14,
                color: Color(0xFFF59E0B),
              ),
              SizedBox(width: 4),
              Text(
                'Ajukan',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
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
              hintText: 'Cari nama, kode, tipe, ukuran...',
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
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFFBFDBFE),
                  ),
                ),
                child: Text(
                  '$activeFilterCount filter aktif',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF0D5BFF),
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
            foregroundColor: const Color(0xFF0D5BFF),
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

List<String> _productFilterOptions({
  required List<Map<String, dynamic>> products,
  required ProductTextGetter getter,
}) {
  final values = <String>{};

  for (final item in products) {
    final value = _safeText(getter(item));

    if (value.isNotEmpty && value != '-') {
      values.add(value);
    }
  }

  final sorted = values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return ['Semua', ...sorted];
}

List<Map<String, dynamic>> _filteredMasterProducts({
  required List<Map<String, dynamic>> products,
  required String keyword,
  required String type,
  required String density,
  required String category,
  required String unit,
  required ProductTextGetter productDisplayName,
  required ProductTextGetter productCode,
  required ProductTextGetter productType,
  required ProductTextGetter productDensity,
  required ProductTextGetter productCategory,
  required ProductTextGetter productUnit,
  required ProductTextGetter productSize,
}) {
  final query = keyword.trim().toLowerCase();

  return products.where((item) {
    final nameText = _safeText(productDisplayName(item));
    final codeText = _safeText(productCode(item));
    final typeText = _safeText(productType(item));
    final densityText = _safeText(productDensity(item));
    final categoryText = _safeText(productCategory(item));
    final unitText = _safeText(productUnit(item));
    final sizeText = _safeText(productSize(item));

    final searchableText = [
      nameText,
      codeText,
      typeText,
      densityText,
      categoryText,
      unitText,
      sizeText,
    ].join(' ').toLowerCase();

    final matchSearch = query.isEmpty || searchableText.contains(query);

    final matchType = type == 'Semua' || typeText == type;
    final matchDensity = density == 'Semua' || densityText == density;
    final matchCategory = category == 'Semua' || categoryText == category;
    final matchUnit = unit == 'Semua' || unitText == unit;

    return matchSearch &&
        matchType &&
        matchDensity &&
        matchCategory &&
        matchUnit;
  }).toList();
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

String _safeText(String value, {String fallback = '-'}) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

class _ProductFilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _ProductFilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value != 'Semua';

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color:
              isActive ? const Color(0xFFBFDBFE) : const Color(0xFFE5E7EB),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color:
                isActive ? const Color(0xFF0D5BFF) : const Color(0xFF6B7280),
          ),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
          selectedItemBuilder: (context) {
            return items.map((item) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value == 'Semua' ? label : item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: value == 'Semua'
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF0D5BFF),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }).toList();
          },
          items: items.map((item) {
            final isDefault = item == 'Semua';

            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                isDefault ? '$label: Semua' : item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDefault
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF111827),
                  fontWeight: isDefault ? FontWeight.w600 : FontWeight.w800,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue == null) return;
            onChanged(newValue);
          },
        ),
      ),
    );
  }
}

class _EmptyProductPickerState extends StatelessWidget {
  const _EmptyProductPickerState();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('empty-master-product'),
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
              'Coba ubah kata kunci, reset filter, atau ajukan barang baru.',
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

class _ProductPickerOption extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelected;
  final String title;
  final String code;
  final String unit;
  final String typeName;
  final String densityName;
  final String categoryName;
  final String sizeText;
  final VoidCallback onTap;
  final ProductLogoBuilder productLogoBuilder;

  const _ProductPickerOption({
    required this.item,
    required this.isSelected,
    required this.title,
    required this.code,
    required this.unit,
    required this.typeName,
    required this.densityName,
    required this.categoryName,
    required this.sizeText,
    required this.onTap,
    required this.productLogoBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final safeTitle = _safeText(title, fallback: 'Barang master');
    final safeCode = _safeText(code);
    final safeUnit = _safeText(unit);
    final safeType = _safeText(typeName);
    final safeDensity = _safeText(densityName);
    final safeCategory = _safeText(categoryName);
    final safeSize = _safeText(sizeText);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFBFDBFE)
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                productLogoBuilder(
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
                        color: Color(0xFF0D5BFF),
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
                _unitBadge(safeUnit),
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
    );
  }

  Widget _unitBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10.8,
          color: Color(0xFF0D5BFF),
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
            color: const Color(0xFF0D5BFF),
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