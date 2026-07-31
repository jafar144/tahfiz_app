"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  runCheckKelulusanPhoto,
  runReserveKelulusanPhoto,
  runSaveKelulusanPhoto,
} = require("../handlers/kelulusanSave");
const {
  canonicalKelulusanId,
  kelulusanRevision,
  kelulusanUploadPath,
} = require("../lib/kelulusanDaily");
const {
  CLEANUP_STATE,
  DELETING_STATE,
  RESERVATION_STATE,
  cleanupDocumentId,
} = require("../lib/kelulusanCleanupQueue");

const NOW = new Date("2026-07-30T08:00:00.000Z");
const DATE_KEY = "2026-07-30";
const BUCKET_NAME = "demo.appspot.com";
const SANTRI_ID = "santri-a";
const STAFF_UID = "staff-a";

function downloadUrl(path, {
  host = "firebasestorage.googleapis.com",
  bucket = BUCKET_NAME,
} = {}) {
  return `https://${host}/v0/b/${bucket}/o/${encodeURIComponent(path)}?alt=media`;
}

function request({
  operationId = "operation-new",
  replaceExisting = false,
  imageUrl,
} = {}) {
  const path = kelulusanUploadPath({
    uploaderUid: STAFF_UID,
    santriId: SANTRI_ID,
    dateKey: DATE_KEY,
    operationId,
  });
  return {
    auth: { uid: STAFF_UID },
    data: {
      santriId: SANTRI_ID,
      santriName: "Ahmad",
      kelas: "Mutawassith",
      hafalan: "Juz 30",
      dateKey: DATE_KEY,
      operationId,
      replaceExisting,
      imageUrl: imageUrl ?? downloadUrl(path),
    },
  };
}

function snapshot(id, data) {
  return {
    id,
    exists: data != null,
    data: () => data,
  };
}

function createHarness({
  canonicalData = null,
  queryRecords = [],
  reservationOperationId = "operation-new",
  reservationReplaceExisting = false,
  reservationData,
  metadata = {
    contentType: "image/jpeg",
    size: "2048",
    metadata: { uploader_uid: STAFF_UID },
  },
  now = NOW,
} = {}) {
  const events = [];
  const writes = [];
  const cleanupQueues = [];
  const cleanupDeletes = [];
  let transactionCalls = 0;
  let metadataCalls = 0;

  const kelulusanCollection = {
    doc(id) {
      return { kind: "document", collectionName: "kelulusan", id };
    },
    where(field, operator, value) {
      return { kind: "query", field, operator, value };
    },
  };
  const revision = kelulusanRevision(
    queryRecords,
    SANTRI_ID,
    DATE_KEY,
  );
  const marker =
    reservationData === null
      ? null
      : reservationData ?? {
          path: kelulusanUploadPath({
            uploaderUid: STAFF_UID,
            santriId: SANTRI_ID,
            dateKey: DATE_KEY,
            operationId: reservationOperationId,
          }),
          state: RESERVATION_STATE,
          uploader_uid: STAFF_UID,
          santri_id: SANTRI_ID,
          date_key: DATE_KEY,
          operation_id: reservationOperationId,
          confirmed_revision: revision,
          replace_existing: reservationReplaceExisting,
          not_before: new Date("2026-07-31T08:00:00.000Z"),
        };

  const transaction = {
    async get(target) {
      if (target.kind === "document") {
        events.push(`get-document:${target.collectionName}:${target.id}`);
        return snapshot(
          target.id,
          target.collectionName === "kelulusan"
            ? canonicalData
            : marker,
        );
      }
      events.push(`get-query:${target.field}:${target.value}`);
      return {
        docs: queryRecords.map((record) =>
          snapshot(record.id, record.data),
        ),
      };
    },
    set(reference, data) {
      events.push(`set-document:${reference.collectionName}:${reference.id}`);
      writes.push({
        collectionName: reference.collectionName,
        id: reference.id,
        data,
      });
    },
    delete(reference) {
      events.push(
        `delete-document:${reference.collectionName}:${reference.id}`,
      );
    },
  };

  const firestore = {
    collection(name) {
      if (name === "kelulusan") return kelulusanCollection;
      assert.equal(name, "kelulusan_storage_cleanup");
      return {
        doc(id) {
          return {
            kind: "document",
            collectionName: name,
            id,
          };
        },
      };
    },
    async runTransaction(callback) {
      transactionCalls++;
      return callback(transaction);
    },
  };

  const bucket = {
    name: BUCKET_NAME,
    file(path) {
      return {
        async getMetadata() {
          metadataCalls++;
          events.push(`metadata:${path}`);
          return [metadata];
        },
      };
    },
  };

  const dependencies = {
    db: firestore,
    bucket,
    now: () => now,
    assertStaff: async (uid) => {
      assert.equal(uid, STAFF_UID);
      return { role: "asatidz" };
    },
    assertSantriAccess: async ({ uid, santriId }) => {
      assert.equal(uid, STAFF_UID);
      assert.equal(santriId, SANTRI_ID);
    },
    queueCleanupInTransaction: ({ paths }) => {
      cleanupQueues.push([...paths]);
      events.push(`queue-cleanup:${paths.join(",")}`);
    },
    queueCleanupPaths: async (paths) => {
      cleanupQueues.push([...paths]);
      events.push(`queue-cleanup:${paths.join(",")}`);
    },
    deleteQueuedStoragePaths: async (paths) => {
      cleanupDeletes.push([...paths]);
      events.push(`delete-cleanup:${paths.join(",")}`);
      return { deleted: paths.length, failedPaths: [] };
    },
  };

  return {
    events,
    writes,
    cleanupQueues,
    cleanupDeletes,
    dependencies,
    get transactionCalls() {
      return transactionCalls;
    },
    get metadataCalls() {
      return metadataCalls;
    },
  };
}

test("save pertama mengunci canonical sebelum query lalu menulis canonical", async () => {
  const operationId = "operation-first";
  const harness = createHarness({
    reservationOperationId: operationId,
  });
  const result = await runSaveKelulusanPhoto(
    request({ operationId }),
    harness.dependencies,
  );
  const canonicalId = canonicalKelulusanId(SANTRI_ID, DATE_KEY);

  const lockIndex = harness.events.indexOf(
    `get-document:kelulusan:${canonicalId}`,
  );
  const queryIndex = harness.events.indexOf(
    `get-query:santri_id:${SANTRI_ID}`,
  );
  const writeIndex = harness.events.indexOf(
    `set-document:kelulusan:${canonicalId}`,
  );

  assert.ok(lockIndex >= 0, "canonical document harus dibaca");
  assert.ok(queryIndex > lockIndex, "canonical harus dikunci sebelum query");
  assert.ok(writeIndex > queryIndex, "canonical ditulis setelah seluruh read");
  assert.equal(harness.writes.length, 1);
  assert.equal(harness.writes[0].collectionName, "kelulusan");
  assert.equal(harness.writes[0].id, canonicalId);
  assert.equal(harness.writes[0].data.operation_id, operationId);
  assert.equal(harness.writes[0].data.day_key, DATE_KEY);
  assert.deepEqual(harness.cleanupQueues, [[]]);
  assert.deepEqual(harness.cleanupDeletes, [[]]);
  assert.equal(result.id, canonicalId);
  assert.equal(result.idempotent, false);
});

test("conflict tanpa replace mengantrekan dan menghapus upload baru", async () => {
  const operationId = "operation-conflict";
  const canonicalId = canonicalKelulusanId(SANTRI_ID, DATE_KEY);
  const existingData = {
    santri_id: SANTRI_ID,
    day_key: DATE_KEY,
    operation_id: "operation-old",
    image_url: downloadUrl("syahadah_photos/old.jpg"),
  };
  const harness = createHarness({
    canonicalData: existingData,
    queryRecords: [{ id: canonicalId, data: existingData }],
    reservationOperationId: operationId,
    reservationReplaceExisting: false,
  });
  const newPath = kelulusanUploadPath({
    uploaderUid: STAFF_UID,
    santriId: SANTRI_ID,
    dateKey: DATE_KEY,
    operationId,
  });

  await assert.rejects(
    () =>
      runSaveKelulusanPhoto(
        request({ operationId, replaceExisting: false }),
        harness.dependencies,
      ),
    (error) => {
      assert.equal(error.code, "already-exists");
      return true;
    },
  );

  assert.deepEqual(harness.cleanupQueues, [[newPath]]);
  assert.deepEqual(harness.cleanupDeletes, [[newPath]]);
  assert.equal(
    harness.writes.some(
      (write) =>
        write.collectionName === "kelulusan" &&
        write.id === canonicalId,
    ),
    false,
    "record lama tidak boleh ditimpa ketika replace belum disetujui",
  );
});

test("URL dengan host bukan Firebase Storage ditolak", async () => {
  const operationId = "operation-invalid-host";
  const path = kelulusanUploadPath({
    uploaderUid: STAFF_UID,
    santriId: SANTRI_ID,
    dateKey: DATE_KEY,
    operationId,
  });
  const harness = createHarness();

  await assert.rejects(
    () =>
      runSaveKelulusanPhoto(
        request({
          operationId,
          imageUrl: downloadUrl(path, { host: "evil.example" }),
        }),
        harness.dependencies,
      ),
    (error) => error.code === "failed-precondition",
  );

  assert.equal(harness.metadataCalls, 0);
  assert.equal(harness.transactionCalls, 0);
});

test("URL dengan bucket berbeda ditolak", async () => {
  const operationId = "operation-invalid-bucket";
  const path = kelulusanUploadPath({
    uploaderUid: STAFF_UID,
    santriId: SANTRI_ID,
    dateKey: DATE_KEY,
    operationId,
  });
  const harness = createHarness();

  await assert.rejects(
    () =>
      runSaveKelulusanPhoto(
        request({
          operationId,
          imageUrl: downloadUrl(path, { bucket: "other.appspot.com" }),
        }),
        harness.dependencies,
      ),
    (error) => error.code === "failed-precondition",
  );

  assert.equal(harness.metadataCalls, 0);
  assert.equal(harness.transactionCalls, 0);
});

test("file dengan metadata bukan gambar ditolak", async () => {
  const path = kelulusanUploadPath({
    uploaderUid: STAFF_UID,
    santriId: SANTRI_ID,
    dateKey: DATE_KEY,
    operationId: "operation-new",
  });
  const harness = createHarness({
    metadata: {
      contentType: "text/plain",
      size: "2048",
      metadata: { uploader_uid: STAFF_UID },
    },
  });

  await assert.rejects(
    () =>
      runSaveKelulusanPhoto(request(), harness.dependencies),
    (error) => error.code === "failed-precondition",
  );

  assert.equal(harness.metadataCalls, 1);
  assert.equal(harness.transactionCalls, 0);
  assert.deepEqual(harness.cleanupQueues, [[path]]);
  assert.deepEqual(harness.cleanupDeletes, [[path]]);
});

test("file milik uploader lain ditolak tanpa pernah dihapus", async () => {
  const harness = createHarness({
    metadata: {
      contentType: "image/jpeg",
      size: "2048",
      metadata: { uploader_uid: "staff-lain" },
    },
  });

  await assert.rejects(
    () => runSaveKelulusanPhoto(request(), harness.dependencies),
    (error) => error.code === "permission-denied",
  );

  assert.deepEqual(harness.cleanupQueues, []);
  assert.deepEqual(harness.cleanupDeletes, []);
});

test("upload dibersihkan jika tanggal WIB berubah sebelum save", async () => {
  const path = kelulusanUploadPath({
    uploaderUid: STAFF_UID,
    santriId: SANTRI_ID,
    dateKey: DATE_KEY,
    operationId: "operation-new",
  });
  const harness = createHarness({
    now: new Date("2026-07-30T17:00:00.000Z"),
  });

  await assert.rejects(
    () => runSaveKelulusanPhoto(request(), harness.dependencies),
    (error) => error.code === "failed-precondition",
  );

  assert.equal(harness.transactionCalls, 0);
  assert.deepEqual(harness.cleanupQueues, [[path]]);
  assert.deepEqual(harness.cleanupDeletes, [[path]]);
});

test("preflight hanya membaca status dan revision hari berjalan", async () => {
  const firestore = {
    collection(name) {
      assert.equal(name, "kelulusan");
      return {
        where() {
          return {
            async get() {
              return { docs: [] };
            },
          };
        },
      };
    },
  };

  const result = await runCheckKelulusanPhoto(
    {
      auth: { uid: STAFF_UID },
      data: { santriId: SANTRI_ID },
    },
    {
      db: firestore,
      now: () => NOW,
      assertStaff: async () => ({ role: "asatidz" }),
      assertSantriAccess: async () => {},
    },
  );

  assert.equal(result.dateKey, DATE_KEY);
  assert.equal(result.existingCount, 0);
  assert.equal(
    result.revision,
    kelulusanRevision([], SANTRI_ID, DATE_KEY),
  );
});

test("reservation dibuat sesaat sebelum upload dan berlaku 24 jam", async () => {
  const operationId = "operation-reserved";
  const expectedRevision = kelulusanRevision(
    [],
    SANTRI_ID,
    DATE_KEY,
  );
  const harness = createHarness({
    reservationData: null,
  });

  const result = await runReserveKelulusanPhoto(
    {
      auth: { uid: STAFF_UID },
      data: {
        santriId: SANTRI_ID,
        dateKey: DATE_KEY,
        operationId,
        expectedRevision,
        replaceExisting: false,
      },
    },
    harness.dependencies,
  );

  const markerWrite = harness.writes.find(
    (write) =>
      write.collectionName === "kelulusan_storage_cleanup",
  );
  assert.ok(markerWrite, "reservation marker harus ditulis");
  assert.equal(markerWrite.id, cleanupDocumentId(
    kelulusanUploadPath({
      uploaderUid: STAFF_UID,
      santriId: SANTRI_ID,
      dateKey: DATE_KEY,
      operationId,
    }),
  ));
  assert.equal(markerWrite.data.state, RESERVATION_STATE);
  assert.equal(
    markerWrite.data.not_before.toDate().getTime() - NOW.getTime(),
    24 * 60 * 60 * 1000,
  );
  assert.deepEqual(result, {
    dateKey: DATE_KEY,
    alreadyActive: false,
  });
});

test("save baru ditolak jika reservation tidak ada", async () => {
  const harness = createHarness({ reservationData: null });

  await assert.rejects(
    () => runSaveKelulusanPhoto(request(), harness.dependencies),
    (error) => error.code === "failed-precondition",
  );

  assert.equal(
    harness.writes.some(
      (write) => write.collectionName === "kelulusan",
    ),
    false,
  );
});

test("retry idempoten tetap sukses tanpa membuat ulang reservation", async () => {
  const operationId = "operation-already-saved";
  const path = kelulusanUploadPath({
    uploaderUid: STAFF_UID,
    santriId: SANTRI_ID,
    dateKey: DATE_KEY,
    operationId,
  });
  const canonicalId = canonicalKelulusanId(SANTRI_ID, DATE_KEY);
  const existingData = {
    santri_id: SANTRI_ID,
    day_key: DATE_KEY,
    operation_id: operationId,
    storage_path: path,
    image_url: downloadUrl(path),
    created_at: NOW,
  };
  const harness = createHarness({
    canonicalData: existingData,
    queryRecords: [{ id: canonicalId, data: existingData }],
    reservationData: null,
  });

  const result = await runSaveKelulusanPhoto(
    request({ operationId }),
    harness.dependencies,
  );

  assert.equal(result.idempotent, true);
  assert.equal(
    harness.writes.some(
      (write) =>
        write.collectionName === "kelulusan" &&
        write.id === canonicalId,
    ),
    true,
  );
});

test("marker yang sudah di-claim cleanup tidak dapat diaktifkan lagi", async () => {
  const operationId = "operation-obsolete";
  const canonicalId = canonicalKelulusanId(SANTRI_ID, DATE_KEY);
  const existingData = {
    santri_id: SANTRI_ID,
    day_key: DATE_KEY,
    operation_id: "operation-current",
    storage_path: "syahadah_photos/staff-a/current.jpg",
    image_url: downloadUrl("syahadah_photos/staff-a/current.jpg"),
  };
  const harness = createHarness({
    canonicalData: existingData,
    queryRecords: [{ id: canonicalId, data: existingData }],
    reservationData: {
      path: kelulusanUploadPath({
        uploaderUid: STAFF_UID,
        santriId: SANTRI_ID,
        dateKey: DATE_KEY,
        operationId,
      }),
      state: DELETING_STATE,
      claim_token: "cleanup-worker",
      not_before: NOW,
    },
  });

  await assert.rejects(
    () =>
      runSaveKelulusanPhoto(
        request({ operationId, replaceExisting: true }),
        harness.dependencies,
      ),
    (error) => error.code === "already-exists",
  );

  assert.equal(
    harness.writes.some(
      (write) => write.collectionName === "kelulusan",
    ),
    false,
  );
});

test("conflict reservation memberi grace untuk upload timeout yang masih berjalan", async () => {
  const operationId = "operation-upload-timeout";
  const path = kelulusanUploadPath({
    uploaderUid: STAFF_UID,
    santriId: SANTRI_ID,
    dateKey: DATE_KEY,
    operationId,
  });
  const currentData = {
    santri_id: SANTRI_ID,
    day_key: DATE_KEY,
    operation_id: "operation-current",
    image_url: downloadUrl("syahadah_photos/staff-a/current.jpg"),
  };
  const harness = createHarness({
    canonicalData: currentData,
    queryRecords: [
      {
        id: canonicalKelulusanId(SANTRI_ID, DATE_KEY),
        data: currentData,
      },
    ],
    reservationData: {
      path,
      state: RESERVATION_STATE,
      operation_id: operationId,
      not_before: new Date("2026-07-31T08:00:00.000Z"),
    },
  });

  await assert.rejects(
    () =>
      runReserveKelulusanPhoto(
        {
          auth: { uid: STAFF_UID },
          data: {
            santriId: SANTRI_ID,
            dateKey: DATE_KEY,
            operationId,
            expectedRevision: kelulusanRevision(
              [],
              SANTRI_ID,
              DATE_KEY,
            ),
            replaceExisting: false,
          },
        },
        harness.dependencies,
      ),
    (error) => error.code === "already-exists",
  );

  const cleanupWrite = harness.writes.find(
    (write) =>
      write.collectionName === "kelulusan_storage_cleanup" &&
      write.data.state === CLEANUP_STATE,
  );
  assert.ok(cleanupWrite);
  assert.equal(
    cleanupWrite.data.not_before.toDate().getTime() - NOW.getTime(),
    24 * 60 * 60 * 1000,
  );
});
