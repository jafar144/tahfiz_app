const { getFunctions } = require("firebase-admin/functions");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const { logger } = require("firebase-functions");
const { admin, db } = require("../lib/firebase");
const { assertAdmin } = require("../lib/authz");
const { CALLABLE_OPTIONS } = require("../lib/config");
const {
  fetchPayingSantri,
  computeUnpaidSantri,
} = require("../lib/paymentStatus");
const {
  FIRST_REMINDER_DAY,
  MIN_INTERVAL_MINUTES,
  MAX_INTERVAL_MINUTES,
  buildPaymentReminderSchedule,
  taskIdForRef,
} = require("../lib/paymentReminderSchedule");
const {
  prepareScheduledPaymentMessages,
} = require("./whatsappNotifier");
const {
  isWablasEnabled,
  normalizeWhatsAppPhone,
  sendTextMessages,
} = require("../lib/wablas");

const DELIVERY_COLLECTION = "scheduled_payment_notifications";
const TASK_FUNCTION_NAME =
  "locations/asia-southeast2/functions/sendScheduledPaymentWhatsApp";
const wablasSecrets = Object.values(require("../lib/wablasSecrets"));

function referenceDate(parts) {
  return new Date(
    `${parts.year}-${String(parts.month).padStart(2, "0")}-20T08:00:00+07:00`,
  );
}

function validMonthParts(yearValue, monthValue) {
  const year = Number(yearValue);
  const month = Number(monthValue);
  if (!Number.isInteger(year) || year < 2020 || year > 2100) {
    throw new HttpsError("invalid-argument", "Tahun jadwal tidak valid.");
  }
  if (!Number.isInteger(month) || month < 1 || month > 12) {
    throw new HttpsError("invalid-argument", "Bulan jadwal tidak valid.");
  }
  const daysInMonth = new Date(year, month, 0).getDate();
  return {
    year,
    month,
    day: FIRST_REMINDER_DAY,
    daysInMonth,
    daysRemaining: daysInMonth - FIRST_REMINDER_DAY,
  };
}

async function loadPaymentReminderPlan(parts, overrides = {}) {
  const date = overrides.now || referenceDate(parts);
  const fetchSantri = overrides.fetchPayingSantri || fetchPayingSantri;
  const computeUnpaid = overrides.computeUnpaidSantri || computeUnpaidSantri;
  const prepareMessages =
    overrides.prepareMessages || prepareScheduledPaymentMessages;
  const recipients = await fetchSantri(date);
  const unpaid = await computeUnpaid(parts, date, recipients);
  const prepared = prepareMessages(parts, unpaid, overrides.messageOptions);
  return {
    schedule: buildPaymentReminderSchedule(
      recipients,
      prepared.messages,
      parts,
    ),
    invalidPhoneCount: prepared.invalidPhoneCount,
    adminFallbackCount: prepared.adminFallbackCount,
  };
}

function isDuplicateTaskError(error) {
  const code = String(error?.code || "");
  return code.includes("task-already-exists") || code === "already-exists";
}

async function runPaymentReminderQueue(parts, overrides = {}) {
  if (parts.day < FIRST_REMINDER_DAY) return { skipped: true };
  const enabled =
    overrides.enabled === undefined ? isWablasEnabled() : overrides.enabled;
  if (!enabled) return { skipped: true, reason: "wablas_disabled" };

  const plan = await loadPaymentReminderPlan(parts, overrides);
  const dueToday = plan.schedule.filter((item) => item.day === parts.day);
  const queue =
    overrides.queue || getFunctions().taskQueue(TASK_FUNCTION_NAME);
  let queued = 0;
  let duplicate = 0;

  for (const item of dueToday) {
    try {
      await queue.enqueue(
        {
          phone: item.phone,
          message: item.message,
          refId: item.refId,
          notificationType: item.notificationType,
          scheduledAt: item.scheduledAt.toISOString(),
        },
        {
          id: taskIdForRef(item.refId),
          scheduleTime: item.scheduledAt,
          dispatchDeadlineSeconds: 60,
        },
      );
      queued += 1;
    } catch (error) {
      if (!isDuplicateTaskError(error)) throw error;
      duplicate += 1;
    }
  }

  logger.info(
    `[paymentReminderQueue] tanggal ${parts.day}: antre ${queued}, ` +
      `duplikat ${duplicate}, nomor invalid ${plan.invalidPhoneCount}.`,
  );
  return {
    queued,
    duplicate,
    scheduledToday: dueToday.length,
    invalidPhone: plan.invalidPhoneCount,
    adminFallback: plan.adminFallbackCount,
  };
}

function validateDelivery(data) {
  const phone = normalizeWhatsAppPhone(data?.phone);
  const message = String(data?.message || "").trim();
  const refId = String(data?.refId || "").trim();
  const notificationType = String(data?.notificationType || "").trim();
  if (!phone || !message || message.length > 5000) {
    throw new Error("Payload reminder pembayaran tidak valid.");
  }
  if (!/^[A-Za-z0-9_-]{1,240}$/.test(refId)) {
    throw new Error("Reference ID reminder pembayaran tidak valid.");
  }
  if (
    ![
      "arrears",
      "two-month-arrears",
      "current-month-payment",
    ].includes(notificationType)
  ) {
    throw new Error("Tipe reminder pembayaran tidak valid.");
  }
  return { phone, message, refId, notificationType };
}

async function claimDelivery(delivery, overrides = {}) {
  const firestore = overrides.firestore || db;
  const now = overrides.now || new Date();
  const ref = firestore.collection(DELIVERY_COLLECTION).doc(delivery.refId);
  return firestore.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const current = snapshot.data() || {};
    if (current.status === "sent") return "sent";
    const leaseUntil = current.lease_until?.toDate?.();
    if (
      current.status === "sending" &&
      leaseUntil &&
      leaseUntil.getTime() > now.getTime()
    ) {
      return "busy";
    }
    transaction.set(
      ref,
      {
        ref_id: delivery.refId,
        notification_type: delivery.notificationType,
        status: "sending",
        attempts: admin.firestore.FieldValue.increment(1),
        lease_until: admin.firestore.Timestamp.fromDate(
          new Date(now.getTime() + 2 * 60 * 1000),
        ),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return "claimed";
  });
}

async function runScheduledPaymentDelivery(request, overrides = {}) {
  const delivery = validateDelivery(request.data);
  const claim = overrides.claim || claimDelivery;
  const claimStatus = await claim(delivery, overrides);
  if (claimStatus === "sent") return { duplicate: true };
  if (claimStatus === "busy") {
    throw new Error("Pengiriman reminder masih diproses.");
  }

  const send = overrides.send || sendTextMessages;
  const firestore = overrides.firestore || db;
  const ref = firestore.collection(DELIVERY_COLLECTION).doc(delivery.refId);
  try {
    await send([delivery]);
    await ref.set(
      {
        status: "sent",
        sent_at: admin.firestore.FieldValue.serverTimestamp(),
        lease_until: admin.firestore.FieldValue.delete(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return { sent: true };
  } catch (error) {
    await ref.set(
      {
        status: "failed",
        last_error_code: String(error?.code || "provider_error").slice(0, 80),
        lease_until: admin.firestore.FieldValue.delete(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    throw error;
  }
}

const sendScheduledPaymentWhatsApp = onTaskDispatched(
  {
    region: "asia-southeast2",
    memory: "256MiB",
    secrets: wablasSecrets,
    retryConfig: {
      maxAttempts: 5,
      minBackoffSeconds: 60,
      maxBackoffSeconds: 600,
    },
    rateLimits: { maxConcurrentDispatches: 1, maxDispatchesPerSecond: 1 },
  },
  runScheduledPaymentDelivery,
);

const getPaymentReminderSchedule = onCall(CALLABLE_OPTIONS, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Harus login.");
  }
  await assertAdmin(request.auth.uid);
  const parts = validMonthParts(request.data?.year, request.data?.month);
  const plan = await loadPaymentReminderPlan(parts);
  return {
    firstDay: FIRST_REMINDER_DAY,
    lastDay: parts.daysInMonth,
    minIntervalMinutes: MIN_INTERVAL_MINUTES,
    maxIntervalMinutes: MAX_INTERVAL_MINUTES,
    timezone: "Asia/Jakarta",
    invalidPhoneCount: plan.invalidPhoneCount,
    adminFallbackCount: plan.adminFallbackCount,
    items: plan.schedule.map((item) => ({
      santriId: item.uid,
      santriName: item.santriName,
      type: item.notificationType,
      scheduledAt: item.scheduledAt.toISOString(),
      intervalMinutes: item.intervalMinutes,
    })),
  };
});

module.exports = {
  getPaymentReminderSchedule,
  sendScheduledPaymentWhatsApp,
  runPaymentReminderQueue,
  _private: {
    claimDelivery,
    isDuplicateTaskError,
    loadPaymentReminderPlan,
    referenceDate,
    runScheduledPaymentDelivery,
    validMonthParts,
    validateDelivery,
  },
};
