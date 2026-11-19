import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_chip.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_search.dart';
import 'package:khoirunnasyien/features/payment/data/payment_scheduling_service.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_reminder_schedule.dart';
import 'package:khoirunnasyien/features/payment/presentation/widgets/payment_period_picker_bottom_sheet.dart';

class PaymentSchedulingPage extends StatefulWidget {
  final PaymentSchedulingService? service;
  final DateTime? initialPeriod;
  const PaymentSchedulingPage({super.key, this.service, this.initialPeriod});

  @override
  State<PaymentSchedulingPage> createState() => _PaymentSchedulingPageState();
}

class _PaymentSchedulingPageState extends State<PaymentSchedulingPage> {
  late final PaymentSchedulingService _service;
  late DateTime _period;
  final _search = TextEditingController();
  PaymentReminderSchedule? _schedule;
  String? _error;
  bool _loading = true;
  String _filter = 'Semua';
  String? _sending;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _service =
        widget.service ??
        FirebasePaymentSchedulingService(getIt<FirebaseFunctions>());
    final now = PaymentReminderScheduleItem.wib(DateTime.now());
    _period = widget.initialPeriod ?? DateTime(now.year, now.month);
    _search.addListener(_onSearch);
    _load();
  }

  void _onSearch() => setState(() {});

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.load(_period);
      if (mounted && request == _request) setState(() => _schedule = result);
    } catch (error) {
      if (mounted && request == _request) {
        setState(() => _error = ErrorHandler.getMessage(error));
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _pickPeriod() async {
    final date = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentPeriodPickerBottomSheet(initialDate: _period),
    );
    if (date == null || !mounted) return;
    setState(() {
      _period = date;
      _schedule = null;
    });
    await _load();
  }

  String _time(DateTime date) =>
      '${DateFormat('d MMM, HH:mm', 'id_ID').format(PaymentReminderScheduleItem.wib(date))} WIB';

  Future<void> _send(PaymentReminderScheduleItem item) async {
    final period = _period;
    final confirmed = await showAiwaActionSheet<bool>(
      context: context,
      title: 'Kirim pengingat pembayaran?',
      content: Text(
        'Pengingat untuk ${item.santriName}, periode '
        '${DateFormat('MMMM yyyy', 'id_ID').format(period)}, akan masuk antrean '
        '08.00–15.00 WIB dengan jeda 1–15 menit. Jika waktu hari ini habis, '
        'pengiriman dilanjutkan besok. Kanal yang sudah berhasil tidak dikirim ulang.',
      ),
      confirmText: 'Jadwalkan',
      confirmValue: true,
      cancelValue: false,
    );
    if (confirmed != true || !mounted || _sending != null) return;
    setState(() => _sending = item.santriId);
    try {
      final scheduled = await _service.send(period, item.santriId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            scheduled == null
                ? 'Pengiriman sudah selesai atau sedang diproses.'
                : 'Dijadwalkan ${_time(scheduled)}.',
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorHandler.getMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _sending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _schedule;
    final items = (schedule?.items ?? []).where((item) {
      final matches = item.santriName.toLowerCase().contains(
        _search.text.trim().toLowerCase(),
      );
      return matches &&
          switch (_filter) {
            'Belum terkirim' => !item.isComplete,
            'Sudah terkirim' => item.isComplete,
            _ => true,
          };
    }).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AiwaAppBar(
        title: 'Penjadwalan Pembayaran',
        actions: [
          IconButton(
            tooltip: 'Perbarui status',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            InkWell(
              onTap: _sending == null ? _pickPeriod : null,
              borderRadius: BorderRadius.circular(16),
              child: _surface(
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Periode pembayaran',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            DateFormat('MMMM yyyy', 'id_ID').format(_period),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _surface(
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mulai tanggal 25 • 08.00–15.00 WIB',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Jeda acak 1–15 menit. Waktu hari ini diisi hingga habis, lalu sisa pengingat dilanjutkan besok.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Hanya santri yang masih menunggak sampai periode pilihan. '
                    'Pilih bulan sebelumnya untuk mengirim susulan di awal bulan.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              color: const Color(0xFFEFF6FF),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _surface(
                Column(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              )
            else if (schedule != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _summary(
                      'Belum terkirim',
                      schedule.pendingCount,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summary(
                      'Sudah terkirim',
                      schedule.sentCount,
                      AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AiwaSearch(
                controller: _search,
                hintText: 'Cari nama santri',
                onSearch: _onSearch,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: ['Semua', 'Belum terkirim', 'Sudah terkirim']
                    .map(
                      (label) => AiwaChoiceChip(
                        label: label,
                        isSelected: _filter == label,
                        onTap: () => setState(() => _filter = label),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              const Text(
                'Status WhatsApp menunjukkan pesan diterima layanan pengiriman; '
                'belum memastikan pesan diterima atau dibaca wali. Tarik ke bawah untuk memperbarui.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.task_alt_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        schedule.items.isEmpty
                            ? 'Tidak ada tunggakan pada periode ini.'
                            : 'Tidak ada santri pada filter ini.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              for (final group in [1, 2, 3])
                if (items.any((item) => item.group == group)) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 10),
                    child: Text(
                      'Tunggakan ${group == 3 ? '3 bulan atau lebih' : '$group bulan'} '
                      '(${items.where((item) => item.group == group).length})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ...items.where((item) => item.group == group).map(_recipient),
                ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _surface(Widget child, {Color color = Colors.white}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  Widget _summary(String label, int count, Color color) => _surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    ),
  );

  Widget _recipient(PaymentReminderScheduleItem item) {
    final statusColor = item.isComplete
        ? AppColors.success
        : ['failed', 'blocked'].contains(item.status)
        ? AppColors.error
        : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _surface(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.santriName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            if (item.months.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  item.months
                      .map(
                        (month) =>
                            DateFormat('MMM yyyy', 'id_ID').format(month),
                      )
                      .join(', '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            _channel(
              Icons.chat_bubble_outline_rounded,
              'WhatsApp: ${item.whatsappLabel}',
            ),
            const SizedBox(height: 5),
            _channel(
              Icons.notifications_none_rounded,
              'Aplikasi: ${item.appLabel}',
            ),
            if (item.sentAt != null || item.scheduledAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  item.sentAt != null
                      ? 'Dikirim ${_time(item.sentAt!)}'
                      : '${item.estimated ? 'Perkiraan' : 'Jadwal'} ${_time(item.scheduledAt!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (item.canSend)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: ValueKey('send-${item.santriId}'),
                  onPressed: _sending == null ? () => _send(item) : null,
                  icon: _sending == item.santriId
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 17),
                  label: Text(
                    item.whatsappStatus == 'sent'
                        ? 'Lanjutkan pengiriman'
                        : 'Kirim manual',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _channel(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: const TextStyle(fontSize: 12, height: 1.4)),
      ),
    ],
  );
}
