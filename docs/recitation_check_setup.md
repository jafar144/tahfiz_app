# Uji Bacaan Qur'an — Fase 0 (Setup)

Fitur pendeteksi kesalahan bacaan: santri membaca rentang ayat, audio
ditranskripsi (Groq Whisper), lalu dicocokkan dengan teks mushaf. Kata yang
salah / kelewat / tambahan ditandai.

## Arsitektur

```
[App Flutter]
  rekam audio (record) ──base64──▶ [Cloud Function transcribeRecitation]
                                       │  proxy ke Groq Whisper (secret key)
                                       ▼
                                   teks Arab (ASR)
  ◀──────────────────────────────────┘
  normalisasi + alignment (Needleman-Wunsch) di Dart, offline
  bandingkan dgn assets/quran/quran.json
  ▶ hasil: akurasi %, kata benar/salah/kelewat/tambahan
```

Kunci: teks Al-Qur'an sudah pasti, jadi tidak perlu model akustik — cukup
transkripsi lalu align ke teks yang seharusnya. Selisihnya = kesalahan.

## Langkah setup (sekali saja)

### 1. Backend — Groq + Cloud Function

1. Buat API key gratis di <https://console.groq.com/keys>.
2. Simpan sebagai secret (bukan di `.env`):
   ```bash
   cd functions
   firebase functions:secrets:set GROQ_API_KEY
   # tempel API key saat diminta
   ```
3. Deploy hanya fungsi baru:
   ```bash
   firebase deploy --only functions:transcribeRecitation
   ```
   Fungsi memakai region `asia-southeast2` (sama dgn fungsi lain).

### 2. App Flutter

```bash
flutter pub get
# kalau resolve gagal (versi cloud_functions/record), pakai:
flutter pub add cloud_functions record
```

Lalu jalankan di **device fisik** (emulator sering tak punya mikrofon):
```bash
flutter run
```

Buka: **Beranda admin → Akademik → Uji Bacaan**. Pilih surah + rentang ayat,
ketuk mikrofon, baca, ketuk lagi untuk berhenti & periksa.

## Biaya

| Komponen | Biaya |
|---|---|
| Groq Whisper API | **Gratis** (free tier, ada rate limit harian). Audio pendek per setoran sangat hemat. |
| Cloud Functions | Kuota gratis bulanan Blaze besar; transkripsi pendek jarang menembusnya. |
| Teks Qur'an | Bundel asset offline — **Rp0**, tanpa server. |
| Alignment | Jalan di HP — **Rp0**. |

Praktis **gratis** untuk skala pesantren. Pantau saja rate limit Groq kalau
dipakai banyak santri serentak.

## Status verifikasi (yang sudah & belum diuji)

- ✅ **Algoritma inti** (normalisasi Arab + Needleman-Wunsch) diuji 14/14 kasus
  lewat port JS di Node (bacaan sempurna, salah kata, ayat kelewat, kata
  tambahan, skip ayat penuh, toleransi typo ASR).
- ✅ **Normalizer Dart** diverifikasi byte-identik (codepoint) dengan versi JS
  yang lolos test.
- ✅ **Cloud Function** lolos `node --check`; `fetch`/`FormData`/`Blob` tersedia
  di Node 20.
- ⚠️ **UI/cubit/data Dart belum dikompilasi** di mesin ini (tidak ada Flutter
  SDK). Jalankan `flutter analyze` setelah `flutter pub get` untuk memastikan.
- ⚠️ **Akurasi ASR pada bacaan santri nyata belum diukur** — ini go/no-go test
  Fase 0. Uji dengan beberapa santri (anak-anak, kecepatan baca beragam).

## Batasan Fase 0 & langkah lanjut

- **Belum real-time** (rekam → periksa, bukan highlight per kata berjalan).
- **Belum deteksi tajwid / panjang-pendek (mad, ghunnah, makhraj)** — Whisper
  menghasilkan teks, bukan durasi vokal, jadi mad tidak bisa dinilai. Butuh
  model fonem/akustik khusus (fase lanjut).
- **Toleransi ejaan mad**: rasm Utsmani sering menulis vokal panjang dengan
  *dagger alef* (mis. عَٰبِدُونَ) yang berbeda dari output ASR (عابدون). Matcher
  memberi toleransi (`_maddTolerance` di `recitation_matcher.dart`) agar beda
  ejaan seperti ini dihitung BENAR, bukan salah. Kata pendek yang benar-benar
  beda (قل vs قال) tetap terdeteksi salah.
- **Analisis per kata ditampilkan tanpa harakat** (hasil normalisasi). Kata
  salah juga menampilkan "terdengar: …" agar jelas ini banding suara vs mushaf.
  Polish berikutnya: petakan diff ke teks mushaf berharakat.
- **Audio panjang (>~25 dtk)** sebaiknya dipotong sebelum dikirim ke Whisper.
- Akurasi bisa dinaikkan dgn model Whisper yang di-finetune Qur'an (mis. dari
  Tarteel di HuggingFace) — ganti `DEFAULT_MODEL` / endpoint di function.

## File yang ditambah

- `assets/quran/quran.json` (+ `SOURCE.md`) — teks 114 surah.
- `functions/handlers/transcribeRecitation.js` — proxy Groq.
- `lib/features/recitation_check/**` — domain (matcher/normalizer/entities),
  data (quran lokal, transkripsi remote, repository), presentation (cubit/page).
- Wiring: `pubspec.yaml`, `core/di/injection.dart`, `core/router/*`,
  `AndroidManifest.xml` (RECORD_AUDIO), `ios/Runner/Info.plist` (mic), menu di
  `admin_home_page.dart`.
