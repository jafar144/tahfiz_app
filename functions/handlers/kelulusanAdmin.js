const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { admin, db } = require("../lib/firebase");
const { assertAdmin } = require("../lib/authz");
const { CALLABLE_OPTIONS } = require("../lib/config");
const { storagePathFromUrl } = require("../lib/storagePath");

const OPTIONS = CALLABLE_OPTIONS;

const deleteKelulusanPhoto = onCall(OPTIONS, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Harus login.");
  }
  await assertAdmin(request.auth.uid);

  const id = String(request.data?.id || "").trim();
  if (!id || id.length > 200 || id.includes("/")) {
    throw new HttpsError("invalid-argument", "ID foto kelulusan tidak valid.");
  }

  const reference = db.collection("kelulusan").doc(id);
  const snapshot = await reference.get();
  if (!snapshot.exists) return { deleted: false };

  const path = storagePathFromUrl(snapshot.data()?.image_url);
  if (path) {
    if (!path.startsWith("syahadah_photos/")) {
      throw new HttpsError(
        "failed-precondition",
        "Path foto kelulusan tidak valid.",
      );
    }
    try {
      await admin.storage().bucket().file(path).delete();
    } catch (error) {
      if (error?.code !== 404 && error?.code !== "404") {
        throw new HttpsError(
          "internal",
          "Gagal menghapus file foto kelulusan.",
        );
      }
    }
  }

  await reference.delete();
  return { deleted: true };
});

module.exports = { deleteKelulusanPhoto };
