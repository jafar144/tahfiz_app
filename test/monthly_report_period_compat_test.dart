import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/monthly_report/data/models/monthly_report_model.dart';
import 'package:khoirunnasyien/features/monthly_report/data/utils/monthly_report_period_compat.dart';

void main() {
  group('monthly report period compatibility', () {
    test('builds numeric and legacy string query values', () {
      expect(monthlyReportPeriodStorageValues(9), [9, '9']);
    });

    test('parses numeric and legacy string period values', () {
      expect(parseMonthlyReportPeriod(9), 9);
      expect(parseMonthlyReportPeriod(9.0), 9);
      expect(parseMonthlyReportPeriod(' 9 '), 9);
      expect(parseMonthlyReportPeriod('September'), isNull);
      expect(parseMonthlyReportPeriod(0), isNull);
    });

    test('collects matching santri once across mixed storage types', () {
      final result = collectReportedSantriIds(
        [
          {'santri_id': 'santri-1', 'bulan': 8, 'tahun': 2026},
          {'santri_id': 'santri-1', 'bulan': '8', 'tahun': '2026'},
          {'santri_id': 'santri-2', 'bulan': '8', 'tahun': 2026},
          {'santri_id': 'santri-lain', 'bulan': 9, 'tahun': 2026},
          {'santri_id': '', 'bulan': 8, 'tahun': 2026},
        ],
        bulan: 8,
        tahun: 2026,
      );

      expect(result, {'santri-1', 'santri-2'});
    });

    test('monthly report model reads legacy string periods', () {
      final timestamp = Timestamp.fromDate(DateTime(2026, 8, 1));
      final report = MonthlyReportModel.fromMap(
        id: 'report-1',
        data: {
          'bulan': '8',
          'tahun': '2026',
          'created_at': timestamp,
          'updated_at': timestamp,
        },
      );

      expect((report.bulan, report.tahun), (8, 2026));
    });
  });
}
