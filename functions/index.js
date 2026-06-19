const { compareSantri } = require("./handlers/compareSantri");
const { importSantri } = require("./handlers/importSantri");
const { importPayments } = require("./handlers/importPayments");
const { importMonthlyReports } = require("./handlers/importMonthlyReports");
const {
  notifyAssessmentWindowOpen,
  notifyIncompleteAssessment,
} = require("./handlers/assessmentNotifier");

exports.compareSantri = compareSantri;
exports.importSantri = importSantri;
exports.importPayments = importPayments;
exports.importMonthlyReports = importMonthlyReports;

// Notifikasi penilaian bulanan (penjadwal harian 19:30 WIB).
exports.notifyAssessmentWindowOpen = notifyAssessmentWindowOpen;
exports.notifyIncompleteAssessment = notifyIncompleteAssessment;
