"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  _private: { accountFromProfile, createFamilyAccountService },
} = require("../handlers/familyAccounts");

function createService({
  users = {},
  families = [],
  profiles = {},
  tokenFor = (uid) => "token-" + uid,
} = {}) {
  return createFamilyAccountService({
    getUser: async (uid) => ({
      exists: users[uid] != null,
      data: users[uid] || {},
    }),
    findFamilies: async (uid) =>
      families.filter((family) => family.santriIds.includes(uid)),
    getProfiles: async (ids) =>
      ids.map((id) => ({
        id,
        exists: profiles[id] != null,
        data: profiles[id] || {},
      })),
    createCustomToken: async (uid) => tokenFor(uid),
  });
}

test("daftar keluarga hanya mengembalikan saudara aktif", async () => {
  const service = createService({
    users: {
      a: { role: "santri" },
      b: { role: "santri" },
      c: { role: "santri" },
    },
    families: [{ id: "family-1", santriIds: ["a", "b", "c", "b"] }],
    profiles: {
      b: {
        name: "Budi",
        nis: "002",
        kelas: "Tahfidz 2",
        jenis_kelamin: "l",
        photo_url: "https://example.test/b.jpg",
      },
      c: { name: "Citra", is_active: false },
    },
  });

  assert.deepEqual(await service.getAccounts("a"), [
    {
      id: "b",
      name: "Budi",
      nis: "002",
      kelas: "Tahfidz 2",
      jenisKelamin: "L",
      photoUrl: "https://example.test/b.jpg",
    },
  ]);
});

test("akun tunggal tidak memperoleh pilihan switch", async () => {
  const service = createService({
    users: { a: { role: "santri" } },
  });

  assert.deepEqual(await service.getAccounts("a"), []);
});

test("token hanya diterbitkan untuk santri aktif dalam keluarga yang sama", async () => {
  const service = createService({
    users: {
      a: { role: "santri" },
      b: { role: "santri" },
      x: { role: "santri" },
    },
    families: [{ id: "family-1", santriIds: ["a", "b"] }],
    profiles: {
      b: { name: "Budi", is_active: true },
      x: { name: "X", is_active: true },
    },
  });

  assert.equal(await service.createSwitchToken("a", " b "), "token-b");
  await assert.rejects(
    service.createSwitchToken("a", "x"),
    (error) => error.code === "permission-denied",
  );
});

test("akun non-santri dan santri nonaktif ditolak", async () => {
  const staffService = createService({
    users: { admin: { role: "admin" } },
  });
  await assert.rejects(
    staffService.getAccounts("admin"),
    (error) => error.code === "permission-denied",
  );

  const inactiveService = createService({
    users: {
      a: { role: "santri" },
      b: { role: "santri" },
    },
    families: [{ id: "family-1", santriIds: ["a", "b"] }],
    profiles: { b: { name: "Budi", is_active: false } },
  });
  await assert.rejects(
    inactiveService.createSwitchToken("a", "b"),
    (error) => error.code === "failed-precondition",
  );
});

test("profil kosong tidak pernah menjadi pilihan akun", () => {
  assert.equal(accountFromProfile(null), null);
  assert.equal(accountFromProfile({ id: "b", exists: false }), null);
});
