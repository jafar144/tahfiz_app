const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { admin, db } = require("../lib/firebase");
const { LEASE_MS, lockRef, tsMillis } = require("../lib/quizLock");

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

// Mulai sesi kuis: cek kuota Whisper → ambil lock 1-user → potong 1 energi.
// Semua dalam satu transaksi (dok lock + dok energi) agar konsisten.
exports.startQuizSession = onCall(OPTIONS, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Harus login.");

  const uid = request.auth.uid;
  const token = request.auth.token || {};
  const name = token.name || token.email || "";

  const energyRef = db.collection(COLLECTION).doc(uid);
  const lock = lockRef();

  const outcome = await db.runTransaction(async (tx) => {
    const nowMs = Date.now();
    const lockSnap = await tx.get(lock);
    const energySnap = await tx.get(energyRef);
    const lockData = lockSnap.exists ? lockSnap.data() || {} : {};

    // 1) Kuota Whisper sedang penuh?
    if (tsMillis(lockData.whisper_cooldown_until) > nowMs) {
      return { block: "whisper" };
    }

    // 2) Sedang dipakai user lain (lock masih berlaku)?
    const holder = lockData.holder_uid || null;
    const leaseActive = tsMillis(lockData.lease_expires_at) > nowMs;
    if (holder && holder !== uid && leaseActive) {
      return { block: "busy", holderName: lockData.holder_name || "" };
    }

    // 3) Energi cukup?
    const { stored, updatedAtMs } = readDoc(energySnap, nowMs);
    const { current, anchorMs } = regen(stored, updatedAtMs, nowMs);
    if (current <= 0) {
      return { block: "no_energy" };
    }

    // Ambil lock + potong 1 energi.
    const wasFull = current >= MAX_ENERGY;
    const newCurrent = current - 1;
    const newAnchorMs = wasFull ? nowMs : anchorMs;

    tx.set(
      lock,
      {
        holder_uid: uid,
        holder_name: name,
        session_started_at: admin.firestore.Timestamp.fromMillis(nowMs),
        lease_expires_at: admin.firestore.Timestamp.fromMillis(nowMs + LEASE_MS),
      },
      { merge: true }
    );
    tx.set(
      energyRef,
      {
        energy: newCurrent,
        updated_at: admin.firestore.Timestamp.fromMillis(newAnchorMs),
      },
      { merge: true }
    );
    return { ok: true, energy: toResponse(newCurrent, newAnchorMs, nowMs) };
  });

  if (outcome.block === "whisper") {
    throw new HttpsError(
      "resource-exhausted",
      "Kuis sedang tidak bisa dimainkan (kuota transkripsi penuh). Silakan coba lagi nanti.",
      { reason: "whisper" }
    );
  }
  if (outcome.block === "busy") {
    throw new HttpsError(
      "aborted",
      "Sedang ada yang bermain. Silakan tunggu sebentar lalu coba lagi.",
      { reason: "busy", holderName: outcome.holderName }
    );
  }
  if (outcome.block === "no_energy") {
    throw new HttpsError("failed-precondition", "Energi habis.", {
      reason: "no_energy",
    });
  }
  return outcome.energy;
});

// Perpanjang lock selama masih bermain (dipanggil berkala oleh app).
exports.heartbeatQuizSession = onCall(OPTIONS, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Harus login.");
  const uid = request.auth.uid;
  const lock = lockRef();

  const held = await db.runTransaction(async (tx) => {
    const snap = await tx.get(lock);
    const data = snap.exists ? snap.data() || {} : {};
    if (data.holder_uid !== uid) return false; // lock sudah diambil alih
    tx.set(
      lock,
      {
        lease_expires_at: admin.firestore.Timestamp.fromMillis(
          Date.now() + LEASE_MS
        ),
      },
      { merge: true }
    );
    return true;
  });
  return { held };
});

// Lepas lock (dipanggil saat sesi selesai / user keluar).
exports.endQuizSession = onCall(OPTIONS, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Harus login.");
  const uid = request.auth.uid;
  const lock = lockRef();

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(lock);
    const data = snap.exists ? snap.data() || {} : {};
    if (data.holder_uid !== uid) return; // bukan pemegang → jangan sentuh
    tx.set(
      lock,
      {
        holder_uid: null,
        holder_name: "",
        lease_expires_at: admin.firestore.Timestamp.fromMillis(Date.now()),
      },
      { merge: true }
    );
  });
  return { ok: true };
});
