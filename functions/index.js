const {
  scheduledAssessmentNotifications,
} = require("./handlers/assessmentNotifier");
const {
  scheduledPaymentNotifications,
} = require("./handlers/paymentNotifier");
const { cleanupExpiredSyahadah } = require("./handlers/cleanupExpiredSyahadah");
const { transcribeRecitation } = require("./handlers/transcribeRecitation");
const {
  getQuizEnergy,
  startQuizSession,
  heartbeatQuizSession,
  endQuizSession,
  grantQuizEnergy,
} = require("./handlers/quizEnergy");
const { setAppFeatureConfig } = require("./handlers/appConfig");
const { deleteKelulusanPhoto } = require("./handlers/kelulusanAdmin");
const {
  provisionInstitutionUser,
} = require("./handlers/provisionInstitutionUser");

// Hanya tiga export scheduler. Nama dua export lama dipertahankan agar deploy
// memperbarui fungsi yang sudah ada, bukan membuat scheduler tambahan.

// #1 Penilaian bulanan: semua kondisi, tiap hari 19:30 WIB.
exports.notifyAssessmentWindowOpen = scheduledAssessmentNotifications;

// #2 SPP: semua kondisi tanggal, tiap hari 08:00 WIB.
exports.notifyArrearsMonthEnd = scheduledPaymentNotifications;

// #3 Pembersih foto kelulusan kedaluwarsa, tiap Senin 03:00 WIB.
exports.cleanupExpiredSyahadah = cleanupExpiredSyahadah;

// Pendeteksi bacaan Quran (Fase 0): proxy transkripsi Groq Whisper.
// onCall, butuh login. Secret GROQ_API_KEY.
exports.transcribeRecitation = transcribeRecitation;

// Energi Kuis Hafalan (server-side, anti ubah-jam). onCall, butuh login.
// KUOTA MINGGUAN tanpa cron: dokumen per-minggu quiz_energy_weeks/{uid}_{senin};
// minggu baru = dokumen baru = kuota penuh kembali (reset Senin 00:00 WIB).
exports.getQuizEnergy = getQuizEnergy;
// Sesi kuis 1-user-pada-satu-waktu (lock + lease/heartbeat) + potong kuota.
exports.startQuizSession = startQuizSession;
exports.heartbeatQuizSession = heartbeatQuizSession;
exports.endQuizSession = endQuizSession;
// Admin/asatidz memberi energi tambahan minggu berjalan ke santri.
exports.grantQuizEnergy = grantQuizEnergy;

// App Config runtime. Penulisan hanya diizinkan untuk admin oleh handler.
exports.setAppFeatureConfig = setAppFeatureConfig;

// Hapus poster kelulusan dan record Home Santri (khusus admin).
exports.deleteKelulusanPhoto = deleteKelulusanPhoto;

// Provisioning akun dan role hanya melalui server, khusus admin.
exports.provisionInstitutionUser = provisionInstitutionUser;

// Endpoint rekonsiliasi MySQL dan guest web adalah kebutuhan migrasi sistem
// lama, bukan bagian aplikasi white-label. Default tidak diekspor agar project
// lembaga baru tidak meminta credential database/guest milik lembaga lain.
if (process.env.DEPLOY_LEGACY_HTTP_FUNCTIONS === "true") {
  exports.compareSantri = require("./handlers/compareSantri").compareSantri;
  exports.checkBirthDates =
    require("./handlers/checkBirthDates").checkBirthDates;
  exports.resetSantriPasswords =
    require("./handlers/resetSantriPasswords").resetSantriPasswords;
  exports.importSantri = require("./handlers/importSantri").importSantri;
  exports.importPayments =
    require("./handlers/importPayments").importPayments;
  exports.importMonthlyReports =
    require("./handlers/importMonthlyReports").importMonthlyReports;
  exports.migrateSantriFiqihClasses =
    require("./handlers/migrateSantriFiqihClasses").migrateSantriFiqihClasses;
  exports.groupPengajarSantri =
    require("./handlers/groupPengajarSantri").groupPengajarSantri;
  exports.guestLookup = require("./handlers/guestLookup").guestLookup;
}
