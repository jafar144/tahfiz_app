import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/core/utils/payment_utils.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_wheel_picker.dart';

class PaymentPeriodPickerBottomSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? now;

  const PaymentPeriodPickerBottomSheet({
    super.key,
    required this.initialDate,
    this.now,
  });

  @override
  State<PaymentPeriodPickerBottomSheet> createState() =>
      _PaymentPeriodPickerBottomSheetState();
}

class _PaymentPeriodPickerBottomSheetState
    extends State<PaymentPeriodPickerBottomSheet> {
  late final List<int> _years;
  late int _selectedYear;
  late int _selectedMonth;

  List<int> get _months => PaymentUtils.availablePaymentMonths(_selectedYear);

  @override
  void initState() {
    super.initState();
    _years = PaymentUtils.availablePaymentYears(now: widget.now);
    final initial = PaymentUtils.clampToSupportedPeriod(widget.initialDate);
    _selectedYear = initial.year.clamp(_years.first, _years.last);
    final months = PaymentUtils.availablePaymentMonths(_selectedYear);
    _selectedMonth = months.contains(initial.month)
        ? initial.month
        : months.first;
  }

  @override
  Widget build(BuildContext context) {
    final months = _months;
    final selectedYearIndex = _years.indexOf(_selectedYear);
    final selectedMonthIndex = months.indexOf(_selectedMonth);

    return AiwaBottomSheet(
      title: 'Pilih Periode Pembayaran',
      resetText: 'Batal',
      applyText: 'Tampilkan',
      resetColor: AppColors.textSecondary,
      onReset: () => Navigator.pop(context),
      onApply: () =>
          Navigator.pop(context, DateTime(_selectedYear, _selectedMonth)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pencatatan pembayaran tersedia mulai Februari 2026.',
                    style: TextStyle(
                      height: 1.35,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Bulan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  'Tahun',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 176,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AiwaWheelPicker<int>(
                    key: ValueKey('payment-month-$_selectedYear'),
                    initialItem: selectedMonthIndex,
                    items: months,
                    itemExtent: 42,
                    highlightColor: AppColors.primary.withValues(alpha: 0.1),
                    onSelectedItemChanged: (index) {
                      _selectedMonth = months[index];
                    },
                    itemBuilder: (month) => Text(
                      DateFormat('MMMM', 'id_ID').format(DateTime(2026, month)),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AiwaWheelPicker<int>(
                    initialItem: selectedYearIndex,
                    items: _years,
                    itemExtent: 42,
                    highlightColor: AppColors.primary.withValues(alpha: 0.1),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedYear = _years[index];
                        final availableMonths = _months;
                        if (!availableMonths.contains(_selectedMonth)) {
                          _selectedMonth = availableMonths.first;
                        }
                      });
                    },
                    itemBuilder: (year) => Text(
                      year.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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
}
