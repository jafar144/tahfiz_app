const { onRequest } = require("firebase-functions/v2/https");
const { FUNCTION_OPTIONS } = require("../lib/legacyConfig");
const { createConnection } = require("../lib/mysql");
const { escapeHtml } = require("../lib/utils");
const { authorizeLegacyAdminHttp } = require("../lib/legacyHttpAuthz");

// Mengelompokkan santri berdasarkan pembimbing (pengajar) DAN sesi (golongan),
// langsung dari data website (MySQL). Satu pengajar yang mengajar di beberapa
// sesi (mis. "Putra Sore" dan "Putra Malam") akan tampil sebagai grup terpisah.
function buildGroups(rows) {
  const groups = new Map();
  for (const r of rows) {
    const sesi = (r.golongan ?? "").trim() || "(tanpa sesi)";
    const pembimbingNama = (r.pembimbing_nama ?? "").trim() || "(tanpa pembimbing)";
    const pembimbingId = r.pembimbing_id == null ? "" : String(r.pembimbing_id);
    const key = `${pembimbingId}|${sesi}`;

    let g = groups.get(key);
    if (!g) {
      g = {
        pembimbing_id: pembimbingId,
        pembimbing_nama: pembimbingNama,
        sesi,
        santri: [],
      };
      groups.set(key, g);
    }
    g.santri.push({ nis: r.nis == null ? "" : String(r.nis), nama: r.nama ?? "" });
  }

  const list = Array.from(groups.values());
  for (const g of list) {
    g.jumlah_santri = g.santri.length;
    g.santri.sort((a, b) => String(a.nama).localeCompare(String(b.nama)));
  }
  list.sort(
    (a, b) =>
      String(a.pembimbing_nama).localeCompare(String(b.pembimbing_nama)) ||
      String(a.sesi).localeCompare(String(b.sesi))
  );
  return list;
}

function renderHtml(summary, groups) {
  const cards = groups
    .map((g) => {
      const rows = g.santri
        .map(
          (s, i) =>
            `<tr><td>${i + 1}</td><td>${escapeHtml(s.nis)}</td><td>${escapeHtml(
              s.nama
            )}</td></tr>`
        )
        .join("");
      return `<section class="group">
  <h2>${escapeHtml(g.pembimbing_nama)} <span class="badge">${escapeHtml(
        g.sesi
      )}</span> <span class="count">${g.jumlah_santri} santri</span></h2>
  <table><thead><tr><th>#</th><th>NIS</th><th>Nama Santri</th></tr></thead>
  <tbody>${rows || '<tr><td colspan="3" class="muted">Tidak ada santri</td></tr>'}</tbody></table>
</section>`;
    })
    .join("");

  return `<!doctype html>
<html lang="id"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Grouping Pengajar & Santri per Sesi</title>
<style>
  body{font-family:system-ui,Arial,sans-serif;margin:24px;color:#1a1a1a}
  h1{font-size:20px}
  .group{margin-top:28px}
  h2{font-size:16px;margin-bottom:8px}
  .badge{display:inline-block;background:#eef2ff;color:#3730a3;border-radius:999px;padding:2px 10px;font-size:12px;vertical-align:middle}
  .count{color:#777;font-size:13px;font-weight:normal}
  .cards{display:flex;gap:12px;flex-wrap:wrap;margin:16px 0}
  .card{border:1px solid #e2e2e2;border-radius:8px;padding:12px 16px;min-width:160px}
  .card b{display:block;font-size:22px}
  table{border-collapse:collapse;width:100%;margin-top:4px}
  th,td{border:1px solid #e2e2e2;padding:6px 10px;text-align:left;font-size:14px}
  th{background:#f5f5f5}
  .muted{color:#777;font-size:13px}
</style></head><body>
<h1>Grouping Pengajar & Santri per Sesi — Data Website (MySQL)</h1>
<p class="muted">Dikelompokkan per pembimbing (<code>santris.pembimbing_id</code>) dan sesi (<code>santris.golongan</code>). Tambahkan <code>?format=json</code> untuk output JSON.</p>
<div class="cards">
  <div class="card">Total Santri<b>${summary.totalSantri}</b></div>
  <div class="card">Total Grup<b>${summary.totalGrup}</b></div>
  <div class="card">Total Pengajar<b>${summary.totalPengajar}</b></div>
  <div class="card">Tanpa Pembimbing<b>${summary.santriTanpaPembimbing}</b></div>
</div>
${cards || '<p class="muted">Tidak ada data.</p>'}
</body></html>`;
}

exports.groupPengajarSantri = onRequest(FUNCTION_OPTIONS, async (req, res) => {
  if (!authorizeLegacyAdminHttp(req, res)) return;
  let connection;
  try {
    connection = await createConnection();
    const [rows] = await connection.execute(
      `SELECT s.nama, s.nis, s.golongan, s.pembimbing_id, u.name AS pembimbing_nama
       FROM santris s
       LEFT JOIN users u ON u.id = s.pembimbing_id`
    );

    const groups = buildGroups(rows);

    const pengajarSet = new Set();
    let santriTanpaPembimbing = 0;
    for (const g of groups) {
      if (g.pembimbing_id) pengajarSet.add(g.pembimbing_id);
      else santriTanpaPembimbing += g.jumlah_santri;
    }

    const summary = {
      totalSantri: rows.length,
      totalGrup: groups.length,
      totalPengajar: pengajarSet.size,
      santriTanpaPembimbing,
    };

    if (req.query.format === "json") {
      res.json({ summary, groups });
      return;
    }

    res.set("Content-Type", "text/html; charset=utf-8");
    res.send(renderHtml(summary, groups));
  } catch (err) {
    console.error("groupPengajarSantri error:", err);
    res
      .status(500)
      .set("Content-Type", "text/html; charset=utf-8")
      .send(`<h1>Error</h1><pre>${escapeHtml(err.message)}</pre>`);
  } finally {
    if (connection) await connection.end().catch(() => {});
  }
});
