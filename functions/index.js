const {
  shouldDeployScheduledFunctions,
  shouldDeployLegacyHttpFunctions,
  shouldDeployNotificationFunctions,
  shouldDeployTranscriptionFunction,
} = require("./lib/deploymentConfig");
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
  checkKelulusanPhoto,
  reserveKelulusanPhoto,
  saveKelulusanPhoto,
} = require("./handlers/kelulusanSave");
const {
  provisionInstitutionUser,
} = require("./handlers/provisionInstitutionUser");
const {
  resetSantriPasswordFromBirthDate,
} = require("./handlers/resetSantriPasswordFromBirthDate");
const {
  getFamilyAccounts,
  switchFamilyAccount,
} = require("./handlers/familyAccounts");

// Konfigurasi checked-in dibaca juga saat discovery manifest (sebelum .env
// dimuat Firebase CLI), sehingga project baru tidak mendapat scheduler.
if (shouldDeployScheduledFunctions()) {
  const {
    scheduledAssessmentNotifications,
  } = require("./handlers/assessmentNotifier");
  const {
    scheduledPaymentNotifications,
  } = require("./handlers/paymentNotifier");
  const {
    cleanupExpiredSyahadah,
  } = require("./handlers/cleanupExpiredSyahadah");
  // #1 Penilaian bulanan: semua kondisi, tiap hari 19:30 WIB.
  exports.notifyAssessmentWindowOpen = scheduledAssessmentNotifications;

  // #2 Tugas pagi: SPP pukul 08:00, reminder bulanan tanggal 3 pukul 09:00 WIB.
  exports.notifyArrearsMonthEnd = scheduledPaymentNotifications;

  // #3 Pembersih foto kelulusan kedaluwarsa, tiap Senin 03:00 WIB.
  exports.cleanupExpiredSyahadah = cleanupExpiredSyahadah;
}

// Pendeteksi bacaan Quran (Fase 0): proxy transkripsi Groq Whisper.
// onCall, butuh login. Secret GROQ_API_KEY.
// Deployment parsial boleh melewati fungsi ini agar tidak memerlukan secret
// Groq milik fitur yang tidak ikut dirilis.
if (shouldDeployTranscriptionFunction()) {
  exports.transcribeRecitation =
    require("./handlers/transcribeRecitation").transcribeRecitation;
}

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

// Cek dan simpan poster secara idempoten per santri + tanggal WIB.
exports.checkKelulusanPhoto = checkKelulusanPhoto;
exports.reserveKelulusanPhoto = reserveKelulusanPhoto;
exports.saveKelulusanPhoto = saveKelulusanPhoto;

// Provisioning akun dan role hanya melalui server, khusus admin.
exports.provisionInstitutionUser = provisionInstitutionUser;
// Perubahan tanggal lahir mereset password santri tanpa mengirimkan password
// tersebut kembali ke perangkat admin.
exports.resetSantriPasswordFromBirthDate = resetSantriPasswordFromBirthDate;

// Monitoring dan pengiriman notifikasi pembayaran dapat dimatikan per project.
if (shouldDeployNotificationFunctions()) {
  const {
    getPaymentReminderSchedule,
    sendManualPaymentReminder,
    sendScheduledPaymentWhatsApp,
  } = require("./handlers/paymentReminderScheduler");
  exports.getPaymentReminderSchedule = getPaymentReminderSchedule;
  exports.sendManualPaymentReminder = sendManualPaymentReminder;
  exports.sendScheduledPaymentWhatsApp = sendScheduledPaymentWhatsApp;
}

// Daftar akun keluarga dan perpindahan sesi terverifikasi untuk santri.
exports.getFamilyAccounts = getFamilyAccounts;
exports.switchFamilyAccount = switchFamilyAccount;

// Endpoint rekonsiliasi MySQL dan guest web adalah kebutuhan migrasi sistem
// lama, bukan bagian aplikasi white-label. Default tidak diekspor agar project
// lembaga baru tidak meminta credential database/guest milik lembaga lain.
if (shouldDeployLegacyHttpFunctions()) {
  exports.compareSantri = require("./handlers/compareSantri").compareSantri;
  exports.checkBirthDates =
    require("./handlers/checkBirthDates").checkBirthDates;
  exports.resetSantriPasswords =
    require("./handlers/resetSantriPasswords").resetSantriPasswords;
  exports.importSantri = require("./handlers/importSantri").importSantri;
  // Jalankan setelah importSantri dan sebelum importMonthlyReports agar
  // penilaian hasil migrasi tertaut ke asatidz_id.
  exports.importAsatidz = require("./handlers/importAsatidz").importAsatidz;
  exports.importPayments =
    require("./handlers/importPayments").importPayments;
  exports.importMonthlyReports =
    require("./handlers/importMonthlyReports").importMonthlyReports;
  exports.migrateSantriFiqihClasses =
    require("./handlers/migrateSantriFiqihClasses").migrateSantriFiqihClasses;
  exports.groupPengajarSantri =
    require("./handlers/groupPengajarSantri").groupPengajarSantri;
  // Endpoint guest web memakai secret terpisah dan bukan kebutuhan import
  // MySQL. Aktifkan hanya pada project lama yang memang masih memakainya.
  if (process.env.DEPLOY_LEGACY_GUEST_LOOKUP === "true") {
    exports.guestLookup = require("./handlers/guestLookup").guestLookup;
  }
}
