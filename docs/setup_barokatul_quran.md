# Setup aplikasi Barokatul Qur'an (Android)

Dokumen ini adalah runbook untuk membuat aplikasi lembaga kedua tanpa
mencampur data, credential, branding, atau signing Khoirunnasyien. Flavor yang
dipakai adalah `barokatul_quran`.

## Status teknis

Fondasi repository sudah mendukung:

- product flavor Android yang ditemukan otomatis dari
  `config/flavors/*.properties`;
- satu Firebase project, Authentication, Firestore, Storage, Functions, FCM,
  dan secret terpisah untuk setiap lembaga;
- signing release per flavor;
- provisioning santri/asatidz hanya melalui Cloud Functions oleh admin;
- password awal staff dapat diatur per lembaga, password santri memakai tanggal
  lahir dalam urutan `YYYYMMDD`, tanpa pemaksaan ganti password setelah login;
- Firestore/Storage Rules yang menolak akses lintas role;
- validator yang menggagalkan build bila project ID, package, app ID Firebase,
  aset, alias, atau entry point tercampur;
- CI yang menguji semua flavor.

Runbook ini khusus Android/Google Play. iOS memerlukan target/scheme, bundle ID,
GoogleService-Info.plist, ikon, dan signing Apple tersendiri.

## Data yang harus diputuskan

Isi tabel ini sebelum membuat file. Jangan memakai nilai Khoirunnasyien.

| Data | Contoh sementara | Nilai final |
|---|---|---|
| Nama flavor | `barokatul_quran` | tetap |
| Nama aplikasi | `Barokatul Qur'an` | |
| Android application ID | `id.or.barokatulquran.tahfiz` | |
| Firebase project ID | `barokatul-quran-tahfiz` | |
| Domain login internal | `barokatulquran.app` | |
| Bank pembayaran | `BSI` | |
| Nomor rekening | — | |
| Nama pemilik rekening | — | |
| Nomor WhatsApp admin format 62 | — | |
| Daftar dan urutan kelas | — | |
| Tipe kelas | `Pagi`, `Sore`, `Malam` atau lainnya | |
| Cakupan hafalan setiap kelas | — | |
| Warna utama/sekunder | — | |
| Logo transparan | PNG | |
| Akun Groq untuk transkripsi | API key | |
| Wablas | aktif/tidak | |

`applicationId` adalah identitas permanen di Google Play. Pastikan nama itu
dimiliki lembaga dan belum pernah dipakai. Firebase project ID harus unik secara
global dan tidak dapat diganti setelah project dibuat.

## 1. Buat Firebase project baru

1. Buka Firebase Console dan buat project baru menggunakan project ID final.
2. Hubungkan billing. Cloud Functions generasi kedua dan Cloud Scheduler
   memerlukan project billing-enabled.
3. Buat Firestore database. Pilih lokasi sedekat mungkin dengan Functions
   `asia-southeast2` dan putuskan dengan hati-hati karena lokasi database tidak
   dapat dipindah begitu saja.
4. Aktifkan Authentication, lalu aktifkan provider **Email/Password**.
5. Aktifkan Storage.
6. Tambahkan Android app dengan package name yang sama persis dengan
   `applicationId`.
7. Unduh `google-services.json`. Jangan menaruhnya di source set `main`.
8. Cloud Messaging tersedia melalui project Firebase yang sama.

Gunakan satu Firebase project khusus Barokatul Qur'an. Menambahkan Android app
kedua ke project Khoirunnasyien tidak mengisolasi data maupun Functions.

### Siapkan App Check

Di Firebase Console buka **App Check**, daftarkan Android app Barokatul Qur'an,
dan pilih provider **Play Integrity**. Aplikasi sudah mengaktifkan:

- debug provider pada build debug;
- Play Integrity pada build release.

Saat menjalankan build debug, salin debug token yang muncul di log lalu
daftarkan melalui **App Check → Apps → Manage debug tokens**. Mulai dalam mode
monitoring; jangan menyalakan enforcement sebelum debug build dan AAB dari
Internal testing terbukti mengirim request valid.

## 2. Siapkan CLI dan pilih project secara eksplisit

```powershell
firebase login
dart pub global activate flutterfire_cli

$barokatulProjectId = "barokatul-quran-tahfiz"
firebase projects:list
firebase use --add
```

Pada `firebase use --add`, pilih project Barokatul Qur'an dan buat alias
`barokatul_quran`. Pastikan `.firebaserc` akhirnya mempunyai pemetaan:

```json
"barokatul_quran": "barokatul-quran-tahfiz"
```

Untuk perintah deploy tetap sertakan `--project $barokatulProjectId`. Alias
berguna untuk validasi, tetapi flag eksplisit mengurangi risiko salah project.

## 3. Buat metadata flavor

Buat `config/flavors/barokatul_quran.properties`:

```properties
appName=Barokatul Qur'an
institutionName=Barokatul Qur'an
applicationId=id.or.barokatulquran.tahfiz
defaultVersionName=1.0.0
defaultVersionCode=1
firebaseProjectId=barokatul-quran-tahfiz
dartEntryPoint=lib/main_barokatul_quran.dart
authEmailDomain=barokatulquran.app
paymentBankName=NAMA_BANK
paymentAccountNumber=NOMOR_REKENING
paymentAccountHolder=NAMA_PEMILIK
```

Tidak perlu mengedit `android/app/build.gradle.kts`. Gradle membaca flavor baru
secara otomatis dari file properties ini.

## 4. Pasang konfigurasi Firebase flavor

Simpan file hasil unduhan Firebase di:

```text
android/app/src/barokatul_quran/google-services.json
```

Generate Firebase options hanya untuk Android dan arahkan output ke flavor:

```powershell
flutterfire configure `
  --project=$barokatulProjectId `
  --platforms=android `
  --android-package-name=id.or.barokatulquran.tahfiz `
  --out=lib/flavors/barokatul_quran/firebase_options.dart
```

Periksa diff setelah perintah ini. File Firebase milik Khoirunnasyien tidak
boleh berubah. Di file hasil generate, ganti nama class
`DefaultFirebaseOptions` menjadi `BarokatulQuranFirebaseOptions`.

Tambahkan resolver di `lib/firebase_options.dart`:

```dart
import 'package:khoirunnasyien/flavors/barokatul_quran/firebase_options.dart';

// Di dalam switch:
'barokatul_quran' => BarokatulQuranFirebaseOptions.currentPlatform,
```

Resolver ini diperlukan ketika FCM menjalankan isolate background.

## 5. Buat konfigurasi Dart dan kurikulum

Buat folder:

```text
lib/flavors/barokatul_quran/
lib/flavors/barokatul_quran/presentation/
```

Salin struktur `curriculum.dart` flavor lama, lalu isi berdasarkan kurikulum
Barokatul Qur'an. Jangan sekadar mempertahankan nama kelas lembaga lama.

Hal yang wajib diputuskan:

- `classNames`: nama dan urutan kelas;
- `classTypes`: sesi/tipe kelas;
- `fiqihClassNames` dan kelas pertama yang mengikuti fiqih;
- `memorizationByClass`: juz dan surah tambahan per kelas;
- `previousChallengeClass`: cakupan kelas sebelumnya yang boleh dipilih.

Buat `app_config.dart`:

```dart
final barokatulQuranAppConfig = AppConfig(
  flavor: 'barokatul_quran',
  appName: "Barokatul Qur'an",
  institutionName: "Barokatul Qur'an",
  logoAsset: 'assets/flavors/barokatul_quran/images/logo.png',
  syahadahLogoAsset:
      'assets/flavors/barokatul_quran/images/logo_bg.png',
  functionsRegion: 'asia-southeast2',
  authEmailDomain: 'barokatulquran.app',
  payment: const InstitutionPaymentConfig(
    bankName: 'NAMA_BANK',
    accountNumber: 'NOMOR_REKENING',
    accountHolder: 'NAMA_PEMILIK',
  ),
  curriculum: barokatulQuranCurriculum,
  firebaseOptionsProvider:
      () => BarokatulQuranFirebaseOptions.currentPlatform,
);
```

Nilai identitas dan pembayaran harus sama dengan file properties; validator
akan menolak perbedaan.

## 6. Siapkan logo, ikon, dan splash

Buat:

```text
assets/flavors/barokatul_quran/images/logo.png
assets/flavors/barokatul_quran/images/logo_bg.png
```

Rekomendasi sumber:

- `logo.png`: PNG transparan, sumber minimal 1024×1024;
- `logo_bg.png`: logo/dekorasi resolusi tinggi untuk syahadah;
- hindari teks kecil pada launcher icon;
- simpan file master desain di luar folder hasil export.

Tambahkan aset ke `pubspec.yaml`:

```yaml
- path: assets/flavors/barokatul_quran/images/
  flavors:
    - barokatul_quran
```

Buat launcher icon:

```text
android/app/src/barokatul_quran/res/mipmap-mdpi/launcher_icon.png       48×48
android/app/src/barokatul_quran/res/mipmap-hdpi/launcher_icon.png       72×72
android/app/src/barokatul_quran/res/mipmap-xhdpi/launcher_icon.png      96×96
android/app/src/barokatul_quran/res/mipmap-xxhdpi/launcher_icon.png    144×144
android/app/src/barokatul_quran/res/mipmap-xxxhdpi/launcher_icon.png   192×192
```

Untuk splash, sediakan file `splash.png` serta `android12splash.png` di folder
drawable tiap density. Gunakan nama file yang sama karena layout native sudah
memilih resource berdasarkan flavor.

## 7. Desain dan implementasi syahadah

Output poster aplikasi berukuran tetap **1080×1350 px (rasio 4:5)**. Desain
referensi dapat dibuat di Figma/Canva, tetapi hasil final harus diterjemahkan
menjadi widget Flutter agar nama, NIS, foto, kelas, hafalan, dan tanggal tetap
dinamis.

Siapkan keputusan desain berikut:

- warna background, aksen, dan kontras teks;
- posisi dan safe area logo;
- area foto santri dan fallback bila foto gagal dimuat;
- area nama panjang dan NIS;
- kalimat untuk kelulusan Tahsin;
- kalimat untuk kelulusan Hafalan;
- format bulan/tahun;
- kutipan/doa yang telah disetujui lembaga;
- jenis font dan lisensi penggunaannya.

Buat:

```text
lib/flavors/barokatul_quran/presentation/
  barokatul_quran_syahadah_template.dart
```

Class harus menerima `SyahadahTemplateData`. Data yang tersedia:

- `displayName`
- `nis`
- `hafalan`
- `photoUrl`
- `kelas`
- `date`

Uji sekurang-kurangnya empat sampel: nama pendek, nama sangat panjang, Tahsin,
dan Hafalan; masing-masing dengan foto valid serta foto gagal. Pastikan teks
tidak terpotong pada hasil export 1080×1350.

## 8. Buat entry point

Buat `lib/main_barokatul_quran.dart`:

```dart
import 'package:khoirunnasyien/bootstrap.dart';
import 'package:khoirunnasyien/flavors/barokatul_quran/app_config.dart';
import 'package:khoirunnasyien/flavors/barokatul_quran/presentation/barokatul_quran_syahadah_template.dart';

Future<void> main() => bootstrap(
  config: barokatulQuranAppConfig,
  syahadahTemplateBuilder: (data) =>
      BarokatulQuranSyahadahTemplate(data: data),
);
```

Nama package Dart tetap `khoirunnasyien` karena itu identitas source package,
bukan nama aplikasi yang terlihat pengguna dan bukan Firebase project.

## 9. Konfigurasi Functions

Salin `functions/.env.example` menjadi:

```text
functions/.env.barokatul-quran-tahfiz
```

Isi nilai non-secret:

```dotenv
AUTH_EMAIL_DOMAIN=barokatulquran.app
INSTITUTION_NAME="Barokatul Qur'an"
PAYMENT_BANK_NAME=NAMA_BANK
PAYMENT_ACCOUNT_NUMBER=NOMOR_REKENING
PAYMENT_ACCOUNT_HOLDER=NAMA_PEMILIK
STAFF_INITIAL_PASSWORD=Barokatul123
APP_CHECK_ENFORCED=false

WABLAS_ENABLED=false
WABLAS_BASE_URL=https://disabled.invalid
WHATSAPP_ADMIN_PHONE=

DEPLOY_LEGACY_HTTP_FUNCTIONS=false
LEGACY_ADMIN_HTTP_ENABLED=false
```

Jangan menyalin host/password database Khoirunnasyien. Grup endpoint MySQL lama
tidak diekspor saat `DEPLOY_LEGACY_HTTP_FUNCTIONS=false`.

Set key transkripsi melalui Secret Manager:

```powershell
firebase functions:secrets:set GROQ_API_KEY `
  --project $barokatulProjectId
```

Jika Wablas akan dipakai, ubah `WABLAS_ENABLED=true`, isi base URL dan nomor
admin, lalu set dua secret sebelum deploy:

```powershell
firebase functions:secrets:set WABLAS_TOKEN `
  --project $barokatulProjectId
firebase functions:secrets:set WABLAS_SECRET_KEY `
  --project $barokatulProjectId
```

File `.env.<project-id>` dan seluruh secret tidak boleh di-commit.

Setelah debug build dan AAB Internal testing tervalidasi di metrik App Check:

1. ubah `APP_CHECK_ENFORCED=true`;
2. deploy ulang Functions;
3. aktifkan enforcement Firestore dan Storage dari Firebase Console;
4. uji lagi login, provisioning, foto, kuis, dan transkripsi.

Jangan aktifkan enforcement saat token debug/Play Integrity masih ditolak
karena seluruh callable, Firestore, dan Storage aplikasi akan ikut ditolak.

## 10. Deploy backend dengan urutan aman

Validasi lokal lebih dahulu:

```powershell
dart run tool/validate_flavors.dart
flutter analyze
flutter test

Push-Location functions
npm ci
npm audit --omit=dev
npm test
$env:PATH = "C:\Program Files\Android\Android Studio\jbr\bin;$env:PATH"
npm run test:rules
Pop-Location
```

Deploy Rules dan indexes sebelum aplikasi dipakai:

```powershell
firebase deploy `
  --project $barokatulProjectId `
  --only firestore:rules,firestore:indexes,storage

firebase deploy `
  --project $barokatulProjectId `
  --only functions
```

Setelah deploy, cek daftar Functions. Endpoint import/rekonsiliasi MySQL dan
`guestLookup` tidak boleh ada pada project Barokatul Qur'an.

## 11. Buat admin pertama

Admin pertama dibuat sekali melalui Firebase Console; tidak ada endpoint
bootstrap publik.

1. Di Authentication, buat user:
   - email: `admin@barokatulquran.app`;
   - password: `Barokatul123`;
   - salin UID.
2. Di Firestore, buat dokumen `users/{UID}` dengan ID dokumen sama persis
   seperti UID Authentication.
3. Isi:

```text
uid                  string     UID Authentication
name                 string     Nama Admin
nis                  string     admin
email                string     admin@barokatulquran.app
phone                string     nomor admin
role                 string     admin
is_admin             boolean    true
created_at           timestamp  waktu saat ini
```

Gunakan password awal `Barokatul123` untuk admin pertama. Login aplikasi
menggunakan NIS `admin`. Setelah admin masuk, pembuatan santri dan asatidz
dilakukan dari aplikasi. Callable server akan membuat Auth + profil secara
konsisten. Asatidz Barokatul memakai password `Barokatul123`, sedangkan santri
memakai tanggal lahir yang dibalik menjadi `YYYYMMDD`. Contoh: tanggal lahir
`09/03/2012` menghasilkan password `20120309`. Aplikasi tidak memaksa pengguna
mengganti password setelah login.

Jangan membuat akun santri/asatidz dengan menulis dokumen Firestore manual.

## 12. Signing release Barokatul Qur'an

Buat upload key khusus aplikasi ini:

```powershell
keytool -genkeypair -v `
  -keystore android/app/barokatul-quran-upload.jks `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias barokatul-upload
```

Buat file lokal `android/key.barokatul_quran.properties`:

```properties
storePassword=PASSWORD_KEYSTORE
keyPassword=PASSWORD_KEY
keyAlias=barokatul-upload
storeFile=barokatul-quran-upload.jks
```

Keystore dan file properties sudah di-ignore Git. Backup keystore dan password
di dua lokasi aman. Kehilangan upload key menghambat proses update aplikasi.

## 13. Run, build, dan QA

```powershell
flutter run `
  --flavor barokatul_quran `
  --target lib/main_barokatul_quran.dart `
  --dart-define=APP_FLAVOR=barokatul_quran
```

Build release:

```powershell
flutter build appbundle `
  --release `
  --flavor barokatul_quran `
  --target lib/main_barokatul_quran.dart `
  --build-name 1.0.0 `
  --build-number 1 `
  --dart-define=APP_FLAVOR=barokatul_quran
```

Checklist wajib:

- nama app, icon, splash, logo, rekening, dan teks WhatsApp hanya Barokatul;
- login admin menuju Firebase Barokatul;
- admin dapat membuat santri dan asatidz;
- admin/asatidz memakai password `Barokatul123`;
- santri lahir `09/03/2012` memakai password `20120309`;
- pengguna langsung masuk Home setelah login berhasil;
- santri tidak dapat membaca profil/pembayaran santri lain;
- asatidz dapat mengisi absensi/setoran tetapi tidak mengubah data master;
- upload foto mengikuti role;
- FCM foreground/background masuk ke project yang benar;
- App Check debug dan Play Integrity tercatat valid sebelum enforcement;
- transkripsi bekerja dengan secret project Barokatul;
- syahadah benar pada seluruh sampel desain;
- AAB memiliki application ID dan signing Barokatul;
- tidak ada data yang muncul di Firebase Khoirunnasyien selama pengujian.

## 14. Google Play dan CI

1. Buat aplikasi Google Play baru dengan package name final.
2. Aktifkan Play App Signing.
3. Upload AAB pertama secara manual ke Internal testing.
4. Buat GitHub Environment bernama `barokatul_quran`.
5. Isi environment secrets:
   - `ANDROID_KEYSTORE_BASE64`
   - `ANDROID_KEYSTORE_PASSWORD`
   - `ANDROID_KEY_ALIAS`
   - `ANDROID_KEY_PASSWORD`
   - `PLAY_SERVICE_ACCOUNT_JSON`
6. Setelah internal test lolos, release berikutnya dapat memakai tag:

```text
barokatul_quran-v1.0.1+2
```

Sebelum produksi, lengkapi privacy policy, Data safety, target audience,
permission mikrofon/notifikasi, screenshot store, dan pengujian tertutup yang
diwajibkan akun Play Console.

## Kriteria selesai

Setup dinyatakan selesai bila validator, analyzer, Flutter test, Functions
test, Rules test, dan build AAB semuanya hijau; lalu checklist QA di atas telah
dicoba memakai perangkat nyata dan Firebase Console project Barokatul Qur'an.
