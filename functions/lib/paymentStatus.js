const { db } = require("./firebase");
const { jakartaDateParts } = require("./jakartaTime");

// Replikasi logika pembayaran SPP di app (PaymentUtils.resolveStartDate +
// SantriHomeCubit.loadData):
//   - "santri reguler" = aktif & TIDAK sedang gratis (free_until kosong atau
//     sudah lewat). Santri yang free_until-nya masih di masa depan dilewati.
//   - Bulan mulai bayar: kalau pernah gratis & sudah lewat → bulan SETELAH
//     free_until; selain itu → bulan tanggal_masuk.
//   - Tunggakan: tiap bulan dari bulan mulai s/d bulan berjalan yang tidak punya
//     dokumen `payments`.
//
// Catatan zona waktu: tanggal_masuk / free_until disimpan sebagai Timestamp,
// year/month-nya diambil di zona Jakarta (WIB) agar konsisten dengan app yang
// memakai waktu lokal perangkat.

// {year, month(1-12)} digeser `delta` bulan, menangani pergantian tahun.
function shiftMonth(year, month, delta) {
  const idx = year * 12 + (month - 1) + delta;
  return { year: Math.floor(idx / 12), month: (idx % 12) + 1 };
}

// Bulan mulai wajib bayar, atau null bila tak bisa ditentukan.
function resolveStartMonth(freeUntil, tanggalMasuk, now) {
  // Tanggal masuk adalah batas minimum mutlak. Tanpa tanggal masuk, santri
  // tidak boleh dianggap mempunyai kewajiban pembayaran.
  if (!tanggalMasuk) return null;
  const entryParts = jakartaDateParts(tanggalMasuk);
  const entryMonth = { year: entryParts.year, month: entryParts.month };

  if (freeUntil && freeUntil.getTime() <= now.getTime()) {
    const { year, month } = jakartaDateParts(freeUntil);
    const afterFree = shiftMonth(year, month, 1);
    const entryIdx = entryMonth.year * 12 + entryMonth.month - 1;
    const afterFreeIdx = afterFree.year * 12 + afterFree.month - 1;
    return afterFreeIdx > entryIdx ? afterFree : entryMonth;
  }
  return entryMonth;
}

// Ambil santri yang berhak ditagih SPP: is_active == true & tidak sedang gratis.
// Mengembalikan profil yang dibutuhkan FCM dan pengingat WhatsApp.
async function fetchPayingSantri(now = new Date()) {
  const snap = await db
    .collection("santri_profiles")
    .where("is_active", "==", true)
    .get();

  const result = [];
  snap.forEach((doc) => {
    const data = doc.data();
    const freeUntil = data.free_until ? data.free_until.toDate() : null;
    // Lewati santri yang masih dalam masa gratis (free_until di masa depan).
    if (freeUntil && freeUntil.getTime() > now.getTime()) return;
    result.push({
      uid: doc.id,
      name: data.name || "",
      nis: String(data.nis || ""),
      namaWali: data.nama_wali || "",
      nomorWali: data.nomor_wali || "",
      freeUntil,
      tanggalMasuk: data.tanggal_masuk ? data.tanggal_masuk.toDate() : null,
    });
  });
  return result;
}

// Peta santri_id → Set(year*100+month) bulan yang SUDAH dibayar. `bulan`/`tahun`
// dinormalisasi ke angka karena data tersimpan campur (int / "1" / "01").
async function fetchPaidMonths() {
  const snap = await db
    .collection("payments")
    .select("santri_id", "bulan", "tahun")
    .get();

  const paidBySantri = new Map();
  snap.forEach((doc) => {
    const data = doc.data();
    const santriId = data.santri_id;
    const bulan = parseInt(data.bulan, 10);
    const tahun = parseInt(data.tahun, 10);
    if (!santriId || Number.isNaN(bulan) || Number.isNaN(tahun)) return;
    if (!paidBySantri.has(santriId)) paidBySantri.set(santriId, new Set());
    paidBySantri.get(santriId).add(tahun * 100 + bulan);
  });
  return paidBySantri;
}

// Santri reguler aktif yang punya tunggakan pada bulan berjalan (parts) ke bawah.
// Mengembalikan array { uid, name, nis, namaWali, nomorWali, count,
// months: [{year, month}] } (terurut dari bulan terlama).
async function computeUnpaidSantri(parts = jakartaDateParts(), now = new Date()) {
  const [santri, paidBySantri] = await Promise.all([
    fetchPayingSantri(now),
    fetchPaidMonths(),
  ]);

  const currentIdx = parts.year * 12 + (parts.month - 1);
  const result = [];

  for (const s of santri) {
    const start = resolveStartMonth(s.freeUntil, s.tanggalMasuk, now);
    if (!start) continue;

    const startIdx = start.year * 12 + (start.month - 1);
    const paid = paidBySantri.get(s.uid) || new Set();
    const months = [];
    for (let idx = startIdx; idx <= currentIdx; idx++) {
      const year = Math.floor(idx / 12);
      const month = (idx % 12) + 1;
      if (!paid.has(year * 100 + month)) months.push({ year, month });
    }

    if (months.length) {
      result.push({
        uid: s.uid,
        name: s.name,
        nis: s.nis,
        namaWali: s.namaWali,
        nomorWali: s.nomorWali,
        tanggalMasuk: s.tanggalMasuk,
        count: months.length,
        months,
      });
    }
  }

  return result;
}

module.exports = {
  resolveStartMonth,
  fetchPayingSantri,
  computeUnpaidSantri,
};
