import 'package:flutter/material.dart';

class DetailItemCard extends StatelessWidget {
  final int index;
  final String productName;
  final String productCode;
  final String unitName;
  final String sizeText;
  final String note;
  final num qty;
  final num unitCost;
  final num subtotal;
  final String Function(num value) formatQty;
  final String Function(num value) formatCurrency;
  final Widget? leading;

  const DetailItemCard({
    super.key,
    required this.index,
    required this.productName,
    required this.productCode,
    required this.unitName,
    required this.sizeText,
    required this.note,
    required this.qty,
    required this.unitCost,
    required this.subtotal,
    required this.formatQty,
    required this.formatCurrency,
    this.leading,
  });

  static const Color _primaryGreen = Color(0xFF16A34A);
  static const Color _softGreen = Color(0xFFEFFDF5);
  static const Color _borderGreen = Color(0xFFBBF7D0);
  static const Color _darkText = Color(0xFF111827);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _primaryBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final safeProductName =
        productName.trim().isEmpty ? '-' : productName.trim();
    final safeProductCode =
        productCode.trim().isEmpty ? '-' : productCode.trim();
    final safeUnit = unitName.trim().isEmpty ? 'PCS' : unitName.trim();
    final safeSize = sizeText.trim().isEmpty ? '-' : sizeText.trim();
    final safeNote = note.trim();

    final firstLetter = safeProductName == '-'
        ? 'B'
        : safeProductName.characters.first.toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderGreen,
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
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _miniChip(
                icon: Icons.inventory_2_outlined,
                text: '${formatQty(qty)} $safeUnit',
              ),
              _miniChip(
                icon: Icons.payments_outlined,
                text: formatCurrency(unitCost),
              ),
              _miniChip(
                icon: Icons.straighten_rounded,
                text: safeSize,
              ),
            ],
          ),
          if (safeNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            _noteBox(safeNote),
          ],
          const SizedBox(height: 10),
          _subtotalBox(),
        ],
      ),
    );
  }

  Widget _topInfo({
    required String firstLetter,
    required String productName,
    required String productCode,
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
                      color: const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      fontSize: 16,
                      color: _primaryBlue,
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
                  color: _primaryGreen,
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
                'Barang Masuk',
                style: TextStyle(
                  fontSize: 11,
                  color: _primaryGreen,
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
      ],
    );
  }

  Widget _noteBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF374151),
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _subtotalBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.request_quote_outlined,
            color: _primaryGreen,
            size: 16,
          ),
          const SizedBox(width: 7),
          const Expanded(
            child: Text(
              'Subtotal',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Flexible(
            child: Text(
              formatCurrency(subtotal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                color: _primaryGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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
            color: _primaryGreen,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              safeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
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
    required String text,
  }) {
    final safeText = text.trim().isEmpty ? '-' : text.trim();

    return Container(
      constraints: const BoxConstraints(maxWidth: 165),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFD1FAE5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: _primaryGreen,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              safeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: _darkText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}