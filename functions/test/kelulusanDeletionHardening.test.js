"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  runDeleteKelulusanPhoto,
} = require("../handlers/kelulusanAdmin");
const {
  runCleanup,
} = require("../handlers/cleanupExpiredSyahadah");

const BUCKET_NAME = "demo.appspot.com";
const NOW = new Date("2026-07-30T08:00:00.000Z");

function downloadUrl(path, bucket = BUCKET_NAME) {
  return (
    "https://firebasestorage.googleapis.com/v0/b/" +
    `${bucket}/o/${encodeURIComponent(path)}?alt=media`
  );
}

function createHarness({
  documents = {},
  queriedKelulusan = [],
  failedStoragePaths = [],
} = {}) {
  const stores = new Map();
  const events = [];
  const deletedStoragePaths = [];
  const failingPaths = new Set(failedStoragePaths);

  function store(collectionName) {
    if (!stores.has(collectionName)) {
      stores.set(collectionName, new Map());
    }
    return stores.get(collectionName);
  }

  for (const [key, data] of Object.entries(documents)) {
    const separator = key.indexOf("/");
    const collectionName = key.slice(0, separator);
    const id = key.slice(separator + 1);
    store(collectionName).set(id, data);
  }

  function reference(collectionName, id) {
    return {
      collectionName,
      id,
      async get() {
        const data = store(collectionName).get(id);
        return snapshot(this, data);
      },
      async delete() {
        events.push(`direct:delete:${collectionName}:${id}`);
        store(collectionName).delete(id);
      },
    };
  }

  function snapshot(ref, data) {
    return {
      id: ref.id,
      ref,
      exists: data !== undefined,
      data: () => data,
    };
  }

  const firestore = {
    collection(collectionName) {
      return {
        doc(id) {
          return reference(collectionName, id);
        },
        async get() {
          return {
            empty: store(collectionName).size === 0,
            docs: [...store(collectionName).entries()].map(([id, data]) => {
              const ref = reference(collectionName, id);
              return snapshot(ref, data);
            }),
          };
        },
        where(field, operator, value) {
          assert.equal(collectionName, "kelulusan");
          if (field === "created_at") {
            assert.equal(operator, "<");
            return {
              async get() {
                return {
                  empty: queriedKelulusan.length === 0,
                  docs: queriedKelulusan.map(({ id, data }) => {
                    const ref = reference(collectionName, id);
                    return snapshot(ref, data);
                  }),
                };
              },
            };
          }
          assert.equal(field, "storage_path");
          assert.equal(operator, "==");
          return {
            limit(limitValue) {
              assert.equal(limitValue, 1);
              return {
                kind: "query",
                collectionName,
                field,
                value,
              };
            },
          };
        },
      };
    },
    async runTransaction(callback) {
      const pending = [];
      const transaction = {
        async get(ref) {
          if (ref.kind === "query") {
            const matching = [...store(ref.collectionName).entries()]
              .filter(([, data]) => data?.[ref.field] === ref.value)
              .slice(0, 1)
              .map(([id, data]) =>
                snapshot(reference(ref.collectionName, id), data),
              );
            return {
              empty: matching.length === 0,
              docs: matching,
            };
          }
          events.push(`tx:get:${ref.collectionName}:${ref.id}`);
          return ref.get();
        },
        set(ref, data, options) {
          events.push(`tx:set:${ref.collectionName}:${ref.id}`);
          pending.push({ kind: "set", ref, data, options });
        },
        delete(ref) {
          events.push(`tx:delete:${ref.collectionName}:${ref.id}`);
          pending.push({ kind: "delete", ref });
        },
      };

      try {
        const result = await callback(transaction);
        for (const operation of pending) {
          const target = store(operation.ref.collectionName);
          if (operation.kind === "delete") {
            target.delete(operation.ref.id);
          } else if (operation.options?.merge) {
            target.set(operation.ref.id, {
              ...(target.get(operation.ref.id) || {}),
              ...operation.data,
            });
          } else {
            target.set(operation.ref.id, operation.data);
          }
        }
        events.push("tx:commit");
        return result;
      } catch (error) {
        events.push("tx:abort");
        throw error;
      }
    },
  };

  const bucket = {
    name: BUCKET_NAME,
    file(path) {
      return {
        async delete() {
          events.push(`storage:delete:${path}`);
          if (failingPaths.has(path)) {
            const error = new Error("storage unavailable");
            error.code = 503;
            throw error;
          }
          deletedStoragePaths.push(path);
        },
      };
    },
  };

  return {
    firestore,
    bucket,
    events,
    deletedStoragePaths,
    getDocument(collectionName, id) {
      return store(collectionName).get(id);
    },
    documentsIn(collectionName) {
      return [...store(collectionName).values()];
    },
  };
}

test("delete manual mengantrekan file dan dokumen dalam transaksi yang sama", async () => {
  const id = "kelulusan-a";
  const path = "syahadah_photos/kelulusan-a.jpg";
  const harness = createHarness({
    documents: {
      [`kelulusan/${id}`]: {
        image_url: downloadUrl(path),
      },
    },
  });

  const result = await runDeleteKelulusanPhoto(
    {
      auth: { uid: "admin-a" },
      data: { id, expectedImageUrl: downloadUrl(path) },
    },
    {
      db: harness.firestore,
      bucket: harness.bucket,
      now: () => NOW,
      assertAdmin: async (uid) => assert.equal(uid, "admin-a"),
    },
  );

  const queueIndex = harness.events.findIndex((event) =>
    event.startsWith("tx:set:kelulusan_storage_cleanup:"),
  );
  const documentDeleteIndex = harness.events.indexOf(
    `tx:delete:kelulusan:${id}`,
  );
  const commitIndex = harness.events.indexOf("tx:commit");
  const storageDeleteIndex = harness.events.indexOf(`storage:delete:${path}`);

  assert.ok(queueIndex >= 0, "file harus masuk antrean di transaksi");
  assert.ok(documentDeleteIndex >= 0, "dokumen harus dihapus di transaksi");
  assert.ok(queueIndex < commitIndex);
  assert.ok(documentDeleteIndex < commitIndex);
  assert.ok(commitIndex < storageDeleteIndex);
  assert.equal(harness.getDocument("kelulusan", id), undefined);
  assert.deepEqual(harness.deletedStoragePaths, [path]);
  assert.deepEqual(harness.documentsIn("kelulusan_storage_cleanup"), []);
  assert.deepEqual(result, {
    deleted: true,
    deletedFiles: 1,
    pendingFileCleanup: 0,
  });
});

test("delete manual menolak URL dari bucket Storage asing", async () => {
  const id = "kelulusan-asing";
  const path = "syahadah_photos/asing.jpg";
  const original = {
    image_url: downloadUrl(path, "bucket-asing.appspot.com"),
  };
  const harness = createHarness({
    documents: {
      [`kelulusan/${id}`]: original,
    },
  });

  await assert.rejects(
    () =>
      runDeleteKelulusanPhoto(
        {
          auth: { uid: "admin-a" },
          data: {
            id,
            expectedImageUrl: downloadUrl(
              path,
              "bucket-asing.appspot.com",
            ),
          },
        },
        {
          db: harness.firestore,
          bucket: harness.bucket,
          now: () => NOW,
          assertAdmin: async () => {},
        },
      ),
    (error) => error.code === "failed-precondition",
  );

  assert.deepEqual(harness.getDocument("kelulusan", id), original);
  assert.equal(
    harness.events.some((event) =>
      event.startsWith("tx:set:kelulusan_storage_cleanup:"),
    ),
    false,
  );
  assert.equal(
    harness.events.some((event) => event.startsWith("tx:delete:")),
    false,
  );
  assert.deepEqual(harness.deletedStoragePaths, []);
  assert.ok(harness.events.includes("tx:abort"));
});

test("delete stale tidak menghapus replacement canonical yang lebih baru", async () => {
  const id = "santri-a_2026-07-30";
  const oldPath = "syahadah_photos/staff-a/old.jpg";
  const newPath = "syahadah_photos/staff-a/new.jpg";
  const replacement = {
    image_url: downloadUrl(newPath),
    operation_id: "operation-new",
  };
  const harness = createHarness({
    documents: {
      [`kelulusan/${id}`]: replacement,
    },
  });

  await assert.rejects(
    () =>
      runDeleteKelulusanPhoto(
        {
          auth: { uid: "admin-a" },
          data: {
            id,
            expectedImageUrl: downloadUrl(oldPath),
            expectedOperationId: "operation-old",
          },
        },
        {
          db: harness.firestore,
          bucket: harness.bucket,
          now: () => NOW,
          assertAdmin: async () => {},
        },
      ),
    (error) => error.code === "failed-precondition",
  );

  assert.deepEqual(harness.getDocument("kelulusan", id), replacement);
  assert.deepEqual(harness.deletedStoragePaths, []);
  assert.deepEqual(
    harness.documentsIn("kelulusan_storage_cleanup"),
    [],
  );
});

test("cleanup tidak menghapus canonical baru dari hasil query yang stale", async () => {
  const id = "santri-a_2026-07-30";
  const path = "syahadah_photos/canonical-baru.jpg";
  const freshData = {
    image_url: downloadUrl(path),
    created_at: new Date("2026-07-30T07:00:00.000Z"),
  };
  const harness = createHarness({
    documents: {
      [`kelulusan/${id}`]: freshData,
    },
    queriedKelulusan: [
      {
        id,
        data: {
          image_url: downloadUrl("syahadah_photos/canonical-lama.jpg"),
          created_at: new Date("2026-07-10T07:00:00.000Z"),
        },
      },
    ],
  });

  const result = await runCleanup({
    db: harness.firestore,
    bucket: harness.bucket,
    now: () => NOW,
  });

  assert.deepEqual(harness.getDocument("kelulusan", id), freshData);
  assert.deepEqual(harness.deletedStoragePaths, []);
  assert.deepEqual(harness.documentsIn("kelulusan_storage_cleanup"), []);
  assert.equal(
    harness.events.some((event) => event === `tx:delete:kelulusan:${id}`),
    false,
  );
  assert.deepEqual(result, {
    deletedDocs: 0,
    deletedFiles: 0,
    pendingFileCleanup: 0,
  });
});

test("cleanup mempertahankan antrean saat file expired gagal dihapus", async () => {
  const id = "kelulusan-expired";
  const path = "syahadah_photos/expired.jpg";
  const expiredData = {
    image_url: downloadUrl(path),
    created_at: new Date("2026-07-10T07:00:00.000Z"),
  };
  const harness = createHarness({
    documents: {
      [`kelulusan/${id}`]: expiredData,
    },
    queriedKelulusan: [{ id, data: expiredData }],
    failedStoragePaths: [path],
  });

  const result = await runCleanup({
    db: harness.firestore,
    bucket: harness.bucket,
    now: () => NOW,
  });

  assert.equal(harness.getDocument("kelulusan", id), undefined);
  assert.deepEqual(harness.deletedStoragePaths, []);
  assert.deepEqual(
    harness.documentsIn("kelulusan_storage_cleanup").map((data) => data.path),
    [path],
  );
  assert.deepEqual(result, {
    deletedDocs: 1,
    deletedFiles: 0,
    pendingFileCleanup: 1,
  });
});
