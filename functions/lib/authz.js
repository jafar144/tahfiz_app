const { HttpsError } = require("firebase-functions/v2/https");
const { db } = require("./firebase");

async function getUser(uid) {
  const snapshot = await db.collection("users").doc(uid).get();
  return snapshot.exists ? snapshot.data() || {} : {};
}

async function assertAdmin(uid) {
  const user = await getUser(uid);
  if (user.is_admin !== true && user.role !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Hanya admin yang dapat melakukan tindakan ini.",
    );
  }
  return user;
}

async function assertStaff(uid) {
  const user = await getUser(uid);
  if (
    user.is_admin !== true &&
    user.role !== "admin" &&
    user.role !== "asatidz"
  ) {
    throw new HttpsError(
      "permission-denied",
      "Hanya admin atau asatidz yang dapat melakukan tindakan ini.",
    );
  }
  return user;
}

function isAdminUser(user) {
  return user?.is_admin === true || user?.role === "admin";
}

async function assertStaffCanManageSantri({
  uid,
  user,
  santriId,
  firestore = db,
}) {
  const santriSnapshot = await firestore
    .collection("santri_profiles")
    .doc(santriId)
    .get();
  if (!santriSnapshot.exists) {
    throw new HttpsError("not-found", "Data santri tidak ditemukan.");
  }
  if (isAdminUser(user)) return santriSnapshot.data() || {};

  const halaqahId = String(
    santriSnapshot.data()?.halaqah_id || "",
  ).trim();
  if (!halaqahId) {
    throw new HttpsError(
      "permission-denied",
      "Santri belum terhubung ke halaqah Anda.",
    );
  }

  const halaqahSnapshot = await firestore
    .collection("halaqahs")
    .doc(halaqahId)
    .get();
  const assignedAsatidzId = String(
    halaqahSnapshot.data()?.asatidz?.id || "",
  ).trim();
  if (!halaqahSnapshot.exists || assignedAsatidzId !== uid) {
    throw new HttpsError(
      "permission-denied",
      "Anda hanya dapat mengelola foto santri di halaqah sendiri.",
    );
  }
  return santriSnapshot.data() || {};
}

module.exports = {
  assertAdmin,
  assertStaff,
  assertStaffCanManageSantri,
  isAdminUser,
};
