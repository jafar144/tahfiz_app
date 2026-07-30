const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const {
  SCHEDULE_OPTIONS,
  institutionMessagingConfig,
} = require("../lib/config");
const { jakartaDateParts } = require("../lib/jakartaTime");
const {
  isWablasEnabled,
  sendTextMessages,
} = require("../lib/wablas");
const {
  configuredWhatsAppGroups,
} = require("../lib/whatsappGroups");
const {
  buildMonthlyAssessmentGroupMessage,
} = require("../lib/whatsappMessages");

const MONTHLY_GROUP_REMINDER_DAY = 3;

const wablasEnabledAtDeploy = ["1", "true", "yes", "on"].includes(
  String(process.env.WABLAS_ENABLED || "").trim().toLowerCase(),
);
const wablasSecrets = wablasEnabledAtDeploy
  ? Object.values(require("../lib/wablasSecrets"))
  : [];
const MONTHLY_GROUP_SCHEDULE_OPTIONS = {
  ...SCHEDULE_OPTIONS,
  schedule: "0 9 3 * *",
  timeoutSeconds: 120,
  secrets: wablasSecrets,
};

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

const scheduledMonthlyGroupReminder = onSchedule(
  MONTHLY_GROUP_SCHEDULE_OPTIONS,
  async () => {
    await runMonthlyGroupReminder();
  },
);

module.exports = {
  MONTHLY_GROUP_REMINDER_DAY,
  scheduledMonthlyGroupReminder,
  runMonthlyGroupReminder,
};
