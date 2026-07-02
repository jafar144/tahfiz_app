const { admin, db } = require("./firebase");

// Kunci sesi Kuis Hafalan + status kuota Whisper — dokumen bersama tunggal.
// Dipakai agar kuis hanya bisa dimainkan 1 user pada satu waktu (menjaga batas
// 20 request/menit Groq Whisper), dan agar sesi yang ditinggalkan tidak
// mengunci selamanya (pakai lease + heartbeat).

const LOCK_COLLECTION = "app_locks";
const LOCK_DOC = "quiz";

// Masa berlaku lock sekali heartbeat; diperpanjang berkala saat bermain.
// Kalau app mati/hilang sinyal, lock otomatis bebas setelah lease ini lewat.
const LEASE_MS = 2 * 60 * 1000; // 2 menit

// Jeda setelah Whisper membalas 429 (rate limit ~20 req/menit).
const COOLDOWN_MS = 90 * 1000; // 90 detik

function lockRef() {
  return db.collection(LOCK_COLLECTION).doc(LOCK_DOC);
}

function tsMillis(ts) {
  return ts && typeof ts.toMillis === "function" ? ts.toMillis() : 0;
}

// Tandai kuota Whisper sedang penuh (dipanggil transcribe saat kena 429).
async function markWhisperCooldown() {
  try {
    await lockRef().set(
      {
        whisper_cooldown_until: admin.firestore.Timestamp.fromMillis(
          Date.now() + COOLDOWN_MS
        ),
      },
      { merge: true }
    );
  } catch (e) {
    console.error("markWhisperCooldown error:", e);
  }
}

module.exports = {
  LEASE_MS,
  COOLDOWN_MS,
  lockRef,
  tsMillis,
  markWhisperCooldown,
};
