const { onRequest } = require("firebase-functions/v2/https");
const { admin, db } = require("../lib/firebase");
const {
  AUTH_EMAIL_DOMAIN,
  asatidzInitialPassword,
} = require("../lib/config");
const {
  FUNCTION_OPTIONS,
  legacyMigrationConfig,
} = require("../lib/legacyConfig");
const { openLegacySource } = require("../lib/legacySource");
const {
  normNis,
  jenisKelaminFromGolongan,
  dateTimeToJakartaTimestamp,
} = require("../lib/utils");
const { authorizeLegacyAdminHttp } = require("../lib/legacyHttpAuthz");

// Nilai kolom role web lama untuk pengajar (0 = admin web, 1 = pengajar).
const ASATIDZ_WEB_ROLES = new Set(["1"]);

// Sama dengan validasi provisionInstitutionUser agar akun hasil migrasi
// tetap dapat diedit dari aplikasi.
const NIS_PATTERN = /^[A-Za-z0-9._-]+$/;

function normalizeGender(value) {
  const g = String(value ?? "").trim().toLowerCase();
  if (!g) return "";
  if (["l", "lk", "laki-laki", "laki laki", "pria", "male", "ikhwan", "putra"].includes(g)) {
    return "L";
  }
  if (["p", "pr", "perempuan", "wanita", "female", "akhwat", "putri"].includes(g)) {
    return "P";
  }
  return "";
}

// Gelar di depan nama: "Ustadzah ..." -> P, "Ust ..."/"Ustadz ..." -> L.
function genderFromTitle(name) {
  const n = String(name ?? "").trim().toLowerCase();
  if (/^(ustadzah|ustazah|ustdzh|ustadzat)\b/.test(n)) return "P";
  if (/^(ustadz|ustaz|ust)\b\.?/.test(n)) return "L";
  return "";
}

// Fallback terakhir: golongan santri bimbingan. Pembimbing yang memegang
// santri putra dan putri dibiarkan kosong agar admin memilih manual.
function genderFromGolongan(golonganList) {
  const set = new Set(
    (golonganList || []).map(jenisKelaminFromGolongan).filter(Boolean),
  );
  return set.size === 1 ? [...set][0] : "";
}

/**
 * Menentukan akun asatidz yang dibuat, tanpa I/O.
 *
 * Bila tabel `users` mempunyai kolom role, asatidz = role pengajar (1).
 * Tanpa kolom role, asatidz = user yang dirujuk sebagai pembimbing santri
 * atau operator penilaian pada periode migrasi. Selain itu (admin web, akun
 * uji) hanya ditampilkan di `bukanAsatidz`.
 */
function planAsatidzImport({
  users,
  pembimbingRows,
  operatorIds,
  existingByNis,
  emailDomain,
}) {
  const golonganByUser = new Map();
  for (const r of pembimbingRows) {
    if (r.pembimbing_id == null || r.pembimbing_id === "") continue;
    const id = String(r.pembimbing_id);
    if (!golonganByUser.has(id)) golonganByUser.set(id, []);
    golonganByUser.get(id).push(r.golongan);
  }
  const operatorSet = new Set(
    operatorIds.filter((v) => v != null).map((v) => String(v)),
  );
  const hasRoleColumn = users.some(
    (u) => u.peran_web !== null && u.peran_web !== undefined,
  );

  const toCreate = [];
  const skipped = [];
  const notAsatidz = [];
  const seenNis = new Map();

  for (const u of users) {
    const id = String(u.id);
    const isPembimbing = golonganByUser.has(id);
    const isOperator = operatorSet.has(id);
    const name = String(u.name ?? "").trim();
    const nis = normNis(u.username);
    const peranWeb =
      u.peran_web === null || u.peran_web === undefined
        ? null
        : String(u.peran_web).trim();

    const isAsatidz = hasRoleColumn
      ? ASATIDZ_WEB_ROLES.has(peranWeb)
      : isPembimbing || isOperator;
    if (!isAsatidz) {
      notAsatidz.push({
        id,
        nama: name,
        username: nis,
        peran_web: peranWeb,
        alasan: hasRoleColumn
          ? `role web ${peranWeb ?? "-"} bukan pengajar`
          : "tidak dirujuk sebagai pembimbing/operator",
        dirujuk: isPembimbing || isOperator,
      });
      continue;
    }
    const base = { id, nama: name, nis };
    if (!nis) {
      skipped.push({ ...base, alasan: "username kosong" });
      continue;
    }
    if (!NIS_PATTERN.test(nis)) {
      skipped.push({
        ...base,
        alasan: "username berisi karakter yang tidak didukung login",
      });
      continue;
    }
    if (!name) {
      skipped.push({ ...base, alasan: "nama kosong" });
      continue;
    }
    const key = nis.toLowerCase();
    if (seenNis.has(key)) {
      skipped.push({
        ...base,
        alasan: `username ganda dengan users.id ${seenNis.get(key)}`,
      });
      continue;
    }
    seenNis.set(key, id);

    const existing = existingByNis.get(key);
    if (existing) {
      skipped.push({
        ...base,
        alasan:
          existing.role === "asatidz"
            ? "sudah ada di Firestore (skip)"
            : `NIS sudah dipakai akun ${existing.role || "lain"}`,
        uid: existing.uid,
      });
      continue;
    }

    const jenisKelamin =
      normalizeGender(u.gender) ||
      genderFromTitle(name) ||
      genderFromGolongan(golonganByUser.get(id));

    toCreate.push({
      legacy_id: id,
      nis,
      name,
      email: `${nis}@${emailDomain}`,
      phone: u.phone == null ? "" : String(u.phone).trim(),
      jenis_kelamin: jenisKelamin,
      created_at: u.created_at ?? null,
      peran_web: peranWeb,
      jumlah_santri_bimbingan: (golonganByUser.get(id) || []).length,
      operator_penilaian: isOperator,
    });
  }

  return { toCreate, skipped, notAsatidz };
}

async function createAsatidzAccount(row, password) {
  let userRecord;
  try {
    userRecord = await admin.auth().createUser({
      email: row.email,
      password,
      displayName: row.name,
    });
  } catch (e) {
    if (e.code === "auth/email-already-exists") {
      // Jangan mengambil alih/mereset akun Auth yang sudah ada.
      throw new Error("email sudah ada di Authentication tanpa profil Firestore");
    }
    throw e;
  }

  const uid = userRecord.uid;
  const now = admin.firestore.FieldValue.serverTimestamp();
  const createdAt = dateTimeToJakartaTimestamp(row.created_at) || now;
  try {
    const batch = db.batch();
    batch.create(db.collection("users").doc(uid), {
      name: row.name,
      email: row.email,
      nis: row.nis,
      phone: row.phone,
      role: "asatidz",
      is_admin: false,
      uid,
      created_at: createdAt,
    });
    batch.create(db.collection("asatidz_profiles").doc(uid), {
      is_active: true,
      jenis_kelamin: row.jenis_kelamin,
      name: row.name,
      nis: row.nis,
      uid,
      created_at: createdAt,
    });
    await batch.commit();
  } catch (e) {
    await admin
      .auth()
      .deleteUser(uid)
      .catch((err) => console.error("Rollback Auth asatidz gagal:", uid, err));
    throw e;
  }
  return uid;
}

exports.importAsatidz = onRequest(FUNCTION_OPTIONS, async (req, res) => {
  if (!authorizeLegacyAdminHttp(req, res)) return;
  const apply = req.query.apply === "true";
  const { year, startMonth } = legacyMigrationConfig();
  let source;
  try {
    source = await openLegacySource(req);
    const { rows: users, detected } = await source.users();
    const pembimbingRows = await source.pembimbingRows();
    const operatorIds = await source.operatorIds(year, startMonth);

    const snap = await db.collection("users").select("nis", "role").get();
    const existingByNis = new Map();
    snap.forEach((doc) => {
      const nis = normNis(doc.data().nis).toLowerCase();
      if (nis && !existingByNis.has(nis)) {
        existingByNis.set(nis, { uid: doc.id, role: doc.data().role || "" });
      }
    });

    const { toCreate, skipped, notAsatidz } = planAsatidzImport({
      users,
      pembimbingRows,
      operatorIds,
      existingByNis,
      emailDomain: AUTH_EMAIL_DOMAIN.value(),
    });

    const created = [];
    const failed = [];
    if (apply) {
      const password = asatidzInitialPassword();
      for (const row of toCreate) {
        try {
          const uid = await createAsatidzAccount(row, password);
          created.push({ nis: row.nis, nama: row.name, uid });
        } catch (e) {
          failed.push({ nis: row.nis, nama: row.name, error: e.message });
        }
      }
    }

    const tanpaJenisKelamin = toCreate.filter((r) => !r.jenis_kelamin);
    res.json({
      summary: {
        mode: apply ? "APPLY (data ditulis)" : "DRY-RUN (tidak ada perubahan)",
        sumber: source.kind,
        periodePenilaian: `${year}-${String(startMonth).padStart(2, "0")} dst.`,
        kolomTerdeteksi: detected,
        totalUsersWeb: users.length,
        akanDibuat: toCreate.length,
        dilewati: skipped.length,
        bukanAsatidz: notAsatidz.length,
        jenisKelaminKosong: tanpaJenisKelamin.length,
        berhasilDibuat: apply ? created.length : null,
        gagal: apply ? failed.length : null,
      },
      ...(apply
        ? { created, failed }
        : {
            previewDibuat: toCreate.map((r) => ({
              nis: r.nis,
              nama: r.name,
              email: r.email,
              phone: r.phone,
              jenis_kelamin: r.jenis_kelamin,
              peran_web: r.peran_web,
              jumlah_santri_bimbingan: r.jumlah_santri_bimbingan,
              operator_penilaian: r.operator_penilaian,
            })),
          }),
      dilewati: skipped,
      bukanAsatidz: notAsatidz,
    });
  } catch (err) {
    console.error("importAsatidz error:", err);
    res.status(err.status || 500).json({ error: err.message });
  } finally {
    if (source) await source.close();
  }
});

exports._private = {
  planAsatidzImport,
  normalizeGender,
  genderFromTitle,
  genderFromGolongan,
};
