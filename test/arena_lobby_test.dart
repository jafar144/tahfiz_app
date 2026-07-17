import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_lobby_cubit.dart';

void main() {
  group('arenaLobbyMonthKeys', () {
    test('hanya menyediakan bulan ini dan bulan lalu', () {
      expect(arenaLobbyMonthKeys(DateTime(2026, 7, 17)), [
        '2026-07',
        '2026-06',
      ]);
    });
  });

  group('currentMonthKey', () {
    test('mengambil bulan berjalan', () {
      expect(currentMonthKey(DateTime(2026, 7, 17)), '2026-07');
    });
  });

  group('previousMonthKey', () {
    test('mengambil bulan sebelum bulan berjalan', () {
      expect(previousMonthKey(DateTime(2026, 7, 17)), '2026-06');
    });

    test('berpindah ke Desember tahun sebelumnya dari Januari', () {
      expect(previousMonthKey(DateTime(2026, 1, 1)), '2025-12');
    });
  });
}
