import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';

/// Blok konten modular penyusun halaman belajar sebuah bagian surah.
///
/// Menambah jenis sub-konten baru (mis. tafsir ringkas) = tambah subclass di
/// sini + cara menggambarnya di `lesson_learn_view.dart`; seed surah tinggal
/// menambahkan blok tersebut ke [LessonSection.blocks].
sealed class LessonBlock {
  const LessonBlock();
}

/// Paragraf teks biasa dengan judul opsional.
class ParagraphBlock extends LessonBlock {
  final String? title;
  final String body;

  const ParagraphBlock({this.title, required this.body});
}

/// Daftar poin fakta bernomor.
class FactListBlock extends LessonBlock {
  final List<String> facts;

  const FactListBlock(this.facts);
}

/// Seluruh ayat surah — teks diambil dari mushaf lokal saat runtime.
class FullSurahBlock extends LessonBlock {
  const FullSurahBlock();
}

/// Daftar kosa kata / potongan ayat penting beserta artinya.
class VocabListBlock extends LessonBlock {
  final List<VocabItem> items;

  const VocabListBlock(this.items);
}

/// Satu kosa kata penting.
///
/// [word] HARUS disalin persis dari teks mushaf (`hafs_v18.json`, lengkap
/// dengan harakatnya) agar bisa disorot di dalam ayat [ayahNumber]; boleh
/// berupa frasa beberapa kata.
class VocabItem {
  final int ayahNumber;
  final String word;

  /// Transliterasi latin sederhana untuk membantu membaca.
  final String latin;

  /// Arti kata/frasa (Indonesia).
  final String meaning;

  /// Catatan singkat opsional (konteks/pelajaran).
  final String? note;

  const VocabItem({
    required this.ayahNumber,
    required this.word,
    required this.latin,
    required this.meaning,
    this.note,
  });
}

/// Aturan ujian sebuah bagian.
class SectionTest {
  /// Jumlah soal yang ditampilkan.
  final int questionCount;

  /// Jumlah benar minimal agar bagian dianggap LULUS.
  final int minCorrect;

  /// Banyak soal SUARA "sambung ayat".
  final int voiceContinueCount;

  /// Banyak soal SUARA "baca ayat terakhir surah".
  final int voiceLastAyahCount;

  /// Susun soal arti kata secara otomatis dari [VocabListBlock] bagian ini.
  final bool useVocabQuestions;

  /// Bank soal pilihan ganda tertulis; ujian mengambil beberapa secara acak.
  final List<FactQuestion> bank;

  /// XP yang didapat saat LULUS PERTAMA KALI pada bagian ini.
  final int xpReward;

  const SectionTest({
    required this.questionCount,
    required this.minCorrect,
    this.voiceContinueCount = 0,
    this.voiceLastAyahCount = 0,
    this.useVocabQuestions = false,
    this.bank = const [],
    required this.xpReward,
  });

  int get voiceCount => voiceContinueCount + voiceLastAyahCount;
}

/// Satu bagian pembelajaran dalam sebuah surah (mis. Informasi Umum,
/// Baca Surah, Kosa Kata). Setiap bagian punya konten + ujian kecil sendiri.
class LessonSection {
  /// Kunci progres di Firestore — JANGAN diubah setelah dipakai santri.
  final String id;

  final String title;

  /// Deskripsi singkat pada kartu daftar bagian.
  final String subtitle;

  /// Konten halaman belajar, digambar berurutan sebagai kartu geser.
  final List<LessonBlock> blocks;

  final SectionTest test;

  const LessonSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.blocks,
    required this.test,
  });

  /// Seluruh kosa kata pada blok-blok bagian ini.
  List<VocabItem> get vocabItems => [
    for (final b in blocks)
      if (b is VocabListBlock) ...b.items,
  ];
}
