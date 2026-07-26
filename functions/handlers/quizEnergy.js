const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { admin, db } = require("../lib/firebase");
const { CALLABLE_OPTIONS } = require("../lib/config");
const { LEASE_MS, lockRef, tsMillis } = require("../lib/quizLock");

// Sistem energi & sesi Kuis Hafalan (Tahfiz Arena) — dihitung SISI SERVER
// (waktu server) agar tidak bisa diakali dengan mengubah jam HP.
//
// Model KUOTA MINGGUAN (tanpa cron/scheduler): pemakaian dicatat pada dokumen
// per-minggu `quiz_energy_weeks/{uid}_{tanggalSenin}`. Minggu baru → dokumen
// baru yang belum ada → kuota otomatis penuh kembali. Reset tiap SENIN 00:00 WIB.
//
// Aturan (Lembaga A):
//  • LATIHAN (practice): 15 energi / minggu; 1 sesi = 1 energi (kedua mode).
//  • TANTANGAN (challenge): 2 energi / minggu PER MODE (suara & pilihan).
//  • Admin/asatidz dapat memberi energi TAMBAHAN ke santri (grantQuizEnergy);
//    tambahan berlaku untuk minggu berjalan saja (hangus saat reset).
//  • Lock 1-user & cooldown Whisper hanya berlaku untuk mode SUARA.

const OPTIONS = CALLABLE_OPTIONS;
const COLLECTION = "quiz_energy_weeks";
const WEEKLY_PRACTICE = 15;
const WEEKLY_CHALLENGE_PER_MODE = 2;
// Default pemberian energi tambahan oleh admin/asatidz.
const GRANT_DEFAULT_PRACTICE = 15;
const GRANT_DEFAULT_CHALLENGE = 2;
// Pagar wajar agar salah ketik tak memberi kuota tak terbatas.
const GRANT_MAX_PER_CALL = 100;

const WIB_OFFSET_MS = 7 * 60 * 60 * 1000; // UTC+7
const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Info minggu berjalan menurut WIB (minggu dimulai SENIN 00:00 WIB):
 * `key` = tanggal Senin (yyyy-mm-dd) sebagai kunci dokumen, `resetAtMs` =
 * epoch millis Senin berikutnya (saat kuota kembali penuh).
 */
function weekInfo(nowMs) {
  const epochDays = Math.floor((nowMs + WIB_OFFSET_MS) / DAY_MS);
  // Epoch day 0 = Kamis 1 Jan 1970 → geser agar Senin berindeks 0.
  const mondayIndex = (epochDays + 3) % 7;
  const mondayEpochDay = epochDays - mondayIndex;
  const key = new Date(mondayEpochDay * DAY_MS).toISOString().slice(0, 10);
  const resetAtMs = (mondayEpochDay + 7) * DAY_MS - WIB_OFFSET_MS;
  return { key, resetAtMs };
}

function weekRef(uid, weekKey) {
  return db.collection(COLLECTION).doc(`${uid}_${weekKey}`);
}

const asInt = (v) => (typeof v === "number" && isFinite(v) ? Math.trunc(v) : 0);

/** Baca pemakaian + bonus minggu ini dari snapshot (dokumen boleh belum ada). */
function readWeek(snap) {
  const d = snap.exists ? snap.data() || {} : {};
  return {
    practiceUsed: asInt(d.practice_used),
    voiceUsed: asInt(d.challenge_voice_used),
    choiceUsed: asInt(d.challenge_choice_used),
    bonusPractice: asInt(d.bonus_practice),
    bonusVoice: asInt(d.bonus_challenge_voice),
    bonusChoice: asInt(d.bonus_challenge_choice),
  };
}

/** Bentuk respons energi untuk klien dari data minggu berjalan. */
function toResponse(week, resetAtMs, nowMs) {
  const practiceMax = WEEKLY_PRACTICE + week.bonusPractice;
  const voiceMax = WEEKLY_CHALLENGE_PER_MODE + week.bonusVoice;
  const choiceMax = WEEKLY_CHALLENGE_PER_MODE + week.bonusChoice;
  const left = (max, used) => Math.max(0, max - used);
  return {
    current: left(practiceMax, week.practiceUsed),
    max: practiceMax,
    resetInSeconds: Math.max(0, Math.round((resetAtMs - nowMs) / 1000)),
    challenge: {
      voice: { left: left(voiceMax, week.voiceUsed), max: voiceMax },
      choice: { left: left(choiceMax, week.choiceUsed), max: choiceMax },
    },
  };
}

// Ambil energi minggu berjalan (read-only; dokumen belum ada = kuota penuh).
exports.getQuizEnergy = onCall(OPTIONS, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Harus login.");

  const nowMs = Date.now();
  const { key, resetAtMs } = weekInfo(nowMs);
  const snap = await weekRef(request.auth.uid, key).get();
  return toResponse(readWeek(snap), resetAtMs, nowMs);
});

// Mulai sesi kuis. Aturan menurut parameter dari klien:
//  • kind:  "practice" (default) → potong 1 energi latihan mingguan;
//           "challenge"          → potong 1 kuota Tantangan mingguan mode ybs.
//  • mode:  "voice" (default) → cek cooldown Whisper + ambil lock 1-user;
//           "choice"          → tanpa lock (tak memakai Whisper).
// Semua dalam satu transaksi agar konsisten.
exports.startQuizSession = onCall(OPTIONS, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Harus login.");

  const uid = request.auth.uid;
  const token = request.auth.token || {};
  const name = token.name || token.email || "";

  const data = request.data || {};
  const isChallenge = data.kind === "challenge";
  const mode = data.mode === "choice" ? "choice" : "voice";
  const needsLock = mode === "voice";

  const lock = lockRef();

  const outcome = await db.runTransaction(async (tx) => {
    const nowMs = Date.now();
    const { key, resetAtMs } = weekInfo(nowMs);
    const ref = weekRef(uid, key);

    const lockSnap = await tx.get(lock);
    const weekSnap = await tx.get(ref);
    const lockData = lockSnap.exists ? lockSnap.data() || {} : {};

    if (needsLock) {
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
    }

    const week = readWeek(weekSnap);

    let usedField;
    if (isChallenge) {
      const max =
        WEEKLY_CHALLENGE_PER_MODE +
        (mode === "voice" ? week.bonusVoice : week.bonusChoice);
      const used = mode === "voice" ? week.voiceUsed : week.choiceUsed;
      if (used >= max) return { block: "challenge_limit" };
      usedField = `challenge_${mode}_used`;
      if (mode === "voice") week.voiceUsed += 1;
      else week.choiceUsed += 1;
    } else {
      const max = WEEKLY_PRACTICE + week.bonusPractice;
      if (week.practiceUsed >= max) return { block: "no_energy" };
      usedField = "practice_used";
      week.practiceUsed += 1;
    }

    tx.set(
      ref,
      {
        user_id: uid,
        week_key: key,
        [usedField]: admin.firestore.FieldValue.increment(1),
        updated_at: admin.firestore.Timestamp.fromMillis(nowMs),
      },
      { merge: true }
    );

    if (needsLock) {
      tx.set(
        lock,
        {
          holder_uid: uid,
          holder_name: name,
          session_started_at: admin.firestore.Timestamp.fromMillis(nowMs),
          lease_expires_at: admin.firestore.Timestamp.fromMillis(
            nowMs + LEASE_MS
          ),
        },
        { merge: true }
      );
    }
    return { ok: true, energy: toResponse(week, resetAtMs, nowMs) };
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
    throw new HttpsError("failed-precondition", "Energi minggu ini habis.", {
      reason: "no_energy",
    });
  }
  if (outcome.block === "challenge_limit") {
    throw new HttpsError(
      "failed-precondition",
      "Jatah Tantangan mode ini minggu ini sudah habis. Kembali lagi pekan depan, ya!",
      { reason: "challenge_limit" }
    );
  }
  return outcome.energy;
});

// Beri energi TAMBAHAN untuk minggu berjalan kepada seorang santri (khusus
// admin/asatidz). Tambahan disimpan sebagai bonus_* pada dokumen minggu ini
// sehingga otomatis hangus saat reset Senin berikutnya.
exports.grantQuizEnergy = onCall(OPTIONS, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Harus login.");

  const callerUid = request.auth.uid;
  const callerDoc = await db.collection("users").doc(callerUid).get();
  const callerRole = (callerDoc.data() || {}).role || "";
  if (callerRole !== "admin" && callerRole !== "asatidz") {
    throw new HttpsError(
      "permission-denied",
      "Hanya admin/asatidz yang bisa memberi energi."
    );
  }

  const data = request.data || {};
  const targetUid = typeof data.uid === "string" ? data.uid.trim() : "";
  if (!targetUid) {
    throw new HttpsError("invalid-argument", "Santri belum dipilih.");
  }

  const clampGrant = (v, fallback) => {
    const n = v === undefined || v === null ? fallback : asInt(v);
    if (n < 0 || n > GRANT_MAX_PER_CALL) {
      throw new HttpsError(
        "invalid-argument",
        `Jumlah energi harus 0-${GRANT_MAX_PER_CALL}.`
      );
    }
    return n;
  };
  const practice = clampGrant(data.practice, GRANT_DEFAULT_PRACTICE);
  const challengeVoice = clampGrant(
    data.challengeVoice,
    GRANT_DEFAULT_CHALLENGE
  );
  const challengeChoice = clampGrant(
    data.challengeChoice,
    GRANT_DEFAULT_CHALLENGE
  );
  if (practice + challengeVoice + challengeChoice <= 0) {
    throw new HttpsError("invalid-argument", "Tidak ada energi yang diberikan.");
  }

  const nowMs = Date.now();
  const { key, resetAtMs } = weekInfo(nowMs);
  const ref = weekRef(targetUid, key);

  const week = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const w = readWeek(snap);
    w.bonusPractice += practice;
    w.bonusVoice += challengeVoice;
    w.bonusChoice += challengeChoice;
    tx.set(
      ref,
      {
        user_id: targetUid,
        week_key: key,
        bonus_practice: admin.firestore.FieldValue.increment(practice),
        bonus_challenge_voice:
          admin.firestore.FieldValue.increment(challengeVoice),
        bonus_challenge_choice:
          admin.firestore.FieldValue.increment(challengeChoice),
        last_grant_by: callerUid,
        last_grant_at: admin.firestore.Timestamp.fromMillis(nowMs),
        updated_at: admin.firestore.Timestamp.fromMillis(nowMs),
      },
      { merge: true }
    );
    return w;
  });

  return {
    granted: { practice, challengeVoice, challengeChoice },
    energy: toResponse(week, resetAtMs, nowMs),
  };
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
