import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_section.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';

/// Konten Petualangan Surah — tahap awal: 4 surah juz 30 (Al-Lail → Al-Fajr,
/// mengikuti urutan hafalan mundur dari akhir mushaf).
///
/// Setiap surah tersusun dari BAGIAN modular (info umum → baca surah →
/// kosa kata); menambah bagian/blok baru cukup di file ini.
///
/// Sumber materi: arti nama & jumlah ayat selaras mushaf Kemenag (hitungan
/// Kufi); kisah memakai riwayat masyhur kitab tafsir; arti kosa kata mengacu
/// terjemah Kemenag — sebaiknya direview ustadz sebelum produksi. Teks Arab
/// kosa kata DISALIN PERSIS dari `assets/quran/hafs_v18.json` agar bisa
/// disorot di dalam ayatnya.
class SurahLessonSeed {
  SurahLessonSeed._();

  /// ID bagian standar (kunci progres Firestore — jangan diubah).
  static const String sectionInfo = 'info';
  static const String sectionRead = 'baca';
  static const String sectionVocab = 'kosakata';

  /// Seluruh level, urut dari level 1.
  static List<SurahLesson> get lessons =>
      List.unmodifiable(_lessons..sort((a, b) => a.level.compareTo(b.level)));

  /// Bagian "Baca Surah" — sama untuk semua surah (teks dari mushaf lokal).
  static LessonSection _readSection() => const LessonSection(
    id: sectionRead,
    title: 'Baca Surahnya',
    subtitle: 'Baca pelan-pelan sambil diingat urutan ayatnya',
    blocks: [
      ParagraphBlock(
        title: 'Cara Belajarnya',
        body:
            'Baca surah ini pelan-pelan dari awal sampai akhir sambil '
            'diingat urutan ayatnya. Perhatikan juga ayat TERAKHIR-nya, ya — '
            'nanti pasti keluar di test!',
      ),
      FullSurahBlock(),
    ],
    test: SectionTest(
      questionCount: 5,
      minCorrect: 4,
      voiceContinueCount: 4,
      voiceLastAyahCount: 1,
      xpReward: 40,
    ),
  );

  /// Template materi untuk level lanjutan. Data spesifik tiap surah tetap
  /// diberikan di bawah; template ini menjaga struktur belajar dan tesnya
  /// konsisten saat perjalanan diperpanjang.
  static SurahLesson _standardLesson({
    required int surahId,
    required int level,
    required String nameLatin,
    required String nameArabic,
    required String meaning,
    required int ayahCount,
    required String overview,
    required String mainMessage,
    required List<String> facts,
    required List<VocabItem> vocabulary,
  }) {
    final ayahOptions = [
      '${ayahCount - 2} ayat',
      '${ayahCount - 1} ayat',
      '$ayahCount ayat',
      '${ayahCount + 2} ayat',
    ];
    return SurahLesson(
      surahId: surahId,
      level: level,
      nameLatin: nameLatin,
      nameArabic: nameArabic,
      meaning: meaning,
      ayahCount: ayahCount,
      place: 'Makkiyah',
      sections: [
        LessonSection(
          id: sectionInfo,
          title: 'Informasi Umum',
          subtitle: 'Arti, jumlah ayat, pesan utama, dan fakta menariknya',
          blocks: [
            ParagraphBlock(
              title: 'Kenalan Dulu, Yuk!',
              body:
                  'Surah $nameLatin adalah surah ke-$surahId, terdiri dari '
                  '$ayahCount ayat, dan turun di Makkah. $overview',
            ),
            ParagraphBlock(title: 'Pesan Utamanya', body: mainMessage),
            FactListBlock(facts),
          ],
          test: SectionTest(
            questionCount: 3,
            minCorrect: 2,
            xpReward: 20,
            bank: [
              FactQuestion(
                question: 'Apa arti nama surah $nameLatin?',
                options: [meaning, 'Langit', 'Cahaya', 'Waktu'],
                correctIndex: 0,
              ),
              FactQuestion(
                question: 'Berapa jumlah ayat surah $nameLatin?',
                options: ayahOptions,
                correctIndex: 2,
              ),
              FactQuestion(
                question: 'Surah $nameLatin tergolong surah apa?',
                options: [
                  'Makkiyah',
                  'Madaniyah',
                  'Turun setelah hijrah',
                  'Tidak diketahui',
                ],
                correctIndex: 0,
              ),
              FactQuestion(
                question: 'Pesan utama surah $nameLatin adalah ...',
                options: [
                  mainMessage,
                  'Mengumpulkan harta sebanyak-banyaknya',
                  'Menunda perbuatan baik',
                  'Mengikuti hawa nafsu tanpa batas',
                ],
                correctIndex: 0,
              ),
            ],
          ),
        ),
        _readSection(),
        LessonSection(
          id: sectionVocab,
          title: 'Kosa Kata',
          subtitle: 'Kata-kata penting dalam surah beserta artinya',
          blocks: [
            const ParagraphBlock(
              title: 'Yuk, Pahami Katanya!',
              body:
                  'Perhatikan kata yang disorot pada tiap ayat berikut dan '
                  'ingat artinya. Memahami arti kata membuat hafalan makin '
                  'kuat dan bermakna.',
            ),
            VocabListBlock(vocabulary),
          ],
          test: const SectionTest(
            questionCount: 5,
            minCorrect: 4,
            useVocabQuestions: true,
            xpReward: 30,
          ),
        ),
      ],
    );
  }

  static final _lessons = <SurahLesson>[
    // ─────────────────────────────────────────────── Level 1 • Al-Lail (92) ──
    SurahLesson(
      surahId: 92,
      level: 1,
      nameLatin: 'Al-Lail',
      nameArabic: 'الليل',
      meaning: 'Malam',
      ayahCount: 21,
      place: 'Makkiyah',
      sections: [
        LessonSection(
          id: sectionInfo,
          title: 'Informasi Umum',
          subtitle: 'Arti, jumlah ayat, kisah, dan fakta menariknya',
          blocks: const [
            ParagraphBlock(
              title: 'Kenalan Dulu, Yuk!',
              body:
                  'Surah Al-Lail adalah surah ke-92, terdiri dari 21 ayat, '
                  'dan turun di Makkah. Surah ini dibuka dengan sumpah Allah '
                  'demi malam yang menutupi dan siang yang terang-benderang. '
                  'Isinya menggambarkan dua jalan hidup manusia: jalan orang '
                  'yang dermawan lagi bertakwa, dan jalan orang yang kikir '
                  'lagi mendustakan kebenaran.',
            ),
            ParagraphBlock(
              title: 'Kisah di Balik Surah',
              body:
                  'Diriwayatkan dalam kitab-kitab tafsir bahwa bagian akhir '
                  'surah ini berkaitan dengan kedermawanan Abu Bakar '
                  'ash-Shiddiq. Ketika kaum muslimin yang lemah — seperti '
                  'Bilal bin Rabah — disiksa tuannya karena beriman, Abu '
                  'Bakar membeli lalu memerdekakan mereka dengan hartanya, '
                  'tanpa mengharap balasan dari siapa pun. Maka turunlah '
                  'ayat "wa sayujannabuhal-atqā" — orang paling bertakwa itu '
                  'akan dijauhkan dari api neraka; ia memberi hartanya '
                  'semata mencari wajah Tuhannya, dan kelak ia benar-benar '
                  'akan puas.',
            ),
            FactListBlock([
              'Allah bersumpah demi malam saat menutupi dan siang saat '
                  'terang — dua waktu yang saling bergantian menjadi tanda '
                  'kekuasaan-Nya.',
              'Orang yang suka MEMBERI dan BERTAKWA dijanjikan dimudahkan '
                  'menuju jalan yang mudah; sebaliknya yang kikir dimudahkan '
                  'menuju jalan yang sukar.',
              'Allah menegaskan: "Sesungguhnya milik Kamilah akhirat dan '
                  'dunia" — jadi jangan takut miskin karena bersedekah.',
              'Surah ini menjadi bukti cinta sahabat: harta bisa habis, '
                  'tetapi balasan Allah tidak pernah habis.',
            ]),
          ],
          test: const SectionTest(
            questionCount: 3,
            minCorrect: 2,
            xpReward: 20,
            bank: [
              FactQuestion(
                question: 'Apa arti nama surah Al-Lail?',
                options: ['Malam', 'Siang', 'Fajar', 'Matahari'],
                correctIndex: 0,
              ),
              FactQuestion(
                question: 'Berapa jumlah ayat surah Al-Lail?',
                options: ['15 ayat', '19 ayat', '21 ayat', '30 ayat'],
                correctIndex: 2,
              ),
              FactQuestion(
                question: 'Surah Al-Lail termasuk golongan surah…',
                options: [
                  'Makkiyah',
                  'Madaniyah',
                  'Turun di Thaif',
                  'Turun di Habasyah',
                ],
                correctIndex: 0,
              ),
              FactQuestion(
                question:
                    'Sahabat yang masyhur disebut para mufassir berkaitan '
                    'dengan akhir surah Al-Lail karena kedermawanannya '
                    'adalah…',
                options: [
                  'Umar bin Khattab',
                  'Abu Bakar ash-Shiddiq',
                  'Utsman bin Affan',
                  'Ali bin Abi Thalib',
                ],
                correctIndex: 1,
              ),
              FactQuestion(
                question:
                    'Apa amal Abu Bakar yang berkaitan dengan turunnya akhir '
                    'surah Al-Lail?',
                options: [
                  'Membangun masjid pertama',
                  'Memerdekakan budak-budak beriman yang disiksa',
                  'Memimpin pasukan perang',
                  'Menuliskan wahyu untuk Nabi ﷺ',
                ],
                correctIndex: 1,
              ),
              FactQuestion(
                question: 'Surah Al-Lail dibuka dengan sumpah Allah demi…',
                options: [
                  'Malam apabila menutupi',
                  'Matahari dan cahayanya',
                  'Fajar dan malam yang sepuluh',
                  'Buah tin dan zaitun',
                ],
                correctIndex: 0,
              ),
              FactQuestion(
                question:
                    'Menurut surah Al-Lail, orang yang suka memberi dan '
                    'bertakwa akan…',
                options: [
                  'Diberi harta berlipat di dunia',
                  'Dijauhkan dari semua ujian',
                  'Dimudahkan menuju jalan yang mudah',
                  'Dipanjangkan umurnya',
                ],
                correctIndex: 2,
              ),
            ],
          ),
        ),
        _readSection(),
        LessonSection(
          id: sectionVocab,
          title: 'Kosa Kata',
          subtitle: 'Kata-kata penting dalam surah beserta artinya',
          blocks: const [
            ParagraphBlock(
              title: 'Yuk, Pahami Katanya!',
              body:
                  'Perhatikan kata yang disorot pada tiap ayat berikut dan '
                  'ingat artinya. Memahami arti kata membuat hafalanmu makin '
                  'kuat dan bermakna.',
            ),
            VocabListBlock([
              VocabItem(
                ayahNumber: 1,
                word: 'يَغۡشَىٰ',
                latin: 'yaghsyā',
                meaning: 'menutupi',
                note: 'Malam menutupi cahaya siang dengan gelapnya.',
              ),
              VocabItem(
                ayahNumber: 2,
                word: 'تَجَلَّىٰ',
                latin: 'tajallā',
                meaning: 'terang benderang',
              ),
              VocabItem(
                ayahNumber: 5,
                word: 'أَعۡطَىٰ',
                latin: 'a‘ṭā',
                meaning: 'memberi (hartanya)',
              ),
              VocabItem(
                ayahNumber: 5,
                word: 'وَٱتَّقَىٰ',
                latin: 'wattaqā',
                meaning: 'dan bertakwa',
              ),
              VocabItem(
                ayahNumber: 7,
                word: 'لِلۡيُسۡرَىٰ',
                latin: 'lil-yusrā',
                meaning: 'jalan yang mudah',
                note: 'Balasan bagi yang dermawan dan bertakwa.',
              ),
              VocabItem(
                ayahNumber: 8,
                word: 'بَخِلَ',
                latin: 'bakhila',
                meaning: 'kikir',
              ),
              VocabItem(
                ayahNumber: 10,
                word: 'لِلۡعُسۡرَىٰ',
                latin: 'lil-‘usrā',
                meaning: 'jalan yang sukar',
              ),
              VocabItem(
                ayahNumber: 18,
                word: 'يَتَزَكَّىٰ',
                latin: 'yatazakkā',
                meaning: 'menyucikan diri',
                note: 'Memberi harta untuk membersihkan jiwa & hartanya.',
              ),
            ]),
          ],
          test: const SectionTest(
            questionCount: 5,
            minCorrect: 4,
            useVocabQuestions: true,
            xpReward: 30,
          ),
        ),
      ],
    ),

    // ───────────────────────────────────────────── Level 2 • Asy-Syams (91) ──
    SurahLesson(
      surahId: 91,
      level: 2,
      nameLatin: 'Asy-Syams',
      nameArabic: 'الشمس',
      meaning: 'Matahari',
      ayahCount: 15,
      place: 'Makkiyah',
      sections: [
        LessonSection(
          id: sectionInfo,
          title: 'Informasi Umum',
          subtitle: 'Arti, jumlah ayat, kisah, dan fakta menariknya',
          blocks: const [
            ParagraphBlock(
              title: 'Kenalan Dulu, Yuk!',
              body:
                  'Surah Asy-Syams adalah surah ke-91, terdiri dari 15 ayat, '
                  'dan turun di Makkah. Surah ini istimewa karena dibuka '
                  'dengan TUJUH sumpah beruntun — demi matahari, bulan, '
                  'siang, malam, langit, bumi, dan jiwa manusia — sebelum '
                  'sampai pada pesan intinya: beruntunglah orang yang '
                  'menyucikan jiwanya.',
            ),
            ParagraphBlock(
              title: 'Kisah di Balik Surah',
              body:
                  'Surah ini menceritakan kaum Tsamud, kaum Nabi Shaleh. '
                  'Mereka meminta bukti kenabian, lalu Allah mengeluarkan '
                  'seekor unta betina dari batu sebagai mukjizat. Nabi '
                  'Shaleh berpesan: "Biarkan unta ini minum pada gilirannya, '
                  'jangan diganggu." Namun orang paling celaka di antara '
                  'mereka justru menyembelihnya. Karena kedurhakaan itu, '
                  'Allah membinasakan mereka semua — dan Allah tidak takut '
                  'terhadap akibatnya, karena Dialah Penguasa segala '
                  'sesuatu.',
            ),
            FactListBlock([
              'Pembuka surah ini memuat tujuh sumpah beruntun — salah satu '
                  'rangkaian sumpah terpanjang di dalam Al-Qur\'an.',
              'Pesan inti surah: "Qad aflaḥa man zakkāhā" — sungguh '
                  'beruntung orang yang menyucikan jiwanya, dan rugilah yang '
                  'mengotorinya.',
              'Mukjizat Nabi Shaleh adalah unta betina yang keluar dari '
                  'batu — tetap didustakan oleh kaumnya.',
              'Kaum Tsamud dibinasakan dengan suara mengguntur karena '
                  'menyembelih unta itu — pelajaran agar tidak menantang '
                  'perintah Allah.',
            ]),
          ],
          test: const SectionTest(
            questionCount: 3,
            minCorrect: 2,
            xpReward: 20,
            bank: [
              FactQuestion(
                question: 'Apa arti nama surah Asy-Syams?',
                options: ['Bulan', 'Matahari', 'Bintang', 'Cahaya'],
                correctIndex: 1,
              ),
              FactQuestion(
                question: 'Berapa jumlah ayat surah Asy-Syams?',
                options: ['11 ayat', '15 ayat', '20 ayat', '21 ayat'],
                correctIndex: 1,
              ),
              FactQuestion(
                question:
                    'Surah Asy-Syams dibuka dengan berapa sumpah Allah '
                    'beruntun?',
                options: ['3 sumpah', '5 sumpah', '7 sumpah', '9 sumpah'],
                correctIndex: 2,
              ),
              FactQuestion(
                question:
                    'Kisah kaum apa yang diceritakan dalam surah Asy-Syams?',
                options: [
                  'Kaum ‘Ad',
                  'Kaum Tsamud',
                  'Kaum Nabi Luth',
                  'Bani Israil',
                ],
                correctIndex: 1,
              ),
              FactQuestion(
                question: 'Siapa nabi yang diutus kepada kaum Tsamud?',
                options: [
                  'Nabi Hud',
                  'Nabi Syuaib',
                  'Nabi Shaleh',
                  'Nabi Musa',
                ],
                correctIndex: 2,
              ),
              FactQuestion(
                question:
                    'Apa mukjizat Nabi Shaleh yang disembelih kaum Tsamud?',
                options: [
                  'Tongkat menjadi ular',
                  'Unta betina dari batu',
                  'Kapal yang sangat besar',
                  'Burung dari tanah liat',
                ],
                correctIndex: 1,
              ),
              FactQuestion(
                question:
                    '"Sungguh beruntung orang yang…" — lanjutan pesan inti '
                    'surah Asy-Syams adalah…',
                options: [
                  'Memperbanyak hartanya',
                  'Menyucikan jiwanya',
                  'Tinggi kedudukannya',
                  'Banyak pengikutnya',
                ],
                correctIndex: 1,
              ),
            ],
          ),
        ),
        _readSection(),
        LessonSection(
          id: sectionVocab,
          title: 'Kosa Kata',
          subtitle: 'Kata-kata penting dalam surah beserta artinya',
          blocks: const [
            ParagraphBlock(
              title: 'Yuk, Pahami Katanya!',
              body:
                  'Ayat-ayat surah ini pendek dan berirama. Perhatikan kata '
                  'yang disorot dan ingat artinya, ya!',
            ),
            VocabListBlock([
              VocabItem(
                ayahNumber: 1,
                word: 'وَضُحَىٰهَا',
                latin: 'wa ḍuḥāhā',
                meaning: 'dan cahayanya di pagi hari',
              ),
              VocabItem(
                ayahNumber: 2,
                word: 'تَلَىٰهَا',
                latin: 'talāhā',
                meaning: 'mengiringinya',
                note: 'Bulan muncul mengiringi matahari.',
              ),
              VocabItem(
                ayahNumber: 4,
                word: 'يَغۡشَىٰهَا',
                latin: 'yaghsyāhā',
                meaning: 'menutupinya',
              ),
              VocabItem(
                ayahNumber: 7,
                word: 'سَوَّىٰهَا',
                latin: 'sawwāhā',
                meaning: 'menyempurnakannya',
                note: 'Allah menyempurnakan penciptaan jiwa manusia.',
              ),
              VocabItem(
                ayahNumber: 9,
                word: 'زَكَّىٰهَا',
                latin: 'zakkāhā',
                meaning: 'menyucikannya (jiwa)',
              ),
              VocabItem(
                ayahNumber: 10,
                word: 'دَسَّىٰهَا',
                latin: 'dassāhā',
                meaning: 'mengotorinya (jiwa)',
              ),
              VocabItem(
                ayahNumber: 13,
                word: 'نَاقَةَ ٱللَّهِ',
                latin: 'nāqatallāh',
                meaning: 'unta betina (milik) Allah',
                note: 'Mukjizat Nabi Shaleh untuk kaum Tsamud.',
              ),
              VocabItem(
                ayahNumber: 14,
                word: 'فَعَقَرُوهَا',
                latin: 'fa ‘aqarūhā',
                meaning: 'lalu mereka menyembelihnya',
              ),
            ]),
          ],
          test: const SectionTest(
            questionCount: 5,
            minCorrect: 4,
            useVocabQuestions: true,
            xpReward: 30,
          ),
        ),
      ],
    ),

    // ────────────────────────────────────────────── Level 3 • Al-Balad (90) ──
    SurahLesson(
      surahId: 90,
      level: 3,
      nameLatin: 'Al-Balad',
      nameArabic: 'البلد',
      meaning: 'Negeri',
      ayahCount: 20,
      place: 'Makkiyah',
      sections: [
        LessonSection(
          id: sectionInfo,
          title: 'Informasi Umum',
          subtitle: 'Arti, jumlah ayat, kisah, dan fakta menariknya',
          blocks: const [
            ParagraphBlock(
              title: 'Kenalan Dulu, Yuk!',
              body:
                  'Surah Al-Balad adalah surah ke-90, terdiri dari 20 ayat, '
                  'dan turun di Makkah. Allah bersumpah demi "negeri ini" — '
                  'kota Makkah yang mulia, tempat Rasulullah ﷺ tinggal. '
                  'Surah ini mengingatkan bahwa manusia diciptakan dalam '
                  'keadaan susah payah, lalu mengajak kita menempuh "jalan '
                  'yang mendaki" — jalan kebaikan yang berat tetapi berbuah '
                  'surga.',
            ),
            ParagraphBlock(
              title: 'Kisah di Balik Surah',
              body:
                  'Allah bersumpah demi kota Makkah dan menyebut kemuliaan '
                  'Nabi ﷺ yang bertempat tinggal di sana. Surah ini lalu '
                  'menegur manusia yang menyombongkan hartanya — "aku telah '
                  'menghabiskan harta yang banyak" — seolah tidak ada yang '
                  'mengawasinya. Padahal Allah telah memberinya dua mata, '
                  'lidah, dua bibir, dan menunjukkan dua jalan: kebaikan dan '
                  'keburukan. Manusia sendirilah yang memilih jalannya.',
            ),
            FactListBlock([
              '"Negeri" yang Allah bersumpah dengannya adalah kota MAKKAH — '
                  'kota kelahiran Rasulullah ﷺ.',
              'Manusia diciptakan dalam keadaan "kabad" — susah payah; '
                  'hidup memang penuh perjuangan.',
              '"Jalan yang mendaki" (al-‘aqabah) ditempuh dengan '
                  'memerdekakan budak serta memberi makan anak yatim dan '
                  'orang miskin di masa kelaparan.',
              'Golongan kanan (ashabul-maimanah) adalah orang beriman yang '
                  'saling berpesan untuk sabar dan berkasih sayang.',
            ]),
          ],
          test: const SectionTest(
            questionCount: 3,
            minCorrect: 2,
            xpReward: 20,
            bank: [
              FactQuestion(
                question: 'Apa arti nama surah Al-Balad?',
                options: ['Negeri', 'Gunung', 'Lembah', 'Rumah'],
                correctIndex: 0,
              ),
              FactQuestion(
                question: 'Berapa jumlah ayat surah Al-Balad?',
                options: ['15 ayat', '18 ayat', '20 ayat', '22 ayat'],
                correctIndex: 2,
              ),
              FactQuestion(
                question:
                    '"Negeri" yang Allah bersumpah dengannya dalam surah '
                    'Al-Balad adalah…',
                options: [
                  'Madinah',
                  'Kota Makkah',
                  'Baitul Maqdis',
                  'Negeri Syam',
                ],
                correctIndex: 1,
              ),
              FactQuestion(
                question:
                    'Menurut surah Al-Balad, manusia diciptakan dalam '
                    'keadaan…',
                options: [
                  'Bersenang-senang',
                  'Susah payah',
                  'Serba kecukupan',
                  'Tanpa ujian',
                ],
                correctIndex: 1,
              ),
              FactQuestion(
                question:
                    '"Jalan yang mendaki lagi sukar" (al-‘aqabah) dalam '
                    'surah Al-Balad ditempuh dengan cara…',
                options: [
                  'Berdagang ke negeri yang jauh',
                  'Mendaki gunung sungguhan',
                  'Memerdekakan budak dan memberi makan yatim & miskin',
                  'Berpuasa setiap hari tanpa henti',
                ],
                correctIndex: 2,
              ),
              FactQuestion(
                question:
                    'Allah menunjukkan manusia "dua jalan" (najdain), '
                    'yaitu…',
                options: [
                  'Jalan darat dan jalan laut',
                  'Jalan kebaikan dan jalan keburukan',
                  'Jalan dunia dan jalan langit',
                  'Jalan siang dan jalan malam',
                ],
                correctIndex: 1,
              ),
              FactQuestion(
                question:
                    'Golongan kanan (ashabul-maimanah) saling berpesan '
                    'untuk…',
                options: [
                  'Sabar dan kasih sayang',
                  'Harta dan kedudukan',
                  'Diam dan menyendiri',
                  'Bekerja tanpa istirahat',
                ],
                correctIndex: 0,
              ),
            ],
          ),
        ),
        _readSection(),
        LessonSection(
          id: sectionVocab,
          title: 'Kosa Kata',
          subtitle: 'Kata-kata penting dalam surah beserta artinya',
          blocks: const [
            ParagraphBlock(
              title: 'Yuk, Pahami Katanya!',
              body:
                  'Surah ini penuh kata bermakna dalam tentang perjuangan '
                  'hidup. Perhatikan kata yang disorot dan artinya, ya!',
            ),
            VocabListBlock([
              VocabItem(
                ayahNumber: 1,
                word: 'ٱلۡبَلَدِ',
                latin: 'al-balad',
                meaning: 'negeri (kota Makkah)',
              ),
              VocabItem(
                ayahNumber: 4,
                word: 'كَبَدٍ',
                latin: 'kabad',
                meaning: 'susah payah',
                note: 'Hidup manusia memang penuh perjuangan.',
              ),
              VocabItem(
                ayahNumber: 8,
                word: 'عَيۡنَيۡنِ',
                latin: '‘ainain',
                meaning: 'dua mata',
              ),
              VocabItem(
                ayahNumber: 9,
                word: 'وَلِسَانٗا وَشَفَتَيۡنِ',
                latin: 'wa lisānan wa syafatain',
                meaning: 'lidah dan dua bibir',
              ),
              VocabItem(
                ayahNumber: 10,
                word: 'ٱلنَّجۡدَيۡنِ',
                latin: 'an-najdain',
                meaning: 'dua jalan (kebaikan & keburukan)',
              ),
              VocabItem(
                ayahNumber: 11,
                word: 'ٱلۡعَقَبَةَ',
                latin: 'al-‘aqabah',
                meaning: 'jalan yang mendaki (sukar)',
                note: 'Jalan kebaikan yang berat tetapi berbuah surga.',
              ),
              VocabItem(
                ayahNumber: 13,
                word: 'فَكُّ رَقَبَةٍ',
                latin: 'fakku raqabah',
                meaning: 'memerdekakan budak',
              ),
              VocabItem(
                ayahNumber: 15,
                word: 'يَتِيمٗا',
                latin: 'yatīman',
                meaning: 'anak yatim',
              ),
            ]),
          ],
          test: const SectionTest(
            questionCount: 5,
            minCorrect: 4,
            useVocabQuestions: true,
            xpReward: 30,
          ),
        ),
      ],
    ),

    // ─────────────────────────────────────────────── Level 4 • Al-Fajr (89) ──
    SurahLesson(
      surahId: 89,
      level: 4,
      nameLatin: 'Al-Fajr',
      nameArabic: 'الفجر',
      meaning: 'Fajar',
      ayahCount: 30,
      place: 'Makkiyah',
      sections: [
        LessonSection(
          id: sectionInfo,
          title: 'Informasi Umum',
          subtitle: 'Arti, jumlah ayat, kisah, dan fakta menariknya',
          blocks: const [
            ParagraphBlock(
              title: 'Kenalan Dulu, Yuk!',
              body:
                  'Surah Al-Fajr adalah surah ke-89, terdiri dari 30 ayat, '
                  'dan turun di Makkah. Surah ini dibuka dengan sumpah demi '
                  'fajar dan "malam yang sepuluh", lalu menceritakan tiga '
                  'kaum perkasa yang dibinasakan karena durhaka: ‘Ad, '
                  'Tsamud, dan Fir‘aun. Surah ini ditutup dengan panggilan '
                  'terindah untuk jiwa yang tenang.',
            ),
            ParagraphBlock(
              title: 'Kisah di Balik Surah',
              body:
                  'Surah ini menghadirkan tiga kisah sebagai peringatan: '
                  'kaum ‘Ad dengan kota Iram yang bertiang tinggi, kaum '
                  'Tsamud yang pandai memahat batu besar di lembah, dan '
                  'Fir‘aun sang pemilik pasak-pasak (tentara dan bangunan '
                  'yang kokoh). Semuanya berbuat sewenang-wenang dan banyak '
                  'kerusakan, maka Allah menimpakan cemeti azab. Surah lalu '
                  'menegur manusia yang hanya mencintai harta dan tidak '
                  'memuliakan anak yatim.',
            ),
            FactListBlock([
              '"Malam yang sepuluh" menurut banyak ulama tafsir adalah '
                  'sepuluh malam pertama bulan Dzulhijjah — hari-hari yang '
                  'sangat mulia.',
              'Kota Iram milik kaum ‘Ad disebut "yang belum pernah dibangun '
                  'sepertinya di negeri-negeri lain".',
              'Ayat penutupnya menjadi salah satu ayat paling menenangkan: '
                  '"Wahai jiwa yang tenang! Kembalilah kepada Tuhanmu dengan '
                  'hati ridha dan diridhai…"',
              'Surah ini mengingatkan: ujian bukan hanya kesempitan — '
                  'kelapangan harta juga ujian, tergantung bagaimana kita '
                  'memperlakukan anak yatim dan orang miskin.',
            ]),
          ],
          test: const SectionTest(
            questionCount: 3,
            minCorrect: 2,
            xpReward: 20,
            bank: [
              FactQuestion(
                question: 'Apa arti nama surah Al-Fajr?',
                options: ['Fajar', 'Malam', 'Matahari terbenam', 'Waktu Duha'],
                correctIndex: 0,
              ),
              FactQuestion(
                question: 'Berapa jumlah ayat surah Al-Fajr?',
                options: ['21 ayat', '25 ayat', '30 ayat', '32 ayat'],
                correctIndex: 2,
              ),
              FactQuestion(
                question:
                    '"Malam yang sepuluh" dalam surah Al-Fajr menurut banyak '
                    'ulama adalah…',
                options: [
                  'Sepuluh malam terakhir Ramadhan',
                  'Sepuluh malam pertama Dzulhijjah',
                  'Sepuluh malam pertama Muharram',
                  'Sepuluh malam pertama Rajab',
                ],
                correctIndex: 1,
              ),
              FactQuestion(
                question:
                    'Kaum ‘Ad dalam surah Al-Fajr terkenal dengan kotanya '
                    'yang bertiang tinggi, bernama…',
                options: ['Madyan', 'Saba’', 'Iram', 'Babilonia'],
                correctIndex: 2,
              ),
              FactQuestion(
                question: 'Kaum Tsamud dalam surah Al-Fajr dikenal pandai…',
                options: [
                  'Berlayar mengarungi lautan',
                  'Memahat batu besar di lembah',
                  'Bercocok tanam di gurun',
                  'Menenun kain sutra',
                ],
                correctIndex: 1,
              ),
              FactQuestion(
                question: 'Dalam surah Al-Fajr, Fir‘aun dijuluki pemilik…',
                options: [
                  'Kebun-kebun anggur',
                  'Kapal-kapal besar',
                  'Pasak-pasak (tentara & bangunan kokoh)',
                  'Istana emas',
                ],
                correctIndex: 2,
              ),
              FactQuestion(
                question:
                    'Di akhir surah Al-Fajr, Allah memanggil dengan lembut: '
                    '"Wahai jiwa yang…"',
                options: ['Gelisah', 'Tenang', 'Sombong', 'Lalai'],
                correctIndex: 1,
              ),
            ],
          ),
        ),
        _readSection(),
        LessonSection(
          id: sectionVocab,
          title: 'Kosa Kata',
          subtitle: 'Kata-kata penting dalam surah beserta artinya',
          blocks: const [
            ParagraphBlock(
              title: 'Yuk, Pahami Katanya!',
              body:
                  'Surah Al-Fajr penuh kisah kaum-kaum terdahulu. Kata-kata '
                  'berikut kunci untuk memahaminya — perhatikan sorotannya!',
            ),
            VocabListBlock([
              VocabItem(
                ayahNumber: 1,
                word: 'وَٱلۡفَجۡرِ',
                latin: 'wal-fajr',
                meaning: 'demi (waktu) fajar',
              ),
              VocabItem(
                ayahNumber: 2,
                word: 'وَلَيَالٍ عَشۡرٖ',
                latin: 'wa layālin ‘asyr',
                meaning: 'dan malam yang sepuluh',
                note: 'Sepuluh malam pertama bulan Dzulhijjah.',
              ),
              VocabItem(
                ayahNumber: 6,
                word: 'بِعَادٍ',
                latin: 'bi-‘ād',
                meaning: 'terhadap kaum ‘Ad',
              ),
              VocabItem(
                ayahNumber: 7,
                word: 'إِرَمَ',
                latin: 'iram',
                meaning: 'Iram (kota kaum ‘Ad)',
                note: 'Kota bertiang tinggi yang tiada bandingannya.',
              ),
              VocabItem(
                ayahNumber: 9,
                word: 'جَابُواْ ٱلصَّخۡرَ',
                latin: 'jābuṣ-ṣakhr',
                meaning: 'memahat batu-batu besar',
              ),
              VocabItem(
                ayahNumber: 10,
                word: 'ٱلۡأَوۡتَادِ',
                latin: 'al-autād',
                meaning: 'pasak-pasak (tentara yang kokoh)',
                note: 'Julukan kekuatan Fir‘aun.',
              ),
              VocabItem(
                ayahNumber: 14,
                word: 'لَبِٱلۡمِرۡصَادِ',
                latin: 'labil-mirṣād',
                meaning: 'benar-benar mengawasi',
              ),
              VocabItem(
                ayahNumber: 27,
                word: 'ٱلنَّفۡسُ ٱلۡمُطۡمَئِنَّةُ',
                latin: 'an-nafsul-muṭma’innah',
                meaning: 'jiwa yang tenang',
                note: 'Panggilan terindah bagi hamba yang ridha.',
              ),
            ]),
          ],
          test: const SectionTest(
            questionCount: 5,
            minCorrect: 4,
            useVocabQuestions: true,
            xpReward: 30,
          ),
        ),
      ],
    ),

    // Level 5-15: Al-Ghasyiyah sampai An-Naba'.
    _standardLesson(
      surahId: 88,
      level: 5,
      nameLatin: 'Al-Ghasyiyah',
      nameArabic: '\u0627\u0644\u063A\u0627\u0634\u064A\u0629',
      meaning: 'Hari Kiamat yang Meliputi',
      ayahCount: 26,
      overview:
          'Surah ini menggambarkan dua keadaan manusia pada hari akhir: '
          'wajah yang terhina dan wajah yang berseri-seri dalam kenikmatan.',
      mainMessage:
          'Ingat akhirat, lalu perhatikan tanda kekuasaan Allah di sekeliling kita.',
      facts: [
        'Surah ini mengajak manusia memperhatikan unta, langit, gunung, dan bumi.',
        'Penutupnya menegaskan bahwa Rasul hanya menyampaikan, sedangkan perhitungan kembali kepada Allah.',
      ],
      vocabulary: const [
        VocabItem(
          ayahNumber: 1,
          word:
              '\u0671\u0644\u06E1\u063A\u064E\u0670\u0634\u0650\u064A\u064E\u0629\u0650',
          latin: 'al-ghasyiyah',
          meaning: 'peristiwa yang meliputi',
        ),
        VocabItem(
          ayahNumber: 2,
          word: '\u062E\u064E\u0670\u0634\u0650\u0639\u064E\u0629\u064C',
          latin: 'khasyi\'ah',
          meaning: 'tertunduk hina',
        ),
        VocabItem(
          ayahNumber: 17,
          word: '\u0671\u0644\u06E1\u0625\u0650\u0628\u0650\u0644\u0650',
          latin: 'al-ibil',
          meaning: 'unta-unta',
        ),
        VocabItem(
          ayahNumber: 25,
          word:
              '\u0625\u0650\u064A\u064E\u0627\u0628\u064E\u0647\u064F\u0645\u06E1',
          latin: 'iyabahum',
          meaning: 'kembalinya mereka',
        ),
      ],
    ),
    _standardLesson(
      surahId: 87,
      level: 6,
      nameLatin: 'Al-A\'la',
      nameArabic: '\u0627\u0644\u0623\u0639\u0644\u0649',
      meaning: 'Yang Paling Tinggi',
      ayahCount: 19,
      overview:
          'Surah ini dibuka dengan perintah menyucikan nama Allah Yang Mahatinggi, Pencipta yang menyempurnakan dan memberi petunjuk.',
      mainMessage:
          'Sucikan nama Allah, ambil pelajaran dari wahyu, dan utamakan akhirat yang lebih baik serta kekal.',
      facts: [
        'Ayat 14-15 mengaitkan keberuntungan dengan menyucikan diri dan mengingat nama Tuhannya lalu salat.',
        'Penutupnya menyebut ajaran ini juga terdapat dalam suhuf Nabi Ibrahim dan Nabi Musa.',
      ],
      vocabulary: const [
        VocabItem(
          ayahNumber: 1,
          word:
              '\u0671\u0644\u06E1\u0623\u064E\u0639\u06E1\u0644\u064E\u0649\u0670',
          latin: 'al-a\'la',
          meaning: 'Yang Mahatinggi',
        ),
        VocabItem(
          ayahNumber: 3,
          word: '\u0642\u064E\u062F\u0651\u064E\u0631\u064E',
          latin: 'qaddara',
          meaning: 'menentukan ukuran',
        ),
        VocabItem(
          ayahNumber: 9,
          word:
              '\u0671\u0644\u0630\u0651\u0650\u0643\u06E1\u0631\u064E\u0649\u0670',
          latin: 'adz-dzikra',
          meaning: 'peringatan',
        ),
        VocabItem(
          ayahNumber: 17,
          word:
              '\u0671\u0644\u06E1\u0623\u0653\u062E\u0650\u0631\u064E\u0629\u064F',
          latin: 'al-akhirah',
          meaning: 'akhirat',
        ),
      ],
    ),
    _standardLesson(
      surahId: 86,
      level: 7,
      nameLatin: 'At-Tariq',
      nameArabic: '\u0627\u0644\u0637\u0627\u0631\u0642',
      meaning: 'Yang Datang di Malam Hari',
      ayahCount: 17,
      overview:
          'Surah ini bersumpah demi langit dan bintang yang menembus, lalu mengingatkan manusia tentang asal penciptaannya dan hari dibukanya semua rahasia.',
      mainMessage:
          'Yakinlah bahwa Allah mengetahui rahasia manusia dan kuasa membangkitkannya kembali.',
      facts: [
        'At-tariq dijelaskan sebagai bintang yang cahayanya menembus kegelapan.',
        'Surah ini menegaskan Al-Qur\'an adalah firman yang memisahkan kebenaran dan kebatilan, bukan senda gurau.',
      ],
      vocabulary: const [
        VocabItem(
          ayahNumber: 1,
          word: '\u0671\u0644\u0637\u0651\u064E\u0627\u0631\u0650\u0642\u0650',
          latin: 'ath-thariq',
          meaning: 'yang datang pada malam hari',
        ),
        VocabItem(
          ayahNumber: 3,
          word:
              '\u0671\u0644\u0646\u0651\u064E\u062C\u06E1\u0645\u064F\u0020\u0671\u0644\u062B\u0651\u064E\u0627\u0642\u0650\u0628\u064F',
          latin: 'an-najm ats-tsaqib',
          meaning: 'bintang yang cahayanya menembus',
        ),
        VocabItem(
          ayahNumber: 9,
          word:
              '\u0671\u0644\u0633\u0651\u064E\u0631\u064E\u0627\u0653\u0626\u0650\u0631\u064F',
          latin: 'as-sara\'ir',
          meaning: 'rahasia-rahasia',
        ),
        VocabItem(
          ayahNumber: 15,
          word: '\u064A\u064E\u0643\u0650\u064A\u062F\u064F\u0648\u0646\u064E',
          latin: 'yakidun',
          meaning: 'mereka membuat tipu daya',
        ),
      ],
    ),
    _standardLesson(
      surahId: 85,
      level: 8,
      nameLatin: 'Al-Buruj',
      nameArabic: '\u0627\u0644\u0628\u0631\u0648\u062C',
      meaning: 'Gugusan Bintang',
      ayahCount: 22,
      overview:
          'Surah ini mengisahkan para pembuat parit yang menyiksa orang-orang beriman karena iman mereka kepada Allah Yang Mahaperkasa dan Maha Terpuji.',
      mainMessage:
          'Tetap teguh dalam iman, karena Allah menyaksikan setiap kezaliman dan memberi balasan yang adil.',
      facts: [
        'Kisah Ashabul Ukhdud menjadi teladan keteguhan orang beriman saat diuji.',
        'Surah ini menutup dengan penegasan bahwa Al-Qur\'an terpelihara pada Lauh Mahfuz.',
      ],
      vocabulary: const [
        VocabItem(
          ayahNumber: 1,
          word: '\u0671\u0644\u06E1\u0628\u064F\u0631\u064F\u0648\u062C\u0650',
          latin: 'al-buruj',
          meaning: 'gugusan bintang',
        ),
        VocabItem(
          ayahNumber: 4,
          word:
              '\u0623\u064E\u0635\u06E1\u062D\u064E\u0670\u0628\u064F\u0020\u0671\u0644\u06E1\u0623\u064F\u062E\u06E1\u062F\u064F\u0648\u062F\u0650',
          latin: 'ashabul-ukhdud',
          meaning: 'orang-orang yang membuat parit',
        ),
        VocabItem(
          ayahNumber: 14,
          word: '\u0671\u0644\u06E1\u0648\u064E\u062F\u064F\u0648\u062F\u064F',
          latin: 'al-wadud',
          meaning: 'Yang Maha Mencintai',
        ),
        VocabItem(
          ayahNumber: 20,
          word: '\u0645\u0651\u064F\u062D\u0650\u064A\u0637\u064F\u06E2',
          latin: 'muhith',
          meaning: 'meliputi',
        ),
      ],
    ),
    _standardLesson(
      surahId: 84,
      level: 9,
      nameLatin: 'Al-Insyiqaq',
      nameArabic: '\u0627\u0644\u0627\u0646\u0634\u0642\u0627\u0642',
      meaning: 'Terbelah',
      ayahCount: 25,
      overview:
          'Surah ini menggambarkan langit yang terbelah dan bumi yang mengeluarkan isinya ketika hari kiamat datang.',
      mainMessage:
          'Setiap manusia sedang bersungguh-sungguh menuju Tuhannya dan akan menemui hasil amalnya.',
      facts: [
        'Surah ini menyebut dua cara menerima catatan amal: dari kanan sebagai kabar gembira, atau dari belakang sebagai penyesalan.',
        'Ayat terakhir menjanjikan pahala yang tidak putus bagi orang beriman dan beramal saleh.',
      ],
      vocabulary: const [
        VocabItem(
          ayahNumber: 1,
          word: '\u0671\u0646\u0634\u064E\u0642\u0651\u064E\u062A\u06E1',
          latin: 'insyaqqat',
          meaning: 'terbelah',
        ),
        VocabItem(
          ayahNumber: 6,
          word: '\u0643\u064E\u0627\u062F\u0650\u062D\u064C',
          latin: 'kadih',
          meaning: 'bersungguh-sungguh berusaha',
        ),
        VocabItem(
          ayahNumber: 12,
          word: '\u0633\u064E\u0639\u0650\u064A\u0631\u064B\u0627',
          latin: 'sa\'ir',
          meaning: 'api yang menyala-nyala',
        ),
        VocabItem(
          ayahNumber: 19,
          word:
              '\u0637\u064E\u0628\u064E\u0642\u064B\u0627\u0020\u0639\u064E\u0646\u0020\u0637\u064E\u0628\u064E\u0642\u0656',
          latin: 'thabaqan \'an thabaq',
          meaning: 'tingkat demi tingkat',
        ),
      ],
    ),
    _standardLesson(
      surahId: 83,
      level: 10,
      nameLatin: 'Al-Muthaffifin',
      nameArabic: '\u0627\u0644\u0645\u0637\u0641\u0641\u064A\u0646',
      meaning: 'Orang-orang yang Curang',
      ayahCount: 36,
      overview:
          'Surah ini mengecam keras orang yang meminta takaran penuh tetapi mengurangi saat menakar atau menimbang untuk orang lain.',
      mainMessage:
          'Jujurlah dalam setiap hak manusia, karena semua amal akan dicatat dan dibalas pada hari pembalasan.',
      facts: [
        'Catatan orang durhaka disebut Sijjin, sedangkan catatan orang baik disebut Illiyyin.',
        'Surah ini menggambarkan kenikmatan orang bertakwa yang saling memandang di atas dipan-dipan.',
      ],
      vocabulary: const [
        VocabItem(
          ayahNumber: 1,
          word:
              '\u0644\u0651\u0650\u0644\u06E1\u0645\u064F\u0637\u064E\u0641\u0651\u0650\u0641\u0650\u064A\u0646\u064E',
          latin: 'lil-muthaffifin',
          meaning: 'bagi orang-orang yang curang',
        ),
        VocabItem(
          ayahNumber: 2,
          word:
              '\u064A\u064E\u0633\u06E1\u062A\u064E\u0648\u06E1\u0641\u064F\u0648\u0646\u064E',
          latin: 'yastaufun',
          meaning: 'mereka minta dipenuhi',
        ),
        VocabItem(
          ayahNumber: 7,
          word: '\u0633\u0650\u062C\u0651\u0650\u064A\u0646\u0656',
          latin: 'sijjin',
          meaning: 'catatan atau tempat yang sempit bagi orang durhaka',
        ),
        VocabItem(
          ayahNumber: 18,
          word:
              '\u0639\u0650\u0644\u0651\u0650\u064A\u0651\u0650\u064A\u0646\u064E',
          latin: '\'illiyyin',
          meaning: 'catatan atau tempat yang tinggi bagi orang baik',
        ),
      ],
    ),
    _standardLesson(
      surahId: 82,
      level: 11,
      nameLatin: 'Al-Infitar',
      nameArabic: '\u0627\u0644\u0627\u0646\u0641\u0637\u0627\u0631',
      meaning: 'Terbelah',
      ayahCount: 19,
      overview:
          'Surah ini melukiskan perubahan besar alam pada hari kiamat: langit terbelah, bintang-bintang berjatuhan, dan kubur-kubur dibongkar.',
      mainMessage:
          'Jangan tertipu oleh kelapangan hidup; ingat bahwa setiap amal diawasi dan hari pembalasan pasti datang.',
      facts: [
        'Malaikat pencatat disebut sebagai penjaga yang mulia dan mengetahui apa yang manusia kerjakan.',
        'Surah ini membedakan tempat orang baik dalam kenikmatan dan orang durhaka dalam neraka.',
      ],
      vocabulary: const [
        VocabItem(
          ayahNumber: 1,
          word: '\u0671\u0646\u0641\u064E\u0637\u064E\u0631\u064E\u062A\u06E1',
          latin: 'infatharat',
          meaning: 'terbelah',
        ),
        VocabItem(
          ayahNumber: 4,
          word: '\u0628\u064F\u0639\u06E1\u062B\u0650\u0631\u064E\u062A\u06E1',
          latin: 'bu\'tsirat',
          meaning: 'dibongkar dan dikeluarkan isinya',
        ),
        VocabItem(
          ayahNumber: 10,
          word:
              '\u0644\u064E\u062D\u064E\u0670\u0641\u0650\u0638\u0650\u064A\u0646\u064E',
          latin: 'lahafizhin',
          meaning: 'para penjaga',
        ),
        VocabItem(
          ayahNumber: 17,
          word:
              '\u064A\u064E\u0648\u06E1\u0645\u064F\u0020\u0671\u0644\u062F\u0651\u0650\u064A\u0646\u0650',
          latin: 'yaumud-din',
          meaning: 'hari pembalasan',
        ),
      ],
    ),
    _standardLesson(
      surahId: 81,
      level: 12,
      nameLatin: 'At-Takwir',
      nameArabic: '\u0627\u0644\u062A\u0643\u0648\u064A\u0631',
      meaning: 'Penggulungan',
      ayahCount: 29,
      overview:
          'Surah ini membuka gambaran hari kiamat dengan matahari digulung, bintang-bintang redup, gunung dihancurkan, dan catatan amal dibuka.',
      mainMessage:
          'Persiapkan amal untuk hari ketika setiap jiwa mengetahui apa yang telah dibawanya.',
      facts: [
        'Surah ini mengecam penguburan bayi perempuan hidup-hidup dan menegaskan mereka akan ditanya atas dosa apa dibunuh.',
        'Ayat 19-21 menerangkan bahwa Al-Qur\'an dibawa oleh utusan yang mulia, Jibril.',
      ],
      vocabulary: const [
        VocabItem(
          ayahNumber: 1,
          word: '\u0643\u064F\u0648\u0651\u0650\u0631\u064E\u062A\u06E1',
          latin: 'kuwwirat',
          meaning: 'digulung',
        ),
        VocabItem(
          ayahNumber: 2,
          word: '\u0671\u0646\u0643\u064E\u062F\u064E\u0631\u064E\u062A\u06E1',
          latin: 'inkadarat',
          meaning: 'berjatuhan dan redup',
        ),
        VocabItem(
          ayahNumber: 8,
          word:
              '\u0671\u0644\u06E1\u0645\u064E\u0648\u06E1\u0621\u064F\u06E5\u062F\u064E\u0629\u064F',
          latin: 'al-mau\'udah',
          meaning: 'bayi perempuan yang dikubur hidup-hidup',
        ),
        VocabItem(
          ayahNumber: 14,
          word: '\u0623\u064E\u062D\u06E1\u0636\u064E\u0631\u064E\u062A\u06E1',
          latin: 'ahdharat',
          meaning: 'yang telah dibawanya',
        ),
      ],
    ),
    _standardLesson(
      surahId: 80,
      level: 13,
      nameLatin: 'Abasa',
      nameArabic: '\u0639\u0628\u0633',
      meaning: 'Ia Bermuka Masam',
      ayahCount: 42,
      overview:
          'Surah ini mengajarkan agar tidak mengabaikan pencari ilmu yang tulus, lalu mengingatkan manusia tentang penciptaan, rezeki, dan hari yang memekakkan telinga.',
      mainMessage:
          'Muliakan orang yang sungguh-sungguh mencari petunjuk dan bersyukurlah atas nikmat Allah.',
      facts: [
        'Awal surah berkaitan dengan teguran agar perhatian tidak hanya diberikan kepada tokoh yang merasa cukup.',
        'Surah ini menyebut makanan manusia sebagai tanda rezeki Allah: air diturunkan, bumi dibelah, lalu tanaman ditumbuhkan.',
      ],
      vocabulary: const [
        VocabItem(
          ayahNumber: 1,
          word: '\u0639\u064E\u0628\u064E\u0633\u064E',
          latin: '\'abasa',
          meaning: 'ia bermuka masam',
        ),
        VocabItem(
          ayahNumber: 3,
          word:
              '\u064A\u064E\u0632\u0651\u064E\u0643\u0651\u064E\u0649\u0670\u0653',
          latin: 'yazzakka',
          meaning: 'menyucikan diri',
        ),
        VocabItem(
          ayahNumber: 20,
          word: '\u0671\u0644\u0633\u0651\u064E\u0628\u0650\u064A\u0644\u064E',
          latin: 'as-sabil',
          meaning: 'jalan',
        ),
        VocabItem(
          ayahNumber: 33,
          word:
              '\u0671\u0644\u0635\u0651\u064E\u0627\u0653\u062E\u0651\u064E\u0629\u064F',
          latin: 'ash-shakhkhah',
          meaning: 'suara yang memekakkan telinga',
        ),
      ],
    ),
    _standardLesson(
      surahId: 79,
      level: 14,
      nameLatin: 'An-Nazi\'at',
      nameArabic: '\u0627\u0644\u0646\u0627\u0632\u0639\u0627\u062A',
      meaning: 'Malaikat-malaikat yang Mencabut',
      ayahCount: 46,
      overview:
          'Surah ini menegaskan kepastian kebangkitan, mengisahkan Nabi Musa saat diutus kepada Fir\'aun, lalu membandingkan orang yang melampaui batas dengan orang yang takut kepada Tuhannya.',
      mainMessage:
          'Takutlah kepada perjumpaan dengan Allah dan tahan diri dari hawa nafsu.',
      facts: [
        'Kisah Nabi Musa mengingatkan bahwa Fir\'aun telah melampaui batas dan akhirnya mendapat azab.',
        'Surah ini menyebut neraka sebagai tempat bagi orang yang melampaui batas, sedangkan surga bagi yang menahan hawa nafsu.',
      ],
      vocabulary: const [
        VocabItem(
          ayahNumber: 1,
          word:
              '\u0671\u0644\u0646\u0651\u064E\u0670\u0632\u0650\u0639\u064E\u0670\u062A\u0650',
          latin: 'an-nazi\'at',
          meaning: 'para pencabut',
        ),
        VocabItem(
          ayahNumber: 2,
          word:
              '\u0671\u0644\u0646\u0651\u064E\u0670\u0634\u0650\u0637\u064E\u0670\u062A\u0650',
          latin: 'an-nasyithat',
          meaning: 'para pencabut dengan lemah lembut',
        ),
        VocabItem(
          ayahNumber: 34,
          word:
              '\u0671\u0644\u0637\u0651\u064E\u0627\u0653\u0645\u0651\u064E\u0629\u064F\u0020\u0671\u0644\u06E1\u0643\u064F\u0628\u06E1\u0631\u064E\u0649\u0670',
          latin: 'ath-thammatul-kubra',
          meaning: 'bencana yang sangat besar',
        ),
        VocabItem(
          ayahNumber: 40,
          word: '\u0671\u0644\u06E1\u0647\u064E\u0648\u064E\u0649\u0670',
          latin: 'al-hawa',
          meaning: 'hawa nafsu',
        ),
      ],
    ),
    _standardLesson(
      surahId: 78,
      level: 15,
      nameLatin: 'An-Naba\'',
      nameArabic: '\u0627\u0644\u0646\u0628\u0623',
      meaning: 'Berita Besar',
      ayahCount: 40,
      overview:
          'Surah ini membuka Juz 30 dengan pertanyaan tentang berita besar, yaitu hari kebangkitan yang dahulu diperselisihkan oleh orang-orang musyrik.',
      mainMessage:
          'Percayalah pada kebangkitan dan siapkan amal sebelum datangnya hari keputusan.',
      facts: [
        'Surah ini menyebut banyak tanda kekuasaan Allah: bumi sebagai hamparan, gunung sebagai pasak, tidur untuk istirahat, serta matahari sebagai pelita.',
        'Hari keputusan digambarkan sebagai waktu sangkakala ditiup dan manusia datang berkelompok-kelompok.',
      ],
      vocabulary: const [
        VocabItem(
          ayahNumber: 2,
          word:
              '\u0671\u0644\u0646\u0651\u064E\u0628\u064E\u0625\u0650\u0020\u0671\u0644\u06E1\u0639\u064E\u0638\u0650\u064A\u0645\u0650',
          latin: 'an-naba\' al-\'azhim',
          meaning: 'berita yang besar',
        ),
        VocabItem(
          ayahNumber: 6,
          word: '\u0645\u0650\u0647\u064E\u0670\u062F\u0657\u0627',
          latin: 'mihad',
          meaning: 'hamparan',
        ),
        VocabItem(
          ayahNumber: 13,
          word:
              '\u0633\u0650\u0631\u064E\u0627\u062C\u0657\u0627\u0020\u0648\u064E\u0647\u0651\u064E\u0627\u062C\u0657\u0627',
          latin: 'sirajan wahhajan',
          meaning: 'pelita yang amat terang',
        ),
        VocabItem(
          ayahNumber: 31,
          word: '\u0645\u064E\u0641\u064E\u0627\u0632\u064B\u0627',
          latin: 'mafazan',
          meaning: 'kemenangan atau tempat keberuntungan',
        ),
      ],
    ),
  ];
}
