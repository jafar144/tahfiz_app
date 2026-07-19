const { monthNameId } = require("./jakartaTime");

// Semua naskah WhatsApp terjadwal dipusatkan di file ini agar dapat diubah
// tanpa menyentuh filter penerima atau konfigurasi scheduler.

function formatUnpaidMonths(months, limit = 6) {
  const labels = months.map((item) => `${monthNameId(item.month)} ${item.year}`);
  if (labels.length <= limit) return labels.join(", ");
  return `${labels.slice(0, limit).join(", ")}, dan ${labels.length - limit} bulan lainnya`;
}

function buildArrearsWhatsAppMessage(santri) {
  const nis = santri.nis ? ` (NIS ${santri.nis})` : "";
  return [
    "Assalamu'alaikum warahmatullahi wabarakatuh.",
    "",
    `Bapak/Ibu wali dari Ananda ${santri.name}${nis}, berdasarkan catatan kami masih terdapat tunggakan SPP:`,
    formatUnpaidMonths(santri.months),
    "",
    "Mohon berkenan memeriksa kembali pembayaran melalui aplikasi dan menyelesaikan tunggakan tersebut.",
    "",
    "Pembayaran dapat dilakukan melalui Bank BSI 7117245448 a.n. Fahmi Ramdani.",
    "",
    "Mohon abaikan pesan ini dan informasikan kepada admin apabila pembayaran sudah dilakukan. Jazakumullahu khairan.",
  ].join("\n");
}

function buildBirthdayWhatsAppMessage(santri) {
  const age = santri.age > 0 ? ` yang hari ini genap berusia ${santri.age} tahun` : "";
  return [
    "Assalamu'alaikum warahmatullahi wabarakatuh.",
    "",
    `Barakallahu fii umrik untuk Ananda ${santri.name}${age}.`,
    "Semoga Allah senantiasa memberikan kesehatan, keberkahan umur, kemudahan dalam menghafal Al-Qur'an, serta menjadikannya anak yang saleh/salehah.",
    "",
    "Salam hangat,",
    "Khoirunnasyien",
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
  buildAdminFallbackWhatsAppMessage,
};
