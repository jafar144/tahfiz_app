import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';

enum PaymentStatus { paid, upcoming, overdue, notApplicable }

class PaymentYearView extends StatefulWidget {
  final Map<int, Set<int>> paidData;
  final DateTime? startDate;

  /// Saat true, bulan yang belum dibayar (belum/menunggak) bisa diketuk untuk
  /// dipilih. Bulan lunas atau sebelum tanggal mulai tidak bisa dipilih.
  final bool selectable;

  /// Bulan yang sedang dipilih, dikelompokkan per tahun (`{tahun: {bulan}}`).
  final Map<int, Set<int>> selectedData;

  /// Dipanggil saat sebuah sel bulan diketuk pada mode [selectable].
  final void Function(int year, int month)? onToggleMonth;

  const PaymentYearView({
    super.key,
    required this.paidData,
    this.startDate,
    this.selectable = false,
    this.selectedData = const {},
    this.onToggleMonth,
  });

  @override
  State<PaymentYearView> createState() => _PaymentYearViewState();
}

class _PaymentYearViewState extends State<PaymentYearView> {
  late int _selectedYear;

  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MEI',
    'JUN',
    'JUL',
    'AGS',
    'SEP',
    'OKT',
    'NOV',
    'DES',
  ];

  static const _yearsBehind = 2;
  static const _yearsAhead = 1;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.startDate?.year ?? DateTime.now().year;
    if (_selectedYear > DateTime.now().year + _yearsAhead) {
      _selectedYear = DateTime.now().year;
    }
  }

  PaymentStatus _getStatus(int month) {
    final now = DateTime.now();
    final startDate = widget.startDate;

    if (startDate != null) {
      final cellDate = DateTime(_selectedYear, month);
      final start = DateTime(startDate.year, startDate.month);
      if (cellDate.isBefore(start)) return PaymentStatus.notApplicable;
    }

    final paidMonths = widget.paidData[_selectedYear] ?? {};
    if (paidMonths.contains(month)) return PaymentStatus.paid;

    if (_selectedYear < now.year) return PaymentStatus.overdue;
    if (_selectedYear > now.year) return PaymentStatus.upcoming;

    if (month <= now.month) return PaymentStatus.overdue;
    return PaymentStatus.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = widget.startDate;
    // Batas bawah navigasi: tahun startDate (jika ada), atau (sekarang - 1)
    final minYear = startDate != null
        ? startDate.year
        : now.year - _yearsBehind;
    final maxYear = now.year + _yearsAhead;

    return Column(
      children: [
        _buildYearHeader(minYear, maxYear),
        const SizedBox(height: 12),
        _buildGrid(now),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  Widget _buildYearHeader(int minYear, int maxYear) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _selectedYear > minYear
              ? () => setState(() => _selectedYear--)
              : null,
          icon: const Icon(Icons.chevron_left),
          color: AppColors.primary,
          disabledColor: AppColors.divider,
        ),
        SizedBox(
          width: 72,
          child: Text(
            _selectedYear.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: _selectedYear < maxYear
              ? () => setState(() => _selectedYear++)
              : null,
          icon: const Icon(Icons.chevron_right),
          color: AppColors.primary,
          disabledColor: AppColors.divider,
        ),
      ],
    );
  }

  Widget _buildGrid(DateTime now) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final monthNumber = index + 1;
        final status = _getStatus(monthNumber);
        final isCurrentMonth =
            monthNumber == now.month && _selectedYear == now.year;

        final isSelected =
            widget.selectedData[_selectedYear]?.contains(monthNumber) ?? false;
        final canSelect =
            widget.selectable &&
            (status == PaymentStatus.overdue ||
                status == PaymentStatus.upcoming);

        final cell = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _months[index],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : isCurrentMonth
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            _buildCircle(status, isSelected: isSelected),
          ],
        );

        if (!canSelect) return cell;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onToggleMonth?.call(_selectedYear, monthNumber),
          child: cell,
        );
      },
    );
  }

  Widget _buildCircle(PaymentStatus status, {bool isSelected = false}) {
    if (isSelected) {
      return _circle(
        border: AppColors.primary,
        fill: AppColors.primary,
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
      );
    }
    switch (status) {
      case PaymentStatus.paid:
        return _circle(
          border: AppColors.success,
          fill: AppColors.success.withValues(alpha: 0.12),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 22,
          ),
        );
      case PaymentStatus.overdue:
        return _circle(
          border: AppColors.error,
          fill: AppColors.error.withValues(alpha: 0.1),
          child: const Icon(
            Icons.close_rounded,
            color: AppColors.error,
            size: 22,
          ),
        );
      case PaymentStatus.upcoming:
        return _circle(
          border: AppColors.divider,
          fill: AppColors.divider.withValues(alpha: 0.3),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
        );
      case PaymentStatus.notApplicable:
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.divider.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
    }
  }

  Widget _circle({
    required Color border,
    required Color fill,
    required Widget child,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
        color: fill,
      ),
      child: Center(child: child),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem(AppColors.success, 'Lunas'),
        _legendItem(AppColors.textSecondary, 'Belum'),
        _legendItem(AppColors.error, 'Menunggak'),
        if (widget.selectable) _legendItem(AppColors.primary, 'Dipilih'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
