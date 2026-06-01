import 'package:flutter/material.dart';
import 'home.dart';
import 'riwayat_transaksi.dart';
import 'stok_barang.dart';
import 'profile.dart';

class AppBottomNav extends StatelessWidget {
  final int selectedIndex;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 70,
        color: Colors.white, // background putih
        child: Row(
          children: List.generate(4, (index) {
            final bool isActive = selectedIndex == index;
            IconData icon;
            String label;

            switch (index) {
              case 0:
                icon = Icons.home_rounded;
                label = 'Home';
                break;
              case 1:
                icon = Icons.receipt_long_rounded;
                label = 'Riwayat';
                break;
              case 2:
                icon = Icons.inventory_2_outlined;
                label = 'Stok';
                break;
              case 3:
                icon = Icons.person_rounded;
                label = 'Profil';
                break;
              default:
                icon = Icons.home;
                label = '';
            }

            return Expanded(
              child: InkWell(
                onTap: () {
                  if (index == selectedIndex) return;

                  Widget page;
                  if (index == 0) {
                    page = const HomeScreen();
                  } else if (index == 1) {
                    page = const RiwayatTransaksiScreen();
                  } else if (index == 2) {
                    page = const StokBarangScreen();
                  } else {
                    page = const ProfileScreen();
                  }

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => page),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 26,
                      color: isActive ? const Color(0xFF2563EB) : const Color(0xFF9A9A9A),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isActive ? const Color(0xFF2563EB) : const Color(0xFF9A9A9A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}