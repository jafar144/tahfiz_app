const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const { admin, db } = require("../lib/firebase");
const {
  assertStaff,
  assertStaffCanManageSantri,
} = require("../lib/authz");
const { CALLABLE_OPTIONS } = require("../lib/config");
const { storageObjectFromUrl } = require("../lib/storagePath");
const {
  kelulusanDateKey,
  canonicalKelulusanId,
  kelulusanUploadPath,
  isKelulusanOnDate,
  matchingKelulusanRecords,
  kelulusanRevision,
  planKelulusanUpsert,
} = require("../lib/kelulusanDaily");
const {
  CLEANUP_STATE,
  RESERVATION_STATE,
  DELETING_STATE,
  cleanupReference,
  cleanupIsReady,
  queueCleanupInTransaction,
  queueCleanupPaths,
  deleteQueuedStoragePaths,
} = require("../lib/kelulusanCleanupQueue");

const OPTIONS = CALLABLE_OPTIONS;
const COLLECTION = "kelulusan";
const UPLOAD_RESERVATION_GRACE_MS = 24 * 60 * 60 * 1000;

function requiredText(value, field, maxLength) {
  const normalized = String(value || "").trim();
  if (!normalized || normalized.length > maxLength) {
    throw new HttpsError(
      "invalid-argument",
      `${field} foto kelulusan tidak valid.`,
    );
  }
  return normalized;
}

function validateSantriId(value) {
  const santriId = requiredText(value, "ID santri", 128);
  if (santriId.includes("/")) {
    throw new HttpsError("invalid-argument", "ID santri tidak valid.");
  }
  return santriId;
}

function validateOperationId(value) {
  const operationId = requiredText(value, "ID operasi", 80);
  if (!/^[A-Za-z0-9-]+$/.test(operationId)) {
    throw new HttpsError("invalid-argument", "ID operasi tidak valid.");
  }
  return operationId;
}

function validateDateKey(value) {
  const dateKey = requiredText(value, "Tanggal", 10);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateKey)) {
    throw new HttpsError("invalid-argument", "Tanggal foto tidak valid.");
  }
  return dateKey;
}

function validateRevision(value) {
  const revision = requiredText(value, "Versi data", 64);
  if (!/^[a-f0-9]{64}$/.test(revision)) {
    throw new HttpsError(
      "invalid-argument",
      "Versi data foto kelulusan tidak valid.",
    );
  }
  return revision;
}

function recordsFromSnapshot(snapshot) {
  return snapshot.docs.map((document) => ({
    id: document.id,
    data: document.data() || {},
  }));
}

function addCanonicalRecord(records, canonicalSnapshot) {
  if (
    canonicalSnapshot.exists &&
    !records.some((record) => record.id === canonicalSnapshot.id)
  ) {
    records.push({
      id: canonicalSnapshot.id,
      data: canonicalSnapshot.data() || {},
    });
  }
  return records;
}

function sameActiveOperation({
  records,
  santriId,
  dateKey,
  operationId,
  expectedPath,
  bucketName,
}) {
  return matchingKelulusanRecords(records, santriId, dateKey).some(
    (record) => {
      if (
        String(record.data?.operation_id || "") !== operationId
      ) {
        return false;
      }
      if (String(record.data?.storage_path || "") === expectedPath) {
        return true;
      }
      const object = storageObjectFromUrl(record.data?.image_url);
      return (
        object?.bucket === bucketName && object.path === expectedPath
      );
    },
  );
}

function reservationMatches(marker, {
  uploaderUid,
  santriId,
  dateKey,
  operationId,
  expectedRevision,
  replaceExisting,
}) {
  return (
    marker.state === RESERVATION_STATE &&
    marker.uploader_uid === uploaderUid &&
    marker.santri_id === santriId &&
    marker.date_key === dateKey &&
    marker.operation_id === operationId &&
    marker.confirmed_revision === expectedRevision &&
    marker.replace_existing === replaceExisting
  );
}

function reservationMarker({
  path,
  uploaderUid,
  santriId,
  dateKey,
  operationId,
  expectedRevision,
  replaceExisting,
  now,
}) {
  return {
    path,
    state: RESERVATION_STATE,
    uploader_uid: uploaderUid,
    santri_id: santriId,
    date_key: dateKey,
    operation_id: operationId,
    confirmed_revision: expectedRevision,
    replace_existing: replaceExisting,
    updated_at: admin.firestore.Timestamp.fromDate(now),
    not_before: admin.firestore.Timestamp.fromDate(
      new Date(now.getTime() + UPLOAD_RESERVATION_GRACE_MS),
    ),
  };
}

async function validateUploadedImage({
  imageUrl,
  expectedPath,
  expectedUploaderUid,
  bucket,
}) {
  const storageObject = storageObjectFromUrl(imageUrl);
  if (
    !storageObject ||
    storageObject.bucket !== bucket.name ||
    storageObject.path !== expectedPath
  ) {
    throw new HttpsError(
      "failed-precondition",
      "URL upload foto kelulusan tidak valid.",
    );
  }

  let metadata;
  try {
    [metadata] = await bucket.file(expectedPath).getMetadata();
  } catch (error) {
    if (error?.code === 404 || error?.code === "404") {
      throw new HttpsError(
        "failed-precondition",
        "File foto kelulusan tidak ditemukan.",
      );
    }
    logger.error(
      `[kelulusan] gagal verifikasi file ${expectedPath}: ${error.message}`,
    );
    throw new HttpsError(
      "unavailable",
      "File foto belum dapat diverifikasi. Silakan coba lagi.",
    );
  }

  const size = Number(metadata.size || 0);
  const uploaderUid = String(
    metadata.metadata?.uploader_uid || "",
  ).trim();
  if (uploaderUid !== expectedUploaderUid) {
    throw new HttpsError(
      "permission-denied",
      "File foto bukan milik akun yang sedang login.",
    );
  }
  if (
    !String(metadata.contentType || "").startsWith("image/") ||
    !Number.isFinite(size) ||
    size <= 0 ||
    size >= 5 * 1024 * 1024
  ) {
    throw new HttpsError(
      "failed-precondition",
      "File foto kelulusan tidak valid.",
    );
  }
  return storageObject.path;
}

async function assertRequestAccess(request, dependencies, santriId) {
  const assertStaffAccess = dependencies.assertStaff || assertStaff;
  const assertSantriAccess =
    dependencies.assertSantriAccess || assertStaffCanManageSantri;
  const firestore = dependencies.db || db;
  const user = await assertStaffAccess(request.auth.uid);
  await assertSantriAccess({
    uid: request.auth.uid,
    user,
    santriId,
    firestore,
  });
}

async function runCheckKelulusanPhoto(request, dependencies = {}) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Harus login.");
  }
  const firestore = dependencies.db || db;
  const now = dependencies.now ? dependencies.now() : new Date();
  const santriId = validateSantriId(request.data?.santriId);
  await assertRequestAccess(request, dependencies, santriId);

  const dateKey = kelulusanDateKey(now);
  const snapshot = await firestore
    .collection(COLLECTION)
    .where("santri_id", "==", santriId)
    .get();
  const records = recordsFromSnapshot(snapshot);
  const existingCount = matchingKelulusanRecords(
    records,
    santriId,
    dateKey,
  ).length;

  return {
    dateKey,
    existingCount,
    exists: existingCount > 0,
    revision: kelulusanRevision(records, santriId, dateKey),
  };
}

async function runReserveKelulusanPhoto(request, dependencies = {}) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Harus login.");
  }
  const firestore = dependencies.db || db;
  const bucket = dependencies.bucket || admin.storage().bucket();
  const now = dependencies.now ? dependencies.now() : new Date();
  const deleteQueued =
    dependencies.deleteQueuedStoragePaths || deleteQueuedStoragePaths;
  const input = request.data || {};
  const santriId = validateSantriId(input.santriId);
  const dateKey = validateDateKey(input.dateKey);
  const operationId = validateOperationId(input.operationId);
  const expectedRevision = validateRevision(input.expectedRevision);
  const replaceExisting = input.replaceExisting === true;
  await assertRequestAccess(request, dependencies, santriId);

  if (dateKey !== kelulusanDateKey(now)) {
    throw new HttpsError(
      "failed-precondition",
      "Tanggal foto sudah berubah. Silakan generate ulang.",
    );
  }

  const path = kelulusanUploadPath({
    uploaderUid: request.auth.uid,
    santriId,
    dateKey,
    operationId,
  });
  const outcome = await firestore.runTransaction(
    async (transaction) => {
      const collection = firestore.collection(COLLECTION);
      const canonicalReference = collection.doc(
        canonicalKelulusanId(santriId, dateKey),
      );
      const markerReference = cleanupReference(firestore, path);

      const markerSnapshot = await transaction.get(markerReference);
      const canonicalSnapshot = await transaction.get(
        canonicalReference,
      );
      const snapshot = await transaction.get(
        collection.where("santri_id", "==", santriId),
      );
      const records = addCanonicalRecord(
        recordsFromSnapshot(snapshot),
        canonicalSnapshot,
      );
      const matching = matchingKelulusanRecords(
        records,
        santriId,
        dateKey,
      );
      const currentRevision = kelulusanRevision(
        records,
        santriId,
        dateKey,
      );
      const marker = markerSnapshot.exists
        ? markerSnapshot.data() || {}
        : {};
      const alreadyActive = sameActiveOperation({
        records,
        santriId,
        dateKey,
        operationId,
        expectedPath: path,
        bucketName: bucket.name,
      });

      if (alreadyActive) {
        if (marker.state === DELETING_STATE) {
          return {
            conflict: true,
            existingCount: matching.length,
            cleanupPath: null,
          };
        }
        if (markerSnapshot.exists) {
          transaction.delete(markerReference);
        }
        return {
          conflict: false,
          alreadyActive: true,
          existingCount: matching.length,
        };
      }

      if (
        currentRevision !== expectedRevision ||
        (matching.length > 0 && !replaceExisting)
      ) {
        let cleanupPath = null;
        if (
          markerSnapshot.exists &&
          marker.state === RESERVATION_STATE &&
          marker.operation_id === operationId
        ) {
          transaction.set(markerReference, {
            path,
            state: CLEANUP_STATE,
            updated_at: admin.firestore.Timestamp.fromDate(now),
            // putFile yang timeout di client masih dapat berjalan di
            // background. Beri grace agar 404 sementara tidak menghapus
            // tombstone sebelum upload lama benar-benar selesai.
            not_before: admin.firestore.Timestamp.fromDate(
              new Date(now.getTime() + UPLOAD_RESERVATION_GRACE_MS),
            ),
          });
          cleanupPath = path;
        }
        return {
          conflict: true,
          existingCount: matching.length,
          cleanupPath,
        };
      }

      if (
        markerSnapshot.exists &&
        marker.state !== RESERVATION_STATE
      ) {
        return {
          conflict: true,
          existingCount: matching.length,
          cleanupPath: null,
        };
      }
      if (
        markerSnapshot.exists &&
        !reservationMatches(marker, {
          uploaderUid: request.auth.uid,
          santriId,
          dateKey,
          operationId,
          expectedRevision,
          replaceExisting,
        })
      ) {
        return {
          conflict: true,
          existingCount: matching.length,
          cleanupPath: null,
        };
      }

      transaction.set(
        markerReference,
        reservationMarker({
          path,
          uploaderUid: request.auth.uid,
          santriId,
          dateKey,
          operationId,
          expectedRevision,
          replaceExisting,
          now,
        }),
      );
      return {
        conflict: false,
        alreadyActive: false,
        existingCount: matching.length,
      };
    },
  );

  if (outcome.cleanupPath) {
    await deleteQueued([outcome.cleanupPath], {
      bucket,
      firestore,
      now,
    });
  }
  if (outcome.conflict) {
    throw new HttpsError(
      "already-exists",
      "Data foto kelulusan hari ini sudah berubah. Periksa kembali.",
      { existingCount: outcome.existingCount },
    );
  }
  return {
    dateKey,
    alreadyActive: outcome.alreadyActive,
  };
}

async function runSaveKelulusanPhoto(request, dependencies = {}) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Harus login.");
  }
  const firestore = dependencies.db || db;
  const bucket = dependencies.bucket || admin.storage().bucket();
  const now = dependencies.now ? dependencies.now() : new Date();
  const enqueue = dependencies.queueCleanupPaths || queueCleanupPaths;
  const deleteQueued =
    dependencies.deleteQueuedStoragePaths || deleteQueuedStoragePaths;

  const input = request.data || {};
  const santriId = validateSantriId(input.santriId);
  await assertRequestAccess(request, dependencies, santriId);
  const santriName = requiredText(input.santriName, "Nama santri", 160);
  const kelas = requiredText(input.kelas, "Kelas", 100);
  const hafalan = requiredText(input.hafalan, "Hafalan", 300);
  const operationId = validateOperationId(input.operationId);
  const submittedDateKey = validateDateKey(input.dateKey);
  const imageUrl = requiredText(input.imageUrl, "URL foto", 2000);
  const expectedPath = kelulusanUploadPath({
    uploaderUid: request.auth.uid,
    santriId,
    dateKey: submittedDateKey,
    operationId,
  });

  let imagePath;
  try {
    imagePath = await validateUploadedImage({
      imageUrl,
      expectedPath,
      expectedUploaderUid: request.auth.uid,
      bucket,
    });
  } catch (error) {
    const storageObject = storageObjectFromUrl(imageUrl);
    if (
      error instanceof HttpsError &&
      error.code === "failed-precondition" &&
      storageObject?.bucket === bucket.name &&
      storageObject.path === expectedPath
    ) {
      await enqueue([expectedPath], { firestore, now });
      await deleteQueued([expectedPath], {
        bucket,
        firestore,
        now,
      });
    }
    throw error;
  }

  const dateKey = kelulusanDateKey(now);
  if (submittedDateKey !== dateKey) {
    await enqueue([imagePath], { firestore, now });
    await deleteQueued([imagePath], { bucket, firestore, now });
    throw new HttpsError(
      "failed-precondition",
      "Tanggal foto sudah berubah. Silakan generate ulang.",
    );
  }

  const queueInTransaction =
    dependencies.queueCleanupInTransaction || queueCleanupInTransaction;
  const outcome = await firestore.runTransaction(
    async (transaction) => {
      const collection = firestore.collection(COLLECTION);
      const canonicalReference = collection.doc(
        canonicalKelulusanId(santriId, dateKey),
      );
      const markerReference = cleanupReference(firestore, imagePath);

      // Semua read dilakukan sebelum write. Marker dan canonical yang sama
      // juga menjadi lock untuk save, admin delete, serta cleanup worker.
      const markerSnapshot = await transaction.get(markerReference);
      const canonicalSnapshot = await transaction.get(
        canonicalReference,
      );
      const snapshot = await transaction.get(
        collection.where("santri_id", "==", santriId),
      );
      const records = addCanonicalRecord(
        recordsFromSnapshot(snapshot),
        canonicalSnapshot,
      );
      const matching = matchingKelulusanRecords(
        records,
        santriId,
        dateKey,
      );
      const marker = markerSnapshot.exists
        ? markerSnapshot.data() || {}
        : {};
      const alreadyActive = sameActiveOperation({
        records,
        santriId,
        dateKey,
        operationId,
        expectedPath: imagePath,
        bucketName: bucket.name,
      });

      if (
        alreadyActive &&
        marker.state === DELETING_STATE
      ) {
        return {
          conflict: false,
          invalidReservation: true,
          cleanupPaths: [],
          existingCount: matching.length,
        };
      }

      let replaceExisting = input.replaceExisting === true;
      if (!alreadyActive) {
        const validReservation =
          markerSnapshot.exists &&
          reservationMatches(marker, {
            uploaderUid: request.auth.uid,
            santriId,
            dateKey,
            operationId,
            expectedRevision: marker.confirmed_revision,
            replaceExisting,
          }) &&
          !cleanupIsReady(marker.not_before, now);
        if (!validReservation) {
          const shouldCleanupReservation =
            markerSnapshot.exists &&
            marker.state === RESERVATION_STATE &&
            marker.operation_id === operationId;
          if (shouldCleanupReservation) {
            queueInTransaction({
              transaction,
              firestore,
              paths: [imagePath],
              now,
            });
          }
          return {
            conflict:
              matching.length > 0 ||
              marker.state === CLEANUP_STATE ||
              marker.state === DELETING_STATE,
            invalidReservation: true,
            cleanupPaths: shouldCleanupReservation
              ? [imagePath]
              : [],
            existingCount: matching.length,
          };
        }

        const currentRevision = kelulusanRevision(
          records,
          santriId,
          dateKey,
        );
        if (
          currentRevision !== marker.confirmed_revision ||
          (matching.length > 0 && !replaceExisting)
        ) {
          queueInTransaction({
            transaction,
            firestore,
            paths: [imagePath],
            now,
          });
          return {
            conflict: true,
            invalidReservation: false,
            cleanupPaths: [imagePath],
            existingCount: matching.length,
          };
        }
      } else {
        // Retry setelah response sukses hilang tidak memerlukan reservation
        // baru. Jika marker cleanup belum sempat di-claim, batalkan atomik.
        replaceExisting = true;
        if (markerSnapshot.exists) {
          transaction.delete(markerReference);
        }
      }

      const plan = planKelulusanUpsert({
        records,
        santriId,
        dateKey,
        operationId,
        newStoragePath: imagePath,
        storageBucket: bucket.name,
        replaceExisting,
      });
      const cleanupPaths = plan.conflict
        ? [imagePath]
        : plan.oldStoragePaths;
      queueInTransaction({
        transaction,
        firestore,
        paths: cleanupPaths,
        now,
      });

      if (!plan.conflict) {
        if (!alreadyActive) {
          transaction.delete(markerReference);
        }
        const previousData = canonicalSnapshot.exists
          ? canonicalSnapshot.data() || {}
          : {};
        const createdAt =
          plan.idempotent && previousData.created_at
            ? previousData.created_at
            : admin.firestore.Timestamp.fromDate(now);
        transaction.set(canonicalReference, {
          santri_id: santriId,
          santri_name: santriName,
          kelas,
          hafalan,
          image_url: imageUrl,
          storage_path: imagePath,
          day_key: dateKey,
          operation_id: operationId,
          created_by: request.auth.uid,
          created_at: createdAt,
        });
        for (const documentId of plan.documentIdsToDelete) {
          transaction.delete(collection.doc(documentId));
        }
      }
      return {
        ...plan,
        invalidReservation: false,
        cleanupPaths,
      };
    },
  );

  const cleanup = await deleteQueued(outcome.cleanupPaths, {
    bucket,
    firestore,
    now,
  });
  if (outcome.conflict) {
    throw new HttpsError(
      "already-exists",
      "Foto kelulusan santri ini sudah ada untuk hari ini.",
      { existingCount: outcome.existingCount },
    );
  }
  if (outcome.invalidReservation) {
    throw new HttpsError(
      "failed-precondition",
      "Sesi upload foto sudah tidak berlaku. Silakan generate ulang.",
    );
  }

  return {
    dateKey,
    id: outcome.canonicalId,
    idempotent: outcome.idempotent,
    removedDocuments: outcome.documentIdsToDelete.length,
    deletedFiles: cleanup.deleted,
    pendingFileCleanup: cleanup.failedPaths.length,
  };
}

const checkKelulusanPhoto = onCall(OPTIONS, runCheckKelulusanPhoto);
const reserveKelulusanPhoto = onCall(
  OPTIONS,
  runReserveKelulusanPhoto,
);
const saveKelulusanPhoto = onCall(OPTIONS, runSaveKelulusanPhoto);

module.exports = {
  checkKelulusanPhoto,
  reserveKelulusanPhoto,
  saveKelulusanPhoto,
  runCheckKelulusanPhoto,
  runReserveKelulusanPhoto,
  runSaveKelulusanPhoto,
};
