# Cloud Functions Tahfiz white-label

Functions ini dipakai oleh semua flavor, tetapi setiap lembaga wajib deploy ke
Firebase project yang berbeda. Konfigurasi non-secret dibaca dari
`.env.<firebase-project-id>` dan secret disimpan di Google Secret Manager.

## Kelompok Functions

Kelompok inti selalu diekspor:

- provisioning akun santri/asatidz oleh admin;
- app config, energi kuis, dan penghapusan syahadah oleh handler berizin;
- transkripsi bacaan.

Notifikasi terjadwal dan pembersihan foto syahadah default tetap tiga scheduler.
`config/deployment.json` menunda ketiganya untuk `al-jauhar-app` melalui
`scheduledFunctions: false`. Ini konfigurasi deploy, bukan `.env`: Firebase CLI
membaca manifest sebelum memuat `.env.<project-id>`. Project lama yang tidak
tercantum tidak berubah. Jangan menonaktifkan project yang sudah berjalan tanpa
rencana penghapusan scheduler. Al-Jauhar belum menjalankan reminder otomatis
maupun cleanup foto berkala sampai scheduling disepakati.

Kelompok legacy hanya untuk rekonsiliasi sistem lama:

- compare/check/import data MySQL;
- reset password/migrasi fiqih;
- grouping data lama;
- `guestLookup`.

Kelompok legacy tidak diekspor secara default. Ini mencegah Firebase project
lembaga baru meminta atau membawa credential database lembaga lain.

## Setup project lembaga

Salin `.env.example` menjadi `.env.<firebase-project-id>`. Parameter inti:

```dotenv
AUTH_EMAIL_DOMAIN=lembaga.app
INSTITUTION_NAME="Nama Lembaga"
PAYMENT_BANK_NAME=NAMA_BANK
PAYMENT_ACCOUNT_NUMBER=NOMOR_REKENING
PAYMENT_ACCOUNT_HOLDER=NAMA_PEMILIK
APP_CHECK_ENFORCED=false

WABLAS_ENABLED=false
WABLAS_BASE_URL=https://disabled.invalid
WHATSAPP_ADMIN_PHONE=
APP_DOWNLOAD_URL=
WHATSAPP_GROUP_PUTRA_PAGI_ID=
WHATSAPP_GROUP_PUTRA_PAGI_INVITE_URL=
# Lengkapi juga PUTRA_SORE, PUTRA_MALAM, PUTRI_PAGI, PUTRI_SORE, PUTRI_MALAM.

DEPLOY_LEGACY_HTTP_FUNCTIONS=false
LEGACY_ADMIN_HTTP_ENABLED=false
```

Set secret transkripsi:

```powershell
firebase functions:secrets:set GROQ_API_KEY --project FIREBASE_PROJECT_ID
```

Jika Wablas diaktifkan, isi konfigurasi Wablas lalu:

```powershell
firebase functions:secrets:set WABLAS_TOKEN --project FIREBASE_PROJECT_ID
firebase functions:secrets:set WABLAS_SECRET_KEY --project FIREBASE_PROJECT_ID
```

Saat `WABLAS_ENABLED=true`, provisioning santri mengirim welcome message ke
nomor wali (fallback ke nomor santri) setelah akun tersimpan. Scheduler pagi
bersama `notifyArrearsMonthEnd` menangani pembayaran pukul 08:00 WIB dan
reminder penilaian/target ke seluruh ID grup setiap tanggal 3 pukul 09:00 WIB.
Pada Senin pukul 08:00 WIB, scheduler yang sama membaca absensi Minggu Subuh
hari sebelumnya. Jika ada status `alpha`, notifikasi aplikasi dan WA dikirim ke
santri terkait, lalu pengumuman yang sama dikirim ke grup Putra Sore dan Putra
Malam. Jika tidak ada `alpha`, tidak ada pesan yang dikirim.
Scheduler penilaian juga mengirim pengingat personal ke WA asatidz pada H-1
dan hari terakhir bulan. Isi keenam pasangan `..._ID` dan `..._INVITE_URL`; ID
digunakan sebagai tujuan Wablas, invite URL dimasukkan ke welcome message.
Gangguan Wablas tidak membatalkan notifikasi aplikasi atau akun yang sudah
tersimpan.

Jangan menyimpan secret di `.env`, source code, APK, atau log CI.

`APP_CHECK_ENFORCED` tetap `false` sampai debug token dan AAB Play Integrity
terlihat valid di Firebase Console. Setelah itu ubah ke `true`, deploy ulang
Functions, lalu aktifkan enforcement Firestore/Storage dari Console.

## Model keamanan akun

Klien tidak membuat Firebase Auth user dan tidak boleh membuat dokumen
`users`, `santri_profiles`, atau `asatidz_profiles`. Admin memanggil
`provisionInstitutionUser`; handler membuat Auth dan profil secara server-side.

Password awal:

- santri memakai tanggal lahir dengan urutan `YYYYMMDD`, misalnya
  `09/03/2012` menjadi `20120309`;
- password semua akun asatidz ditetapkan server dari `ASATIDZ_INITIAL_PASSWORD`
  pada `.env.<project-id>` (default `Khoirun123`; Al-Jauhar `Jauhar123`) dan
  tidak dapat diubah dari form;
- aplikasi tidak memaksa pengguna mengganti password setelah login.

Fitur ganti akun keluarga memerlukan kedua callable `getFamilyAccounts` dan
`switchFamilyAccount` di project lembaga yang sama dengan aplikasi. Memasang APK
saja tidak memasang callable tersebut. Deploy terarah:

```powershell
firebase deploy --project FIREBASE_PROJECT_ID --only functions:getFamilyAccounts,functions:switchFamilyAccount
```

`switchFamilyAccount` membuat Firebase custom token setelah memverifikasi relasi
keluarga dan akun tujuan. Aktifkan IAM Service Account Credentials API dan berikan
runtime service account Functions role `roles/iam.serviceAccountTokenCreator`
pada resource service account itu sendiri. Role Editor saja tidak mencakup
`iam.serviceAccounts.signBlob`. Izin ini tidak perlu diberikan pada seluruh
project atau kepada akun santri. Jangan menyimpan service account key di aplikasi.

Akun admin pertama dibuat secara manual di Firebase Console mengikuti runbook
lembaga. Tidak ada endpoint bootstrap admin publik.

## Endpoint legacy

Untuk maintenance project lama saja:

```dotenv
DEPLOY_LEGACY_HTTP_FUNCTIONS=true
LEGACY_ADMIN_HTTP_ENABLED=true
DB_HOST=...
DB_PORT=3306
DB_USER=...
DB_NAME=...
```

Set secret:

```powershell
firebase functions:secrets:set DB_PASSWORD --project FIREBASE_PROJECT_ID
firebase functions:secrets:set ADMIN_HTTP_TOKEN --project FIREBASE_PROJECT_ID
firebase functions:secrets:set GUEST_API_KEY --project FIREBASE_PROJECT_ID
```

Semua endpoint maintenance memakai `x-admin-token` atau Bearer token. Token
tidak boleh dikirim melalui query string. Dry-run tetap memerlukan token.

Endpoint import (`compareSantri`, `importSantri`, `importAsatidz`,
`importPayments`, `importMonthlyReports`) membaca MySQL bila dipanggil GET,
atau export JSON phpMyAdmin bila dipanggil POST `{ tables: { santris, users,
payments, nilais } }` (untuk hosting yang menutup port 3306). Gunakan
`scripts/runLegacyMigration.ps1` dengan `-DataDir` dan
`-TokenFromSecretManager`; lihat `docs/setup_al_jauhar.md`.

Contoh:

```powershell
$headers = @{ "x-admin-token" = "TOKEN_DARI_PASSWORD_MANAGER" }
Invoke-RestMethod `
  -Headers $headers `
  -Uri "https://REGION-PROJECT.cloudfunctions.net/importSantri"
```

Untuk apply, tambahkan parameter yang diminta handler, misalnya `?apply=true`.
Setelah maintenance:

1. ubah `LEGACY_ADMIN_HTTP_ENABLED=false`;
2. ubah `DEPLOY_LEGACY_HTTP_FUNCTIONS=false`;
3. deploy ulang Functions dan konfirmasi penghapusan endpoint legacy;
4. rotasi/revoke token bila sudah tidak dipakai.

Script lokal migrasi Firestore tidak mempunyai project fallback. Set project
secara eksplisit dan gunakan Application Default Credentials:

```powershell
$env:GCLOUD_PROJECT = "firebase-project-id"
npm run migrate:santri-fiqih
npm run migrate:quiz-leaderboards -- --month=2026-07
```

Tambahkan `--apply` hanya setelah output dry-run ditinjau.

## Penjadwalan pengingat pembayaran

Menu admin **Penjadwalan → Pembayaran** menampilkan hanya santri aktif yang masih
memiliki tunggakan sampai periode pilihan. Kelompok 1, 2, dan 3+ bulan dihitung dari
jumlah bulan yang belum dibayar, bukan umur tagihan paling lama. Data pembayaran
dibaca ulang saat halaman dimuat dan tepat sebelum pengiriman.

- WA dan notifikasi aplikasi mulai **tanggal 25, pukul 08.00–15.00 WIB**. Notifikasi
  pembayaran terpisah tanggal 5 dan 15 tidak lagi dipilih oleh scheduler.
- Antrean mengisi satu hari dengan jeda pseudorandom **1–15 menit**, stabil per
  santri/periode. Sisa penerima dilanjutkan pada hari berikutnya sampai akhir bulan.
  Tidak ada pembagian penerima ke tanggal-tanggal di awal. Hari yang terlewat akan
  dikejar pada eksekusi harian berikutnya selama masih dalam periode otomatis.
- Reservasi tersimpan di `scheduled_payment_notifications/payment-YYYY-MM-UID`.
  Cursor transaksi `payment_notification_cursors/payment` menjaga jarak slot
  otomatis dan manual, termasuk kiriman susulan untuk periode sebelumnya.
- Retry Cloud Tasks tetap **5 percobaan**, backoff 60–600 detik. Kanal yang sudah
  berhasil tidak dikirim ulang ketika kanal lain gagal. Retry yang melewati jam
  15.00 ditunda. Kegagalan yang menghabiskan percobaan dapat ditindaklanjuti admin.
- Tombol **Kirim manual** memasukkan satu santri ke slot berikutnya dalam jam
  operasional. Setelah akhir bulan, pilih periode sebelumnya untuk susulan.
  Pengiriman yang masih aktif atau sudah selesai tidak dibuat ganda. Pesan yang
  dialihkan ke admin tidak dihitung sebagai terkirim ke wali; setelah nomor wali
  diperbaiki, admin dapat mengirim susulan ke wali.
- Status WA berarti permintaan diterima Wablas, **bukan delivery/read receipt**.
  Status aplikasi ditampilkan tersendiri (terkirim, sebagian, tanpa perangkat, gagal).
  Nomor WA tidak valid atau Wablas nonaktif tidak menghalangi notifikasi aplikasi.
- Semua akses monitor/manual melalui callable berizin admin. Kedua koleksi
  internal tetap ditolak oleh default Firestore rules untuk klien.

Tetap ada **tiga `onSchedule`** dengan nama dan cron yang sama. Fitur ini memakai
`onCall` dan worker `onTaskDispatched`, tanpa menambah Cloud Scheduler.

Deploy terarah ke lembaga yang dipilih (harus memakai project ID eksplisit):

```powershell
firebase deploy --project FIREBASE_PROJECT_ID --only functions:notifyArrearsMonthEnd,functions:getPaymentReminderSchedule,functions:sendManualPaymentReminder,functions:sendScheduledPaymentWhatsApp
```

Setelah deploy, verifikasi ketiga scheduler lama masih terdaftar, callable manual
menolak pemanggil tanpa login, serta endpoint monitor bisa dibuka oleh admin.
Update aplikasi diperlukan untuk menampilkan menu baru; tidak perlu indeks
Firestore tambahan. Jangan memanggil worker/manual dengan data produksi untuk
sekadar smoke test karena tindakan tersebut menjadwalkan pengiriman nyata.

## Pengujian otomatis

Gunakan Node 22 dan Java 21+ untuk Firebase emulator. Build Android tetap
memakai Java 17:

```powershell
npm ci
npm audit --omit=dev
npm test
npm run test:rules
```

`test:rules` menyalakan emulator Firestore dan Storage, lalu memastikan:

- anonymous dan akses lintas santri ditolak;
- role tidak dapat dinaikkan dari klien;
- asatidz hanya dapat menulis data kegiatan;
- token perangkat terikat pada pemilik;
- upload Storage dibatasi role, tipe file, dan ukuran.

## Deploy

Selalu tulis project ID:

```powershell
firebase deploy `
  --project FIREBASE_PROJECT_ID `
  --only firestore:rules,firestore:indexes,storage

firebase deploy `
  --project FIREBASE_PROJECT_ID `
  --only functions
```

Runbook lengkap Barokatul Qur'an berada di
`docs/setup_barokatul_quran.md`.
