const { defineString } = require("firebase-functions/params");

const AUTH_EMAIL_DOMAIN = defineString("AUTH_EMAIL_DOMAIN");
const INSTITUTION_NAME = defineString("INSTITUTION_NAME");
const PAYMENT_BANK_NAME = defineString("PAYMENT_BANK_NAME");
const PAYMENT_ACCOUNT_NUMBER = defineString("PAYMENT_ACCOUNT_NUMBER");
const PAYMENT_ACCOUNT_HOLDER = defineString("PAYMENT_ACCOUNT_HOLDER");
const PAYMENT_START_YEAR = defineString("PAYMENT_START_YEAR", {
  default: "2026",
});
const PAYMENT_START_MONTH = defineString("PAYMENT_START_MONTH", {
  default: "2",
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

// Password awal seluruh akun asatidz per lembaga. Nama parameter sengaja
// berbeda dari STAFF_INITIAL_PASSWORD lama agar env project yang masih
// menyimpan nilai lama tidak berubah perilaku diam-diam.
const DEFAULT_ASATIDZ_INITIAL_PASSWORD = "Khoirun123";
const ASATIDZ_INITIAL_PASSWORD = defineString("ASATIDZ_INITIAL_PASSWORD", {
  default: DEFAULT_ASATIDZ_INITIAL_PASSWORD,
});

function asatidzInitialPassword(
  configured = ASATIDZ_INITIAL_PASSWORD.value(),
) {
  const password = String(configured ?? "").trim();
  if (!password) return DEFAULT_ASATIDZ_INITIAL_PASSWORD;
  // Batas minimal Firebase Authentication.
  if (password.length < 6) {
    throw new Error("ASATIDZ_INITIAL_PASSWORD minimal 6 karakter.");
  }
  return password;
}

function paymentStartPeriod() {
  // Nilai default parameter dipakai Firebase saat deploy. Fallback eksplisit
  // ini membuat helper tetap deterministik di unit test Node biasa.
  const year = Number(PAYMENT_START_YEAR.value() || "2026");
  const month = Number(PAYMENT_START_MONTH.value() || "2");
  if (
    !Number.isInteger(year) ||
    !Number.isInteger(month) ||
    month < 1 ||
    month > 12
  ) {
    throw new Error("PAYMENT_START_YEAR/MONTH tidak valid.");
  }
  return { year, month };
}

module.exports = {
  AUTH_EMAIL_DOMAIN,
  INSTITUTION_NAME,
  PAYMENT_BANK_NAME,
  PAYMENT_ACCOUNT_NUMBER,
  PAYMENT_ACCOUNT_HOLDER,
  PAYMENT_START_YEAR,
  PAYMENT_START_MONTH,
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
  DEFAULT_ASATIDZ_INITIAL_PASSWORD,
  ASATIDZ_INITIAL_PASSWORD,
  asatidzInitialPassword,
  institutionMessagingConfig,
  paymentStartPeriod,
};
