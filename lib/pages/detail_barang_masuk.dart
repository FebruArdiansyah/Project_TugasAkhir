import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/shared/product_logo.dart';
import '../widgets/transaction_detail/detail_attachment_grid.dart';
import '../widgets/transaction_detail/detail_header_card.dart';
import '../widgets/transaction_detail/detail_info_box.dart';
import '../widgets/transaction_detail/detail_info_row.dart';
import '../widgets/transaction_detail/detail_item_card.dart';
import '../widgets/transaction_detail/detail_section_card.dart';
import '../widgets/transaction_detail/detail_state_widgets.dart';
import '../widgets/transaction_detail/detail_status_badge.dart';
import 'tambah_barang_masuk.dart';

class DetailBarangMasukScreen extends StatefulWidget {
  const DetailBarangMasukScreen({super.key});

  @override
  State<DetailBarangMasukScreen> createState() =>
      _DetailBarangMasukScreenState();
}

class _DetailBarangMasukScreenState extends State<DetailBarangMasukScreen> {
  static const Color _bgColor = Color(0xFFF7FAFC);
  static const Color _primaryGreen = Color(0xFF16A34A);
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _softText = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);

  static const String _fallbackProductionBaseUrl =
      'https://febru.djncloud.my.id';

  bool isLoading = false;
  bool isArgumentLoaded = false;
  bool hasDetailChanged = false;

  String? errorMessage;
  int? inboundId;

  Map<String, dynamic>? detail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (isArgumentLoaded) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map && args['id'] != null) {
      inboundId = int.tryParse(args['id'].toString());
    }

    isArgumentLoaded = true;

    if (inboundId == null) {
      setState(() {
        errorMessage = 'ID barang masuk tidak ditemukan.';
      });
      return;
    }

    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (isLoading || inboundId == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.get('/inbounds/$inboundId');

      if (response is! Map<String, dynamic>) {
        throw ApiException(
          message: 'Response detail barang masuk tidak valid.',
        );
      }

      final data = response['data'];

      if (data is! Map<String, dynamic>) {
        throw ApiException(
          message: 'Data detail barang masuk tidak valid.',
        );
      }

      if (!mounted) return;

      setState(() {
        detail = data;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.message;
      });

      _showSnackBar(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Gagal memuat detail barang masuk: $e';
      });

      _showSnackBar('Gagal memuat detail barang masuk: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> get supplier {
    final value = detail?['supplier'];

    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    return {};
  }

  Map<String, dynamic> get warehouse {
    final value = detail?['warehouse'];

    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    return {};
  }

  Map<String, dynamic> get submittedBy {
    final value = detail?['submitted_by'];

    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    return {};
  }

  Map<String, dynamic> get summary {
    final value = detail?['summary'];

    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    return {};
  }

  List<Map<String, dynamic>> get items {
    final value = detail?['items'];

    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  List<Map<String, dynamic>> get attachments {
    final value = detail?['attachments'];

    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  String get transactionNumber {
    return _firstNonEmpty([
      detail?['transaction_number'],
      detail?['code'],
      detail?['nomor_transaksi'],
    ]);
  }

  String get invoiceNumber {
    return _firstNonEmpty([
      detail?['invoice_number'],
      detail?['reference_number'],
      detail?['no_invoice'],
    ]);
  }

  String get supplierName {
    return _firstNonEmpty([
      detail?['supplier_name'],
      detail?['supplier_text'],
      supplier['name'],
      supplier['supplier_name'],
    ]);
  }

  String get warehouseName {
    return _firstNonEmpty([
      detail?['warehouse_name'],
      warehouse['name'],
      warehouse['warehouse_name'],
    ]);
  }

  String get warehouseCode {
    return _firstNonEmpty([
      detail?['warehouse_code'],
      warehouse['code'],
      warehouse['warehouse_code'],
    ]);
  }

  String get submittedByName {
    return _firstNonEmpty([
      detail?['submitted_by_name'],
      detail?['input_by_name'],
      submittedBy['name'],
      submittedBy['email'],
    ]);
  }

  String get statusText {
    return _formatStatus(detail?['status']?.toString());
  }

  Color get statusColor {
    switch (statusText) {
      case 'Disetujui':
        return _primaryGreen;
      case 'Ditolak':
        return const Color(0xFFEF4444);
      case 'Pending':
        return const Color(0xFFF59E0B);
      default:
        return _softText;
    }
  }

  Color get statusBgColor {
    switch (statusText) {
      case 'Disetujui':
        return const Color(0xFFEFFDF5);
      case 'Ditolak':
        return const Color(0xFFFFE4E6);
      case 'Pending':
        return const Color(0xFFFFF7ED);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  num get totalQty {
    final value = _toDouble(summary['total_qty']);

    if (value > 0) return value;

    return items.fold<num>(
      0,
      (total, item) => total + _toDouble(item['qty']),
    );
  }

  String _firstNonEmpty(List<dynamic> values, {String fallback = '-'}) {
    for (final value in values) {
      final text = _cleanText(value);

      if (text.isNotEmpty && text != '-' && text.toLowerCase() != 'null') {
        return text;
      }
    }

    return fallback;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().trim();

    if (raw.isEmpty) return null;

    return DateTime.tryParse(raw);
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatQty(num value) {
    final doubleValue = value.toDouble();

    if (doubleValue % 1 == 0) {
      return doubleValue.toInt().toString();
    }

    return doubleValue.toStringAsFixed(2);
  }

  String _formatCurrency(num value) {
    final raw = _formatQty(value);
    final parts = raw.split('.');
    final number = parts.first;
    final buffer = StringBuffer();

    for (int i = 0; i < number.length; i++) {
      final reverseIndex = number.length - i;

      buffer.write(number[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    if (parts.length > 1) {
      return 'Rp ${buffer.toString()},${parts.last}';
    }

    return 'Rp ${buffer.toString()}';
  }

  String _formatStatus(String? status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status ?? '-';
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '-';

    const bulan = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${bulan[date.month]} ${date.year}';
  }

  String _cleanText(dynamic value) {
    if (value == null) return '';

    return value
        .toString()
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Map<String, dynamic> _detailProductLogoItem(Map<String, dynamic> item) {
    return {
      'id': item['product_id'] ?? item['id'],
      'code': item['product_code'],
      'product_code': item['product_code'],
      'name': item['product_name'],
      'display_name': item['product_name'],
      'full_name': item['product_name'],
      'product_name': item['product_name'],
      'logo_path': item['logo_path'] ?? item['product_logo_path'],
      'product_logo_path': item['product_logo_path'] ?? item['logo_path'],
      'logo_url': item['logo_url'] ?? item['product_logo_url'],
      'product_logo_url': item['product_logo_url'] ?? item['logo_url'],
    };
  }

  Widget _buildDetailProductLogo(
    Map<String, dynamic> item, {
    double size = 42,
  }) {
    return ProductLogo(
      item: _detailProductLogoItem(item),
      size: size,
      selected: false,
      fallbackBaseUrl: _fallbackProductionBaseUrl,
      masterLoadedAtMs: 0,
      rebuildVersion: 0,
    );
  }

  Future<void> _openEditPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TambahBarangMasukScreen(isEdit: true),
        settings: RouteSettings(
          arguments: {
            'id': inboundId,
            'kode': transactionNumber,
            'detail': detail,
          },
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      hasDetailChanged = true;
      await _loadDetail();
    }
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
        backgroundColor: isError ? const Color(0xFFEF4444) : _primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionDate = _parseDate(detail?['transaction_date']);

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _DetailInboundBackgroundPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildTopHeader(),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: _primaryGreen,
                    backgroundColor: Colors.white,
                    onRefresh: _loadDetail,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLoading) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: const LinearProgressIndicator(
                                minHeight: 4,
                                backgroundColor: _borderColor,
                                color: _primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (errorMessage != null && detail == null)
                            _buildErrorState()
                          else if (detail == null)
                            _buildLoadingState()
                          else ...[
                            _buildHeaderCard(transactionDate),
                            const SizedBox(height: 12),
                            _buildDokumenSection(transactionDate),
                            const SizedBox(height: 12),
                            _buildBarangSection(),
                            const SizedBox(height: 12),
                            _buildLokasiSection(),
                            const SizedBox(height: 12),
                            _buildLampiranSection(),
                            if (statusText == 'Pending') ...[
                              const SizedBox(height: 14),
                              _buildEditButton(),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF22C55E),
            Color(0xFF16A34A),
            Color(0xFF15803D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context, hasDetailChanged),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Barang Masuk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Informasi penerimaan barang',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFEFFDF5),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _HeaderIconButton(
            icon: Icons.refresh_rounded,
            onTap: inboundId == null ? null : _loadDetail,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(DateTime? transactionDate) {
    return DetailHeaderCard(
      transactionDate: transactionDate,
      transactionNumber: transactionNumber,
      invoiceNumber: invoiceNumber,
      partnerLabel: 'Supplier',
      partnerName: supplierName,
      warehouseName: warehouseName,
      statusText: statusText,
      statusColor: statusColor,
      statusBgColor: statusBgColor,
      totalItems: items.length,
      totalQty: totalQty,
      unitName: 'PCS',
      formatDate: formatDate,
      formatQty: _formatQty,
    );
  }

  Widget _buildDokumenSection(DateTime? transactionDate) {
    return _buildSection(
      color: _primaryBlue,
      icon: Icons.description_outlined,
      title: 'INFORMASI DOKUMEN',
      child: Column(
        children: [
          DetailInfoRow(
            leftItems: const [
              'Tanggal Barang Masuk',
              'No. Transaksi',
              'No. Invoice',
              'Supplier',
              'Dibuat Oleh',
              'Status',
            ],
            rightItems: [
              formatDate(transactionDate),
              transactionNumber,
              invoiceNumber,
              supplierName,
              submittedByName,
              statusText,
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: DetailStatusBadge(
              text: statusText,
              textColor: statusColor,
              bgColor: statusBgColor,
            ),
          ),
          if (statusText == 'Ditolak' &&
              _cleanText(detail?['rejection_reason']).isNotEmpty) ...[
            const SizedBox(height: 10),
            DetailInfoBox(
              title: 'Alasan Ditolak',
              value: _cleanText(detail?['rejection_reason']),
              backgroundColor: const Color(0xFFFFF1F2),
              borderColor: const Color(0xFFFECACA),
            ),
          ],
          if (_cleanText(detail?['approval_note']).isNotEmpty) ...[
            const SizedBox(height: 10),
            DetailInfoBox(
              title: 'Catatan Approval',
              value: _cleanText(detail?['approval_note']),
              backgroundColor: const Color(0xFFF8FAFC),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBarangSection() {
    return _buildSection(
      color: _primaryGreen,
      icon: Icons.inventory_2_outlined,
      title: 'INFORMASI BARANG',
      child: Column(
        children: [
          if (items.isEmpty)
            const DetailInfoBox(
              title: 'Data Barang',
              value: 'Tidak ada item barang.',
            )
          else
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              final productName = _firstNonEmpty([
                item['product_name'],
                item['product_display_name'],
                item['name'],
              ]);

              final productCode = _firstNonEmpty([
                item['product_code'],
                item['code'],
              ]);

              final unitName = _firstNonEmpty([
                item['unit_name'],
                item['unit'],
              ], fallback: 'PCS');

              final qty = _toDouble(item['qty']);
              final unitCost = _toDouble(item['unit_cost']);
              final subtotal = _toDouble(item['subtotal']);
              final sizeText = _firstNonEmpty([
                item['product_size_text'],
                item['size_text'],
                item['ukuran'],
              ]);

              final note = _cleanText(item['note']);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == items.length - 1 ? 0 : 10,
                ),
                child: DetailItemCard(
                  index: index,
                  productName: productName,
                  productCode: productCode,
                  unitName: unitName,
                  sizeText: sizeText,
                  note: note,
                  qty: qty,
                  unitCost: unitCost,
                  subtotal: subtotal,
                  formatQty: _formatQty,
                  formatCurrency: _formatCurrency,
                  leading: _buildDetailProductLogo(item, size: 42),
                ),
              );
            }),
          const SizedBox(height: 12),
          DetailInfoBox(
            title: 'Ringkasan Barang',
            value:
                'Total item: ${items.length}\n'
                'Total qty: ${_formatQty(totalQty)} PCS\n'
                'Subtotal: ${_formatCurrency(_toDouble(summary['sub_total']))}\n'
                'Diskon: ${_formatCurrency(_toDouble(summary['discount_amount']))}\n'
                'Biaya lain: ${_formatCurrency(_toDouble(summary['other_cost']))}\n'
                'Grand total: ${_formatCurrency(_toDouble(summary['grand_total']))}',
            backgroundColor: const Color(0xFFF8FAFC),
          ),
        ],
      ),
    );
  }

  Widget _buildLokasiSection() {
    return _buildSection(
      color: _primaryBlue,
      icon: Icons.location_on_outlined,
      title: 'LOKASI & CATATAN',
      child: DetailInfoRow(
        leftItems: const [
          'Gudang Tujuan',
          'Kode Gudang',
          'Catatan',
          'Dikirim Pada',
          'Disetujui Pada',
        ],
        rightItems: [
          warehouseName,
          warehouseCode,
          _firstNonEmpty([detail?['note']]),
          _firstNonEmpty([detail?['submitted_at']]),
          _firstNonEmpty([detail?['approved_at']]),
        ],
      ),
    );
  }

  Widget _buildLampiranSection() {
    return _buildSection(
      color: _primaryBlue,
      icon: Icons.attach_file_rounded,
      title: 'LAMPIRAN BUKTI',
      child: DetailAttachmentGrid(
        attachments: attachments,
      ),
    );
  }

  Widget _buildEditButton() {
    return DetailEditButton(
      text: 'Edit Pengajuan Barang Masuk',
      color: _primaryGreen,
      onPressed: _openEditPage,
    );
  }

  Widget _buildSection({
    required Color color,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return DetailSectionCard(
      color: color,
      icon: icon,
      title: title,
      child: child,
    );
  }

  Widget _buildLoadingState() {
    return const DetailLoadingState(
      message: 'Memuat detail barang masuk...',
      color: _primaryGreen,
    );
  }

  Widget _buildErrorState() {
    return DetailErrorState(
      title: 'Gagal memuat detail',
      message: errorMessage ?? 'Terjadi kesalahan saat memuat data.',
      color: _primaryGreen,
      onRetry: inboundId == null ? null : _loadDetail,
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: Colors.white,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _DetailInboundBackgroundPainter extends CustomPainter {
  const _DetailInboundBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF7FAFC),
          Color(0xFFF0FDF4),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);

    final topCircle = Paint()
      ..color = const Color(0xFFEFFDF5).withValues(alpha: 0.65);

    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.10),
      size.width * 0.35,
      topCircle,
    );

    final bottomCircle = Paint()
      ..color = const Color(0xFFEFF6FF).withValues(alpha: 0.55);

    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.88),
      size.width * 0.40,
      bottomCircle,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}