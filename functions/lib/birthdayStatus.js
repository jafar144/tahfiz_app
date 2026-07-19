const { db } = require("./firebase");
const { jakartaDateParts } = require("./jakartaTime");

function firestoreDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === "function") return value.toDate();
  return null;
}

function birthdayInfo(value, parts) {
  const birthDate = firestoreDate(value);
  if (!birthDate || Number.isNaN(birthDate.getTime())) return null;
  const birthParts = jakartaDateParts(birthDate);
  if (birthParts.month !== parts.month || birthParts.day !== parts.day) {
    return null;
  }
  const age = parts.year - birthParts.year;
  if (age < 0) return null;
  return { birthDate, age };
}

async function fetchTodayBirthdays(parts = jakartaDateParts()) {
  const snap = await db
    .collection("santri_profiles")
    .where("is_active", "==", true)
    .select("name", "nis", "nama_wali", "nomor_wali", "tanggal_lahir")
    .get();

  const result = [];
  snap.forEach((doc) => {
    const data = doc.data();
    const info = birthdayInfo(data.tanggal_lahir, parts);
    if (!info) return;
    result.push({
      uid: doc.id,
      name: data.name || "Santri",
      nis: String(data.nis || ""),
      namaWali: data.nama_wali || "",
      nomorWali: data.nomor_wali || "",
      birthDate: info.birthDate,
      age: info.age,
    });
  });
  return result;
}

module.exports = {
  firestoreDate,
  birthdayInfo,
  fetchTodayBirthdays,
};
