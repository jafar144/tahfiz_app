// Util tanggal berbasis zona waktu Asia/Jakarta (WIB).
// Dipakai penjadwal agar perhitungan "akhir bulan" konsisten dengan app.

const MONTH_NAMES_ID = [
  "Januari",
  "Februari",
  "Maret",
  "April",
  "Mei",
  "Juni",
  "Juli",
  "Agustus",
  "September",
  "Oktober",
  "November",
  "Desember",
];

// Mengembalikan bagian tanggal di zona Jakarta beserta sisa hari di bulan ini.
// { year, month (1-12), day, daysInMonth, daysRemaining }
function jakartaDateParts(date = new Date()) {
  const fmt = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Jakarta",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  const [year, month, day] = fmt.format(date).split("-").map(Number);

  // new Date(year, month, 0) = hari terakhir bulan ke-`month` (murni kalkulasi
  // kalender pada integer, jadi tidak terpengaruh zona waktu server).
  const daysInMonth = new Date(year, month, 0).getDate();
  const daysRemaining = daysInMonth - day;

  return { year, month, day, daysInMonth, daysRemaining };
}

function monthNameId(month) {
  return MONTH_NAMES_ID[month - 1] || String(month);
}

module.exports = {
  jakartaDateParts,
  monthNameId,
};
