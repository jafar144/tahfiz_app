const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { db } = require("../lib/firebase");
const { resolveStartMonth } = require("../lib/paymentStatus");
const { jakartaDateParts } = require("../lib/jakartaTime");
const { normNis } = require("../lib/utils");

// API key yang harus dikirim web (cPanel) lewat header `x-api-key`. Disimpan di
// Secret Manager: `firebase functions:secrets:set GUEST_API_KEY`.
const GUEST_API_KEY = defineSecret("GUEST_API_KEY");

const OPTIONS = {
  region: "asia-southeast2",
  memory: "256MiB",
  timeoutSeconds: 30,
  secrets: [GUEST_API_KEY],
};

// Kumpulan bulan (year*100+month) yang sudah dibayar santri. `bulan`/`tahun`
// tersimpan campur (int / "1" / "01") jadi diparse ke angka.
async function fetchPaidKeys(uid) {
  const snap = await db
    .collection("payments")
    .where("santri_id", "==", uid)
    .select("bulan", "tahun")
    .get();

  const paidKeys = new Set();
  snap.forEach((doc) => {
    const d = doc.data();
    const bulan = parseInt(d.bulan, 10);
    const tahun = parseInt(d.tahun, 10);
    if (!Number.isNaN(bulan) && !Number.isNaN(tahun)) {
      paidKeys.add(tahun * 100 + bulan);
    }
  });
  return paidKeys;
}

// Status SPP bulan berjalan (replikasi logika app):
//   - sedang gratis (free_until di masa depan) → dianggap LUNAS.
//   - bulan berjalan belum masuk masa wajib bayar → LUNAS.
//   - selain itu → LUNAS bila bulan berjalan ada di `payments`.
function isCurrentMonthLunas(freeUntil, tanggalMasuk, paidKeys, now) {
  if (freeUntil && freeUntil.getTime() > now.getTime()) return true;

  const parts = jakartaDateParts(now);
  const curKey = parts.year * 100 + parts.month;

  const start = resolveStartMonth(freeUntil, tanggalMasuk, now);
  if (start && curKey < start.year * 100 + start.month) return true;

  return paidKeys.has(curKey);
}

// Penilaian bulanan terakhir dari `monthly_reports` (diurut created_at terbaru).
async function fetchLatestReport(uid) {
  const snap = await db
    .collection("monthly_reports")
    .where("santri_id", "==", uid)
    .get();

  let latest = null;
  let latestTs = -1;
  snap.forEach((doc) => {
    const d = doc.data();
    const ts = d.created_at ? d.created_at.toDate().getTime() : 0;
    if (ts >= latestTs) {
      latestTs = ts;
      latest = d;
    }
  });
  return latest;
}

// Nama & telepon pembimbing dari laporan terakhir: nama di report, telepon di
// dokumen users/{asatidz_id}. null bila tidak ada.
async function fetchPembimbing(report) {
  if (!report || !report.asatidz_id) {
    return report && report.asatidz_name
      ? { name: report.asatidz_name, phone: "" }
      : null;
  }
  let phone = "";
  try {
    const userDoc = await db.collection("users").doc(report.asatidz_id).get();
    if (userDoc.exists) phone = userDoc.data().phone || "";
  } catch (_) {
    // abaikan; tombol WA cuma tidak muncul.
  }
  return { name: report.asatidz_name || "", phone };
}

// GET /guestLookup?nis=12345678  (header: x-api-key: <GUEST_API_KEY>)
// Read-only. Mengembalikan data yang dipakai view `check` web: profil santri,
// status SPP bulan berjalan, penilaian bulanan terakhir, & pembimbing.
exports.guestLookup = onRequest(OPTIONS, async (req, res) => {
  try {
    const provided = req.get("x-api-key") || req.query.key || "";
    if (provided !== GUEST_API_KEY.value()) {
      res.status(401).json({ error: "unauthorized" });
      return;
    }

    const nis = normNis(req.query.nis);
    if (!nis) {
      res.status(400).json({ error: "nis wajib diisi" });
      return;
    }

    const santriSnap = await db
      .collection("santri_profiles")
      .where("nis", "==", nis)
      .limit(1)
      .get();

    if (santriSnap.empty) {
      res.status(404).json({ found: false, nis });
      return;
    }

    const data = santriSnap.docs[0].data();
    const uid = santriSnap.docs[0].id;
    const freeUntil = data.free_until ? data.free_until.toDate() : null;
    const tanggalMasuk = data.tanggal_masuk ? data.tanggal_masuk.toDate() : null;
    const now = new Date();

    const [paidKeys, report] = await Promise.all([
      fetchPaidKeys(uid),
      fetchLatestReport(uid),
    ]);
    const pembimbing = await fetchPembimbing(report);

    res.set("Cache-Control", "no-store");
    res.json({
      found: true,
      santri: {
        nis: data.nis || nis,
        nama: data.name || "",
        kelas: data.kelas || "",
        statusSpp: isCurrentMonthLunas(freeUntil, tanggalMasuk, paidKeys, now),
        pembimbing,
      },
      nilai: report
        ? {
            perkembangan:
              report.nilai_perkembangan === undefined
                ? null
                : report.nilai_perkembangan,
            akhlak:
              report.nilai_akhlaq === undefined ? null : report.nilai_akhlaq,
            hafalan: report.hafalan_terakhir || "",
            createdAt: report.created_at
              ? report.created_at.toDate().toISOString()
              : null,
          }
        : null,
    });
  } catch (err) {
    console.error("guestLookup error:", err);
    res.status(500).json({ error: err.message });
  }
});
