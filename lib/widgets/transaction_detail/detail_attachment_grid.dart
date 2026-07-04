import 'package:flutter/material.dart';

class DetailAttachmentGrid extends StatelessWidget {
  final List<Map<String, dynamic>> attachments;

  const DetailAttachmentGrid({
    super.key,
    required this.attachments,
  });

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _primaryGreen = Color(0xFF16A34A);
  static const Color _primaryRed = Color(0xFFEF4444);
  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const _EmptyAttachmentBox();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 500 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: attachments.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final attachment = attachments[index];

            final fileName = _cleanText(attachment['file_name']);
            final mimeType = _cleanText(attachment['mime_type']);
            final fileUrl = _cleanText(attachment['file_url']);
            final fileSize = _fileSize(attachment['file_size']);

            final isImage = _isImageAttachment(
              mimeType: mimeType,
              fileName: fileName,
              fileUrl: fileUrl,
            );

            return _AttachmentCard(
              fileName: fileName.isEmpty ? '-' : fileName,
              mimeType: mimeType,
              fileUrl: fileUrl,
              fileSize: fileSize,
              isImage: isImage,
            );
          },
        );
      },
    );
  }

  static String _cleanText(dynamic value) {
    if (value == null) return '';

    return value
        .toString()
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0;
  }

  static String _formatQty(num value) {
    final doubleValue = value.toDouble();

    if (doubleValue % 1 == 0) {
      return doubleValue.toInt().toString();
    }

    return doubleValue.toStringAsFixed(2);
  }

  static String _fileSize(dynamic value) {
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

  static bool _isImageAttachment({
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
}

class _AttachmentCard extends StatelessWidget {
  final String fileName;
  final String mimeType;
  final String fileUrl;
  final String fileSize;
  final bool isImage;

  const _AttachmentCard({
    required this.fileName,
    required this.mimeType,
    required this.fileUrl,
    required this.fileSize,
    required this.isImage,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DetailAttachmentGrid._borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: isImage && fileUrl.isNotEmpty
                      ? Image.network(
                          fileUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;

                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DetailAttachmentGrid._primaryBlue,
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
                  left: 8,
                  top: 8,
                  child: _typeBadge(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _bottomOverlay(),
                ),
                if (isImage && fileUrl.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.zoom_in_rounded,
                        size: 17,
                        color: DetailAttachmentGrid._darkText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeBadge() {
    final color = isImage
        ? DetailAttachmentGrid._primaryGreen
        : DetailAttachmentGrid._primaryBlue;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isImage ? const Color(0xFFEFFDF5) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isImage ? const Color(0xFFBBF7D0) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isImage ? 'Gambar' : 'File',
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomOverlay() {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 18, 9, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.74),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fileName.trim().isEmpty ? '-' : fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(
                Icons.sd_storage_outlined,
                size: 11,
                color: Color(0xFFE5E7EB),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  fileSize,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFFE5E7EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (isImage && fileUrl.isNotEmpty) {
      _showImagePreview(
        context: context,
        imageUrl: fileUrl,
        fileName: fileName,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Preview hanya tersedia untuk file gambar.',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: DetailAttachmentGrid._primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
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
          color: DetailAttachmentGrid._primaryBlue,
          size: 38,
        ),
      ),
    );
  }

  void _showImagePreview({
    required BuildContext context,
    required String imageUrl,
    required String fileName,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.82),
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
                _previewHeader(context),
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
                                  color: DetailAttachmentGrid._primaryBlue,
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
                                  color: DetailAttachmentGrid._primaryRed,
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

  Widget _previewHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: DetailAttachmentGrid._primaryBlue,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.image_outlined,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName.trim().isEmpty ? 'Preview Gambar' : fileName,
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
    );
  }
}

class _EmptyAttachmentBox extends StatelessWidget {
  const _EmptyAttachmentBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: DetailAttachmentGrid._borderColor,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.attach_file_rounded,
            size: 18,
            color: DetailAttachmentGrid._softText,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lampiran',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: DetailAttachmentGrid._softText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Belum ada lampiran dokumen.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w600,
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