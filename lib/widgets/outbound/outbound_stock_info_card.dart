import 'package:flutter/material.dart';

typedef OutboundInfoLogoBuilder = Widget Function(
  Map<String, dynamic> item, {
  double size,
  bool selected,
});

class OutboundStockInfoCard extends StatelessWidget {
  final Map<String, dynamic> stock;
  final String productName;
  final String productCode;
  final String unit;
  final String warehouseName;
  final String sizeText;
  final String typeName;
  final String densityName;
  final String categoryName;
  final double availableQty;
  final double availableAfterSelected;
  final double sisaStok;
  final bool barangHabis;
  final bool qtyKosongAtauNol;
  final bool stokTidakCukup;
  final String Function(num value) formatQty;
  final OutboundInfoLogoBuilder? logoBuilder;

  const OutboundStockInfoCard({
    super.key,
    required this.stock,
    required this.productName,
    required this.productCode,
    required this.unit,
    required this.warehouseName,
    required this.sizeText,
    required this.typeName,
    required this.densityName,
    required this.categoryName,
    required this.availableQty,
    required this.availableAfterSelected,
    required this.sisaStok,
    required this.barangHabis,
    required this.qtyKosongAtauNol,
    required this.stokTidakCukup,
    required this.formatQty,
    this.logoBuilder,
  });

  static const Color _primaryRed = Color(0xFFEF4444);
  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _cardBg = Color(0xFFFFFBFB);
  static const Color _softRedBg = Color(0xFFFFECEC);
  static const Color _softRedBorder = Color(0xFFFCA5A5);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _softRedBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  logoBuilder == null
                      ? _fallbackIcon()
                      : logoBuilder!(
                          stock,
                          size: 42,
                          selected: false,
                        ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _safeText(productName, fallback: 'Barang keluar'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.4,
                            color: _darkText,
                            fontWeight: FontWeight.w900,
                            height: 1.18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _mainChip(
                          Icons.qr_code_2_rounded,
                          _safeText(productCode, fallback: '-'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _miniChip(
                    Icons.inventory_2_outlined,
                    '${formatQty(availableQty)} ${_safeText(unit, fallback: '')}',
                  ),
                  _miniChip(
                    Icons.location_on_outlined,
                    warehouseName,
                  ),
                  _miniChip(
                    Icons.straighten_rounded,
                    sizeText,
                  ),
                  _miniChip(
                    Icons.category_outlined,
                    typeName,
                  ),
                  _miniChip(
                    Icons.label_outline_rounded,
                    densityName,
                  ),
                  _miniChip(
                    Icons.sell_outlined,
                    categoryName,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _qtySummaryRow(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _stockResultBox(),
      ],
    );
  }

  Widget _qtySummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _smallInfoBox(
            label: 'Stok tersedia',
            value: '${formatQty(availableQty)} ${_safeText(unit, fallback: '')}',
            icon: Icons.warehouse_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _smallInfoBox(
            label: 'Setelah dipilih',
            value:
                '${formatQty(availableAfterSelected)} ${_safeText(unit, fallback: '')}',
            icon: Icons.outbox_outlined,
          ),
        ),
      ],
    );
  }

  Widget _smallInfoBox({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _softRedBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 15,
              color: _primaryRed,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _softText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _safeText(value, fallback: '-'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.2,
                    color: _darkText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockResultBox() {
    late final Color color;
    late final Color bgColor;
    late final Color borderColor;
    late final IconData icon;
    late final String text;

    if (barangHabis) {
      color = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFFECEC);
      borderColor = const Color(0xFFFCA5A5);
      icon = Icons.cancel_outlined;
      text = 'Stok barang habis';
    } else if (qtyKosongAtauNol) {
      color = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFFFF7ED);
      borderColor = const Color(0xFFFED7AA);
      icon = Icons.warning_amber_rounded;
      text = 'Qty harus lebih dari 0';
    } else if (stokTidakCukup) {
      color = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFFECEC);
      borderColor = const Color(0xFFFCA5A5);
      icon = Icons.warning_amber_rounded;
      text = 'Stok tidak cukup';
    } else {
      color = const Color(0xFF16A34A);
      bgColor = const Color(0xFFEFFDF5);
      borderColor = const Color(0xFFBBF7D0);
      icon = Icons.check_circle_outline_rounded;
      text = '${formatQty(sisaStok)} ${_safeText(unit, fallback: '')}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sisa stok setelah keluar',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() {
    final initial = productName.trim().isNotEmpty
        ? productName.trim()[0].toUpperCase()
        : 'B';

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _softRedBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 16,
          color: _primaryRed,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _mainChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: _primaryRed,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              _safeText(text, fallback: '-'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.8,
                color: _darkText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String text) {
    final safeText = _safeText(text, fallback: '-');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: _primaryRed,
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 112),
            child: Text(
              safeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.3,
                color: _darkText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _safeText(String value, {String fallback = '-'}) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}