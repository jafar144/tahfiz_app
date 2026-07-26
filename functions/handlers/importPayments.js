const { onRequest } = require("firebase-functions/v2/https");
const { admin, db } = require("../lib/firebase");
const { FUNCTION_OPTIONS } = require("../lib/legacyConfig");
const { createConnection } = require("../lib/mysql");
const { normNis, plusYearsJakartaTimestamp } = require("../lib/utils");
const { authorizeLegacyAdminHttp } = require("../lib/legacyHttpAuthz");

const TARGET_YEAR = 2026;
const TOTAL = 200000;

exports.importPayments = onRequest(FUNCTION_OPTIONS, async (req, res) => {
  if (!authorizeLegacyAdminHttp(req, res)) return;
  const apply = req.query.apply === "true";
  let connection;
  try {
    connection = await createConnection({ dateStrings: true });

    const [santriRows] = await connection.execute(
      "SELECT id, nis, status_spp, created_at FROM santris"
    );
    const [payRows] = await connection.execute(
      "SELECT santri_id, bulan, tahun FROM payments WHERE status = 1 AND tahun = ?",
      [TARGET_YEAR]
    );

    const mysqlSantri = new Map();
    for (const s of santriRows) mysqlSantri.set(String(s.id), s);

    const usnap = await db
      .collection("users")
      .where("role", "==", "santri")
      .select("nis")
      .get();
    const nisToUid = new Map();
    usnap.forEach((d) => {
      const nis = normNis(d.data().nis);
      if (nis && !nisToUid.has(nis)) nisToUid.set(nis, d.id);
    });

    const existing = new Set();
    const [snapInt, snapStr] = await Promise.all([
      db
        .collection("payments")
        .where("tahun", "==", TARGET_YEAR)
        .select("santri_id", "bulan")
        .get(),
      db
        .collection("payments")
        .where("tahun", "==", String(TARGET_YEAR))
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

    const freeUpdates = [];
    const freeSkipped = [];
    for (const s of santriRows) {
      if (Number(s.status_spp) !== 2) continue;
      const nis = normNis(s.nis);
      const uid = nisToUid.get(nis);
      if (!uid) {
        freeSkipped.push({ nis, alasan: "santri tidak ada di mobile" });
        continue;
      }
      freeUpdates.push({
        uid,
        nis,
        free_until: plusYearsJakartaTimestamp(s.created_at, 10),
      });
    }

    const toInsert = [];
    const paySkipped = [];
    const seen = new Set();
    for (const p of payRows) {
      const s = mysqlSantri.get(String(p.santri_id));
      if (!s) {
        paySkipped.push({
          santri_id: p.santri_id,
          bulan: p.bulan,
          alasan: "santri_id tidak ada di tabel santris",
        });
        continue;
      }
      const nis = normNis(s.nis);
      const uid = nisToUid.get(nis);
      if (!uid) {
        paySkipped.push({ nis, bulan: p.bulan, alasan: "santri tidak ada di mobile" });
        continue;
      }
      const bulan = parseInt(p.bulan, 10);
      if (Number.isNaN(bulan)) {
        paySkipped.push({ nis, bulan: p.bulan, alasan: "bulan tidak valid" });
        continue;
      }
      const key = `${uid}|${bulan}`;
      if (existing.has(key)) {
        paySkipped.push({ nis, bulan, alasan: "sudah ada di Firestore (skip)" });
        continue;
      }
      if (seen.has(key)) continue;
      seen.add(key);
      toInsert.push({ uid, nis, bulan });
    }

    let freeWritten = 0;
    let payWritten = 0;
    if (apply) {
      for (let i = 0; i < freeUpdates.length; i += 400) {
        const batch = db.batch();
        for (const f of freeUpdates.slice(i, i + 400)) {
          batch.set(
            db.collection("santri_profiles").doc(f.uid),
            { free_until: f.free_until },
            { merge: true }
          );
        }
        await batch.commit();
        freeWritten += Math.min(400, freeUpdates.length - i);
      }
      for (let i = 0; i < toInsert.length; i += 400) {
        const batch = db.batch();
        for (const t of toInsert.slice(i, i + 400)) {
          batch.set(db.collection("payments").doc(), {
            santri_id: t.uid,
            bulan: t.bulan,
            tahun: TARGET_YEAR,
            total: TOTAL,
            metode: "migrasi",
            created_by: "SYSTEM_MIGRATION",
            created_at: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
        payWritten += Math.min(400, toInsert.length - i);
      }
    }

    res.json({
      summary: {
        mode: apply ? "APPLY (data ditulis)" : "DRY-RUN (tidak ada perubahan)",
        tahun: TARGET_YEAR,
        totalSantriMysql: santriRows.length,
        totalPaymentStatus1Mysql: payRows.length,
        existingPaymentFirestore2026: existing.size,
        freeUntilAkanDiupdate: freeUpdates.length,
        paymentAkanDibuat: toInsert.length,
        paymentDilewati: paySkipped.length,
        freeUntilDilewati: freeSkipped.length,
        freeUntilDitulis: apply ? freeWritten : null,
        paymentDitulis: apply ? payWritten : null,
      },
      ...(apply
        ? {}
        : {
            previewFreeUntil: freeUpdates.slice(0, 100).map((f) => ({
              nis: f.nis,
              uid: f.uid,
              free_until: f.free_until ? f.free_until.toDate().toISOString() : null,
            })),
            previewPayments: toInsert.slice(0, 200),
          }),
      paymentDilewati: paySkipped.slice(0, 300),
      freeUntilDilewati: freeSkipped.slice(0, 300),
    });
  } catch (err) {
    console.error("importPayments error:", err);
    res.status(500).json({ error: err.message });
  } finally {
    if (connection) await connection.end().catch(() => {});
  }
});
