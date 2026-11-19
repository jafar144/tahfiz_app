const crypto = require("node:crypto");
const { jakartaDateTimeParts } = require("./jakartaTime");

const FIRST_REMINDER_DAY = 25;
const MIN_INTERVAL_MINUTES = 1;
const MAX_INTERVAL_MINUTES = 15;
const START_MINUTE_WIB = 8 * 60;
const END_MINUTE_WIB = 15 * 60;

function hashNumber(value) {
  return crypto.createHash("sha256").update(String(value)).digest().readUInt32BE(0);
}

function monthKey(parts) {
  return `${parts.year}-${String(parts.month).padStart(2, "0")}`;
}

function reminderRefId(parts, uid) {
  // Category changes after partial payment must not send a second reminder.
  return `payment-${monthKey(parts)}-${uid}`;
}

function taskIdForRef(refId) {
  return `payment-${crypto.createHash("sha256").update(String(refId)).digest("hex").slice(0, 40)}`;
}

function intervalForRecipient(parts, uid) {
  return MIN_INTERVAL_MINUTES + hashNumber(`${monthKey(parts)}|gap|${uid}`) %
    (MAX_INTERVAL_MINUTES - MIN_INTERVAL_MINUTES + 1);
}

function atMinute(parts, minute) {
  return new Date(`${monthKey(parts)}-${String(parts.day).padStart(2, "0")}T` +
    `${String(Math.floor(minute / 60)).padStart(2, "0")}:${String(minute % 60).padStart(2, "0")}:00+07:00`);
}

function inDeliveryWindow(now) {
  const parts = jakartaDateTimeParts(now);
  const minute = parts.hour * 60 + parts.minute;
  return minute >= START_MINUTE_WIB && minute < END_MINUTE_WIB;
}

// Fill today's remaining time, then move to the next morning. No day hashing.
function nextDeliverySlot(now, previous, gap) {
  let cursor = new Date(Math.max(now.getTime(), previous?.getTime() || 0));
  let parts = jakartaDateTimeParts(cursor);
  const opening = atMinute(parts, START_MINUTE_WIB);
  cursor = new Date(Math.max(opening.getTime(), cursor.getTime()));
  let slot = new Date(Math.ceil(cursor.getTime() / 60000) * 60000 + gap * 60000);
  if (slot >= atMinute(parts, END_MINUTE_WIB)) {
    parts = jakartaDateTimeParts(new Date(opening.getTime() + 86400000));
    slot = new Date(atMinute(parts, START_MINUTE_WIB).getTime() + gap * 60000);
  }
  return slot;
}

function orderedMessages(messages, parts) {
  const unique = new Map();
  for (const message of messages || []) {
    if (message.recipientUid && !unique.has(message.recipientUid)) {
      unique.set(message.recipientUid, message);
    }
  }
  return [...unique.values()].sort((a, b) =>
    hashNumber(`${monthKey(parts)}|order|${a.recipientUid}`) -
      hashNumber(`${monthKey(parts)}|order|${b.recipientUid}`) ||
    a.recipientUid.localeCompare(b.recipientUid));
}

function buildPaymentReminderSchedule(recipients, messages, parts, options = {}) {
  const byUid = new Map(recipients.map((recipient) => [recipient.uid, recipient]));
  const start = atMinute({ ...parts, day: FIRST_REMINDER_DAY }, START_MINUTE_WIB);
  const now = new Date(Math.max(start.getTime(), options.now?.getTime() || 0));
  let previous = options.previous || null;
  const result = [];
  for (const message of orderedMessages(messages, parts)) {
    if (!byUid.has(message.recipientUid)) continue;
    const gap = intervalForRecipient(parts, message.recipientUid);
    const scheduledAt = nextDeliverySlot(now, previous, gap);
    const date = jakartaDateTimeParts(scheduledAt);
    if (monthKey(date) !== monthKey(parts)) break;
    previous = scheduledAt;
    result.push({
      ...message,
      uid: message.recipientUid,
      santriName: byUid.get(message.recipientUid).name,
      scheduledAt,
      dateKey: `${monthKey(date)}-${String(date.day).padStart(2, "0")}`,
      day: date.day,
      hour: date.hour,
      minute: date.minute,
      intervalMinutes: gap,
    });
  }
  return result;
}

module.exports = {
  FIRST_REMINDER_DAY, MIN_INTERVAL_MINUTES, MAX_INTERVAL_MINUTES,
  START_MINUTE_WIB, END_MINUTE_WIB, monthKey, reminderRefId,
  intervalForRecipient, atMinute, inDeliveryWindow, nextDeliverySlot,
  orderedMessages, buildPaymentReminderSchedule, taskIdForRef,
};
