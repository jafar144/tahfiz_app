"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  assertStaffCanManageSantri,
} = require("../lib/authz");

function fakeFirestore(documents) {
  return {
    collection(collectionName) {
      return {
        doc(documentId) {
          return {
            async get() {
              const data = documents[`${collectionName}/${documentId}`];
              return {
                exists: data != null,
                data: () => data,
              };
            },
          };
        },
      };
    },
  };
}

test("admin dapat mengelola santri yang valid tanpa terikat halaqah", async () => {
  const firestore = fakeFirestore({
    "santri_profiles/santri-a": { halaqah_id: "" },
  });

  await assert.doesNotReject(() =>
    assertStaffCanManageSantri({
      uid: "admin-a",
      user: { role: "admin" },
      santriId: "santri-a",
      firestore,
    }),
  );
});

test("asatidz hanya dapat mengelola santri pada halaqah sendiri", async () => {
  const firestore = fakeFirestore({
    "santri_profiles/santri-a": { halaqah_id: "halaqah-a" },
    "halaqahs/halaqah-a": { asatidz: { id: "asatidz-a" } },
  });

  await assert.doesNotReject(() =>
    assertStaffCanManageSantri({
      uid: "asatidz-a",
      user: { role: "asatidz" },
      santriId: "santri-a",
      firestore,
    }),
  );
  await assert.rejects(
    () =>
      assertStaffCanManageSantri({
        uid: "asatidz-lain",
        user: { role: "asatidz" },
        santriId: "santri-a",
        firestore,
      }),
    (error) => error.code === "permission-denied",
  );
});

test("ID santri yang tidak terdaftar selalu ditolak", async () => {
  const firestore = fakeFirestore({});

  await assert.rejects(
    () =>
      assertStaffCanManageSantri({
        uid: "admin-a",
        user: { role: "admin" },
        santriId: "tidak-ada",
        firestore,
      }),
    (error) => error.code === "not-found",
  );
});
