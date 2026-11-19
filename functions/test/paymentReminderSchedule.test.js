"use strict";
const assert = require("node:assert/strict");
const test = require("node:test");
const { admin } = require("../lib/firebase");
const {
  buildPaymentReminderSchedule, reminderRefId, nextDeliverySlot, inDeliveryWindow,
} = require("../lib/paymentReminderSchedule");
const {
  DELIVERY_COLLECTION, reserveDelivery, loadDeliveryRecords,
} = require("../lib/paymentReminderStore");
const {
  runPaymentReminderQueue,
  _private: {
    runScheduledPaymentDelivery, paymentReminderDashboard, runManualPaymentReminder,
    requireAdmin, validMonthParts,
  },
} = require("../handlers/paymentReminderScheduler");

const parts = validMonthParts(2026, 10);
const start = new Date("2026-10-25T08:00:00+07:00");
const institution = { institutionName: "Uji", bankName: "BSI", accountNumber: "123", accountHolder: "Uji" };
const ts = (date) => admin.firestore.Timestamp.fromDate(new Date(date));
function santri(i, count = 1) {
  return { uid: `santri-${i}`, name: `Santri ${i}`, nis: String(i),
    nomorWali: "081234567890", tanggalMasuk: new Date("2025-01-01"),
    count, months: Array.from({ length: count }, (_, offset) => ({ year: 2026, month: 11 - count + offset })) };
}
function item(s) {
  return { ...s, recipientUid: s.uid, notificationType: "current-month-payment",
    refId: reminderRefId(parts, s.uid), phone: "6281234567890", message: "Pengingat",
    pushNotification: { title: "SPP", body: "Belum dibayar" }, adminFallback: false };
}
function fakeFirestore() {
  const data = new Map();
  let serial = Promise.resolve();
  function put(path, patch, merge = true) {
    const current = merge ? { ...(data.get(path) || {}) } : {};
    for (const [key, value] of Object.entries(patch)) {
      const type = value?.constructor?.name;
      if (type === "DeleteTransform") delete current[key];
      else if (type === "NumericIncrementTransform") current[key] = Number(current[key] || 0) + value.operand;
      else if (type === "ServerTimestampTransform") current[key] = ts(start);
      else current[key] = value;
    }
    data.set(path, current);
  }
  const snapshot = (path) => ({ id: path.split("/").at(-1), exists: data.has(path), data: () => data.get(path) });
  return {
    data, put,
    collection(name) {
      let lower = "", upper = "\uffff";
      const query = {
        doc(id) { return { path: `${name}/${id}`, get: async () => snapshot(`${name}/${id}`),
          set: async (patch, options) => put(`${name}/${id}`, patch, options?.merge) }; },
        orderBy() { return query; },
        startAt(value) { lower = value; return query; },
        endAt(value) { upper = value; return query; },
        async get() {
          return { docs: [...data.keys()].filter((path) => path.startsWith(name + "/"))
            .filter((path) => { const id = path.split("/").at(-1); return id >= lower && id <= upper; })
            .map(snapshot) };
        },
      };
      return query;
    },
    runTransaction(callback) {
      const result = serial.then(async () => {
        const writes = [];
        const value = await callback({
          get: async (ref) => snapshot(ref.path),
          set: (ref, patch, options) => writes.push([ref.path, patch, options?.merge]),
        });
        writes.forEach((args) => put(...args));
        return value;
      });
      serial = result.catch(() => {});
      return result;
    },
  };
}
function dependencies(recipients, firestore = fakeFirestore(), now = start) {
  const calls = [];
  const options = {
    firestore, now, enabled: true,
    fetchPayingSantri: async () => recipients,
    computeUnpaidSantri: async () => recipients,
    messageOptions: { institution, adminPhone: "" },
    queue: { enqueue: async (data, config) => calls.push({ data, config }) },
  };
  return { options, calls, firestore };
}
function task(reservation, period = parts) {
  return { data: { recipientUid: reservation.recipient_uid, refId: reservation.refId,
    year: period.year, month: period.month, generation: reservation.generation } };
}

test("80 penerima mengisi hari pertama, sisa langsung ke hari kedua; jeda 1–15 menit", () => {
  const recipients = Array.from({ length: 80 }, (_, i) => santri(i));
  const schedule = buildPaymentReminderSchedule(recipients, recipients.map(item), parts);
  assert.equal(schedule.length, 80);
  assert.deepEqual(new Set(schedule.map((x) => x.day)), new Set([25, 26]));
  const firstDay = schedule.filter((x) => x.day === 25);
  assert.ok(firstDay.length > 40);
  assert.ok(firstDay.at(-1).hour === 14 && firstDay.at(-1).minute >= 45);
  for (let i = 0; i < schedule.length; i++) {
    assert.ok(inDeliveryWindow(schedule[i].scheduledAt));
    assert.ok(schedule[i].intervalMinutes >= 1 && schedule[i].intervalMinutes <= 15);
    if (i && schedule[i].day === schedule[i - 1].day) {
      assert.equal((schedule[i].scheduledAt - schedule[i - 1].scheduledAt) / 60000, schedule[i].intervalMinutes);
    }
  }
  assert.deepEqual(schedule, buildPaymentReminderSchedule([...recipients].reverse(), recipients.map(item).reverse(), parts));
});

test("batas 15.00, sebelum 08.00, Februari, dan pergantian tahun memakai WIB", () => {
  assert.equal(nextDeliverySlot(new Date("2026-10-25T14:59:00+07:00"), null, 1).toISOString(), "2026-10-26T01:01:00.000Z");
  assert.equal(nextDeliverySlot(new Date("2026-12-31T23:00:00+07:00"), null, 15).toISOString(), "2027-01-01T01:15:00.000Z");
  assert.equal(nextDeliverySlot(new Date("2026-02-28T07:00:00+07:00"), null, 1).toISOString(), "2026-02-28T01:01:00.000Z");
  assert.equal(inDeliveryWindow(new Date("2026-10-25T15:00:00+07:00")), false);
  const recipients = Array.from({ length: 500 }, (_, i) => santri(i));
  const schedule = buildPaymentReminderSchedule(recipients, recipients.map(item), validMonthParts(2026, 2));
  assert.ok(schedule.length < 500);
  assert.ok(schedule.every((x) => x.day >= 25 && x.day <= 28));
});

test("scheduler hanya mulai tanggal 25; 80 santri lanjut besok tanpa menduplikasi yang selesai", async () => {
  const recipients = Array.from({ length: 80 }, (_, i) => santri(i));
  const env = dependencies(recipients);
  assert.deepEqual(await runPaymentReminderQueue(parts, { ...env.options, now: new Date("2026-10-24T08:00:00+07:00") }), { skipped: true });
  await runPaymentReminderQueue(parts, env.options);
  const first = [...env.calls];
  assert.ok(first.length > 40 && first.length < 80);
  for (const call of first) {
    env.firestore.put(`${DELIVERY_COLLECTION}/${call.data.refId}`, { status: "sent", whatsapp_status: "sent" });
  }
  await runPaymentReminderQueue(parts, { ...env.options, now: new Date("2026-10-26T08:00:00+07:00") });
  assert.equal(env.calls.length, 80);
  assert.equal(new Set(env.calls.map((x) => x.data.refId)).size, 80);
});

test("catch-up menjalankan penerima belum terkirim walaupun baru aktif tanggal 29", async () => {
  const env = dependencies([santri(1), santri(2)], undefined, new Date("2026-10-29T08:00:00+07:00"));
  await runPaymentReminderQueue(parts, env.options);
  assert.equal(env.calls.length, 2);
  assert.ok(env.calls.every((x) => x.config.scheduleTime.getDate() >= 28));
});

test("retry enqueue menggunakan reservasi dan task ID sama; pemanggilan bersamaan tidak membuat duplikat", async () => {
  const s = santri(1);
  const firestore = fakeFirestore();
  const reservations = await Promise.all([
    reserveDelivery(item(s), parts, { firestore, now: start }),
    reserveDelivery(item(s), parts, { firestore, now: start }),
  ]);
  assert.equal(reservations[0].task_id, reservations[1].task_id);
  assert.equal(reservations[0].scheduledAt.getTime(), reservations[1].scheduledAt.getTime());
  const env = dependencies([s], firestore);
  let fail = true;
  const enqueue = env.options.queue.enqueue;
  env.options.queue.enqueue = async (...args) => { if (fail) { fail = false; throw new Error("enqueue offline"); } return enqueue(...args); };
  await assert.rejects(runPaymentReminderQueue(parts, env.options), /offline/);
  await runPaymentReminderQueue(parts, env.options);
  assert.equal(env.calls[0].config.id, reservations[0].task_id);
});

test("worker memeriksa pelunasan sebelum mengirim WA maupun notifikasi", async () => {
  const env = dependencies([santri(1)]);
  const reservation = await reserveDelivery(item(santri(1)), parts, env.options);
  let sent = 0;
  const result = await runScheduledPaymentDelivery(task(reservation), {
    ...env.options, loadPlan: async () => ({ messages: [] }),
    send: async () => sent++, sendPush: async () => sent++,
  });
  assert.equal(result.reason, "paid_or_inactive");
  assert.equal(sent, 0);
  assert.equal(env.firestore.data.get(`${DELIVERY_COLLECTION}/${reservation.refId}`).status, "cancelled");
});

test("worker di luar jam menunda kedua kanal dan scheduler besok melanjutkan", async () => {
  const env = dependencies([santri(1)]);
  const reservation = await reserveDelivery(item(santri(1)), parts, env.options);
  const result = await runScheduledPaymentDelivery(task(reservation), {
    ...env.options, now: new Date("2026-10-25T15:01:00+07:00"),
    send: async () => assert.fail("tidak boleh kirim di luar jam"),
    loadPlan: async () => assert.fail("tidak perlu query pembayaran"),
  });
  assert.deepEqual(result, { deferred: true });
  await runPaymentReminderQueue(parts, { ...env.options, now: new Date("2026-10-26T08:00:00+07:00") });
  assert.equal(env.calls[0].data.generation, 2);
});

test("retry aplikasi tidak mengirim WA lagi; kegagalan WA tidak menghalangi aplikasi", async () => {
  for (const failing of ["app", "wa"]) {
    const env = dependencies([santri(1)]);
    const reservation = await reserveDelivery(item(santri(1)), parts, env.options);
    let wa = 0, app = 0, fail = true;
    const options = {
      ...env.options, loadPlan: async () => ({ messages: [item(santri(1))] }),
      send: async () => { wa++; if (failing === "wa" && fail) throw new Error("WA gagal"); },
      sendPush: async () => { app++; if (failing === "app" && fail) throw new Error("FCM gagal"); return { successCount: 1, failureCount: 0 }; },
    };
    await assert.rejects(runScheduledPaymentDelivery(task(reservation), options));
    fail = false;
    await runScheduledPaymentDelivery(task(reservation), options);
    assert.equal(wa, failing === "wa" ? 2 : 1);
    assert.equal(app, failing === "app" ? 2 : 1);
    const again = await runScheduledPaymentDelivery(task(reservation), options);
    assert.deepEqual(again, { duplicate: true });
  }
});

test("FCM tanpa perangkat berbeda dari FCM gagal, WA nonaktif tetap mengirim notifikasi", async () => {
  const env = dependencies([santri(1)]);
  const reservation = await reserveDelivery(item(santri(1)), parts, env.options);
  await runScheduledPaymentDelivery(task(reservation), {
    ...env.options, enabled: false, loadPlan: async () => ({ messages: [item(santri(1))] }),
    send: async () => assert.fail("WA nonaktif"),
    sendPush: async () => ({ successCount: 0, failureCount: 0 }),
  });
  const record = env.firestore.data.get(`${DELIVERY_COLLECTION}/${reservation.refId}`);
  assert.equal(record.status, "blocked");
  assert.equal(record.app_notification_status, "no-device");
  assert.equal(record.whatsapp_status, "disabled");
});

test("status admin mengelompokkan jumlah bulan aktual, termasuk 1 bulan lampau dan nomor invalid", async () => {
  const recipients = [santri(1), santri(2, 2), santri(3, 3), { ...santri(4), months: [{ year: 2026, month: 9 }], nomorWali: "" }];
  const env = dependencies(recipients);
  const dashboard = await paymentReminderDashboard(parts, env.options);
  assert.equal(dashboard.items.length, 4);
  assert.deepEqual(dashboard.items.map((x) => x.arrearsCount).sort(), [1, 1, 2, 3]);
  assert.ok(dashboard.items.every((x) => x.status === "pending"));
  assert.ok(dashboard.items.find((x) => x.santriId === "santri-4"));
  assert.equal((await paymentReminderDashboard(parts, dependencies([]).options)).items.length, 0);
});

test("riwayat legacy tetap muncul dan tidak dikirim ulang setelah kategori berubah", async () => {
  const env = dependencies([santri(1, 2)]);
  env.firestore.put(`${DELIVERY_COLLECTION}/arrears-2026-10-santri-1`, { status: "sent", sent_at: ts(start) });
  const dashboard = await paymentReminderDashboard(parts, env.options);
  assert.equal(dashboard.items[0].status, "sent");
  assert.equal(dashboard.items[0].canSend, false);
  await runPaymentReminderQueue(parts, env.options);
  assert.equal(env.calls.length, 0);
  assert.equal((await loadDeliveryRecords(parts, [santri(1)], env.firestore)).size, 1);
});

test("pengiriman manual periode lalu tetap dijadwalkan dalam WIB dan memakai ulang kanal sukses", async () => {
  const env = dependencies([santri(1)], undefined, new Date("2026-11-01T16:00:00+07:00"));
  env.firestore.put(`${DELIVERY_COLLECTION}/payment-2026-10-santri-1`, {
    status: "failed", generation: 1, cycle_attempts: 5, whatsapp_status: "sent",
    app_notification_status: "failed", scheduled_at: ts(start),
  });
  const result = await runManualPaymentReminder({ year: 2026, month: 10, santriId: "santri-1" }, env.options);
  assert.equal(result.status, "queued");
  assert.ok(result.scheduledAt.startsWith("2026-11-02T01:"));
  assert.equal(env.calls[0].data.generation, 2);
  const record = env.firestore.data.get(`${DELIVERY_COLLECTION}/payment-2026-10-santri-1`);
  assert.equal(record.whatsapp_status, "sent");
  assert.equal(record.manual, true);
  const old = await runScheduledPaymentDelivery({ data: { ...env.calls[0].data, generation: 1 } }, env.options);
  assert.deepEqual(old, { duplicate: true });
});

test("manual menolak santri lunas/periode sebelum tanggal 25; auth wajib admin", async () => {
  await assert.rejects(runManualPaymentReminder({ year: 2026, month: 10, santriId: "s" },
    dependencies([], undefined, new Date("2026-10-24")).options), /tanggal 25/);
  await assert.rejects(runManualPaymentReminder({ year: 2026, month: 10, santriId: "s" },
    dependencies([]).options), /lunas/);
  await assert.rejects(requireAdmin({}, async () => assert.fail()), { code: "unauthenticated" });
  await assert.rejects(requireAdmin({ auth: { uid: "santri" } }, async () => {
    const error = new Error("Admin saja"); error.code = "permission-denied"; throw error;
  }), { code: "permission-denied" });
  let checked;
  await requireAdmin({ auth: { uid: "admin" } }, async (uid) => { checked = uid; });
  assert.equal(checked, "admin");
});

test("lima kegagalan berhenti otomatis, admin dapat mengulang kanal yang gagal", async () => {
  const env = dependencies([santri(1)]);
  const reservation = await reserveDelivery(item(santri(1)), parts, env.options);
  let pushCalls = 0;
  for (let attempt = 0; attempt < 5; attempt++) {
    await assert.rejects(runScheduledPaymentDelivery(task(reservation), {
      ...env.options, loadPlan: async () => ({ messages: [item(santri(1))] }),
      send: async () => { throw new Error("provider offline"); },
      sendPush: async () => { pushCalls++; return { successCount: 1, failureCount: 0 }; },
    }), /offline/);
  }
  assert.equal(pushCalls, 1);
  const record = env.firestore.data.get(`${DELIVERY_COLLECTION}/${reservation.refId}`);
  assert.equal(record.cycle_attempts, 5);
  const nextDay = { ...env.options, now: new Date("2026-10-26T08:00:00+07:00") };
  await runPaymentReminderQueue(parts, nextDay);
  assert.equal(env.calls.length, 0);
  assert.equal((await paymentReminderDashboard(parts, nextDay)).items[0].status, "failed");
  await runManualPaymentReminder({ year: 2026, month: 10, santriId: "santri-1" }, nextDay);
  assert.equal(env.calls.length, 1);
  assert.equal(env.calls[0].data.generation, 2);
});

test("nomor invalid tetap mendapatkan notifikasi; koreksi nomor fallback dapat dikirim ke wali", async () => {
  const env = dependencies([santri(1)]);
  const reservation = await reserveDelivery(item(santri(1)), parts, env.options);
  const deliveryItem = { ...item(santri(1)), phone: null };
  await runScheduledPaymentDelivery(task(reservation), {
    ...env.options, loadPlan: async () => ({ messages: [deliveryItem] }),
    send: async () => assert.fail("nomor kosong"),
    sendPush: async () => ({ successCount: 1, failureCount: 0 }),
  });
  let record = env.firestore.data.get(`${DELIVERY_COLLECTION}/${reservation.refId}`);
  assert.equal(record.whatsapp_status, "invalid-phone");
  assert.equal(record.app_notification_status, "sent");
  env.firestore.put(`${DELIVERY_COLLECTION}/${reservation.refId}`, {
    status: "sent", whatsapp_status: "sent", admin_fallback: true,
    whatsapp_sent_at: ts(start), sent_at: ts(start),
  });
  const dashboard = await paymentReminderDashboard(parts, env.options);
  assert.equal(dashboard.items[0].adminFallback, true);
  assert.equal(dashboard.items[0].canSend, true);
  await runManualPaymentReminder({ year: 2026, month: 10, santriId: "santri-1" }, env.options);
  record = env.firestore.data.get(`${DELIVERY_COLLECTION}/${reservation.refId}`);
  assert.equal(record.whatsapp_status, "pending");
  assert.equal(record.app_notification_status, "sent");
  assert.equal(record.whatsapp_sent_at, undefined);
  assert.equal(record.sent_at, undefined);
});

test("susulan manual yang retry lewat jam 15 berlanjut esok meski periode bulan lalu", async () => {
  const env = dependencies([santri(1)], undefined, new Date("2026-11-01T08:00:00+07:00"));
  await runManualPaymentReminder({ year: 2026, month: 10, santriId: "santri-1" }, env.options);
  const old = env.calls[0];
  await runScheduledPaymentDelivery({ data: old.data }, {
    ...env.options, now: new Date("2026-11-01T15:30:00+07:00"),
  });
  assert.equal(env.calls.length, 2);
  assert.ok(env.calls[1].config.scheduleTime.toISOString().startsWith("2026-11-02T01:"));
  assert.equal(env.calls[1].data.generation, 2);
});

test("pembayaran sebagian memperbarui isi pesan saat kirim, tanpa mengubah identitas reminder", async () => {
  const env = dependencies([santri(1, 3)]);
  const reservation = await reserveDelivery(item(santri(1, 3)), parts, env.options);
  let message;
  await runScheduledPaymentDelivery(task(reservation), {
    ...env.options, loadPlan: async () => ({ messages: [{ ...item(santri(1)), message: "Tinggal Oktober" }] }),
    send: async (messages) => { message = messages[0]; },
    sendPush: async () => ({ successCount: 1, failureCount: 0 }),
  });
  assert.equal(message.message, "Tinggal Oktober");
  assert.equal(message.refId, reservation.refId);
});

test("error pemeriksaan pembayaran melepaskan lease dan terlihat gagal untuk retry", async () => {
  const env = dependencies([santri(1)]);
  const reservation = await reserveDelivery(item(santri(1)), parts, env.options);
  await assert.rejects(runScheduledPaymentDelivery(task(reservation), {
    ...env.options, loadPlan: async () => { throw new Error("Firestore offline"); },
  }), /offline/);
  const record = env.firestore.data.get(`${DELIVERY_COLLECTION}/${reservation.refId}`);
  assert.equal(record.status, "failed");
  assert.equal(record.lease_until, undefined);
});

test("pemeriksaan yang melewati pukul 15 menunda pengiriman; WA lambat menunda aplikasi", async () => {
  for (const crossesDuring of ["read", "wa"]) {
    const env = dependencies([santri(1)]);
    const reservation = await reserveDelivery(item(santri(1)), parts, env.options);
    let current = new Date("2026-10-25T14:59:59+07:00");
    let wa = 0;
    const late = () => { current = new Date("2026-10-25T15:00:01+07:00"); };
    const result = await runScheduledPaymentDelivery(task(reservation), {
      ...env.options, clock: () => current,
      loadPlan: async () => { if (crossesDuring === "read") late(); return { messages: [item(santri(1))] }; },
      send: async () => { wa++; late(); },
      sendPush: async () => assert.fail("notifikasi tidak boleh mulai setelah 15.00"),
    });
    assert.equal(result.deferred, true);
    assert.equal(wa, crossesDuring === "wa" ? 1 : 0);
  }
});
