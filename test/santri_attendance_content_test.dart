import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/widgets/santri_attendance_content.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

void main() {
  testWidgets('status ketidakhadiran diteruskan dari lembar alasan', (
    tester,
  ) async {
    String? selectedSantriId;
    String? selectedStatus;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SantriAttendanceList(
            santris: [
              SantriEntity(
                id: 'santri-1',
                name: 'Ahmad',
                nis: '1234',
                kelas: 'Tahfiz 1',
                jenisKelamin: 'L',
                isActive: true,
                isFree: false,
                halaqahId: 'halaqah-lain',
              ),
            ],
            attendanceMap: const {'santri-1': 'hadir'},
            activeHalaqahId: 'halaqah-aktif',
            onStatusChanged: (santriId, status) {
              selectedSantriId = santriId;
              selectedStatus = status;
            },
          ),
        ),
      ),
    );

    expect(find.text('Ahmad'), findsOneWidget);
    expect(find.text('Tamu'), findsOneWidget);

    await tester.tap(find.text('Hadir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sakit'));
    await tester.pumpAndSettle();

    expect(selectedSantriId, 'santri-1');
    expect(selectedStatus, 'sakit');
    expect(find.text('Alasan Tidak Hadir'), findsNothing);
  });
}
