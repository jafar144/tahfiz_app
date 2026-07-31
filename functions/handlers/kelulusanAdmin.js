const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { admin, db } = require("../lib/firebase");
const { assertAdmin } = require("../lib/authz");
const { CALLABLE_OPTIONS } = require("../lib/config");
const { storageObjectFromUrl } = require("../lib/storagePath");
const {
  queueCleanupInTransaction,
  deleteQueuedStoragePaths,
} = require("../lib/kelulusanCleanupQueue");

const OPTIONS = CALLABLE_OPTIONS;

async function runDeleteKelulusanPhoto(request, dependencies = {}) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Harus login.");
  }
  const assertAdminAccess = dependencies.assertAdmin || assertAdmin;
  const firestore = dependencies.db || db;
  const bucket = dependencies.bucket || admin.storage().bucket();
  const queueInTransaction =
    dependencies.queueCleanupInTransaction || queueCleanupInTransaction;
  const deleteQueued =
    dependencies.deleteQueuedStoragePaths || deleteQueuedStoragePaths;
  const now = dependencies.now ? dependencies.now() : new Date();
  await assertAdminAccess(request.auth.uid);

  const id = String(request.data?.id || "").trim();
  if (!id || id.length > 200 || id.includes("/")) {
    throw new HttpsError("invalid-argument", "ID foto kelulusan tidak valid.");
  }
  const expectedImageUrl = String(
    request.data?.expectedImageUrl || "",
  ).trim();
  const expectedOperationId = String(
    request.data?.expectedOperationId || "",
  ).trim();
  if (!expectedImageUrl || expectedImageUrl.length > 2000) {
    throw new HttpsError(
      "invalid-argument",
      "Identitas foto kelulusan tidak valid.",
    );
  }
  if (
    expectedOperationId.length > 80 ||
    expectedOperationId.includes("/")
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Identitas operasi foto kelulusan tidak valid.",
    );
  }

  const outcome = await firestore.runTransaction(async (transaction) => {
    const reference = firestore.collection("kelulusan").doc(id);
    const snapshot = await transaction.get(reference);
    if (!snapshot.exists) return { deleted: false, paths: [] };

    const data = snapshot.data() || {};
    const imageUrl = String(data.image_url || "");
    if (
      imageUrl !== expectedImageUrl ||
      (
        expectedOperationId &&
        String(data.operation_id || "") !== expectedOperationId
      )
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Foto sudah berubah. Muat ulang daftar sebelum menghapus.",
      );
    }
    const storageObject = imageUrl ? storageObjectFromUrl(imageUrl) : null;
    if (
      imageUrl &&
      (
        !storageObject ||
        storageObject.bucket !== bucket.name ||
        !storageObject.path.startsWith("syahadah_photos/")
      )
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Path foto kelulusan tidak valid.",
      );
    }

    const paths = storageObject ? [storageObject.path] : [];
    queueInTransaction({
      transaction,
      firestore,
      paths,
      now,
    });
    transaction.delete(reference);
    return { deleted: true, paths };
  });

  if (!outcome.deleted) return { deleted: false };
  const cleanup = await deleteQueued(outcome.paths, {
    bucket,
    firestore,
  });
  return {
    deleted: true,
    deletedFiles: cleanup.deleted,
    pendingFileCleanup: cleanup.failedPaths.length,
  };
}

const deleteKelulusanPhoto = onCall(OPTIONS, runDeleteKelulusanPhoto);

module.exports = { deleteKelulusanPhoto, runDeleteKelulusanPhoto };
