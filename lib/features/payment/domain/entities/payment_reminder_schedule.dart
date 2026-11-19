class PaymentReminderSchedule {
  final int firstDay;
  final int lastDay;
  final int minIntervalMinutes;
  final int maxIntervalMinutes;
  final int invalidPhoneCount;
  final int adminFallbackCount;
  final List<PaymentReminderScheduleItem> items;

  int get sentCount => items.where((item) => item.isComplete).length;
  int get pendingCount => items.length - sentCount;

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
  final DateTime? scheduledAt;
  final int intervalMinutes;
  final int arrearsCount;
  final List<DateTime> months;
  final String status;
  final String whatsappStatus;
  final String appStatus;
  final bool adminFallback;
  final bool estimated;
  final bool canSend;
  final DateTime? sentAt;
  final int attempts;

  const PaymentReminderScheduleItem({
    required this.santriId,
    required this.santriName,
    required this.type,
    required this.scheduledAt,
    required this.intervalMinutes,
    this.arrearsCount = 1,
    this.months = const [],
    this.status = 'pending',
    this.whatsappStatus = 'pending',
    this.appStatus = 'pending',
    this.adminFallback = false,
    this.estimated = true,
    this.canSend = false,
    this.sentAt,
    this.attempts = 0,
  });

  bool get isComplete => status == 'sent' && !adminFallback;
  int get group => arrearsCount >= 3 ? 3 : arrearsCount;
  String get groupLabel => group == 3 ? '3 bulan atau lebih' : '$group bulan';

  String get statusLabel => switch (status) {
    'sent' => adminFallback ? 'Dialihkan ke admin' : 'Sudah terkirim',
    'queued' => 'Terjadwal',
    'sending' => 'Sedang dikirim',
    'retrying' => 'Mencoba ulang',
    'failed' => 'Gagal dikirim',
    'blocked' => 'Perlu diperiksa',
    _ => 'Belum dikirim',
  };

  String get whatsappLabel => switch (whatsappStatus) {
    'sent' => adminFallback ? 'Dialihkan ke admin' : 'Diterima layanan WA',
    'failed' => 'Gagal',
    'invalid-phone' => 'Nomor wali tidak valid',
    'disabled' => 'Layanan nonaktif',
    _ => 'Belum dikirim',
  };

  String get appLabel => switch (appStatus) {
    'sent' => 'Terkirim',
    'partial' => 'Terkirim ke sebagian perangkat',
    'no-device' => 'Tidak ada perangkat terdaftar',
    'failed' => 'Gagal',
    _ => 'Belum dikirim',
  };

  static DateTime wib(DateTime date) =>
      date.toUtc().add(const Duration(hours: 7));

  String get typeLabel => switch (type) {
    'two-month-arrears' => 'Tunggakan 2 bulan',
    'arrears' => 'Tunggakan 3+ periode',
    _ => 'Tagihan bulan berjalan',
  };
}
