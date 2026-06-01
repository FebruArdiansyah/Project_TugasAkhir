import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'app_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController(
    text: 'Memuat...',
  );

  final TextEditingController roleController = TextEditingController(
    text: '-',
  );

  final TextEditingController warehouseController = TextEditingController(
    text: '-',
  );

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

  @override
  void dispose() {
    nameController.dispose();
    roleController.dispose();
    warehouseController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (isLoadingProfile) return;

    setState(() {
      isLoadingProfile = true;
    });

    try {
      final response = await AuthService.getProfile();

      final data = response['data'];

      if (data is! Map<String, dynamic>) {
        throw ApiException(message: 'Data profile tidak valid.');
      }

      final user = data['user'] as Map<String, dynamic>? ?? {};
      final profile = data['profile'] as Map<String, dynamic>? ?? {};
      final warehouse = data['warehouse'] as Map<String, dynamic>?;
      final stats = data['stats'] as Map<String, dynamic>? ?? {};

      final roles = user['roles'];

      String roleText = profile['position']?.toString() ?? '';

      if (roleText.trim().isEmpty && roles is List && roles.isNotEmpty) {
        roleText = _formatRole(roles.first.toString());
      }

      setState(() {
        nameController.text = user['name']?.toString() ?? '-';
        roleController.text = roleText.trim().isEmpty ? '-' : roleText;
        warehouseController.text = warehouse?['name']?.toString() ?? '-';

        inboundCount = int.tryParse(stats['inbound_count'].toString()) ?? 0;
        outboundCount = int.tryParse(stats['outbound_count'].toString()) ?? 0;
        stockCount = int.tryParse(stats['stock_count'].toString()) ?? 0;
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

  String _formatRole(String value) {
    final words = value.replaceAll('_', ' ').split(' ');

    return words
        .where((word) => word.trim().isNotEmpty)
        .map((word) {
          final lower = word.toLowerCase();

          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
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
    final name = nameController.text.trim();

    if (name.isEmpty || name == 'Memuat...' || name == '-') return 'U';

    final parts = name.split(' ');

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF7),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 3),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            child: Column(
              children: [
                _buildHeader(),
                if (isLoadingProfile) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: Color(0xFFE5E7EB),
                      color: Color(0xFF0D5BFF),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _buildProfileCard(),
                const SizedBox(height: 14),
                _buildQuickInfoCard(),
                const SizedBox(height: 14),
                _buildMenuSection(),
                const SizedBox(height: 16),
                _buildLogoutButton(),
              ],
            ),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil Pengguna',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola akun dan informasi aplikasi',
                  style: TextStyle(
                    color: Color(0xFFEAF1FF),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 22),
      child: Row(
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
            ),
            child: Text(
              userInitial,
              style: const TextStyle(
                fontSize: 24,
                color: Color(0xFF0D5BFF),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameController.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    roleController.text,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF0D5BFF),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.warehouse_outlined,
                      size: 15,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        warehouseController.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _showEditProfileSheet,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF0D5BFF),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 22),
      child: Row(
        children: [
          Expanded(
            child: _infoItem(
              icon: Icons.login_rounded,
              label: 'Masuk',
              value: inboundCount.toString(),
              color: const Color(0xFF16A34A),
              bgColor: const Color(0xFFEFFDF5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _infoItem(
              icon: Icons.logout_rounded,
              label: 'Keluar',
              value: outboundCount.toString(),
              color: const Color(0xFFEF4444),
              bgColor: const Color(0xFFFFECEC),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _infoItem(
              icon: Icons.inventory_2_outlined,
              label: 'Stok',
              value: stockCount.toString(),
              color: const Color(0xFF0D5BFF),
              bgColor: const Color(0xFFEFF6FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
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
    );
  }

  Widget _buildMenuSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          _menuItem(
            icon: Icons.lock_outline_rounded,
            title: 'Ubah Password',
            subtitle: 'Perbarui password akun',
            color: const Color(0xFF0D5BFF),
            bgColor: const Color(0xFFEFF6FF),
            onTap: _showChangePasswordSheet,
          ),
          _divider(),
          _menuItem(
            icon: Icons.notifications_none_rounded,
            title: 'Notifikasi',
            subtitle: 'Atur pemberitahuan aplikasi',
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

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: 9,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: color,
                size: 21,
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
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 24,
            ),
          ],
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
    return InkWell(
      onTap: isLoggingOut ? null : _showLogoutConfirm,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFEF4444),
              Color(0xFFDC2626),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22EF4444),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoggingOut) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
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
    );
  }

  void _showEditProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _bottomSheetContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 16),
                _sheetTitle(
                  title: 'Edit Profil',
                  subtitle:
                      'Untuk saat ini perubahan profil utama dilakukan melalui dashboard admin.',
                ),
                const SizedBox(height: 16),
                _inputField(
                  label: 'Nama Lengkap',
                  controller: nameController,
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                _inputField(
                  label: 'Role',
                  controller: roleController,
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                _inputField(
                  label: 'Gudang',
                  controller: warehouseController,
                  readOnly: true,
                ),
                const SizedBox(height: 18),
                _sheetActionButtons(
                  primaryText: 'Tutup',
                  onPrimaryTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangePasswordSheet() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _bottomSheetContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 16),
                _sheetTitle(
                  title: 'Ubah Password',
                  subtitle:
                      'Fitur ini belum disambungkan ke API. Sementara ubah password dilakukan melalui dashboard admin.',
                ),
                const SizedBox(height: 16),
                _inputField(
                  label: 'Password Lama',
                  controller: oldPasswordController,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                _inputField(
                  label: 'Password Baru',
                  controller: newPasswordController,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                _inputField(
                  label: 'Konfirmasi Password',
                  controller: confirmPasswordController,
                  obscureText: true,
                ),
                const SizedBox(height: 18),
                _sheetActionButtons(
                  primaryText: 'Tutup',
                  onPrimaryTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Fitur ubah password belum aktif');
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      oldPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  void _showNotificationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _bottomSheetContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 16),
                  _sheetTitle(
                    title: 'Notifikasi',
                    subtitle: 'Atur notifikasi aktivitas gudang.',
                  ),
                  const SizedBox(height: 10),
                  _switchTile(
                    title: 'Barang Masuk',
                    subtitle: 'Notifikasi saat ada pengajuan barang masuk',
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
                    subtitle: 'Notifikasi saat ada pengajuan barang keluar',
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
                    subtitle: 'Notifikasi stok menipis dan habis',
                    value: notifStokMenipis,
                    onChanged: (value) {
                      setModalState(() {
                        notifStokMenipis = value;
                      });
                      setState(() {});
                    },
                  ),
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
      items: const [
        'Gunakan menu Home untuk akses cepat.',
        'Barang masuk dan keluar akan menunggu approval admin.',
        'Menu Stok digunakan untuk melihat kondisi stok gudang.',
        'Menu Riwayat digunakan untuk melihat transaksi sebelumnya.',
      ],
    );
  }

  void _showAboutSheet() {
    _showInfoSheet(
      title: 'Tentang Aplikasi',
      subtitle: 'Sistem inventory gudang berbasis mobile.',
      icon: Icons.info_outline_rounded,
      items: const [
        'Nama aplikasi: Inventory Gudang Mobile',
        'Versi: 1.0.0',
        'Role pengguna: Staff Gudang',
        'Terhubung dengan dashboard admin untuk approval.',
      ],
    );
  }

  void _showInfoSheet({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> items,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _bottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF0D5BFF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sheetTitle(
                      title: title,
                      subtitle: subtitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...items.map(
                (item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
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
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Keluar dari aplikasi?',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Anda akan keluar dari akun staff gudang.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoggingOut ? null : () => Navigator.pop(context),
              child: const Text('Batal'),
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
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  Widget _bottomSheetContainer({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: child,
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _sheetTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _sheetActionButtons({
    required String primaryText,
    required VoidCallback onPrimaryTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                side: const BorderSide(
                  color: Color(0xFFD1D5DB),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: onPrimaryTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5BFF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                primaryText,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
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
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
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
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF0D5BFF),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: readOnly
                ? const Color(0xFFF1F5F9)
                : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF0D5BFF),
              ),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
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
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF0D5BFF),
      ),
    );
  }
}