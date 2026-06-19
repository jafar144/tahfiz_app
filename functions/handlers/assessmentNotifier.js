const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const { SCHEDULE_OPTIONS } = require("../lib/config");
const { jakartaDateParts, monthNameId } = require("../lib/jakartaTime");
const { sendToRole, sendToUid } = require("../lib/messaging");
const { computeIncompleteAsatidz } = require("../lib/assessmentStatus");

// Hari (sisa) saat window penilaian dibuka. Konsisten dengan app:
// MonthlyReportCubit.checkIsInWindow → windowStart = lastDay - 6 hari,
// sehingga pada hari pembukaan daysRemaining == 6.
const WINDOW_OPEN_DAYS_REMAINING = 6;

// Dua hari terakhir bulan: daysRemaining 1 (sehari sebelum) & 0 (hari terakhir).
const LAST_DAYS_THRESHOLD = 1;

// --- Notif #1: pemberitahuan window penilaian dibuka (broadcast ke asatidz) ---
async function runWindowOpen(parts = jakartaDateParts()) {
  const { month, year, daysRemaining } = parts;
  if (daysRemaining !== WINDOW_OPEN_DAYS_REMAINING) {
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
  if (daysRemaining > LAST_DAYS_THRESHOLD) {
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

// Penjadwal: tiap hari 19:30 WIB. Fungsi memutuskan sendiri apakah hari ini
// perlu mengirim, berdasarkan posisi tanggal dalam bulan (zona Jakarta).
const notifyAssessmentWindowOpen = onSchedule(
  { ...SCHEDULE_OPTIONS, schedule: "30 19 * * *" },
  async () => {
    await runWindowOpen();
  }
);

const notifyIncompleteAssessment = onSchedule(
  { ...SCHEDULE_OPTIONS, schedule: "30 19 * * *" },
  async () => {
    await runIncomplete();
  }
);

module.exports = {
  notifyAssessmentWindowOpen,
  notifyIncompleteAssessment,
  // diekspor untuk pengujian manual
  runWindowOpen,
  runIncomplete,
};
