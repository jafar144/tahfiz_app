import 'package:flutter_test/flutter_test.dart';

import '../tool/check_required_callables.dart';

void main() {
  test('guard mencakup seluruh callable penyimpanan foto kelulusan', () {
    expect(requiredKelulusanCallables, const [
      'checkKelulusanPhoto',
      'reserveKelulusanPhoto',
      'saveKelulusanPhoto',
    ]);
  });

  test('status endpoint callable dibedakan dari service yang hilang', () {
    expect(isCallableEndpointAvailableStatus(200), isTrue);
    expect(isCallableEndpointAvailableStatus(400), isTrue);
    expect(isCallableEndpointAvailableStatus(401), isTrue);
    expect(isCallableEndpointAvailableStatus(403), isTrue);
    expect(isCallableEndpointAvailableStatus(404), isFalse);
    expect(isCallableEndpointAvailableStatus(500), isFalse);
  });

  test('URL callable memakai project dan region milik flavor', () {
    final result = callableEndpoint(
      projectId: 'project-a',
      region: 'asia-southeast2',
      callable: 'checkKelulusanPhoto',
    );

    expect(
      result.toString(),
      'https://asia-southeast2-project-a.cloudfunctions.net/'
      'checkKelulusanPhoto',
    );
  });
}
