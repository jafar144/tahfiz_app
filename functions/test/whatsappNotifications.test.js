const assert = require("node:assert/strict");
const test = require("node:test");

const { birthdayInfo } = require("../lib/birthdayStatus");
const { resolveStartMonth } = require("../lib/paymentStatus");
const {
  normalizeBaseUrl,
  normalizeWhatsAppPhone,
  sendTextMessages,
} = require("../lib/wablas");
const {
  buildArrearsWhatsAppMessage,
  buildBirthdayWhatsAppMessage,
  buildSantriWelcomeWhatsAppMessage,
  buildMonthlyAssessmentGroupMessage,
  buildIncompleteAssessmentWhatsAppMessage,
} = require("../lib/whatsappMessages");
const {
  WHATSAPP_GROUP_IDENTITIES,
  findWhatsAppGroupIdentity,
  resolveWhatsAppGroup,
  configuredWhatsAppGroups,
} = require("../lib/whatsappGroups");
const {
  oldestArrearsAge,
  billingPeriodsSinceEntry,
  selectLongOverdueSantri,
  runBirthdayWhatsApp,
  runSantriWelcomeWhatsApp,
  runIncompleteAssessmentWhatsApp,
} = require("../handlers/whatsappNotifier");

const institution = {
  institutionName: "Lembaga Uji",
  bankName: "BSI",
  accountNumber: "1234567890",
  accountHolder: "Bendahara Uji",
};

test("normalisasi Wablas mencegah double slash dan merapikan nomor Indonesia", () => {
  assert.equal(normalizeBaseUrl("https://solo.wablas.com///"), "https://solo.wablas.com");
  assert.equal(normalizeWhatsAppPhone("0877-9984-1612"), "6287799841612");
  assert.equal(normalizeWhatsAppPhone("87799841612"), "6287799841612");
  assert.equal(normalizeWhatsAppPhone(""), null);
});

test("client Wablas memakai endpoint V2, authorization, dan JSON yang benar", async () => {
  let captured;
  const result = await sendTextMessages(
    [
      {
        phone: "087799841612",
        message: "Pesan test",
        isGroup: "false",
        refId: "test-1",
      },
    ],
    {
      baseUrl: "https://solo.wablas.com/",
      token: "token-test",
      secretKey: "secret-test",
      fetchImpl: async (url, options) => {
        captured = { url, options };
        return {
          ok: true,
          status: 200,
          text: async () => JSON.stringify({ status: true, message: "pending" }),
        };
      },
    }
  );

  assert.equal(captured.url, "https://solo.wablas.com/api/v2/send-message");
  assert.equal(captured.options.method, "POST");
  assert.equal(captured.options.headers.Authorization, "token-test.secret-test");
  assert.deepEqual(JSON.parse(captured.options.body), {
    data: [
      {
        phone: "6287799841612",
        message: "Pesan test",
        isGroup: "false",
        ref_id: "test-1",
      },
    ],
  });
  assert.equal(result.messageCount, 1);
});

test("tunggakan Mei memenuhi ambang tiga periode pada bulan Juli", () => {
  const parts = { year: 2026, month: 7, day: 28 };
  const may = {
    uid: "may",
    tanggalMasuk: new Date("2026-04-30T17:00:00.000Z"),
    months: [{ year: 2026, month: 5 }],
  };
  const june = {
    uid: "june",
    tanggalMasuk: new Date("2026-05-31T17:00:00.000Z"),
    months: [{ year: 2026, month: 6 }],
  };
  const joinedJuly = {
    uid: "new-july",
    tanggalMasuk: new Date("2026-06-30T17:00:00.000Z"),
    months: [{ year: 2026, month: 5 }],
  };

  assert.equal(oldestArrearsAge(may, parts), 3);
  assert.equal(oldestArrearsAge(june, parts), 2);
  assert.equal(billingPeriodsSinceEntry(joinedJuly, parts), 1);
  assert.deepEqual(selectLongOverdueSantri([may, june, joinedJuly], parts), [
    may,
  ]);
});

test("awal kewajiban tidak pernah mendahului bulan tanggal masuk", () => {
  const now = new Date("2026-07-19T05:00:00.000Z");
  const joinedJuly = new Date("2026-06-30T17:00:00.000Z");
  const oldFreeUntil = new Date("2025-12-31T16:59:59.000Z");

  assert.deepEqual(resolveStartMonth(oldFreeUntil, joinedJuly, now), {
    year: 2026,
    month: 7,
  });
  assert.equal(resolveStartMonth(oldFreeUntil, null, now), null);
});

test("tanggal lahir midnight UTC+7 dicocokkan sebagai tanggal Jakarta", () => {
  const storedDate = new Date("2010-12-27T17:00:00.000Z");
  const info = birthdayInfo(storedDate, {
    year: 2026,
    month: 12,
    day: 28,
  });

  assert.ok(info);
  assert.equal(info.age, 16);
  assert.equal(
    birthdayInfo(storedDate, { year: 2026, month: 12, day: 27 }),
    null
  );
});

test("template WhatsApp memuat detail tunggakan dan doa ulang tahun", () => {
  const arrears = buildArrearsWhatsAppMessage(
    {
      name: "Ahmad",
      nis: "123",
      months: [
        { year: 2026, month: 5 },
        { year: 2026, month: 6 },
      ],
    },
    institution,
  );
  assert.match(arrears, /Ahmad/);
  assert.match(arrears, /Mei 2026, Juni 2026/);

  const birthday = buildBirthdayWhatsAppMessage(
    { name: "Ahmad", age: 16 },
    institution,
  );
  assert.match(birthday, /Barakallahu fii umrik/);
  assert.match(birthday, /16 tahun/);
});

test("identitas grup memilih kombinasi gender dan sesi secara konsisten", () => {
  assert.equal(findWhatsAppGroupIdentity("L", "Pagi").key, "putra_pagi");
  assert.equal(findWhatsAppGroupIdentity("putri", "MALAM").key, "putri_malam");
  assert.equal(findWhatsAppGroupIdentity("L", "siang"), null);

  const overrides = Object.fromEntries(
    WHATSAPP_GROUP_IDENTITIES.map((identity) => [
      identity.key,
      { groupId: "", inviteUrl: "" },
    ]),
  );
  overrides.putri_sore = {
    groupId: "group-putri-sore",
    inviteUrl: "https://chat.whatsapp.com/putri-sore",
  };
  overrides.putri_malam = {
    groupId: "group-putri-sore",
    inviteUrl: "https://chat.whatsapp.com/putri-malam",
  };

  const selected = resolveWhatsAppGroup("P", "Sore", overrides);
  assert.equal(selected.label, "Putri Sore");
  assert.equal(selected.groupId, "group-putri-sore");
  assert.equal(
    selected.inviteUrl,
    "https://chat.whatsapp.com/putri-sore",
  );
  assert.deepEqual(
    configuredWhatsAppGroups(overrides).map((group) => group.key),
    ["putri_sore"],
  );
});

test("template welcome memuat profil, kredensial, aplikasi, dan link grup", () => {
  const message = buildSantriWelcomeWhatsAppMessage({
    santri: {
      name: "Fatimah",
      nis: "24001",
      kelas: "Tahsin Awwal",
      tipeKelas: "Pagi",
      jenisKelamin: "P",
    },
    password: "20120309",
    institution,
    appUrl: "https://example.com/aplikasi",
    group: {
      label: "Putri Pagi",
      inviteUrl: "https://chat.whatsapp.com/putri-pagi",
    },
  });

  assert.match(message, /Fatimah/);
  assert.match(message, /NIS: 24001/);
  assert.match(message, /Kelas: Tahsin Awwal/);
  assert.match(message, /Sesi: Pagi/);
  assert.match(message, /Password awal: 20120309/);
  assert.match(message, /https:\/\/example\.com\/aplikasi/);
  assert.match(message, /https:\/\/chat\.whatsapp\.com\/putri-pagi/);
  assert.match(message, /progres hafalan dan target bulanan/);
});

test("welcome dikirim ke wali setelah seluruh link terkonfigurasi", async () => {
  let sent;
  const result = await runSantriWelcomeWhatsApp(
    {
      uid: "santri-1",
      name: "Fatimah",
      nis: "24001",
      nomorWali: "0812-3456-7890",
      phone: "0813-0000-0000",
      kelas: "Tahsin Awwal",
      tipeKelas: "Pagi",
      jenisKelamin: "P",
    },
    "20120309",
    {
      enabled: true,
      appUrl: "https://example.com/aplikasi",
      group: {
        key: "putri_pagi",
        label: "Putri Pagi",
        inviteUrl: "https://chat.whatsapp.com/putri-pagi",
      },
      institution,
      send: async (messages) => {
        sent = messages;
        return { messageCount: messages.length };
      },
    },
  );

  assert.equal(sent.length, 1);
  assert.equal(sent[0].phone, "6281234567890");
  assert.equal(sent[0].isGroup, "false");
  assert.equal(sent[0].refId, "welcome-santri-1");
  assert.match(sent[0].message, /Password awal: 20120309/);
  assert.deepEqual(
    { recipient: result.recipient, group: result.group, sent: result.sent },
    { recipient: "wali", group: "putri_pagi", sent: 1 },
  );
});

test("welcome tidak mengirim kredensial bila link grup belum diatur", async () => {
  let sendCalled = false;
  const result = await runSantriWelcomeWhatsApp(
    {
      uid: "santri-1",
      nomorWali: "081234567890",
      tipeKelas: "Pagi",
      jenisKelamin: "P",
    },
    "rahasia",
    {
      enabled: true,
      appUrl: "https://example.com/aplikasi",
      group: { key: "putri_pagi", label: "Putri Pagi", inviteUrl: "" },
      send: async () => {
        sendCalled = true;
      },
    },
  );

  assert.equal(sendCalled, false);
  assert.deepEqual(result, {
    skipped: true,
    reason: "group_invite_not_configured",
  });
});

test("pesan grup awal bulan menyebut penilaian lalu target bulan berjalan", () => {
  const message = buildMonthlyAssessmentGroupMessage(
    { month: 1, year: 2027 },
    institution,
  );
  assert.match(message, /Desember 2026/);
  assert.match(message, /Januari 2027/);
  assert.match(message, /hubungi asatidz masing-masing/);
});

test("template pengingat asatidz memuat progres penilaian yang belum lengkap", () => {
  const message = buildIncompleteAssessmentWhatsAppMessage(
    { name: "Ahmad", count: 3, total: 12 },
    { month: 7, year: 2026 },
    institution,
  );

  assert.match(message, /Ustadz\/Ustadzah Ahmad/);
  assert.match(message, /3 dari 12 santri binaan/);
  assert.match(message, /Juli 2026/);
  assert.match(message, /melengkapinya melalui aplikasi/);
  assert.match(message, /Lembaga Uji/);
});

test("pengingat penilaian dikirim personal ke nomor asatidz yang dinormalisasi", async () => {
  let sent;
  const result = await runIncompleteAssessmentWhatsApp(
    { day: 30, month: 7, year: 2026 },
    [
      { uid: "asatidz-a", name: "Ahmad", total: 10, count: 2 },
      {
        uid: "asatidz-b",
        name: "Fatimah",
        total: 8,
        count: 1,
        phone: "0813-0000-0000",
      },
    ],
    {
      enabled: true,
      institution,
      resolvePhone: async (uid) =>
        uid === "asatidz-a" ? "0812-3456-7890" : "",
      send: async (messages) => {
        sent = messages;
        return { messageCount: messages.length };
      },
    },
  );

  assert.deepEqual(
    sent.map((message) => ({
      phone: message.phone,
      isGroup: message.isGroup,
      refId: message.refId,
    })),
    [
      {
        phone: "6281234567890",
        isGroup: "false",
        refId: "assessment-incomplete-2026-07-30-asatidz-a",
      },
      {
        phone: "6281300000000",
        isGroup: "false",
        refId: "assessment-incomplete-2026-07-30-asatidz-b",
      },
    ],
  );
  assert.equal(result.eligible, 2);
  assert.equal(result.invalidPhone, 0);
  assert.equal(result.sent, 2);
});

test("nomor asatidz invalid dilewati dan Wablas nonaktif tidak membaca nomor", async () => {
  let resolverCalls = 0;
  let sendCalls = 0;
  const incomplete = [
    { uid: "asatidz-a", name: "Ahmad", total: 10, count: 2 },
  ];
  const disabled = await runIncompleteAssessmentWhatsApp(
    { day: 30, month: 7, year: 2026 },
    incomplete,
    {
      enabled: false,
      resolvePhone: async () => {
        resolverCalls += 1;
        return "081234567890";
      },
      send: async () => {
        sendCalls += 1;
      },
    },
  );
  const invalid = await runIncompleteAssessmentWhatsApp(
    { day: 31, month: 7, year: 2026 },
    incomplete,
    {
      enabled: true,
      institution,
      resolvePhone: async () => {
        resolverCalls += 1;
        return "nomor-tidak-valid";
      },
      send: async () => {
        sendCalls += 1;
      },
    },
  );

  assert.deepEqual(disabled, {
    skipped: true,
    reason: "wablas_disabled",
  });
  assert.equal(resolverCalls, 1);
  assert.equal(sendCalls, 0);
  assert.deepEqual(invalid, {
    eligible: 1,
    invalidPhone: 1,
    sent: 0,
    failed: 0,
  });
});

test("nomor wali kosong dialihkan ke nomor admin dengan penjelasan", async () => {
  let sent;
  const result = await runBirthdayWhatsApp(
    { year: 2026, month: 12, day: 28 },
    {
      enabled: true,
      adminPhone: "+62 896-7947-9654",
      institution,
      birthdays: [
        { uid: "a", name: "Ahmad", age: 16, nomorWali: "087799841612" },
        { uid: "b", name: "Fatimah", age: 15, nomorWali: "" },
      ],
      send: async (messages) => {
        sent = messages;
        return { messageCount: messages.length };
      },
    }
  );

  assert.equal(sent.length, 2);
  assert.equal(sent[0].phone, "6287799841612");
  assert.equal(sent[0].refId, "birthday-2026-12-28-a");
  assert.equal(sent[1].phone, "6289679479654");
  assert.match(sent[1].message, /nomor wali belum diisi/);
  assert.match(sent[1].message, /nomor admin/);
  assert.equal(result.invalidPhone, 1);
  assert.equal(result.adminFallback, 1);
  assert.equal(result.sent, 2);
});
