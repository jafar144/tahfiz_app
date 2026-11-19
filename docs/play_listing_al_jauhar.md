# Google Play — isian Al-Jauhar

App Play Console: **Al-Jauhar** (`id.or.aljauhar.tahfiz`), akun developer
JeffDev (sama dengan Khoirunnasyien). Draf ini dasar pengisian "Siapkan
aplikasi" dan listing toko. Jawaban harus sesuai perilaku aplikasi; perbarui
bila fitur berubah.

Internal testing tidak wajib. Karena akun pribadi, produksi mensyaratkan
closed testing minimal 12 penguji selama 14 hari.

## Status pengisian (19 Nov 2026)

| Bagian | Status |
|---|---|
| Kebijakan privasi | Selesai |
| Iklan, Aplikasi pemerintah, Fitur keuangan, Kesehatan | Selesai |
| Keamanan Data | Draf lengkap; kirim setelah Audiens target selesai |
| Kategori | Selesai (Pendidikan) |
| Teks listing (nama, deskripsi singkat & lengkap) | Draf tersimpan |
| Detail login | Menunggu akun demo + kredensial (diisi pemilik) |
| Audiens target | Terkunci sampai Detail login selesai |
| Rating konten | Menunggu email kontak & persetujuan IARC (pemilik), lalu kuesioner |
| Detail kontak listing | Menunggu email publik (pemilik); situs https://lttq-aljauharbdi.com/ |
| Grafis listing | Menunggu upload: ikon, feature graphic, ≥2 screenshot |

## Konten aplikasi

| Bagian | Jawaban |
|---|---|
| Kebijakan privasi | https://al-jauhar-app.web.app/kebijakan-privasi (sudah terisi) |
| Detail login | Semua fungsi memerlukan login. Akun demo santri berisi data contoh (bukan data santri asli); kredensial diketik pemilik akun. |
| Iklan | Tidak berisi iklan |
| ID iklan | Tidak memakai ID iklan (manifest tanpa `AD_ID`) |
| Rating konten | Kategori Referensi/Berita/Edukasi; semua pertanyaan kekerasan, seksual, bahasa, zat, judi = Tidak; pengguna tidak bertukar konten/chat; tidak berbagi lokasi; tidak ada pembelian digital |
| Audiens target | 6–8, 9–12, 13–15, 16–17, 18+ (data 19 Nov 2026: 1 santri ≤5, 23 santri 6–8, 56 santri 9–12, 22 santri 13–15, 3 santri 16–17; wali/asatidz/admin dewasa). Tidak dirancang menarik perhatian anak di luar lembaga; berkomitmen pada Kebijakan Keluarga |
| Aplikasi pemerintah | Tidak |
| Fitur keuangan | Tidak menyediakan fitur keuangan (SPP hanya dicatat admin) |
| Kesehatan | Tidak ada fitur kesehatan |

Catatan: Khoirunnasyien memilih usia 9+; Al-Jauhar memiliki santri 6–8 tahun
sehingga kelompok itu ikut dipilih.

### Keamanan Data

- Mengumpulkan data: **Ya**. Dienkripsi saat transit: **Ya** (HTTPS Firebase).
- Pembuatan akun: nama pengguna + sandi (akun dibuat admin lembaga).
  URL hapus akun: https://al-jauhar-app.web.app/kebijakan-privasi#hapus-akun
- Pengguna dapat meminta penghapusan data: **Ya**.
- Dibagikan ke pihak ketiga: **Tidak** (Firebase/Google dan Groq adalah
  penyedia layanan yang memproses atas nama lembaga).

| Jenis data | Dikumpulkan | Wajib/opsional | Tujuan |
|---|---|---|---|
| Info pribadi — Nama | Ya | Wajib | Fungsi aplikasi, pengelolaan akun |
| Info pribadi — ID pengguna (NIS, UID) | Ya | Wajib | Fungsi aplikasi, pengelolaan akun |
| Info pribadi — Nomor telepon (wali/asatidz) | Ya | Opsional | Fungsi aplikasi |
| Info pribadi — Info lainnya (tanggal/tempat lahir, jenis kelamin, kelas) | Ya | Wajib | Fungsi aplikasi |
| Info keuangan — Info keuangan lainnya (catatan SPP) | Ya | Wajib | Fungsi aplikasi |
| Foto | Ya | Opsional | Fungsi aplikasi |
| Audio — Rekaman suara | Ya, diproses singkat (tidak disimpan) | Opsional | Fungsi aplikasi |
| Aktivitas aplikasi — Interaksi aplikasi (kuis, setoran, absensi) | Ya | Wajib | Fungsi aplikasi |
| ID perangkat atau ID lainnya (token FCM) | Ya | Wajib | Fungsi aplikasi (notifikasi) |

Tidak dikumpulkan: lokasi, kontak, email pribadi, riwayat penjelajahan,
pesan, info kesehatan, log error/diagnostik, ID iklan.

Catatan: listing publik Khoirunnasyien saat ini menyatakan "tidak ada data
dikumpulkan", "data tidak dienkripsi", dan "data tidak dapat dihapus". Itu
tidak sesuai perilaku aplikasi dan sebaiknya dikoreksi memakai tabel ini.

## Listing toko

- Nama aplikasi: `Tahfiz Al-Jauhar`
- Deskripsi singkat (68/80):
  `Aplikasi internal santri, wali, dan asatidz LTTQ Al-Jauhar Palembang`
- Deskripsi lengkap:

```text
Tahfiz Al-Jauhar adalah aplikasi internal Lembaga Pendidikan Tahsin & Tahfizh Al-Qur'an Al Jauhar, Palembang, untuk santri, wali santri, asatidz, dan pengurus lembaga.

Dengan aplikasi ini:
• Santri dan wali dapat memantau perkembangan hafalan, penilaian bulanan, absensi, dan status SPP.
• Asatidz dapat mencatat setoran, menilai perkembangan dan akhlak santri, serta mengisi absensi halaqah.
• Pengurus dapat mengelola data santri, asatidz, pembayaran, dan kelulusan secara rapi dan cepat.
• Santri dapat berlatih hafalan Juz 30 lewat kuis dan latihan yang menyenangkan.
• Pengingat penilaian, pembayaran, dan informasi lembaga dikirim melalui notifikasi.

Akun diberikan oleh pengurus Al-Jauhar; aplikasi ini tidak menyediakan pendaftaran mandiri. Tidak ada iklan dan tidak ada pembelian di dalam aplikasi.

Informasi dan pendaftaran santri: https://lttq-aljauharbdi.com/
```

- Kategori: Aplikasi → **Pendidikan** (sama dengan Khoirunnasyien).
- Kontak: email developer akun JeffDev; situs https://lttq-aljauharbdi.com/;
  telepon opsional.
- Grafis: ikon `store/al_jauhar/play_icon_512.png`, feature graphic
  `store/al_jauhar/feature_graphic_1024x500.png`, screenshot ponsel minimal 2
  (belum ada; ambil dari perangkat setelah login akun demo).
