const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const { SCHEDULE_OPTIONS } = require("../lib/config");
const { jakartaDateParts, monthNameId } = require("../lib/jakartaTime");
const { sendToUid } = require("../lib/messaging");
const { fetchPayingSantri, computeUnpaidSantri } = require("../lib/paymentStatus");

// Notif #1: tiap tanggal 5 → ajakan bayar SPP bulan ini.
const PAYMENT_DUE_DAY = 5;
// Notif #2: tiap tanggal 15 → pengingat tunggakan.
const ARREARS_MID_DAY = 15;
// Notif #3: 3 hari sebelum akhir bulan (daysRemaining == 3) → pengingat tunggakan.
const MONTH_END_DAYS_REMAINING = 3;

// Reads penuh (santri_profiles + payments) butuh kelonggaran timeout.
const PAYMENT_SCHEDULE_OPTIONS = { ...SCHEDULE_OPTIONS, timeoutSeconds: 300 };

// Susun teks daftar bulan tunggakan, dipadatkan bila banyak.
function formatArrearsList(months) {
  const labels = months.map((m) => `${monthNameId(m.month)} ${m.year}`);
  if (labels.length <= 4) return labels.join(", ");
  return `${labels.slice(0, 3).join(", ")}, dan ${labels.length - 3} bulan lainnya`;
}

// --- Notif #1: pemberitahuan pembayaran SPP bulan berjalan (per santri) ---
async function runPaymentDue(parts = jakartaDateParts()) {
  const { day, month, year } = parts;
  if (day !== PAYMENT_DUE_DAY) {
    logger.info(`[paymentDue] dilewati (tanggal ${day}, bukan ${PAYMENT_DUE_DAY}).`);
    return { skipped: true };
  }

  const santri = await fetchPayingSantri();
  const namaBulan = monthNameId(month);
  let notified = 0;
  for (const s of santri) {
    await sendToUid(s.uid, {
      title: `Pembayaran SPP ${namaBulan}`,
      body: `Pembayaran SPP bulan ${namaBulan} ${year} sudah dapat ditunaikan. Abaikan pesan ini jika sudah membayar.`,
      data: { type: "payment_due", bulan: month, tahun: year },
    });
    notified += 1;
  }

  logger.info(`[paymentDue] mengingatkan ${notified} santri reguler aktif.`);
  return { notified };
}

// --- Notif #2 & #3: pengingat tunggakan SPP (per santri) ---
async function sendArrearsReminders(parts) {
  const unpaid = await computeUnpaidSantri(parts);
  if (!unpaid.length) {
    logger.info("[arrears] tidak ada santri menunggak.");
    return { notified: 0 };
  }

  let notified = 0;
  for (const s of unpaid) {
    const body =
      s.count === 1
        ? `Pembayaran SPP bulan ${formatArrearsList(s.months)} belum kami terima. Mohon segera melakukan pembayaran.`
        : `Anda memiliki tunggakan SPP ${s.count} bulan: ${formatArrearsList(s.months)}. Mohon segera melakukan pembayaran.`;
    await sendToUid(s.uid, {
      title: "Pengingat Pembayaran SPP",
      body,
      data: { type: "payment_arrears", count: s.count, bulan: parts.month, tahun: parts.year },
    });
    notified += 1;
  }

  logger.info(`[arrears] mengingatkan ${notified} santri menunggak.`);
  return { notified };
}

// Tanggal 15: jalankan pengingat tunggakan.
async function runArrearsMidMonth(parts = jakartaDateParts()) {
  if (parts.day !== ARREARS_MID_DAY) {
    logger.info(`[arrearsMid] dilewati (tanggal ${parts.day}, bukan ${ARREARS_MID_DAY}).`);
    return { skipped: true };
  }
  return sendArrearsReminders(parts);
}

// 3 hari sebelum akhir bulan: jalankan pengingat tunggakan.
async function runArrearsMonthEnd(parts = jakartaDateParts()) {
  if (parts.daysRemaining !== MONTH_END_DAYS_REMAINING) {
    logger.info(`[arrearsEnd] dilewati (sisa ${parts.daysRemaining} hari).`);
    return { skipped: true };
  }
  return sendArrearsReminders(parts);
}

// Penjadwal (zona Jakarta, 08:00 WIB). Tanggal tetap (5, 15) pakai cron langsung;
// akhir bulan dievaluasi harian karena tanggalnya bergeser tiap bulan.
const notifyPaymentDue = onSchedule(
  { ...PAYMENT_SCHEDULE_OPTIONS, schedule: "0 8 5 * *" },
  async () => {
    await runPaymentDue();
  }
);

const notifyArrearsMidMonth = onSchedule(
  { ...PAYMENT_SCHEDULE_OPTIONS, schedule: "0 8 15 * *" },
  async () => {
    await runArrearsMidMonth();
  }
);

const notifyArrearsMonthEnd = onSchedule(
  { ...PAYMENT_SCHEDULE_OPTIONS, schedule: "0 8 * * *" },
  async () => {
    await runArrearsMonthEnd();
  }
);

module.exports = {
  notifyPaymentDue,
  notifyArrearsMidMonth,
  notifyArrearsMonthEnd,
  // diekspor untuk pengujian manual
  runPaymentDue,
  runArrearsMidMonth,
  runArrearsMonthEnd,
};
