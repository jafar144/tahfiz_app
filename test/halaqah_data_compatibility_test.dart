import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/management_schedule/data/models/halaqah_model.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/exceptions/halaqah_conflict_exception.dart';

void main() {
  group('HalaqahDocumentCompat', () {
    test('current session_id is authoritative', () {
      final data = <String, dynamic>{
        'session_id': 'sore',
        'schedule_id': 'pagi',
      };

      expect(
        HalaqahDocumentCompat.directlyReferencesSession(data, 'sore'),
        isTrue,
      );
      expect(
        HalaqahDocumentCompat.directlyReferencesSession(data, 'pagi'),
        isFalse,
      );
    });

    test('legacy schedule_id can act as the session reference', () {
      final data = <String, dynamic>{'schedule_id': 'malam'};

      expect(
        HalaqahDocumentCompat.directlyReferencesSession(data, 'malam'),
        isTrue,
      );
      expect(HalaqahDocumentCompat.sessionId(data), 'malam');
      expect(HalaqahDocumentCompat.scheduleIds(data), ['malam']);
    });

    test('reads current schedule_ids and embedded teacher safely', () {
      final data = <String, dynamic>{
        'schedule_ids': ['senin', 'rabu'],
        'asatidz': <Object, Object>{'id': 'teacher-1', 'name': 'Nama Lama'},
      };

      expect(HalaqahDocumentCompat.scheduleIds(data), ['senin', 'rabu']);
      expect(HalaqahDocumentCompat.asatidzData(data), {
        'id': 'teacher-1',
        'name': 'Nama Lama',
      });
    });
  });

  test('conflict exception exposes a clean user-facing message', () {
    const exception = HalaqahConflictException(
      'Pengajar ini sudah memiliki halaqah pada sesi Sore.',
    );

    expect(exception.toString(), exception.message);
    expect(exception.toString(), isNot(startsWith('Exception:')));
  });

  test('current Halaqah writes persist teacher id without embedded name', () {
    const model = HalaqahModel(
      id: '',
      programId: 'sore',
      scheduleIds: ['senin'],
      name: 'Legacy name',
      room: 'Aula',
      teacherId: 'teacher-1',
      teacherName: 'Nama yang hanya untuk tampilan',
      status: 'Active',
    );

    final data = model.toCurrentFirestore(
      santriCount: 2,
      santriIds: const ['santri-1', 'santri-2'],
    );

    expect(data['asatidz'], {'id': 'teacher-1'});
    expect((data['asatidz'] as Map<String, dynamic>), isNot(contains('name')));
    expect(data['name'], 'Legacy name');
    expect(data['santri_count'], 2);
    expect(data['santri_ids'], ['santri-1', 'santri-2']);
  });

  test('distinguishes legacy membership from an authoritative empty list', () {
    expect(HalaqahDocumentCompat.santriIds(const {}), isNull);
    expect(
      HalaqahDocumentCompat.santriIds(const {'santri_ids': <String>[]}),
      isEmpty,
    );
    expect(
      HalaqahDocumentCompat.santriIds(const {
        'santri_ids': [' santri-1 ', '', 'santri-1', 'santri-2'],
      }),
      {'santri-1', 'santri-2'},
    );
  });
}
