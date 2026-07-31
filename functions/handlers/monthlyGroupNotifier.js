const { logger } = require("firebase-functions");
const { institutionMessagingConfig } = require("../lib/config");
const { jakartaDateParts, monthNameId } = require("../lib/jakartaTime");
const { sendToRole } = require("../lib/messaging");
const {
  isWablasEnabled,
  sendTextMessages,
} = require("../lib/wablas");
const {
  configuredWhatsAppGroups,
} = require("../lib/whatsappGroups");
const {
  buildMonthlyAssessmentGroupMessage,
  previousMonthParts,
} = require("../lib/whatsappMessages");

const MONTHLY_GROUP_REMINDER_DAY = 3;

async function runMonthlyGroupReminder(
  parts = jakartaDateParts(),
  options = {},
) {
  if (parts.day !== MONTHLY_GROUP_REMINDER_DAY) {
    return { skipped: true, reason: "not_reminder_day" };
  }
  const enabled =
    options.enabled === undefined ? isWablasEnabled() : options.enabled;
  if (!enabled) return { skipped: true, reason: "wablas_disabled" };

  const groups =
    options.groups === undefined
      ? configuredWhatsAppGroups()
      : options.groups;
  const configured = groups.filter(
    (group) => String(group?.groupId || "").trim(),
  );
  if (!configured.length) {
    return { skipped: true, reason: "group_ids_not_configured" };
  }

  const institution =
    options.institution === undefined
      ? institutionMessagingConfig()
      : options.institution;
  const message = buildMonthlyAssessmentGroupMessage(parts, institution);
  const messages = configured.map((group) => ({
    phone: String(group.groupId).trim(),
    message,
    isGroup: "true",
    refId: `monthly-assessment-target-${parts.year}-${String(
      parts.month,
    ).padStart(2, "0")}-${group.key}`,
  }));

  try {
    const send = options.send || sendTextMessages;
    const provider = await send(messages);
    logger.info(
      `[monthlyGroupReminder] ${messages.length} grup diserahkan ke Wablas.`,
    );
    return { sent: messages.length, failed: 0, provider };
  } catch (error) {
    logger.error(
      `[monthlyGroupReminder] pengiriman Wablas gagal: ${error.message}`,
    );
    return { sent: 0, failed: messages.length, error: error.message };
  }
}

async function runMonthlyAppReminder(
  parts = jakartaDateParts(),
  options = {},
) {
  if (parts.day !== MONTHLY_GROUP_REMINDER_DAY) {
    return { skipped: true, reason: "not_reminder_day" };
  }

  const previous = previousMonthParts(parts);
  const push = options.sendPush || sendToRole;
  try {
    const result = await push("santri", {
      title: "Penilaian & Target Bulanan Tersedia",
      body: `Penilaian bulan ${monthNameId(previous.month)} ${previous.year} dan target bulan ${monthNameId(parts.month)} ${parts.year} sudah tersedia di aplikasi.`,
      data: {
        type: "monthly_assessment_target_available",
        bulan: parts.month,
        tahun: parts.year,
        assessment_month: previous.month,
        assessment_year: previous.year,
      },
    });
    logger.info(
      `[monthlyAppReminder] terkirim ${result.successCount}, gagal ${result.failureCount}.`,
    );
    return result;
  } catch (error) {
    logger.error(
      `[monthlyAppReminder] pengiriman notifikasi HP gagal: ${error.message}`,
    );
    return { successCount: 0, failureCount: 0, error: error.message };
  }
}

async function runMonthlyAssessmentReminder(
  parts = jakartaDateParts(),
  options = {},
) {
  const appDelivery = (async () => {
    try {
      return await runMonthlyAppReminder(parts, options.app);
    } catch (error) {
      logger.error(`[monthlyReminder] kanal aplikasi gagal: ${error.message}`);
      return { successCount: 0, failureCount: 0, error: error.message };
    }
  })();
  const whatsappDelivery = (async () => {
    try {
      return await runMonthlyGroupReminder(parts, options.whatsapp);
    } catch (error) {
      logger.error(`[monthlyReminder] kanal WhatsApp gagal: ${error.message}`);
      return { sent: 0, failed: 0, error: error.message };
    }
  })();
  const [app, whatsapp] = await Promise.all([
    appDelivery,
    whatsappDelivery,
  ]);

  return { app, whatsapp };
}

module.exports = {
  MONTHLY_GROUP_REMINDER_DAY,
  runMonthlyGroupReminder,
  runMonthlyAppReminder,
  runMonthlyAssessmentReminder,
};
