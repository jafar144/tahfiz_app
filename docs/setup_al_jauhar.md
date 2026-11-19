# Al-Jauhar — Android dan Firebase

Flavor ketiga, dibuat 8 Oktober 2026. Konfigurasi awal dan logo mengikuti
Khoirunnasyien atas permintaan pemilik; data pengguna tidak disalin.

## Identitas

| Item | Nilai |
|---|---|
| Nama aplikasi | Tahfiz Al-Jauhar |
| Flavor / Firebase alias | `al_jauhar` |
| Android application ID | `id.or.aljauhar.tahfiz` |
| Entry point | `lib/main_al_jauhar.dart` |
| Versi pertama | `1.0.0+1` |
| Firebase project | `al-jauhar-app` |
| Project number | `469727255045` |
| Firebase Android app ID | `1:469727255045:android:0f24a420b6a4d50bea5a6c` |
| Login internal | `<nis>@aljauhar.app` |
| Firestore / Functions / Storage | `asia-southeast2` (Jakarta) |
| Bucket | `al-jauhar-app.firebasestorage.app` |

[Firebase Console](https://console.firebase.google.com/project/al-jauhar-app/overview).
Alias default repository tetap `khoirun-app`: **selalu pakai `--project
al-jauhar-app`** saat menjalankan perintah Al-Jauhar.

## Konfigurasi dan batasan awal

- Billing Blaze terhubung ke billing account Khoirunnasyien, dengan persetujuan
  pemilik. Blaze tidak menjamin seluruh penggunaan gratis.
- Email/Password aktif. Provisioning Firebase CLI membuat subtype Authentication
  `IDENTITY_PLATFORM`, berbeda dari `FIREBASE_AUTH` project lama. Aplikasi tetap
  memakai login yang sama. Pada Blaze, Auth Identity Platform memiliki kuota
  gratis 50.000 pengguna aktif bulanan; di atas kuota dapat ditagihkan.
  Lihat [ketentuan Firebase Auth](https://firebase.google.com/docs/auth#identity-platform).
- Firestore Native Standard dan default Storage telah dibuat di Jakarta;
  Rules dan indexes memakai file bersama dalam repository.
- Seluruh 18 Functions inti aktif di Jakarta. Akun layanan runtime diberi
  `roles/iam.serviceAccountTokenCreator` hanya pada dirinya sendiri untuk
  custom token keluarga. IAM Credentials API aktif. Service agent Storage
  memiliki `roles/firebaserules.firestoreServiceAgent` agar Rules dapat
  membaca role pengguna dari Firestore.
- Image build Functions dibersihkan otomatis setelah 1 hari, sama dengan
  kebijakan Khoirunnasyien. Ini bukan penghapusan data/foto atau fungsi aktif,
  dan tidak menambah Cloud Scheduler.
- `app_config/runtime.features.tahfiz_arena=true`, mengikuti konfigurasi
  Khoirunnasyien. Database diawali hanya akun admin dan konfigurasi tersebut.
- Kelas, tipe kelas, materi hafalan, fiqih, milestone, serta template syahadah
  disalin ke direktori flavor sendiri. Logo/ikon/splash masih gambar Khoirun.
- Rekening sementara sama: BSI `7117245448`, a.n. Fahmi Ramdani.
- `GROQ_API_KEY` disalin ke Secret Manager Al-Jauhar dengan persetujuan pemilik;
  kuota Groq masih berbagi. Rotasi key di Khoirun tidak otomatis memperbarui
  salinan Al-Jauhar.
- Wablas **nonaktif**; nomor admin, tujuan grup, invite URL, dan URL download
  belum diisi. Secret Wablas baru berisi placeholder nonaktif agar deklarasi
  Functions dapat dipasang, bukan credential WhatsApp Khoirun.
- App Check Play Integrity sudah didaftarkan dengan SHA-256 upload key baru;
  enforcement belum diaktifkan. Validasi token perangkat/Google Play dan
  tambahkan SHA-256 Play App Signing sebelum mengaktifkannya.
- Belum dipublikasikan ke Google Play; iOS/web belum dikonfigurasi.

## Scheduling: tidak menambah job

`functions/config/deployment.json` berisi:

```json
{
  "al-jauhar-app": { "scheduledFunctions": false }
}
```

Manifest Al-Jauhar mengekspor fungsi inti tetapi **nol scheduler**. Tiga
scheduler project lama tetap memakai perilaku semula. Tidak ada reminder
otomatis, pengumuman alpha Senin, maupun cleanup foto berkala di Al-Jauhar
sampai strategi scheduling disepakati. Cloud Tasks worker bukan Cloud Scheduler.
Jangan ubah flag menjadi `true` sebelum menyepakati biaya/jadwal lintas project.

## Admin dan signing lokal

NIS admin pertama: `admin`. Email internal: `admin@aljauhar.app`.
Password acak berada di `functions/al-jauhar-admin.local`; sengaja tidak
dicantumkan dalam dokumentasi/log. File ini diabaikan Git dan upload Functions.

Signing Al-Jauhar berbeda dari lembaga lain:

- `android/app/al-jauhar-upload.jks`
- `android/key.al_jauhar.properties`
- alias `al-jauhar-upload`
- SHA-1: `BF:B8:F6:6A:23:21:AB:89:16:A3:12:02:58:53:09:31:BB:E7:04:0B`
- SHA-256: `DC:27:E6:24:2B:F4:63:61:4B:D5:42:7A:85:D2:4F:5F:4F:89:25:25:31:64:2A:6D:28:15:27:4F:11:08:C9:D8`

Kedua fingerprint sudah didaftarkan ke Firebase Android app. Backup signing,
password admin, dan `.env.al-jauhar-app` secara aman; semuanya tidak masuk Git.
`tool/create_al_jauhar_signing.cjs` hanya untuk pembuatan pertama dan menolak
menimpa signing yang sudah ada. Jangan membuat ulang key setelah aplikasi
didistribusikan.

## Build dan pemeriksaan

```powershell
dart run tool/validate_flavors.dart
flutter analyze
flutter test
flutter test test/al_jauhar_flavor_test.dart --dart-define=APP_FLAVOR=al_jauhar
flutter build apk --release --flavor al_jauhar --target lib/main_al_jauhar.dart --dart-define=APP_FLAVOR=al_jauhar
```

Jalankan perintah Flutter berurutan. Untuk build release awal setelah test/debug,
jangan memakai `--no-pub`: metadata plugin perlu diregenerasi agar plugin
dev-only seperti `flutter_native_splash` tidak tersisa pada registrant release.

APK: `build/app/outputs/flutter-apk/app-al_jauhar-release.apk`.
Untuk AAB Google Play, ganti `apk` dengan `appbundle`. CI otomatis menemukan
flavor baru. Setup GitHub Environment/signing/publikasi Play masih langkah
rilis terpisah; bukan bagian provisioning Firebase.

## Deploy ulang

Pastikan file `functions/.env.al-jauhar-app` tersedia dan flag scheduling dalam
JSON di atas tetap `false`:

```powershell
firebase deploy --only firestore,storage,functions --project al-jauhar-app
```

File env mengikuti `functions/.env.example` dengan identitas Al-Jauhar dan
Wablas tetap nonaktif. Jangan salin `.env.khoirun-app` secara keseluruhan karena
mengandung tujuan WhatsApp lembaga lama. Jangan mengaktifkan endpoint legacy.

## Migrasi data dari web lama (selesai 19 November 2026)

Data web lama (MySQL `lttm2936_jauhar` di Rumahweb, host `103.247.11.222`)
sudah dipindahkan ke Firestore `al-jauhar-app`. Endpoint migrasi sudah
**dihapus** dari project (`legacyHttpFunctions: false`, flag env `false`);
jangan mengaktifkannya lagi kecuali ada migrasi ulang yang disepakati.

### Hasil

| Data | Sumber web | Firestore | Catatan |
|---|---|---|---|
| Santri | `santris` (107) | 107 akun Auth + `users` + `santri_profiles` | login `<nis>@aljauhar.app`, password tanggal lahir `YYYYMMDD` |
| Asatidz | `users` role 1 (11) | 11 akun Auth + `users` + `asatidz_profiles` | NIS = `users.username` (01001–01011), password `Jauhar123` |
| Pembayaran | `payments` status 1, April 2026 dst. (761) | 761 `payments` | Rp200.000 per bulan; tidak ada santri gratis (`status_spp=2`) |
| Penilaian | `nilais` April 2026 dst. (557) | 557 `monthly_reports` | seluruhnya tertaut ke `asatidz_id` |

Akun web role 0 (admin `Aljauhar`/`Fahmi`, `x`, dan dua akun uji) tidak
diimpor. Dry-run ulang setelah apply menunjukkan 0 data baru pada semua langkah.

Keputusan data:

- **Password asatidz** per lembaga lewat `ASATIDZ_INITIAL_PASSWORD` di
  `.env.al-jauhar-app` (`Jauhar123`); berlaku juga untuk tombol Tambah
  Asatidz di aplikasi. Project lain tetap default `Khoirun123`.
- **Tanggal masuk**: 66 santri tidak memiliki `created_at` di web. Agar tetap
  dihitung di tagihan/laporan, tanggal masuk diisi bulan aktivitas pertama
  (pembayaran/penilaian paling awal, umumnya Mei 2025). 41 santri lain memakai
  `created_at`.
- **Jenis kelamin asatidz** dari gelar (Ust → L, Ustadzah → P).
- **Kelas** disalin apa adanya: `Tahfizh` (66) dan `Tahsin` (41). Nilai ini
  belum ada di `lib/flavors/al_jauhar/curriculum.dart` (masih salinan kelas
  Khoirun); lihat bagian kurikulum di bawah.
- **Tipe kelas** kosong karena `golongan` web hanya `Putra`/`Putri` tanpa
  sesi Pagi/Sore/Malam.
- **Halaqah** tidak dibuat; atur dari aplikasi setelah sesi/jadwal tersedia.
  Pembimbing lama ada di `santris.pembimbing_id`.
- Data perlu dicek admin: NIS `129` (lahir 2025-08-03) dan `158` (lahir
  2027-02-02) kemungkinan salah input di web; password awal keduanya mengikuti
  tanggal tersebut.

### Cara menjalankan ulang (bila diperlukan)

Port MySQL 3306 server Al-Jauhar tertutup dari luar, sehingga migrasi memakai
**export JSON phpMyAdmin** (`santris.json`, `users.json`, `payments.json`,
`nilais.json`). Endpoint menerima tabel tersebut lewat POST; GET tetap membaca
MySQL langsung. Semua langkah idempoten (data yang sudah ada dilewati).

1. Set `legacyHttpFunctions: true` untuk `al-jauhar-app` di
   `functions/config/deployment.json` dan
   `LEGACY_ADMIN_HTTP_ENABLED=true` di env, lalu deploy:

   ```powershell
   firebase deploy --project al-jauhar-app --only functions:compareSantri,functions:importSantri,functions:importAsatidz,functions:importPayments,functions:importMonthlyReports
   ```

2. Dry-run, tinjau, lalu apply per langkah. Urutan wajib
   santri → asatidz → payments → reports (asatidz sebelum penilaian agar
   `asatidz_id` tertaut):

   ```powershell
   cd functions
   .scriptsunLegacyMigration.ps1 -ProjectId al-jauhar-app -Step all -TokenFromSecretManager -DataDir C:pathexport
   .scriptsunLegacyMigration.ps1 -ProjectId al-jauhar-app -Step santri -Apply -TokenFromSecretManager -DataDir C:pathexport
   ```

   Hasil JSON tersimpan di `functions/migration-output.local/al-jauhar-app/`
   (diabaikan Git, berisi data pribadi). Kolom password/token `users` dibuang
   runner sebelum dikirim.

3. Kembalikan kedua sakelar ke `false` lalu hapus endpoint:

   ```powershell
   firebase functions:delete compareSantri importSantri importAsatidz importPayments importMonthlyReports --region asia-southeast2 --project al-jauhar-app --force
   ```

Catatan token: `ADMIN_HTTP_TOKEN` Al-Jauhar (versi 1–2) tersimpan dengan CRLF
di ujung. Server kini mengabaikan spasi/baris baru di ujung token, jadi secret
tidak perlu dibuat ulang; saat membuat secret baru, gunakan nilai tanpa baris
baru.

## Ketika kelas/kurikulum final tersedia

Edit `lib/flavors/al_jauhar/curriculum.dart` dan template/config Al-Jauhar saja.
Jika urutan promosi atau milestone berubah, validasi backend
`functions/lib/graduationCurriculum.js` dan fiqih juga perlu dijadikan
konfigurasi khusus project; saat ini backend masih sama karena kurikulum
awal memang sama. Jangan mengganti konstanta bersama lalu men-deploy ke semua
lembaga. Sesuaikan tes parity awal Al-Jauhar ketika konfigurasi sengaja berbeda.

Sebelum operasional: tetapkan kurikulum/kelas, konfirmasi rekening, isi nomor
dan grup WA khusus Al-Jauhar jika ingin diaktifkan, dan sepakati scheduling.

## Hasil verifikasi 8 Oktober 2026

- Validator: ketiga flavor valid dan terisolasi.
- `flutter analyze`: tidak ada masalah; seluruh 246 tes Flutter lolos.
- Tes spesifik dengan `APP_FLAVOR=al_jauhar`: 3 lolos.
- Backend: 130 tes lolos, termasuk manifest Al-Jauhar tanpa scheduler dan
  manifest Khoirun tetap tiga scheduler.
- APK release `1.0.0+1`, package `id.or.aljauhar.tahfiz`, label Tahfiz Al-Jauhar;
  tanda tangan valid dan hanya direktori aset flavor Al-Jauhar yang terpaket.
- Login admin HTTP 200 dan akses profil Firestore melalui token pengguna
  berhasil; dashboard pembayaran menolak anonim (401), menerima admin (200).
- Tiga endpoint foto kelulusan tersedia. Provisioning dan transkripsi menerima
  autentikasi dan menolak payload kosong seperti yang diharapkan.
- Key Groq valid (HTTP 200) dan model `whisper-large-v3` tersedia. Tidak
  mengirim audio santri saat pengujian.
- Upload, baca metadata, dan hapus foto uji melalui SDK klien dengan Rules
  admin berhasil. Hanya objek uji yang dihapus; tidak ada profil yang diubah.
- Cloud Scheduler di Jakarta: Al-Jauhar **0**, Khoirunnasyien **3**, seluruh
  jadwal Khoirunnasyien tetap ENABLED. Tidak ada pesan WA/push yang dikirim.

Pengujian pada HP fisik, penerimaan push FCM, rekaman mikrofon/transkripsi
audio nyata, dan Google Play belum dilakukan. APK siap dipasang untuk uji coba.
