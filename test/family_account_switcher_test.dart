import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/family/domain/entities/family_account.dart';
import 'package:khoirunnasyien/features/family/presentation/widgets/family_account_switcher.dart';

void main() {
  testWidgets('akun tunggal tidak menampilkan switcher', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FamilyAccountSwitcher(
            accounts: const [],
            onSwitch: (_) async => null,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('family-account-switcher')), findsNothing);
  });

  testWidgets('switcher menampilkan saudara dan meneruskan akun pilihan', (
    tester,
  ) async {
    String? switchedId;
    const sibling = FamilyAccount(
      id: 'santri-b',
      name: 'Aisyah',
      nis: '002',
      kelas: 'Tahfidz 2',
      jenisKelamin: 'P',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FamilyAccountSwitcher(
            accounts: const [sibling],
            onSwitch: (id) async {
              switchedId = id;
              return null;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('family-account-switcher')));
    await tester.pumpAndSettle();

    expect(find.text('Ganti Akun'), findsOneWidget);
    expect(find.text('Aisyah'), findsOneWidget);
    expect(find.text('NIS: 002 • Tahfidz 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('family-account-santri-b')));
    await tester.pumpAndSettle();

    expect(switchedId, 'santri-b');
    expect(find.text('Ganti Akun'), findsNothing);
  });

  testWidgets('kegagalan switch ditampilkan kepada pengguna', (tester) async {
    const sibling = FamilyAccount(
      id: 'santri-b',
      name: 'Aisyah',
      nis: '002',
      kelas: 'Tahfidz 2',
      jenisKelamin: 'P',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FamilyAccountSwitcher(
            accounts: const [sibling],
            onSwitch: (_) async => 'Gagal mengganti akun.',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('family-account-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('family-account-santri-b')));
    await tester.pumpAndSettle();

    expect(find.text('Gagal mengganti akun.'), findsOneWidget);
  });
}
