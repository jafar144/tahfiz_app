# Pembelajaran Kosa Kata Journey

Bagian Kosa Kata tidak lagi memakai satu test lima soal. Setiap percobaan
menjalankan tiga fase secara berurutan dengan total 20 aktivitas. Angka dan
komposisinya berada di `vocab_learning_rules.dart`; pembentukan soalnya berada
di `vocab_lesson_question_factory.dart`.

## Komposisi fase

| Fase | Bentuk latihan | Jumlah |
|---|---|---:|
| 1 — Kenali Artinya | Arab → arti Indonesia | 5 |
| 2 — Latihan Campuran | Arab → arti Indonesia | 4 |
| 2 — Latihan Campuran | Arti Indonesia → Arab | 4 |
| 2 — Latihan Campuran | Cocokkan empat pasangan | 2 |
| 3 — Ingat & Ucapkan | Arti Indonesia → ucapkan potongan Arab | 5 |

Urutan antar-fase tidak diacak. Sepuluh aktivitas di dalam Fase 2 diacak agar
dua arah latihan dan papan pasangan tidak membentuk pola yang mudah ditebak.
Jika suatu surah hanya memiliki empat entri kosa kata, item sengaja diulang
dengan urutan baru untuk memberi efek penguatan seperti spaced repetition.

Kelulusan membutuhkan minimal 16 jawaban benar dari 20 aktivitas (80%). Hadiah
XP bagian Kosa Kata tetap mengikuti `SectionTest.xpReward` lembaga/kurikulum.

## Fase 3

Layar hanya menampilkan arti Indonesia. Santri mengucapkan `VocabItem.word`,
yaitu kata atau frasa Arab yang disimpan pada materi, bukan seluruh ayat.
Latihan ini tidak memakai timer.

Tombol **Lihat Bahasa Arab** dapat membuka jawaban sebagai hint karena Fase 3
adalah proses belajar. Sesudah rekaman diperiksa, jawaban Arab selalu terlihat
untuk penguatan.

Entri hanya dapat dipakai jika jumlah token `VocabItem.word` lebih sedikit
daripada jumlah token ayat sumber. Entri yang mencakup satu ayat penuh dibuang
karena tidak lagi menjadi latihan recall potongan kosa kata.

## Ujian Akhir

Ujian Akhir tetap berisi 10 soal dan selalu menyertakan tepat dua soal recall
arti Indonesia → potongan Arab. Kedua soal tersebut:

- diacak bersama delapan soal lainnya;
- tidak memakai timer;
- tidak menyediakan hint sebelum jawaban diperiksa;
- dinilai dengan ambang pemeriksaan bacaan Journey yang sama, yaitu 80%.

## Kompatibilitas progres lama

ID progres bagian tetap `kosakata`, sehingga data Firestore lama tidak rusak
dan pengguna yang sudah lulus tidak dipaksa mengulang. Kartu bagian menandai
bahwa tiga fase baru tersedia untuk diulang. Hasil baru disimpan sebagai jumlah
benar terbaik dari 20 aktivitas.
