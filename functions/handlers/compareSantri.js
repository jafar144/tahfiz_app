const { onRequest } = require("firebase-functions/v2/https");
const { db } = require("../lib/firebase");
const { FUNCTION_OPTIONS } = require("../lib/config");
const { createConnection } = require("../lib/mysql");
const { normNis, escapeHtml } = require("../lib/utils");

function renderHtml(summary, inWebNotMobile, inMobileNotWeb) {
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

  return `<!doctype html>
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
</body></html>`;
}

exports.compareSantri = onRequest(FUNCTION_OPTIONS, async (req, res) => {
  let connection;
  try {
    connection = await createConnection();
    const [rows] = await connection.execute("SELECT nama, nis FROM santris");

    const snap = await db
      .collection("users")
      .where("role", "==", "santri")
      .select("name", "nis")
      .get();

    const webByNis = new Map();
    const webNoNis = [];
    for (const r of rows) {
      const nis = normNis(r.nis);
      if (!nis) {
        webNoNis.push({ nama: r.nama, nis: r.nis });
        continue;
      }
      if (!webByNis.has(nis)) webByNis.set(nis, { nama: r.nama, nis });
    }

    const mobileByNis = new Map();
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

    res.set("Content-Type", "text/html; charset=utf-8");
    res.send(renderHtml(summary, inWebNotMobile, inMobileNotWeb));
  } catch (err) {
    console.error("compareSantri error:", err);
    res
      .status(500)
      .set("Content-Type", "text/html; charset=utf-8")
      .send(`<h1>Error</h1><pre>${escapeHtml(err.message)}</pre>`);
  } finally {
    if (connection) await connection.end().catch(() => {});
  }
});
