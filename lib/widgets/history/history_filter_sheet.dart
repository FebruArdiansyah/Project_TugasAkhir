import 'package:flutter/material.dart';

typedef HistoryDateFormatter = String Function(DateTime date);

Future<void> showHistoryDateFilterSheet({
  required BuildContext context,
  required DateTime? initialStartDate,
  required DateTime? initialEndDate,
  required HistoryDateFormatter formatDate,
  required void Function(DateTime? startDate, DateTime? endDate) onApply,
  required VoidCallback onReset,
}) {
  DateTime? startDate = initialStartDate;
  DateTime? endDate = initialEndDate;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickStartDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: startDate ?? endDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2035),
              helpText: 'Pilih tanggal awal',
              cancelText: 'Batal',
              confirmText: 'Pilih',
            );

            if (picked == null) return;

            setModalState(() {
              startDate = picked;

              if (endDate != null && endDate!.isBefore(picked)) {
                endDate = picked;
              }
            });
          }

          Future<void> pickEndDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: endDate ?? startDate ?? DateTime.now(),
              firstDate: startDate ?? DateTime(2000),
              lastDate: DateTime(2035),
              helpText: 'Pilih tanggal akhir',
              cancelText: 'Batal',
              confirmText: 'Pilih',
            );

            if (picked == null) return;

            setModalState(() {
              endDate = picked;

              if (startDate != null && startDate!.isAfter(picked)) {
                startDate = picked;
              }
            });
          }

          final hasFilter = startDate != null || endDate != null;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sheetHeader(),
                    const SizedBox(height: 16),
                    _HistoryDateBox(
                      label: 'Dari Tanggal',
                      value: startDate == null
                          ? 'Pilih tanggal awal'
                          : formatDate(startDate!),
                      icon: Icons.calendar_today_outlined,
                      isSelected: startDate != null,
                      onTap: pickStartDate,
                    ),
                    const SizedBox(height: 10),
                    _HistoryDateBox(
                      label: 'Sampai Tanggal',
                      value: endDate == null
                          ? 'Pilih tanggal akhir'
                          : formatDate(endDate!),
                      icon: Icons.event_available_outlined,
                      isSelected: endDate != null,
                      onTap: pickEndDate,
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: hasFilter
                          ? Padding(
                              key: const ValueKey('active-date-filter-info'),
                              padding: const EdgeInsets.only(top: 14),
                              child: _activeFilterInfo(
                                startDate: startDate,
                                endDate: endDate,
                                formatDate: formatDate,
                              ),
                            )
                          : const SizedBox(
                              key: ValueKey('no-active-date-filter-info'),
                              height: 14,
                            ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                startDate = null;
                                endDate = null;
                                onReset();
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6B7280),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                onApply(startDate, endDate);
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Terapkan',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2F47B7),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _sheetHeader() {
  return Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFBFDBFE),
          ),
        ),
        child: const Icon(
          Icons.calendar_month_outlined,
          color: Color(0xFF2F47B7),
          size: 22,
        ),
      ),
      const SizedBox(width: 11),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Tanggal',
              style: TextStyle(
                fontSize: 17,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Tampilkan transaksi berdasarkan rentang tanggal',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _activeFilterInfo({
  required DateTime? startDate,
  required DateTime? endDate,
  required HistoryDateFormatter formatDate,
}) {
  final startText = startDate == null ? 'Awal' : formatDate(startDate);
  final endText = endDate == null ? 'Akhir' : formatDate(endDate);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: const Color(0xFFBFDBFE),
      ),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 17,
          color: Color(0xFF2563EB),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$startText - $endText',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HistoryDateBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _HistoryDateBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  static const Color _primaryBlue = Color(0xFF2F47B7);
  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFBFDBFE) : _borderColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isSelected ? const Color(0xFFBFDBFE) : _borderColor,
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _softText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? _primaryBlue : _darkText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}