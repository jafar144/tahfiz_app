"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  buildPaymentReminderSchedule,
  taskIdForRef,
} = require("../lib/paymentReminderSchedule");
const {
  prepareScheduledPaymentMessages,
} = require("../handlers/whatsappNotifier");
const {
  runPaymentReminderQueue,
  _private: { runScheduledPaymentDelivery, validateDelivery },
} = require("../handlers/paymentReminderScheduler");

const parts = {
  year: 2026,
  month: 9,
  day: 20,
  daysInMonth: 30,
  daysRemaining: 10,
};
const institution = {
  institutionName: "Lembaga Uji",
  bankName: "BSI",
  accountNumber: "123",
  accountHolder: "Bendahara",
};

function santri(index) {
  return {
    uid: `santri-${index}`,
    name: `Santri ${index}`,
    nis: String(1000 + index),
    nomorWali: `081200000${String(index).padStart(3, "0")}`,
    tanggalMasuk: new Date("2025-01-01T00:00:00+07:00"),
  };
}

test("jadwal deterministik tersebar tanggal 20-akhir dengan interval 1-10 menit", () => {
  const recipients = Array.from({ length: 80 }, (_, index) => santri(index));
  const messages = recipients.map((item) => ({
    recipientUid: item.uid,
    santriName: item.name,
    notificationType: "current-month-payment",
    phone: item.nomorWali,
    message: `Pesan ${item.uid}`,
    refId: `current-month-payment-2026-09-${item.uid}`,
  }));

  const first = buildPaymentReminderSchedule(recipients, messages, parts);
  const reordered = buildPaymentReminderSchedule(
    [...recipients].reverse(),
    [...messages].reverse(),
    parts,
  );

  assert.equal(first.length, recipients.length);
  assert.deepEqual(
    first.map(({ uid, scheduledAt }) => [uid, scheduledAt.toISOString()]),
    reordered.map(({ uid, scheduledAt }) => [uid, scheduledAt.toISOString()]),
  );
  assert.equal(new Set(first.map((item) => item.uid)).size, first.length);
  for (const item of first) {
    assert.ok(item.day >= 20 && item.day <= 30);
    assert.ok(item.intervalMinutes >= 1 && item.intervalMinutes <= 10);
  }
  assert.ok(new Set(first.map((item) => item.day)).size > 1);
});

test("interval 1-10 menit dihitung hanya antar penerima aktual", () => {
  const recipients = Array.from({ length: 1000 }, (_, index) => santri(index));
  const allMessages = recipients.map((item) => ({
    recipientUid: item.uid,
    santriName: item.name,
    notificationType: "current-month-payment",
    phone: item.nomorWali,
    message: `Pesan ${item.uid}`,
    refId: `current-month-payment-2026-09-${item.uid}`,
  }));
  const fullSchedule = buildPaymentReminderSchedule(
    recipients,
    allMessages,
    parts,
  );
  const byDay = Map.groupBy(fullSchedule, (item) => item.day);
  const denseDay = [...byDay.values()].find((items) => items.length > 11);
  assert.ok(denseDay);

  const selected = [denseDay[0], denseDay[denseDay.length - 1]];
  assert.ok(
    (selected[1].scheduledAt - selected[0].scheduledAt) / 60_000 > 10,
  );
  const selectedIds = new Set(selected.map((item) => item.uid));
  const actualSchedule = buildPaymentReminderSchedule(
    recipients,
    allMessages.filter((message) => selectedIds.has(message.recipientUid)),
    parts,
  );

  assert.equal(actualSchedule.length, 2);
  assert.equal(actualSchedule[0].day, selected[0].day);
  assert.equal(actualSchedule[1].day, selected[1].day);
  const actualGapMinutes =
    (actualSchedule[1].scheduledAt - actualSchedule[0].scheduledAt) / 60_000;
  assert.ok(actualGapMinutes >= 1 && actualGapMinutes <= 10);
});

test("setiap kategori pembayaran saling eksklusif", () => {
  const twoMonth = {
    ...santri(1),
    months: [
      { year: 2026, month: 8 },
      { year: 2026, month: 9 },
    ],
  };
  const long = {
    ...santri(2),
    months: [
      { year: 2026, month: 7 },
      { year: 2026, month: 8 },
      { year: 2026, month: 9 },
    ],
  };
  const current = {
    ...santri(3),
    months: [{ year: 2026, month: 9 }],
  };
  const prepared = prepareScheduledPaymentMessages(
    parts,
    [twoMonth, long, current],
    {
      institution,
      adminPhone: "",
    },
  );

  assert.equal(prepared.messages.length, 3);
  assert.deepEqual(
    prepared.messages.map((message) => message.notificationType).sort(),
    ["arrears", "current-month-payment", "two-month-arrears"],
  );
  assert.equal(
    new Set(prepared.messages.map((message) => message.recipientUid)).size,
    3,
  );
  for (const message of prepared.messages) {
    assert.equal(message.pushNotification.title, "Pengingat Pembayaran SPP");
    assert.equal(message.pushNotification.data.type, "payment_arrears");
  }
});

test("scheduler hanya mengantre slot hari ini dengan task id idempoten", async () => {
  const recipient = santri(1);
  const messages = [
    {
      recipientUid: recipient.uid,
      santriName: recipient.name,
      notificationType: "current-month-payment",
      phone: recipient.nomorWali,
      message: "Pengingat pembayaran",
      refId: "current-month-payment-2026-09-santri-1",
      pushNotification: {
        title: "Pengingat Pembayaran SPP",
        body: "Pembayaran belum kami terima.",
        data: { type: "payment_arrears" },
      },
    },
  ];
  const schedule = buildPaymentReminderSchedule([recipient], messages, parts);
  const queueCalls = [];
  const result = await runPaymentReminderQueue(
    { ...parts, day: schedule[0].day },
    {
      enabled: true,
      fetchPayingSantri: async () => [recipient],
      computeUnpaidSantri: async () => [recipient],
      prepareMessages: () => ({
        messages,
        invalidPhoneCount: 0,
        adminFallbackCount: 0,
      }),
      queue: {
        async enqueue(data, options) {
          queueCalls.push({ data, options });
        },
      },
    },
  );

  assert.equal(result.queued, 1);
  assert.equal(queueCalls.length, 1);
  assert.equal(
    queueCalls[0].options.id,
    taskIdForRef("current-month-payment-2026-09-santri-1"),
  );
  assert.equal(queueCalls[0].data.recipientUid, recipient.uid);
  assert.equal(
    queueCalls[0].data.pushNotification.data.type,
    "payment_arrears",
  );
});

test("worker menerima tipe reminder tunggakan dua bulan", () => {
  const delivery = validateDelivery({
    phone: "081234567890",
    message: "Tunggakan dua bulan",
    refId: "two-month-arrears-2026-09-santri-1",
    notificationType: "two-month-arrears",
  });

  assert.equal(delivery.notificationType, "two-month-arrears");
});

test("worker tidak mengirim ulang delivery yang sudah terkirim", async () => {
  let sendCalls = 0;
  const result = await runScheduledPaymentDelivery(
    {
      data: {
        phone: "081234567890",
        message: "Pengingat pembayaran",
        refId: "current-month-payment-2026-09-santri-1",
        notificationType: "current-month-payment",
      },
    },
    {
      claim: async () => "sent",
      send: async () => {
        sendCalls += 1;
      },
    },
  );

  assert.deepEqual(result, { duplicate: true });
  assert.equal(sendCalls, 0);
});

test("worker mengirim WhatsApp dan notifikasi HP pada task yang sama", async () => {
  let whatsappCalls = 0;
  let pushCalls = 0;
  const patches = [];
  const result = await runScheduledPaymentDelivery(
    {
      data: {
        recipientUid: "santri-1",
        phone: "081234567890",
        message: "Pengingat pembayaran",
        refId: "current-month-payment-2026-09-santri-1",
        notificationType: "current-month-payment",
        pushNotification: {
          title: "Pengingat Pembayaran SPP",
          body: "Pembayaran belum kami terima.",
          data: { type: "payment_arrears" },
        },
      },
    },
    {
      claim: async () => ({ status: "claimed" }),
      send: async () => {
        whatsappCalls += 1;
      },
      sendPush: async (uid, notification) => {
        pushCalls += 1;
        assert.equal(uid, "santri-1");
        assert.equal(notification.data.type, "payment_arrears");
        return { successCount: 1, failureCount: 0 };
      },
      persist: async (patch) => patches.push(patch),
    },
  );

  assert.equal(whatsappCalls, 1);
  assert.equal(pushCalls, 1);
  assert.equal(result.sent, true);
  assert.equal(result.appNotification.status, "sent");
  assert.ok(patches.some((patch) => patch.whatsapp_status === "sent"));
  assert.ok(
    patches.some((patch) => patch.app_notification_status === "sent"),
  );
  assert.equal(patches.at(-1).status, "sent");
});

test("retry notifikasi HP tidak mengirim ulang WhatsApp", async () => {
  let whatsappCalls = 0;
  let pushCalls = 0;
  const result = await runScheduledPaymentDelivery(
    {
      data: {
        recipientUid: "santri-1",
        phone: "081234567890",
        message: "Pengingat pembayaran",
        refId: "current-month-payment-2026-09-santri-1",
        notificationType: "current-month-payment",
        pushNotification: {
          title: "Pengingat Pembayaran SPP",
          body: "Pembayaran belum kami terima.",
          data: { type: "payment_arrears" },
        },
      },
    },
    {
      claim: async () => ({
        status: "claimed",
        whatsappComplete: true,
        appNotificationComplete: false,
      }),
      send: async () => {
        whatsappCalls += 1;
      },
      sendPush: async () => {
        pushCalls += 1;
        return { successCount: 1, failureCount: 0 };
      },
      persist: async () => {},
    },
  );

  assert.equal(whatsappCalls, 0);
  assert.equal(pushCalls, 1);
  assert.equal(result.whatsapp, "already-complete");
});
