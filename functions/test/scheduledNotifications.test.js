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
const { jakartaDateTimeParts } = require("../lib/jakartaTime");

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

test("slot scheduler pagi dibaca konsisten dalam zona Jakarta", () => {
  const atEight = jakartaDateTimeParts(
    new Date("2026-08-03T01:00:00.000Z"),
  );
  const atNine = jakartaDateTimeParts(
    new Date("2026-08-03T02:00:00.000Z"),
  );

  assert.deepEqual(
    {
      year: atEight.year,
      month: atEight.month,
      day: atEight.day,
      hour: atEight.hour,
      minute: atEight.minute,
    },
    { year: 2026, month: 8, day: 3, hour: 8, minute: 0 },
  );
  assert.equal(atNine.hour, 9);
  assert.equal(atNine.day, 3);
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

test("satu scheduler pagi memisahkan tugas pukul 08 dan 09", async () => {
  const {
    MORNING_NOTIFICATION_JOBS,
    morningNotificationJobNames,
    runMorningNotifications,
  } = require("../handlers/paymentNotifier");
  const calls = [];
  const runners = {
    [MORNING_NOTIFICATION_JOBS.payment]: async (parts) => {
      calls.push(["payment", parts.hour, parts.day]);
      return { channel: "payment" };
    },
    [MORNING_NOTIFICATION_JOBS.monthlyAssessment]: async (parts) => {
      calls.push(["monthly", parts.hour, parts.day]);
      return { channel: "monthly" };
    },
  };

  assert.deepEqual(
    morningNotificationJobNames({ day: 3, hour: 8 }),
    [MORNING_NOTIFICATION_JOBS.payment],
  );
  assert.deepEqual(
    morningNotificationJobNames({ day: 3, hour: 9 }),
    [MORNING_NOTIFICATION_JOBS.monthlyAssessment],
  );
  assert.deepEqual(morningNotificationJobNames({ day: 4, hour: 9 }), []);

  await runMorningNotifications(
    {
      day: 3,
      month: 8,
      year: 2026,
      daysRemaining: 28,
      hour: 8,
      minute: 0,
    },
    runners,
  );
  await runMorningNotifications(
    {
      day: 3,
      month: 8,
      year: 2026,
      daysRemaining: 28,
      hour: 9,
      minute: 0,
    },
    runners,
  );
  const skipped = await runMorningNotifications(
    {
      day: 4,
      month: 8,
      year: 2026,
      daysRemaining: 27,
      hour: 9,
      minute: 0,
    },
    runners,
  );

  assert.deepEqual(calls, [
    ["payment", 8, 3],
    ["monthly", 9, 3],
  ]);
  assert.deepEqual(skipped, { skipped: true, jobs: {} });
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

test("H-1 dan hari terakhir mengirim FCM serta WhatsApp ke asatidz belum lengkap", async () => {
  const { runIncomplete } = require("../handlers/assessmentNotifier");
  const incomplete = [
    { uid: "asatidz-a", name: "Ahmad", total: 10, count: 2 },
    { uid: "asatidz-b", name: "Fatimah", total: 8, count: 1 },
  ];
  const pushCalls = [];
  let whatsappInput;

  const result = await runIncomplete(
    { day: 30, month: 7, year: 2026, daysRemaining: 1 },
    {
      computeIncomplete: async () => incomplete,
      sendPush: async (uid, payload) => {
        pushCalls.push({ uid, payload });
        if (uid === "asatidz-b") throw new Error("FCM sementara gagal");
        return { successCount: 1, failureCount: 0 };
      },
      sendWhatsApp: async (parts, recipients) => {
        whatsappInput = { parts, recipients };
        return { sent: recipients.length, failed: 0 };
      },
    },
  );

  assert.deepEqual(
    pushCalls.map((call) => call.uid),
    ["asatidz-a", "asatidz-b"],
  );
  assert.equal(pushCalls[0].payload.data.type, "monthly_assessment_reminder");
  assert.deepEqual(whatsappInput, {
    parts: { day: 30, month: 7, year: 2026, daysRemaining: 1 },
    recipients: incomplete,
  });
  assert.deepEqual(result, {
    notified: 1,
    pushFailed: 1,
    whatsapp: { sent: 2, failed: 0 },
  });
});

test("reminder tanggal 3 mengirim notifikasi aplikasi ke role santri", async () => {
  const {
    runMonthlyAppReminder,
  } = require("../handlers/monthlyGroupNotifier");
  let captured;
  const result = await runMonthlyAppReminder(
    { day: 3, month: 1, year: 2027 },
    {
      sendPush: async (role, payload) => {
        captured = { role, payload };
        return { successCount: 4, failureCount: 1 };
      },
    },
  );

  assert.equal(captured.role, "santri");
  assert.equal(captured.payload.title, "Penilaian & Target Bulanan Tersedia");
  assert.match(captured.payload.body, /Desember 2026/);
  assert.match(captured.payload.body, /Januari 2027/);
  assert.deepEqual(captured.payload.data, {
    type: "monthly_assessment_target_available",
    bulan: 1,
    tahun: 2027,
    assessment_month: 12,
    assessment_year: 2026,
  });
  assert.deepEqual(result, { successCount: 4, failureCount: 1 });
});

test("notifikasi aplikasi tanggal 3 tetap jalan saat Wablas nonaktif", async () => {
  const {
    runMonthlyAssessmentReminder,
  } = require("../handlers/monthlyGroupNotifier");
  let pushCalls = 0;
  const result = await runMonthlyAssessmentReminder(
    { day: 3, month: 8, year: 2026 },
    {
      app: {
        sendPush: async () => {
          pushCalls += 1;
          return { successCount: 3, failureCount: 0 };
        },
      },
      whatsapp: {
        enabled: false,
      },
    },
  );

  assert.equal(pushCalls, 1);
  assert.deepEqual(result, {
    app: { successCount: 3, failureCount: 0 },
    whatsapp: { skipped: true, reason: "wablas_disabled" },
  });
});

test("reminder grup tanggal 3 tetap jalan saat FCM gagal", async () => {
  const {
    runMonthlyAssessmentReminder,
  } = require("../handlers/monthlyGroupNotifier");
  let sent;
  const result = await runMonthlyAssessmentReminder(
    { day: 3, month: 8, year: 2026 },
    {
      app: {
        sendPush: async () => {
          throw new Error("FCM tidak tersedia");
        },
      },
      whatsapp: {
        enabled: true,
        institution: { institutionName: "Lembaga Uji" },
        groups: [{ key: "putra_pagi", groupId: "group-1" }],
        send: async (messages) => {
          sent = messages;
          return { messageCount: messages.length };
        },
      },
    },
  );

  assert.equal(sent.length, 1);
  assert.equal(result.app.error, "FCM tidak tersedia");
  assert.equal(result.whatsapp.sent, 1);
});

test("manifest Firebase memuat tepat tiga jadwal di zona Jakarta", () => {
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
      schedule: "0 8,9 * * *",
      timeZone: "Asia/Jakarta",
    },
    {
      name: "cleanupExpiredSyahadah",
      schedule: "0 3 * * 1",
      timeZone: "Asia/Jakarta",
    },
  ]);

  assert.equal(cloudFunctions.notifyIncompleteAssessment, undefined);
  assert.equal(cloudFunctions.notifyPaymentDue, undefined);
  assert.equal(cloudFunctions.notifyArrearsMidMonth, undefined);
  assert.equal(cloudFunctions.notifyMonthlyAssessmentGroups, undefined);
});

test("fungsi yang memakai Wablas mengikat kedua secret pada manifest", () => {
  const cloudFunctions = require("../index");
  const expected = ["WABLAS_SECRET_KEY", "WABLAS_TOKEN"];

  for (const functionName of [
    "notifyAssessmentWindowOpen",
    "notifyArrearsMonthEnd",
    "provisionInstitutionUser",
  ]) {
    const names = (
      cloudFunctions[functionName].__endpoint.secretEnvironmentVariables || []
    )
      .map((secret) => secret.key)
      .sort();
    assert.deepEqual(names, expected, functionName);
  }
});

test("source hanya mendaftarkan tiga Cloud Scheduler", () => {
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
  assert.equal(registrationCount, 3);

  const indexSource = fs.readFileSync(path.join(root, "index.js"), "utf8");
  assert.match(indexSource, /exports\.notifyAssessmentWindowOpen\s*=/);
  assert.match(indexSource, /exports\.notifyArrearsMonthEnd\s*=/);
  assert.match(indexSource, /exports\.cleanupExpiredSyahadah\s*=/);
  assert.doesNotMatch(indexSource, /exports\.notifyIncompleteAssessment\s*=/);
  assert.doesNotMatch(indexSource, /exports\.notifyPaymentDue\s*=/);
  assert.doesNotMatch(indexSource, /exports\.notifyArrearsMidMonth\s*=/);
  assert.doesNotMatch(
    indexSource,
    /exports\.notifyMonthlyAssessmentGroups\s*=/,
  );
});
