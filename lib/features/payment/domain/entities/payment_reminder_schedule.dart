class PaymentReminderSchedule {
  final int firstDay;
  final int lastDay;
  final int minIntervalMinutes;
  final int maxIntervalMinutes;
  final int invalidPhoneCount;
  final int adminFallbackCount;
  final List<PaymentReminderScheduleItem> items;

  const PaymentReminderSchedule({
    required this.firstDay,
    required this.lastDay,
    required this.minIntervalMinutes,
    required this.maxIntervalMinutes,
    required this.invalidPhoneCount,
    required this.adminFallbackCount,
    required this.items,
  });
}

class PaymentReminderScheduleItem {
  final String santriId;
  final String santriName;
  final String type;
  final DateTime scheduledAt;
  final int intervalMinutes;

  const PaymentReminderScheduleItem({
    required this.santriId,
    required this.santriName,
    required this.type,
    required this.scheduledAt,
    required this.intervalMinutes,
  });

  String get typeLabel => switch (type) {
    'two-month-arrears' => 'Tunggakan 2 bulan',
    'arrears' => 'Tunggakan 3+ periode',
    _ => 'Tagihan bulan berjalan',
  };
}
