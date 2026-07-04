import 'package:flutter/material.dart';

class HistorySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasActiveFilter;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  const HistorySearchBar({
    super.key,
    required this.controller,
    required this.hasActiveFilter,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
  });

  static const Color _primaryBlue = Color(0xFF2F47B7);
  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF9CA3AF);
  static const Color _borderColor = Color(0xFFD1D5DB);
  static const Color _activeBg = Color(0xFFEFF6FF);
  static const Color _activeDot = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final hasSearch = controller.text.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasSearch
                    ? _primaryBlue.withValues(alpha: 0.35)
                    : _borderColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: hasSearch ? _primaryBlue : _softText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      fontSize: 12.8,
                      color: _darkText,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Cari kode, barang, supplier, status...',
                      hintStyle: TextStyle(
                        fontSize: 11.8,
                        color: _softText,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
                if (hasSearch)
                  InkWell(
                    onTap: onClear,
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: _softText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onFilterTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: hasActiveFilter ? _activeBg : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasActiveFilter ? _primaryBlue : _borderColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.filter_list_rounded,
                  size: 18,
                  color: _primaryBlue,
                ),
                const SizedBox(width: 5),
                Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 11.8,
                    color: _primaryBlue,
                    fontWeight:
                        hasActiveFilter ? FontWeight.w900 : FontWeight.w800,
                  ),
                ),
                if (hasActiveFilter) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: _activeDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}