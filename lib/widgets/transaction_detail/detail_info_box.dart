import 'package:flutter/material.dart';

class DetailInfoBox extends StatelessWidget {
  final String title;
  final String value;
  final Color? borderColor;
  final Color? backgroundColor;

  const DetailInfoBox({
    super.key,
    required this.title,
    required this.value,
    this.borderColor,
    this.backgroundColor,
  });

  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _darkText = Color(0xFF374151);
  static const Color _softText = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.trim().isEmpty ? 'Informasi' : title.trim();
    final displayValue = value.trim().isEmpty ? '-' : value.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: borderColor ?? _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.8,
              color: _softText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 11.8,
              color: _darkText,
              fontWeight: FontWeight.w600,
              height: 1.38,
            ),
          ),
        ],
      ),
    );
  }
}