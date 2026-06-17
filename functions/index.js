const { compareSantri } = require("./handlers/compareSantri");
const { importSantri } = require("./handlers/importSantri");
const { importPayments } = require("./handlers/importPayments");
const { importMonthlyReports } = require("./handlers/importMonthlyReports");

exports.compareSantri = compareSantri;
exports.importSantri = importSantri;
exports.importPayments = importPayments;
exports.importMonthlyReports = importMonthlyReports;
