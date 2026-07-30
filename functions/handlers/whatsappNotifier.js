const { logger } = require("firebase-functions");
const {
  APP_DOWNLOAD_URL,
  WHATSAPP_ADMIN_PHONE,
  institutionMessagingConfig,
} = require("../lib/config");
const { fetchTodayBirthdays } = require("../lib/birthdayStatus");
const { jakartaDateParts } = require("../lib/jakartaTime");
const {
  isWablasEnabled,
  normalizeWhatsAppPhone,
  sendTextMessages,
} = require("../lib/wablas");
const {
  normalizeHttpsUrl,
  resolveWhatsAppGroup,
} = require("../lib/whatsappGroups");
const {
  buildArrearsWhatsAppMessage,
  buildBirthdayWhatsAppMessage,
  buildSantriWelcomeWhatsAppMessage,
  buildAdminFallbackWhatsAppMessage,
} = require("../lib/whatsappMessages");

// Dihitung inklusif: pada Juli, tunggakan Mei berumur 3 periode tagihan.
const MIN_ARREARS_BILLING_PERIODS = 3;

function monthIndex(item) {
  return item.year * 12 + (item.month - 1);
}

function oldestArrearsAge(santri, parts) {
  if (!santri.months?.length) return 0;
  return monthIndex(parts) - monthIndex(santri.months[0]) + 1;
}

function billingPeriodsSinceEntry(santri, parts) {
  if (!santri.tanggalMasuk) return 0;
  const entry = jakartaDateParts(santri.tanggalMasuk);
  return monthIndex(parts) - monthIndex(entry) + 1;
}

function selectLongOverdueSantri(
  unpaid,
  parts,
  minimumPeriods = MIN_ARREARS_BILLING_PERIODS
) {
  return unpaid.filter(
    (santri) =>
      oldestArrearsAge(santri, parts) >= minimumPeriods &&
      billingPeriodsSinceEntry(santri, parts) >= minimumPeriods
  );
}

function prepareMessages(items, parts, type, builder, adminPhone) {
  const messages = [];
  let invalidPhoneCount = 0;
  let adminFallbackCount = 0;
  const normalizedAdminPhone = normalizeWhatsAppPhone(adminPhone);
  for (const item of items) {
    const originalMessage = builder(item);
    const phone = normalizeWhatsAppPhone(item.nomorWali);
    if (!phone) {
      invalidPhoneCount += 1;
      if (normalizedAdminPhone) {
        const reason = String(item.nomorWali || "").trim()
          ? "format nomor wali tidak valid"
          : "nomor wali belum diisi";
        messages.push({
          phone: normalizedAdminPhone,
          message: buildAdminFallbackWhatsAppMessage({
            santri: item,
            notificationType: type,
            reason,
            originalMessage,
          }),
          isGroup: "false",
          refId: `${type}-admin-${parts.year}-${String(parts.month).padStart(
            2,
            "0"
          )}-${item.uid}`,
        });
        adminFallbackCount += 1;
      }
      continue;
    }
    const dateSuffix =
      type === "birthday" ? `-${String(parts.day).padStart(2, "0")}` : "";
    messages.push({
      phone,
      message: originalMessage,
      isGroup: "false",
      refId: `${type}-${parts.year}-${String(parts.month).padStart(
        2,
        "0"
      )}${dateSuffix}-${item.uid}`,
    });
  }
  return { messages, invalidPhoneCount, adminFallbackCount };
}

async function dispatch(messages, label, send = sendTextMessages) {
  if (!messages.length) return { sent: 0, failed: 0 };
  try {
    const result = await send(messages);
    logger.info(`[${label}] ${messages.length} pesan diserahkan ke Wablas.`);
    return { sent: messages.length, failed: 0, provider: result };
  } catch (error) {
    logger.error(`[${label}] pengiriman Wablas gagal: ${error.message}`);
    return { sent: 0, failed: messages.length, error: error.message };
  }
}

async function runWhatsAppArrears(parts, unpaid, options = {}) {
  const enabled =
    options.enabled === undefined ? isWablasEnabled() : options.enabled;
  if (!enabled) return { skipped: true, reason: "wablas_disabled" };

  const eligible = selectLongOverdueSantri(unpaid, parts);
  const adminPhone =
    options.adminPhone === undefined
      ? WHATSAPP_ADMIN_PHONE.value()
      : options.adminPhone;
  const institution =
    options.institution === undefined
      ? institutionMessagingConfig()
      : options.institution;
  const prepared = prepareMessages(
    eligible,
    parts,
    "arrears",
    (item) => buildArrearsWhatsAppMessage(item, institution),
    adminPhone
  );
  const delivery = await dispatch(
    prepared.messages,
    "whatsappArrears",
    options.send
  );
  return {
    eligible: eligible.length,
    invalidPhone: prepared.invalidPhoneCount,
    adminFallback: prepared.adminFallbackCount,
    ...delivery,
  };
}

async function runBirthdayWhatsApp(parts, options = {}) {
  const enabled =
    options.enabled === undefined ? isWablasEnabled() : options.enabled;
  if (!enabled) return { skipped: true, reason: "wablas_disabled" };

  const birthdays = options.birthdays || (await fetchTodayBirthdays(parts));
  const adminPhone =
    options.adminPhone === undefined
      ? WHATSAPP_ADMIN_PHONE.value()
      : options.adminPhone;
  const institution =
    options.institution === undefined
      ? institutionMessagingConfig()
      : options.institution;
  const prepared = prepareMessages(
    birthdays,
    parts,
    "birthday",
    (item) => buildBirthdayWhatsAppMessage(item, institution),
    adminPhone
  );
  const delivery = await dispatch(
    prepared.messages,
    "whatsappBirthday",
    options.send
  );
  return {
    birthdays: birthdays.length,
    invalidPhone: prepared.invalidPhoneCount,
    adminFallback: prepared.adminFallbackCount,
    ...delivery,
  };
}

async function runSantriWelcomeWhatsApp(santri, password, options = {}) {
  const enabled =
    options.enabled === undefined ? isWablasEnabled() : options.enabled;
  if (!enabled) return { skipped: true, reason: "wablas_disabled" };

  const appUrl = normalizeHttpsUrl(
    options.appUrl === undefined ? APP_DOWNLOAD_URL.value() : options.appUrl,
  );
  if (!appUrl) {
    return { skipped: true, reason: "app_url_not_configured" };
  }

  const group =
    options.group === undefined
      ? resolveWhatsAppGroup(santri.jenisKelamin, santri.tipeKelas)
      : options.group;
  if (!group) {
    return { skipped: true, reason: "group_identity_not_supported" };
  }
  const inviteUrl = normalizeHttpsUrl(group.inviteUrl);
  if (!inviteUrl) {
    return { skipped: true, reason: "group_invite_not_configured" };
  }

  // Nomor wali diprioritaskan karena pesan memuat kredensial akun. Nomor
  // santri hanya menjadi fallback bila nomor wali kosong/tidak valid. Pesan
  // tidak dialihkan ke admin agar password tidak terkirim ke penerima lain.
  const waliPhone = normalizeWhatsAppPhone(santri.nomorWali);
  const santriPhone = normalizeWhatsAppPhone(santri.phone);
  const phone = waliPhone || santriPhone;
  if (!phone) {
    return { skipped: true, reason: "recipient_phone_invalid" };
  }

  const institution =
    options.institution === undefined
      ? institutionMessagingConfig()
      : options.institution;
  const message = buildSantriWelcomeWhatsAppMessage({
    santri,
    password,
    institution,
    appUrl,
    group: { ...group, inviteUrl },
  });
  const delivery = await dispatch(
    [
      {
        phone,
        message,
        isGroup: "false",
        refId: `welcome-${santri.uid}`,
      },
    ],
    "whatsappSantriWelcome",
    options.send,
  );

  return {
    recipient: waliPhone ? "wali" : "santri",
    group: group.key,
    ...delivery,
  };
}

module.exports = {
  MIN_ARREARS_BILLING_PERIODS,
  oldestArrearsAge,
  billingPeriodsSinceEntry,
  selectLongOverdueSantri,
  prepareMessages,
  runWhatsAppArrears,
  runBirthdayWhatsApp,
  runSantriWelcomeWhatsApp,
};
