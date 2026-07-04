import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'app_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _bgColor = Color(0xFFF8FBFF);
  static const Color _primaryBlue = Color(0xFF005BEA);
  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF667085);
  static const Color _borderColor = Color(0xFFE5EAF2);

  String userName = 'Memuat...';
  String userEmail = '-';
  String roleName = '-';
  String warehouseName = '-';

  bool notifBarangMasuk = true;
  bool notifBarangKeluar = true;
  bool notifStokMenipis = true;

  bool isLoadingProfile = false;
  bool isLoggingOut = false;

  int inboundCount = 0;
  int outboundCount = 0;
  int stockCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (isLoadingProfile) return;

    setState(() {
      isLoadingProfile = true;
    });

    try {
      final response = await AuthService.getProfile();
      final data = response['data'];

      if (data is! Map) {
        throw ApiException(message: 'Data profile tidak valid.');
      }

      final dataMap = Map<String, dynamic>.from(data);
      final user = _asMap(dataMap['user']);
      final profile = _asMap(dataMap['profile']);
      final warehouse = _asMap(dataMap['warehouse']);
      final stats = _asMap(dataMap['stats']);

      final roles = user['roles'];

      String roleText = profile['position']?.toString() ?? '';

      if (roleText.trim().isEmpty && roles is List && roles.isNotEmpty) {
        roleText = _formatRole(roles.first.toString());
      }

      final warehouseLabel = _safeText(
        dataMap['warehouse_label'],
        fallback: _safeText(warehouse['name'], fallback: '-'),
      );

      if (!mounted) return;

      setState(() {
        userName = _safeText(user['name'], fallback: '-');
        userEmail = _safeText(user['email'], fallback: '-');
        roleName = roleText.trim().isEmpty ? '-' : roleText;
        warehouseName = warehouseLabel;

        inboundCount =
            int.tryParse(stats['inbound_count']?.toString() ?? '0') ?? 0;
        outboundCount =
            int.tryParse(stats['outbound_count']?.toString() ?? '0') ?? 0;
        stockCount = int.tryParse(stats['stock_count']?.toString() ?? '0') ?? 0;
      });
    } on ApiException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar('Gagal memuat profile: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoadingProfile = false;
        });
      }
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    return <String, dynamic>{};
  }

  String _safeText(dynamic value, {String fallback = '-'}) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  String _formatRole(String value) {
    final words = value.replaceAll('_', ' ').split(' ');

    return words.where((word) => word.trim().isNotEmpty).map((word) {
      final lower = word.toLowerCase();

      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }).join(' ');
  }

  Future<void> _handleLogout() async {
    if (isLoggingOut) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
      await AuthService.logout();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } on ApiException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar('Gagal logout: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoggingOut = false;
        });
      }
    }
  }

  String get userInitial {
    final name = userName.trim();

    if (name.isEmpty || name == 'Memuat...' || name == '-') return 'U';

    final parts = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _animatedBox({
    required Widget child,
    required int index,
  }) {
    return child
        .animate()
        .fadeIn(
          delay: (70 * index).ms,
          duration: 500.ms,
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.045,
          end: 0,
          delay: (70 * index).ms,
          duration: 540.ms,
          curve: Curves.easeOutCubic,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: const AppBottomNav(selectedIndex: 3),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _ProfileBackgroundPainter(),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: _primaryBlue,
              backgroundColor: Colors.white,
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                child: Column(
                  children: [
                    _animatedBox(
                      index: 0,
                      child: _buildHeader(),
                    ),
                    if (isLoadingProfile) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: const LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: Color(0xFFE5EAF2),
                          color: _primaryBlue,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _animatedBox(
                      index: 1,
                      child: _buildProfileCard(),
                    ),
                    const SizedBox(height: 14),
                    _animatedBox(
                      index: 2,
                      child: _buildActivityCard(),
                    ),
                    const SizedBox(height: 14),
                    _animatedBox(
                      index: 3,
                      child: _buildMenuSection(),
                    ),
                    const SizedBox(height: 16),
                    _animatedBox(
                      index: 4,
                      child: _buildLogoutButton(),
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
            right: -30,
            top: -34,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: -48,
            child: Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil Pengguna',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Informasi akun dan akses aplikasi',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFEAF1FF),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: _loadProfile,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: _softCardDecoration(radius: 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFEFF6FF),
                      Color(0xFFDCEBFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFBFDBFE),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryBlue.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  userInitial,
                  style: const TextStyle(
                    fontSize: 25,
                    color: _primaryBlue,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        color: _darkText,
                        fontWeight: FontWeight.w900,
                        height: 1.18,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _miniBadge(
                      icon: Icons.verified_user_outlined,
                      label: roleName,
                      color: _primaryBlue,
                      bgColor: const Color(0xFFEFF6FF),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _profileInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: userEmail,
          ),
          const SizedBox(height: 10),
          _profileInfoRow(
            icon: Icons.warehouse_outlined,
            label: 'Gudang',
            value: warehouseName,
          ),
        ],
      ),
    );
  }

  Widget _profileInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 17,
              color: _primaryBlue,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _softText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.4,
                color: _darkText,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 190,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.13),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 13,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.2,
                color: color,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: _softCardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Aktivitas',
            style: TextStyle(
              fontSize: 15,
              color: _darkText,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 12),
          _activityItem(
            icon: Icons.download_rounded,
            title: 'Barang Masuk',
            subtitle: 'Total transaksi yang dibuat',
            value: inboundCount.toString(),
            color: const Color(0xFF16A34A),
            bgColor: const Color(0xFFEFFDF5),
          ),
          const SizedBox(height: 10),
          _activityItem(
            icon: Icons.upload_rounded,
            title: 'Barang Keluar',
            subtitle: 'Total transaksi yang dibuat',
            value: outboundCount.toString(),
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFFECEC),
          ),
          const SizedBox(height: 10),
          _activityItem(
            icon: Icons.inventory_2_outlined,
            title: 'Stok Tersedia',
            subtitle: 'Jumlah item stok aktif',
            value: stockCount.toString(),
            color: _primaryBlue,
            bgColor: const Color(0xFFEFF6FF),
          ),
        ],
      ),
    );
  }

  Widget _activityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: double.infinity,
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.10),
              ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.3,
                    color: _darkText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.2,
                    color: _softText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _softCardDecoration(radius: 24),
      child: Column(
        children: [
          _sectionSmallTitle('Pengaturan & Informasi'),
          const SizedBox(height: 5),
          _menuItem(
            icon: Icons.lock_outline_rounded,
            title: 'Ubah Password',
            subtitle: 'Perbarui password akun',
            color: _primaryBlue,
            bgColor: const Color(0xFFEFF6FF),
            onTap: _showChangePasswordSheet,
          ),
          _divider(),
          _menuItem(
            icon: Icons.notifications_none_rounded,
            title: 'Notifikasi',
            subtitle: 'Atur pemberitahuan aktivitas gudang',
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFF7ED),
            onTap: _showNotificationSheet,
          ),
          _divider(),
          _menuItem(
            icon: Icons.help_outline_rounded,
            title: 'Bantuan',
            subtitle: 'Panduan penggunaan aplikasi',
            color: const Color(0xFF7C3AED),
            bgColor: const Color(0xFFF3E8FF),
            onTap: _showHelpSheet,
          ),
          _divider(),
          _menuItem(
            icon: Icons.info_outline_rounded,
            title: 'Tentang Aplikasi',
            subtitle: 'Informasi versi dan sistem',
            color: const Color(0xFF0891B2),
            bgColor: const Color(0xFFE0F7FA),
            onTap: _showAboutSheet,
          ),
        ],
      ),
    );
  }

  Widget _sectionSmallTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: _darkText,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 3,
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
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
                        fontSize: 14,
                        color: _darkText,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.7,
                        color: _softText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isLoggingOut ? null : _showLogoutConfirm,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFEF4444),
                Color(0xFFDC2626),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoggingOut) ...[
                const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 9),
                const Text(
                  'Keluar...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Keluar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordSheet() {
    FocusManager.instance.primaryFocus?.unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ChangePasswordSheet(
          onSubmit: ({
            required String currentPassword,
            required String newPassword,
            required String confirmPassword,
          }) async {
            await ApiService.post(
              '/profile/change-password',
              body: {
                'current_password': currentPassword,
                'new_password': newPassword,
                'new_password_confirmation': confirmPassword,
              },
            );
          },
          onSuccess: () {
            _showSnackBar('Password berhasil diubah');
          },
          onError: (message) {
            _showSnackBar(message, isError: true);
          },
        );
      },
    );
  }

  void _showNotificationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _bottomSheetContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 17),
                  _sheetHeader(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifikasi',
                    subtitle: 'Atur notifikasi aktivitas gudang.',
                    color: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFFFF7ED),
                  ),
                  const SizedBox(height: 12),
                  _switchTile(
                    title: 'Barang Masuk',
                    subtitle: 'Pemberitahuan transaksi barang masuk',
                    value: notifBarangMasuk,
                    onChanged: (value) {
                      setModalState(() {
                        notifBarangMasuk = value;
                      });
                      setState(() {});
                    },
                  ),
                  _switchTile(
                    title: 'Barang Keluar',
                    subtitle: 'Pemberitahuan transaksi barang keluar',
                    value: notifBarangKeluar,
                    onChanged: (value) {
                      setModalState(() {
                        notifBarangKeluar = value;
                      });
                      setState(() {});
                    },
                  ),
                  _switchTile(
                    title: 'Stok Menipis',
                    subtitle: 'Pemberitahuan stok menipis dan habis',
                    value: notifStokMenipis,
                    onChanged: (value) {
                      setModalState(() {
                        notifStokMenipis = value;
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showHelpSheet() {
    _showInfoSheet(
      title: 'Bantuan',
      subtitle: 'Panduan singkat penggunaan aplikasi.',
      icon: Icons.help_outline_rounded,
      color: const Color(0xFF7C3AED),
      bgColor: const Color(0xFFF3E8FF),
      items: const [
        'Gunakan menu Home untuk melihat ringkasan gudang.',
        'Barang masuk dan barang keluar menunggu approval admin.',
        'Menu Stok digunakan untuk memantau kondisi stok.',
        'Menu Riwayat digunakan untuk melihat transaksi sebelumnya.',
      ],
    );
  }

  void _showAboutSheet() {
    _showInfoSheet(
      title: 'Tentang Aplikasi',
      subtitle: 'Sistem inventory gudang berbasis mobile.',
      icon: Icons.info_outline_rounded,
      color: const Color(0xFF0891B2),
      bgColor: const Color(0xFFE0F7FA),
      items: const [
        'Nama aplikasi: NSA Mobile',
        'Versi: 1.0.0',
        'Role pengguna: Staff Gudang',
        'Terhubung dengan dashboard admin untuk approval transaksi.',
      ],
    );
  }

  void _showInfoSheet({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required List<String> items,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _bottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 17),
              _sheetHeader(
                icon: icon,
                title: title,
                subtitle: subtitle,
                color: color,
                bgColor: bgColor,
              ),
              const SizedBox(height: 15),
              ...items.map(
                (item) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 9),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _borderColor,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 17,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Keluar dari aplikasi?',
            style: TextStyle(
              color: _darkText,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          content: const Text(
            'Anda akan keluar dari akun staff gudang.',
            style: TextStyle(
              color: _softText,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoggingOut ? null : () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoggingOut
                  ? null
                  : () {
                      Navigator.pop(context);
                      _handleLogout();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bottomSheetContainer({
    required Widget child,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.82,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFE5EAF2),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _sheetHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: color.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: _darkText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.7,
                  color: _softText,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _darkText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _softText,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: _primaryBlue,
            activeTrackColor: _primaryBlue.withValues(alpha: 0.28),
            inactiveThumbColor: const Color(0xFFCBD5E1),
            inactiveTrackColor: const Color(0xFFE5EAF2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  BoxDecoration _softCardDecoration({
    double radius = 20,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: _borderColor,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.055),
          blurRadius: 20,
          offset: const Offset(0, 9),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
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
        backgroundColor: isError ? const Color(0xFFEF4444) : _primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  final Future<void> Function({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) onSubmit;

  final VoidCallback onSuccess;
  final ValueChanged<String> onError;

  const _ChangePasswordSheet({
    required this.onSubmit,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool oldHidden = true;
  bool newHidden = true;
  bool confirmHidden = true;
  bool isSubmitting = false;

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _closeSheet() async {
    FocusManager.instance.primaryFocus?.unfocus();

    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  Future<void> _submitPassword() async {
    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (oldPassword.isEmpty) {
      widget.onError('Password lama wajib diisi');
      return;
    }

    if (newPassword.isEmpty) {
      widget.onError('Password baru wajib diisi');
      return;
    }

    if (newPassword.length < 8) {
      widget.onError('Password baru minimal 8 karakter');
      return;
    }

    if (confirmPassword != newPassword) {
      widget.onError('Konfirmasi password baru tidak sesuai');
      return;
    }

    if (isSubmitting) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      await widget.onSubmit(
        currentPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (!mounted) return;

      await _closeSheet();
      widget.onSuccess();
    } on ApiException catch (e) {
      widget.onError(e.message);
    } catch (e) {
      widget.onError('Gagal mengubah password: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.82,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 17),
                _sheetHeader(),
                const SizedBox(height: 15),
                _passwordField(
                  label: 'Password Lama',
                  hint: 'Masukkan password lama',
                  controller: oldPasswordController,
                  hidden: oldHidden,
                  onToggle: () {
                    if (isSubmitting) return;

                    setState(() {
                      oldHidden = !oldHidden;
                    });
                  },
                ),
                const SizedBox(height: 11),
                _passwordField(
                  label: 'Password Baru',
                  hint: 'Minimal 8 karakter',
                  controller: newPasswordController,
                  hidden: newHidden,
                  onToggle: () {
                    if (isSubmitting) return;

                    setState(() {
                      newHidden = !newHidden;
                    });
                  },
                ),
                const SizedBox(height: 11),
                _passwordField(
                  label: 'Konfirmasi Password',
                  hint: 'Ulangi password baru',
                  controller: confirmPasswordController,
                  hidden: confirmHidden,
                  onToggle: () {
                    if (isSubmitting) return;

                    setState(() {
                      confirmHidden = !confirmHidden;
                    });
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: isSubmitting ? null : _closeSheet,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF667085),
                            side: const BorderSide(
                              color: Color(0xFFD1D5DB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : _submitPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005BEA),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFE5EAF2),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _sheetHeader() {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFF005BEA).withValues(alpha: 0.12),
            ),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFF005BEA),
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ubah Password',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Masukkan password lama dan password baru akun kamu.',
                style: TextStyle(
                  fontSize: 11.7,
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _passwordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: hidden,
          cursorColor: const Color(0xFF005BEA),
          enabled: !isSubmitting,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF8B96A8),
              size: 20,
            ),
            suffixIcon: IconButton(
              onPressed: isSubmitting ? null : onToggle,
              icon: Icon(
                hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF8B96A8),
                size: 20,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Color(0xFFE5EAF2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Color(0xFFE5EAF2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Color(0xFF005BEA),
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Color(0xFFE5EAF2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileBackgroundPainter extends CustomPainter {
  const _ProfileBackgroundPainter();

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