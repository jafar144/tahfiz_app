const assert = require("node:assert/strict");
const test = require("node:test");

const {
  buildSundayFajrAlphaAnnouncement,
} = require("../lib/whatsappMessages");
const {
  isMonday,
  previousSunday,
  fetchSundayFajrAlphas,
  configuredTargetGroups,
  prepareSundayFajrWhatsAppMessages,
  runSundayFajrAlphaNotifications,
} = require("../handlers/sundayFajrNotifier");

const participants = [
  { uid: "santri-a", name: "Ali Umar Hasan" },
  { uid: "santri-b", name: "Zidan" },
];

test("tanggal Senin dipetakan ke Ahad sebelumnya termasuk lintas tahun", () => {
  assert.equal(isMonday({ year: 2027, month: 1, day: 4 }), true);
  assert.equal(isMonday({ year: 2027, month: 1, day: 5 }), false);
  assert.deepEqual(previousSunday({ year: 2027, month: 1, day: 4 }), {
    year: 2027,
    month: 1,
    day: 3,
  });
});

test("pengumuman WhatsApp memakai naskah lengkap dan daftar bernomor", () => {
  const message = buildSundayFajrAlphaAnnouncement(
    { year: 2026, month: 2, day: 8 },
    participants,
  );

  assert.match(message, /^PENGUMUMAN/);
  assert.match(message, /Ahad, 8 Februari 2026/);
  assert.match(message, /1\. Ali Umar Hasan\n2\. Zidan/);
  assert.match(message, /3 \(tiga\) kali pertemuan/);
  assert.match(message, /Terima kasih atas perhatian dan kerja samanya\.$/);
});

test("data alpha dibaca dari subcollection Ahad dan diurutkan berdasarkan nama", async () => {
  let queriedStatus;
  const participantCollection = {
    where(field, operator, value) {
      assert.equal(field, "status");
      assert.equal(operator, "==");
      queriedStatus = value;
      return this;
    },
    async get() {
      return {
        docs: [
          {
            id: "santri-b",
            data: () => ({
              santri_id: "santri-b",
              santri_name: "Zidan",
            }),
          },
          {
            id: "santri-a",
            data: () => ({
              santri_id: "santri-a",
              santri_name: "Ali Umar Hasan",
            }),
          },
        ],
      };
    },
  };
  const firestore = {
    collection(name) {
      assert.equal(name, "sunday_fajr_attendance");
      return {
        doc(weekKey) {
          assert.equal(weekKey, "2026-02-08");
          return {
            async get() {
              return {
                exists: true,
                data: () => ({ total_alpha: 2 }),
              };
            },
            collection(childName) {
              assert.equal(childName, "participants");
              return participantCollection;
            },
          };
        },
      };
    },
  };

  const result = await fetchSundayFajrAlphas("2026-02-08", firestore);

  assert.equal(queriedStatus, "alpha");
  assert.deepEqual(result, participants);
});

test("grup default Minggu Subuh hanya Putra Sore dan Putra Malam", () => {
  const groups = configuredTargetGroups({
    putra_pagi: { groupId: "group-pagi" },
    putra_sore: { groupId: "group-sore" },
    putra_malam: { groupId: "group-malam" },
    putri_sore: { groupId: "group-putri" },
  });

  assert.deepEqual(
    groups.map(({ key, groupId }) => ({ key, groupId })),
    [
      { key: "putra_sore", groupId: "group-sore" },
      { key: "putra_malam", groupId: "group-malam" },
    ],
  );
});

test("pesan WA dibuat untuk nomor santri valid dan dua grup tujuan", () => {
  const prepared = prepareSundayFajrWhatsAppMessages({
    weekKey: "2026-02-08",
    eventParts: { year: 2026, month: 2, day: 8 },
    participants: [
      ...participants,
      { uid: "santri-c", name: "Tanpa Nomor" },
    ],
    phones: new Map([
      ["santri-a", "081234567890"],
      ["santri-b", "+62 813-4567-8901"],
      ["santri-c", ""],
    ]),
    groups: [
      { key: "putra_sore", groupId: "group-sore" },
      { key: "putra_malam", groupId: "group-malam" },
    ],
  });

  assert.equal(prepared.personalCount, 2);
  assert.equal(prepared.groupCount, 2);
  assert.equal(prepared.invalidPhoneCount, 1);
  assert.deepEqual(
    prepared.messages.map(({ phone, isGroup, refId }) => ({
      phone,
      isGroup,
      refId,
    })),
    [
      {
        phone: "6281234567890",
        isGroup: "false",
        refId: "sunday-fajr-alpha-2026-02-08-santri-a",
      },
      {
        phone: "6281345678901",
        isGroup: "false",
        refId: "sunday-fajr-alpha-2026-02-08-santri-b",
      },
      {
        phone: "group-sore",
        isGroup: "true",
        refId: "sunday-fajr-alpha-2026-02-08-putra_sore",
      },
      {
        phone: "group-malam",
        isGroup: "true",
        refId: "sunday-fajr-alpha-2026-02-08-putra_malam",
      },
    ],
  );
  assert.ok(
    prepared.messages.every(
      (message) => message.message === prepared.announcement,
    ),
  );
});

test("hari selain Senin tidak membaca absensi atau mengirim pesan", async () => {
  let fetchCalls = 0;
  const result = await runSundayFajrAlphaNotifications(
    { year: 2026, month: 2, day: 10 },
    {
      fetchAlphas: async () => {
        fetchCalls += 1;
        return participants;
      },
    },
  );

  assert.equal(fetchCalls, 0);
  assert.deepEqual(result, { skipped: true, reason: "not_monday" });
});

test("Senin tanpa alpha tidak mengirim notifikasi HP maupun WA", async () => {
  let pushCalls = 0;
  let whatsappCalls = 0;
  const result = await runSundayFajrAlphaNotifications(
    { year: 2026, month: 2, day: 9 },
    {
      fetchAlphas: async (weekKey) => {
        assert.equal(weekKey, "2026-02-08");
        return [];
      },
      app: {
        sendPush: async () => {
          pushCalls += 1;
        },
      },
      whatsapp: {
        enabled: true,
        send: async () => {
          whatsappCalls += 1;
        },
      },
    },
  );

  assert.equal(pushCalls, 0);
  assert.equal(whatsappCalls, 0);
  assert.deepEqual(result, {
    skipped: true,
    reason: "no_alpha",
    weekKey: "2026-02-08",
  });
});

test("Senin dengan alpha mengirim push personal dan WA personal plus grup", async () => {
  const pushCalls = [];
  let whatsappMessages;
  const result = await runSundayFajrAlphaNotifications(
    { year: 2026, month: 2, day: 9 },
    {
      fetchAlphas: async () => participants,
      app: {
        sendPush: async (uid, payload) => {
          pushCalls.push({ uid, payload });
          return { successCount: 1, failureCount: 0 };
        },
      },
      whatsapp: {
        enabled: true,
        fetchPhones: async () =>
          new Map([
            ["santri-a", "081234567890"],
            ["santri-b", "081345678901"],
          ]),
        groups: [
          { key: "putra_sore", groupId: "group-sore" },
          { key: "putra_malam", groupId: "group-malam" },
        ],
        send: async (messages) => {
          whatsappMessages = messages;
          return { messageCount: messages.length };
        },
      },
    },
  );

  assert.deepEqual(
    pushCalls.map((call) => call.uid),
    ["santri-a", "santri-b"],
  );
  assert.equal(pushCalls[0].payload.data.type, "sunday_fajr_alpha");
  assert.equal(pushCalls[0].payload.data.week_key, "2026-02-08");
  assert.match(pushCalls[0].payload.body, /3 pertemuan/);
  assert.equal(whatsappMessages.length, 4);
  assert.equal(whatsappMessages.filter((item) => item.isGroup === "true").length, 2);
  assert.deepEqual(result, {
    skipped: false,
    weekKey: "2026-02-08",
    alphaCount: 2,
    app: {
      notified: 2,
      pushFailed: 0,
      successCount: 2,
      failureCount: 0,
    },
    whatsapp: {
      sent: 4,
      failed: 0,
      personal: 2,
      groups: 2,
      invalidPhone: 0,
      provider: { messageCount: 4 },
    },
  });
});

test("Wablas nonaktif tidak menghalangi notifikasi HP", async () => {
  let pushCalls = 0;
  const result = await runSundayFajrAlphaNotifications(
    { year: 2026, month: 2, day: 9 },
    {
      fetchAlphas: async () => participants,
      app: {
        sendPush: async () => {
          pushCalls += 1;
          return { successCount: 1, failureCount: 0 };
        },
      },
      whatsapp: { enabled: false },
    },
  );

  assert.equal(pushCalls, 2);
  assert.deepEqual(result.whatsapp, {
    skipped: true,
    reason: "wablas_disabled",
  });
});

test("gagal membaca nomor personal tidak menghalangi push dan WA grup", async () => {
  let pushCalls = 0;
  let whatsappMessages;
  const result = await runSundayFajrAlphaNotifications(
    { year: 2026, month: 2, day: 9 },
    {
      fetchAlphas: async () => participants,
      app: {
        sendPush: async () => {
          pushCalls += 1;
          return { successCount: 1, failureCount: 0 };
        },
      },
      whatsapp: {
        enabled: true,
        fetchPhones: async () => {
          throw new Error("Firestore sementara gagal");
        },
        groups: [
          { key: "putra_sore", groupId: "group-sore" },
          { key: "putra_malam", groupId: "group-malam" },
        ],
        send: async (messages) => {
          whatsappMessages = messages;
          return { messageCount: messages.length };
        },
      },
    },
  );

  assert.equal(pushCalls, 2);
  assert.equal(whatsappMessages.length, 2);
  assert.ok(whatsappMessages.every((message) => message.isGroup === "true"));
  assert.equal(result.whatsapp.sent, 2);
  assert.equal(
    result.whatsapp.phoneLookupError,
    "Firestore sementara gagal",
  );
});
