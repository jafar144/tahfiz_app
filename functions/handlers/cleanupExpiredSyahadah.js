const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const { admin, db } = require("../lib/firebase");
const { SCHEDULE_OPTIONS } = require("../lib/config");
const { storagePathFromUrl } = require("../lib/storagePath");

// Foto kelulusan hanya tampil 7 hari; setelah itu dibuang agar hemat storage.
const EXPIRY_DAYS = 7;

async function runCleanup() {
  const cutoff = new Date(Date.now() - EXPIRY_DAYS * 24 * 60 * 60 * 1000);
  const snap = await db
    .collection("kelulusan")
    .where("created_at", "<", admin.firestore.Timestamp.fromDate(cutoff))
    .get();

  if (snap.empty) {
    logger.info("[cleanupSyahadah] tidak ada entri kedaluwarsa.");
    return { deletedDocs: 0, deletedFiles: 0 };
  }

  const bucket = admin.storage().bucket();
  let deletedDocs = 0;
  let deletedFiles = 0;

  for (const doc of snap.docs) {
    const path = storagePathFromUrl(doc.data().image_url);
    if (path) {
      try {
        await bucket.file(path).delete();
        deletedFiles++;
      } catch (e) {
        // File mungkin sudah terhapus; lanjut hapus dokumennya.
        logger.warn(`[cleanupSyahadah] gagal hapus file ${path}: ${e.message}`);
      }
    }
    await doc.ref.delete();
    deletedDocs++;
  }

  logger.info(
    `[cleanupSyahadah] hapus ${deletedDocs} dokumen & ${deletedFiles} file.`
  );
  return { deletedDocs, deletedFiles };
}

// Jalan tiap Senin 03:00 WIB (zona dari SCHEDULE_OPTIONS).
const cleanupExpiredSyahadah = onSchedule(
  { ...SCHEDULE_OPTIONS, schedule: "0 3 * * 1" },
  async () => {
    await runCleanup();
  }
);

module.exports = { cleanupExpiredSyahadah, runCleanup };
