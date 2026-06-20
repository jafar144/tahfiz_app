const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const { admin, db } = require("../lib/firebase");
const { SCHEDULE_OPTIONS } = require("../lib/config");

// Foto kelulusan hanya tampil 7 hari; setelah itu dibuang agar hemat storage.
const EXPIRY_DAYS = 7;

// Ambil path objek Storage dari Firebase download URL:
// https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<ENCODED_PATH>?alt=media&token=...
function storagePathFromUrl(url) {
  try {
    const m = String(url).match(/\/o\/([^?]+)/);
    return m ? decodeURIComponent(m[1]) : null;
  } catch (_) {
    return null;
  }
}

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
