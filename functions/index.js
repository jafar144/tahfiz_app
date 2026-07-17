const { compareSantri } = require("./handlers/compareSantri");
const { checkBirthDates } = require("./handlers/checkBirthDates");
const { resetSantriPasswords } = require("./handlers/resetSantriPasswords");
const { importSantri } = require("./handlers/importSantri");
const { importPayments } = require("./handlers/importPayments");
const { importMonthlyReports } = require("./handlers/importMonthlyReports");
const {
  migrateSantriFiqihClasses,
} = require("./handlers/migrateSantriFiqihClasses");
const { groupPengajarSantri } = require("./handlers/groupPengajarSantri");
const {
  scheduledAssessmentNotifications,
} = require("./handlers/assessmentNotifier");
const {
  scheduledPaymentNotifications,
} = require("./handlers/paymentNotifier");
const { cleanupExpiredSyahadah } = require("./handlers/cleanupExpiredSyahadah");
const { guestLookup } = require("./handlers/guestLookup");
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

exports.compareSantri = compareSantri;
exports.checkBirthDates = checkBirthDates;
exports.resetSantriPasswords = resetSantriPasswords;
exports.importSantri = importSantri;
exports.importPayments = importPayments;
exports.importMonthlyReports = importMonthlyReports;
exports.migrateSantriFiqihClasses = migrateSantriFiqihClasses;
exports.groupPengajarSantri = groupPengajarSantri;

// Hanya tiga export scheduler. Nama dua export lama dipertahankan agar deploy
// memperbarui fungsi yang sudah ada, bukan membuat scheduler tambahan.

// #1 Penilaian bulanan: semua kondisi, tiap hari 19:30 WIB.
exports.notifyAssessmentWindowOpen = scheduledAssessmentNotifications;

// #2 SPP: semua kondisi tanggal, tiap hari 08:00 WIB.
exports.notifyArrearsMonthEnd = scheduledPaymentNotifications;

// #3 Pembersih foto kelulusan kedaluwarsa, tiap Senin 03:00 WIB.
exports.cleanupExpiredSyahadah = cleanupExpiredSyahadah;

// Endpoint guest web (read-only): cek pembayaran & penilaian terakhir by NIS.
// Dilindungi header x-api-key (secret GUEST_API_KEY). Dipakai web cPanel
// sementara sampai web pensiun (September 2026).
exports.guestLookup = guestLookup;

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
