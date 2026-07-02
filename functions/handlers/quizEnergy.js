const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { admin, db } = require("../lib/firebase");

// Sistem energi Kuis Hafalan — dihitung SISI SERVER (waktu server) agar tidak
// bisa diakali dengan mengubah jam HP. Tiap pengguna (admin/asatidz/santri)
// punya energi sendiri: dokumen quiz_energy/{uid}.
//
// Aturan: maksimum 6 energi, terisi +1 tiap 4 jam, 1 sesi kuis = 1 energi.

const OPTIONS = { region: "asia-southeast2" };
const COLLECTION = "quiz_energy";
const MAX_ENERGY = 6;
const REFILL_MS = 4 * 60 * 60 * 1000; // 4 jam

/**
 * Hitung energi terkini dari nilai tersimpan pada [updatedAtMs].
 * Mengembalikan energi baru + jangkar waktu (anchor) untuk timer berikutnya.
 */
function regen(stored, updatedAtMs, nowMs) {
  if (stored >= MAX_ENERGY) return { current: MAX_ENERGY, anchorMs: nowMs };
  const clamped = stored < 0 ? 0 : stored;
  const elapsed = nowMs - updatedAtMs;
  if (elapsed < REFILL_MS) return { current: clamped, anchorMs: updatedAtMs };

  const gained = Math.floor(elapsed / REFILL_MS);
  const next = clamped + gained;
  if (next >= MAX_ENERGY) return { current: MAX_ENERGY, anchorMs: nowMs };
  return { current: next, anchorMs: updatedAtMs + gained * REFILL_MS };
}

/** Bentuk respons untuk klien; sisa pengisian dihitung relatif waktu server. */
function toResponse(current, anchorMs, nowMs) {
  const full = current >= MAX_ENERGY;
  const nextRefillInSeconds = full
    ? null
    : Math.max(0, Math.round((anchorMs + REFILL_MS - nowMs) / 1000));
  return { current, max: MAX_ENERGY, nextRefillInSeconds };
}

/** Baca dokumen energi; dokumen belum ada → pengguna baru (energi penuh). */
function readDoc(snap, nowMs) {
  if (!snap.exists) {
    return { stored: MAX_ENERGY, updatedAtMs: nowMs, isNew: true };
  }
  const data = snap.data() || {};
  const stored = typeof data.energy === "number" ? data.energy : MAX_ENERGY;
  const ts = data.updated_at;
  const updatedAtMs =
    ts && typeof ts.toMillis === "function" ? ts.toMillis() : nowMs;
  return { stored, updatedAtMs, isNew: false };
}

// Ambil energi terkini (sekaligus persist hasil regen bila bertambah).
exports.getQuizEnergy = onCall(OPTIONS, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Harus login.");

  const ref = db.collection(COLLECTION).doc(request.auth.uid);
  const nowMs = Date.now();
  const snap = await ref.get();
  const { stored, updatedAtMs, isNew } = readDoc(snap, nowMs);

  if (isNew) {
    await ref.set({
      energy: MAX_ENERGY,
      updated_at: admin.firestore.Timestamp.fromMillis(nowMs),
    });
    return toResponse(MAX_ENERGY, nowMs, nowMs);
  }

  const { current, anchorMs } = regen(stored, updatedAtMs, nowMs);
  if (current !== stored) {
    await ref.set(
      {
        energy: current,
        updated_at: admin.firestore.Timestamp.fromMillis(anchorMs),
      },
      { merge: true }
    );
  }
  return toResponse(current, anchorMs, nowMs);
});

// Pakai 1 energi untuk memulai sesi (transaksi). Gagal bila energi habis.
exports.consumeQuizEnergy = onCall(OPTIONS, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Harus login.");

  const ref = db.collection(COLLECTION).doc(request.auth.uid);

  const result = await db.runTransaction(async (tx) => {
    const nowMs = Date.now();
    const snap = await tx.get(ref);
    const { stored, updatedAtMs } = readDoc(snap, nowMs);
    const { current, anchorMs } = regen(stored, updatedAtMs, nowMs);

    if (current <= 0) return { empty: true };

    // Jika sebelumnya penuh, timer pengisian mulai dihitung dari sekarang.
    const wasFull = current >= MAX_ENERGY;
    const newCurrent = current - 1;
    const newAnchorMs = wasFull ? nowMs : anchorMs;

    tx.set(
      ref,
      {
        energy: newCurrent,
        updated_at: admin.firestore.Timestamp.fromMillis(newAnchorMs),
      },
      { merge: true }
    );
    return { empty: false, current: newCurrent, anchorMs: newAnchorMs, nowMs };
  });

  if (result.empty) {
    throw new HttpsError("failed-precondition", "Energi habis.");
  }
  return toResponse(result.current, result.anchorMs, result.nowMs);
});
