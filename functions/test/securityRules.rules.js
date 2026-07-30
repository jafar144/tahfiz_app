"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const {
  after,
  before,
  beforeEach,
  test,
} = require("node:test");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  collectionGroup,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  runTransaction,
  serverTimestamp,
  setDoc,
  Timestamp,
  where,
  writeBatch,
} = require("firebase/firestore");
const {
  ref,
  uploadString,
} = require("firebase/storage");

const projectId = "demo-tahfiz";
const root = path.resolve(__dirname, "..", "..");
let testEnv;

function wibCalendarDate(now = new Date()) {
  const wib = new Date(now.getTime() + (7 * 60 * 60 * 1000));
  return new Date(Date.UTC(
    wib.getUTCFullYear(),
    wib.getUTCMonth(),
    wib.getUTCDate(),
  ));
}

function latestSundayWib(now = new Date()) {
  const today = wibCalendarDate(now);
  today.setUTCDate(today.getUTCDate() - today.getUTCDay());
  return today;
}

function isSundayWib(now = new Date()) {
  return wibCalendarDate(now).getUTCDay() === 0;
}

function weekKey(date) {
  return date.toISOString().slice(0, 10);
}

function sundaySummary(date, {
  participantCount,
  hadir = 0,
  izin = 0,
  alpha = participantCount - hadir - izin,
  revision = 1,
} = {}) {
  const key = weekKey(date);
  const timestamp = Timestamp.fromDate(date);
  return {
    week_key: key,
    event_date: timestamp,
    participant_count: participantCount,
    total_hadir: hadir,
    total_izin: izin,
    total_alpha: alpha,
    revision,
    schema_version: 1,
    created_by: "admin",
    created_at: timestamp,
    updated_by: "admin",
    updated_at: timestamp,
  };
}

function sundayParticipant(
  date,
  santriId,
  status = "alpha",
  izinReason = "",
) {
  return {
    record_type: "sunday_fajr_participant",
    santri_id: santriId,
    santri_name: `Santri ${santriId}`,
    santri_nis: santriId.replace(/\D/g, "") || "1001",
    kelas: "Tahfiz 1",
    week_key: weekKey(date),
    event_date: Timestamp.fromDate(date),
    status,
    izin_reason: izinReason,
  };
}

async function seedSundayAttendance(date, participantIds) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    const key = weekKey(date);
    await setDoc(
      doc(firestore, "sunday_fajr_attendance", key),
      sundaySummary(date, { participantCount: participantIds.length }),
    );
    await Promise.all(participantIds.map((santriId) =>
      setDoc(
        doc(
          firestore,
          "sunday_fajr_attendance",
          key,
          "participants",
          santriId,
        ),
        sundayParticipant(date, santriId),
      ),
    ));
  });
}

async function seedUsers() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await Promise.all([
      setDoc(doc(firestore, "users/admin"), {
        uid: "admin",
        role: "admin",
        is_admin: true,
      }),
      setDoc(doc(firestore, "users/asatidz"), {
        uid: "asatidz",
        role: "asatidz",
        is_admin: false,
      }),
      setDoc(doc(firestore, "users/santri"), {
        uid: "santri",
        role: "santri",
        is_admin: false,
      }),
      setDoc(doc(firestore, "users/santri-lain"), {
        uid: "santri-lain",
        role: "santri",
        is_admin: false,
      }),
      setDoc(doc(firestore, "santri_profiles/santri"), {
        uid: "santri",
        name: "Santri Sendiri",
      }),
      setDoc(doc(firestore, "santri_profiles/santri-lain"), {
        uid: "santri-lain",
        name: "Santri Lain",
      }),
    ]);
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(path.join(root, "firestore.rules"), "utf8"),
    },
    storage: {
      rules: fs.readFileSync(path.join(root, "storage.rules"), "utf8"),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();
  await seedUsers();
});

after(async () => {
  await testEnv.cleanup();
});

test("akses anonim dan pembacaan profil santri lain ditolak", async () => {
  const anonymous = testEnv.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(anonymous, "users/admin")));

  const santri = testEnv.authenticatedContext("santri").firestore();
  await assertSucceeds(getDoc(doc(santri, "users/santri")));
  await assertSucceeds(getDoc(doc(santri, "santri_profiles/santri")));
  await assertFails(getDoc(doc(santri, "santri_profiles/santri-lain")));
});

test("klien tidak dapat membuat akun atau menaikkan role", async () => {
  const santri = testEnv.authenticatedContext("santri").firestore();
  await assertFails(
    setDoc(doc(santri, "users/attacker"), {
      uid: "attacker",
      role: "admin",
      is_admin: true,
    }),
  );
  await assertFails(
    setDoc(
      doc(santri, "users/santri"),
      { role: "admin" },
      { merge: true },
    ),
  );

  const admin = testEnv.authenticatedContext("admin").firestore();
  await assertFails(
    setDoc(doc(admin, "users/user-baru"), {
      uid: "user-baru",
      role: "santri",
    }),
  );
});

test("asatidz dapat menulis kegiatan belajar tetapi bukan data master", async () => {
  const firestore = testEnv.authenticatedContext("asatidz").firestore();
  await assertSucceeds(
    setDoc(doc(firestore, "meetings/pertemuan-1"), {
      asatidz_id: "asatidz",
      halaqah_id: "halaqah-1",
    }),
  );
  await assertSucceeds(
    setDoc(doc(firestore, "monthly_reports/laporan-1"), {
      asatidz_id: "asatidz",
      santri_id: "santri",
      bulan: 7,
      tahun: 2026,
    }),
  );
  await assertFails(
    setDoc(doc(firestore, "monthly_reports/laporan-palsu"), {
      asatidz_id: "asatidz-lain",
      santri_id: "santri",
    }),
  );
  await assertFails(
    setDoc(doc(firestore, "santri_profiles/user-baru"), {
      uid: "user-baru",
    }),
  );
});

test("santri hanya dapat membaca pembayaran dan laporan miliknya", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await Promise.all([
      setDoc(doc(firestore, "payments/sendiri"), { santri_id: "santri" }),
      setDoc(doc(firestore, "payments/orang-lain"), {
        santri_id: "santri-lain",
      }),
      setDoc(doc(firestore, "monthly_reports/sendiri"), {
        santri_id: "santri",
      }),
    ]);
  });

  const santri = testEnv.authenticatedContext("santri").firestore();
  await assertSucceeds(getDoc(doc(santri, "payments/sendiri")));
  await assertFails(getDoc(doc(santri, "payments/orang-lain")));
  await assertSucceeds(getDoc(doc(santri, "monthly_reports/sendiri")));
});

test("token perangkat hanya dapat ditulis oleh pemiliknya", async () => {
  const santri = testEnv.authenticatedContext("santri").firestore();
  await assertSucceeds(
    setDoc(doc(santri, "device_tokens/token-sendiri"), {
      token: "token-sendiri",
      uid: "santri",
      role: "santri",
    }),
  );
  await assertFails(
    setDoc(doc(santri, "device_tokens/token-palsu"), {
      token: "token-palsu",
      uid: "admin",
      role: "admin",
    }),
  );
});

test("santri hanya dapat membaca profil pengajar yang ditugaskan", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await Promise.all([
      setDoc(
        doc(firestore, "santri_profiles/santri"),
        { halaqah_id: "halaqah-santri" },
        { merge: true },
      ),
      setDoc(doc(firestore, "halaqahs/halaqah-santri"), {
        asatidz: { id: "asatidz" },
        session_id: "sore",
      }),
      setDoc(doc(firestore, "asatidz_profiles/asatidz"), {
        name: "Pengajar Aktif",
      }),
      setDoc(doc(firestore, "asatidz_profiles/asatidz-lain"), {
        name: "Pengajar Lain",
      }),
      setDoc(doc(firestore, "users/asatidz-lain"), {
        uid: "asatidz-lain",
        role: "asatidz",
        is_admin: false,
      }),
    ]);
  });

  const santri = testEnv.authenticatedContext("santri").firestore();
  await assertSucceeds(getDoc(doc(santri, "asatidz_profiles/asatidz")));
  await assertSucceeds(getDoc(doc(santri, "users/asatidz")));
  await assertFails(getDoc(doc(santri, "asatidz_profiles/asatidz-lain")));
  await assertFails(getDoc(doc(santri, "users/asatidz-lain")));
});

test("guard pengajar dan sesi hanya dapat dikelola admin", async () => {
  const admin = testEnv.authenticatedContext("admin").firestore();
  const santri = testEnv.authenticatedContext("santri").firestore();
  const guardData = {
    teacher_id: "asatidz",
    session_id: "sore",
    halaqah_id: "halaqah-1",
  };

  await assertSucceeds(
    setDoc(
      doc(admin, "halaqah_teacher_sessions/asatidz%3A%3Asore"),
      guardData,
    ),
  );
  await assertFails(
    setDoc(
      doc(santri, "halaqah_teacher_sessions/palsu"),
      guardData,
    ),
  );
});

test("update hanya berlaku pada hari Minggu yang sedang dicatat", async () => {
  const sunday = isSundayWib() ? wibCalendarDate() : latestSundayWib();
  const key = weekKey(sunday);
  await seedSundayAttendance(sunday, ["santri"]);

  const admin = testEnv.authenticatedContext("admin").firestore();
  const update = runTransaction(admin, async (transaction) => {
    const parent = doc(admin, "sunday_fajr_attendance", key);
    const participant = doc(
      admin,
      "sunday_fajr_attendance",
      key,
      "participants",
      "santri",
    );
    transaction.update(parent, {
      total_hadir: 1,
      total_izin: 0,
      total_alpha: 0,
      revision: 2,
      updated_by: "admin",
      updated_at: serverTimestamp(),
    });
    transaction.update(participant, {
      status: "hadir",
      izin_reason: "",
    });
  });

  if (isSundayWib()) {
    await assertSucceeds(update);
  } else {
    await assertFails(update);
  }
});

test("absensi setelah hari Minggunya tidak dapat diubah", async () => {
  const oldSunday = latestSundayWib();
  if (isSundayWib()) {
    oldSunday.setUTCDate(oldSunday.getUTCDate() - 7);
  }
  const key = weekKey(oldSunday);
  await seedSundayAttendance(oldSunday, ["santri"]);

  const admin = testEnv.authenticatedContext("admin").firestore();
  await assertFails(runTransaction(admin, async (transaction) => {
    transaction.update(doc(admin, "sunday_fajr_attendance", key), {
      total_hadir: 1,
      total_izin: 0,
      total_alpha: 0,
      revision: 2,
      updated_by: "admin",
      updated_at: serverTimestamp(),
    });
    transaction.update(
      doc(
        admin,
        "sunday_fajr_attendance",
        key,
        "participants",
        "santri",
      ),
      { status: "hadir", izin_reason: "" },
    );
  }));
});

test("santri hanya dapat meng-query riwayat Minggu Subuh miliknya", async () => {
  const sunday = latestSundayWib();
  await seedSundayAttendance(sunday, ["santri-lain"]);
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    const key = weekKey(sunday);
    await setDoc(
      doc(
        firestore,
        "sunday_fajr_attendance",
        key,
        "participants",
        "santri",
      ),
      sundayParticipant(sunday, "santri", "izin", "Sakit (data lama)"),
    );
  });

  const santri = testEnv.authenticatedContext("santri").firestore();
  const ownQuery = query(
    collectionGroup(santri, "participants"),
    where("record_type", "==", "sunday_fajr_participant"),
    where("santri_id", "==", "santri"),
    orderBy("event_date", "desc"),
  );
  const otherQuery = query(
    collectionGroup(santri, "participants"),
    where("record_type", "==", "sunday_fajr_participant"),
    where("santri_id", "==", "santri-lain"),
    orderBy("event_date", "desc"),
  );

  const ownSnapshot = await assertSucceeds(getDocs(ownQuery));
  assert.equal(ownSnapshot.size, 1);
  assert.equal(ownSnapshot.docs[0].data().izin_reason, "Sakit (data lama)");
  await assertFails(getDocs(otherQuery));

  const admin = testEnv.authenticatedContext("admin").firestore();
  const adminQuery = query(
    collectionGroup(admin, "participants"),
    where("record_type", "==", "sunday_fajr_participant"),
    where("santri_id", "==", "santri-lain"),
    orderBy("event_date", "desc"),
  );
  const adminSnapshot = await assertSucceeds(getDocs(adminQuery));
  assert.equal(adminSnapshot.size, 1);
});

test("create Absensi baru hanya pada hari Minggu WIB yang sama", async () => {
  const today = wibCalendarDate();
  const isSunday = isSundayWib();
  const selectedDate = isSunday ? today : latestSundayWib();
  const key = weekKey(selectedDate);
  const admin = testEnv.authenticatedContext("admin").firestore();
  const batch = writeBatch(admin);
  batch.set(doc(admin, "sunday_fajr_attendance", key), {
    ...sundaySummary(selectedDate, { participantCount: 1 }),
    created_at: serverTimestamp(),
    updated_at: serverTimestamp(),
  });
  batch.set(
    doc(
      admin,
      "sunday_fajr_attendance",
      key,
      "participants",
      "santri",
    ),
    sundayParticipant(selectedDate, "santri"),
  );

  if (isSunday) {
    await assertSucceeds(batch.commit());
  } else {
    await assertFails(batch.commit());
  }
});

test("write baru menolak alasan izin non-kosong", async (t) => {
  if (!isSundayWib()) {
    t.skip("create positif hanya dapat diuji pada hari Minggu WIB");
    return;
  }

  const sunday = wibCalendarDate();
  const key = weekKey(sunday);
  const admin = testEnv.authenticatedContext("admin").firestore();
  const batch = writeBatch(admin);
  batch.set(doc(admin, "sunday_fajr_attendance", key), {
    ...sundaySummary(sunday, { participantCount: 1, izin: 1 }),
    created_at: serverTimestamp(),
    updated_at: serverTimestamp(),
  });
  batch.set(
    doc(
      admin,
      "sunday_fajr_attendance",
      key,
      "participants",
      "santri",
    ),
    sundayParticipant(sunday, "santri", "izin", "Sakit"),
  );

  await assertFails(batch.commit());
});

test("rules menerima batas 497 hanya saat record masih editable", async () => {
  const sunday = isSundayWib() ? wibCalendarDate() : latestSundayWib();
  const key = weekKey(sunday);
  const participantIds = Array.from(
    { length: 497 },
    (_, index) => `santri-${index + 1}`,
  );
  await seedSundayAttendance(sunday, participantIds);

  const admin = testEnv.authenticatedContext("admin").firestore();
  const update = runTransaction(admin, async (transaction) => {
    transaction.update(doc(admin, "sunday_fajr_attendance", key), {
      total_hadir: participantIds.length,
      total_izin: 0,
      total_alpha: 0,
      revision: 2,
      updated_by: "admin",
      updated_at: serverTimestamp(),
    });
    for (const participantId of participantIds) {
      transaction.update(
        doc(
          admin,
          "sunday_fajr_attendance",
          key,
          "participants",
          participantId,
        ),
        { status: "hadir", izin_reason: "" },
      );
    }
  });

  if (isSundayWib()) {
    await assertSucceeds(update);
  } else {
    await assertFails(update);
  }
});

test("Storage menerima gambar hanya dari role yang sesuai", async () => {
  const adminStorage = testEnv.authenticatedContext("admin").storage();
  const asatidzStorage = testEnv.authenticatedContext("asatidz").storage();
  const santriStorage = testEnv.authenticatedContext("santri").storage();

  await assertSucceeds(
    uploadString(
      ref(adminStorage, "santri_photos/foto.jpg"),
      "image",
      "raw",
      { contentType: "image/jpeg" },
    ),
  );
  await assertSucceeds(
    uploadString(
      ref(asatidzStorage, "syahadah_photos/poster.jpg"),
      "image",
      "raw",
      { contentType: "image/jpeg" },
    ),
  );
  await assertFails(
    uploadString(
      ref(santriStorage, "syahadah_photos/poster-palsu.jpg"),
      "image",
      "raw",
      { contentType: "image/jpeg" },
    ),
  );
  await assertFails(
    uploadString(
      ref(adminStorage, "santri_photos/bukan-gambar.txt"),
      "text",
      "raw",
      { contentType: "text/plain" },
    ),
  );

  assert.ok(true);
});
