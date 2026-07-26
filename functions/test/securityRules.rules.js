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
  doc,
  getDoc,
  setDoc,
} = require("firebase/firestore");
const {
  ref,
  uploadString,
} = require("firebase/storage");

const projectId = "demo-tahfiz";
const root = path.resolve(__dirname, "..", "..");
let testEnv;

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
