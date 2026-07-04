import 'package:flutter/material.dart';

import 'detail_status_badge.dart';

class DetailOutboundHeaderCard extends StatelessWidget {
  final DateTime? transactionDate;
  final String transactionNumber;
  final String referenceNumber;
  final String outboundType;
  final String partnerLabel;
  final String partnerName;
  final String warehouseName;
  final String statusText;
  final Color statusColor;
  final Color statusBgColor;
  final int totalItems;
  final num totalQty;
  final String unitName;
  final String Function(DateTime? date) formatDate;
  final String Function(num value) formatQty;

  const DetailOutboundHeaderCard({
    super.key,
    required this.transactionDate,
    required this.transactionNumber,
    required this.referenceNumber,
    required this.outboundType,
    required this.partnerLabel,
    required this.partnerName,
    required this.warehouseName,
    required this.statusText,
    required this.statusColor,
    required this.statusBgColor,
    required this.totalItems,
    required this.totalQty,
    required this.unitName,
    required this.formatDate,
    required this.formatQty,
  });

  static const Color _primaryRed = Color(0xFFEF4444);
  static const Color _darkRed = Color(0xFFDC2626);
  static const Color _softRed = Color(0xFFFFE4E6);
  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final safeReference =
        referenceNumber.trim().isEmpty ? '-' : referenceNumber.trim();
    final safeOutboundType =
        outboundType.trim().isEmpty ? '-' : outboundType.trim();
    final safePartner = partnerName.trim().isEmpty ? '-' : partnerName.trim();
    final safeWarehouse =
        warehouseName.trim().isEmpty ? '-' : warehouseName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF5757),
            _primaryRed,
            _darkRed,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryRed.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topHeader(),
          const SizedBox(height: 14),
          _infoPanel(
            referenceNumber: safeReference,
            outboundType: safeOutboundType,
            partnerName: safePartner,
            warehouseName: safeWarehouse,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryBox(
                  title: 'Total Item',
                  value: '$totalItems',
                  subtitle: 'Jenis barang',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SummaryBox(
                  title: 'Total Keluar',
                  value: '${formatQty(totalQty)} $unitName',
                  subtitle: 'Jumlah keluar',
                  icon: Icons.outbox_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: const Icon(
            Icons.upload_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Barang Keluar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Detail pengeluaran barang gudang',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: _softRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 0,
          child: DetailStatusBadge(
            text: statusText,
            textColor: statusColor,
            bgColor: statusBgColor,
          ),
        ),
      ],
    );
  }

  Widget _infoPanel({
    required String referenceNumber,
    required String outboundType,
    required String partnerName,
    required String warehouseName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        children: [
          _HeaderInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal Keluar',
            value: formatDate(transactionDate),
          ),
          const SizedBox(height: 9),
          _HeaderInfoRow(
            icon: Icons.category_outlined,
            label: 'Jenis Keluar',
            value: outboundType,
          ),
          const SizedBox(height: 9),
          _HeaderInfoRow(
            icon: Icons.receipt_long_outlined,
            label: 'No. Transaksi',
            value: transactionNumber,
          ),
          const SizedBox(height: 9),
          _HeaderInfoRow(
            icon: Icons.confirmation_number_outlined,
            label: 'No. Referensi',
            value: referenceNumber,
          ),
          const SizedBox(height: 9),
          _HeaderInfoRow(
            icon: Icons.person_outline_rounded,
            label: partnerLabel,
            value: partnerName,
          ),
          const SizedBox(height: 9),
          _HeaderInfoRow(
            icon: Icons.warehouse_outlined,
            label: 'Gudang Asal',
            value: warehouseName,
          ),
        ],
      ),
    );
  }
}

class _HeaderInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.trim().isEmpty ? '-' : value.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: Colors.white,
        ),
        const SizedBox(width: 7),
        SizedBox(
          width: 92,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: DetailOutboundHeaderCard._softRed,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            safeValue,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.3,
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _SummaryBox({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: DetailOutboundHeaderCard._softRed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: DetailOutboundHeaderCard._primaryRed,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: DetailOutboundHeaderCard._softText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: DetailOutboundHeaderCard._darkText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF9CA3AF),
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