import 'package:flutter/material.dart';

class DetailStatusBadge extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color bgColor;

  const DetailStatusBadge({
    super.key,
    required this.text,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final safeText = text.trim().isEmpty ? '-' : text.trim();

    IconData icon;

    if (safeText == 'Pending') {
      icon = Icons.schedule_rounded;
    } else if (safeText == 'Disetujui') {
      icon = Icons.check_circle_outline_rounded;
    } else if (safeText == 'Ditolak') {
      icon = Icons.cancel_outlined;
    } else {
      icon = Icons.info_outline_rounded;
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 116),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: textColor.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              safeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}