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
const APP_DOWNLOAD_URL = defineString("APP_DOWNLOAD_URL", {
  default: "",
});

// ID grup dipakai Wablas untuk broadcast (isGroup=true), sedangkan invite URL
// disematkan pada pesan selamat datang santri. Keduanya sengaja dipisah karena
// ID internal WhatsApp bukan tautan yang dapat dibuka wali.
const WHATSAPP_GROUP_PUTRA_PAGI_ID = defineString(
  "WHATSAPP_GROUP_PUTRA_PAGI_ID",
  { default: "" },
);
const WHATSAPP_GROUP_PUTRA_PAGI_INVITE_URL = defineString(
  "WHATSAPP_GROUP_PUTRA_PAGI_INVITE_URL",
  { default: "" },
);
const WHATSAPP_GROUP_PUTRA_SORE_ID = defineString(
  "WHATSAPP_GROUP_PUTRA_SORE_ID",
  { default: "" },
);
const WHATSAPP_GROUP_PUTRA_SORE_INVITE_URL = defineString(
  "WHATSAPP_GROUP_PUTRA_SORE_INVITE_URL",
  { default: "" },
);
const WHATSAPP_GROUP_PUTRA_MALAM_ID = defineString(
  "WHATSAPP_GROUP_PUTRA_MALAM_ID",
  { default: "" },
);
const WHATSAPP_GROUP_PUTRA_MALAM_INVITE_URL = defineString(
  "WHATSAPP_GROUP_PUTRA_MALAM_INVITE_URL",
  { default: "" },
);
const WHATSAPP_GROUP_PUTRI_PAGI_ID = defineString(
  "WHATSAPP_GROUP_PUTRI_PAGI_ID",
  { default: "" },
);
const WHATSAPP_GROUP_PUTRI_PAGI_INVITE_URL = defineString(
  "WHATSAPP_GROUP_PUTRI_PAGI_INVITE_URL",
  { default: "" },
);
const WHATSAPP_GROUP_PUTRI_SORE_ID = defineString(
  "WHATSAPP_GROUP_PUTRI_SORE_ID",
  { default: "" },
);
const WHATSAPP_GROUP_PUTRI_SORE_INVITE_URL = defineString(
  "WHATSAPP_GROUP_PUTRI_SORE_INVITE_URL",
  { default: "" },
);
const WHATSAPP_GROUP_PUTRI_MALAM_ID = defineString(
  "WHATSAPP_GROUP_PUTRI_MALAM_ID",
  { default: "" },
);
const WHATSAPP_GROUP_PUTRI_MALAM_INVITE_URL = defineString(
  "WHATSAPP_GROUP_PUTRI_MALAM_INVITE_URL",
  { default: "" },
);

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
  APP_DOWNLOAD_URL,
  WHATSAPP_GROUP_PUTRA_PAGI_ID,
  WHATSAPP_GROUP_PUTRA_PAGI_INVITE_URL,
  WHATSAPP_GROUP_PUTRA_SORE_ID,
  WHATSAPP_GROUP_PUTRA_SORE_INVITE_URL,
  WHATSAPP_GROUP_PUTRA_MALAM_ID,
  WHATSAPP_GROUP_PUTRA_MALAM_INVITE_URL,
  WHATSAPP_GROUP_PUTRI_PAGI_ID,
  WHATSAPP_GROUP_PUTRI_PAGI_INVITE_URL,
  WHATSAPP_GROUP_PUTRI_SORE_ID,
  WHATSAPP_GROUP_PUTRI_SORE_INVITE_URL,
  WHATSAPP_GROUP_PUTRI_MALAM_ID,
  WHATSAPP_GROUP_PUTRI_MALAM_INVITE_URL,
  CALLABLE_OPTIONS,
  SCHEDULE_OPTIONS,
  institutionMessagingConfig,
};
