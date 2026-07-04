import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/api_service.dart';
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
  static const Color _bgColor = Color(0xFFF8FBFF);
  static const Color _primaryBlue = Color(0xFF005BEA);
  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF667085);
  static const Color _borderColor = Color(0xFFE5EAF2);

  String userName = 'Staff Gudang';
  String todayLabel = '-';

  int totalStock = 0;
  int amanStock = 0;
  int menipisStock = 0;
  int habisStock = 0;

  List<Map<String, dynamic>> attentionItems = [];
  List<Map<String, dynamic>> recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final response = await ApiService.get('dashboard');

      final Map<String, dynamic> data = response is Map<String, dynamic>
          ? Map<String, dynamic>.from(response['data'] ?? {})
          : {};

      final Map<String, dynamic> stockSummary =
          data['stock_summary'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(data['stock_summary'])
              : {};

      final List<dynamic> attentionRaw =
          data['attention_items'] is List ? data['attention_items'] : [];

      final List<dynamic> activityRaw =
          data['recent_activities'] is List ? data['recent_activities'] : [];

      if (!mounted) return;

      setState(() {
        userName = data['user_name']?.toString() ?? 'Staff Gudang';
        todayLabel = data['today_label']?.toString() ?? '-';

        totalStock =
            int.tryParse(stockSummary['total']?.toString() ?? '0') ?? 0;
        amanStock =
            int.tryParse(stockSummary['aman']?.toString() ?? '0') ?? 0;
        menipisStock =
            int.tryParse(stockSummary['menipis']?.toString() ?? '0') ?? 0;
        habisStock =
            int.tryParse(stockSummary['habis']?.toString() ?? '0') ?? 0;

        attentionItems = attentionRaw.map<Map<String, dynamic>>((item) {
          final Map<String, dynamic> row =
              item is Map<String, dynamic> ? item : {};

          final String status = row['status']?.toString() ?? '-';
          final bool isHabis = status.toLowerCase() == 'habis';

          return {
            'status': status,
            'name': row['name']?.toString() ?? '-',
            'qty': row['qty']?.toString() ?? '0 PCS',
            'color':
                isHabis ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
            'bgColor':
                isHabis ? const Color(0xFFFFECEC) : const Color(0xFFFFF7ED),
          };
        }).toList();

        recentActivities = activityRaw.map<Map<String, dynamic>>((item) {
          final Map<String, dynamic> row =
              item is Map<String, dynamic> ? item : {};

          final String type = row['type']?.toString() ?? '-';
          final bool isInbound = type.toLowerCase().contains('masuk');

          return {
            'type': type,
            'code': row['code']?.toString() ?? '-',
            'qty': row['qty']?.toString() ?? '0 PCS',
            'time': row['time']?.toString() ?? '-',
            'icon': isInbound ? Icons.download_rounded : Icons.upload_rounded,
            'color':
                isInbound ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
            'bgColor':
                isInbound ? const Color(0xFFEFFDF5) : const Color(0xFFFFECEC),
          };
        }).toList();
      });
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Gagal memuat dashboard: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFEF4444),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  void _goToBarangMasuk() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarangMasukScreen(),
      ),
    );
  }

  void _goToBarangKeluar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarangKeluarScreen(),
      ),
    );
  }

  void _goToStokBarang() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StokBarangScreen(),
      ),
    );
  }

  void _goToRiwayat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RiwayatTransaksiScreen(),
      ),
    );
  }

  Widget _animatedSection({
    required Widget child,
    required int index,
  }) {
    return child
        .animate()
        .fadeIn(
          delay: (90 * index).ms,
          duration: 520.ms,
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.05,
          end: 0,
          delay: (90 * index).ms,
          duration: 560.ms,
          curve: Curves.easeOutCubic,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: const AppBottomNav(selectedIndex: 0),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _HomeBackgroundPainter(),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: _primaryBlue,
              backgroundColor: Colors.white,
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _animatedSection(
                      index: 0,
                      child: _buildHeader(),
                    ),
                    const SizedBox(height: 16),
                    _animatedSection(
                      index: 1,
                      child: _buildQuickActionsSection(),
                    ),
                    const SizedBox(height: 16),
                    _animatedSection(
                      index: 2,
                      child: _buildStockSummaryCard(),
                    ),
                    const SizedBox(height: 16),
                    _animatedSection(
                      index: 3,
                      child: _buildAttentionSection(),
                    ),
                    const SizedBox(height: 16),
                    _animatedSection(
                      index: 4,
                      child: _buildRecentActivitySection(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: [
          Color(0xFF0EA5E9),
          Color(0xFF0062F5),
          Color(0xFF2F3192),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: _primaryBlue.withValues(alpha: 0.22),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -26,
          top: -30,
          child: Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
        ),
        Positioned(
          right: 28,
          bottom: -44,
          child: Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang,',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.86),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 25,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Pantau aktivitas gudang hari ini secara cepat',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w500,
                height: 1.28,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    todayLabel,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            iconColor: _primaryBlue,
            iconBgColor: const Color(0xFFEFF6FF),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            childAspectRatio: 1.46,
            children: [
              _quickActionCard(
                title: 'Barang Masuk',
                subtitle: 'Tambah stok',
                icon: Icons.download_rounded,
                color: const Color(0xFF16A34A),
                bgColor: const Color(0xFFEFFDF5),
                onTap: _goToBarangMasuk,
              ),
              _quickActionCard(
                title: 'Barang Keluar',
                subtitle: 'Kurangi stok',
                icon: Icons.upload_rounded,
                color: const Color(0xFFEF4444),
                bgColor: const Color(0xFFFFECEC),
                onTap: _goToBarangKeluar,
              ),
              _quickActionCard(
                title: 'Cek Stok',
                subtitle: 'Monitoring',
                icon: Icons.inventory_2_outlined,
                color: _primaryBlue,
                bgColor: const Color(0xFFEFF6FF),
                onTap: _goToStokBarang,
              ),
              _quickActionCard(
                title: 'Riwayat',
                subtitle: 'Transaksi',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF3E8FF),
                onTap: _goToRiwayat,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.13),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.3,
                        color: _darkText,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.8,
                        color: _softText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockSummaryCard() {
    final int total = totalStock;
    final int aman = amanStock;
    final int menipis = menipisStock;
    final int habis = habisStock;

    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'Ringkasan Stok',
            subtitle: 'Kondisi stok saat ini',
            icon: Icons.bar_chart_rounded,
            iconColor: _primaryBlue,
            iconBgColor: const Color(0xFFEFF6FF),
            trailing: _pillButton(
              label: 'Detail',
              color: _primaryBlue,
              bgColor: const Color(0xFFEFF6FF),
              onTap: _goToStokBarang,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  title: 'Total Item',
                  value: '$total',
                  color: _primaryBlue,
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
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    color: color,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.7,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w800,
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
    if (total <= 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kesehatan Stok',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 10,
              color: const Color(0xFFE5EAF2),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Belum ada data stok yang tersedia',
            style: TextStyle(
              fontSize: 11,
              color: _softText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

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
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Row(
            children: [
              Expanded(
                flex: amanFlex,
                child: Container(
                  height: 10,
                  color: const Color(0xFF22C55E),
                ),
              ),
              Expanded(
                flex: menipisFlex,
                child: Container(
                  height: 10,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              Expanded(
                flex: habisFlex,
                child: Container(
                  height: 10,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
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
    final List<Map<String, dynamic>> items = attentionItems.take(2).toList();

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
          const SizedBox(height: 13),
          if (items.isEmpty)
            _emptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Stok masih aman',
              subtitle: 'Tidak ada stok menipis atau habis saat ini.',
              color: const Color(0xFF16A34A),
              bgColor: const Color(0xFFEFFDF5),
            )
          else
            ...items.map(
              (item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _attentionItem(item),
                );
              },
            ),
          const SizedBox(height: 2),
          _wideButton(
            label: 'Lihat Semua Stok',
            icon: Icons.arrow_forward_rounded,
            color: _primaryBlue,
            bgColor: const Color(0xFFEFF6FF),
            onTap: _goToStokBarang,
          ),
        ],
      ),
    );
  }

  Widget _attentionItem(Map<String, dynamic> item) {
    final Color color = item['color'] as Color? ?? const Color(0xFFF59E0B);
    final Color bgColor = item['bgColor'] as Color? ?? const Color(0xFFFFF7ED);
    final String status = item['status']?.toString() ?? '-';
    final bool isHabis = status.toLowerCase() == 'habis';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isHabis ? Icons.cancel_outlined : Icons.warning_amber_rounded,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.8,
                    color: _darkText,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w900,
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
    final List<Map<String, dynamic>> items = recentActivities.take(3).toList();

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
            trailing: _pillButton(
              label: 'Lihat',
              color: const Color(0xFF7C3AED),
              bgColor: const Color(0xFFF3E8FF),
              onTap: _goToRiwayat,
            ),
          ),
          const SizedBox(height: 13),
          if (items.isEmpty)
            _emptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada transaksi',
              subtitle: 'Aktivitas gudang terbaru akan tampil di sini.',
              color: const Color(0xFF7C3AED),
              bgColor: const Color(0xFFF3E8FF),
            )
          else
            ...items.map(
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
    final Color color = item['color'] as Color? ?? _primaryBlue;
    final Color bgColor = item['bgColor'] as Color? ?? const Color(0xFFEFF6FF);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item['icon'] as IconData? ?? Icons.receipt_long_rounded,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['type'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.8,
                    color: _darkText,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['code']} • ${item['time']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _softText,
                    fontWeight: FontWeight.w700,
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
              color: _darkText,
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.055),
            blurRadius: 22,
            offset: const Offset(0, 10),
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
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.7,
                  color: _darkText,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _softText,
                  fontWeight: FontWeight.w700,
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

  Widget _pillButton({
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _wideButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                icon,
                size: 16,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 41,
            height: 41,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.8,
                    color: _darkText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _softText,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
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
            fontSize: 10.7,
            color: Color(0xFF667085),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HomeBackgroundPainter extends CustomPainter {
  const _HomeBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF8FBFF),
          Color(0xFFEFF6FF),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, basePaint);

    final Paint topGlow = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.05,
        colors: [
          const Color(0xFFD9EAFF).withValues(alpha: 0.88),
          const Color(0xFFEAF4FF).withValues(alpha: 0.38),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(
        Rect.fromLTWH(
          -size.width * 0.42,
          -size.height * 0.18,
          size.width * 1.12,
          size.height * 0.58,
        ),
      );

    canvas.drawOval(
      Rect.fromLTWH(
        -size.width * 0.42,
        -size.height * 0.18,
        size.width * 1.12,
        size.height * 0.58,
      ),
      topGlow,
    );

    final Paint rightGlow = Paint()
      ..shader = RadialGradient(
        center: Alignment.centerRight,
        radius: 0.95,
        colors: [
          const Color(0xFFD8EAFF).withValues(alpha: 0.58),
          const Color(0xFFEAF4FF).withValues(alpha: 0.26),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.60, 1.0],
      ).createShader(
        Rect.fromLTWH(
          size.width * 0.48,
          size.height * 0.20,
          size.width * 0.70,
          size.height * 0.55,
        ),
      );

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.50,
        size.height * 0.20,
        size.width * 0.76,
        size.height * 0.58,
      ),
      rightGlow,
    );

    final Paint bottomGlow = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomRight,
        radius: 1.02,
        colors: [
          const Color(0xFFD8EAFF).withValues(alpha: 0.72),
          const Color(0xFFEAF4FF).withValues(alpha: 0.36),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.62, 1.0],
      ).createShader(
        Rect.fromLTWH(
          size.width * 0.38,
          size.height * 0.68,
          size.width * 0.90,
          size.height * 0.48,
        ),
      );

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.38,
        size.height * 0.68,
        size.width * 0.90,
        size.height * 0.48,
      ),
      bottomGlow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}