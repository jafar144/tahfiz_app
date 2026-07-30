const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const {
  ASSESSMENT_JOBS,
  PAYMENT_JOBS,
  assessmentJobNames,
  paymentJobNames,
  runScheduledJobs,
} = require("../lib/notificationSchedule");

test("scheduler penilaian memilih hanya job pada hari yang tepat", () => {
  assert.deepEqual(
    assessmentJobNames({ day: 24, daysRemaining: 6 }),
    [ASSESSMENT_JOBS.windowOpen]
  );
  assert.deepEqual(
    assessmentJobNames({ day: 29, daysRemaining: 1 }),
    [ASSESSMENT_JOBS.incomplete]
  );
  assert.deepEqual(
    assessmentJobNames({ day: 30, daysRemaining: 0 }),
    [ASSESSMENT_JOBS.incomplete]
  );
  assert.deepEqual(assessmentJobNames({ day: 20, daysRemaining: 10 }), []);
});

test("scheduler pembayaran mempertahankan tanggal 5, 15, dan H-3", () => {
  assert.deepEqual(paymentJobNames({ day: 5, daysRemaining: 25 }), [
    PAYMENT_JOBS.paymentDue,
    PAYMENT_JOBS.birthdayWhatsApp,
  ]);
  assert.deepEqual(paymentJobNames({ day: 15, daysRemaining: 15 }), [
    PAYMENT_JOBS.arrearsMidMonth,
    PAYMENT_JOBS.birthdayWhatsApp,
  ]);
  assert.deepEqual(paymentJobNames({ day: 27, daysRemaining: 3 }), [
    PAYMENT_JOBS.arrearsMonthEnd,
    PAYMENT_JOBS.birthdayWhatsApp,
  ]);
  assert.deepEqual(paymentJobNames({ day: 10, daysRemaining: 20 }), [
    PAYMENT_JOBS.birthdayWhatsApp,
  ]);
});

test("koordinator menjalankan hanya runner terpilih dan meneruskan tanggal", async () => {
  const parts = { day: 5, month: 7, year: 2026, daysRemaining: 26 };
  const calls = [];
  const result = await runScheduledJobs(
    [PAYMENT_JOBS.paymentDue],
    {
      [PAYMENT_JOBS.paymentDue]: async (received) => {
        calls.push([PAYMENT_JOBS.paymentDue, received]);
        return { notified: 4 };
      },
      [PAYMENT_JOBS.arrearsMidMonth]: async () => {
        calls.push([PAYMENT_JOBS.arrearsMidMonth]);
      },
    },
    parts
  );

  assert.deepEqual(calls, [[PAYMENT_JOBS.paymentDue, parts]]);
  assert.deepEqual(result, {
    skipped: false,
    jobs: { [PAYMENT_JOBS.paymentDue]: { notified: 4 } },
  });
});

test("koordinator melewati hari kosong tanpa memanggil runner", async () => {
  const result = await runScheduledJobs([], {}, { day: 10 });
  assert.deepEqual(result, { skipped: true, jobs: {} });
});

test("handler gabungan meneruskan hanya job yang dipilih planner", async () => {
  const {
    runAssessmentNotifications,
  } = require("../handlers/assessmentNotifier");
  const { runPaymentNotifications } = require("../handlers/paymentNotifier");
  const calls = [];

  await runAssessmentNotifications(
    { day: 25, month: 7, year: 2026, daysRemaining: 6 },
    {
      [ASSESSMENT_JOBS.windowOpen]: async () => {
        calls.push(ASSESSMENT_JOBS.windowOpen);
        return { notified: 2 };
      },
    }
  );
  await runPaymentNotifications(
    { day: 15, month: 7, year: 2026, daysRemaining: 16 },
    {
      [PAYMENT_JOBS.arrearsMidMonth]: async () => {
        calls.push(PAYMENT_JOBS.arrearsMidMonth);
        return { notified: 3 };
      },
      [PAYMENT_JOBS.birthdayWhatsApp]: async () => {
        calls.push(PAYMENT_JOBS.birthdayWhatsApp);
        return { sent: 1 };
      },
    }
  );

  assert.deepEqual(calls, [
    ASSESSMENT_JOBS.windowOpen,
    PAYMENT_JOBS.arrearsMidMonth,
    PAYMENT_JOBS.birthdayWhatsApp,
  ]);
});

test("reminder tanggal 3 dikirim sebagai pesan grup ke seluruh ID terisi", async () => {
  const {
    runMonthlyGroupReminder,
  } = require("../handlers/monthlyGroupNotifier");
  let sent;
  const result = await runMonthlyGroupReminder(
    { day: 3, month: 8, year: 2026 },
    {
      enabled: true,
      institution: { institutionName: "Lembaga Uji" },
      groups: [
        { key: "putra_pagi", groupId: "group-1" },
        { key: "putri_sore", groupId: "group-2" },
      ],
      send: async (messages) => {
        sent = messages;
        return { messageCount: messages.length };
      },
    },
  );

  assert.equal(result.sent, 2);
  assert.deepEqual(
    sent.map((message) => ({
      phone: message.phone,
      isGroup: message.isGroup,
      refId: message.refId,
    })),
    [
      {
        phone: "group-1",
        isGroup: "true",
        refId: "monthly-assessment-target-2026-08-putra_pagi",
      },
      {
        phone: "group-2",
        isGroup: "true",
        refId: "monthly-assessment-target-2026-08-putri_sore",
      },
    ],
  );
  assert.match(sent[0].message, /penilaian santri bulan Juli 2026/);
  assert.match(sent[0].message, /target hafalan bulan Agustus 2026/);
});

test("reminder grup tetap aman saat Wablas dinonaktifkan", async () => {
  const {
    runMonthlyGroupReminder,
  } = require("../handlers/monthlyGroupNotifier");
  let sendCalled = false;
  const result = await runMonthlyGroupReminder(
    { day: 3, month: 8, year: 2026 },
    {
      enabled: false,
      groups: [{ key: "putra_pagi", groupId: "group-1" }],
      send: async () => {
        sendCalled = true;
      },
    },
  );

  assert.equal(sendCalled, false);
  assert.deepEqual(result, {
    skipped: true,
    reason: "wablas_disabled",
  });
});

test("manifest Firebase memuat tepat empat jadwal di zona Jakarta", () => {
  const cloudFunctions = require("../index");
  const scheduled = Object.entries(cloudFunctions)
    .filter(([, handler]) => Boolean(handler?.__endpoint?.scheduleTrigger))
    .map(([name, handler]) => ({
      name,
      schedule: handler.__endpoint.scheduleTrigger.schedule,
      timeZone: handler.__endpoint.scheduleTrigger.timeZone,
    }));

  assert.deepEqual(scheduled, [
    {
      name: "notifyAssessmentWindowOpen",
      schedule: "30 19 * * *",
      timeZone: "Asia/Jakarta",
    },
    {
      name: "notifyArrearsMonthEnd",
      schedule: "0 8 * * *",
      timeZone: "Asia/Jakarta",
    },
    {
      name: "cleanupExpiredSyahadah",
      schedule: "0 3 * * 1",
      timeZone: "Asia/Jakarta",
    },
    {
      name: "notifyMonthlyAssessmentGroups",
      schedule: "0 9 3 * *",
      timeZone: "Asia/Jakarta",
    },
  ]);

  assert.equal(cloudFunctions.notifyIncompleteAssessment, undefined);
  assert.equal(cloudFunctions.notifyPaymentDue, undefined);
  assert.equal(cloudFunctions.notifyArrearsMidMonth, undefined);
});

test("source hanya mendaftarkan empat Cloud Scheduler", () => {
  const root = path.resolve(__dirname, "..");
  const handlerFiles = [
    "handlers/assessmentNotifier.js",
    "handlers/paymentNotifier.js",
    "handlers/cleanupExpiredSyahadah.js",
    "handlers/monthlyGroupNotifier.js",
  ];
  const registrationCount = handlerFiles.reduce((total, file) => {
    const source = fs.readFileSync(path.join(root, file), "utf8");
    return total + (source.match(/= onSchedule\(/g) || []).length;
  }, 0);
  assert.equal(registrationCount, 4);

  const indexSource = fs.readFileSync(path.join(root, "index.js"), "utf8");
  assert.match(indexSource, /exports\.notifyAssessmentWindowOpen\s*=/);
  assert.match(indexSource, /exports\.notifyArrearsMonthEnd\s*=/);
  assert.match(indexSource, /exports\.cleanupExpiredSyahadah\s*=/);
  assert.match(indexSource, /exports\.notifyMonthlyAssessmentGroups\s*=/);
  assert.doesNotMatch(indexSource, /exports\.notifyIncompleteAssessment\s*=/);
  assert.doesNotMatch(indexSource, /exports\.notifyPaymentDue\s*=/);
  assert.doesNotMatch(indexSource, /exports\.notifyArrearsMidMonth\s*=/);
});
