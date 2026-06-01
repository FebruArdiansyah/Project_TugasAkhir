import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'tambah_barang_masuk.dart';

class DetailBarangMasukScreen extends StatefulWidget {
  const DetailBarangMasukScreen({super.key});

  @override
  State<DetailBarangMasukScreen> createState() =>
      _DetailBarangMasukScreenState();
}

class _DetailBarangMasukScreenState extends State<DetailBarangMasukScreen> {
  bool isLoading = false;
  bool isArgumentLoaded = false;

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
        throw ApiException(message: 'Response detail barang masuk tidak valid.');
      }

      final data = response['data'];

      if (data is! Map<String, dynamic>) {
        throw ApiException(message: 'Data detail barang masuk tidak valid.');
      }

      setState(() {
        detail = data;
      });
    } on ApiException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
      _showSnackBar(e.message, isError: true);
    } catch (e) {
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

    return {};
  }

  Map<String, dynamic> get warehouse {
    final value = detail?['warehouse'];

    if (value is Map<String, dynamic>) return value;

    return {};
  }

  Map<String, dynamic> get submittedBy {
    final value = detail?['submitted_by'];

    if (value is Map<String, dynamic>) return value;

    return {};
  }

  Map<String, dynamic> get summary {
    final value = detail?['summary'];

    if (value is Map<String, dynamic>) return value;

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
    return detail?['transaction_number']?.toString() ?? '-';
  }

  String get statusText {
    return _formatStatus(detail?['status']?.toString());
  }

  Color get statusColor {
    switch (statusText) {
      case 'Disetujui':
        return const Color(0xFF16A34A);
      case 'Ditolak':
        return const Color(0xFFEF4444);
      case 'Pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
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

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final raw = value.toString();

    if (raw.trim().isEmpty) return null;

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

  String _fileSize(dynamic value) {
    final size = _toDouble(value);

    if (size <= 0) return '-';

    if (size < 1024) {
      return '${_formatQty(size)} B';
    }

    if (size < 1024 * 1024) {
      return '${_formatQty(size / 1024)} KB';
    }

    return '${_formatQty(size / 1024 / 1024)} MB';
  }

  bool _isImageAttachment({
    required String mimeType,
    required String fileName,
    required String fileUrl,
  }) {
    final mime = mimeType.toLowerCase();
    final name = fileName.toLowerCase();
    final url = fileUrl.toLowerCase();

    return mime.startsWith('image/') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png') ||
        url.endsWith('.webp');
  }

  Widget _fileFallbackIcon(String mimeType) {
    final isPdf = mimeType.toLowerCase().contains('pdf');

    return Container(
      color: const Color(0xFFEFF6FF),
      child: Center(
        child: Icon(
          isPdf
              ? Icons.picture_as_pdf_outlined
              : Icons.insert_drive_file_outlined,
          color: const Color(0xFF2F47B7),
          size: 36,
        ),
      ),
    );
  }

  void _showImagePreview({
    required String imageUrl,
    required String fileName,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(14),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.86,
              maxWidth: MediaQuery.of(context).size.width * 0.96,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2F47B7),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(999),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;

                            return const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2F47B7),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Gambar gagal dimuat.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openEditPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TambahBarangMasukScreen(isEdit: true),
        settings: RouteSettings(
          arguments: {
            'id': inboundId,
            'kode': transactionNumber,
          },
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionDate = _parseDate(detail?['transaction_date']);

    return Scaffold(
      backgroundColor: const Color(0xFFDCE3F1),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDetail,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLoading) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: const LinearProgressIndicator(
                            minHeight: 4,
                            backgroundColor: Color(0xFFE5E7EB),
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (errorMessage != null && detail == null)
                        _buildErrorState()
                      else if (detail == null)
                        _buildLoadingState()
                      else ...[
                        _buildHeaderCard(transactionDate),
                        const SizedBox(height: 10),
                        _buildDokumenSection(transactionDate),
                        const SizedBox(height: 10),
                        _buildBarangSection(),
                        const SizedBox(height: 10),
                        _buildLokasiSection(),
                        const SizedBox(height: 10),
                        _buildLampiranSection(),
                        const SizedBox(height: 12),
                        if (statusText == 'Pending') _buildEditButton(context),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: const Color(0xFF2F47B7),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Detail Barang Masuk',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: inboundId == null ? null : _loadDetail,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(DateTime? transactionDate) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD8F3DC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.download_rounded,
              color: Color(0xFF16A34A),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tanggal',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF4E5563),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Supplier',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Total Barang',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 145,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transactionNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF15803D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  supplier['name']?.toString() ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatQty(_toDouble(summary['total_qty']))} PCS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF111827),
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

  Widget _buildDokumenSection(DateTime? transactionDate) {
    return _buildSection(
      color: const Color(0xFF2F47B7),
      icon: Icons.description_outlined,
      title: 'INFORMASI DOKUMEN',
      child: Column(
        children: [
          _InfoTwoColumn(
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
              detail?['invoice_number']?.toString() ?? '-',
              supplier['name']?.toString() ?? '-',
              submittedBy['name']?.toString() ?? '-',
              statusText,
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _StatusBadge(
              text: statusText,
              textColor: statusColor,
              bgColor: statusBgColor,
            ),
          ),
          if (statusText == 'Ditolak' &&
              _cleanText(detail?['rejection_reason']).isNotEmpty) ...[
            const SizedBox(height: 8),
            _FullInfoBox(
              title: 'Alasan Ditolak',
              value: _cleanText(detail?['rejection_reason']),
            ),
          ],
          if (_cleanText(detail?['approval_note']).isNotEmpty) ...[
            const SizedBox(height: 8),
            _FullInfoBox(
              title: 'Catatan Approval',
              value: _cleanText(detail?['approval_note']),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBarangSection() {
    return _buildSection(
      color: const Color(0xFF2F47B7),
      icon: Icons.inventory_2_outlined,
      title: 'INFORMASI BARANG',
      child: Column(
        children: [
          if (items.isEmpty)
            const _FullInfoBox(
              title: 'Data Barang',
              value: 'Tidak ada item barang.',
            )
          else
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              final productName = item['product_name']?.toString() ?? '-';
              final productCode = item['product_code']?.toString() ?? '-';
              final unitName = item['unit_name']?.toString() ?? 'PCS';
              final qty = _toDouble(item['qty']);
              final unitCost = _toDouble(item['unit_cost']);
              final subtotal = _toDouble(item['subtotal']);
              final sizeText = _cleanText(item['product_size_text']);
              final note = _cleanText(item['note']);

              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(
                  bottom: index == items.length - 1 ? 0 : 10,
                ),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF2F47B7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _miniPill(productCode),
                              _miniPill('${_formatQty(qty)} $unitName'),
                              _miniPill(_formatCurrency(unitCost)),
                            ],
                          ),
                          const SizedBox(height: 7),
                          _detailLine('Subtotal', _formatCurrency(subtotal)),
                          if (sizeText.isNotEmpty)
                            _detailLine('Ukuran', sizeText),
                          if (note.isNotEmpty) _detailLine('Catatan', note),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 10),
          _FullInfoBox(
            title: 'Ringkasan Barang',
            value:
                'Total item: ${items.length}\nTotal qty: ${_formatQty(_toDouble(summary['total_qty']))} PCS\nSubtotal: ${_formatCurrency(_toDouble(summary['sub_total']))}\nDiskon: ${_formatCurrency(_toDouble(summary['discount_amount']))}\nBiaya lain: ${_formatCurrency(_toDouble(summary['other_cost']))}\nGrand total: ${_formatCurrency(_toDouble(summary['grand_total']))}',
          ),
        ],
      ),
    );
  }

  Widget _buildLokasiSection() {
    return _buildSection(
      color: const Color(0xFF2F47B7),
      icon: Icons.location_on_outlined,
      title: 'LOKASI & CATATAN',
      child: Column(
        children: [
          _InfoTwoColumn(
            leftItems: const [
              'Gudang Tujuan',
              'Kode Gudang',
              'Catatan',
              'Dikirim Pada',
              'Disetujui Pada',
            ],
            rightItems: [
              warehouse['name']?.toString() ?? '-',
              warehouse['code']?.toString() ?? '-',
              _cleanText(detail?['note']).isEmpty
                  ? '-'
                  : _cleanText(detail?['note']),
              detail?['submitted_at']?.toString() ?? '-',
              detail?['approved_at']?.toString() ?? '-',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLampiranSection() {
    return _buildSection(
      color: const Color(0xFF2F47B7),
      icon: Icons.attach_file,
      title: 'LAMPIRAN BUKTI',
      child: attachments.isEmpty
          ? const _FullInfoBox(
              title: 'Lampiran',
              value: 'Belum ada lampiran dokumen.',
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attachments.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final attachment = attachments[index];

                final fileName = attachment['file_name']?.toString() ?? '-';
                final mimeType = attachment['mime_type']?.toString() ?? '';
                final fileUrl = attachment['file_url']?.toString() ?? '';
                final fileSize = _fileSize(attachment['file_size']);

                final isImage = _isImageAttachment(
                  mimeType: mimeType,
                  fileName: fileName,
                  fileUrl: fileUrl,
                );

                return InkWell(
                  onTap: () {
                    if (isImage && fileUrl.isNotEmpty) {
                      _showImagePreview(
                        imageUrl: fileUrl,
                        fileName: fileName,
                      );
                    } else {
                      _showSnackBar(
                        'Preview hanya tersedia untuk file gambar.',
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: isImage && fileUrl.isNotEmpty
                                ? Image.network(
                                    fileUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }

                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF2F47B7),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return _fileFallbackIcon(mimeType);
                                    },
                                  )
                                : _fileFallbackIcon(mimeType),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.0),
                                    Colors.black.withOpacity(0.62),
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    fileSize,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFFE5E7EB),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isImage)
                            Positioned(
                              top: 7,
                              right: 7,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'FILE',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Color(0xFF2F47B7),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.edit),
        label: const Text('Edit Pengajuan'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B6DF0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _openEditPage,
      ),
    );
  }

  Widget _buildSection({
    required Color color,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _miniPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFD1D5DB),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF374151),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              fontSize: 10.5,
              color: Color(0xFF6B7280),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            color: Color(0xFF16A34A),
          ),
          SizedBox(height: 12),
          Text(
            'Memuat detail barang masuk...',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 34,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 42,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 10),
          const Text(
            'Gagal memuat detail',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            errorMessage ?? 'Terjadi kesalahan saat memuat data.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: inboundId == null ? null : _loadDetail,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTwoColumn extends StatelessWidget {
  final List<String> leftItems;
  final List<String> rightItems;

  const _InfoTwoColumn({
    required this.leftItems,
    required this.rightItems,
  });

  @override
  Widget build(BuildContext context) {
    final totalRows = leftItems.length > rightItems.length
        ? leftItems.length
        : rightItems.length;

    return Column(
      children: List.generate(totalRows, (index) {
        final left = index < leftItems.length ? leftItems[index] : '';
        final right = index < rightItems.length ? rightItems[index] : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  left,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  right.trim().isEmpty ? '-' : right,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color bgColor;

  const _StatusBadge({
    required this.text,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;

    if (text == 'Pending') {
      icon = Icons.schedule_rounded;
    } else if (text == 'Disetujui') {
      icon = Icons.check_circle_outline_rounded;
    } else {
      icon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: textColor.withOpacity(0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullInfoBox extends StatelessWidget {
  final String title;
  final String value;

  const _FullInfoBox({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final String displayValue = value.trim().isEmpty ? '-' : value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}