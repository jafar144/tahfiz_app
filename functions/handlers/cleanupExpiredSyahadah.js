const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const { admin, db } = require("../lib/firebase");
const { SCHEDULE_OPTIONS } = require("../lib/config");
const { storageObjectFromUrl } = require("../lib/storagePath");
const {
  queueCleanupInTransaction,
  deleteQueuedStoragePaths,
  drainKelulusanCleanupQueue,
} = require("../lib/kelulusanCleanupQueue");

// Foto kelulusan hanya tampil 7 hari; setelah itu dibuang agar hemat storage.
const EXPIRY_DAYS = 7;

function timestampDate(value) {
  if (value instanceof Date) return value;
  if (value && typeof value.toDate === "function") return value.toDate();
  return null;
}

async function runCleanup(dependencies = {}) {
  const firestore = dependencies.db || db;
  const bucket = dependencies.bucket || admin.storage().bucket();
  const now = dependencies.now ? dependencies.now() : new Date();
  const queueInTransaction =
    dependencies.queueCleanupInTransaction || queueCleanupInTransaction;
  const deleteQueued =
    dependencies.deleteQueuedStoragePaths || deleteQueuedStoragePaths;
  const drainQueue =
    dependencies.drainKelulusanCleanupQueue ||
    drainKelulusanCleanupQueue;

  // Retry dulu file pengganti/duplikat yang gagal dihapus pada request
  // sebelumnya. Dokumen antrean hanya dibuang setelah file hilang.
  const queuedCleanup = await drainQueue({ bucket, firestore, now });
  const cutoff = new Date(
    now.getTime() - EXPIRY_DAYS * 24 * 60 * 60 * 1000,
  );
  const snap = await firestore
    .collection("kelulusan")
    .where("created_at", "<", admin.firestore.Timestamp.fromDate(cutoff))
    .get();

  if (snap.empty) {
    logger.info("[cleanupSyahadah] tidak ada entri kedaluwarsa.");
    return {
      deletedDocs: 0,
      deletedFiles: queuedCleanup.deleted,
      pendingFileCleanup: queuedCleanup.failedPaths.length,
    };
  }

  let deletedDocs = 0;
  let deletedFiles = 0;
  let pendingFileCleanup = queuedCleanup.failedPaths.length;

  for (const doc of snap.docs) {
    const outcome = await firestore.runTransaction(async (transaction) => {
      const freshSnapshot = await transaction.get(doc.ref);
      if (!freshSnapshot.exists) return { deleted: false, paths: [] };

      // Query awal dapat menjadi stale ketika foto diganti bersamaan. Jangan
      // hapus canonical baru yang created_at-nya sudah kembali aktif.
      const freshCreatedAt = timestampDate(
        freshSnapshot.data()?.created_at,
      );
      if (!freshCreatedAt || freshCreatedAt >= cutoff) {
        return { deleted: false, paths: [] };
      }

      const imageUrl = freshSnapshot.data()?.image_url;
      const storageObject = imageUrl
        ? storageObjectFromUrl(imageUrl)
        : null;
      const validStorageObject =
        storageObject?.bucket === bucket.name &&
        storageObject.path.startsWith("syahadah_photos/");
      if (imageUrl && !validStorageObject) {
        logger.warn(
          `[cleanupSyahadah] lewati URL Storage tidak valid pada ${doc.id}`,
        );
      }

      const paths = validStorageObject ? [storageObject.path] : [];
      queueInTransaction({
        transaction,
        firestore,
        paths,
        now,
      });
      transaction.delete(doc.ref);
      return { deleted: true, paths };
    });

    if (!outcome.deleted) continue;
    deletedDocs++;
    const cleanup = await deleteQueued(outcome.paths, {
      bucket,
      firestore,
    });
    deletedFiles += cleanup.deleted;
    pendingFileCleanup += cleanup.failedPaths.length;
  }

  logger.info(
    `[cleanupSyahadah] hapus ${deletedDocs} dokumen & ${deletedFiles} file.`,
  );
  return {
    deletedDocs,
    deletedFiles: deletedFiles + queuedCleanup.deleted,
    pendingFileCleanup,
  };
}

// Jalan tiap Senin 03:00 WIB (zona dari SCHEDULE_OPTIONS).
const cleanupExpiredSyahadah = onSchedule(
  { ...SCHEDULE_OPTIONS, schedule: "0 3 * * 1" },
  async () => {
    await runCleanup();
  }
);

module.exports = { cleanupExpiredSyahadah, runCleanup };
