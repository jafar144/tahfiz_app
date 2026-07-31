"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  canonicalKelulusanId,
  kelulusanDateKey,
  kelulusanUploadPath,
  planKelulusanUpsert,
} = require("../lib/kelulusanDaily");

const SANTRI_ID = "santri-a";
const UPLOADER_UID = "staff-a";
const DATE_KEY = "2026-07-30";

function imageUrl(path, bucket = "demo.appspot.com") {
  return (
    `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/` +
    `${encodeURIComponent(path)}?alt=media`
  );
}

function record({
  id,
  santriId = SANTRI_ID,
  dayKey,
  createdAt,
  operationId,
  storagePath,
  storageBucket,
}) {
  const data = {
    santri_id: santriId,
  };
  if (dayKey !== undefined) data.day_key = dayKey;
  if (createdAt !== undefined) data.created_at = createdAt;
  if (operationId !== undefined) data.operation_id = operationId;
  if (storagePath !== undefined) {
    data.image_url = imageUrl(storagePath, storageBucket);
  }

  return {
    id,
    data,
  };
}

function plan({
  records,
  operationId = "operation-new",
  replaceExisting = false,
}) {
  return planKelulusanUpsert({
    records,
    santriId: SANTRI_ID,
    dateKey: DATE_KEY,
    operationId,
    newStoragePath: kelulusanUploadPath({
      uploaderUid: UPLOADER_UID,
      santriId: SANTRI_ID,
      dateKey: DATE_KEY,
      operationId,
    }),
    storageBucket: "demo.appspot.com",
    replaceExisting,
  });
}

test("tanggal kelulusan berpindah tepat pada tengah malam WIB", () => {
  assert.equal(
    kelulusanDateKey(new Date("2026-07-30T16:59:59.999Z")),
    "2026-07-30",
  );
  assert.equal(
    kelulusanDateKey(new Date("2026-07-30T17:00:00.000Z")),
    "2026-07-31",
  );
});

test("record santri pada hari yang sama menjadi conflict tanpa replace", () => {
  const result = plan({
    records: [
      record({
        id: "legacy-random-id",
        dayKey: DATE_KEY,
        operationId: "operation-old",
        storagePath: "syahadah_photos/old.jpg",
      }),
    ],
  });

  assert.equal(result.conflict, true);
  assert.equal(result.existingCount, 1);
  assert.equal(result.idempotent, false);
  assert.equal(result.canonicalId, canonicalKelulusanId(SANTRI_ID, DATE_KEY));
});

test("replace merencanakan pembersihan seluruh tiga foto lama", () => {
  const canonicalId = canonicalKelulusanId(SANTRI_ID, DATE_KEY);
  const result = plan({
    replaceExisting: true,
    records: [
      record({
        id: canonicalId,
        dayKey: DATE_KEY,
        operationId: "operation-old-a",
        storagePath: "syahadah_photos/old-a.jpg",
      }),
      record({
        id: "legacy-random-b",
        createdAt: new Date("2026-07-30T08:00:00.000Z"),
        operationId: "operation-old-b",
        storagePath: "syahadah_photos/old-b.jpg",
      }),
      record({
        id: "legacy-random-c",
        dayKey: DATE_KEY,
        operationId: "operation-old-c",
        storagePath: "syahadah_photos/old-c.jpg",
      }),
    ],
  });

  assert.equal(result.conflict, false);
  assert.equal(result.existingCount, 3);
  assert.deepEqual(
    [...result.documentIdsToDelete].sort(),
    ["legacy-random-b", "legacy-random-c"],
  );
  assert.deepEqual(
    [...result.oldStoragePaths].sort(),
    [
      "syahadah_photos/old-a.jpg",
      "syahadah_photos/old-b.jpg",
      "syahadah_photos/old-c.jpg",
    ],
  );
});

test("foto dari hari lain dan santri lain tidak dianggap duplicate", () => {
  const result = plan({
    records: [
      record({
        id: "yesterday",
        dayKey: "2026-07-29",
        operationId: "operation-yesterday",
        storagePath: "syahadah_photos/yesterday.jpg",
      }),
      record({
        id: "tomorrow-legacy",
        createdAt: new Date("2026-07-30T17:00:00.000Z"),
        operationId: "operation-tomorrow",
        storagePath: "syahadah_photos/tomorrow.jpg",
      }),
      record({
        id: "other-santri",
        santriId: "santri-b",
        dayKey: DATE_KEY,
        operationId: "operation-other",
        storagePath: "syahadah_photos/other.jpg",
      }),
    ],
  });

  assert.equal(result.conflict, false);
  assert.equal(result.existingCount, 0);
  assert.equal(result.idempotent, false);
  assert.deepEqual(result.documentIdsToDelete, []);
  assert.deepEqual(result.oldStoragePaths, []);
});

test("operationId yang sama bersifat idempoten tanpa meminta replace", () => {
  const operationId = "operation-same";
  const storagePath = kelulusanUploadPath({
    uploaderUid: UPLOADER_UID,
    santriId: SANTRI_ID,
    dateKey: DATE_KEY,
    operationId,
  });
  const result = plan({
    operationId,
    records: [
      record({
        id: canonicalKelulusanId(SANTRI_ID, DATE_KEY),
        dayKey: DATE_KEY,
        operationId,
        storagePath,
      }),
    ],
  });

  assert.equal(result.conflict, false);
  assert.equal(result.existingCount, 1);
  assert.equal(result.idempotent, true);
  assert.deepEqual(result.documentIdsToDelete, []);
  assert.deepEqual(result.oldStoragePaths, []);
});

test("path dari bucket asing tidak pernah masuk rencana penghapusan", () => {
  const result = plan({
    replaceExisting: true,
    records: [
      record({
        id: "foreign-bucket",
        dayKey: DATE_KEY,
        operationId: "operation-old",
        storagePath: "syahadah_photos/same-name.jpg",
        storageBucket: "other.appspot.com",
      }),
    ],
  });

  assert.equal(result.existingCount, 1);
  assert.deepEqual(result.oldStoragePaths, []);
});
