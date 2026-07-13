# White-label flavor dan rilis Google Play

Dokumen ini menjelaskan arsitektur white-label Android yang dipakai repo ini,
cara menambah lembaga, dan setup GitHub Actions sampai AAB masuk ke Google Play.

Referensi utama:

- [Flutter flavors untuk Android](https://docs.flutter.dev/deployment/flavors)
- [Setup Firebase untuk Flutter](https://firebase.google.com/docs/flutter/setup)
- [Firebase project aliases](https://firebase.google.com/docs/cli#project_aliases)
- [Secret Cloud Functions](https://firebase.google.com/docs/functions/config-env#secret_parameters)
- [Google Play Developer API](https://developers.google.com/android-publisher/getting_started)
- [GitHub deployment environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments)
- [Action upload Google Play](https://github.com/r0adkll/upload-google-play)

## Struktur yang dipakai

Satu lembaga mempunyai satu nama flavor. Nama harus huruf kecil dan boleh
mengandung angka atau underscore, misalnya `khoirunnasyien` atau
`pesantren_nurul_huda`.

| Kebutuhan | Lokasi |
|---|---|
| Nama aplikasi, application ID, versi default, Firebase project ID | `config/flavors/<flavor>.properties` |
| Konfigurasi Dart dan aset brand | `lib/flavors/<flavor>/app_config.dart` |
| Entry point | `lib/main_<flavor>.dart` |
| Kurikulum lembaga | `lib/flavors/<flavor>/curriculum.dart` |
| Template syahadah | `lib/flavors/<flavor>/presentation/<flavor>_syahadah_template.dart` |
| Firebase options Dart | `lib/flavors/<flavor>/firebase_options.dart` |
| Firebase Android | `android/app/src/<flavor>/google-services.json` |
| Logo dalam UI | `assets/flavors/<flavor>/images/` |
| Ikon/splash Android | `android/app/src/<flavor>/res/` |
| Product flavor Android | `android/app/build.gradle.kts` |
| Resolver Firebase background FCM | `lib/firebase_options.dart` |
| Alias deploy Functions | `.firebaserc` |

`AppConfig` hanya dikonfigurasi di composition root. Fitur memakai konfigurasi
aktif melalui dependency yang stabil. Kurikulum adalah domain lembaga; fitur
kuis hanya memiliki adapter yang mengubah cakupan hafalan menjadi
`QuizSettings`. Template syahadah dipasang melalui registry presentasi sehingga
halaman generator tidak mengimpor template lembaga tertentu.

Saat ini product flavor native yang disiapkan adalah Android karena pipeline
tujuannya Google Play. Konfigurasi Dart tetap dapat dipakai lintas platform,
tetapi bundle ID, scheme, ikon, dan Firebase native iOS harus dibuat terpisah
sebelum melakukan white-label release ke App Store.

## Menjalankan flavor saat ini

Untuk debug:

```powershell
flutter run --flavor khoirunnasyien `
  --target lib/main_khoirunnasyien.dart `
  --dart-define=APP_FLAVOR=khoirunnasyien
```

Untuk build AAB lokal:

```powershell
$env:APP_VERSION_NAME = "1.5.1"
$env:APP_VERSION_CODE = "13"
flutter build appbundle --release `
  --flavor khoirunnasyien `
  --target lib/main_khoirunnasyien.dart `
  --build-name 1.5.1 `
  --build-number 13 `
  --dart-define=APP_FLAVOR=khoirunnasyien
```

`pubspec.yaml` menetapkan `khoirunnasyien` sebagai default flavor untuk
kenyamanan development. Build CI tetap selalu eksplisit agar tidak mungkin
merilis konfigurasi lembaga yang salah.

## Menambah lembaga baru

Contoh di bawah memakai flavor `nurul_huda`, application ID
`id.or.nurulhuda.tahfiz`, dan Firebase project `nurul-huda-tahfiz`.

### 1. Buat metadata flavor

Salin `config/flavors/khoirunnasyien.properties` menjadi
`config/flavors/nurul_huda.properties`, lalu ubah:

```properties
appName=Tahfiz Nurul Huda
applicationId=id.or.nurulhuda.tahfiz
defaultVersionName=1.0.0
defaultVersionCode=1
firebaseProjectId=nurul-huda-tahfiz
dartEntryPoint=lib/main_nurul_huda.dart
```

`applicationId` tidak boleh sama dengan aplikasi lain dan tidak dapat diganti
setelah aplikasi terbit di Google Play. `versionCode` wajib selalu naik untuk
application ID yang sama. Aplikasi lain boleh memiliki urutan versionCode
sendiri.

### 2. Daftarkan product flavor Android

Di `android/app/build.gradle.kts`, muat file properties:

```kotlin
val nurulHudaFlavor = loadFlavorProperties("nurul_huda")
```

Lalu tambahkan di dalam `productFlavors`:

```kotlin
create("nurul_huda") {
    dimension = "institution"
    applicationId = nurulHudaFlavor.getProperty("applicationId")
    resValue("string", "app_name", nurulHudaFlavor.getProperty("appName"))
    versionName = System.getenv("APP_VERSION_NAME")
        ?: nurulHudaFlavor.getProperty("defaultVersionName")
    versionCode = System.getenv("APP_VERSION_CODE")?.toInt()
        ?: nurulHudaFlavor.getProperty("defaultVersionCode").toInt()
}
```

Versi dari tag CI dikirim melalui `APP_VERSION_NAME` dan
`APP_VERSION_CODE`. Nilai properties hanya fallback untuk build lokal.

### 3. Tambahkan logo Dart dan resource Android

Buat:

```text
assets/flavors/nurul_huda/images/logo.png
assets/flavors/nurul_huda/images/logo_bg.png
```

Tambahkan aset flavor di `pubspec.yaml`:

```yaml
- path: assets/flavors/nurul_huda/images/
  flavors:
    - nurul_huda
```

Untuk launcher icon, buat file bernama `launcher_icon.png` pada masing-masing
folder berikut. Resource brand sengaja tidak diletakkan di source set global;
flavor baru wajib menyediakannya agar tidak pernah memakai logo lembaga lain.

```text
android/app/src/nurul_huda/res/mipmap-mdpi/launcher_icon.png      # 48x48
android/app/src/nurul_huda/res/mipmap-hdpi/launcher_icon.png      # 72x72
android/app/src/nurul_huda/res/mipmap-xhdpi/launcher_icon.png     # 96x96
android/app/src/nurul_huda/res/mipmap-xxhdpi/launcher_icon.png    # 144x144
android/app/src/nurul_huda/res/mipmap-xxxhdpi/launcher_icon.png   # 192x192
```

Jika native splash juga berbeda, override resource dengan nama yang sama:
`splash.png` pada `drawable-mdpi` sampai `drawable-xxxhdpi`, serta
`android12splash.png` pada folder drawable yang sama. Jangan menjalankan
generator splash global tanpa mengecek diff karena konfigurasi global dapat
menimpa resource semua flavor.

### 4. Buat kurikulum lembaga

Salin file kurikulum flavor saat ini ke
`lib/flavors/nurul_huda/curriculum.dart`. Ubah `classNames`, `classTypes`,
`memorizationByClass`, dan `previousChallengeClass`.

- `classNames` menentukan daftar dan urutan kelas di seluruh aplikasi.
- `memorizationByClass` adalah cakupan kumulatif tiap kelas.
- Kelas tanpa entri hafalan tetap dapat dipakai untuk administrasi, tetapi
  tidak masuk Tantangan/leaderboard.
- `previousChallengeClass` hanya diisi jika santri boleh memilih cakupan satu
  kelas di bawahnya.

### 5. Buat template syahadah

Salin template flavor saat ini menjadi
`lib/flavors/nurul_huda/presentation/nurul_huda_syahadah_template.dart`.
Ganti nama class, layout, warna, teks, atau aset sesuai lembaga. Constructor
tetap menerima `SyahadahTemplateData` agar kompatibel dengan halaman generator.

### 6. Buat Firebase project khusus lembaga

Gunakan satu Firebase project per lembaga. Ini mengisolasi Authentication,
Firestore, Storage, Functions, FCM, serta secret akun Whisper/Groq. Memakai dua
Android app di satu Firebase project tidak mengisolasi secret Cloud Functions.

1. Buat project `nurul-huda-tahfiz` di Firebase Console.
2. Tambahkan Android app dengan package `id.or.nurulhuda.tahfiz`.
3. Unduh `google-services.json` ke
   `android/app/src/nurul_huda/google-services.json`.
4. Instal CLI jika belum ada:

   ```powershell
   dart pub global activate flutterfire_cli
   npm install -g firebase-tools
   firebase login
   ```

5. Generate opsi Dart. CLI bersifat interaktif; pastikan Android app/package
   yang dipilih adalah milik flavor baru dan output-nya spesifik flavor:

   ```powershell
   flutterfire configure `
     --project=nurul-huda-tahfiz `
     --out=lib/flavors/nurul_huda/firebase_options.dart
   ```

6. Ganti nama class hasil generate menjadi `NurulHudaFirebaseOptions` agar
   tidak bentrok dengan flavor lain.
7. Tambahkan case `nurul_huda` di resolver `lib/firebase_options.dart`. Resolver
   ini diperlukan oleh background isolate FCM.
8. Tambahkan alias project:

   ```powershell
   firebase use --add
   ```

   Pilih `nurul-huda-tahfiz` dan gunakan alias `nurul_huda`. Commit perubahan
   `.firebaserc`.

### 7. Buat AppConfig dan entry point

Buat `lib/flavors/nurul_huda/app_config.dart`:

```dart
final nurulHudaAppConfig = AppConfig(
  flavor: 'nurul_huda',
  appName: 'Tahfiz Nurul Huda',
  institutionName: 'Pondok Nurul Huda',
  logoAsset: 'assets/flavors/nurul_huda/images/logo.png',
  syahadahLogoAsset: 'assets/flavors/nurul_huda/images/logo_bg.png',
  functionsRegion: 'asia-southeast2',
  curriculum: nurulHudaCurriculum,
  firebaseOptionsProvider: () => NurulHudaFirebaseOptions.currentPlatform,
);
```

Buat `lib/main_nurul_huda.dart` dan pasang template flavor ke `bootstrap`, sama
seperti `main_khoirunnasyien.dart`.

### 8. Konfigurasi Functions dan akun Whisper/Groq

Aktifkan project yang tepat, lalu set secret. Nama secret sengaja tetap sama;
nilainya terisolasi oleh Firebase project.

```powershell
firebase use nurul_huda
firebase functions:secrets:set GROQ_API_KEY
firebase deploy --only functions
```

Masukkan API key dari akun Groq milik lembaga Nurul Huda. Key tidak pernah
ditaruh di Dart, APK, `.env`, GitHub log, atau source control. Setelah key
dirotasi, deploy ulang function `transcribeRecitation` agar revision baru
memakai secret terbaru.

Untuk domain email login santri, buat `functions/.env.nurul-huda-tahfiz` yang
tidak berisi secret:

```dotenv
AUTH_EMAIL_DOMAIN=nurulhuda.id
```

Parameter database yang berbeda juga dapat ditaruh di file project-specific
tersebut. Password database tetap harus memakai Secret Manager.

### 9. Verifikasi flavor baru sebelum CI

```powershell
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter run --flavor nurul_huda `
  --target lib/main_nurul_huda.dart `
  --dart-define=APP_FLAVOR=nurul_huda
```

Periksa nama, ikon, splash, logo login, Firebase login, FCM background, akses
Firestore/Storage, kurikulum, template syahadah, dan transkripsi. Jangan lanjut
ke Play Console bila salah satu masih menunjuk ke project lembaga lain.

## Setup Google Play dan GitHub Actions

Workflow berada di `.github/workflows/release-android.yml`. Tag yang diterima:

```text
<flavor>-v<major>.<minor>.<patch>+<versionCode>
```

Contoh:

```text
khoirunnasyien-v1.6.0+14
nurul_huda-v1.0.0+1
```

### 1. Siapkan upload key

Untuk aplikasi yang sudah ada, wajib gunakan upload key lama. Jangan membuat
key baru kecuali menjalani proses reset upload key di Play Console.

Untuk aplikasi baru:

```powershell
keytool -genkeypair -v `
  -keystore upload-keystore.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload
```

Simpan ke password manager dan backup offline. File `.jks` tidak boleh masuk
Git; `.gitignore` sudah mengabaikannya.

Ubah ke Base64 untuk GitHub Secret pada Windows:

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("C:\path\upload-keystore.jks")
) | Set-Clipboard
```

### 2. Buat aplikasi di Play Console

1. Buat app baru di Google Play Console.
2. Pastikan package name sama persis dengan `applicationId` flavor.
3. Isi app content, data safety, privacy policy, store listing, target audience,
   dan deklarasi lain yang diwajibkan Play Console.
4. Aktifkan Play App Signing.
5. Build AAB flavor secara lokal dan upload release pertama secara manual ke
   Internal testing. Google Play/action membutuhkan package yang sudah dikenal;
   action upload juga mendokumentasikan bahwa upload manual pertama diperlukan.
6. Selesaikan semua blocking task pada dashboard Play Console.

Mulai otomatisasi dari track `internal`. Promosikan ke production setelah alur
signing, service account, tester, dan update aplikasi terbukti benar.

### 3. Buat service account Google Play

1. Buka Google Cloud Console dan pilih/buat Cloud project untuk CI release.
2. Enable **Google Play Android Developer API**.
3. Buat service account, lalu buat JSON key.
4. Di Play Console buka **Users and permissions** dan invite email service
   account tersebut.
5. Beri akses hanya ke aplikasi terkait dan permission minimum untuk membuat
   release pada track yang dipakai. Hindari permission finansial/admin bila
   tidak dibutuhkan.

Satu service account boleh dipakai untuk beberapa app jika permission dibatasi
dengan benar. Untuk isolasi maksimum, gunakan service account per lembaga.

### 4. Buat GitHub Environment per flavor

Di repo GitHub buka **Settings → Environments → New environment**. Nama
environment harus sama persis dengan flavor, misalnya `khoirunnasyien`.

Tambahkan lima environment secrets:

| Secret | Isi |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Seluruh file upload keystore dalam Base64 satu baris |
| `ANDROID_KEYSTORE_PASSWORD` | Password keystore |
| `ANDROID_KEY_ALIAS` | Alias key, misalnya `upload` |
| `ANDROID_KEY_PASSWORD` | Password key |
| `PLAY_SERVICE_ACCOUNT_JSON` | Seluruh isi JSON key service account |

Tambahkan environment variables opsional:

| Variable | Default | Nilai umum |
|---|---|---|
| `PLAY_TRACK` | `internal` | `internal`, `alpha`, `beta`, `production` |
| `PLAY_STATUS` | `completed` | `completed` atau `draft` |

Untuk production, aktifkan **Required reviewers**, larang self-review bila
sesuai proses tim, dan batasi deployment tag ke `<flavor>-v*`. Environment
secrets baru diberikan ke job setelah protection rule lolos.

### 5. Jalankan release dengan tag

Pastikan semua perubahan sudah ada di branch yang akan ditag, lalu:

```powershell
git tag khoirunnasyien-v1.6.0+14
git push origin khoirunnasyien-v1.6.0+14
```

Workflow akan:

1. memvalidasi format tag dan keberadaan flavor;
2. membaca application ID dan entry point dari properties flavor;
3. menjalankan `flutter pub get`, analyzer, dan seluruh test;
4. memulihkan upload key hanya di runner sementara;
5. build AAB flavor dengan version name/code dari tag;
6. menyimpan AAB sebagai artifact selama 30 hari;
7. membuat release di track Google Play yang dikonfigurasi.

Jika salah, jangan memakai ulang versionCode yang sudah pernah diterima Google
Play. Perbaiki kode, naikkan versionCode, buat tag baru, lalu push lagi.

### 6. Jalankan manual tanpa tag

Buka **Actions → Release Android flavor to Google Play → Run workflow**. Isi
flavor, version name, version code, track, dan status. Jalur manual cocok untuk
uji awal, tetapi release reguler sebaiknya memakai tag agar versi dapat diaudit
dari Git history.

### 7. Memindahkan dari internal ke production

Ada dua pola aman:

- Promosikan release yang sudah diuji dari Play Console; ini tidak build ulang.
- Jalankan workflow manual ke `production` menggunakan versionCode baru.

Google Play tetap dapat menahan production release untuk review, kebijakan,
atau managed publishing. “Completed” berarti workflow mengirim release ke
track, bukan menjamin aplikasi langsung terlihat publik tanpa proses Google.

## Catatan kompatibilitas Kotlin plugin

Project aplikasi utama sudah tidak menerapkan Kotlin Gradle Plugin: entry point
Android yang hanya mewarisi `FlutterActivity` menggunakan Java. Ini mengikuti
[panduan migrasi Built-in Kotlin Flutter](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers).

Flutter 3.44 masih memberi peringatan bahwa beberapa plugin pihak ketiga
(`cloud_functions`, `firebase_storage`, `device_info_plus`,
`flutter_image_compress`, `in_app_update`, `package_info_plus`, `record`, dan
`share_plus`) menerapkan Kotlin Gradle Plugin pada modul plugin mereka sendiri.
AAB saat ini berhasil dibangun; sisa migrasi tersebut harus datang dari versi
plugin upstream. Saat menaikkan Flutter/AGP, jalankan `flutter pub outdated`,
cek changelog paket, upgrade bertahap, lalu ulangi analyzer, test, dan build AAB.
Jangan memaksa AGP 9 sebelum semua plugin kritis menyatakan kompatibel.

## Checklist sebelum menambah tag

- Flavor dan application ID benar.
- VersionCode lebih besar daripada release terakhir app tersebut.
- Firebase project, `google-services.json`, dan Dart Firebase options cocok.
- Secret `GROQ_API_KEY` diset di Firebase project lembaga yang benar.
- Upload key sama dengan yang terdaftar di Play Console.
- GitHub Environment sama dengan nama flavor dan semua secrets tersedia.
- Internal test berhasil login, menerima FCM, upload foto, generate syahadah,
  memuat kurikulum, dan transkripsi memakai akun lembaga yang tepat.
- Store listing serta deklarasi kebijakan Play Console sudah lengkap.
