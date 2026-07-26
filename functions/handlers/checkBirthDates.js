const { onRequest } = require("firebase-functions/v2/https");
const { db } = require("../lib/firebase");
const { FUNCTION_OPTIONS } = require("../lib/legacyConfig");
const { createConnection } = require("../lib/mysql");
const { normNis, toJakartaDateString, escapeHtml } = require("../lib/utils");
const { authorizeLegacyAdminHttp } = require("../lib/legacyHttpAuthz");

// Tahun lahir >= ambang ini dianggap anomali (mis. 2024 ke atas: tidak mungkin
// ada santri baru berumur 2-3 tahun). Bisa di-override lewat ?minYear=2023.
const DEFAULT_MIN_ANOMALY_YEAR = 2024;

function yearOf(dateStr) {
  if (!dateStr) return null;
  const y = Number(dateStr.slice(0, 4));
  return Number.isFinite(y) ? y : null;
}

function renderHtml(summary, beda, anomali, minYear) {
  const rowsBeda = beda
    .map(
      (v, i) =>
        `<tr><td>${i + 1}</td><td>${escapeHtml(v.nis)}</td><td>${escapeHtml(
          v.nama
        )}</td><td>${escapeHtml(v.web ?? "—")}</td><td>${escapeHtml(
          v.mobile ?? "—"
        )}</td></tr>`
    )
    .join("");
  const rowsAnomali = anomali
    .map(
      (v, i) =>
        `<tr><td>${i + 1}</td><td>${escapeHtml(v.nis)}</td><td>${escapeHtml(
          v.nama
        )}</td><td>${escapeHtml(v.sumber)}</td><td>${escapeHtml(
          v.tanggal ?? "—"
        )}</td></tr>`
    )
    .join("");

  return `<!doctype html>
<html lang="id"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cek Tanggal Lahir Santri</title>
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
<h1>Cek Tanggal Lahir Santri — Web (MySQL) vs Mobile (Firestore)</h1>
<p class="muted">Dicocokkan berdasarkan NIS. Tanggal dinormalisasi ke zona WIB (YYYY-MM-DD).
Ambang anomali tahun &ge; <b>${minYear}</b> (ubah dengan <code>?minYear=2023</code>).
Tambahkan <code>?format=json</code> untuk output JSON.</p>
<div class="cards">
  <div class="card">Dibandingkan (NIS cocok)<b>${summary.dibandingkan}</b></div>
  <div class="card">Tanggal Lahir Beda<b>${summary.beda}</b></div>
  <div class="card">Anomali (tahun &ge; ${minYear})<b>${summary.anomali}</b></div>
</div>

<h2>1. Tanggal Lahir BEDA antara Web & Mobile (${beda.length})</h2>
<table><thead><tr><th>#</th><th>NIS</th><th>Nama</th><th>Web (MySQL)</th><th>Mobile (Firestore)</th></tr></thead>
<tbody>${rowsBeda || '<tr><td colspan="5" class="muted">Tidak ada</td></tr>'}</tbody></table>

<h2>2. Tanggal Lahir ANOMALI — tahun &ge; ${minYear} (${anomali.length})</h2>
<table><thead><tr><th>#</th><th>NIS</th><th>Nama</th><th>Sumber</th><th>Tanggal Lahir</th></tr></thead>
<tbody>${rowsAnomali || '<tr><td colspan="5" class="muted">Tidak ada</td></tr>'}</tbody></table>
</body></html>`;
}

exports.checkBirthDates = onRequest(FUNCTION_OPTIONS, async (req, res) => {
  if (!authorizeLegacyAdminHttp(req, res)) return;
  const minYear = Number(req.query.minYear) || DEFAULT_MIN_ANOMALY_YEAR;
  let connection;
  try {
    // dateStrings: true agar DATE tidak dikonversi ke Date objek server (zona berbeda).
    connection = await createConnection({ dateStrings: true });
    const [rows] = await connection.execute(
      "SELECT nama, nis, tanggal_lahir FROM santris"
    );

    // Tanggal lahir mobile ada di santri_profiles (bukan di users).
    const snap = await db
      .collection("santri_profiles")
      .select("name", "nis", "tanggal_lahir")
      .get();

    const webByNis = new Map();
    for (const r of rows) {
      const nis = normNis(r.nis);
      if (!nis) continue;
      if (!webByNis.has(nis)) {
        webByNis.set(nis, {
          nis,
          nama: r.nama,
          tgl: toJakartaDateString(r.tanggal_lahir),
        });
      }
    }

    const mobileByNis = new Map();
    snap.forEach((doc) => {
      const d = doc.data();
      const nis = normNis(d.nis);
      if (!nis) return;
      if (!mobileByNis.has(nis)) {
        mobileByNis.set(nis, {
          nis,
          nama: d.name,
          tgl: toJakartaDateString(d.tanggal_lahir),
        });
      }
    });

    // 1. Beda tanggal lahir (hanya yang NIS-nya cocok di kedua sumber).
    const beda = [];
    let dibandingkan = 0;
    for (const [nis, w] of webByNis) {
      const m = mobileByNis.get(nis);
      if (!m) continue;
      dibandingkan++;
      if (w.tgl !== m.tgl) {
        beda.push({ nis, nama: w.nama || m.nama, web: w.tgl, mobile: m.tgl });
      }
    }

    // 2. Anomali tahun lahir (cek di kedua sumber, satu baris per sumber).
    const anomali = [];
    for (const [, w] of webByNis) {
      const y = yearOf(w.tgl);
      if (y !== null && y >= minYear) {
        anomali.push({ nis: w.nis, nama: w.nama, sumber: "Web", tanggal: w.tgl });
      }
    }
    for (const [, m] of mobileByNis) {
      const y = yearOf(m.tgl);
      if (y !== null && y >= minYear) {
        anomali.push({ nis: m.nis, nama: m.nama, sumber: "Mobile", tanggal: m.tgl });
      }
    }

    beda.sort((a, b) => String(a.nama).localeCompare(String(b.nama)));
    anomali.sort((a, b) => String(a.tanggal).localeCompare(String(b.tanggal)));

    const summary = {
      minYear,
      totalWeb: webByNis.size,
      totalMobile: mobileByNis.size,
      dibandingkan,
      beda: beda.length,
      anomali: anomali.length,
    };

    if (req.query.format === "json") {
      res.json({ summary, beda, anomali });
      return;
    }

    res.set("Content-Type", "text/html; charset=utf-8");
    res.send(renderHtml(summary, beda, anomali, minYear));
  } catch (err) {
    console.error("checkBirthDates error:", err);
    res
      .status(500)
      .set("Content-Type", "text/html; charset=utf-8")
      .send(`<h1>Error</h1><pre>${escapeHtml(err.message)}</pre>`);
  } finally {
    if (connection) await connection.end().catch(() => {});
  }
});
