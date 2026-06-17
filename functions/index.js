const { onRequest } = require("firebase-functions/v2/https");
const { defineString, defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const mysql = require("mysql2/promise");

admin.initializeApp();
const db = admin.firestore();

// ---- Konfigurasi koneksi MySQL (host publik) ----
// Set lewat: firebase functions:config / .env / secret (lihat README.md)
const DB_HOST = defineString("DB_HOST");
const DB_PORT = defineString("DB_PORT", { default: "3306" });
const DB_USER = defineString("DB_USER");
const DB_NAME = defineString("DB_NAME");
const DB_PASSWORD = defineSecret("DB_PASSWORD");

/**
 * Normalisasi NIS supaya perbandingan web vs mobile adil:
 * - jadikan string, trim spasi
 * - buang ".0" kalau MySQL/Firestore menyimpan sebagai angka
 */
function normNis(value) {
  if (value === null || value === undefined) return "";
  let s = String(value).trim();
  if (s.endsWith(".0")) s = s.slice(0, -2);
  return s;
}

function escapeHtml(s) {
  return String(s ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// "Putra Sore" -> "L", "Putri Malam" -> "P"
function jenisKelaminFromGolongan(golongan) {
  const g = String(golongan ?? "").trim().toLowerCase();
  if (g.startsWith("putri")) return "P";
  if (g.startsWith("putra")) return "L";
  return "";
}

// "Putra Sore" -> "Sore" (kata ke-2)
function tipeKelasFromGolongan(golongan) {
  const parts = String(golongan ?? "").trim().split(/\s+/);
  return parts[1] || "";
}

/**
 * Parse string DATE 'YYYY-MM-DD' (mysql2 dateStrings:true) menjadi Timestamp
 * pada tengah malam waktu Jakarta (UTC+7). null bila tidak valid.
 */
function dateOnlyToJakartaTimestamp(value) {
  const s = String(value ?? "").trim();
  const m = s.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (!m) return null;
  return admin.firestore.Timestamp.fromDate(
    new Date(`${m[1]}-${m[2]}-${m[3]}T00:00:00+07:00`)
  );
}

/**
 * Parse string DATETIME 'YYYY-MM-DD HH:MM:SS' (Jakarta) menjadi Timestamp.
 */
function dateTimeToJakartaTimestamp(value) {
  const s = String(value ?? "").trim();
  const m = s.match(/^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})/);
  if (!m) return null;
  return admin.firestore.Timestamp.fromDate(
    new Date(`${m[1]}-${m[2]}-${m[3]}T${m[4]}:${m[5]}:${m[6]}+07:00`)
  );
}

// Password = tanggal lahir format YYYYMMDD (konvensi mobile app).
function passwordFromBirthDate(value) {
  const s = String(value ?? "").trim();
  const m = s.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (!m) return null;
  return `${m[1]}${m[2]}${m[3]}`;
}

/**
 * Bandingkan data santri:
 *  - Ada di Web (MySQL) tapi TIDAK ada di Mobile (Firestore)
 *  - Ada di Mobile tapi TIDAK ada di Web
 * Key perbandingan: NIS (dinormalisasi).
 */
exports.compareSantri = onRequest(
  {
    region: "asia-southeast2", // Jakarta
    timeoutSeconds: 540, // 9 menit, anti-timeout
    memory: "512MiB",
    secrets: [DB_PASSWORD],
  },
  async (req, res) => {
    let connection;
    try {
      // 1) Ambil semua santri dari MySQL dalam 1 query
      connection = await mysql.createConnection({
        host: DB_HOST.value(),
        port: Number(DB_PORT.value()),
        user: DB_USER.value(),
        password: DB_PASSWORD.value(),
        database: DB_NAME.value(),
        connectTimeout: 30000,
      });
      const [rows] = await connection.execute(
        "SELECT nama, nis FROM santris"
      );

      // 2) Ambil user role "santri" dari Firestore (hanya field yang dibutuhkan)
      const snap = await db
        .collection("users")
        .where("role", "==", "santri")
        .select("name", "nis")
        .get();

      // 3) Susun map ber-key NIS
      const webByNis = new Map(); // nis -> { nama, nis }
      const webNoNis = []; // santri web tanpa nis (tidak bisa dibandingkan)
      for (const r of rows) {
        const nis = normNis(r.nis);
        if (!nis) {
          webNoNis.push({ nama: r.nama, nis: r.nis });
          continue;
        }
        if (!webByNis.has(nis)) webByNis.set(nis, { nama: r.nama, nis });
      }

      const mobileByNis = new Map(); // nis -> { name, nis }
      const mobileNoNis = [];
      snap.forEach((doc) => {
        const d = doc.data();
        const nis = normNis(d.nis);
        if (!nis) {
          mobileNoNis.push({ name: d.name, nis: d.nis, id: doc.id });
          return;
        }
        if (!mobileByNis.has(nis)) mobileByNis.set(nis, { name: d.name, nis });
      });

      // 4) Diff
      const inWebNotMobile = [];
      for (const [nis, v] of webByNis) {
        if (!mobileByNis.has(nis)) inWebNotMobile.push(v);
      }
      const inMobileNotWeb = [];
      for (const [nis, v] of mobileByNis) {
        if (!webByNis.has(nis)) inMobileNotWeb.push(v);
      }

      inWebNotMobile.sort((a, b) => String(a.nama).localeCompare(String(b.nama)));
      inMobileNotWeb.sort((a, b) => String(a.name).localeCompare(String(b.name)));

      const summary = {
        totalWeb: rows.length,
        totalMobile: snap.size,
        webByNis: webByNis.size,
        mobileByNis: mobileByNis.size,
        adaDiWebTidakDiMobile: inWebNotMobile.length,
        adaDiMobileTidakDiWeb: inMobileNotWeb.length,
        webTanpaNis: webNoNis.length,
        mobileTanpaNis: mobileNoNis.length,
      };

      // 5) Output: JSON atau HTML
      if (req.query.format === "json") {
        res.json({
          summary,
          adaDiWebTidakDiMobile: inWebNotMobile,
          adaDiMobileTidakDiWeb: inMobileNotWeb,
          webTanpaNis: webNoNis,
          mobileTanpaNis: mobileNoNis,
        });
        return;
      }

      const tableWeb = inWebNotMobile
        .map(
          (v, i) =>
            `<tr><td>${i + 1}</td><td>${escapeHtml(v.nis)}</td><td>${escapeHtml(
              v.nama
            )}</td></tr>`
        )
        .join("");
      const tableMobile = inMobileNotWeb
        .map(
          (v, i) =>
            `<tr><td>${i + 1}</td><td>${escapeHtml(v.nis)}</td><td>${escapeHtml(
              v.name
            )}</td></tr>`
        )
        .join("");

      res.set("Content-Type", "text/html; charset=utf-8");
      res.send(`<!doctype html>
<html lang="id"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Rekonsiliasi Santri Web vs Mobile</title>
<style>
  body{font-family:system-ui,Arial,sans-serif;margin:24px;color:#1a1a1a}
  h1{font-size:20px} h2{font-size:16px;margin-top:28px}
  .cards{display:flex;gap:12px;flex-wrap:wrap;margin:16px 0}
  .card{border:1px solid #e2e2e2;border-radius:8px;padding:12px 16px;min-width:160px}
  .card b{display:block;font-size:22px}
  table{border-collapse:collapse;width:100%;margin-top:8px}
  th,td{border:1px solid #e2e2e2;padding:6px 10px;text-align:left;font-size:14px}
  th{background:#f5f5f5}
  .muted{color:#777;font-size:13px}
</style></head><body>
<h1>Rekonsiliasi Data Santri — Web (MySQL) vs Mobile (Firestore)</h1>
<p class="muted">Dibandingkan berdasarkan NIS. Tambahkan <code>?format=json</code> untuk output JSON.</p>
<div class="cards">
  <div class="card">Total Web<b>${summary.totalWeb}</b></div>
  <div class="card">Total Mobile<b>${summary.totalMobile}</b></div>
  <div class="card">Web, bukan Mobile<b>${summary.adaDiWebTidakDiMobile}</b></div>
  <div class="card">Mobile, bukan Web<b>${summary.adaDiMobileTidakDiWeb}</b></div>
</div>

<h2>1. Ada di Web, TIDAK ada di Mobile (${inWebNotMobile.length})</h2>
<table><thead><tr><th>#</th><th>NIS</th><th>Nama</th></tr></thead>
<tbody>${tableWeb || '<tr><td colspan="3" class="muted">Tidak ada</td></tr>'}</tbody></table>

<h2>2. Ada di Mobile, TIDAK ada di Web (${inMobileNotWeb.length})</h2>
<table><thead><tr><th>#</th><th>NIS</th><th>Nama</th></tr></thead>
<tbody>${tableMobile || '<tr><td colspan="3" class="muted">Tidak ada</td></tr>'}</tbody></table>

<p class="muted">Catatan: ${summary.webTanpaNis} santri di Web dan ${summary.mobileTanpaNis} user di Mobile tidak punya NIS sehingga tidak ikut dibandingkan (lihat output JSON untuk detail).</p>
</body></html>`);
    } catch (err) {
      console.error("compareSantri error:", err);
      res
        .status(500)
        .set("Content-Type", "text/html; charset=utf-8")
        .send(
          `<h1>Error</h1><pre>${escapeHtml(err.message)}</pre>`
        );
    } finally {
      if (connection) await connection.end().catch(() => {});
    }
  }
);

/**
 * Migrasi santri Web -> Mobile.
 *
 *  - Santri ADA di Web tapi TIDAK di Mobile  -> buat akun Auth + dokumen
 *    users/{uid} & santri_profiles/{uid}.
 *  - Santri ADA di Mobile tapi TIDAK di Web  -> set santri_profiles.is_active = false.
 *
 * SAFETY: default DRY-RUN (tidak menulis apa pun). Untuk benar-benar menulis,
 * panggil dengan ?apply=true.
 */
exports.importSantri = onRequest(
  {
    region: "asia-southeast2",
    timeoutSeconds: 540,
    memory: "512MiB",
    secrets: [DB_PASSWORD],
  },
  async (req, res) => {
    const apply = req.query.apply === "true";
    let connection;
    try {
      // 1) Ambil santri dari MySQL (dateStrings agar tanggal tidak bergeser TZ)
      connection = await mysql.createConnection({
        host: DB_HOST.value(),
        port: Number(DB_PORT.value()),
        user: DB_USER.value(),
        password: DB_PASSWORD.value(),
        database: DB_NAME.value(),
        connectTimeout: 30000,
        dateStrings: true,
      });
      const [rows] = await connection.execute(
        "SELECT nama, nis, tanggal_lahir, kelas, golongan, phone, tempat_lahir, created_at FROM santris"
      );

      // 2) Santri yang sudah ada di Mobile (role santri) -> uid per NIS
      const snap = await db
        .collection("users")
        .where("role", "==", "santri")
        .select("name", "nis")
        .get();
      const mobileByNis = new Map(); // nis -> { uid, name }
      snap.forEach((doc) => {
        const nis = normNis(doc.data().nis);
        if (nis && !mobileByNis.has(nis)) {
          mobileByNis.set(nis, { uid: doc.id, name: doc.data().name });
        }
      });

      // 3) Tentukan yang perlu dibuat & yang perlu dinonaktifkan
      const webNisSet = new Set();
      const toCreate = [];
      const skipped = []; // tidak bisa diproses (mis. NIS kosong)
      for (const r of rows) {
        const nis = normNis(r.nis);
        if (!nis) {
          skipped.push({ nama: r.nama, alasan: "NIS kosong" });
          continue;
        }
        webNisSet.add(nis);
        if (!mobileByNis.has(nis)) toCreate.push({ ...r, _nis: nis });
      }
      const toDeactivate = [];
      for (const [nis, v] of mobileByNis) {
        if (!webNisSet.has(nis)) toDeactivate.push({ nis, ...v });
      }

      const created = [];
      const failed = [];

      if (apply) {
        // 4a) Buat akun + dokumen untuk santri baru
        for (const r of toCreate) {
          const nis = r._nis;
          const email = `${nis}@khoirunnasyien.app`;
          const password =
            passwordFromBirthDate(r.tanggal_lahir) || String(nis);
          try {
            let userRecord;
            try {
              userRecord = await admin.auth().createUser({ email, password });
            } catch (e) {
              if (e.code === "auth/email-already-exists") {
                userRecord = await admin.auth().getUserByEmail(email);
              } else {
                throw e;
              }
            }
            const uid = userRecord.uid;

            await db.collection("users").doc(uid).set({
              name: r.nama,
              email,
              nis,
              phone: "",
              role: "santri",
              uid,
              created_at: admin.firestore.FieldValue.serverTimestamp(),
            });

            await db.collection("santri_profiles").doc(uid).set({
              is_active: true,
              free_until: null,
              halaqah_id: null,
              jenis_kelamin: jenisKelaminFromGolongan(r.golongan),
              kelas: r.kelas ?? "",
              nama_wali: "",
              nomor_wali: r.phone || "",
              name: r.nama,
              nis,
              tanggal_lahir: dateOnlyToJakartaTimestamp(r.tanggal_lahir),
              tanggal_masuk: dateTimeToJakartaTimestamp(r.created_at),
              tempat_lahir: r.tempat_lahir ?? "",
              tipe_kelas: tipeKelasFromGolongan(r.golongan),
              uid,
              created_at: admin.firestore.FieldValue.serverTimestamp(),
            });

            created.push({ nis, nama: r.nama, uid });
          } catch (e) {
            failed.push({ nis, nama: r.nama, error: e.message });
          }
        }

        // 4b) Nonaktifkan santri yang tidak ada di Web (batch)
        for (let i = 0; i < toDeactivate.length; i += 400) {
          const batch = db.batch();
          for (const v of toDeactivate.slice(i, i + 400)) {
            batch.update(db.collection("santri_profiles").doc(v.uid), {
              is_active: false,
            });
          }
          await batch.commit();
        }
      }

      const summary = {
        mode: apply ? "APPLY (data ditulis)" : "DRY-RUN (tidak ada perubahan)",
        totalWeb: rows.length,
        totalMobile: snap.size,
        akanDibuat: toCreate.length,
        akanDinonaktifkan: toDeactivate.length,
        nisKosongDilewati: skipped.length,
        berhasilDibuat: apply ? created.length : null,
        gagal: apply ? failed.length : null,
      };

      res.json({
        summary,
        ...(apply
          ? { created, failed }
          : {
              previewDibuat: toCreate.map((r) => ({
                nis: r._nis,
                nama: r.nama,
                email: `${r._nis}@khoirunnasyien.app`,
                password:
                  passwordFromBirthDate(r.tanggal_lahir) || String(r._nis),
                jenis_kelamin: jenisKelaminFromGolongan(r.golongan),
                tipe_kelas: tipeKelasFromGolongan(r.golongan),
                kelas: r.kelas,
                tempat_lahir: r.tempat_lahir,
                tanggal_lahir: r.tanggal_lahir,
                tanggal_masuk: r.created_at,
                nomor_wali: r.phone || "",
              })),
            }),
        akanDinonaktifkan: toDeactivate,
        nisKosongDilewati: skipped,
      });
    } catch (err) {
      console.error("importSantri error:", err);
      res.status(500).json({ error: err.message });
    } finally {
      if (connection) await connection.end().catch(() => {});
    }
  }
);
