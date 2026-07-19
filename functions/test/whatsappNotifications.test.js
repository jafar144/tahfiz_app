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
} = require("../lib/whatsappMessages");
const {
  oldestArrearsAge,
  billingPeriodsSinceEntry,
  selectLongOverdueSantri,
  runBirthdayWhatsApp,
} = require("../handlers/whatsappNotifier");

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
  const arrears = buildArrearsWhatsAppMessage({
    name: "Ahmad",
    nis: "123",
    months: [
      { year: 2026, month: 5 },
      { year: 2026, month: 6 },
    ],
  });
  assert.match(arrears, /Ahmad/);
  assert.match(arrears, /Mei 2026, Juni 2026/);

  const birthday = buildBirthdayWhatsAppMessage({ name: "Ahmad", age: 16 });
  assert.match(birthday, /Barakallahu fii umrik/);
  assert.match(birthday, /16 tahun/);
});

test("nomor wali kosong dialihkan ke nomor admin dengan penjelasan", async () => {
  let sent;
  const result = await runBirthdayWhatsApp(
    { year: 2026, month: 12, day: 28 },
    {
      enabled: true,
      adminPhone: "+62 896-7947-9654",
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
