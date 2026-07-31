const { monthNameId } = require("./jakartaTime");

// Semua naskah WhatsApp terjadwal dipusatkan di file ini agar dapat diubah
// tanpa menyentuh filter penerima atau konfigurasi scheduler.

function formatUnpaidMonths(months, limit = 6) {
  const labels = months.map((item) => `${monthNameId(item.month)} ${item.year}`);
  if (labels.length <= limit) return labels.join(", ");
  return `${labels.slice(0, limit).join(", ")}, dan ${labels.length - limit} bulan lainnya`;
}

function buildArrearsWhatsAppMessage(santri, institution) {
  const nis = santri.nis ? ` (NIS ${santri.nis})` : "";
  return [
    "Assalamu'alaikum warahmatullahi wabarakatuh.",
    "",
    `Bapak/Ibu wali dari Ananda ${santri.name}${nis}, berdasarkan catatan kami masih terdapat tunggakan SPP:`,
    formatUnpaidMonths(santri.months),
    "",
    "Mohon berkenan memeriksa kembali pembayaran melalui aplikasi dan menyelesaikan tunggakan tersebut.",
    "",
    `Pembayaran dapat dilakukan melalui Bank ${institution.bankName} ` +
      `${institution.accountNumber} a.n. ${institution.accountHolder}.`,
    "",
    "Mohon abaikan pesan ini dan informasikan kepada admin apabila pembayaran sudah dilakukan. Jazakumullahu khairan.",
  ].join("\n");
}

function buildBirthdayWhatsAppMessage(santri, institution) {
  const age = santri.age > 0 ? ` yang hari ini genap berusia ${santri.age} tahun` : "";
  return [
    "Assalamu'alaikum warahmatullahi wabarakatuh.",
    "",
    `Barakallahu fii umrik untuk Ananda ${santri.name}${age}.`,
    "Semoga Allah senantiasa memberikan kesehatan, keberkahan umur, kemudahan dalam menghafal Al-Qur'an, serta menjadikannya anak yang saleh/salehah.",
    "",
    "Salam hangat,",
    institution.institutionName,
  ].join("\n");
}

function buildSantriWelcomeWhatsAppMessage({
  santri,
  password,
  institution,
  appUrl,
  group,
}) {
  const genderLabel = santri.jenisKelamin === "P" ? "Putri" : "Putra";
  return [
    "Assalamu'alaikum warahmatullahi wabarakatuh.",
    "",
    `Alhamdulillah, Ananda ${santri.name} sudah terdaftar sebagai santri ${institution.institutionName}. Selamat bergabung.`,
    "",
    "*Data santri*",
    `Nama: ${santri.name}`,
    `NIS: ${santri.nis}`,
    `Kelas: ${santri.kelas}`,
    `Sesi: ${santri.tipeKelas}`,
    `Kelompok: ${genderLabel}`,
    "",
    "*Akses aplikasi*",
    `NIS/login: ${santri.nis}`,
    `Password awal: ${password}`,
    `Link aplikasi: ${appUrl}`,
    "",
    "Aplikasi dapat digunakan untuk memantau progres hafalan dan target bulanan, melihat hasil penilaian, serta mengecek status pembayaran.",
    "",
    `Silakan bergabung ke Grup WhatsApp ${group.label}:`,
    group.inviteUrl,
    "",
    "Mohon simpan data login dengan baik dan tidak membagikan password kepada pihak lain. Jazakumullahu khairan.",
  ].join("\n");
}

function previousMonthParts(parts) {
  return parts.month === 1
    ? { month: 12, year: parts.year - 1 }
    : { month: parts.month - 1, year: parts.year };
}

function buildMonthlyAssessmentGroupMessage(parts, institution) {
  const previous = previousMonthParts(parts);
  return [
    "Assalamu'alaikum warahmatullahi wabarakatuh.",
    "",
    `Bapak/Ibu, penilaian santri bulan ${monthNameId(previous.month)} ${previous.year} dan target hafalan bulan ${monthNameId(parts.month)} ${parts.year} sudah tersedia di aplikasi.`,
    "",
    "Silakan dicek melalui akun masing-masing. Jika ada yang ingin disampaikan, silakan hubungi asatidz masing-masing.",
    "",
    `Jazakumullahu khairan.\n${institution.institutionName}`,
  ].join("\n");
}

function buildIncompleteAssessmentWhatsAppMessage(
  asatidz,
  parts,
  institution,
) {
  const recipient = asatidz.name
    ? `Ustadz/Ustadzah ${asatidz.name}`
    : "Ustadz/Ustadzah";
  return [
    "Assalamu'alaikum warahmatullahi wabarakatuh.",
    "",
    `${recipient}, masih ada ${asatidz.count} dari ${asatidz.total} santri binaan yang penilaian bulan ${monthNameId(parts.month)} ${parts.year} belum dilengkapi.`,
    "",
    "Mohon berkenan melengkapinya melalui aplikasi sebelum bulan ini berakhir. Jika sudah selesai, pesan ini dapat diabaikan.",
    "",
    `Jazakumullahu khairan.\n${institution.institutionName}`,
  ].join("\n");
}

function buildAdminFallbackWhatsAppMessage({
  santri,
  notificationType,
  reason,
  originalMessage,
}) {
  const typeLabel =
    notificationType === "birthday"
      ? "ucapan ulang tahun"
      : "pengingat tunggakan SPP";
  const nis = santri.nis ? ` (NIS ${santri.nis})` : "";
  return [
    "[NOTIFIKASI OTOMATIS UNTUK ADMIN]",
    "",
    `Pesan ${typeLabel} untuk wali Ananda ${santri.name}${nis} tidak dapat dikirim karena ${reason}.`,
    "",
    "Isi pesan yang seharusnya dikirim:",
    originalMessage,
    "",
    "Pesan ini otomatis dialihkan kepada Anda karena nomor ini terdaftar sebagai nomor admin.",
  ].join("\n");
}

module.exports = {
  formatUnpaidMonths,
  buildArrearsWhatsAppMessage,
  buildBirthdayWhatsAppMessage,
  buildSantriWelcomeWhatsAppMessage,
  previousMonthParts,
  buildMonthlyAssessmentGroupMessage,
  buildIncompleteAssessmentWhatsAppMessage,
  buildAdminFallbackWhatsAppMessage,
};
