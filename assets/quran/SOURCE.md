# Sumber data Quran

`quran.json` berisi teks Al-Qur'an rasm Utsmani (114 surah, 6236 ayat).

- **Sumber:** [quran-json](https://github.com/risan/quran-json) v3.1.2 (teks dari proyek [Tanzil](https://tanzil.net)).
- **Lisensi teks (Tanzil):** boleh dipakai non-komersial dengan atribusi, teks tidak boleh dimodifikasi.

Format (ringkas, Arabic-only):

```json
[
  {
    "id": 1,
    "name": "الفاتحة",
    "latin": "Al-Fatihah",
    "total_verses": 7,
    "verses": ["بِسۡمِ ...", "ٱلۡحَمۡدُ ...", "..."]
  }
]
```

`verses[i]` adalah ayat ke-`i+1`. Untuk memperbarui:

```bash
curl -s "https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/quran.json" \
  | jq -c '[.[] | {id, name, latin: .transliteration, total_verses, verses: [.verses[].text]}]' \
  > assets/quran/quran.json
```
