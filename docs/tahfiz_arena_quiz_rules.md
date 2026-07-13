# Aturan Kuis Tahfiz Arena

Sumber kebenaran gameplay berada di
`lib/features/recitation_quiz/domain/rules/`. Generator, penilaian, UI, dan test
mengambil aturan dari file yang sama.

## Jenis sesi

| Aspek | Latihan | Tantangan |
|---|---|---|
| Mode, difficulty, cakupan | Dipilih santri | Mode, difficulty, dan cakupan dipilih pada lembar Tantangan |
| Batas bermain | Energi mingguan | Kuota per mode |
| Histori dan leaderboard | Tidak disimpan | Disimpan |
| Lock transkripsi | Mode Suara | Mode Suara |

## Tingkat kesulitan sesi

Setiap soal inti mempunyai label aktual Mudah, Sedang, atau Sulit. Difficulty
sesi menentukan probabilitas label yang diminta generator:

| Difficulty sesi | Soal Mudah | Soal Sedang | Soal Sulit |
|---|---:|---:|---:|
| Mudah | 80% | 20% | 0% |
| Sedang | 40% | 40% | 20% |
| Sulit | 10% | 30% | 60% |

Generator hanya memilih tipe yang dapat dibentuk dari cakupan materi. Jika bank
materi untuk label target tidak tersedia, generator memilih label terdekat dan
label pada layar selalu menunjukkan kesulitan aktual, bukan target undian.

Multiplier diterapkan setelah sesi:

| Difficulty | Skor akhir/leaderboard | XP Pilihan | XP Suara |
|---|---:|---:|---:|
| Mudah | ×1 | ×1 | ×2 |
| Sedang | ×1,5 | ×1,5 | ×2,5 |
| Sulit | ×2 | ×2 | ×3 |

Bonus mode Suara pada XP dipertahankan karena memakai pemeriksaan rekaman, tetapi
tidak ditumpuk secara eksponensial dengan multiplier difficulty.

## Label soal inti Suara

| Variasi | Label |
|---|---|
| Lanjutkan ayat, total jawaban maksimal 20 kata | Mudah |
| Lanjutkan ayat, total jawaban di atas 20 kata | Sedang |
| Baca ayat terakhir surah | Sedang |
| Baca ayat ke-N | Sulit |
| Tebak ayat dari makna | Sulit |

Mode Suara berisi 10 soal. Lanjutan ayat tetap menyesuaikan panjang ayat:

| Panjang ayat pertama | Jumlah ayat jawaban | Timer |
|---|---:|---:|
| Maksimal 6 kata | acak 3–4 | 30 detik |
| 7–13 kata | 2 | 45 detik |
| Lebih dari 13 kata | 1 | 60 detik |

Timer memakai ayat terpanjang di jawaban. Jumlah ayat tetap dipotong di batas
segmen/juz.

### Tebak ayat dari makna

Soal menampilkan:

- kata atau frasa bermakna Indonesia;
- nama surah tempat ayat berada;
- timer 60 detik.

Santri membacakan satu ayat lengkap yang direferensikan bank kosakata Journey.
Saat waktu tersisa 30 detik, kata/frasa Arabnya muncul sebagai petunjuk.

Entri kosakata hanya eligible jika kata/frasa Arab merupakan bagian dari ayat.
Jika jumlah token kosakata sama dengan seluruh token ayat, entri dibuang karena
petunjuk tersebut pada dasarnya sudah mengungkap satu ayat penuh.

### Penilaian Suara

- Akurasi minimal lulus: 80%.
- Percobaan pertama di bawah 80% mendapat satu percobaan ulang.
- Lulus pada percobaan kedua tetap dihitung benar untuk streak.
- Akurasi 91–100% menjadi skor 100; tepat 90 tetap 90.
- Gagal dua kali memakai akurasi terbaik sebagai skor, tetapi memutus streak.
- Waktu habis memberi skor 0 dan memutus streak.

## Label soal inti Pilihan

| Variasi | Label |
|---|---|
| Lanjutan 1 ayat | Mudah |
| Lanjutan 2 ayat | Mudah |
| Lanjutan 3 ayat | Sedang |
| Arti kosakata | Sedang |
| Fakta materi Journey | Sulit |

Jika materi Journey tidak tersedia atau opsi `Ayat saja` aktif, target soal
Sulit dapat fallback ke soal Sedang/Mudah yang tersedia. Label aktual tetap
ditampilkan dengan benar.

Mode Pilihan berlangsung 60 detik. Batch berisi 40 kandidat dan ditambah saat
tersisa 10. Poin lanjutan ayat:

| Jawaban | Poin benar | Tambahan waktu |
|---:|---:|---:|
| 1 ayat | 10 | +1 detik |
| 2 ayat | 14 | +2 detik |
| 3 ayat | 18 | +3 detik |

Arti kosakata atau fakta Journey yang benar bernilai 10 poin dan +1 detik.

## Syarat bonus kedua mode

Bonus tidak lagi muncul berdasarkan nomor soal. Aturannya sama untuk Suara dan
Pilihan:

1. Lima soal inti harus dijawab benar secara berturut-turut.
2. Salah atau waktu habis mereset streak ke 0.
3. Setelah jawaban benar kelima, bonus langsung ditampilkan.
4. Jawaban bonus tidak menambah atau merusak streak.
5. Ketika bonus ditampilkan, streak dikonsumsi dan dimulai lagi dari 0.

Pada Pilihan, timer sesi utama dijeda selama bonus. Bonus penuh memberi 20 poin
dan +8 detik. Pada Suara, bonus penuh memberi 35 poin. Sumber bonus tetap diundi
50% matching kosakata dan 50% pengetahuan surah ketika kedua sumber tersedia.

## File aturan

- `quiz_difficulty_rules.dart`: distribusi difficulty dan multiplier.
- `voice_quiz_rules.dart`: timer, ambang, panjang jawaban, dan bonus Suara.
- `choice_quiz_rules.dart`: timer, poin, opsi, dan bonus Pilihan.
- `quiz_bonus_rules.dart`: syarat streak dan aturan bonus bersama.
- `weighted_quiz_rule.dart`: picker probabilitas berbobot.
