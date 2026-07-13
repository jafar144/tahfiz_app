const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { admin, db } = require("../lib/firebase");
const { AUTH_EMAIL_DOMAIN } = require("../lib/config");
const {
  normNis,
  passwordFromBirthDate,
  dateOnlyToJakartaTimestamp,
} = require("../lib/utils");

// Token wajib untuk langkah APPLY (reset password = sensitif). Set sekali:
//   firebase functions:secrets:set RESET_TOKEN
const RESET_TOKEN = defineSecret("RESET_TOKEN");

const OPTIONS = {
  region: "asia-southeast2",
  timeoutSeconds: 540,
  memory: "512MiB",
  secrets: [RESET_TOKEN],
};

const MIN_PASSWORD_LEN = 6;

// Kumpulkan daftar item {nis, tanggal_lahir?, password?} dari body JSON atau query.
function collectItems(req) {
  const body = req.body || {};
  if (Array.isArray(body.items)) return body.items;
  if (Array.isArray(body)) return body;
  // Bentuk tunggal lewat query/body untuk koreksi cepat satu santri.
  const nis = req.query.nis || body.nis;
  if (nis) {
    return [
      {
        nis,
        tanggal_lahir: req.query.tanggal_lahir || body.tanggal_lahir,
        password: req.query.password || body.password,
      },
    ];
  }
  return [];
}

// Tentukan password baru: utamakan `password` eksplisit, lalu turunkan dari
// `tanggal_lahir` (YYYYMMDD). Kembalikan { password } atau { error }.
function resolvePassword(item) {
  if (item.password !== undefined && item.password !== null && item.password !== "") {
    const p = String(item.password).trim();
    if (p.length < MIN_PASSWORD_LEN) {
      return { error: `password < ${MIN_PASSWORD_LEN} karakter` };
    }
    return { password: p, sumber: "password eksplisit" };
  }
  if (item.tanggal_lahir) {
    const p = passwordFromBirthDate(item.tanggal_lahir);
    if (!p) return { error: `tanggal_lahir tidak valid: ${item.tanggal_lahir}` };
    return { password: p, sumber: `tanggal_lahir ${item.tanggal_lahir}` };
  }
  return { error: "tidak ada `password` maupun `tanggal_lahir`" };
}

exports.resetSantriPasswords = onRequest(OPTIONS, async (req, res) => {
  const apply = req.query.apply === "true";
  // Saat APPLY juga selaraskan santri_profiles.tanggal_lahir (default tidak).
  const syncProfile = req.query.syncProfile === "true";

  try {
    if (apply) {
      let expected = "";
      try {
        expected = RESET_TOKEN.value();
      } catch (_) {
        expected = "";
      }
      if (!expected) {
        res.status(500).json({
          error:
            "RESET_TOKEN belum diset. Jalankan: firebase functions:secrets:set RESET_TOKEN",
        });
        return;
      }
      const provided = req.query.token || (req.body && req.body.token) || "";
      if (provided !== expected) {
        res.status(403).json({ error: "token salah / tidak ada (?token=...)" });
        return;
      }
    }

    const items = collectItems(req);
    if (items.length === 0) {
      res.status(400).json({
        error:
          "Tidak ada input. Kirim JSON {items:[{nis, tanggal_lahir|password}]} atau ?nis=...&tanggal_lahir=YYYY-MM-DD",
      });
      return;
    }

    const preview = [];
    const updated = [];
    const skipped = [];

    for (const item of items) {
      const nis = normNis(item.nis);
      if (!nis) {
        skipped.push({ nis: item.nis ?? null, alasan: "NIS kosong" });
        continue;
      }

      const pw = resolvePassword(item);
      if (pw.error) {
        skipped.push({ nis, alasan: pw.error });
        continue;
      }

      const email = `${nis}@${AUTH_EMAIL_DOMAIN.value()}`;
      let userRecord;
      try {
        userRecord = await admin.auth().getUserByEmail(email);
      } catch (e) {
        skipped.push({ nis, email, alasan: `akun tidak ditemukan (${e.code || e.message})` });
        continue;
      }
      const uid = userRecord.uid;

      // Ambil nama dari profil (untuk verifikasi mata di output).
      let nama = userRecord.displayName || null;
      try {
        const snap = await db.collection("santri_profiles").doc(uid).get();
        if (snap.exists) nama = snap.data().name || nama;
      } catch (_) {}

      const row = {
        nis,
        nama,
        email,
        uid,
        passwordBaru: pw.password,
        sumber: pw.sumber,
        ...(syncProfile && item.tanggal_lahir
          ? { syncTanggalLahir: item.tanggal_lahir }
          : {}),
      };

      if (!apply) {
        preview.push(row);
        continue;
      }

      try {
        await admin.auth().updateUser(uid, { password: pw.password });
        if (syncProfile && item.tanggal_lahir) {
          const ts = dateOnlyToJakartaTimestamp(item.tanggal_lahir);
          if (ts) {
            await db
              .collection("santri_profiles")
              .doc(uid)
              .update({ tanggal_lahir: ts });
          }
        }
        updated.push(row);
      } catch (e) {
        skipped.push({ nis, email, uid, alasan: `gagal update: ${e.message}` });
      }
    }

    const summary = {
      mode: apply ? "APPLY (password ditimpa)" : "DRY-RUN (tidak ada perubahan)",
      diminta: items.length,
      akanDiubah: apply ? null : preview.length,
      berhasilDiubah: apply ? updated.length : null,
      dilewati: skipped.length,
      syncProfile,
    };

    res.json({
      summary,
      ...(apply ? { updated } : { preview }),
      skipped,
    });
  } catch (err) {
    console.error("resetSantriPasswords error:", err);
    res.status(500).json({ error: err.message });
  }
});
