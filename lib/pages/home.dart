import 'package:flutter/material.dart';

import 'barang_masuk.dart';
import 'barang_keluar.dart';
import 'riwayat_transaksi.dart';
import 'stok_barang.dart';
import 'app_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> attentionItems = [
    {
      'status': 'Habis',
      'name': 'QUANTUM - QN1 200x160x20',
      'qty': '0 PCS',
      'color': const Color(0xFFEF4444),
      'bgColor': const Color(0xFFFFECEC),
    },
    {
      'status': 'Menipis',
      'name': 'INOAC - EON 100x200x10',
      'qty': '12 PCS',
      'color': const Color(0xFFF59E0B),
      'bgColor': const Color(0xFFFFF7ED),
    },
    {
      'status': 'Menipis',
      'name': 'ROYAL FOAM - RF 180x200x20',
      'qty': '8 PCS',
      'color': const Color(0xFFF59E0B),
      'bgColor': const Color(0xFFFFF7ED),
    },
  ];

  final List<Map<String, dynamic>> recentActivities = [
    {
      'type': 'Barang Masuk',
      'code': 'BM-202505-001',
      'qty': '130 PCS',
      'time': '20 Mei 2025',
      'icon': Icons.download_rounded,
      'color': const Color(0xFF16A34A),
      'bgColor': const Color(0xFFEFFDF5),
    },
    {
      'type': 'Barang Keluar',
      'code': 'BK-202505-002',
      'qty': '50 PCS',
      'time': '20 Mei 2025',
      'icon': Icons.upload_rounded,
      'color': const Color(0xFFEF4444),
      'bgColor': const Color(0xFFFFECEC),
    },
    {
      'type': 'Barang Masuk',
      'code': 'BM-202505-003',
      'qty': '80 PCS',
      'time': '21 Mei 2025',
      'icon': Icons.download_rounded,
      'color': const Color(0xFF16A34A),
      'bgColor': const Color(0xFFEFFDF5),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF7),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildQuickActionsSection(),
              const SizedBox(height: 14),
              _buildStockSummaryCard(),
              const SizedBox(height: 14),
              _buildAttentionSection(),
              const SizedBox(height: 14),
              _buildRecentActivitySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1677FF),
            Color(0xFF0D5BFF),
            Color(0xFF2F47B7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260D5BFF),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang,',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFEAF1FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Staff Gudang',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pantau aktivitas gudang hari ini secara cepat',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFEAF1FF),
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.20),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '20 Mei 2025',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 66,
            height: 66,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.warehouse_rounded,
                  color: Colors.white,
                  size: 34,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'Aksi Cepat',
            subtitle: 'Pilih aktivitas gudang',
            icon: Icons.flash_on_rounded,
            iconColor: const Color(0xFF0D5BFF),
            iconBgColor: const Color(0xFFEFF6FF),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _quickActionCard(
                title: 'Barang Masuk',
                icon: Icons.download_rounded,
                color: const Color(0xFF16A34A),
                bgColor: const Color(0xFFEFFDF5),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BarangMasukScreen(),
                    ),
                  );
                },
              ),
              _quickActionCard(
                title: 'Barang Keluar',
                icon: Icons.upload_rounded,
                color: const Color(0xFFEF4444),
                bgColor: const Color(0xFFFFECEC),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BarangKeluarScreen(),
                    ),
                  );
                },
              ),
              _quickActionCard(
                title: 'Cek Stok',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF0D5BFF),
                bgColor: const Color(0xFFEFF6FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StokBarangScreen(),
                    ),
                  );
                },
              ),
              _quickActionCard(
                title: 'Riwayat',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF3E8FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RiwayatTransaksiScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.14),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockSummaryCard() {
    const int total = 143;
    const int aman = 128;
    const int menipis = 12;
    const int habis = 3;

    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'Ringkasan Stok',
            subtitle: 'Kondisi stok saat ini',
            icon: Icons.bar_chart_rounded,
            iconColor: const Color(0xFF0D5BFF),
            iconBgColor: const Color(0xFFEFF6FF),
            trailing: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StokBarangScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Detail',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0D5BFF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  title: 'Total Item',
                  value: '$total',
                  color: const Color(0xFF0D5BFF),
                  bgColor: const Color(0xFFEFF6FF),
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryItem(
                  title: 'Aman',
                  value: '$aman',
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFEFFDF5),
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  title: 'Menipis',
                  value: '$menipis',
                  color: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFFF7ED),
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryItem(
                  title: 'Habis',
                  value: '$habis',
                  color: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFFFECEC),
                  icon: Icons.cancel_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _stockHealthBar(
            total: total,
            aman: aman,
            menipis: menipis,
            habis: habis,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockHealthBar({
    required int total,
    required int aman,
    required int menipis,
    required int habis,
  }) {
    final int amanFlex = _healthFlex(aman, total);
    final int menipisFlex = _healthFlex(menipis, total);
    final int habisFlex = _healthFlex(habis, total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kesehatan Stok',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Row(
            children: [
              Expanded(
                flex: amanFlex,
                child: Container(
                  height: 9,
                  color: const Color(0xFF22C55E),
                ),
              ),
              Expanded(
                flex: menipisFlex,
                child: Container(
                  height: 9,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              Expanded(
                flex: habisFlex,
                child: Container(
                  height: 9,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            _LegendDot(color: Color(0xFF22C55E), label: 'Aman'),
            SizedBox(width: 12),
            _LegendDot(color: Color(0xFFF59E0B), label: 'Menipis'),
            SizedBox(width: 12),
            _LegendDot(color: Color(0xFFEF4444), label: 'Habis'),
          ],
        ),
      ],
    );
  }

  int _healthFlex(int value, int total) {
    if (total <= 0 || value <= 0) return 1;

    final int result = ((value / total) * 100).round();

    if (result < 1) return 1;

    return result;
  }

  Widget _buildAttentionSection() {
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'Perlu Perhatian',
            subtitle: 'Stok menipis dan habis',
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBgColor: const Color(0xFFFFF7ED),
          ),
          const SizedBox(height: 12),
          ...attentionItems.take(2).map(
            (item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _attentionItem(item),
              );
            },
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StokBarangScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Lihat Semua Stok',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF0D5BFF),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attentionItem(Map<String, dynamic> item) {
    final Color color = item['color'] as Color;
    final Color bgColor = item['bgColor'] as Color;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              item['status'] == 'Habis'
                  ? Icons.cancel_outlined
                  : Icons.warning_amber_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['status'].toString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item['qty'].toString(),
            style: TextStyle(
              fontSize: 12.5,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'Aktivitas Terbaru',
            subtitle: 'Transaksi gudang terakhir',
            icon: Icons.history_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBgColor: const Color(0xFFF3E8FF),
            trailing: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RiwayatTransaksiScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Lihat',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...recentActivities.take(3).map(
            (item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _recentActivityItem(item),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _recentActivityItem(Map<String, dynamic> item) {
    final Color color = item['color'] as Color;
    final Color bgColor = item['bgColor'] as Color;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              item['icon'] as IconData,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['type'].toString(),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item['code']} • ${item['time']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item['qty'].toString(),
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionContainer({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}