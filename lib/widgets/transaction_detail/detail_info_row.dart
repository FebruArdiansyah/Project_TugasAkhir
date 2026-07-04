import 'package:flutter/material.dart';

class DetailInfoRow extends StatelessWidget {
  final List<String> leftItems;
  final List<String> rightItems;

  const DetailInfoRow({
    super.key,
    required this.leftItems,
    required this.rightItems,
  });

  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final totalRows =
        leftItems.length > rightItems.length ? leftItems.length : rightItems.length;

    return Column(
      children: List.generate(totalRows, (index) {
        final left = index < leftItems.length ? leftItems[index].trim() : '';
        final right = index < rightItems.length ? rightItems[index].trim() : '';

        return Container(
          margin: EdgeInsets.only(
            bottom: index == totalRows - 1 ? 0 : 8,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  left.isEmpty ? '-' : left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _softText,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 7,
                child: Text(
                  right.isEmpty ? '-' : right,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.2,
                    color: _darkText,
                    fontWeight: FontWeight.w900,
                    height: 1.28,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}