const { onRequest } = require("firebase-functions/v2/https");
const { admin, db } = require("../lib/firebase");
const {
  FUNCTION_OPTIONS,
  legacyMigrationConfig,
} = require("../lib/legacyConfig");
const { openLegacySource } = require("../lib/legacySource");
const { normNis, dateTimeToJakartaTimestamp } = require("../lib/utils");
const { authorizeLegacyAdminHttp } = require("../lib/legacyHttpAuthz");

exports.importMonthlyReports = onRequest(FUNCTION_OPTIONS, async (req, res) => {
  if (!authorizeLegacyAdminHttp(req, res)) return;
  const apply = req.query.apply === "true";
  const { year: targetYear, startMonth } = legacyMigrationConfig();
  let source;
  try {
    source = await openLegacySource(req);

    const santriRows = await source.santris();
    const { rows: userRows } = await source.users();
    const operatorRows = userRows.map((u) => ({
      id: u.id,
      name: u.name,
      nis: u.username,
    }));
    const nilaiRows = await source.nilais(targetYear, startMonth);

    const mysqlSantri = new Map();
    for (const s of santriRows) mysqlSantri.set(String(s.id), s);
    const mysqlOperator = new Map();
    for (const o of operatorRows) mysqlOperator.set(String(o.id), o);

    const usnap = await db
      .collection("users")
      .where("role", "==", "santri")
      .select("name", "nis")
      .get();
    const nisToSantri = new Map();
    usnap.forEach((d) => {
      const nis = normNis(d.data().nis);
      if (nis && !nisToSantri.has(nis)) {
        nisToSantri.set(nis, { uid: d.id, name: d.data().name });
      }
    });

    const asnap = await db
      .collection("users")
      .where("role", "==", "asatidz")
      .select("name", "nis")
      .get();
    const nisToAsatidz = new Map();
    asnap.forEach((d) => {
      const nis = normNis(d.data().nis);
      if (nis && !nisToAsatidz.has(nis)) {
        nisToAsatidz.set(nis, { uid: d.id, name: d.data().name });
      }
    });

    const existing = new Set();
    const [snapInt, snapStr] = await Promise.all([
      db
        .collection("monthly_reports")
        .where("tahun", "==", targetYear)
        .select("santri_id", "bulan")
        .get(),
      db
        .collection("monthly_reports")
        .where("tahun", "==", String(targetYear))
        .select("santri_id", "bulan")
        .get(),
    ]);
    for (const snap of [snapInt, snapStr]) {
      snap.forEach((d) => {
        const x = d.data();
        const b = parseInt(x.bulan, 10);
        if (x.santri_id && !Number.isNaN(b)) existing.add(`${x.santri_id}|${b}`);
      });
    }

    const toInsert = [];
    const skipped = [];
    const seen = new Set();
    for (const n of nilaiRows) {
      const santri = mysqlSantri.get(String(n.santri_id));
      if (!santri) {
        skipped.push({
          santri_id: n.santri_id,
          bulan: n.bulan,
          alasan: "santri_id tidak ada di tabel santris",
        });
        continue;
      }
      const nis = normNis(santri.nis);
      const santriDoc = nisToSantri.get(nis);
      if (!santriDoc) {
        skipped.push({ nis, bulan: n.bulan, alasan: "santri tidak ada di mobile" });
        continue;
      }
      const bulan = parseInt(n.bulan, 10);
      if (Number.isNaN(bulan)) {
        skipped.push({ nis, bulan: n.bulan, alasan: "bulan tidak valid" });
        continue;
      }
      const key = `${santriDoc.uid}|${bulan}`;
      if (existing.has(key)) {
        skipped.push({ nis, bulan, alasan: "sudah ada di Firestore (skip)" });
        continue;
      }
      if (seen.has(key)) continue;
      seen.add(key);

      const operator = mysqlOperator.get(String(n.operator_id));
      const asatidz = operator ? nisToAsatidz.get(normNis(operator.nis)) : null;

      toInsert.push({
        santri_id: santriDoc.uid,
        santri_name: santriDoc.name || santri.nama || "",
        asatidz_id: asatidz ? asatidz.uid : "",
        asatidz_name: asatidz ? asatidz.name : operator ? operator.name : "",
        bulan,
        tahun: targetYear,
        hafalan_terakhir: n.hafalan == null ? "" : String(n.hafalan),
        nilai_perkembangan: parseInt(n.perkembangan, 10) || 0,
        nilai_akhlaq: parseInt(n.akhlak, 10) || 0,
        notes: "",
        created_at:
          dateTimeToJakartaTimestamp(n.created_at) ||
          admin.firestore.FieldValue.serverTimestamp(),
        updated_at:
          dateTimeToJakartaTimestamp(n.updated_at) ||
          dateTimeToJakartaTimestamp(n.created_at) ||
          admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    let written = 0;
    if (apply) {
      for (let i = 0; i < toInsert.length; i += 400) {
        const batch = db.batch();
        for (const t of toInsert.slice(i, i + 400)) {
          batch.set(db.collection("monthly_reports").doc(), t);
        }
        await batch.commit();
        written += Math.min(400, toInsert.length - i);
      }
    }

    res.json({
      summary: {
        mode: apply ? "APPLY (data ditulis)" : "DRY-RUN (tidak ada perubahan)",
        sumber: source.kind,
        tahun: targetYear,
        bulanMulai: startMonth,
        totalNilaiMysql: nilaiRows.length,
        existingReportFirestore2026: existing.size,
        akanDibuat: toInsert.length,
        dilewati: skipped.length,
        ditulis: apply ? written : null,
      },
      ...(apply ? {} : { previewDibuat: toInsert.slice(0, 200) }),
      dilewati: skipped.slice(0, 300),
    });
  } catch (err) {
    console.error("importMonthlyReports error:", err);
    res.status(err.status || 500).json({ error: err.message });
  } finally {
    if (source) await source.close();
  }
});
