# Asatidz Input Pages - Complete Documentation

## ✅ PAGES CREATED

### 1. Santri Attendance Page ✅
**File:** `features/asatidz/presentation/pages/santri_attendance_page.dart`

#### Features:
- **Header dengan Gradient Blue** menampilkan jumlah santri hadir
- **List Santri** dengan avatar colorful dan initial
- **Toggle Status** untuk setiap santri:
  - ✅ Hadir (Green)
  - ℹ️ Izin (Orange)
  - 🏥 Sakit (Blue)
  - ❌ Alpha (Red)
- **Submit Button** di bottom dengan loading state
- **Auto-calculate** total hadir/tidak hadir

#### State Management:
- `SantriAttendanceCubit` - Manage attendance state
- `SantriAttendanceState` - States: Initial, Loading, Loaded, Success, Error
- **Attendance Map** - Track status untuk setiap santri

#### UI Components:
```dart
_buildHeader()           // Tampil jumlah hadir
_buildAttendanceList()   // List santri dengan toggle
_buildStatusToggle()     // 4 button status
_buildStatusButton()     // Individual status button
_buildSubmitButton()     // Submit dengan loading
```

---

### 2. Santri Setoran Page ✅
**File:** `features/asatidz/presentation/pages/santri_setoran_page.dart`

#### Features:
- **Header dengan Gradient Purple** menampilkan info santri
- **Form Input:**
  - 📅 Tanggal (auto-filled)
  - 📖 Surah (text input)
  - 🔢 Ayat Awal & Akhir (number input)
  - ⭐ Kualitas Hafalan (3 options: Mantap, Jaryid, Kurang)
  - 📝 Catatan Ustadz (multiline text)
- **Validation** untuk semua required fields
- **Submit Button** floating dengan loading state

#### State Management:
- `SantriSetoranCubit` - Manage setoran submission
- `SantriSetoranState` - States: Initial, Loading, Success, Error

#### UI Components:
```dart
_buildSantriHeader()      // Info santri dengan avatar
_buildDateCard()          // Tanggal setoran
_buildSurahInput()        // Input nama surah
_buildAyatInputs()        // Input ayat awal & akhir
_buildKualitasSelector()  // 3 button kualitas
_buildCatatanInput()      // Catatan multiline
_buildSubmitButton()      // Floating submit button
```

#### Kualitas Options:
- **Mantap** (Green) - Hafalan lancar
- **Jaryid** (Orange) - Perlu perbaikan
- **Kurang** (Red) - Banyak kesalahan

---

### 3. Halaqah Deposit List Page ✅
**File:** `features/asatidz/presentation/pages/halaqah_deposit_list_page.dart`

#### Features:
- **Header dengan Gradient Purple** menampilkan info halaqah
- **List Santri** dengan:
  - Avatar colorful dengan initial
  - Nama santri
  - Status badge "Not Deposited Yet"
  - Arrow icon untuk navigate
- **Tap to Navigate** ke Santri Setoran Page

#### UI Components:
```dart
_buildHeader()        // Info halaqah & schedule
_buildSantriList()    // List semua santri
_buildSantriCard()    // Card untuk setiap santri
```

---

## 🎨 UI DESIGN FEATURES

### Color Scheme:
- **Attendance Page:** Blue gradient header, Orange/Blue/Green/Red status
- **Setoran Page:** Purple gradient header, Green/Orange/Red kualitas
- **Deposit List:** Purple gradient header, Colorful avatars

### Common Design Elements:
1. **Gradient Headers** - Modern dan eye-catching
2. **White Cards** dengan shadow - Clean dan professional
3. **Rounded Corners** - 12-16px radius
4. **Color-coded Avatars** - Easy identification
5. **Loading States** - CircularProgressIndicator
6. **Success/Error Feedback** - SnackBar notifications

---

## 📱 USER FLOW

### Attendance Flow:
```
Dashboard → Quick Action "Attendance"
  ↓
Santri Attendance Page
  ├─ View all santri
  ├─ Toggle status for each (default: hadir)
  └─ Submit attendance
      ├─ Success → Navigate back to dashboard
      └─ Error → Show error message
```

### Setoran Flow:
```
Dashboard → Quick Action "Input Deposit"
  ↓
Halaqah Deposit List Page
  ├─ View all santri in halaqah
  └─ Tap on santri
      ↓
  Santri Setoran Page
    ├─ Fill form (surah, ayat, kualitas, catatan)
    └─ Submit setoran
        ├─ Success → Navigate back to deposit list
        └─ Error → Show error message
```

---

## 🔄 STATE MANAGEMENT

### Santri Attendance Cubit:
```dart
class SantriAttendanceCubit {
  // Initialize dengan semua santri status = 'hadir'
  void init()
  
  // Update status santri tertentu
  void updateAttendance(String santriId, String status)
  
  // Submit attendance ke repository
  Future<void> submitAttendance()
}
```

### Santri Setoran Cubit:
```dart
class SantriSetoranCubit {
  // Submit setoran ke repository
  Future<void> submitSetoran({
    required String surah,
    required int ayatAwal,
    required int ayatAkhir,
    required String kualitasHafalan,
    String catatan,
  })
}
```

---

## 🔗 NAVIGATION

### Dashboard Navigation Updated:
```dart
// Quick Action: Attendance
Navigator.pushNamed(
  context,
  '/asatidz/attendance',
  arguments: activeHalaqah,
);

// Quick Action: Input Deposit
Navigator.pushNamed(
  context,
  '/asatidz/deposit-list',
  arguments: activeHalaqah,
);
```

### Routes Required:
```dart
'/asatidz/attendance'      → SantriAttendancePage
'/asatidz/deposit-list'    → HalaqahDepositListPage
'/asatidz/setoran'         → SantriSetoranPage (from deposit list)
```

---

## ✅ VALIDATION

### Attendance Page:
- ✅ At least one status must be selected (default: all hadir)
- ✅ Cannot submit without active halaqah

### Setoran Page:
- ✅ Surah name required
- ✅ Ayat awal required & must be number
- ✅ Ayat akhir required & must be number
- ✅ Kualitas hafalan required (default: Mantap)
- ⚠️ Catatan optional

---

## 🎯 INTEGRATION POINTS

### Required Dependencies:
```dart
// Cubits
- SantriAttendanceCubit
- SantriSetoranCubit

// Repositories
- AsatidzRepository (already implemented)

// Entities
- ActiveHalaqah
- HalaqahSantri
- SantriAttendance
- SantriSetoran
```

### Data Flow:
```
Page → Cubit → Repository → DataSource → Firestore
  ↓                                          ↓
Success/Error ← State ← Either ← Model ← Document
```

---

## 📊 FIRESTORE OPERATIONS

### Create Attendance:
```dart
await repository.createSantriAttendance(
  halaqahId: activeHalaqah.halaqah.id,
  halaqahName: activeHalaqah.halaqah.name,
  scheduleId: activeHalaqah.schedule.id,
  date: DateTime.now(),
  asatidzId: asatidzId,
  asatidzName: asatidzName,
  attendanceList: [
    SantriAttendanceItem(
      santriId: 'santri1',
      santriName: 'Ali',
      status: 'hadir',
      notes: '',
    ),
    ...
  ],
);
```

### Create Setoran:
```dart
await repository.createSetoran(
  santriId: santri.id,
  santriName: santri.name,
  halaqahId: activeHalaqah.halaqah.id,
  halaqahName: activeHalaqah.halaqah.name,
  asatidzId: asatidzId,
  asatidzName: asatidzName,
  date: DateTime.now(),
  surah: 'Al-Mulk',
  ayatAwal: 1,
  ayatAkhir: 10,
  kualitasHafalan: 'Mantap',
  catatan: 'Bagus, lancar',
);
```

---

## 🚀 NEXT STEPS

### 1. Dependency Injection ❌
Register cubits di injection container:
```dart
// Attendance Cubit
sl.registerFactory(() => SantriAttendanceCubit(
  repository: sl(),
  activeHalaqah: // from args,
  asatidzId: // from auth,
  asatidzName: // from auth,
));

// Setoran Cubit
sl.registerFactory(() => SantriSetoranCubit(
  repository: sl(),
  activeHalaqah: // from args,
  santri: // from args,
  asatidzId: // from auth,
  asatidzName: // from auth,
));
```

### 2. Routing Setup ❌
Add routes to router:
```dart
GoRoute(
  path: '/asatidz/attendance',
  builder: (context, state) {
    final activeHalaqah = state.extra as ActiveHalaqah;
    return BlocProvider(
      create: (_) => sl<SantriAttendanceCubit>()..init(),
      child: SantriAttendancePage(activeHalaqah: activeHalaqah),
    );
  },
),
```

### 3. Auth Integration ❌
Get asatidz ID & name from auth service:
```dart
final user = context.read<AuthCubit>().state.user;
final asatidzId = user.id;
final asatidzName = user.name;
```

### 4. Testing ❌
- Unit tests untuk cubits
- Widget tests untuk pages
- Integration tests untuk full flow

---

## 📝 SUMMARY

**Total Files Created:** 6
- ✅ 3 Pages (Attendance, Setoran, Deposit List)
- ✅ 2 Cubits (Attendance, Setoran)
- ✅ 2 States (Attendance, Setoran)

**Features Implemented:**
- ✅ Input absensi santri dengan 4 status
- ✅ Input setoran hafalan dengan validasi
- ✅ List santri untuk navigate ke setoran
- ✅ Modern UI dengan gradient & shadows
- ✅ Loading states & error handling
- ✅ Navigation dari dashboard

**Ready for:**
- Dependency injection setup
- Routing configuration
- Auth integration
- Production testing
