const { createHash, randomUUID } = require("node:crypto");
const { logger } = require("firebase-functions");
const { admin, db } = require("./firebase");
const { storageObjectFromUrl } = require("./storagePath");

const COLLECTION = "kelulusan_storage_cleanup";
const ALLOWED_PREFIX = "syahadah_photos/";
const CLEANUP_STATE = "cleanup";
const RESERVATION_STATE = "reserved";
const DELETING_STATE = "deleting";
const CLAIM_LEASE_MS = 10 * 60 * 1000;
const RETRY_DELAY_MS = 15 * 60 * 1000;

function validCleanupPaths(paths) {
  return [
    ...new Set(
      (paths || []).filter(
        (path) =>
          typeof path === "string" && path.startsWith(ALLOWED_PREFIX),
      ),
    ),
  ];
}

function cleanupDocumentId(path) {
  return createHash("sha256").update(path).digest("hex");
}

function cleanupReference(firestore, path) {
  return firestore.collection(COLLECTION).doc(cleanupDocumentId(path));
}

function timestampDate(value) {
  if (value instanceof Date) return value;
  if (value && typeof value.toDate === "function") return value.toDate();
  return null;
}

function cleanupIsReady(value, now) {
  const date = timestampDate(value);
  return date ? date <= now : true;
}

function cleanupMarker(path, now, notBefore = now) {
  return {
    path,
    state: CLEANUP_STATE,
    updated_at: admin.firestore.Timestamp.fromDate(now),
    not_before: admin.firestore.Timestamp.fromDate(notBefore),
  };
}

function queueCleanupInTransaction({
  transaction,
  firestore,
  paths,
  now,
}) {
  for (const path of validCleanupPaths(paths)) {
    // Overwrite penuh agar reservation lama tidak dapat menghidupkan kembali
    // path yang sudah diputuskan untuk dibuang.
    transaction.set(
      cleanupReference(firestore, path),
      cleanupMarker(path, now),
    );
  }
}

function cancelCleanupInTransaction({
  transaction,
  firestore,
  paths,
}) {
  for (const path of validCleanupPaths(paths)) {
    transaction.delete(cleanupReference(firestore, path));
  }
}

async function queueCleanupPaths(
  paths,
  {
    firestore = db,
    now = new Date(),
    notBefore = now,
  } = {},
) {
  const normalized = validCleanupPaths(paths);
  if (normalized.length === 0) return;

  const batch = firestore.batch();
  for (const path of normalized) {
    batch.set(
      cleanupReference(firestore, path),
      cleanupMarker(path, now, notBefore),
    );
  }
  await batch.commit();
}

async function claimQueuedStoragePath(
  path,
  {
    firestore,
    now,
    claimToken = randomUUID(),
  },
) {
  return firestore.runTransaction(async (transaction) => {
    const reference = cleanupReference(firestore, path);
    const markerSnapshot = await transaction.get(reference);
    if (!markerSnapshot.exists) return null;

    const marker = markerSnapshot.data() || {};
    if (!cleanupIsReady(marker.not_before, now)) return null;
    if (
      marker.state === DELETING_STATE &&
      !cleanupIsReady(marker.claim_until, now)
    ) {
      return null;
    }

    // Record baru menyimpan storage_path. Pemeriksaan ini berada dalam
    // transaksi yang sama dengan claim marker, sehingga save/cancel dan
    // cleanup tidak mungkin sama-sama menang.
    const activeSnapshot = await transaction.get(
      firestore
        .collection("kelulusan")
        .where("storage_path", "==", path)
        .limit(1),
    );
    if (!activeSnapshot.empty) {
      transaction.delete(reference);
      return { active: true };
    }

    transaction.set(reference, {
      ...marker,
      path,
      state: DELETING_STATE,
      claim_token: claimToken,
      claim_until: admin.firestore.Timestamp.fromDate(
        new Date(now.getTime() + CLAIM_LEASE_MS),
      ),
      updated_at: admin.firestore.Timestamp.fromDate(now),
    });
    return { active: false, claimToken };
  });
}

async function finishCleanupClaim({
  firestore,
  path,
  claimToken,
}) {
  await firestore.runTransaction(async (transaction) => {
    const reference = cleanupReference(firestore, path);
    const snapshot = await transaction.get(reference);
    const marker = snapshot.exists ? snapshot.data() || {} : {};
    if (
      snapshot.exists &&
      marker.state === DELETING_STATE &&
      marker.claim_token === claimToken
    ) {
      transaction.delete(reference);
    }
  });
}

async function releaseCleanupClaim({
  firestore,
  path,
  claimToken,
  now,
}) {
  await firestore.runTransaction(async (transaction) => {
    const reference = cleanupReference(firestore, path);
    const snapshot = await transaction.get(reference);
    const marker = snapshot.exists ? snapshot.data() || {} : {};
    if (
      snapshot.exists &&
      marker.state === DELETING_STATE &&
      marker.claim_token === claimToken
    ) {
      transaction.set(
        reference,
        cleanupMarker(
          path,
          now,
          new Date(now.getTime() + RETRY_DELAY_MS),
        ),
      );
    }
  });
}

async function deleteQueuedStoragePaths(
  paths,
  {
    bucket = admin.storage().bucket(),
    firestore = db,
    now = new Date(),
  } = {},
) {
  let deleted = 0;
  const failedPaths = [];

  for (const path of validCleanupPaths(paths)) {
    const claim = await claimQueuedStoragePath(path, {
      firestore,
      now,
    });
    if (!claim || claim.active) continue;

    let fileDeleted = false;
    try {
      await bucket.file(path).delete();
      deleted++;
      fileDeleted = true;
    } catch (error) {
      if (error?.code === 404 || error?.code === "404") {
        fileDeleted = true;
      } else {
        failedPaths.push(path);
        logger.warn(
          `[kelulusanCleanup] gagal hapus ${path}: ${error.message}`,
        );
      }
    }

    try {
      if (fileDeleted) {
        await finishCleanupClaim({
          firestore,
          path,
          claimToken: claim.claimToken,
        });
      } else {
        await releaseCleanupClaim({
          firestore,
          path,
          claimToken: claim.claimToken,
          now,
        });
      }
    } catch (error) {
      // Claim memiliki lease. Jika worker mati di sini, eksekusi berikutnya
      // dapat mengambil alih setelah lease berakhir.
      logger.warn(
        `[kelulusanCleanup] gagal finalisasi antrean ${path}: ${error.message}`,
      );
    }
  }

  return { deleted, failedPaths };
}

async function drainKelulusanCleanupQueue({
  bucket = admin.storage().bucket(),
  firestore = db,
  now = new Date(),
} = {}) {
  const [snapshot, kelulusanSnapshot] = await Promise.all([
    firestore.collection(COLLECTION).get(),
    firestore.collection("kelulusan").get(),
  ]);
  const activePaths = new Set(
    kelulusanSnapshot.docs
      .map((document) =>
        storageObjectFromUrl(document.data()?.image_url),
      )
      .filter(
        (object) =>
          object?.bucket === bucket.name &&
          object.path.startsWith(ALLOWED_PREFIX),
      )
      .map((object) => object.path),
  );
  const paths = [];
  for (const document of snapshot.docs) {
    const data = document.data() || {};
    const path = data.path;
    // Snapshot ini juga melindungi record legacy yang belum memiliki
    // storage_path. Claim transaction melakukan pemeriksaan atomik kedua
    // untuk semua record baru.
    if (
      !activePaths.has(path) &&
      cleanupIsReady(data.not_before, now)
    ) {
      paths.push(path);
    }
  }
  return deleteQueuedStoragePaths(paths, {
    bucket,
    firestore,
    now,
  });
}

module.exports = {
  CLEANUP_STATE,
  RESERVATION_STATE,
  DELETING_STATE,
  cleanupDocumentId,
  cleanupReference,
  cleanupIsReady,
  validCleanupPaths,
  queueCleanupInTransaction,
  cancelCleanupInTransaction,
  queueCleanupPaths,
  claimQueuedStoragePath,
  finishCleanupClaim,
  releaseCleanupClaim,
  deleteQueuedStoragePaths,
  drainKelulusanCleanupQueue,
};
