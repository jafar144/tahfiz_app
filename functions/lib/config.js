const { defineString, defineSecret } = require("firebase-functions/params");

const DB_HOST = defineString("DB_HOST");
const DB_PORT = defineString("DB_PORT", { default: "3306" });
const DB_USER = defineString("DB_USER");
const DB_NAME = defineString("DB_NAME");
const DB_PASSWORD = defineSecret("DB_PASSWORD");
const AUTH_EMAIL_DOMAIN = defineString("AUTH_EMAIL_DOMAIN", {
  default: "khoirunnasyien.app",
});
const WABLAS_BASE_URL = defineString("WABLAS_BASE_URL");
const WABLAS_ENABLED = defineString("WABLAS_ENABLED", { default: "false" });
const WHATSAPP_ADMIN_PHONE = defineString("WHATSAPP_ADMIN_PHONE", {
  default: "6289679479654",
});
const WABLAS_TOKEN = defineSecret("WABLAS_TOKEN");
const WABLAS_SECRET_KEY = defineSecret("WABLAS_SECRET_KEY");

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
  AUTH_EMAIL_DOMAIN,
  WABLAS_BASE_URL,
  WABLAS_ENABLED,
  WHATSAPP_ADMIN_PHONE,
  WABLAS_TOKEN,
  WABLAS_SECRET_KEY,
  FUNCTION_OPTIONS,
  SCHEDULE_OPTIONS,
};
