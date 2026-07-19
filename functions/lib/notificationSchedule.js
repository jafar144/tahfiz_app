// Perencana murni untuk seluruh notifikasi terjadwal. Pemisahan keputusan
// tanggal dari handler Firebase menjaga jumlah Cloud Scheduler tetap tiga dan
// membuat setiap kondisi dapat diuji tanpa koneksi Firestore/FCM.

const ASSESSMENT_WINDOW_OPEN_DAYS_REMAINING = 6;
const ASSESSMENT_LAST_DAYS_THRESHOLD = 1;
const PAYMENT_DUE_DAY = 5;
const ARREARS_MID_DAY = 15;
const ARREARS_MONTH_END_DAYS_REMAINING = 3;

const ASSESSMENT_JOBS = Object.freeze({
  windowOpen: "windowOpen",
  incomplete: "incomplete",
});

const PAYMENT_JOBS = Object.freeze({
  paymentDue: "paymentDue",
  arrearsMidMonth: "arrearsMidMonth",
  arrearsMonthEnd: "arrearsMonthEnd",
  birthdayWhatsApp: "birthdayWhatsApp",
});

function assessmentJobNames(parts) {
  const jobs = [];
  if (parts.daysRemaining === ASSESSMENT_WINDOW_OPEN_DAYS_REMAINING) {
    jobs.push(ASSESSMENT_JOBS.windowOpen);
  }
  if (parts.daysRemaining <= ASSESSMENT_LAST_DAYS_THRESHOLD) {
    jobs.push(ASSESSMENT_JOBS.incomplete);
  }
  return jobs;
}

function paymentJobNames(parts) {
  const jobs = [];
  if (parts.day === PAYMENT_DUE_DAY) {
    jobs.push(PAYMENT_JOBS.paymentDue);
  }
  if (parts.day === ARREARS_MID_DAY) {
    jobs.push(PAYMENT_JOBS.arrearsMidMonth);
  }
  if (parts.daysRemaining === ARREARS_MONTH_END_DAYS_REMAINING) {
    jobs.push(PAYMENT_JOBS.arrearsMonthEnd);
  }
  // Scheduler pembayaran berjalan harian; pemeriksaan ulang tahun menumpang di
  // sini agar tidak menambah Cloud Scheduler keempat.
  jobs.push(PAYMENT_JOBS.birthdayWhatsApp);
  return jobs;
}

// Jalankan hanya job terpilih. Eksekusi sengaja berurutan agar pembacaan data
// besar tidak saling berebut resource bila dua kondisi suatu saat berimpit.
async function runScheduledJobs(jobNames, runners, parts) {
  if (!jobNames.length) return { skipped: true, jobs: {} };

  const results = {};
  for (const name of jobNames) {
    const runner = runners[name];
    if (typeof runner !== "function") {
      throw new TypeError(`Runner scheduler tidak tersedia: ${name}`);
    }
    results[name] = await runner(parts);
  }
  return { skipped: false, jobs: results };
}

module.exports = {
  ASSESSMENT_WINDOW_OPEN_DAYS_REMAINING,
  ASSESSMENT_LAST_DAYS_THRESHOLD,
  PAYMENT_DUE_DAY,
  ARREARS_MID_DAY,
  ARREARS_MONTH_END_DAYS_REMAINING,
  ASSESSMENT_JOBS,
  PAYMENT_JOBS,
  assessmentJobNames,
  paymentJobNames,
  runScheduledJobs,
};
