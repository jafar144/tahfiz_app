const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const { SCHEDULE_OPTIONS } = require("../lib/config");
const {
  jakartaDateParts,
  jakartaDateTimeParts,
  monthNameId,
} = require("../lib/jakartaTime");
const { sendToUid } = require("../lib/messaging");
const { fetchPayingSantri, computeUnpaidSantri } = require("../lib/paymentStatus");
const {
  runMonthlyAssessmentReminder,
} = require("./monthlyGroupNotifier");
const {
  runWhatsAppArrears,
  runBirthdayWhatsApp,
} = require("./whatsappNotifier");
const {
  PAYMENT_DUE_DAY,
  ARREARS_MID_DAY,
  ARREARS_MONTH_END_DAYS_REMAINING,
  PAYMENT_JOBS,
  paymentJobNames,
  runScheduledJobs,
} = require("../lib/notificationSchedule");

// Ketiga kebutuhan pembayaran berbagi satu scheduler harian dan dipilih dari
// tanggal Jakarta sebelum query Firestore dijalankan.

// Reads penuh (santri_profiles + payments) butuh kelonggaran timeout.
const wablasEnabledAtDeploy = ["1", "true", "yes", "on"].includes(
  String(process.env.WABLAS_ENABLED || "").trim().toLowerCase()
);
const wablasSecrets = wablasEnabledAtDeploy
  ? Object.values(require("../lib/wablasSecrets"))
  : [];

const PAYMENT_SCHEDULE_OPTIONS = {
  ...SCHEDULE_OPTIONS,
  timeoutSeconds: 300,
  secrets: wablasSecrets,
};

const MORNING_NOTIFICATION_JOBS = Object.freeze({
  payment: "payment",
  monthlyAssessment: "monthlyAssessment",
});

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
async function sendArrearsReminders(parts, { sendWhatsApp = false } = {}) {
  const unpaid = await computeUnpaidSantri(parts);
  if (!unpaid.length) {
    logger.info("[arrears] tidak ada santri menunggak.");
    return {
      notified: 0,
      whatsapp: sendWhatsApp
        ? await runWhatsAppArrears(parts, [])
        : { skipped: true },
    };
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
  const whatsapp = sendWhatsApp
    ? await runWhatsAppArrears(parts, unpaid)
    : { skipped: true };
  return { notified, whatsapp };
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
  if (parts.daysRemaining !== ARREARS_MONTH_END_DAYS_REMAINING) {
    logger.info(`[arrearsEnd] dilewati (sisa ${parts.daysRemaining} hari).`);
    return { skipped: true };
  }
  return sendArrearsReminders(parts, { sendWhatsApp: true });
}

async function runPaymentNotifications(
  parts = jakartaDateParts(),
  runners = {
    [PAYMENT_JOBS.paymentDue]: runPaymentDue,
    [PAYMENT_JOBS.arrearsMidMonth]: runArrearsMidMonth,
    [PAYMENT_JOBS.arrearsMonthEnd]: runArrearsMonthEnd,
    [PAYMENT_JOBS.birthdayWhatsApp]: runBirthdayWhatsApp,
  }
) {
  const jobNames = paymentJobNames(parts);
  if (!jobNames.length) {
    logger.info(`[paymentSchedule] tidak ada tugas pada tanggal ${parts.day}.`);
  }
  return runScheduledJobs(jobNames, runners, parts);
}

function morningNotificationJobNames(parts) {
  if (parts.hour === 8) {
    return [MORNING_NOTIFICATION_JOBS.payment];
  }
  if (parts.hour === 9 && parts.day === 3) {
    return [MORNING_NOTIFICATION_JOBS.monthlyAssessment];
  }
  return [];
}

async function runMorningNotifications(
  parts = jakartaDateTimeParts(),
  runners = {
    [MORNING_NOTIFICATION_JOBS.payment]: runPaymentNotifications,
    [MORNING_NOTIFICATION_JOBS.monthlyAssessment]:
      runMonthlyAssessmentReminder,
  },
) {
  const jobNames = morningNotificationJobNames(parts);
  if (!jobNames.length) {
    logger.info(
      `[morningSchedule] tidak ada tugas pukul ${parts.hour}:${String(
        parts.minute,
      ).padStart(2, "0")} tanggal ${parts.day}.`,
    );
  }
  return runScheduledJobs(jobNames, runners, parts);
}

// Satu Cloud Scheduler dipakai bersama: pembayaran tetap pukul 08:00 WIB,
// sedangkan penilaian + target hanya tanggal 3 pukul 09:00 WIB.
const scheduledPaymentNotifications = onSchedule(
  { ...PAYMENT_SCHEDULE_OPTIONS, schedule: "0 8,9 * * *" },
  async (event) => {
    const scheduledAt = event?.scheduleTime
      ? new Date(event.scheduleTime)
      : new Date();
    await runMorningNotifications(jakartaDateTimeParts(scheduledAt));
  }
);

module.exports = {
  MORNING_NOTIFICATION_JOBS,
  scheduledPaymentNotifications,
  runPaymentDue,
  runArrearsMidMonth,
  runArrearsMonthEnd,
  runBirthdayWhatsApp,
  runPaymentNotifications,
  morningNotificationJobNames,
  runMorningNotifications,
};
