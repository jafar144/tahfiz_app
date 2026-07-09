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
                question: 'Surah Al-Lail adalah surah ke berapa di Al-Qur\'an?',
                options: ['Ke-90', 'Ke-91', 'Ke-92', 'Ke-93'],
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
                    'Surah Asy-Syams adalah surah ke berapa di Al-Qur\'an?',
                options: ['Ke-89', 'Ke-90', 'Ke-91', 'Ke-92'],
                correctIndex: 2,
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
                    'Surah Al-Balad adalah surah ke berapa di Al-Qur\'an?',
                options: ['Ke-88', 'Ke-89', 'Ke-90', 'Ke-91'],
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
                    'Surah Al-Fajr adalah surah ke berapa di Al-Qur\'an?',
                options: ['Ke-87', 'Ke-88', 'Ke-89', 'Ke-90'],
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
  ];
}
