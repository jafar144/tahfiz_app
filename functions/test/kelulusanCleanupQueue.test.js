"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  CLEANUP_STATE,
  RESERVATION_STATE,
  DELETING_STATE,
  cleanupDocumentId,
  claimQueuedStoragePath,
  deleteQueuedStoragePaths,
  drainKelulusanCleanupQueue,
} = require("../lib/kelulusanCleanupQueue");

const NOW = new Date("2026-07-30T08:00:00.000Z");

function firestoreHarness(path, marker = {}) {
  const markerId = cleanupDocumentId(path);
  const queue = new Map([
    [
      markerId,
      {
        path,
        state: CLEANUP_STATE,
        not_before: NOW,
        ...marker,
      },
    ],
  ]);

  function snapshot(reference, data) {
    return {
      id: reference.id,
      ref: reference,
      exists: data !== undefined,
      data: () => data,
    };
  }

  function reference(collectionName, id) {
    return {
      collectionName,
      id,
      async delete() {
        if (collectionName === "kelulusan_storage_cleanup") {
          queue.delete(id);
        }
      },
    };
  }

  function collection(collectionName) {
    return {
      doc(id) {
        return reference(collectionName, id);
      },
      where(field, operator, value) {
        assert.equal(collectionName, "kelulusan");
        assert.equal(field, "storage_path");
        assert.equal(operator, "==");
        return {
          limit() {
            return {
              kind: "query",
              collectionName,
              value,
            };
          },
        };
      },
    };
  }

  const firestore = {
    collection,
    async runTransaction(callback) {
      const pending = [];
      const transaction = {
        async get(target) {
          if (target.kind === "query") {
            return { empty: true, docs: [] };
          }
          const data =
            target.collectionName === "kelulusan_storage_cleanup"
              ? queue.get(target.id)
              : undefined;
          return snapshot(target, data);
        },
        set(referenceValue, data) {
          pending.push({ kind: "set", referenceValue, data });
        },
        delete(referenceValue) {
          pending.push({ kind: "delete", referenceValue });
        },
      };
      const result = await callback(transaction);
      for (const operation of pending) {
        if (
          operation.referenceValue.collectionName !==
          "kelulusan_storage_cleanup"
        ) {
          continue;
        }
        if (operation.kind === "delete") {
          queue.delete(operation.referenceValue.id);
        } else {
          queue.set(operation.referenceValue.id, operation.data);
        }
      }
      return result;
    },
  };

  return {
    firestore,
    markerId,
    get marker() {
      return queue.get(markerId);
    },
  };
}

test("antrean dipertahankan ketika penghapusan Storage gagal", async () => {
  const path = "syahadah_photos/old.jpg";
  const harness = firestoreHarness(path);
  const bucket = {
    file() {
      return {
        async delete() {
          const error = new Error("storage unavailable");
          error.code = 503;
          throw error;
        },
      };
    },
  };

  const result = await deleteQueuedStoragePaths([path], {
    bucket,
    firestore: harness.firestore,
    now: NOW,
  });

  assert.deepEqual(result.failedPaths, [path]);
  assert.equal(result.deleted, 0);
  assert.equal(harness.marker.state, CLEANUP_STATE);
});

test("file yang sudah hilang dianggap bersih dan antreannya dihapus", async () => {
  const path = "syahadah_photos/already-gone.jpg";
  const harness = firestoreHarness(path);
  const bucket = {
    file() {
      return {
        async delete() {
          const error = new Error("not found");
          error.code = 404;
          throw error;
        },
      };
    },
  };

  const result = await deleteQueuedStoragePaths([path], {
    bucket,
    firestore: harness.firestore,
    now: NOW,
  });

  assert.deepEqual(result.failedPaths, []);
  assert.equal(result.deleted, 0);
  assert.equal(harness.marker, undefined);
});

test("claim transaksional mencegah worker kedua menghapus path yang sama", async () => {
  const path = "syahadah_photos/staff-a/claimed.jpg";
  const harness = firestoreHarness(path);

  const first = await claimQueuedStoragePath(path, {
    firestore: harness.firestore,
    now: NOW,
    claimToken: "worker-a",
  });
  const second = await claimQueuedStoragePath(path, {
    firestore: harness.firestore,
    now: NOW,
    claimToken: "worker-b",
  });

  assert.deepEqual(first, { active: false, claimToken: "worker-a" });
  assert.equal(second, null);
  assert.equal(harness.marker.state, DELETING_STATE);
  assert.equal(harness.marker.claim_token, "worker-a");
});

test("drain tidak menghapus path yang masih aktif", async () => {
  const path = "syahadah_photos/active.jpg";
  let storageDeletes = 0;
  const imageUrl =
    "https://firebasestorage.googleapis.com/v0/b/demo.appspot.com/o/" +
    `${encodeURIComponent(path)}?alt=media`;
  const firestore = {
    collection(name) {
      if (name === "kelulusan_storage_cleanup") {
        return {
          async get() {
            return {
              docs: [
                {
                  data: () => ({
                    path,
                    state: CLEANUP_STATE,
                    not_before: NOW,
                  }),
                },
              ],
            };
          },
        };
      }
      assert.equal(name, "kelulusan");
      return {
        async get() {
          return {
            docs: [{ data: () => ({ image_url: imageUrl }) }],
          };
        },
      };
    },
  };
  const bucket = {
    name: "demo.appspot.com",
    file() {
      return {
        async delete() {
          storageDeletes++;
        },
      };
    },
  };

  const result = await drainKelulusanCleanupQueue({
    bucket,
    firestore,
    now: NOW,
  });

  assert.equal(storageDeletes, 0);
  assert.deepEqual(result, { deleted: 0, failedPaths: [] });
});

test("reservation upload tidak dibersihkan sebelum masa tenggang", async () => {
  const path = "syahadah_photos/staff-a/reserved.jpg";
  let storageDeletes = 0;
  const firestore = {
    collection(name) {
      if (name === "kelulusan_storage_cleanup") {
        return {
          async get() {
            return {
              docs: [
                {
                  data: () => ({
                    path,
                    state: RESERVATION_STATE,
                    not_before: new Date(
                      "2026-07-31T08:00:00.000Z",
                    ),
                  }),
                },
              ],
            };
          },
        };
      }
      assert.equal(name, "kelulusan");
      return {
        async get() {
          return { docs: [] };
        },
      };
    },
  };
  const bucket = {
    name: "demo.appspot.com",
    file() {
      return {
        async delete() {
          storageDeletes++;
        },
      };
    },
  };

  const result = await drainKelulusanCleanupQueue({
    bucket,
    firestore,
    now: NOW,
  });

  assert.equal(storageDeletes, 0);
  assert.deepEqual(result, { deleted: 0, failedPaths: [] });
});
