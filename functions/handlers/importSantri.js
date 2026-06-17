const { onRequest } = require("firebase-functions/v2/https");
const { admin, db } = require("../lib/firebase");
const { FUNCTION_OPTIONS } = require("../lib/config");
const { createConnection } = require("../lib/mysql");
const {
  normNis,
  jenisKelaminFromGolongan,
  tipeKelasFromGolongan,
  dateOnlyToJakartaTimestamp,
  dateTimeToJakartaTimestamp,
  passwordFromBirthDate,
} = require("../lib/utils");

exports.importSantri = onRequest(FUNCTION_OPTIONS, async (req, res) => {
  const apply = req.query.apply === "true";
  let connection;
  try {
    connection = await createConnection({ dateStrings: true });
    const [rows] = await connection.execute(
      "SELECT nama, nis, tanggal_lahir, kelas, golongan, phone, tempat_lahir, created_at FROM santris"
    );

    const snap = await db
      .collection("users")
      .where("role", "==", "santri")
      .select("name", "nis")
      .get();
    const mobileByNis = new Map();
    snap.forEach((doc) => {
      const nis = normNis(doc.data().nis);
      if (nis && !mobileByNis.has(nis)) {
        mobileByNis.set(nis, { uid: doc.id, name: doc.data().name });
      }
    });

    const webNisSet = new Set();
    const toCreate = [];
    const skipped = [];
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
      for (const r of toCreate) {
        const nis = r._nis;
        const email = `${nis}@khoirunnasyien.app`;
        const password = passwordFromBirthDate(r.tanggal_lahir) || String(nis);
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
              password: passwordFromBirthDate(r.tanggal_lahir) || String(r._nis),
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
});
