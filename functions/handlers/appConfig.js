const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { admin, db } = require("../lib/firebase");
const { isSupportedAppFeature } = require("../lib/appFeatureConfig");

const OPTIONS = { region: "asia-southeast2" };
const CONFIG_DOCUMENT = db.collection("app_config").doc("runtime");

async function assertAdmin(uid) {
  const snapshot = await db.collection("users").doc(uid).get();
  const user = snapshot.exists ? snapshot.data() || {} : {};
  if (user.is_admin !== true && user.role !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Hanya admin yang dapat mengubah App Config.",
    );
  }
}

const setAppFeatureConfig = onCall(OPTIONS, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Harus login.");
  }

  await assertAdmin(request.auth.uid);

  const data = request.data || {};
  const feature = data.feature;
  const enabled = data.enabled;

  if (!isSupportedAppFeature(feature)) {
    throw new HttpsError("invalid-argument", "App Config tidak dikenal.");
  }
  if (typeof enabled !== "boolean") {
    throw new HttpsError(
      "invalid-argument",
      "Nilai App Config harus berupa boolean.",
    );
  }

  await CONFIG_DOCUMENT.set(
    {
      features: { [feature]: enabled },
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_by: request.auth.uid,
    },
    {
      mergeFields: [`features.${feature}`, "updated_at", "updated_by"],
    },
  );

  return { feature, enabled };
});

module.exports = { setAppFeatureConfig };
