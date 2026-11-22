# Arsitektur white-label dan rilis Android

Repository ini menghasilkan satu aplikasi Android terpisah untuk setiap
lembaga. Satu flavor harus memiliki application ID, Firebase project, branding,
konfigurasi pembayaran, signing key, dan Google Play app sendiri.

Runbook konkret untuk lembaga kedua:
[`setup_barokatul_quran.md`](setup_barokatul_quran.md).
Al-Jauhar: [`setup_al_jauhar.md`](setup_al_jauhar.md).

## Struktur satu flavor

| Kebutuhan | Lokasi |
|---|---|
| Metadata native dan integritas | `config/flavors/<flavor>.properties` |
| Konfigurasi aplikasi | `lib/flavors/<flavor>/app_config.dart` |
| Kurikulum | `lib/flavors/<flavor>/curriculum.dart` |
| Firebase options | `lib/flavors/<flavor>/firebase_options.dart` |
| Template syahadah | `lib/flavors/<flavor>/presentation/<flavor>_syahadah_template.dart` |
| Entry point | `lib/main_<flavor>.dart` |
| Aset UI | `assets/flavors/<flavor>/images/` |
| Firebase Android | `android/app/src/<flavor>/google-services.json` |
| Icon/splash | `android/app/src/<flavor>/res/` |
| Signing lokal | `android/key.<flavor>.properties` |
| Firebase alias | `.firebaserc` |

Gradle menemukan seluruh file `config/flavors/*.properties` secara otomatis.
Menambah lembaga tidak memerlukan edit manual pada `productFlavors`.

Properti wajib:

```properties
appName=Nama App
institutionName=Nama Lembaga
applicationId=id.or.lembaga.tahfiz
defaultVersionName=1.0.0
defaultVersionCode=1
firebaseProjectId=project-firebase
functionsRegion=asia-southeast2
dartEntryPoint=lib/main_nama_flavor.dart
authEmailDomain=lembaga.app
paymentBankName=Nama Bank
paymentAccountNumber=0000000000
paymentAccountHolder=Nama Pemilik
```

## Isolasi yang diberlakukan

`tool/validate_flavors.dart` menolak:

- application ID yang dipakai dua flavor;
- Firebase project yang dipakai dua lembaga;
- project/package/app ID yang tidak cocok antara properties,
  `google-services.json`, dan Firebase options;
- entry point, app config, kurikulum, syahadah, logo, atau launcher icon yang
  belum tersedia;
- nilai identitas/pembayaran Dart yang berbeda dari metadata flavor;
- mapping aset, resolver background FCM, atau alias Firebase yang hilang.

Cloud Functions memisahkan konfigurasi per Firebase project. Endpoint MySQL dan
guest web lama tidak dideploy secara default. Akun hanya dibuat server-side oleh
admin. Password awal santri memakai tanggal lahir dalam urutan `YYYYMMDD`,
sedangkan password asatidz dapat diatur per lembaga. Aplikasi tidak memaksa
pengguna mengganti password setelah login.
Build debug memakai App Check debug provider dan build release memakai Play
Integrity; enforcement diaktifkan per project setelah token tervalidasi.

Firestore dan Storage memakai default-deny Rules. Rules serta seluruh flavor
dikompilasi di CI.

## Warna brand per flavor

Warna brand dipilih saat compile dari `--dart-define=APP_FLAVOR` di
`lib/core/theme/app_colors.dart` (`kGreenBrand`), sehingga tetap `const`.
Khoirunnasyien dan Barokatul memakai biru; Al-Jauhar memakai hijau yang
luminansnya dicocokkan dengan biru (kontras teks sama).

- Pakai `AppColors.brand`, `AppColors.brandLight`, `AppColors.brandDeep`,
  `AppColors.primary`, dan `AppColors.secondary`. Jangan menulis
  `Colors.blue`, `Colors.lightBlue`, `Colors.indigo`, atau hex biru langsung.
- Warna hex khusus layar ditulis `kGreenBrand ? hijau : biru`.
- Abu "slate" (`#64748B`, `#334155`, `#475569`) dianggap netral.
- Tanpa `APP_FLAVOR` aplikasi berhenti di native splash (dicek bootstrap);
  konfigurasi run di `.vscode/launch.json` sudah menyertakannya.

## Perintah validasi

```powershell
dart run tool/validate_flavors.dart
flutter analyze
flutter test

Push-Location functions
npm ci
npm audit --omit=dev
npm test
npm run test:rules
Pop-Location
```

Run debug:

```powershell
flutter run `
  --flavor NAMA_FLAVOR `
  --target lib/main_NAMA_FLAVOR.dart `
  --dart-define=APP_FLAVOR=NAMA_FLAVOR
```

Build release:

```powershell
flutter build appbundle `
  --release `
  --flavor NAMA_FLAVOR `
  --target lib/main_NAMA_FLAVOR.dart `
  --build-name 1.0.0 `
  --build-number 1 `
  --dart-define=APP_FLAVOR=NAMA_FLAVOR
```

Build release gagal bila `android/key.<flavor>.properties` tidak ada. Untuk
flavor lama Khoirunnasyien saja tersedia fallback sementara ke
`android/key.properties`.

## Signing dan GitHub Environment

Setiap flavor memakai GitHub Environment dengan nama sama persis. Secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `PLAY_SERVICE_ACCOUNT_JSON`

Environment variables opsional:

- `PLAY_TRACK`, default `internal`;
- `PLAY_STATUS`, default `completed`.

Workflow release menerima tag:

```text
<flavor>-v<major>.<minor>.<patch>+<versionCode>
```

Contoh:

```text
barokatul_quran-v1.0.1+2
```

Workflow memvalidasi flavor, menjalankan analyzer/test/audit/Rules test,
memulihkan keystore hanya pada runner sementara, build AAB, menyimpan artifact,
dan mengirimnya ke track Google Play.

## Google Play

1. Buat Play app dengan package yang sama persis dengan `applicationId`.
2. Aktifkan Play App Signing.
3. Upload AAB pertama secara manual ke Internal testing.
4. Hubungkan service account dengan permission minimum hanya ke app/track yang
   diperlukan.
5. Aktifkan required reviewer untuk environment production.
6. Naikkan `versionCode` pada setiap upload; kode yang sudah diterima Play
   tidak dapat digunakan ulang.

## Batas platform

White-label native saat ini siap untuk Android. Konfigurasi Dart dapat berjalan
lintas platform, tetapi iOS belum mempunyai scheme, bundle ID per flavor,
GoogleService-Info.plist, ikon, maupun signing per lembaga. Jangan menganggap
build iOS sudah terisolasi sebelum bagian native tersebut dibuat dan diuji.
