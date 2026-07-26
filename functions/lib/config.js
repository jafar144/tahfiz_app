const { defineString } = require("firebase-functions/params");

const AUTH_EMAIL_DOMAIN = defineString("AUTH_EMAIL_DOMAIN");
const INSTITUTION_NAME = defineString("INSTITUTION_NAME");
const PAYMENT_BANK_NAME = defineString("PAYMENT_BANK_NAME");
const PAYMENT_ACCOUNT_NUMBER = defineString("PAYMENT_ACCOUNT_NUMBER");
const PAYMENT_ACCOUNT_HOLDER = defineString("PAYMENT_ACCOUNT_HOLDER");
const STAFF_INITIAL_PASSWORD = defineString("STAFF_INITIAL_PASSWORD", {
  default: "",
});
const WABLAS_BASE_URL = defineString("WABLAS_BASE_URL", {
  default: "https://disabled.invalid",
});
const WABLAS_ENABLED = defineString("WABLAS_ENABLED", { default: "false" });
const WHATSAPP_ADMIN_PHONE = defineString("WHATSAPP_ADMIN_PHONE", {
  default: "",
});

const CALLABLE_OPTIONS = {
  region: "asia-southeast2",
  memory: "256MiB",
  enforceAppCheck: process.env.APP_CHECK_ENFORCED === "true",
};

// Opsi dasar untuk fungsi terjadwal (tanpa secret DB). Jadwal & timeZone
// ditentukan per-fungsi di handler-nya.
const SCHEDULE_OPTIONS = {
  region: "asia-southeast2",
  timeZone: "Asia/Jakarta",
  memory: "256MiB",
};

function institutionMessagingConfig() {
  return {
    institutionName: INSTITUTION_NAME.value(),
    bankName: PAYMENT_BANK_NAME.value(),
    accountNumber: PAYMENT_ACCOUNT_NUMBER.value(),
    accountHolder: PAYMENT_ACCOUNT_HOLDER.value(),
  };
}

module.exports = {
  AUTH_EMAIL_DOMAIN,
  INSTITUTION_NAME,
  PAYMENT_BANK_NAME,
  PAYMENT_ACCOUNT_NUMBER,
  PAYMENT_ACCOUNT_HOLDER,
  STAFF_INITIAL_PASSWORD,
  WABLAS_BASE_URL,
  WABLAS_ENABLED,
  WHATSAPP_ADMIN_PHONE,
  CALLABLE_OPTIONS,
  SCHEDULE_OPTIONS,
  institutionMessagingConfig,
};
