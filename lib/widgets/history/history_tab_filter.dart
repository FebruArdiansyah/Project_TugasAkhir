import 'package:flutter/material.dart';

class HistoryMainTabs extends StatelessWidget {
  final int selectedTypeFilter;
  final ValueChanged<int> onChanged;

  const HistoryMainTabs({
    super.key,
    required this.selectedTypeFilter,
    required this.onChanged,
  });

  static const Color _primaryBlue = Color(0xFF2F3192);
  static const Color _darkText = Color(0xFF4B5563);
  static const Color _borderColor = Color(0xFFD1D5DB);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _tabButton(
            text: 'Semua',
            value: 0,
            icon: Icons.grid_view_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tabButton(
            text: 'Masuk',
            value: 1,
            icon: Icons.download_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tabButton(
            text: 'Keluar',
            value: 2,
            icon: Icons.upload_rounded,
          ),
        ),
      ],
    );
  }

  Widget _tabButton({
    required String text,
    required int value,
    required IconData icon,
  }) {
    final active = selectedTypeFilter == value;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? _primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? _primaryBlue : _borderColor,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _primaryBlue.withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? Colors.white : _darkText,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.7,
                  color: active ? Colors.white : _darkText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryStatusTabs extends StatelessWidget {
  final String selectedStatusFilter;
  final ValueChanged<String> onChanged;

  const HistoryStatusTabs({
    super.key,
    required this.selectedStatusFilter,
    required this.onChanged,
  });

  static const Color _blue = Color(0xFF2F47B7);
  static const Color _blueSoft = Color(0xFFEFF6FF);
  static const Color _green = Color(0xFF16A34A);
  static const Color _greenSoft = Color(0xFFEFFDF5);
  static const Color _red = Color(0xFFEF4444);
  static const Color _redSoft = Color(0xFFFFE4E6);
  static const Color _orange = Color(0xFFF59E0B);
  static const Color _orangeSoft = Color(0xFFFFF7ED);
  static const Color _borderColor = Color(0xFFD1D5DB);
  static const Color _softText = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 37,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _statusButton(
            text: 'Semua Status',
            value: 'all',
            icon: Icons.tune_rounded,
            activeColor: _blue,
            activeBg: _blueSoft,
          ),
          const SizedBox(width: 8),
          _statusButton(
            text: 'Pending',
            value: 'pending',
            icon: Icons.schedule_rounded,
            activeColor: _orange,
            activeBg: _orangeSoft,
          ),
          const SizedBox(width: 8),
          _statusButton(
            text: 'Disetujui',
            value: 'approved',
            icon: Icons.check_circle_outline_rounded,
            activeColor: _green,
            activeBg: _greenSoft,
          ),
          const SizedBox(width: 8),
          _statusButton(
            text: 'Ditolak',
            value: 'rejected',
            icon: Icons.cancel_outlined,
            activeColor: _red,
            activeBg: _redSoft,
          ),
        ],
      ),
    );
  }

  Widget _statusButton({
    required String text,
    required String value,
    required IconData icon,
    required Color activeColor,
    required Color activeBg,
  }) {
    final active = selectedStatusFilter == value;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 37,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: active ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? activeColor : _borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: active ? 0.035 : 0.025),
              blurRadius: active ? 10 : 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active ? activeColor : _softText,
            ),
            const SizedBox(width: 5),
            Text(
              text,
              style: TextStyle(
                fontSize: 10.9,
                color: active ? activeColor : _softText,
                fontWeight: active ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}