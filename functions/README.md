# Khoirun Functions — Rekonsiliasi Data

Cloud Functions (v2) untuk membandingkan data Web (MySQL) vs Mobile (Firestore).

## Function yang tersedia

- `compareSantri` — bandingkan santri berdasarkan **NIS**. Menampilkan:
  1. Santri yang ada di **Web** tapi **tidak ada di Mobile**
  2. Santri yang ada di **Mobile** tapi **tidak ada di Web**

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

# Migrasi — LIHAT DULU (dry-run, tidak menulis)
https://asia-southeast2-khoirun-app.cloudfunctions.net/importSantri

# Migrasi santri — EKSEKUSI (menulis data)
https://asia-southeast2-khoirun-app.cloudfunctions.net/importSantri?apply=true

# Migrasi pembayaran 2026 — LIHAT DULU lalu EKSEKUSI
https://asia-southeast2-khoirun-app.cloudfunctions.net/importPayments
https://asia-southeast2-khoirun-app.cloudfunctions.net/importPayments?apply=true
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
