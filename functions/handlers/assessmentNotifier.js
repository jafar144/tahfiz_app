const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const { SCHEDULE_OPTIONS } = require("../lib/config");
const { jakartaDateParts, monthNameId } = require("../lib/jakartaTime");
const { previousMonthParts } = require("../lib/whatsappMessages");
const { sendToRole, sendToUid } = require("../lib/messaging");
const { computeIncompleteAsatidz } = require("../lib/assessmentStatus");
const {
  runIncompleteAssessmentWhatsApp,
} = require("./whatsappNotifier");
const {
  ASSESSMENT_WINDOW_OPEN_DAYS_REMAINING,
  ASSESSMENT_LAST_DAYS_THRESHOLD,
  ASSESSMENT_PREVIOUS_MONTH_REMINDER_DAYS,
  ASSESSMENT_JOBS,
  assessmentJobNames,
  runScheduledJobs,
} = require("../lib/notificationSchedule");

// Seluruh kebutuhan penilaian berbagi satu scheduler dan dipilih berdasarkan
// tanggal serta posisi terhadap akhir bulan di zona Jakarta.

// WABLAS_ENABLED dari .env.<project> baru diterapkan setelah manifest dibuat.
// Ikat secret tanpa kondisi agar tersedia ketika pengiriman runtime diaktifkan.
const wablasSecrets = Object.values(require("../lib/wablasSecrets"));
const ASSESSMENT_SCHEDULE_OPTIONS = {
  ...SCHEDULE_OPTIONS,
  schedule: "30 19 * * *",
  timeoutSeconds: 300,
  secrets: wablasSecrets,
};

// --- Notif #1: pemberitahuan window penilaian dibuka (broadcast ke asatidz) ---
async function runWindowOpen(parts = jakartaDateParts()) {
  const { month, year, daysRemaining } = parts;
  if (daysRemaining !== ASSESSMENT_WINDOW_OPEN_DAYS_REMAINING) {
    logger.info(`[windowOpen] dilewati (sisa ${daysRemaining} hari).`);
    return { skipped: true };
  }

  const namaBulan = monthNameId(month);
  const res = await sendToRole("asatidz", {
    title: "Penilaian Bulanan Dibuka",
    body: `Penilaian bulanan ${namaBulan} sudah bisa diisi. Yuk nilai santri Anda.`,
    data: {
      type: "monthly_assessment_open",
      bulan: month,
      tahun: year,
    },
  });

  logger.info(`[windowOpen] terkirim ${res.successCount}, gagal ${res.failureCount}.`);
  return res;
}

// --- Notif #2: pengingat penilaian belum lengkap (per asatidz) ---
async function runIncomplete(parts = jakartaDateParts(), options = {}) {
  const { month, year, daysRemaining } = parts;
  if (daysRemaining > ASSESSMENT_LAST_DAYS_THRESHOLD) {
    logger.info(`[incomplete] dilewati (sisa ${daysRemaining} hari).`);
    return { skipped: true };
  }

  const computeIncomplete =
    options.computeIncomplete || computeIncompleteAsatidz;
  const push = options.sendPush || sendToUid;
  const sendWhatsApp =
    options.sendWhatsApp || runIncompleteAssessmentWhatsApp;
  const incomplete = await computeIncomplete(month, year);
  if (!incomplete.length) {
    logger.info("[incomplete] semua asatidz sudah lengkap.");
    return {
      notified: 0,
      pushFailed: 0,
      whatsapp: { skipped: true, reason: "no_recipients" },
    };
  }

  const namaBulan = monthNameId(month);
  const pushDelivery = (async () => {
    let notified = 0;
    let pushFailed = 0;
    for (const a of incomplete) {
      try {
        await push(a.uid, {
          title: "Pengingat Penilaian Bulanan",
          body: `Masih ada ${a.count} santri yang belum dinilai bulan ${namaBulan}. Mohon dilengkapi sebelum akhir bulan.`,
          data: {
            type: "monthly_assessment_reminder",
            bulan: month,
            tahun: year,
            count: a.count,
          },
        });
        notified += 1;
      } catch (error) {
        pushFailed += 1;
        logger.error(
          `[incomplete] notifikasi HP ke ${a.uid} gagal: ${error.message}`,
        );
      }
    }
    return { notified, pushFailed };
  })();

  const whatsappDelivery = (async () => {
    try {
      return await sendWhatsApp(parts, incomplete);
    } catch (error) {
      logger.error(`[incomplete] pengiriman WhatsApp gagal: ${error.message}`);
      return {
        sent: 0,
        failed: incomplete.length,
        error: error.message,
      };
    }
  })();

  const [{ notified, pushFailed }, whatsapp] = await Promise.all([
    pushDelivery,
    whatsappDelivery,
  ]);

  logger.info(
    `[incomplete] notifikasi HP ke ${notified} asatidz, gagal ${pushFailed}; WhatsApp terkirim ${whatsapp.sent || 0}.`,
  );
  return { notified, pushFailed, whatsapp };
}

// --- Notif #3: susulan WA untuk penilaian bulan sebelumnya (tanggal 1 & 2) ---
async function runPreviousMonthIncomplete(
  parts = jakartaDateParts(),
  options = {},
) {
  if (!ASSESSMENT_PREVIOUS_MONTH_REMINDER_DAYS.includes(parts.day)) {
    logger.info(
      `[previousMonthIncomplete] dilewati (tanggal ${parts.day}).`,
    );
    return { skipped: true, reason: "not_reminder_day" };
  }

  const previous = previousMonthParts(parts);
  const assessmentParts = {
    day: parts.day,
    month: previous.month,
    year: previous.year,
  };
  const computeIncomplete =
    options.computeIncomplete || computeIncompleteAsatidz;
  const sendWhatsApp =
    options.sendWhatsApp || runIncompleteAssessmentWhatsApp;
  const incomplete = await computeIncomplete(previous.month, previous.year);

  if (!incomplete.length) {
    logger.info(
      `[previousMonthIncomplete] penilaian ${monthNameId(previous.month)} ${previous.year} sudah lengkap.`,
    );
    return {
      period: previous,
      eligible: 0,
      whatsapp: { skipped: true, reason: "no_recipients" },
    };
  }

  try {
    const whatsapp = await sendWhatsApp(assessmentParts, incomplete, {
      deliveryParts: parts,
    });
    logger.info(
      `[previousMonthIncomplete] ${incomplete.length} asatidz belum lengkap untuk ${monthNameId(previous.month)} ${previous.year}; WhatsApp terkirim ${whatsapp.sent || 0}.`,
    );
    return { period: previous, eligible: incomplete.length, whatsapp };
  } catch (error) {
    logger.error(
      `[previousMonthIncomplete] pengiriman WhatsApp gagal: ${error.message}`,
    );
    return {
      period: previous,
      eligible: incomplete.length,
      whatsapp: {
        sent: 0,
        failed: incomplete.length,
        error: error.message,
      },
    };
  }
}

async function runAssessmentNotifications(
  parts = jakartaDateParts(),
  runners = {
    [ASSESSMENT_JOBS.windowOpen]: runWindowOpen,
    [ASSESSMENT_JOBS.incomplete]: runIncomplete,
    [ASSESSMENT_JOBS.previousMonthIncomplete]: runPreviousMonthIncomplete,
  }
) {
  const jobNames = assessmentJobNames(parts);
  if (!jobNames.length) {
    logger.info(`[assessmentSchedule] tidak ada tugas pada tanggal ${parts.day}.`);
  }
  return runScheduledJobs(jobNames, runners, parts);
}

// Satu penjadwal harian 19:30 WIB menangani seluruh notifikasi penilaian.
const scheduledAssessmentNotifications = onSchedule(
  ASSESSMENT_SCHEDULE_OPTIONS,
  async (event) => {
    const scheduledAt = event?.scheduleTime
      ? new Date(event.scheduleTime)
      : new Date();
    await runAssessmentNotifications(jakartaDateParts(scheduledAt));
  }
);

module.exports = {
  scheduledAssessmentNotifications,
  runWindowOpen,
  runIncomplete,
  runPreviousMonthIncomplete,
  runAssessmentNotifications,
};
