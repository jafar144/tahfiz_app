const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const { SCHEDULE_OPTIONS } = require("../lib/config");
const { jakartaDateParts, monthNameId } = require("../lib/jakartaTime");
const { sendToRole, sendToUid } = require("../lib/messaging");
const { computeIncompleteAsatidz } = require("../lib/assessmentStatus");
const {
  ASSESSMENT_WINDOW_OPEN_DAYS_REMAINING,
  ASSESSMENT_LAST_DAYS_THRESHOLD,
  ASSESSMENT_JOBS,
  assessmentJobNames,
  runScheduledJobs,
} = require("../lib/notificationSchedule");

// Kedua kebutuhan penilaian berbagi satu scheduler dan dipilih berdasarkan
// posisi tanggal terhadap akhir bulan di zona Jakarta.

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
async function runIncomplete(parts = jakartaDateParts()) {
  const { month, year, daysRemaining } = parts;
  if (daysRemaining > ASSESSMENT_LAST_DAYS_THRESHOLD) {
    logger.info(`[incomplete] dilewati (sisa ${daysRemaining} hari).`);
    return { skipped: true };
  }

  const incomplete = await computeIncompleteAsatidz(month, year);
  if (!incomplete.length) {
    logger.info("[incomplete] semua asatidz sudah lengkap.");
    return { notified: 0 };
  }

  const namaBulan = monthNameId(month);
  let notified = 0;
  for (const a of incomplete) {
    await sendToUid(a.uid, {
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
  }

  logger.info(`[incomplete] mengingatkan ${notified} asatidz.`);
  return { notified };
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
  { ...SCHEDULE_OPTIONS, schedule: "30 19 * * *" },
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
