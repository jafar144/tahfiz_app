import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/utils/kelulusan_share_flow.dart';

void main() {
  test('share dibuka tanpa menunggu penyimpanan selesai', () async {
    final uploadGate = Completer<void>();
    final saveFinished = Completer<void>();
    final events = <String>[];

    final flow = shareKelulusanWhileSaving(
      save: () async {
        events.add('save-start');
        await uploadGate.future;
        events.add('save-finish');
        saveFinished.complete();
      },
      share: () async {
        events.add('share-opened');
      },
    );

    await flow;

    expect(events, ['save-start', 'share-opened']);
    expect(uploadGate.isCompleted, isFalse);

    uploadGate.complete();
    await saveFinished.future;

    expect(events, ['save-start', 'share-opened', 'save-finish']);
  });
}
