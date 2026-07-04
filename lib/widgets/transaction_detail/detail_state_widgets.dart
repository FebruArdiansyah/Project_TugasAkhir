import 'package:flutter/material.dart';

class DetailLoadingState extends StatelessWidget {
  final String message;
  final Color color;

  const DetailLoadingState({
    super.key,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safeMessage = message.trim().isEmpty
        ? 'Memuat data...'
        : message.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              color: color,
              strokeWidth: 2.8,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            safeMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class DetailErrorState extends StatelessWidget {
  final String title;
  final String message;
  final Color color;
  final VoidCallback? onRetry;

  const DetailErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.color,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final safeTitle = title.trim().isEmpty ? 'Gagal memuat data' : title.trim();
    final safeMessage = message.trim().isEmpty
        ? 'Terjadi kesalahan saat memuat data.'
        : message.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 34,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.14),
              ),
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 31,
              color: color,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            safeTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            safeMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.8,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 17),
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                disabledBackgroundColor: color.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailEditButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const DetailEditButton({
    super.key,
    required this.text,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final safeText = text.trim().isEmpty ? 'Edit Pengajuan' : text.trim();

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.edit_note_rounded,
          size: 21,
        ),
        label: Flexible(
          child: Text(
            safeText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}