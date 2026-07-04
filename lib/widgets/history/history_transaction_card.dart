import 'package:flutter/material.dart';

class HistoryTransactionCard extends StatelessWidget {
  final String nomor;
  final bool isMasuk;
  final String tanggal;
  final String supplier;
  final String partnerLabel;
  final String warehouse;
  final String totalBarang;
  final String kode;
  final String nama;
  final String status;
  final String inputOleh;
  final String? alasan;
  final VoidCallback onTap;

  const HistoryTransactionCard({
    super.key,
    required this.nomor,
    required this.isMasuk,
    required this.tanggal,
    required this.supplier,
    required this.partnerLabel,
    required this.warehouse,
    required this.totalBarang,
    required this.kode,
    required this.nama,
    required this.status,
    required this.inputOleh,
    required this.onTap,
    this.alasan,
  });

  bool get isPending => status == 'Pending';

  bool get isApproved => status == 'Disetujui';

  bool get isRejected => status == 'Ditolak';

  String get displayInputOleh {
    final value = inputOleh.trim();

    if (value.isEmpty ||
        value == '-' ||
        value.toLowerCase() == 'null' ||
        value.toLowerCase() == 'user mobile') {
      return 'Belum tersedia';
    }

    return value;
  }

  Color get typeColor {
    return isMasuk ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
  }

  Color get typeBgColor {
    return isMasuk ? const Color(0xFFEFFDF5) : const Color(0xFFFFECEC);
  }

  Color get statusColor {
    if (isPending) return const Color(0xFFF59E0B);
    if (isApproved) return const Color(0xFF16A34A);
    return const Color(0xFFEF4444);
  }

  Color get statusBgColor {
    if (isPending) return const Color(0xFFFFF7ED);
    if (isApproved) return const Color(0xFFEFFDF5);
    return const Color(0xFFFFE4E6);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: typeColor.withValues(alpha: 0.06),
        highlightColor: typeColor.withValues(alpha: 0.025),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE5EAF2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.055),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: typeColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopRow(),
                      const SizedBox(height: 12),
                      _buildTypeRow(),
                      const SizedBox(height: 10),
                      _buildTitleArea(),
                      const SizedBox(height: 13),
                      _buildInfoGrid(),
                      const SizedBox(height: 11),
                      _buildInputOlehRow(),
                      if (isRejected &&
                          alasan != null &&
                          alasan!.trim().isNotEmpty) ...[
                        const SizedBox(height: 11),
                        _buildRejectedReason(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: typeBgColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: typeColor.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            isMasuk ? Icons.download_rounded : Icons.upload_rounded,
            color: typeColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            kode,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              color: typeColor,
              fontWeight: FontWeight.w900,
              height: 1.16,
              letterSpacing: -0.1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _statusBadge(),
      ],
    );
  }

  Widget _buildTypeRow() {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _smallBadge(
          text: isMasuk ? 'Barang Masuk' : 'Barang Keluar',
          color: typeColor,
          bgColor: typeBgColor,
          borderColor: typeColor.withValues(alpha: 0.16),
        ),
        _smallBadge(
          text: 'No. $nomor',
          color: const Color(0xFF667085),
          bgColor: const Color(0xFFF3F4F6),
          borderColor: const Color(0xFFE5EAF2),
        ),
      ],
    );
  }

  Widget _buildTitleArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nama,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14.7,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -0.15,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Icon(
              isMasuk
                  ? Icons.storefront_outlined
                  : Icons.person_pin_circle_outlined,
              size: 15,
              color: const Color(0xFF667085),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$partnerLabel: $supplier',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    return Row(
      children: [
        Expanded(
          child: _infoBox(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal',
            value: tanggal,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _infoBox(
            icon: Icons.inventory_2_outlined,
            label: 'Jumlah',
            value: totalBarang,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _infoBox(
            icon: Icons.warehouse_outlined,
            label: 'Gudang',
            value: warehouse,
          ),
        ),
      ],
    );
  }

  Widget _buildInputOlehRow() {
    final bool notAvailable = displayInputOleh == 'Belum tersedia';

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
          color: const Color(0xFFE5EAF2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_outline_rounded,
            size: 16,
            color: Color(0xFF667085),
          ),
          const SizedBox(width: 8),
          const Text(
            'Input oleh',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF667085),
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              displayInputOleh,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.2,
                color: notAvailable
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF111827),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedReason() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFCA5A5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: Color(0xFFB91C1C),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Alasan ditolak: ${alasan ?? '-'}',
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 74,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15,
            color: const Color(0xFF667085),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.8,
              color: Color(0xFF667085),
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.9,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallBadge({
    required String text,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }

  Widget _statusBadge() {
    IconData icon;

    if (isPending) {
      icon = Icons.schedule_rounded;
    } else if (isApproved) {
      icon = Icons.check_circle_outline_rounded;
    } else {
      icon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: statusBgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 10.5,
              color: statusColor,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}