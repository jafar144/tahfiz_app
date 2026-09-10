import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';

class SessionSpinHalaqah {
  final Halaqah halaqah;
  final bool isOwn;
  final List<SantriEntity> participants;

  const SessionSpinHalaqah({
    required this.halaqah,
    required this.isOwn,
    required this.participants,
  });
}

class SessionSpinCatalog {
  final String teacherGender;
  final List<SessionSpinHalaqah> halaqahs;

  const SessionSpinCatalog({
    required this.teacherGender,
    required this.halaqahs,
  });
}

class SessionSpinLoader {
  final ScheduleRepository scheduleRepository;
  final AsatidzRepository asatidzRepository;

  const SessionSpinLoader({
    required this.scheduleRepository,
    required this.asatidzRepository,
  });

  Future<SessionSpinCatalog> load(String teacherId) async {
    if (teacherId.trim().isEmpty) {
      throw StateError('Sesi login pengajar tidak ditemukan.');
    }

    // Ketiga request ini tidak saling bergantung sehingga dimulai bersamaan.
    final teacherFuture = asatidzRepository.getAsatidzDetail(teacherId);
    final ownHalaqahsFuture = scheduleRepository.getHalaqahsByTeacher(
      teacherId,
    );
    final allHalaqahsFuture = scheduleRepository.getAllHalaqahs();

    final teacher = await teacherFuture;
    final gender = teacher.jenisKelamin.trim();
    if (gender != 'L' && gender != 'P') {
      throw StateError('Jenis kelamin pengajar belum terisi dengan benar.');
    }
    final programsResult = await scheduleRepository.getPrograms(gender: gender);
    final ownResult = await ownHalaqahsFuture;
    final allResult = await allHalaqahsFuture;

    final programs = programsResult.fold(
      ifLeft: (failure) => throw StateError(failure.message),
      ifRight: (items) => items,
    );
    final ownHalaqahs = ownResult.fold(
      ifLeft: (failure) => throw StateError(failure.message),
      ifRight: (items) => items,
    );
    final allHalaqahs = allResult.fold(
      ifLeft: (failure) => throw StateError(failure.message),
      ifRight: (items) => items,
    );

    final sameGenderProgramIds = programs.map((item) => item.id).toSet();
    final ownIds = ownHalaqahs.map((item) => item.id).toSet();
    final allowedIds = [...ownHalaqahs, ...allHalaqahs]
        .where(
          (halaqah) =>
              halaqah.status.trim().toLowerCase() == 'active' &&
              (ownIds.contains(halaqah.id) ||
                  sameGenderProgramIds.contains(halaqah.programId)),
        )
        .map((item) => item.id)
        .toSet();
    final participantsResult = await scheduleRepository.getSantrisByHalaqahIds(
      allowedIds,
    );
    final participantsByHalaqah = participantsResult.fold(
      ifLeft: (failure) => throw StateError(failure.message),
      ifRight: (items) => items,
    );

    return SessionSpinCatalog(
      teacherGender: gender,
      halaqahs: buildSessionSpinHalaqahs(
        teacherGender: gender,
        ownHalaqahs: ownHalaqahs,
        allHalaqahs: allHalaqahs,
        sameGenderProgramIds: sameGenderProgramIds,
        participantsByHalaqah: participantsByHalaqah,
      ),
    );
  }
}

List<SessionSpinHalaqah> buildSessionSpinHalaqahs({
  required String teacherGender,
  required List<Halaqah> ownHalaqahs,
  required List<Halaqah> allHalaqahs,
  required Set<String> sameGenderProgramIds,
  required Map<String, List<SantriEntity>> participantsByHalaqah,
}) {
  final ownIds = ownHalaqahs.map((item) => item.id).toSet();
  final allowedById = <String, Halaqah>{};
  for (final halaqah in [...ownHalaqahs, ...allHalaqahs]) {
    final isOwn = ownIds.contains(halaqah.id);
    final isSameGender = sameGenderProgramIds.contains(halaqah.programId);
    final isActive = halaqah.status.trim().toLowerCase() == 'active';
    if (isActive && (isOwn || isSameGender)) {
      allowedById.putIfAbsent(halaqah.id, () => halaqah);
    }
  }

  final allowed = allowedById.values.toList()
    ..sort((first, second) {
      final ownOrder = (ownIds.contains(first.id) ? 0 : 1).compareTo(
        ownIds.contains(second.id) ? 0 : 1,
      );
      return ownOrder != 0
          ? ownOrder
          : first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

  return [
    for (final halaqah in allowed)
      SessionSpinHalaqah(
        halaqah: halaqah,
        isOwn: ownIds.contains(halaqah.id),
        participants:
            (participantsByHalaqah[halaqah.id] ?? const [])
                .where(
                  (santri) =>
                      santri.isActive &&
                      (ownIds.contains(halaqah.id) ||
                          santri.jenisKelamin.trim() == teacherGender),
                )
                .toList(growable: false)
              ..sort(
                (first, second) => first.name.toLowerCase().compareTo(
                  second.name.toLowerCase(),
                ),
              ),
      ),
  ];
}
