# Rencana Fitur PR (Pekerjaan Rumah / Setoran Hafalan)

Tujuan: asatidz memberi PR hafalan mingguan ke tiap santri; santri mengerjakan
dengan merekam bacaan (ayat disembunyikan = uji hafalan), dan hasilnya (persentase
kebenaran) disimpan. Reset otomatis tiap Minggu malam.

---

## 1. Ringkasan alur

**Asatidz**
1. Menu baru "PR Santri" di dashboard → daftar santri miliknya.
2. Klik santri → bottom sheet "Beri PR": pilih surah + ayat (dari–sampai),
   boleh **banyak item** (multi-surah). Tanpa deadline.
3. Simpan → sheet tutup → kartu santri update (status: belum/sedang/selesai).

**Santri**
1. Banner di home: "Kamu punya PR minggu ini".
2. Klik → daftar item PR (surah + rentang ayat) + status per item.
3. Klik item → layar hafalan: **ayat disembunyikan**, hanya info "Surah X ayat A–B"
   + tombol rekam.
4. Setelah rekam → ayat muncul + warna koreksi + persentase.
5. Aturan: **≥ 90% → boleh Submit**; < 90% → "Ulangi".
6. Submit → simpan **persentase saja** (audio TIDAK dikirim/disimpan). Status item
   jadi "selesai".

**Reset mingguan:** murni berbasis *week key* (tanpa cron). Dokumen PR dikunci per
minggu; ganti minggu → key berubah → PR lama tak lagi "aktif" (tersimpan sebagai
riwayat). Lihat §4.

---

## 2. Fakta arsitektur (integrasi)

- Santri id **= `user.uid`** (`home_page.dart:60`, `SantriHomeCubit.overrideSantriId ?? user.uid`).
  Dokumen `santri_profiles` ber-id uid.
- Asatidz id **= `user.uid`** (`home_page.dart:72`).
- Daftar santri asatidz: `AsatidzSantriCubit.loadMySantri(uid)` →
  `scheduleRepository.getHalaqahsByTeacher(uid)` lalu `getSantrisByHalaqahId(halaqahId)`.
  → **pakai ulang** untuk halaman PR asatidz.
- Home routing per-role: `features/home/presentation/pages/home_page.dart`
  (santri → `SantriMainPage` + `SantriHomeCubit`; asatidz → `AsatidzDashboardPage`).
- Daftar surah + jumlah ayat: `RecitationRepository.getSurahList()` /
  `QuranLocalDataSource` (fitur `recitation_check`) → **pakai ulang** untuk picker.
- Koleksi Firestore relevan: `santri_profiles` (id=uid), `halaqahs` (teacherId),
  `users` (role).
- Pola: `feature/{data/{datasource,models,repository},domain/{entities,repositories,utils},presentation/{cubit,pages,widgets}}`.
  DI di `core/di/injection.dart`. Route di `core/router/app_router.dart` +
  `route_names.dart` / `route_paths.dart`.

---

## 3. Model data (Firestore)

**Koleksi: `pr_assignments`** — 1 dokumen per santri per minggu.

- **doc id** (deterministik → gampang upsert): `` `${santriId}_${weekKey}` ``
- Field:
  - `santri_id` (string, = uid)
  - `santri_name` (string)
  - `asatidz_id` (string)
  - `asatidz_name` (string)
  - `halaqah_id` (string)
  - `week_key` (string, lihat §4)
  - `created_at`, `updated_at` (Timestamp)
  - `items` (array of map):
    - `surah_id` (int)
    - `surah_name` (string, latin)
    - `from_ayah` (int)
    - `to_ayah` (int)
    - `status` (string: `pending` | `done`)
    - `score` (int? = persentase; null sebelum selesai)
    - `completed_at` (Timestamp?)

- Status keseluruhan = derived: `done` bila semua item `done`, else `pending`.
  (Tidak perlu disimpan; hitung di client.)

Catatan: `items` sebagai array cukup untuk skala kecil (beberapa item). Update skor
1 item = baca dok → ubah item di array → tulis balik (tanpa konkurensi, aman).

**Yang disimpan sesuai keputusan:** hanya persentase (+ status + waktu). Tidak ada
audio/transkripsi.

---

## 4. Week key & reset mingguan (tanpa cron)

Reset "Minggu malam" ditangani lewat *penguncian per minggu*. Tiap PR dok memakai
`week_key` = tanggal Minggu awal periode. Ganti minggu → id dok berubah → query PR
"minggu ini" tak menemukan apa-apa → tampil seperti ter-reset. Dok lama tetap ada
(riwayat).

`domain/utils/week_key.dart` (sketsa):

```dart
/// Kunci minggu untuk PR. Reset tiap Minggu (default jam 0; ubah [resetHour]
/// kalau mau "malam", mis. 19).
String prWeekKey(DateTime now, {int resetHour = 0}) {
  final daysSinceSunday = now.weekday % 7; // Senin=1..Minggu=7 -> Minggu=0
  var sunday = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: daysSinceSunday));
  if (now.weekday == DateTime.sunday && now.hour < resetHour) {
    sunday = sunday.subtract(const Duration(days: 7));
  }
  String two(int n) => n.toString().padLeft(2, '0');
  return '${sunday.year}-${two(sunday.month)}-${two(sunday.day)}';
}
```

> Keputusan yang perlu dipastikan: jam reset persisnya (§10). Default aman: Minggu 00:00.

---

## 5. Struktur folder fitur baru

```
lib/features/pr/
  domain/
    entities/pr_assignment.dart        # PrAssignment, PrItem, PrItemStatus (enum)
    repositories/pr_repository.dart
    utils/week_key.dart
  data/
    models/pr_assignment_model.dart     # fromFirestore / toFirestore
    datasource/pr_remote_datasource.dart
    repository/pr_repository_impl.dart
  presentation/
    cubit/
      asatidz_pr_cubit.dart + _state.dart   # daftar santri + status PR; beri PR
      santri_pr_cubit.dart  + _state.dart   # PR santri + submit skor
    pages/
      asatidz_pr_list_page.dart
      santri_pr_list_page.dart
    widgets/
      give_pr_sheet.dart      # bottom sheet beri PR (multi item)
      pr_santri_card.dart     # kartu santri + badge status
      pr_item_tile.dart       # baris item PR (santri)
```

---

## 6. Repository (kontrak `pr_repository.dart`)

```dart
abstract class PrRepository {
  // Asatidz
  Future<Either<Failure, PrAssignment?>> getForSantri(String santriId, String weekKey);
  Future<Either<Failure, List<PrAssignment>>> getForSantris(
      List<String> santriIds, String weekKey);       // batch buat list
  Future<Either<Failure, void>> savePr(PrAssignment pr); // upsert (id = santri_week)

  // Santri
  Future<Either<Failure, PrAssignment?>> getMyPr(String santriId, String weekKey);
  Future<Either<Failure, void>> submitItemScore({
    required String santriId,
    required String weekKey,
    required int itemIndex,
    required int score,
  });
}
```

`getForSantris`: Firestore `whereIn` (maks 10 id per query → chunk kalau perlu),
atau ambil satu-satu (halaqah biasanya kecil). Cukup ambil doc id `${id}_$weekKey`.

---

## 7. Sisi Asatidz

**Menu**: tambah `MenuCard`/tile di `AsatidzDashboardPage` → `context.push(RoutePaths.asatidzPr)`.

**`AsatidzPrListPage`** (+ `AsatidzPrCubit`)
- `load(asatidzUid)`:
  1. daftar santri (pakai ulang `getHalaqahsByTeacher` + `getSantrisByHalaqahId`).
  2. `weekKey = prWeekKey(DateTime.now())`.
  3. `getForSantris(santriIds, weekKey)` → map santriId→PrAssignment.
  4. emit list gabungan (santri + PR-nya / null).
- UI: `ListView` `PrSantriCard`:
  - nama santri + badge:
    - null → "Belum diberi PR"
    - ada, belum semua done → "PR: {n} item · {done}/{n} selesai"
    - semua done → "Selesai ✓"
  - tap → buka `GivePrSheet`.

**`GivePrSheet`** (bottom sheet)
- State lokal: `List<PrItemDraft>` (surah, from, to). Prefill dari PR existing bila ada.
- Tombol "Tambah item" → baris picker: dropdown Surah (dari `getSurahList()`),
  dropdown dari/sampai ayat (maks = totalVerses). Bisa hapus item.
- "Simpan" → susun `PrAssignment` (id `${santriId}_$weekKey`, items status `pending`,
  score null) → `repo.savePr` → tutup sheet → `cubit.load(...)` refresh.
- Tanpa deadline.

---

## 8. Sisi Santri

**Banner home**: di `home_page.dart` (tempat santriId=uid tersedia), bungkus dengan
`MultiBlocProvider` menambah `SantriPrCubit()..load(santriId, weekKey)`. Di
`SantriHomePage` tampilkan banner paling atas bila ada PR belum selesai:
"Kamu punya PR minggu ini ({done}/{n})" → tap → `SantriPrListPage`.
(Sementara cukup tampil; styling menyusul.)

**`SantriPrListPage`** (+ pakai `SantriPrCubit`)
- Tampilkan item PR (surah + ayat) + status:
  - `pending` → bisa dikerjakan
  - `done` → tampilkan skor (mis. "92%")
- Tap item `pending` → layar hafalan (rekam).

**Layar hafalan (integrasi recitation)** — lihat §9.

**Submit**: `repo.submitItemScore(santriId, weekKey, itemIndex, score)` → refresh →
banner/list update.

---

## 9. Integrasi dengan fitur `recitation_check`

Yang sudah ada & dipakai ulang: `RecitationCheckCubit` (rekam→transkrip→match→hasil
dengan target surah+from+to), `MushafView`, matcher (+ penanganan muqatta'at),
`buildTargetColoring`.

Yang perlu ditambah (kecil) untuk **mode PR**:
1. **Preset target** dari item PR (surah, from, to) saat init — tanpa selector.
2. **Sembunyikan ayat** sebelum hasil ada (uji hafalan). MushafView baru muncul saat
   status `done`. Sebelum itu tampilkan kartu "Surah X · ayat A–B" + tombol rekam.
   > Perlu konfirmasi hide vs show (§10). Default: HIDE.
3. **Gerbang 90%**: setelah hasil, kalau `accuracyPercent >= 90` → tombol **Submit**;
   else → tombol **Ulangi** (reset ke rekam lagi).
4. **Submit** memanggil `SantriPrCubit.submit(itemIndex, score)`.

Opsi implementasi (rekomendasi): buat halaman tipis `SantriPrRecitePage` yang
- menyediakan `RecitationCheckCubit` dengan target di-preset (tambahkan method
  `initTarget(surahId, from, to)` di cubit, atau parameter),
- membungkus tampilan: sebelum `done` → sembunyikan mushaf; sesudah → tampilkan +
  tombol Submit/Ulangi sesuai skor,
- Submit lewat `SantriPrCubit`.

Threshold 90% simpan sebagai const (`kPrPassThreshold = 90`).

---

## 10. Keputusan yang perlu dipastikan (default sudah dipilih)

1. **Sembunyikan ayat saat rekam?** (uji hafalan) — **default: YA (hide)**, sesuai
   niat awal. Kalau mau tampil, ubah §9.2.
2. **Jam reset Minggu** — default **Minggu 00:00**. Kalau "malam" beneran, set
   `resetHour` (mis. 19) di `prWeekKey`.
3. **Gerbang submit** — **< 90% = tidak boleh submit (ulangi)**. Threshold = 90.
4. **Riwayat PR minggu lama** — **disimpan** (murah, berguna nanti untuk rekap asatidz).
5. **Asatidz lihat skor santri** — belum sekarang (santri "tampilin dulu"). Nanti:
   tinggal baca `items[].score` di kartu asatidz.

---

## 11. Titik integrasi ke file eksisting

- `features/asatidz/presentation/pages/asatidz_dashboard_page.dart` → tambah menu PR.
- `features/home/presentation/pages/home_page.dart` → provide `SantriPrCubit` (santri).
- `features/santri/presentation/pages/santri_home_page.dart` → banner PR.
- `core/router/app_router.dart` → route `asatidzPr`, `santriPr`, `santriPrRecite`.
- `core/router/route_names.dart` & `route_paths.dart` → nama/paths baru.
- `core/di/injection.dart` → register `PrRemoteDataSource`, `PrRepository`,
  `AsatidzPrCubit`, `SantriPrCubit`.
- `features/recitation_check/.../recitation_check_cubit.dart` → tambah preset target
  + (opsional) flag hide.

---

## 12. Urutan bangun (biar bisa nyicil ~3 jam)

1. **Fondasi data** (± paling dulu): entity `PrAssignment`/`PrItem`, `week_key.dart`,
   model from/to Firestore, datasource, repo impl, daftar di DI. Uji manual tulis/baca
   satu dok lewat asatidz sheet sederhana.
2. **Asatidz**: `AsatidzPrListPage` + `GivePrSheet` + `PrSantriCard` + menu + route.
   (Pakai ulang loader santri & getSurahList.)
3. **Santri (tampil)**: banner home + `SantriPrListPage` + status item.
4. **Integrasi rekam** (paling tricky, terakhir): preset target + hide + gerbang 90%
   + submit skor.

Selesai per langkah bisa langsung dites, jadi kalau waktu habis pun sudah ada bagian
yang jalan.
```
