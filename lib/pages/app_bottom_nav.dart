import 'package:flutter/material.dart';

import 'home.dart';
import 'profile.dart';
import 'riwayat_transaksi.dart';
import 'stok_barang.dart';

class AppBottomNav extends StatelessWidget {
  final int selectedIndex;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
  });

  static const Color _borderColor = Color(0xFFE5EAF2);

  void _onItemTap(BuildContext context, int index) {
    if (index == selectedIndex) return;

    Widget page;

    switch (index) {
      case 0:
        page = const HomeScreen();
        break;
      case 1:
        page = const RiwayatTransaksiScreen();
        break;
      case 2:
        page = const StokBarangScreen();
        break;
      case 3:
        page = const ProfileScreen();
        break;
      default:
        page = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_BottomNavItem> items = [
      const _BottomNavItem(
        icon: Icons.home_rounded,
        label: 'Home',
      ),
      const _BottomNavItem(
        icon: Icons.receipt_long_rounded,
        label: 'Riwayat',
      ),
      const _BottomNavItem(
        icon: Icons.inventory_2_outlined,
        label: 'Stok',
      ),
      const _BottomNavItem(
        icon: Icons.person_rounded,
        label: 'Profil',
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 74,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (index) {
              final bool isActive = selectedIndex == index;
              final item = items[index];

              return Expanded(
                child: _BottomNavButton(
                  item: item,
                  isActive: isActive,
                  onTap: () => _onItemTap(context, index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  final _BottomNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  static const Color _primaryBlue = Color(0xFF005BEA);
  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF8B96A8);
  static const Color _softBlue = Color(0xFFEFF6FF);

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isActive ? _primaryBlue : _softText;
    final Color textColor = isActive ? _darkText : _softText;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: _primaryBlue.withValues(alpha: 0.08),
        highlightColor: _primaryBlue.withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? _softBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                scale: isActive ? 1.10 : 1.0,
                child: Icon(
                  item.icon,
                  size: 25,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1,
                  color: textColor,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: -0.1,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final String label;

  const _BottomNavItem({
    required this.icon,
    required this.label,
  });
}