const { compareSantri } = require("./handlers/compareSantri");
const { checkBirthDates } = require("./handlers/checkBirthDates");
const { resetSantriPasswords } = require("./handlers/resetSantriPasswords");
const { importSantri } = require("./handlers/importSantri");
const { importPayments } = require("./handlers/importPayments");
const { importMonthlyReports } = require("./handlers/importMonthlyReports");
const { groupPengajarSantri } = require("./handlers/groupPengajarSantri");
const {
  notifyAssessmentWindowOpen,
  notifyIncompleteAssessment,
} = require("./handlers/assessmentNotifier");
const {
  notifyPaymentDue,
  notifyArrearsMidMonth,
  notifyArrearsMonthEnd,
} = require("./handlers/paymentNotifier");
const {
  cleanupExpiredSyahadah,
} = require("./handlers/cleanupExpiredSyahadah");
const { guestLookup } = require("./handlers/guestLookup");
const { transcribeRecitation } = require("./handlers/transcribeRecitation");

exports.compareSantri = compareSantri;
exports.checkBirthDates = checkBirthDates;
exports.resetSantriPasswords = resetSantriPasswords;
exports.importSantri = importSantri;
exports.importPayments = importPayments;
exports.importMonthlyReports = importMonthlyReports;
exports.groupPengajarSantri = groupPengajarSantri;

// Notifikasi penilaian bulanan (penjadwal harian 19:30 WIB).
exports.notifyAssessmentWindowOpen = notifyAssessmentWindowOpen;
exports.notifyIncompleteAssessment = notifyIncompleteAssessment;

// Notifikasi SPP santri reguler (penjadwal 08:00 WIB):
// tgl 5 ajakan bayar, tgl 15 & 3 hari sebelum akhir bulan pengingat tunggakan.
exports.notifyPaymentDue = notifyPaymentDue;
exports.notifyArrearsMidMonth = notifyArrearsMidMonth;
exports.notifyArrearsMonthEnd = notifyArrearsMonthEnd;

// Pembersih foto kelulusan kedaluwarsa (>7 hari), jalan tiap Senin 03:00 WIB.
exports.cleanupExpiredSyahadah = cleanupExpiredSyahadah;

// Endpoint guest web (read-only): cek pembayaran & penilaian terakhir by NIS.
// Dilindungi header x-api-key (secret GUEST_API_KEY). Dipakai web cPanel
// sementara sampai web pensiun (September 2026).
exports.guestLookup = guestLookup;

// Pendeteksi bacaan Quran (Fase 0): proxy transkripsi Groq Whisper.
// onCall, butuh login. Secret GROQ_API_KEY.
exports.transcribeRecitation = transcribeRecitation;
