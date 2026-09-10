"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  _private: {
    birthDateInput,
    runResetSantriPasswordFromBirthDate,
  },
} = require("../handlers/resetSantriPasswordFromBirthDate");

function harness({ authFailure = null } = {}) {
  const updates = [];
  const authCalls = [];
  const documents = {
    "users/santri-1": { role: "santri" },
    "santri_profiles/santri-1": { tanggal_lahir: "lama" },
  };
  const firestore = {
    collection(name) {
      return {
        doc(id) {
          const key = `${name}/${id}`;
          return {
            async get() {
              return {
                exists: Object.hasOwn(documents, key),
                data: () => documents[key],
              };
            },
            async update(data) {
              updates.push({ key, data });
            },
          };
        },
      };
    },
  };
  const auth = {
    async updateUser(uid, data) {
      authCalls.push({ type: "update", uid, data });
      if (authFailure) throw authFailure;
    },
    async revokeRefreshTokens(uid) {
      authCalls.push({ type: "revoke", uid });
    },
  };
  return {
    firestore,
    auth,
    updates,
    authCalls,
    overrides: {
      firestore,
      auth,
      assertAdminFn: async () => {},
      timestampFromDate: (date) => `timestamp:${date.toISOString()}`,
      serverTimestamp: () => "server-time",
      deleteField: () => "delete-field",
      now: new Date("2026-09-10T00:00:00+07:00"),
    },
  };
}

test("tanggal lahir divalidasi sebagai date-only yang nyata", () => {
  assert.equal(
    birthDateInput("2012-03-09", new Date("2026-09-10T00:00:00+07:00")).text,
    "2012-03-09",
  );
  assert.throws(() =>
    birthDateInput("2012-02-30", new Date("2026-09-10T00:00:00+07:00")),
  );
  assert.throws(() =>
    birthDateInput("2027-01-01", new Date("2026-09-10T00:00:00+07:00")),
  );
});

test("reset menolak pemanggil yang belum login", async () => {
  await assert.rejects(
    runResetSantriPasswordFromBirthDate(
      { auth: null, data: {} },
      harness().overrides,
    ),
    (error) => error.code === "unauthenticated",
  );
});

test("reset mengubah auth, mencabut sesi, dan tidak mengembalikan password", async () => {
  const ctx = harness();
  const result = await runResetSantriPasswordFromBirthDate(
    {
      auth: { uid: "admin-1" },
      data: { santriId: "santri-1", birthDate: "2012-03-09" },
    },
    ctx.overrides,
  );

  assert.deepEqual(result, { reset: true });
  assert.equal(Object.hasOwn(result, "password"), false);
  assert.deepEqual(ctx.authCalls, [
    {
      type: "update",
      uid: "santri-1",
      data: { password: "20120309" },
    },
    { type: "revoke", uid: "santri-1" },
  ]);
  assert.equal(ctx.updates[0].data.password_reset_pending_birth_date, "2012-03-09");
  assert.equal(ctx.updates[1].data.password_reset_pending_birth_date, "delete-field");
});

test("kegagalan auth menyisakan marker agar reset dapat dicoba lagi", async () => {
  const ctx = harness({ authFailure: { code: "auth/internal-error" } });

  await assert.rejects(
    runResetSantriPasswordFromBirthDate(
      {
        auth: { uid: "admin-1" },
        data: { santriId: "santri-1", birthDate: "2012-03-09" },
      },
      ctx.overrides,
    ),
    (error) => error.code === "internal",
  );

  assert.equal(ctx.updates.length, 1);
  assert.equal(ctx.updates[0].data.password_reset_pending_birth_date, "2012-03-09");
});
