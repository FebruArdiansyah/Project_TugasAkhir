import 'package:flutter/material.dart';

class DetailOutboundItemCard extends StatelessWidget {
  final int index;
  final String productCode;
  final String productName;
  final String sizeText;
  final String warehouseName;
  final num qty;
  final String unitName;
  final num remainingStock;
  final String Function(num value) formatQty;
  final Widget? leading;

  const DetailOutboundItemCard({
    super.key,
    required this.index,
    required this.productCode,
    required this.productName,
    required this.sizeText,
    required this.warehouseName,
    required this.qty,
    required this.unitName,
    required this.remainingStock,
    required this.formatQty,
    required this.leading,
  });

  static const Color _primaryRed = Color(0xFFEF4444);
  static const Color _softRed = Color(0xFFFFF1F2);
  static const Color _borderRed = Color(0xFFFECACA);
  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _successGreen = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final safeProductName =
        productName.trim().isEmpty ? '-' : productName.trim();
    final safeProductCode =
        productCode.trim().isEmpty ? '-' : productCode.trim();
    final safeSize = sizeText.trim().isEmpty ? '-' : sizeText.trim();
    final safeWarehouse =
        warehouseName.trim().isEmpty ? '-' : warehouseName.trim();
    final safeUnit = unitName.trim().isEmpty ? 'PCS' : unitName.trim();

    final firstLetter = safeProductName == '-'
        ? 'B'
        : safeProductName.substring(0, 1).toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _softRed,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderRed,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topInfo(
            firstLetter: firstLetter,
            productName: safeProductName,
            productCode: safeProductCode,
            unitName: safeUnit,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _miniChip(
                icon: Icons.straighten_rounded,
                label: 'Ukuran',
                text: safeSize,
              ),
              _miniChip(
                icon: Icons.warehouse_outlined,
                label: 'Gudang',
                text: safeWarehouse,
              ),
              _miniChip(
                icon: Icons.inventory_outlined,
                label: 'Sisa Stok',
                text: '${formatQty(remainingStock)} $safeUnit',
                valueColor: _successGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topInfo({
    required String firstLetter,
    required String productName,
    required String productCode,
    required String unitName,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            leading ??
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      fontSize: 16,
                      color: _primaryRed,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _primaryRed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
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
              const Text(
                'Barang Keluar',
                style: TextStyle(
                  fontSize: 11,
                  color: _primaryRed,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.2,
                  color: _darkText,
                  fontWeight: FontWeight.w900,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 7),
              _primaryChip(
                icon: Icons.qr_code_2_rounded,
                text: productCode,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 0,
          child: _qtyBadge(unitName),
        ),
      ],
    );
  }

  Widget _qtyBadge(String unitName) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 104),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: _primaryRed,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AEF4444),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '${formatQty(qty)} $unitName',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _primaryChip({
    required IconData icon,
    required String text,
  }) {
    final safeText = text.trim().isEmpty ? '-' : text.trim();

    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
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
            size: 13,
            color: _primaryRed,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              safeText,
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

  Widget _miniChip({
    required IconData icon,
    required String label,
    required String text,
    Color valueColor = _darkText,
  }) {
    final safeText = text.trim().isEmpty ? '-' : text.trim();

    return Container(
      constraints: const BoxConstraints(maxWidth: 165),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: _softText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  safeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: valueColor,
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
}

class DetailOutboundTotalBox extends StatelessWidget {
  final int totalItems;
  final num totalQty;
  final String unitName;
  final String Function(num value) formatQty;

  const DetailOutboundTotalBox({
    super.key,
    required this.totalItems,
    required this.totalQty,
    required this.unitName,
    required this.formatQty,
  });

  static const Color _primaryRed = Color(0xFFEF4444);
  static const Color _darkRedText = Color(0xFF991B1B);
  static const Color _softText = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final safeUnit = unitName.trim().isEmpty ? 'PCS' : unitName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFCA5A5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.summarize_outlined,
              color: _primaryRed,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Barang Keluar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: _darkRedText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$totalItems item barang',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: _softText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 0,
            child: Text(
              '${formatQty(totalQty)} $safeUnit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: _primaryRed,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}