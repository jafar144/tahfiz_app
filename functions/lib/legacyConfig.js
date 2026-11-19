const crypto = require("node:crypto");
const { defineSecret, defineString } = require("firebase-functions/params");

const DB_HOST = defineString("DB_HOST");
const DB_PORT = defineString("DB_PORT", { default: "3306" });
const DB_USER = defineString("DB_USER");
const DB_NAME = defineString("DB_NAME");
const DB_PASSWORD = defineSecret("DB_PASSWORD");
const ADMIN_HTTP_TOKEN = defineSecret("ADMIN_HTTP_TOKEN");
const LEGACY_ADMIN_HTTP_ENABLED = defineString("LEGACY_ADMIN_HTTP_ENABLED", {
  default: "false",
});
const LEGACY_MIGRATION_YEAR = defineString("LEGACY_MIGRATION_YEAR", {
  default: "2026",
});
const LEGACY_MIGRATION_START_MONTH = defineString(
  "LEGACY_MIGRATION_START_MONTH",
  { default: "1" },
);
const LEGACY_PAYMENT_AMOUNT = defineString("LEGACY_PAYMENT_AMOUNT", {
  default: "200000",
});

const FUNCTION_OPTIONS = {
  region: "asia-southeast2",
  timeoutSeconds: 540,
  memory: "512MiB",
  secrets: [DB_PASSWORD, ADMIN_HTTP_TOKEN],
};

const LEGACY_ADMIN_HTTP_OPTIONS = {
  region: "asia-southeast2",
  timeoutSeconds: 540,
  memory: "512MiB",
  secrets: [ADMIN_HTTP_TOKEN],
};

function secureCompare(value, expected) {
  const actualBuffer = Buffer.from(String(value || ""), "utf8");
  const expectedBuffer = Buffer.from(String(expected || ""), "utf8");
  if (actualBuffer.length !== expectedBuffer.length) return false;
  return crypto.timingSafeEqual(actualBuffer, expectedBuffer);
}

function legacyMigrationConfig() {
  const year = Number(LEGACY_MIGRATION_YEAR.value() || "2026");
  const startMonth = Number(LEGACY_MIGRATION_START_MONTH.value() || "1");
  const paymentAmount = Number(LEGACY_PAYMENT_AMOUNT.value() || "200000");
  if (
    !Number.isInteger(year) ||
    !Number.isInteger(startMonth) ||
    startMonth < 1 ||
    startMonth > 12 ||
    !Number.isInteger(paymentAmount) ||
    paymentAmount < 0
  ) {
    throw new Error("Konfigurasi periode atau nominal migrasi tidak valid.");
  }
  return { year, startMonth, paymentAmount };
}

module.exports = {
  DB_HOST,
  DB_PORT,
  DB_USER,
  DB_NAME,
  DB_PASSWORD,
  ADMIN_HTTP_TOKEN,
  LEGACY_ADMIN_HTTP_ENABLED,
  LEGACY_MIGRATION_YEAR,
  LEGACY_MIGRATION_START_MONTH,
  LEGACY_PAYMENT_AMOUNT,
  FUNCTION_OPTIONS,
  LEGACY_ADMIN_HTTP_OPTIONS,
  secureCompare,
  legacyMigrationConfig,
};
