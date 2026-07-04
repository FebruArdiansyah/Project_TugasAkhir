import 'package:flutter/material.dart';

typedef OutboundItemLogoBuilder = Widget Function(
  Map<String, dynamic> item, {
  double size,
  bool selected,
});

class OutboundItemCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  final String Function(num value) formatQty;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final OutboundItemLogoBuilder? productLogoBuilder;

  const OutboundItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.formatQty,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    this.productLogoBuilder,
  });

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0;
  }

  String _text(dynamic value) {
    if (value == null) return '-';

    final text = value.toString().trim();

    return text.isEmpty ? '-' : text;
  }

  String _initialText(String name) {
    final cleanName = name.trim();

    if (cleanName.isEmpty || cleanName == '-') return 'B';

    return cleanName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final qty = _toDouble(item['qty']);
    final name = _text(item['name']);
    final unit = _text(item['satuan']);
    final code = _text(item['code']);
    final warehouse = _text(item['gudang']);
    final size = _text(item['ukuran']);
    final type = _text(item['type_name']);
    final density = _text(item['density_name']);
    final category = _text(item['category_name']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(name),
          const SizedBox(height: 10),
          _primaryChip(
            Icons.qr_code_2_rounded,
            code,
          ),
          const SizedBox(height: 8),
          _buildInfoChips(
            unit: unit,
            type: type,
            density: density,
            category: category,
            size: size,
            warehouse: warehouse,
          ),
          const SizedBox(height: 12),
          _buildQtyControl(
            qty: qty,
            unit: unit,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      children: [
        productLogoBuilder == null
            ? _fallbackIcon(name)
            : productLogoBuilder!(
                item,
                size: 42,
                selected: false,
              ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Barang ${index + 1}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.2,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _removeButton(),
      ],
    );
  }

  Widget _removeButton() {
    return InkWell(
      onTap: onRemove,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFFCA5A5),
          ),
        ),
        child: const Icon(
          Icons.close_rounded,
          size: 17,
          color: Color(0xFFEF4444),
        ),
      ),
    );
  }

  Widget _buildInfoChips({
    required String unit,
    required String type,
    required String density,
    required String category,
    required String size,
    required String warehouse,
  }) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _miniChip(
          Icons.inventory_2_outlined,
          unit,
        ),
        _miniChip(
          Icons.category_outlined,
          type,
        ),
        _miniChip(
          Icons.label_outline_rounded,
          density,
        ),
        _miniChip(
          Icons.sell_outlined,
          category,
        ),
        _miniChip(
          Icons.straighten_rounded,
          size,
        ),
        _miniChip(
          Icons.location_on_outlined,
          warehouse,
        ),
      ],
    );
  }

  Widget _buildQtyControl({
    required double qty,
    required String unit,
  }) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Qty Keluar',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _qtyButton(
          icon: Icons.remove_rounded,
          onTap: onDecrease,
        ),
        const SizedBox(width: 8),
        Text(
          '${formatQty(qty)} $unit',
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        _qtyButton(
          icon: Icons.add_rounded,
          onTap: onIncrease,
        ),
      ],
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFFECACA),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: const Color(0xFFEF4444),
        ),
      ),
    );
  }

  Widget _fallbackIcon(String name) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initialText(name),
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFFEF4444),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _primaryChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
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
            size: 13,
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.8,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
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
            constraints: const BoxConstraints(
              maxWidth: 110,
            ),
            child: Text(
              text,
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