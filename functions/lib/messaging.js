const { admin, db } = require("./firebase");

const TOKENS_COLLECTION = "device_tokens";

// FCM hanya menerima nilai data berupa string.
function stringifyData(data = {}) {
  const out = {};
  for (const [key, value] of Object.entries(data)) {
    if (value === null || value === undefined) continue;
    out[key] = String(value);
  }
  return out;
}

// Ambil seluruh token milik satu role (mis. semua asatidz).
async function getTokensByRole(role) {
  const snap = await db
    .collection(TOKENS_COLLECTION)
    .where("role", "==", role)
    .get();
  return snap.docs.map((doc) => doc.id);
}

// Ambil seluruh token milik satu user (uid).
async function getTokensByUid(uid) {
  const snap = await db
    .collection(TOKENS_COLLECTION)
    .where("uid", "==", uid)
    .get();
  return snap.docs.map((doc) => doc.id);
}

// Hapus token yang sudah tidak valid agar koleksi tetap bersih.
async function pruneTokens(tokens) {
  if (!tokens.length) return;
  await Promise.all(
    tokens.map((token) =>
      db.collection(TOKENS_COLLECTION).doc(token).delete().catch(() => {})
    )
  );
}

const INVALID_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

// Kirim ke daftar token (otomatis dipecah per 500 & prune token mati).
// Mengembalikan { successCount, failureCount }.
async function sendToTokens(tokens, { title, body, data = {} }) {
  const unique = [...new Set(tokens.filter(Boolean))];
  if (!unique.length) return { successCount: 0, failureCount: 0 };

  const payloadData = stringifyData(data);
  let successCount = 0;
  let failureCount = 0;
  const invalidTokens = [];

  for (let i = 0; i < unique.length; i += 500) {
    const chunk = unique.slice(i, i + 500);
    const res = await admin.messaging().sendEachForMulticast({
      tokens: chunk,
      notification: { title, body },
      data: payloadData,
      android: {
        priority: "high",
        notification: { channelId: "high_importance_channel" },
      },
    });

    successCount += res.successCount;
    failureCount += res.failureCount;

    res.responses.forEach((r, idx) => {
      if (!r.success && r.error && INVALID_TOKEN_CODES.has(r.error.code)) {
        invalidTokens.push(chunk[idx]);
      }
    });
  }

  await pruneTokens(invalidTokens);
  return { successCount, failureCount };
}

// Broadcast ke semua device pada satu role.
async function sendToRole(role, payload) {
  const tokens = await getTokensByRole(role);
  return sendToTokens(tokens, payload);
}

// Kirim ke semua device milik satu user.
async function sendToUid(uid, payload) {
  const tokens = await getTokensByUid(uid);
  return sendToTokens(tokens, payload);
}

module.exports = {
  TOKENS_COLLECTION,
  getTokensByRole,
  getTokensByUid,
  sendToTokens,
  sendToRole,
  sendToUid,
};
