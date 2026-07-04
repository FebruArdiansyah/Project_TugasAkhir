import 'package:flutter/material.dart';

class HistoryPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const HistoryPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  static const Color _primaryBlue = Color(0xFF2F47B7);
  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF6B7280);
  static const Color _mutedText = Color(0xFF9CA3AF);
  static const Color _borderColor = Color(0xFFD1D5DB);
  static const Color _lightBorderColor = Color(0xFFE5E7EB);
  static const Color _softBg = Color(0xFFF8FAFC);
  static const Color _blueSoft = Color(0xFFEFF6FF);

  int get _safeCurrentPage {
    if (totalPages <= 1) return 1;
    if (currentPage < 1) return 1;
    if (currentPage > totalPages) return totalPages;

    return currentPage;
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final page = _safeCurrentPage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        children: [
          _arrowButton(
            icon: Icons.chevron_left_rounded,
            enabled: page > 1,
            onTap: () => onPageChanged(page - 1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => _showPagePicker(context, page),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                height: 42,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _borderColor,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.035),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 16,
                      color: _primaryBlue,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'Halaman $page dari $totalPages',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _darkText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: _softText,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _arrowButton(
            icon: Icons.chevron_right_rounded,
            enabled: page < totalPages,
            onTap: () => onPageChanged(page + 1),
          ),
        ],
      ),
    );
  }

  Widget _arrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 24,
            color: enabled ? _primaryBlue : _mutedText,
          ),
        ),
      ),
    );
  }

  void _showPagePicker(BuildContext context, int activePage) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72,
            ),
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
                    color: _lightBorderColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                _sheetHeader(),
                const SizedBox(height: 16),
                Flexible(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth >= 390 ? 6 : 5;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 4),
                        itemCount: totalPages,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.25,
                        ),
                        itemBuilder: (context, index) {
                          final page = index + 1;
                          final isActive = page == activePage;

                          return _pageButton(
                            page: page,
                            isActive: isActive,
                            onTap: () {
                              Navigator.pop(context);

                              if (page != activePage) {
                                onPageChanged(page);
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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
            color: _blueSoft,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFBFDBFE),
            ),
          ),
          child: const Icon(
            Icons.menu_book_outlined,
            color: _primaryBlue,
            size: 22,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Halaman',
                style: TextStyle(
                  fontSize: 17,
                  color: _darkText,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Pilih nomor halaman riwayat transaksi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: _softText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pageButton({
    required int page,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? _primaryBlue : _softBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? _primaryBlue : _lightBorderColor,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _primaryBlue.withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$page',
          style: TextStyle(
            fontSize: 12.5,
            color: isActive ? Colors.white : const Color(0xFF374151),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}