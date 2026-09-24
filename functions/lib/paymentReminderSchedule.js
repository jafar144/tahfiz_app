const crypto = require("node:crypto");

const FIRST_REMINDER_DAY = 20;
const MIN_INTERVAL_MINUTES = 1;
const MAX_INTERVAL_MINUTES = 10;
const START_MINUTE_WIB = 8 * 60;
const END_MINUTE_WIB = 21 * 60;

function hashNumber(value) {
  return crypto
    .createHash("sha256")
    .update(String(value))
    .digest()
    .readUInt32BE(0);
}

function monthKey(parts) {
  return `${parts.year}-${String(parts.month).padStart(2, "0")}`;
}

function daysInMonth(parts) {
  return parts.daysInMonth || new Date(parts.year, parts.month, 0).getDate();
}

function taskIdForRef(refId) {
  return `payment-${crypto
    .createHash("sha256")
    .update(String(refId))
    .digest("hex")
    .slice(0, 40)}`;
}

// Assign each active paying santri a stable day, then calculate times only for
// actual message recipients. A santri's day remains stable while the visible
// delivery gaps stay within the configured interval.
function buildPaymentReminderSchedule(recipients, messages, parts) {
  const lastDay = daysInMonth(parts);
  if (lastDay < FIRST_REMINDER_DAY) return [];

  const key = monthKey(parts);
  const dayCount = lastDay - FIRST_REMINDER_DAY + 1;
  const uniqueRecipients = new Map();
  for (const recipient of recipients || []) {
    const uid = String(recipient.uid || "").trim();
    if (uid) uniqueRecipients.set(uid, recipient);
  }
  const uniqueMessages = new Map();
  for (const message of messages || []) {
    const uid = String(message.recipientUid || "").trim();
    if (uid && !uniqueMessages.has(uid)) uniqueMessages.set(uid, message);
  }

  const dayByUid = new Map();
  for (const [uid] of uniqueRecipients) {
    const day =
      FIRST_REMINDER_DAY + hashNumber(`${key}|day|${uid}`) % dayCount;
    dayByUid.set(uid, day);
  }

  const groups = new Map();
  for (const [uid] of uniqueMessages) {
    const recipient = uniqueRecipients.get(uid);
    const day = dayByUid.get(uid);
    if (!recipient || !day) continue;
    if (!groups.has(day)) groups.set(day, []);
    groups.get(day).push({ uid, recipient });
  }

  const slotByUid = new Map();
  for (const [day, group] of groups) {
    group.sort(
      (a, b) =>
        hashNumber(`${key}|order|${a.uid}`) -
          hashNumber(`${key}|order|${b.uid}`) ||
        a.uid.localeCompare(b.uid),
    );
    if (group.length > END_MINUTE_WIB - START_MINUTE_WIB) {
      throw new Error("Kapasitas jadwal reminder harian terlampaui.");
    }

    let cursor = START_MINUTE_WIB;
    for (let index = 0; index < group.length; index += 1) {
      const current = group[index];
      const rawGap =
        MIN_INTERVAL_MINUTES +
        (hashNumber(`${key}|gap|${current.uid}`) %
          (MAX_INTERVAL_MINUTES - MIN_INTERVAL_MINUTES + 1));
      const remaining = group.length - index - 1;
      const maxGap = END_MINUTE_WIB - cursor - remaining;
      const gap = Math.max(
        MIN_INTERVAL_MINUTES,
        Math.min(rawGap, maxGap),
      );
      cursor += gap;
      slotByUid.set(current.uid, { day, minuteOfDay: cursor, gap });
    }
  }

  const result = [];
  for (const [uid, message] of uniqueMessages) {
    const slot = slotByUid.get(uid);
    if (!slot) continue;
    const hour = Math.floor(slot.minuteOfDay / 60);
    const minute = slot.minuteOfDay % 60;
    const dateKey = `${key}-${String(slot.day).padStart(2, "0")}`;
    const scheduledAt = new Date(
      `${dateKey}T${String(hour).padStart(2, "0")}:${String(minute).padStart(
        2,
        "0",
      )}:00+07:00`,
    );
    result.push({
      uid,
      santriName:
        uniqueRecipients.get(uid)?.name || message.santriName || "Santri",
      notificationType: message.notificationType,
      refId: message.refId,
      phone: message.phone,
      message: message.message,
      pushNotification: message.pushNotification,
      scheduledAt,
      dateKey,
      day: slot.day,
      hour,
      minute,
      intervalMinutes: slot.gap,
    });
  }

  return result.sort(
    (a, b) => a.scheduledAt - b.scheduledAt || a.uid.localeCompare(b.uid),
  );
}

module.exports = {
  FIRST_REMINDER_DAY,
  MIN_INTERVAL_MINUTES,
  MAX_INTERVAL_MINUTES,
  buildPaymentReminderSchedule,
  taskIdForRef,
};
