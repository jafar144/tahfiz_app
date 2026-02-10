# Database Structure - Asatidz Features

## Collections

### 1. asatidz_attendance (Absensi Asatidz)
```
Collection: asatidz_attendance
Document ID: auto-generated

Fields:
- asatidzId: string (ID pengajar)
- asatidzName: string (Nama pengajar)
- halaqahId: string (ID halaqah)
- halaqahName: string (Nama halaqah)
- scheduleId: string (ID jadwal)
- date: timestamp (Tanggal absen)
- checkInTime: timestamp (Waktu check-in)
- status: string (hadir/izin/sakit)
- notes: string (Catatan optional)
- createdAt: timestamp
```

### 2. santri_attendance (Absensi Santri)
```
Collection: santri_attendance
Document ID: auto-generated

Fields:
- halaqahId: string (ID halaqah)
- halaqahName: string (Nama halaqah)
- scheduleId: string (ID jadwal)
- date: timestamp (Tanggal)
- asatidzId: string (ID pengajar yang input)
- asatidzName: string (Nama pengajar)
- attendanceList: array of objects [
    {
      santriId: string
      santriName: string
      status: string (hadir/izin/sakit/alpha)
      notes: string (optional)
    }
  ]
- totalPresent: number (Jumlah hadir)
- totalAbsent: number (Jumlah tidak hadir)
- createdAt: timestamp
- updatedAt: timestamp
```

### 3. santri_setoran (Setoran Santri)
```
Collection: santri_setoran
Document ID: auto-generated

Fields:
- santriId: string (ID santri)
- santriName: string (Nama santri)
- halaqahId: string (ID halaqah)
- halaqahName: string (Nama halaqah)
- asatidzId: string (ID pengajar)
- asatidzName: string (Nama pengajar)
- date: timestamp (Tanggal setoran)
- surah: string (Nama surah, contoh: "Al-Mulk")
- ayatAwal: number (Ayat awal)
- ayatAkhir: number (Ayat akhir)
- kualitasHafalan: string (Mantap/Jaryid/Kurang)
- catatan: string (Catatan pengajar)
- createdAt: timestamp
```

## Indexes (untuk query optimization)

### asatidz_attendance
- asatidzId + date (untuk cek sudah absen atau belum)
- halaqahId + date (untuk list absensi per halaqah)

### santri_attendance  
- halaqahId + date (untuk cek sudah input atau belum)
- date (untuk laporan harian)

### santri_setoran
- santriId + date (untuk history setoran santri)
- halaqahId + date (untuk list setoran per halaqah)
- asatidzId + date (untuk list setoran yang diinput pengajar)

## Business Logic

### Active Halaqah Detection
```
Halaqah dianggap "aktif" jika:
- Status halaqah = "Active"
- Waktu sekarang dalam range:
  - Mulai: schedule.startTime - 1 jam
  - Selesai: schedule.endTime + 2 jam
- Hari sesuai dengan schedule.day
```

### Validation Rules
1. Asatidz hanya bisa absen 1x per halaqah per hari
2. Asatidz hanya bisa input absensi santri untuk halaqah yang dia ajar
3. Asatidz hanya bisa input setoran untuk santri di halaqah yang dia ajar
4. Setoran bisa multiple per santri per hari (bisa setoran beberapa surah)
