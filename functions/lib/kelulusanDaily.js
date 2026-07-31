const { createHash } = require("node:crypto");
const { storageObjectFromUrl } = require("./storagePath");

const WIB_OFFSET_MS = 7 * 60 * 60 * 1000;

function kelulusanDateKey(value = new Date()) {
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return new Date(date.getTime() + WIB_OFFSET_MS).toISOString().slice(0, 10);
}

function canonicalKelulusanId(santriId, dateKey) {
  return `${santriId}_${dateKey}`;
}

function kelulusanUploadPath({
  uploaderUid,
  santriId,
  dateKey,
  operationId,
}) {
  return (
    `syahadah_photos/${uploaderUid}/` +
    `${santriId}_${dateKey}_${operationId}.jpg`
  );
}

function timestampDate(value) {
  if (value instanceof Date) return value;
  if (value && typeof value.toDate === "function") return value.toDate();
  if (typeof value === "string" || typeof value === "number") {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }
  return null;
}

function isKelulusanOnDate(data, dateKey) {
  if (String(data?.day_key || "") === dateKey) return true;
  const createdAt = timestampDate(data?.created_at);
  return createdAt ? kelulusanDateKey(createdAt) === dateKey : false;
}

function matchingKelulusanRecords(records, santriId, dateKey) {
  return records.filter((record) => {
    const data = record.data || {};
    return (
      String(data.santri_id || "") === santriId &&
      isKelulusanOnDate(data, dateKey)
    );
  });
}

function kelulusanRevision(records, santriId, dateKey) {
  const normalized = matchingKelulusanRecords(
    records,
    santriId,
    dateKey,
  )
    .map((record) => {
      const data = record.data || {};
      return {
        id: String(record.id || ""),
        operationId: String(data.operation_id || ""),
        imageUrl: String(data.image_url || ""),
        createdAt: timestampDate(data.created_at)?.toISOString() || "",
      };
    })
    .sort((left, right) => left.id.localeCompare(right.id));
  return createHash("sha256")
    .update(JSON.stringify(normalized))
    .digest("hex");
}

function planKelulusanUpsert({
  records,
  santriId,
  dateKey,
  operationId,
  newStoragePath,
  storageBucket,
  replaceExisting,
}) {
  const matching = matchingKelulusanRecords(records, santriId, dateKey);
  const sameOperation = matching.some(
    (record) => String(record.data?.operation_id || "") === operationId,
  );
  const conflict =
    matching.length > 0 && !sameOperation && replaceExisting !== true;
  const canonicalId = canonicalKelulusanId(santriId, dateKey);

  const documentIdsToDelete = matching
    .map((record) => record.id)
    .filter((id) => id !== canonicalId);
  const oldStoragePaths = [
    ...new Set(
      matching
        .map((record) => storageObjectFromUrl(record.data?.image_url))
        .filter(
          (object) =>
            object?.bucket === storageBucket &&
            object.path !== newStoragePath &&
            object.path.startsWith("syahadah_photos/"),
        )
        .map((object) => object.path),
    ),
  ];

  return {
    canonicalId,
    conflict,
    existingCount: matching.length,
    idempotent: sameOperation,
    documentIdsToDelete,
    oldStoragePaths,
  };
}

module.exports = {
  kelulusanDateKey,
  canonicalKelulusanId,
  kelulusanUploadPath,
  isKelulusanOnDate,
  matchingKelulusanRecords,
  kelulusanRevision,
  planKelulusanUpsert,
};
