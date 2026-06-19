const { admin } = require("./firebase");

function normNis(value) {
  if (value === null || value === undefined) return "";
  let s = String(value).trim();
  if (s.endsWith(".0")) s = s.slice(0, -2);
  return s;
}

function escapeHtml(s) {
  return String(s ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function jenisKelaminFromGolongan(golongan) {
  const g = String(golongan ?? "").trim().toLowerCase();
  if (g.startsWith("putri")) return "P";
  if (g.startsWith("putra")) return "L";
  return "";
}

function tipeKelasFromGolongan(golongan) {
  const parts = String(golongan ?? "").trim().split(/\s+/);
  return parts[1] || "";
}

function dateOnlyToJakartaTimestamp(value) {
  const s = String(value ?? "").trim();
  const m = s.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (!m) return null;
  return admin.firestore.Timestamp.fromDate(
    new Date(`${m[1]}-${m[2]}-${m[3]}T00:00:00+07:00`)
  );
}

function dateTimeToJakartaTimestamp(value) {
  const s = String(value ?? "").trim();
  const m = s.match(/^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})/);
  if (!m) return null;
  return admin.firestore.Timestamp.fromDate(
    new Date(`${m[1]}-${m[2]}-${m[3]}T${m[4]}:${m[5]}:${m[6]}+07:00`)
  );
}

// Normalisasi nilai tanggal apa pun (string MySQL "YYYY-MM-DD ..." atau
// Firestore Timestamp) menjadi string "YYYY-MM-DD" di zona Jakarta, agar bisa
// dibandingkan tanggal-vs-tanggal tanpa terganggu jam/zona. Mengembalikan null
// bila tidak bisa diparse.
function toJakartaDateString(value) {
  if (value === null || value === undefined) return null;

  // Firestore Timestamp (punya toDate) atau objek Date.
  let date = null;
  if (typeof value.toDate === "function") date = value.toDate();
  else if (value instanceof Date) date = value;

  if (date) {
    if (isNaN(date.getTime())) return null;
    return new Intl.DateTimeFormat("en-CA", {
      timeZone: "Asia/Jakarta",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).format(date);
  }

  // String tanggal (mis. DATE/DATETIME dari MySQL).
  const m = String(value).trim().match(/^(\d{4})-(\d{2})-(\d{2})/);
  return m ? `${m[1]}-${m[2]}-${m[3]}` : null;
}

function passwordFromBirthDate(value) {
  const s = String(value ?? "").trim();
  const m = s.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (!m) return null;
  return `${m[1]}${m[2]}${m[3]}`;
}

function plusYearsJakartaTimestamp(value, years) {
  const s = String(value ?? "").trim();
  const m = s.match(/^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2}):(\d{2}))?/);
  if (!m) return null;
  const y = Number(m[1]) + years;
  const hh = m[4] || "00";
  const mm = m[5] || "00";
  const ss = m[6] || "00";
  return admin.firestore.Timestamp.fromDate(
    new Date(`${y}-${m[2]}-${m[3]}T${hh}:${mm}:${ss}+07:00`)
  );
}

module.exports = {
  normNis,
  escapeHtml,
  jenisKelaminFromGolongan,
  tipeKelasFromGolongan,
  dateOnlyToJakartaTimestamp,
  dateTimeToJakartaTimestamp,
  toJakartaDateString,
  passwordFromBirthDate,
  plusYearsJakartaTimestamp,
};
