# Cloud Functions Tahfiz white-label

Functions ini dipakai oleh semua flavor, tetapi setiap lembaga wajib deploy ke
Firebase project yang berbeda. Konfigurasi non-secret dibaca dari
`.env.<firebase-project-id>` dan secret disimpan di Google Secret Manager.

## Kelompok Functions

Kelompok inti selalu diekspor:

- provisioning akun santri/asatidz oleh admin;
- app config, energi kuis, dan penghapusan syahadah oleh handler berizin;
- transkripsi bacaan;
- notifikasi terjadwal dan pembersihan foto syahadah.

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
STAFF_INITIAL_PASSWORD=
APP_CHECK_ENFORCED=false

WABLAS_ENABLED=false
WABLAS_BASE_URL=https://disabled.invalid
WHATSAPP_ADMIN_PHONE=

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
- asatidz dapat memakai nilai `STAFF_INITIAL_PASSWORD` per lembaga; jika
  kosong, password dibuat acak;
- aplikasi tidak memaksa pengguna mengganti password setelah login.

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

## Pengujian

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
