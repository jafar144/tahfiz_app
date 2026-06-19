const { defineString, defineSecret } = require("firebase-functions/params");

const DB_HOST = defineString("DB_HOST");
const DB_PORT = defineString("DB_PORT", { default: "3306" });
const DB_USER = defineString("DB_USER");
const DB_NAME = defineString("DB_NAME");
const DB_PASSWORD = defineSecret("DB_PASSWORD");

const FUNCTION_OPTIONS = {
  region: "asia-southeast2",
  timeoutSeconds: 540,
  memory: "512MiB",
  secrets: [DB_PASSWORD],
};

// Opsi dasar untuk fungsi terjadwal (tanpa secret DB). Jadwal & timeZone
// ditentukan per-fungsi di handler-nya.
const SCHEDULE_OPTIONS = {
  region: "asia-southeast2",
  timeZone: "Asia/Jakarta",
  memory: "256MiB",
};

module.exports = {
  DB_HOST,
  DB_PORT,
  DB_USER,
  DB_NAME,
  DB_PASSWORD,
  FUNCTION_OPTIONS,
  SCHEDULE_OPTIONS,
};
