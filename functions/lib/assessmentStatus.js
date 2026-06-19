const { db } = require("./firebase");

// Replikasi logika AdminAssessmentCubit (lib/.../admin_assessment_cubit.dart):
// menentukan asatidz yang penilaian bulanannya BELUM lengkap pada bulan & tahun
// tertentu. Hemat baca: satu query per koleksi, lalu digabung di memori.
//
// Relasi data: santri terhubung ke halaqah lewat santri_profiles.halaqah_id,
// halaqah terhubung ke asatidz lewat halaqahs.asatidz.id (= uid asatidz).
//
// Mengembalikan array: { uid, name, total, count }
//   total  = jumlah santri aktif yang menjadi tanggung jawab asatidz
//   count  = jumlah santri yang belum dinilai bulan ini
async function computeIncompleteAsatidz(bulan, tahun) {
  // 1. Halaqah → peta halaqahId→teacherId dan teacherId→nama.
  const halaqahsSnap = await db.collection("halaqahs").get();
  const teacherByHalaqah = new Map();
  const teacherName = new Map();
  halaqahsSnap.forEach((doc) => {
    const asatidz = doc.data().asatidz || {};
    const teacherId = asatidz.id;
    if (!teacherId) return;
    teacherByHalaqah.set(doc.id, teacherId);
    if (!teacherName.has(teacherId)) teacherName.set(teacherId, asatidz.name || "");
  });

  // 2. Asatidz aktif (filter sama seperti di app).
  const asatidzSnap = await db
    .collection("asatidz_profiles")
    .where("is_active", "==", true)
    .get();
  const activeAsatidz = new Set(asatidzSnap.docs.map((doc) => doc.id));

  // 3. Santri aktif → kelompokkan id santri per asatidz lewat halaqah_id.
  const santriSnap = await db
    .collection("santri_profiles")
    .where("is_active", "==", true)
    .get();
  const santriIdsByTeacher = new Map();
  santriSnap.forEach((doc) => {
    const halaqahId = doc.data().halaqah_id;
    if (!halaqahId) return;
    const teacherId = teacherByHalaqah.get(halaqahId);
    if (!teacherId) return;
    if (!santriIdsByTeacher.has(teacherId)) santriIdsByTeacher.set(teacherId, new Set());
    santriIdsByTeacher.get(teacherId).add(doc.id);
  });

  // 4. Santri yang sudah dinilai pada bulan & tahun tsb.
  const reportsSnap = await db
    .collection("monthly_reports")
    .where("bulan", "==", bulan)
    .where("tahun", "==", tahun)
    .get();
  const reportedSantriIds = new Set(
    reportsSnap.docs.map((doc) => doc.data().santri_id).filter(Boolean)
  );

  // 5. Susun daftar asatidz yang belum lengkap.
  const result = [];
  for (const [teacherId, santriIds] of santriIdsByTeacher) {
    if (!activeAsatidz.has(teacherId)) continue;
    let unassessed = 0;
    for (const santriId of santriIds) {
      if (!reportedSantriIds.has(santriId)) unassessed += 1;
    }
    if (unassessed > 0) {
      result.push({
        uid: teacherId,
        name: teacherName.get(teacherId) || "",
        total: santriIds.size,
        count: unassessed,
      });
    }
  }

  return result;
}

module.exports = { computeIncompleteAsatidz };
