const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const { SCHEDULE_OPTIONS } = require("../lib/config");
const { jakartaDateParts, monthNameId } = require("../lib/jakartaTime");
const { sendToRole, sendToUid } = require("../lib/messaging");
const { computeIncompleteAsatidz } = require("../lib/assessmentStatus");
const {
  runIncompleteAssessmentWhatsApp,
} = require("./whatsappNotifier");
const {
  ASSESSMENT_WINDOW_OPEN_DAYS_REMAINING,
  ASSESSMENT_LAST_DAYS_THRESHOLD,
  ASSESSMENT_JOBS,
  assessmentJobNames,
  runScheduledJobs,
} = require("../lib/notificationSchedule");

// Kedua kebutuhan penilaian berbagi satu scheduler dan dipilih berdasarkan
// posisi tanggal terhadap akhir bulan di zona Jakarta.

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

async function runAssessmentNotifications(
  parts = jakartaDateParts(),
  runners = {
    [ASSESSMENT_JOBS.windowOpen]: runWindowOpen,
    [ASSESSMENT_JOBS.incomplete]: runIncomplete,
  }
) {
  const jobNames = assessmentJobNames(parts);
  if (!jobNames.length) {
    logger.info(`[assessmentSchedule] tidak ada tugas pada tanggal ${parts.day}.`);
  }
  return runScheduledJobs(jobNames, runners, parts);
}

// Satu penjadwal harian 19:30 WIB menangani kedua notifikasi penilaian.
const scheduledAssessmentNotifications = onSchedule(
  ASSESSMENT_SCHEDULE_OPTIONS,
  async () => {
    await runAssessmentNotifications();
  }
);

module.exports = {
  scheduledAssessmentNotifications,
  runWindowOpen,
  runIncomplete,
  runAssessmentNotifications,
};
