const { getFunctions } = require("firebase-admin/functions");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const { logger } = require("firebase-functions");
const { admin, db } = require("../lib/firebase");
const { assertAdmin } = require("../lib/authz");
const { CALLABLE_OPTIONS } = require("../lib/config");
const { sendToUid } = require("../lib/messaging");
const { fetchPayingSantri, computeUnpaidSantri } = require("../lib/paymentStatus");
const { jakartaDateTimeParts } = require("../lib/jakartaTime");
const {
  FIRST_REMINDER_DAY, MIN_INTERVAL_MINUTES, MAX_INTERVAL_MINUTES,
  START_MINUTE_WIB, monthKey, reminderRefId,
  atMinute, inDeliveryWindow, orderedMessages, buildPaymentReminderSchedule,
} = require("../lib/paymentReminderSchedule");
const {
  DELIVERY_COLLECTION, MAX_ATTEMPTS, asDate, loadDeliveryRecords,
  hasActiveTask, reserveDelivery,
} = require("../lib/paymentReminderStore");
const { prepareScheduledPaymentMessages } = require("./whatsappNotifier");
const { buildArrearsWhatsAppMessage } = require("../lib/whatsappMessages");
const { buildPaymentArrearsPushNotification } = require("../lib/paymentPushNotifications");
const { institutionMessagingConfig } = require("../lib/config");
const { isWablasEnabled, normalizeWhatsAppPhone, sendTextMessages } = require("../lib/wablas");

const TASK_FUNCTION_NAME = "locations/asia-southeast2/functions/sendScheduledPaymentWhatsApp";
const { shouldBindWablasSecrets } = require("../lib/deploymentConfig");
const wablasSecrets = shouldBindWablasSecrets()
  ? Object.values(require("../lib/wablasSecrets"))
  : [];
const timestamp = () => admin.firestore.FieldValue.serverTimestamp();
const deleteField = () => admin.firestore.FieldValue.delete();

function validMonthParts(yearValue, monthValue) {
  const year = Number(yearValue);
  const month = Number(monthValue);
  if (!Number.isInteger(year) || year < 2020 || year > 2100 ||
      !Number.isInteger(month) || month < 1 || month > 12) {
    throw new HttpsError("invalid-argument", "Periode pembayaran tidak valid.");
  }
  const daysInMonth = new Date(year, month, 0).getDate();
  return { year, month, day: FIRST_REMINDER_DAY, daysInMonth,
    daysRemaining: daysInMonth - FIRST_REMINDER_DAY };
}

function referenceDate(parts) {
  return atMinute({ ...parts, day: FIRST_REMINDER_DAY }, START_MINUTE_WIB);
}

async function loadPaymentReminderPlan(parts, overrides = {}) {
  const now = overrides.now || new Date();
  const recipients = await (overrides.fetchPayingSantri || fetchPayingSantri)(now, overrides.recipientUid);
  const unpaid = await (overrides.computeUnpaidSantri || computeUnpaidSantri)(parts, now, recipients);
  const prepared = (overrides.prepareMessages || prepareScheduledPaymentMessages)(
    parts, unpaid, overrides.messageOptions,
  );
  const byUid = new Map(prepared.messages.map((item) => [item.recipientUid, item]));
  // Include every unpaid santri: invalid/missing phones still receive the app
  // notification, and a single older unpaid month must not fall between groups.
  const messages = unpaid.map((santri) => {
    const existing = byUid.get(santri.uid);
    return {
      ...(existing || {
        recipientUid: santri.uid,
        notificationType: "arrears",
        phone: normalizeWhatsAppPhone(santri.nomorWali),
        message: buildArrearsWhatsAppMessage(
          santri, overrides.messageOptions?.institution || institutionMessagingConfig(),
        ),
        pushNotification: buildPaymentArrearsPushNotification(santri, parts),
      }),
      uid: santri.uid,
      santriName: santri.name,
      arrearsCount: santri.months.length,
      months: santri.months,
      adminFallback: Boolean(existing && !normalizeWhatsAppPhone(santri.nomorWali)),
      refId: reminderRefId(parts, santri.uid),
    };
  });
  const records = overrides.skipRecords ? new Map() : await (overrides.loadRecords || loadDeliveryRecords)(
    parts, unpaid, overrides.firestore || db,
  );
  return { unpaid, messages, records, now, invalidPhoneCount: prepared.invalidPhoneCount,
    adminFallbackCount: prepared.adminFallbackCount };
}

function isDuplicateTaskError(error) {
  const code = String(error?.code || "");
  return code.includes("task-already-exists") || ["already-exists", "6"].includes(code);
}

async function enqueueReservation(reservation, parts, overrides = {}) {
  const queue = overrides.queue || getFunctions().taskQueue(TASK_FUNCTION_NAME);
  try {
    await queue.enqueue({
      recipientUid: reservation.recipient_uid,
      refId: reservation.refId,
      year: parts.year,
      month: parts.month,
      generation: reservation.generation,
    }, {
      id: reservation.task_id,
      scheduleTime: reservation.scheduledAt,
      dispatchDeadlineSeconds: 60,
    });
    return true;
  } catch (error) {
    if (!isDuplicateTaskError(error)) throw error;
    return false;
  }
}

async function runPaymentReminderQueue(parts, overrides = {}) {
  // Use the actual execution time for catch-up; event.scheduleTime can be stale.
  const now = overrides.now || new Date();
  const today = jakartaDateTimeParts(now);
  if (today.day < FIRST_REMINDER_DAY) return { skipped: true };
  parts = today;
  const plan = await loadPaymentReminderPlan(parts, { ...overrides, now });
  let queued = 0;
  let duplicate = 0;
  for (const item of orderedMessages(plan.messages, parts)) {
    const reservation = await (overrides.reserve || reserveDelivery)(item, parts, {
      ...overrides, now, seed: plan.records.get(item.uid),
    });
    if (reservation.reason === "day_full") break;
    if (reservation.skipped) continue;
    if (await enqueueReservation(reservation, parts, overrides)) queued += 1;
    else duplicate += 1;
  }
  logger.info(`[paymentReminderQueue] tanggal ${parts.day}: antre ${queued}, duplikat ${duplicate}, nomor invalid ${plan.invalidPhoneCount}.`);
  return { queued, duplicate, invalidPhone: plan.invalidPhoneCount,
    adminFallback: plan.adminFallbackCount };
}

function validateDelivery(data) {
  const parts = validMonthParts(data?.year, data?.month);
  const recipientUid = String(data?.recipientUid || "").trim();
  const generation = Number(data?.generation);
  if (!recipientUid || recipientUid.length > 128 || recipientUid.includes("/") ||
      !Number.isInteger(generation) || generation < 1 ||
      data?.refId !== reminderRefId(parts, recipientUid)) {
    throw new HttpsError("invalid-argument", "Identitas reminder pembayaran tidak valid.");
  }
  return { recipientUid, refId: data.refId, generation, parts };
}

async function claimDelivery(delivery, overrides = {}) {
  const firestore = overrides.firestore || db;
  const now = overrides.now || new Date();
  const ref = firestore.collection(DELIVERY_COLLECTION).doc(delivery.refId);
  return firestore.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const current = snapshot.data() || {};
    if (!snapshot.exists || current.generation !== delivery.generation) return { status: "obsolete" };
    if (["sent", "cancelled"].includes(current.status)) return { status: "complete" };
    if (current.status === "sending" && asDate(current.lease_until) > now) return { status: "busy" };
    transaction.set(ref, {
      status: "sending",
      attempts: admin.firestore.FieldValue.increment(1),
      cycle_attempts: admin.firestore.FieldValue.increment(1),
      lease_until: admin.firestore.Timestamp.fromDate(new Date(now.getTime() + 2 * 60000)),
      updated_at: timestamp(),
    }, { merge: true });
    return { ...current, status: "claimed" };
  });
}

async function runScheduledPaymentDelivery(request, overrides = {}) {
  // Old queued payloads are re-reserved under the new calendar and identity.
  if (!request.data?.generation && request.data?.recipientUid) {
    const match = String(request.data.refId || "").match(/-(\d{4})-(\d{2})-/);
    if (match) {
      const parts = validMonthParts(match[1], match[2]);
      const plan = await loadPaymentReminderPlan(parts, overrides);
      const item = plan.messages.find((value) => value.uid === request.data.recipientUid);
      if (!item) return { skipped: true, reason: "paid" };
      const now = overrides.now || new Date();
      const today = jakartaDateTimeParts(now);
      if (monthKey(today) !== monthKey(parts) || today.day < FIRST_REMINDER_DAY) {
        return { skipped: true, reason: "outside_period" };
      }
      const reservation = await (overrides.reserve || reserveDelivery)(item, today, {
        ...overrides, now, seed: plan.records.get(item.uid),
      });
      if (!reservation.skipped) await enqueueReservation(reservation, parts, overrides);
      return { migrated: true };
    }
  }
  const delivery = validateDelivery(request.data);
  const deliveryNow = () => overrides.clock?.() || overrides.now || new Date();
  const now = deliveryNow();
  const claim = await (overrides.claim || claimDelivery)(delivery, { ...overrides, now });
  if (["complete", "obsolete"].includes(claim.status)) return { duplicate: true };
  if (claim.status === "busy") throw new Error("Pengiriman reminder masih diproses.");
  const ref = (overrides.firestore || db).collection(DELIVERY_COLLECTION).doc(delivery.refId);
  const persist = overrides.persist || ((data) => ref.set(data, { merge: true }));
  const today = jakartaDateTimeParts(now);
  const defer = async () => {
    await persist({ status: "deferred", lease_until: deleteField(), updated_at: timestamp() });
    // Automatic tasks resume at the next daily run. A manual follow-up can be
    // for a previous period, so explicitly retain its next-day continuation.
    if (claim.manual) {
      const reservation = await (overrides.reserve || reserveDelivery)(
        { uid: delivery.recipientUid, notificationType: claim.notification_type },
        delivery.parts, { ...overrides, now: deliveryNow(), manual: true },
      );
      if (!reservation.skipped) await enqueueReservation(reservation, delivery.parts, overrides);
    }
    return { deferred: true };
  };
  if (!inDeliveryWindow(now) || (!claim.manual &&
      (today.day < FIRST_REMINDER_DAY || monthKey(today) !== monthKey(delivery.parts)))) {
    return defer();
  }

  // Re-read payments just before delivery; never send a stale queued bill.
  let plan;
  try {
    plan = await (overrides.loadPlan || loadPaymentReminderPlan)(delivery.parts, {
      ...overrides, now, recipientUid: delivery.recipientUid, skipRecords: true,
    });
  } catch (error) {
    await persist({ status: "failed", last_error_code: "payment_recheck_failed",
      lease_until: deleteField(), updated_at: timestamp() });
    throw error;
  }
  const item = plan.messages.find((value) => value.uid === delivery.recipientUid);
  if (!item) {
    await persist({ status: "cancelled", reason: "paid_or_inactive",
      lease_until: deleteField(), updated_at: timestamp() });
    return { skipped: true, reason: "paid_or_inactive" };
  }
  let failure;
  const enabled = overrides.enabled === undefined ? isWablasEnabled() : overrides.enabled;
  const whatsappComplete = claim.whatsapp_status === "sent";
  // A slow Firestore/provider call can cross 15:00 after the first guard.
  if (!inDeliveryWindow(deliveryNow())) return defer();
  if (!whatsappComplete) {
    try {
      if (enabled && item.phone) {
        await (overrides.send || sendTextMessages)([item]);
        await persist({ whatsapp_status: "sent", whatsapp_sent_at: timestamp(),
          admin_fallback: item.adminFallback, updated_at: timestamp() });
      } else {
        await persist({ whatsapp_status: enabled ? "invalid-phone" : "disabled",
          updated_at: timestamp() });
      }
    } catch (error) {
      failure = error;
      await persist({ whatsapp_status: "failed", updated_at: timestamp() });
    }
  }
  if (!["sent", "partial", "no-device"].includes(claim.app_notification_status)) {
    if (!inDeliveryWindow(deliveryNow())) return defer();
    try {
      const result = await (overrides.sendPush || sendToUid)(delivery.recipientUid, item.pushNotification);
      const success = Number(result?.successCount || 0);
      const failed = Number(result?.failureCount || 0);
      if (success === 0 && failed > 0) throw new Error("Pengiriman notifikasi aplikasi gagal.");
      await persist({
        app_notification_status: success > 0 ? (failed > 0 ? "partial" : "sent") : "no-device",
        app_notification_success_count: success,
        app_notification_failure_count: failed,
        app_notification_sent_at: timestamp(),
        updated_at: timestamp(),
      });
    } catch (error) {
      failure ||= error;
      await persist({ app_notification_status: "failed", updated_at: timestamp() });
    }
  }
  await persist({
    status: failure ? "failed" : (whatsappComplete || (enabled && item.phone)) ? "sent" : "blocked",
    ...(failure ? { last_error_code: String(failure.code || "provider_error").slice(0, 80) }
      : { sent_at: timestamp(), last_error_code: deleteField() }),
    lease_until: deleteField(),
    updated_at: timestamp(),
  });
  if (failure) throw failure;
  return { sent: true, whatsapp: whatsappComplete ? "already-complete" : "processed" };
}

async function paymentReminderDashboard(parts, overrides = {}) {
  const plan = await loadPaymentReminderPlan(parts, overrides);
  const pending = plan.messages.filter((item) => {
    const record = plan.records.get(item.uid);
    return !record || !["sent", "blocked", "failed"].includes(record.status) &&
      !hasActiveTask(record, plan.now);
  });
  const futureSlots = [...plan.records.values()].map((r) => asDate(r.scheduled_at))
    .filter((date) => date && date > plan.now);
  const previous = futureSlots.length ? new Date(Math.max(...futureSlots.map(Number))) : null;
  const preview = new Map(buildPaymentReminderSchedule(plan.unpaid, pending, parts, {
    now: plan.now, previous,
  }).map((item) => [item.uid, item]));
  return {
    firstDay: FIRST_REMINDER_DAY, lastDay: parts.daysInMonth,
    minIntervalMinutes: MIN_INTERVAL_MINUTES, maxIntervalMinutes: MAX_INTERVAL_MINUTES,
    timezone: "Asia/Jakarta", startTime: "08:00", endTime: "15:00",
    invalidPhoneCount: plan.invalidPhoneCount, adminFallbackCount: plan.adminFallbackCount,
    items: plan.messages.map((item) => {
      const record = plan.records.get(item.uid) || {};
      const active = hasActiveTask(record, plan.now);
      const estimated = preview.get(item.uid);
      const status = record.status === "sent" ? "sent" :
        record.status === "blocked" ? "blocked" :
        record.status === "failed" ? (active ? "retrying" : "failed") :
        active ? record.status : "pending";
      const scheduled = estimated?.scheduledAt || asDate(record.scheduled_at);
      return {
        santriId: item.uid, santriName: item.santriName, type: item.notificationType,
        arrearsCount: item.arrearsCount, months: item.months,
        status, whatsappStatus: record.whatsapp_status || "pending",
        appStatus: record.app_notification_status || "pending",
        adminFallback: record.whatsapp_status === "sent"
          ? Boolean(record.admin_fallback) : Boolean(item.adminFallback),
        scheduledAt: scheduled?.toISOString() || null,
        estimated: Boolean(estimated) || !record.scheduled_at,
        sentAt: asDate(record.whatsapp_sent_at || record.sent_at)?.toISOString() || null,
        intervalMinutes: record.interval_minutes || estimated?.intervalMinutes || 0,
        attempts: Number(record.attempts || 0),
        canSend: !active && (record.status !== "sent" ||
          record.admin_fallback && !item.adminFallback && Boolean(item.phone)) &&
          plan.now >= referenceDate(parts),
      };
    }).sort((a, b) => a.arrearsCount - b.arrearsCount || a.santriName.localeCompare(b.santriName)),
  };
}

async function runManualPaymentReminder(data, overrides = {}) {
  const parts = validMonthParts(data?.year, data?.month);
  const now = overrides.now || new Date();
  if (now < referenceDate(parts)) {
    throw new HttpsError("failed-precondition", "Pengiriman dimulai tanggal 25 pukul 08.00 WIB.");
  }
  const plan = await loadPaymentReminderPlan(parts, { ...overrides, now });
  const item = plan.messages.find((value) => value.uid === data?.santriId);
  if (!item) throw new HttpsError("failed-precondition", "Santri sudah lunas atau tidak lagi wajib membayar.");
  const reservation = await (overrides.reserve || reserveDelivery)(item, parts, {
    ...overrides, now, manual: true, seed: plan.records.get(item.uid),
  });
  if (reservation.skipped) return { status: reservation.reason };
  await enqueueReservation(reservation, parts, overrides);
  return { status: "queued", scheduledAt: reservation.scheduledAt.toISOString() };
}

async function requireAdmin(request, check = assertAdmin) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Harus login.");
  await check(request.auth.uid);
}

const sendScheduledPaymentWhatsApp = onTaskDispatched({
  region: "asia-southeast2", memory: "256MiB",
  ...(wablasSecrets.length > 0
    ? { secrets: wablasSecrets }
    : {}),
  retryConfig: { maxAttempts: MAX_ATTEMPTS, minBackoffSeconds: 60, maxBackoffSeconds: 600 },
  rateLimits: { maxConcurrentDispatches: 1, maxDispatchesPerSecond: 1 },
}, runScheduledPaymentDelivery);

const getPaymentReminderSchedule = onCall({ ...CALLABLE_OPTIONS, timeoutSeconds: 120 }, async (request) => {
  await requireAdmin(request);
  return paymentReminderDashboard(validMonthParts(request.data?.year, request.data?.month));
});

const sendManualPaymentReminder = onCall({ ...CALLABLE_OPTIONS, timeoutSeconds: 120 }, async (request) => {
  await requireAdmin(request);
  return runManualPaymentReminder(request.data);
});

module.exports = {
  getPaymentReminderSchedule, sendManualPaymentReminder, sendScheduledPaymentWhatsApp,
  runPaymentReminderQueue,
  _private: { claimDelivery, isDuplicateTaskError, loadPaymentReminderPlan, referenceDate,
    runScheduledPaymentDelivery, validMonthParts, validateDelivery, paymentReminderDashboard,
    runManualPaymentReminder, requireAdmin },
};
