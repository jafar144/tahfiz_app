const { admin, db } = require("./firebase");
const { FieldPath } = require("firebase-admin/firestore");
const { jakartaDateTimeParts } = require("./jakartaTime");
const {
  monthKey, reminderRefId, intervalForRecipient, nextDeliverySlot, taskIdForRef,
} = require("./paymentReminderSchedule");

const DELIVERY_COLLECTION = "scheduled_payment_notifications";
const CURSOR_COLLECTION = "payment_notification_cursors";
const MAX_ATTEMPTS = 5;
const timestamp = () => admin.firestore.FieldValue.serverTimestamp();
const asDate = (value) => value?.toDate?.() || (value ? new Date(value) : null);

async function loadDeliveryRecords(parts, recipients, firestore = db) {
  const result = new Map();
  const allowed = new Set(recipients.map((item) => item.uid));
  if (!allowed.size) return result;
  const prefixes = [
    ...["current-month-payment", "two-month-arrears", "arrears"].flatMap((type) => [
      `${type}-${monthKey(parts)}-`, `${type}-admin-${monthKey(parts)}-`,
    ]),
    `payment-${monthKey(parts)}-`,
  ];
  // Prefix reads cost only the existing records, not 7 missing docs per santri.
  const snapshots = await Promise.all(prefixes.map((prefix) =>
    firestore.collection(DELIVERY_COLLECTION)
      .orderBy(FieldPath.documentId())
      .startAt(prefix).endAt(prefix + "\uf8ff").get()));
  snapshots.forEach((snapshot, index) => snapshot.docs.forEach((doc) => {
    const uid = doc.id.slice(prefixes[index].length);
    if (!allowed.has(uid)) return;
    const data = doc.data();
    const canonical = index === prefixes.length - 1;
    const current = result.get(uid);
    if (canonical || !current || data.status === "sent") {
      result.set(uid, {
        ...data,
        whatsapp_status: data.whatsapp_status || (data.status === "sent" ? "sent" : null),
        admin_fallback: data.admin_fallback ?? prefixes[index].includes("-admin-"),
      });
    }
  }));
  return result;
}

function hasActiveTask(record, now) {
  if (!record) return false;
  if (record.status === "sending" && asDate(record.lease_until) > now) return true;
  const scheduled = asDate(record.scheduled_at);
  return ["queued", "sending", "failed"].includes(record.status) &&
    scheduled && now.getTime() - scheduled.getTime() < 60 * 60000 &&
    Number(record.cycle_attempts || 0) < MAX_ATTEMPTS;
}

// A shared cursor serializes automatic and manual reservations across periods.
// Reserve before enqueue: a repeated scheduler can recover the same task ID.
async function reserveDelivery(item, parts, options = {}) {
  const firestore = options.firestore || db;
  const now = options.now || new Date();
  const refId = reminderRefId(parts, item.uid);
  const ref = firestore.collection(DELIVERY_COLLECTION).doc(refId);
  const cursorRef = firestore.collection(CURSOR_COLLECTION).doc("payment");
  return firestore.runTransaction(async (transaction) => {
    const [snapshot, cursorSnapshot] = await Promise.all([
      transaction.get(ref), transaction.get(cursorRef),
    ]);
    const record = snapshot.exists ? snapshot.data() : options.seed || {};
    const correctedPhone = options.manual && record.admin_fallback && !item.adminFallback && Boolean(item.phone);
    if (record.status === "sent" && !correctedPhone) return { skipped: true, reason: "sent" };
    if (!options.manual && record.status === "blocked") return { skipped: true, reason: "blocked" };
    if (hasActiveTask(record, now)) {
      if (record.status === "queued") {
        return { refId, ...record, scheduledAt: asDate(record.scheduled_at), existing: true };
      }
      return { skipped: true, reason: "active" };
    }
    if (!options.manual && record.status === "failed" &&
        Number(record.cycle_attempts || 0) >= MAX_ATTEMPTS) {
      return { skipped: true, reason: "failed" };
    }
    const gap = intervalForRecipient(parts, item.uid);
    const slot = nextDeliverySlot(now, asDate(cursorSnapshot.data()?.last_slot), gap);
    const local = jakartaDateTimeParts(slot);
    if (!options.manual && (monthKey(local) !== monthKey(parts) || local.day !== parts.day)) {
      return { skipped: true, reason: "day_full" };
    }
    const generation = Number(record.generation || 0) + 1;
    const data = {
      ref_id: refId,
      recipient_uid: item.uid,
      period: monthKey(parts),
      notification_type: item.notificationType,
      status: "queued",
      generation,
      cycle_attempts: 0,
      attempts: Number(record.attempts || 0),
      scheduled_at: admin.firestore.Timestamp.fromDate(slot),
      interval_minutes: gap,
      manual: Boolean(options.manual),
      task_id: taskIdForRef(`${refId}-${generation}`),
      whatsapp_status: correctedPhone ? "pending" : record.whatsapp_status || "pending",
      app_notification_status: record.app_notification_status || "pending",
      admin_fallback: correctedPhone ? false : Boolean(record.admin_fallback),
      updated_at: timestamp(),
    };
    if (correctedPhone) data.whatsapp_sent_at = admin.firestore.FieldValue.delete();
    else if (record.whatsapp_sent_at) data.whatsapp_sent_at = record.whatsapp_sent_at;
    data.sent_at = admin.firestore.FieldValue.delete();
    if (record.app_notification_sent_at) data.app_notification_sent_at = record.app_notification_sent_at;
    transaction.set(ref, data, { merge: true });
    transaction.set(cursorRef, { last_slot: data.scheduled_at, updated_at: timestamp() });
    return { refId, ...data, scheduledAt: slot };
  });
}

module.exports = {
  DELIVERY_COLLECTION, MAX_ATTEMPTS, asDate, loadDeliveryRecords,
  hasActiveTask, reserveDelivery,
};
