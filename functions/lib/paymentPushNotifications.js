const { monthNameId } = require("./jakartaTime");

function formatArrearsList(months) {
  const labels = (months || []).map(
    (item) => `${monthNameId(item.month)} ${item.year}`,
  );
  if (labels.length <= 4) return labels.join(", ");
  return `${labels.slice(0, 3).join(", ")}, dan ${labels.length - 3} bulan lainnya`;
}

function buildPaymentDuePushNotification(parts) {
  const monthName = monthNameId(parts.month);
  return {
    title: `Pembayaran SPP ${monthName}`,
    body:
      `Pembayaran SPP bulan ${monthName} ${parts.year} sudah dapat ditunaikan. ` +
      "Abaikan pesan ini jika sudah membayar.",
    data: {
      type: "payment_due",
      bulan: parts.month,
      tahun: parts.year,
    },
  };
}

function buildPaymentArrearsPushNotification(santri, parts) {
  const count = Number(santri.count || santri.months?.length || 0);
  const months = formatArrearsList(santri.months);
  const body =
    count === 1
      ? `Pembayaran SPP bulan ${months} belum kami terima. Mohon segera melakukan pembayaran.`
      : `Anda memiliki tunggakan SPP ${count} bulan: ${months}. Mohon segera melakukan pembayaran.`;
  return {
    title: "Pengingat Pembayaran SPP",
    body,
    data: {
      type: "payment_arrears",
      count,
      bulan: parts.month,
      tahun: parts.year,
    },
  };
}

module.exports = {
  formatArrearsList,
  buildPaymentDuePushNotification,
  buildPaymentArrearsPushNotification,
};
