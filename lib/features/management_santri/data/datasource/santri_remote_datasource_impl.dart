import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/features/management_santri/data/datasource/santri_remote_datasource.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_page_result.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';

class SantriRemoteDataSourceImpl implements SantriRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  SantriRemoteDataSourceImpl(this.firestore, this.functions);

  static String _dateOnly(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}';
  }

  /// Status gratis santri. Sumber utama adalah `free_until` (tanggal berakhir
  /// masa gratis). Untuk data lama yang belum dimigrasi (free_until belum
  /// di-set), fallback ke field legacy `is_free` (boolean). Tanpa fallback ini
  /// santri gratis lama akan dianggap reguler.
  static bool _isFreeFromData(Map<String, dynamic> data) {
    final freeUntil = (data['free_until'] as Timestamp?)?.toDate();
    if (freeUntil != null) return freeUntil.isAfter(DateTime.now());
    return data['is_free'] == true;
  }

  static String? _fiqihClassFromData(Map<String, dynamic> data) {
    final value = data['kelas_fiqih'];
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  static String? _normalizedFiqihClass(SantriParams params) => AppConfig
      .current
      .curriculum
      .normalizeFiqihClass(params.kelas, params.kelasFiqih);

  @override
  Future<SantriPageResult> getSantriPage({
    String? keyword,
    bool? isActive,
    String? gender,
    String? session,
    String? kelas,
    String? asatidzId,
    bool? isFree,
    bool? hasPhoto,
    bool? hasHalaqah,
    SantriSortBy sortBy = SantriSortBy.name,
    int limit = 10,
  }) async {
    // Filter pengajar merupakan join melalui koleksi halaqah. Jalur existing
    // memang mengambil seluruh kandidat, jadi total dapat digunakan tanpa
    // query tambahan.
    if (asatidzId != null) {
      final allMatches = await getSantriList(
        keyword: keyword,
        isActive: isActive,
        gender: gender,
        session: session,
        kelas: kelas,
        asatidzId: asatidzId,
        isFree: isFree,
        hasPhoto: hasPhoto,
        hasHalaqah: hasHalaqah,
        sortBy: sortBy,
        limit: limit,
      );
      return SantriPageResult(items: allMatches, totalCount: allMatches.length);
    }

    final normalizedKeyword = keyword?.trim().toLowerCase() ?? '';
    final requiresClientEvaluation =
        normalizedKeyword.isNotEmpty ||
        isFree != null ||
        hasPhoto != null ||
        hasHalaqah != null;

    // Substring search serta filter presence/status kompatibilitas tidak dapat
    // dihitung akurat oleh satu aggregate query Firestore. Scan kandidat satu
    // kali, gunakan hasil yang sama untuk list dan total, lalu hentikan
    // pagination agar dokumen tersebut tidak dibaca ulang.
    if (requiresClientEvaluation) {
      final allMatches = await _fetchAllClientEvaluated(
        keyword: keyword,
        isActive: isActive,
        gender: gender,
        session: session,
        kelas: kelas,
        isFree: isFree,
        hasPhoto: hasPhoto,
        hasHalaqah: hasHalaqah,
        sortBy: sortBy,
      );
      return SantriPageResult(items: allMatches, totalCount: allMatches.length);
    }

    final query = _buildSantriQuery(
      isActive: isActive,
      gender: gender,
      session: session,
      kelas: kelas,
    ).orderBy(sortBy == SantriSortBy.nis ? 'nis' : 'name');

    try {
      final snapshot = await query.limit(limit).get();
      final aggregate = await query.count().get();
      return SantriPageResult(
        items: snapshot.docs.map(_entityFromSnapshot).toList(),
        totalCount: aggregate.count ?? 0,
      );
    } on FirebaseException catch (error) {
      final isMissingNisIndex =
          error.code == 'failed-precondition' && sortBy == SantriSortBy.nis;
      if (!isMissingNisIndex) rethrow;

      // Fallback sementara selama composite index NIS belum tersedia. Karena
      // seluruh kandidat sudah harus dibaca untuk sorting global, kembalikan
      // semuanya sekaligus agar total eksak dan tidak ada scan berulang.
      final allMatches = await _fetchAllNisSortedWithNameIndex(
        keyword: keyword,
        isActive: isActive,
        gender: gender,
        session: session,
        kelas: kelas,
        isFree: isFree,
        hasPhoto: hasPhoto,
        hasHalaqah: hasHalaqah,
      );
      return SantriPageResult(items: allMatches, totalCount: allMatches.length);
    }
  }

  @override
  Future<List<SantriEntity>> getSantriList({
    String? keyword,
    bool? isActive,
    String? gender,
    String? session,
    String? kelas,
    String? asatidzId,
    bool? isFree,
    bool? hasPhoto,
    bool? hasHalaqah,
    SantriSortBy sortBy = SantriSortBy.name,
    int limit = 10,
    String? lastDocumentId,
  }) async {
    try {
      if (asatidzId != null) {
        final halaqahsSnapshot = await firestore
            .collection('halaqahs')
            .where('asatidz.id', isEqualTo: asatidzId)
            .get();

        final halaqahIds = halaqahsSnapshot.docs.map((doc) => doc.id).toList();
        if (halaqahIds.isEmpty) return [];

        final allSantri = <SantriEntity>[];

        for (var i = 0; i < halaqahIds.length; i += 10) {
          final end = (i + 10 < halaqahIds.length) ? i + 10 : halaqahIds.length;
          final chunk = halaqahIds.sublist(i, end);

          Query<Map<String, dynamic>> query = firestore
              .collection('santri_profiles')
              .where('halaqah_id', whereIn: chunk);

          if (isActive != null) {
            query = query.where('is_active', isEqualTo: isActive);
          }
          if (gender != null) {
            query = query.where('jenis_kelamin', isEqualTo: gender);
          }
          if (session != null) {
            query = query.where('tipe_kelas', isEqualTo: session);
          }
          if (kelas != null) query = query.where('kelas', isEqualTo: kelas);

          final snapshot = await query.get();
          allSantri.addAll(snapshot.docs.map(_entityFromSnapshot));
        }

        final normalizedKeyword = keyword?.trim().toLowerCase() ?? '';
        final result = allSantri.where((santri) {
          final matchesKeyword =
              normalizedKeyword.isEmpty ||
              santri.name.toLowerCase().contains(normalizedKeyword) ||
              santri.nis.toLowerCase().contains(normalizedKeyword);
          return matchesKeyword &&
              _matchesClientFilters(
                santri,
                isFree: isFree,
                hasPhoto: hasPhoto,
                hasHalaqah: hasHalaqah,
              );
        }).toList()..sort((a, b) => _compareSantri(a, b, sortBy));

        return result;
      }

      Query<Map<String, dynamic>> query = _buildSantriQuery(
        isActive: isActive,
        gender: gender,
        session: session,
        kelas: kelas,
      ).orderBy(sortBy == SantriSortBy.nis ? 'nis' : 'name');

      // Firestore tidak mendukung pencarian substring. Saat ada keyword, ambil
      // seluruh kandidat lalu selesaikan pencarian di client.
      final normalizedKeyword = keyword?.trim().toLowerCase() ?? '';
      if (normalizedKeyword.isNotEmpty) {
        final snapshot = await query.get();
        return snapshot.docs.map(_entityFromSnapshot).where((santri) {
          final matchesKeyword =
              santri.name.toLowerCase().contains(normalizedKeyword) ||
              santri.nis.toLowerCase().contains(normalizedKeyword);
          return matchesKeyword &&
              _matchesClientFilters(
                santri,
                isFree: isFree,
                hasPhoto: hasPhoto,
                hasHalaqah: hasHalaqah,
              );
        }).toList();
      }

      // Status gratis serta keberadaan field foto/halaqah diselesaikan di
      // client. Dokumen lama dapat benar-benar tidak memiliki field tersebut.
      if (isFree != null || hasPhoto != null || hasHalaqah != null) {
        return _fetchWithClientFilters(
          baseQuery: query,
          isFree: isFree,
          hasPhoto: hasPhoto,
          hasHalaqah: hasHalaqah,
          limit: limit,
          lastDocumentId: lastDocumentId,
        );
      }

      if (lastDocumentId != null) {
        final lastDoc = await firestore
            .collection('santri_profiles')
            .doc(lastDocumentId)
            .get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map(_entityFromSnapshot).toList();
    } on FirebaseException catch (error) {
      final isMissingNisIndex =
          error.code == 'failed-precondition' &&
          sortBy == SantriSortBy.nis &&
          asatidzId == null;
      if (!isMissingNisIndex) rethrow;

      return _fetchNisSortedWithNameIndex(
        keyword: keyword,
        isActive: isActive,
        gender: gender,
        session: session,
        kelas: kelas,
        isFree: isFree,
        hasPhoto: hasPhoto,
        hasHalaqah: hasHalaqah,
        limit: limit,
        lastDocumentId: lastDocumentId,
      );
    }
  }

  Query<Map<String, dynamic>> _buildSantriQuery({
    bool? isActive,
    String? gender,
    String? session,
    String? kelas,
  }) {
    Query<Map<String, dynamic>> query = firestore.collection('santri_profiles');
    if (isActive != null) {
      query = query.where('is_active', isEqualTo: isActive);
    }
    if (gender != null) {
      query = query.where('jenis_kelamin', isEqualTo: gender);
    }
    if (session != null) {
      query = query.where('tipe_kelas', isEqualTo: session);
    }
    if (kelas != null) {
      query = query.where('kelas', isEqualTo: kelas);
    }
    return query;
  }

  Future<List<SantriEntity>> _fetchAllClientEvaluated({
    String? keyword,
    bool? isActive,
    String? gender,
    String? session,
    String? kelas,
    bool? isFree,
    bool? hasPhoto,
    bool? hasHalaqah,
    required SantriSortBy sortBy,
  }) async {
    final query = _buildSantriQuery(
      isActive: isActive,
      gender: gender,
      session: session,
      kelas: kelas,
    ).orderBy(sortBy == SantriSortBy.nis ? 'nis' : 'name');

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await query.get();
    } on FirebaseException catch (error) {
      final isMissingNisIndex =
          error.code == 'failed-precondition' && sortBy == SantriSortBy.nis;
      if (!isMissingNisIndex) rethrow;

      return _fetchAllNisSortedWithNameIndex(
        keyword: keyword,
        isActive: isActive,
        gender: gender,
        session: session,
        kelas: kelas,
        isFree: isFree,
        hasPhoto: hasPhoto,
        hasHalaqah: hasHalaqah,
      );
    }

    final normalizedKeyword = keyword?.trim().toLowerCase() ?? '';
    return snapshot.docs.map(_entityFromSnapshot).where((santri) {
      final matchesKeyword =
          normalizedKeyword.isEmpty ||
          santri.name.toLowerCase().contains(normalizedKeyword) ||
          santri.nis.toLowerCase().contains(normalizedKeyword);
      return matchesKeyword &&
          _matchesClientFilters(
            santri,
            isFree: isFree,
            hasPhoto: hasPhoto,
            hasHalaqah: hasHalaqah,
          );
    }).toList()..sort((a, b) => _compareSantri(a, b, sortBy));
  }

  /// Jalur kompatibilitas sementara saat composite index NIS masih dibangun.
  ///
  /// Query memakai index `name` lama yang sudah digunakan halaman ini, lalu
  /// mengurutkan seluruh kandidat berdasarkan NIS sebelum menerapkan pagination.
  Future<List<SantriEntity>> _fetchNisSortedWithNameIndex({
    String? keyword,
    bool? isActive,
    String? gender,
    String? session,
    String? kelas,
    bool? isFree,
    bool? hasPhoto,
    bool? hasHalaqah,
    required int limit,
    String? lastDocumentId,
  }) async {
    final allMatches = await _fetchAllNisSortedWithNameIndex(
      keyword: keyword,
      isActive: isActive,
      gender: gender,
      session: session,
      kelas: kelas,
      isFree: isFree,
      hasPhoto: hasPhoto,
      hasHalaqah: hasHalaqah,
    );

    final normalizedKeyword = keyword?.trim().toLowerCase() ?? '';

    // Pencarian memang dikembalikan lengkap karena Cubit menonaktifkan
    // pagination ketika keyword aktif.
    if (normalizedKeyword.isNotEmpty) return allMatches;

    var startIndex = 0;
    if (lastDocumentId != null) {
      final lastIndex = allMatches.indexWhere(
        (santri) => santri.id == lastDocumentId,
      );
      if (lastIndex >= 0) startIndex = lastIndex + 1;
    }

    if (startIndex >= allMatches.length) return [];
    final endIndex = (startIndex + limit).clamp(0, allMatches.length);
    return allMatches.sublist(startIndex, endIndex);
  }

  Future<List<SantriEntity>> _fetchAllNisSortedWithNameIndex({
    String? keyword,
    bool? isActive,
    String? gender,
    String? session,
    String? kelas,
    bool? isFree,
    bool? hasPhoto,
    bool? hasHalaqah,
  }) async {
    final snapshot = await _buildSantriQuery(
      isActive: isActive,
      gender: gender,
      session: session,
      kelas: kelas,
    ).orderBy('name').get();

    final normalizedKeyword = keyword?.trim().toLowerCase() ?? '';
    final allMatches = snapshot.docs.map(_entityFromSnapshot).where((santri) {
      final matchesKeyword =
          normalizedKeyword.isEmpty ||
          santri.name.toLowerCase().contains(normalizedKeyword) ||
          santri.nis.toLowerCase().contains(normalizedKeyword);
      return matchesKeyword &&
          _matchesClientFilters(
            santri,
            isFree: isFree,
            hasPhoto: hasPhoto,
            hasHalaqah: hasHalaqah,
          );
    }).toList()..sort((a, b) => _compareSantri(a, b, SantriSortBy.nis));
    return allMatches;
  }

  Future<List<SantriEntity>> _fetchWithClientFilters({
    required Query<Map<String, dynamic>> baseQuery,
    bool? isFree,
    bool? hasPhoto,
    bool? hasHalaqah,
    required int limit,
    String? lastDocumentId,
  }) async {
    final result = <SantriEntity>[];
    DocumentSnapshot<Map<String, dynamic>>? lastDoc;
    const int batchSize = 50;

    if (lastDocumentId != null) {
      final snap = await firestore
          .collection('santri_profiles')
          .doc(lastDocumentId)
          .get();
      if (snap.exists) lastDoc = snap;
    }

    while (result.length < limit) {
      Query<Map<String, dynamic>> q = baseQuery.limit(batchSize);
      if (lastDoc != null) q = q.startAfterDocument(lastDoc);

      final snapshot = await q.get();
      if (snapshot.docs.isEmpty) break;

      for (final doc in snapshot.docs) {
        final santri = _entityFromSnapshot(doc);
        if (_matchesClientFilters(
          santri,
          isFree: isFree,
          hasPhoto: hasPhoto,
          hasHalaqah: hasHalaqah,
        )) {
          result.add(santri);
          if (result.length >= limit) break;
        }
      }

      if (snapshot.docs.length < batchSize) break;
      lastDoc = snapshot.docs.last;
    }

    return result;
  }

  static SantriEntity _entityFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final freeUntil = (data['free_until'] as Timestamp?)?.toDate();
    return SantriEntity(
      id: doc.id,
      name: data['name'] as String? ?? '',
      nis: data['nis']?.toString() ?? '',
      kelas: data['kelas'] as String? ?? '',
      kelasFiqih: _fiqihClassFromData(data),
      jenisKelamin: data['jenis_kelamin'] as String? ?? '',
      isActive: data['is_active'] as bool? ?? true,
      isFree: _isFreeFromData(data),
      freeUntil: freeUntil,
      nomorWali: data['nomor_wali'] as String?,
      tipeKelas: data['tipe_kelas'] as String?,
      halaqahId: data['halaqah_id'] as String?,
      tanggalMasuk: (data['tanggal_masuk'] as Timestamp?)?.toDate(),
      photoUrl: data['photo_url'] as String?,
    );
  }

  static bool _matchesClientFilters(
    SantriEntity santri, {
    bool? isFree,
    bool? hasPhoto,
    bool? hasHalaqah,
  }) {
    return (isFree == null || santri.isFree == isFree) &&
        (hasPhoto == null || santri.hasProfilePhoto == hasPhoto) &&
        (hasHalaqah == null || santri.hasHalaqah == hasHalaqah);
  }

  static int _compareSantri(
    SantriEntity first,
    SantriEntity second,
    SantriSortBy sortBy,
  ) {
    final comparison = switch (sortBy) {
      SantriSortBy.nis => first.nis.compareTo(second.nis),
      SantriSortBy.name => first.name.toLowerCase().compareTo(
        second.name.toLowerCase(),
      ),
    };
    return comparison != 0 ? comparison : first.id.compareTo(second.id);
  }

  @override
  Future<SantriDetail> getSantriDetail(String id) async {
    final doc = await firestore.collection('santri_profiles').doc(id).get();
    final userDoc = await firestore.collection('users').doc(id).get();

    if (!doc.exists) {
      throw Exception('Data santri tidak ditemukan');
    }

    final data = doc.data() as Map<String, dynamic>;
    final userData = userDoc.exists
        ? userDoc.data() as Map<String, dynamic>
        : <String, dynamic>{};

    final freeUntil = (data['free_until'] as Timestamp?)?.toDate();
    final isFree = _isFreeFromData(data);

    return SantriDetail(
      id: doc.id,
      name: data['name'] ?? '',
      nis: data['nis'] ?? '',
      kelas: data['kelas'] ?? '',
      kelasFiqih: _fiqihClassFromData(data),
      jenisKelamin: data['jenis_kelamin'] ?? '',
      isActive: data['is_active'] ?? true,
      isFree: isFree,
      freeUntil: freeUntil,
      namaWali: data['nama_wali'],
      nomorWali: data['nomor_wali'],
      tanggalMasuk: (data['tanggal_masuk'] as Timestamp?)?.toDate(),
      tanggalLahir: (data['tanggal_lahir'] as Timestamp?)?.toDate(),
      tempatLahir: data['tempat_lahir'],
      tipeKelas: data['tipe_kelas'],
      phone: userData['phone'],
      halaqahId: data['halaqah_id'],
      photoUrl: data['photo_url'],
    );
  }

  @override
  Future<String> addSantri(SantriParams params) async {
    final kelasFiqih = _normalizedFiqihClass(params);
    final fallbackFreeUntil = DateTime(
      DateTime.now().year + 7,
      DateTime.now().month,
      DateTime.now().day,
    );
    final result = await functions
        .httpsCallable('provisionInstitutionUser')
        .call(<String, dynamic>{
          'role': 'santri',
          'name': params.name,
          'nis': params.nis,
          'phone': params.phone,
          'jenisKelamin': params.jenisKelamin,
          'isActive': params.isActive,
          'birthPlace': params.birthPlace,
          'birthDate': _dateOnly(params.birthDate),
          'waliName': params.waliName,
          'waliPhone': params.waliPhone,
          'kelas': params.kelas,
          'kelasFiqih': ?kelasFiqih,
          'tipeKelas': params.tipeKelas,
          'entryDate': _dateOnly(params.entryDate),
          'isFree': params.isFree,
          if (params.isFree)
            'freeUntil': _dateOnly(params.freeUntil ?? fallbackFreeUntil),
          if (params.photoUrl != null) 'photoUrl': params.photoUrl,
        });
    final data = Map<String, dynamic>.from(result.data as Map);
    final password = (data['temporaryPassword'] as String?)?.trim() ?? '';
    if (password.isEmpty) {
      throw StateError('Server tidak mengembalikan password sementara.');
    }
    return password;
  }

  @override
  Future<void> updateSantri(String id, SantriParams params) async {
    final docRef = firestore.collection('santri_profiles').doc(id);
    final kelasFiqih = _normalizedFiqihClass(params);

    // Catat kapan santri keluar untuk laporan mutasi. tanggal_keluar hanya
    // di-set saat transisi aktif → nonaktif (bukan tiap edit), dan dihapus
    // kembali bila santri diaktifkan ulang.
    final snap = await docRef.get();
    final wasActive = (snap.data()?['is_active'] as bool?) ?? true;

    // Update Santri Profile
    await docRef.update({
      'name': params.name,
      'nis': params.nis,
      'kelas': params.kelas,
      'kelas_fiqih': kelasFiqih ?? FieldValue.delete(),
      'jenis_kelamin': params.jenisKelamin,
      'is_active': params.isActive,
      'free_until': params.isFree
          ? Timestamp.fromDate(
              params.freeUntil ??
                  DateTime(
                    DateTime.now().year + 7,
                    DateTime.now().month,
                    DateTime.now().day,
                  ),
            )
          : null,
      'is_free': FieldValue.delete(), // Ensure old field is removed if present
      'nama_wali': params.waliName,
      'nomor_wali': params.waliPhone,
      'tanggal_masuk': Timestamp.fromDate(params.entryDate),
      'tanggal_lahir': Timestamp.fromDate(params.birthDate),
      'tempat_lahir': params.birthPlace,
      'tipe_kelas': params.tipeKelas,
      if (!params.isActive && wasActive)
        'tanggal_keluar': FieldValue.serverTimestamp()
      else if (params.isActive && !wasActive)
        'tanggal_keluar': FieldValue.delete(),
      if (params.photoUrl != null)
        'photo_url': params.photoUrl
      else if (params.removePhoto)
        'photo_url': FieldValue.delete(),
    });

    // Update User Document
    await firestore.collection('users').doc(id).update({
      'name': params.name,
      'phone': params.phone,
      'nis': params.nis,
    });
  }

  @override
  Future<String> getNextNis() async {
    // NIS menjadi bagian email Firebase Auth dan karena itu unik lintas role.
    // Hitung dari santri serta asatidz agar kedua form tidak menawarkan nomor
    // yang sama ketika akun terakhir yang dibuat berasal dari role berbeda.
    final snapshots = await Future.wait([
      firestore.collection('santri_profiles').get(),
      firestore.collection('asatidz_profiles').get(),
    ]);
    // Mulai dari 1000 agar pengguna pertama mendapat 1001 saat data kosong.
    int maxNis = 1000;
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        final s = (doc.data()['nis'] ?? '').toString().trim();
        final n = int.tryParse(s) ?? double.tryParse(s)?.toInt();
        if (n != null && n > maxNis) maxNis = n;
      }
    }
    return (maxNis + 1).toString();
  }

  @override
  Future<bool> isNisTaken(String nis) async {
    final results = await Future.wait([
      firestore
          .collection('santri_profiles')
          .where('nis', isEqualTo: nis)
          .limit(1)
          .get(),
      firestore
          .collection('asatidz_profiles')
          .where('nis', isEqualTo: nis)
          .limit(1)
          .get(),
    ]);
    return results.any((query) => query.docs.isNotEmpty);
  }

  @override
  Future<List<SantriEntity>> getSantriByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final List<SantriEntity> allSantris = [];

    // Firestore whereIn supports max 10 items
    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 < ids.length) ? i + 10 : ids.length;
      final chunk = ids.sublist(i, end);

      final snapshot = await firestore
          .collection('santri_profiles')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        final freeUntil = (data['free_until'] as Timestamp?)?.toDate();
        final isFree = _isFreeFromData(data);

        return SantriEntity(
          id: doc.id,
          name: data['name'] ?? '',
          nis: data['nis'] ?? '',
          kelas: data['kelas'] ?? '',
          kelasFiqih: _fiqihClassFromData(data),
          jenisKelamin: data['jenis_kelamin'] ?? '',
          isActive: data['is_active'] ?? true,
          isFree: isFree,
          freeUntil: freeUntil,
          nomorWali: data['nomor_wali'],
          pembimbing: null,
          tipeKelas: data['tipe_kelas'],
          tanggalMasuk: (data['tanggal_masuk'] as Timestamp?)?.toDate(),
          halaqahId: data['halaqah_id'],
          photoUrl: data['photo_url'],
        );
      }).toList();

      allSantris.addAll(items);
    }

    return allSantris;
  }

  @override
  Future<List<AsatidzEntity>> getAsatidzList() async {
    final snapshot = await firestore
        .collection('asatidz_profiles')
        .where('is_active', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AsatidzEntity(
        id: doc.id,
        name: data['name'] ?? '',
        nis: data['nis'] ?? '',
        jenisKelamin: data['jenis_kelamin'] ?? '',
        isActive: data['is_active'] ?? true,
        photoUrl: data['photo_url'],
      );
    }).toList();
  }
}
