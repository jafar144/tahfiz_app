# Khoirun Functions — Rekonsiliasi Data

Cloud Functions (v2) untuk membandingkan data Web (MySQL) vs Mobile (Firestore).

## Function yang tersedia

- `compareSantri` — bandingkan santri berdasarkan **NIS**. Menampilkan:
  1. Santri yang ada di **Web** tapi **tidak ada di Mobile**
  2. Santri yang ada di **Mobile** tapi **tidak ada di Web**

- `checkBirthDates` — bandingkan **tanggal lahir** Web (MySQL `santris`) vs Mobile
  (Firestore `santri_profiles`), dicocokkan berdasarkan **NIS**. Menampilkan:
  1. Santri yang tanggal lahirnya **beda** antara Web & Mobile.
  2. Santri yang tanggal lahirnya **anomali** — tahun ≥ ambang (default `2024`,
     ubah dengan `?minYear=2023`), mis. santri baru tak mungkin berumur 2-3 tahun.
  - Tanggal dinormalisasi ke zona WIB (`YYYY-MM-DD`) agar perbandingan tidak
    terganggu jam/zona. `?format=json` untuk output JSON.

- `resetSantriPasswords` — **reset password** Firebase Auth santri yang sudah
  terdaftar (mis. tanggal lahirnya salah saat impor → password ikut salah).
  Login app pakai email `{nis}@khoirunnasyien.app`; password baru ditentukan
  **manual per-NIS**:
  - Kirim `password` eksplisit, **atau** `tanggal_lahir` (`YYYY-MM-DD`) yang akan
    diturunkan jadi password `YYYYMMDD` (konvensi mobile).
  - Input: JSON body `{ "items": [ { "nis": "123", "tanggal_lahir": "2010-05-12" },
    { "nis": "456", "password": "rahasia123" } ] }` — atau satu santri lewat query
    `?nis=123&tanggal_lahir=2010-05-12`.
  - **Default DRY-RUN.** Jalankan dulu untuk lihat `preview` (NIS, nama, email,
    `passwordBaru`), lalu `?apply=true`.
  - **APPLY butuh token** (langkah sensitif). Set sekali:
    `firebase functions:secrets:set RESET_TOKEN`, lalu kirim `?token=...` saat apply.
  - Opsional `?syncProfile=true` → sekalian perbaiki `santri_profiles.tanggal_lahir`
    bila `tanggal_lahir` diberikan.

- `importSantri` — migrasi santri Web → Mobile:
  - Santri di Web tapi tidak di Mobile → buat akun Auth + dokumen
    `users/{uid}` & `santri_profiles/{uid}`.
  - Santri di Mobile tapi tidak di Web → set `santri_profiles.is_active = false`.
  - **Default DRY-RUN** (tidak menulis). Jalankan dulu tanpa parameter untuk
    melihat preview, lalu tambahkan `?apply=true` untuk benar-benar menulis.

  Aturan mapping:
  | Firestore | Sumber |
  |-----------|--------|
  | email | `nis@khoirunnasyien.app` |
  | password (Auth) | tanggal lahir `YYYYMMDD` (konvensi mobile) |
  | users.phone | dikosongkan |
  | jenis_kelamin | `golongan` diawali "Putra" → L, "Putri" → P |
  | tipe_kelas | kata ke-2 dari `golongan` (mis. "Putra Sore" → "Sore") |
  | nomor_wali | `phone` MySQL (kalau ada) |
  | tanggal_lahir | DATE MySQL @ 00:00 WIB |
  | tanggal_masuk | `created_at` MySQL |
  | free_until / nama_wali / halaqah_id | dikosongkan |

  > Tabel MySQL harus punya kolom: `nama, nis, tanggal_lahir, kelas, golongan,
  > phone, tempat_lahir, created_at`. Kalau nama kolom berbeda, sesuaikan query
  > `SELECT ... FROM santris` di `index.js`.

- `importPayments` — migrasi pembayaran **tahun 2026**, hanya yang **sudah bayar**
  (`payments.status = 1`):
  - **Bagian A** — santri `status_spp = 2` (gratis) → set
    `santri_profiles.free_until = tanggal_masuk + 10 tahun`.
  - **Bagian B** — tiap baris `payments` → buat dokumen `payments` Firestore:
    `santri_id`=uid, `bulan` (angka), `tahun`=2026, `total`=200000,
    `metode`="migrasi", `created_by`="SYSTEM_MIGRATION", `created_at`=serverTimestamp.
  - **Anti-duplikat:** sebelum insert, cek apakah pembayaran santri+bulan+tahun
    sudah ada di Firestore. `bulan` dinormalisasi ke angka karena data migrasi
    lama tersimpan campur (int / "1" / "01"), jadi tidak akan dobel.
  - Resolusi id: `payments.santri_id` → `santris.id` → `nis` → `uid`.
  - **Default DRY-RUN.** Jalankan tanpa parameter dulu (periksa `summary`,
    `previewPayments`, `previewFreeUntil`, dan `*Dilewati`), lalu `?apply=true`.

  > Mengasumsikan PK tabel `santris` bernama `id` dan `payments` punya kolom
  > `santri_id, bulan, tahun, status`. Sesuaikan query di `index.js` bila beda.

- `importMonthlyReports` — migrasi penilaian bulanan **tahun 2026** dari tabel
  `nilais` → koleksi `monthly_reports` Firestore:
  | Firestore | Sumber |
  |-----------|--------|
  | santri_id | uid (`nilais.santri_id` → `santris.id` → `nis` → uid) |
  | santri_name | nama santri di Firestore |
  | asatidz_id | uid asatidz (`nilais.operator_id` → `users.username` web → `nis` asatidz Firestore) |
  | asatidz_name | nama asatidz Firestore; kalau operator bukan asatidz → nama operator web |
  | hafalan_terakhir | `hafalan` |
  | nilai_perkembangan | `perkembangan` |
  | nilai_akhlaq | `akhlak` |
  | notes | dikosongkan |
  | bulan / tahun | `bulan` / 2026 |
  | created_at / updated_at | kolom `created_at` / `updated_at` di `nilais` |
  - **Anti-duplikat:** cek `monthly_reports` santri+bulan+tahun yang sudah ada
    (bulan dinormalisasi ke angka).
  - **Default DRY-RUN.** Jalankan dulu, periksa `previewDibuat` & `dilewati`,
    lalu `?apply=true`.

  > Operator dicocokkan lewat `users.username` (web) = `nis` asatidz Firestore.
  > Mengasumsikan `nilais` punya kolom `created_at`/`updated_at`.

- `groupPengajarSantri` — **read-only**, mengelompokkan pengajar & santri yang
  diajar langsung dari data website (MySQL). Grouping per **pembimbing**
  (`santris.pembimbing_id` → `users.id`) **dan per sesi** (`santris.golongan`),
  jadi satu ustadz yang mengajar mis. "Putra Sore" dan "Putra Malam" tampil
  sebagai dua grup terpisah. Tiap grup berisi: nama pengajar, sesi, dan daftar
  santri (NIS + nama). Tampil sebagai HTML; tambahkan `?format=json` untuk JSON.

  > Mengasumsikan tabel `santris` punya kolom `pembimbing_id` (FK ke `users.id`)
  > dan `golongan`. Santri tanpa `pembimbing_id` masuk grup "(tanpa pembimbing)".

## Notifikasi terjadwal (FCM)

Penjadwal mengirim notifikasi lewat token di koleksi `device_tokens` (per `uid`).
Perhitungan tanggal memakai zona **WIB** (`lib/jakartaTime.js`).

Jumlah fungsi terjadwal dibatasi menjadi **3 scheduler**. Dua scheduler notifikasi
berjalan harian dan memilih job lewat kondisi tanggal; satu scheduler lain tetap
menangani cleanup mingguan:

1. `notifyAssessmentWindowOpen` — koordinator penilaian, harian **19:30 WIB**:
   - H-6 akhir bulan: broadcast bahwa window penilaian dibuka.
   - H-1 dan hari terakhir: pengingat penilaian belum lengkap per asatidz.
2. `notifyArrearsMonthEnd` — koordinator SPP, harian **08:00 WIB**:
   - Tanggal 5: ajakan membayar SPP bulan berjalan.
   - Tanggal 15: pengingat tunggakan.
   - H-3 akhir bulan: pengingat tunggakan.
3. `cleanupExpiredSyahadah` — cleanup foto kelulusan, Senin **03:00 WIB**.

Nama scheduler #1 dan #2 mempertahankan export lama agar deploy memperbarui
fungsi yang sudah ada tanpa membuat scheduler keempat.

Saat deploy pertama dari versi enam scheduler, pastikan menyetujui penghapusan
`notifyIncompleteAssessment`, `notifyPaymentDue`, dan
`notifyArrearsMidMonth`. Ketiganya sudah digantikan koordinator di atas dan
tidak boleh dibiarkan aktif karena dapat mengirim notifikasi ganda.

- **SPP santri** (`paymentNotifier.js`, 08:00 WIB) — hanya **santri reguler aktif**:
  `is_active == true` dan **tidak sedang gratis** (`free_until` kosong atau sudah
  lewat; yang `free_until`-nya masih di masa depan dilewati).
  - Bulan mulai tagih = bulan `tanggal_masuk`, atau bulan **setelah** `free_until`
    bila masa gratis sudah lewat — konsisten dengan `PaymentUtils.resolveStartDate`
    di app. `bulan`/`tahun` pada `payments` dinormalisasi ke angka (data campur
    int / "1" / "01").
  - Tap notifikasi membuka beranda santri (`data.type` = `payment_due` /
    `payment_arrears`).

- **Pembersih foto kelulusan** (`cleanupExpiredSyahadah.js`, **tiap Senin 03:00
  WIB**): menghapus entri koleksi `kelulusan` yang `created_at`-nya lebih dari
  **7 hari** beserta file gambarnya di Storage (`syahadah_photos/`), agar storage
  tidak penuh. Path file diambil dari `image_url`. Di app, carousel kelulusan
  hanya menampilkan entri ≤ 7 hari, jadi yang kedaluwarsa sudah tidak tampil
  meski belum sempat dibersihkan.

## Setup

### 1. Install dependency

```bash
cd functions
npm install
```

### 2. Isi konfigurasi MySQL

Salin `.env.example` → `.env`, isi `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_NAME`.

Password MySQL disimpan sebagai **secret** (bukan di `.env`):

```bash
firebase functions:secrets:set DB_PASSWORD
# tempel password saat diminta
```

> Pastikan IP MySQL mengizinkan koneksi dari luar. Cloud Functions tidak punya IP
> tetap by default; bila firewall MySQL membatasi IP, whitelist range Google atau
> sementara izinkan `0.0.0.0/0` (lalu perketat setelah migrasi).

### 3. Deploy

```bash
firebase deploy --only functions
```

Setelah deploy, jalankan link yang muncul:

```
# Rekonsiliasi (read-only)
https://asia-southeast2-khoirun-app.cloudfunctions.net/compareSantri
https://asia-southeast2-khoirun-app.cloudfunctions.net/compareSantri?format=json
https://asia-southeast2-khoirun-app.cloudfunctions.net/checkBirthDates
https://asia-southeast2-khoirun-app.cloudfunctions.net/checkBirthDates?format=json
https://asia-southeast2-khoirun-app.cloudfunctions.net/checkBirthDates?minYear=2023
https://asia-southeast2-khoirun-app.cloudfunctions.net/groupPengajarSantri
https://asia-southeast2-khoirun-app.cloudfunctions.net/groupPengajarSantri?format=json

# Reset password santri — LIHAT DULU (dry-run), lalu EKSEKUSI dengan token
# Satu santri cepat:
https://asia-southeast2-khoirun-app.cloudfunctions.net/resetSantriPasswords?nis=123&tanggal_lahir=2010-05-12
https://asia-southeast2-khoirun-app.cloudfunctions.net/resetSantriPasswords?nis=123&tanggal_lahir=2010-05-12&apply=true&token=RAHASIA
# Banyak santri (POST JSON):
#   curl -X POST '.../resetSantriPasswords?apply=true&token=RAHASIA' \
#     -H 'Content-Type: application/json' \
#     -d '{"items":[{"nis":"123","tanggal_lahir":"2010-05-12"}]}'

# Migrasi — LIHAT DULU (dry-run, tidak menulis)
https://asia-southeast2-khoirun-app.cloudfunctions.net/importSantri

# Migrasi santri — EKSEKUSI (menulis data)
https://asia-southeast2-khoirun-app.cloudfunctions.net/importSantri?apply=true

# Migrasi pembayaran 2026 — LIHAT DULU lalu EKSEKUSI
https://asia-southeast2-khoirun-app.cloudfunctions.net/importPayments
https://asia-southeast2-khoirun-app.cloudfunctions.net/importPayments?apply=true

# Migrasi penilaian bulanan 2026 — LIHAT DULU lalu EKSEKUSI
https://asia-southeast2-khoirun-app.cloudfunctions.net/importMonthlyReports
https://asia-southeast2-khoirun-app.cloudfunctions.net/importMonthlyReports?apply=true
```

- `compareSantri` → tampil 2 list dalam tabel HTML (`?format=json` untuk JSON).
- `importSantri` → **selalu jalankan tanpa `?apply=true` dulu**, periksa
  `previewDibuat` & `akanDinonaktifkan`, baru jalankan dengan `?apply=true`.

## Catatan anti-timeout

- `timeoutSeconds: 540` (9 menit), memory `512MiB`.
- Semua data diambil dalam 1 query MySQL + 1 `get()` Firestore (field `name`, `nis` saja),
  diff dilakukan di memori. Untuk ribuan baris ini berjalan dalam hitungan detik.

## Test lokal (emulator)

```bash
firebase emulators:start --only functions
```

`.env` akan otomatis terbaca. Untuk secret di emulator, set `DB_PASSWORD` di `.env` juga
(emulator membaca `.env` untuk secret).
