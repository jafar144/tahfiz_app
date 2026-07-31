import 'dart:convert';
import 'dart:io';

const requiredKelulusanCallables = <String>[
  'checkKelulusanPhoto',
  'reserveKelulusanPhoto',
  'saveKelulusanPhoto',
];

Future<void> main(List<String> arguments) async {
  final flavor = _argumentValue(arguments, '--flavor');
  if (flavor == null || !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(flavor)) {
    stderr.writeln('Gunakan --flavor <nama_flavor>.');
    exitCode = 64;
    return;
  }

  final configFile = File('config/flavors/$flavor.properties');
  if (!configFile.existsSync()) {
    stderr.writeln('Konfigurasi flavor tidak ditemukan: ${configFile.path}');
    exitCode = 66;
    return;
  }

  final properties = parseFlavorProperties(configFile.readAsLinesSync());
  final projectId = properties['firebaseProjectId']?.trim() ?? '';
  final region = properties['functionsRegion']?.trim() ?? '';
  if (projectId.isEmpty || region.isEmpty) {
    stderr.writeln(
      'firebaseProjectId/functionsRegion belum lengkap untuk flavor $flavor.',
    );
    exitCode = 78;
    return;
  }

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  final failures = <String>[];
  try {
    for (final callable in requiredKelulusanCallables) {
      final endpoint = callableEndpoint(
        projectId: projectId,
        region: region,
        callable: callable,
      );
      final result = await probeCallable(client, endpoint);
      if (result.available) {
        stdout.writeln('OK $callable (HTTP ${result.statusCode})');
      } else {
        failures.add('$callable: ${result.description}');
      }
    }
  } finally {
    client.close(force: true);
  }

  if (failures.isEmpty) return;
  stderr.writeln(
    'Release dihentikan: backend Foto Kelulusan belum siap di $projectId.',
  );
  for (final failure in failures) {
    stderr.writeln('- $failure');
  }
  exitCode = 1;
}

Map<String, String> parseFlavorProperties(Iterable<String> lines) {
  final result = <String, String>{};
  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final separator = line.indexOf('=');
    if (separator <= 0) continue;
    result[line.substring(0, separator).trim()] = line
        .substring(separator + 1)
        .trim();
  }
  return result;
}

Uri callableEndpoint({
  required String projectId,
  required String region,
  required String callable,
}) {
  return Uri.https('$region-$projectId.cloudfunctions.net', '/$callable');
}

Future<CallableProbeResult> probeCallable(
  HttpClient client,
  Uri endpoint, {
  int maxAttempts = 3,
}) async {
  Object? lastError;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final request = await client.postUrl(endpoint);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(const {'data': <String, Object?>{}}));
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final statusCode = response.statusCode;
      await response.drain<void>();

      if (isCallableEndpointAvailableStatus(statusCode)) {
        return CallableProbeResult.available(statusCode);
      }
      if (statusCode == HttpStatus.notFound) {
        return const CallableProbeResult.missing();
      }
      lastError = 'HTTP $statusCode';
    } on Object catch (error) {
      lastError = error;
    }
  }
  return CallableProbeResult.failed(lastError?.toString() ?? 'unknown error');
}

bool isCallableEndpointAvailableStatus(int statusCode) {
  // Tanpa token, callable yang ada normalnya membalas 400/401/403. Yang perlu
  // dibedakan di sini adalah 404 gateway saat service belum pernah dideploy.
  return statusCode >= 200 && statusCode < 500 && statusCode != 404;
}

String? _argumentValue(List<String> arguments, String name) {
  final index = arguments.indexOf(name);
  if (index < 0 || index + 1 >= arguments.length) return null;
  return arguments[index + 1];
}

class CallableProbeResult {
  final bool available;
  final int? statusCode;
  final String description;

  const CallableProbeResult._({
    required this.available,
    required this.statusCode,
    required this.description,
  });

  const CallableProbeResult.available(int statusCode)
    : this._(available: true, statusCode: statusCode, description: 'tersedia');

  const CallableProbeResult.missing()
    : this._(
        available: false,
        statusCode: HttpStatus.notFound,
        description: 'endpoint tidak ditemukan (HTTP 404)',
      );

  const CallableProbeResult.failed(String reason)
    : this._(
        available: false,
        statusCode: null,
        description: 'gagal diverifikasi ($reason)',
      );
}
