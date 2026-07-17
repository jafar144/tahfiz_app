const { HttpsError } = require("firebase-functions/v2/https");
const { db } = require("./firebase");

async function assertAdmin(uid) {
  const snapshot = await db.collection("users").doc(uid).get();
  const user = snapshot.exists ? snapshot.data() || {} : {};
  if (user.is_admin !== true && user.role !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Hanya admin yang dapat melakukan tindakan ini.",
    );
  }
}

module.exports = { assertAdmin };
