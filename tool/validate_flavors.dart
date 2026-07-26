import 'dart:convert';
import 'dart:io';

const requiredProperties = <String>[
  'appName',
  'institutionName',
  'applicationId',
  'defaultVersionName',
  'defaultVersionCode',
  'firebaseProjectId',
  'dartEntryPoint',
  'authEmailDomain',
  'paymentBankName',
  'paymentAccountNumber',
  'paymentAccountHolder',
];

const androidDensities = <String>['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];

Map<String, String> readProperties(File file) {
  final result = <String, String>{};
  for (final rawLine in file.readAsLinesSync()) {
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

String normalizedPath(String value) => value.replaceAll('\\', '/');

void main() {
  final root = Directory.current;
  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('Jalankan validator dari root repository.');
    exitCode = 2;
    return;
  }

  final errors = <String>[];
  final configDirectory = Directory('${root.path}/config/flavors');
  final configFiles =
      configDirectory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.properties'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  if (configFiles.isEmpty) {
    errors.add('Tidak ada config/flavors/*.properties.');
  }

  final pubspec = File('${root.path}/pubspec.yaml').readAsStringSync();
  final resolver = File(
    '${root.path}/lib/firebase_options.dart',
  ).readAsStringSync();
  final firebaserc =
      jsonDecode(File('${root.path}/.firebaserc').readAsStringSync())
          as Map<String, dynamic>;
  final firebaseAliases = Map<String, dynamic>.from(
    (firebaserc['projects'] as Map?) ?? const <String, dynamic>{},
  );

  final applicationIds = <String, String>{};
  final firebaseProjects = <String, String>{};

  for (final configFile in configFiles) {
    final flavor = configFile.uri.pathSegments.last.replaceFirst(
      '.properties',
      '',
    );
    final properties = readProperties(configFile);
    final prefix = '[$flavor]';

    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(flavor)) {
      errors.add('$prefix nama flavor tidak valid.');
    }

    for (final key in requiredProperties) {
      if ((properties[key] ?? '').isEmpty) {
        errors.add('$prefix properti $key wajib diisi.');
      }
    }
    if (requiredProperties.any((key) => (properties[key] ?? '').isEmpty)) {
      continue;
    }

    final applicationId = properties['applicationId']!;
    final firebaseProjectId = properties['firebaseProjectId']!;
    final previousApplicationFlavor = applicationIds[applicationId];
    if (previousApplicationFlavor != null) {
      errors.add(
        '$prefix applicationId sama dengan flavor $previousApplicationFlavor.',
      );
    }
    applicationIds[applicationId] = flavor;

    final previousFirebaseFlavor = firebaseProjects[firebaseProjectId];
    if (previousFirebaseFlavor != null) {
      errors.add(
        '$prefix Firebase project sama dengan flavor $previousFirebaseFlavor. '
        'Setiap lembaga wajib memakai project terpisah.',
      );
    }
    firebaseProjects[firebaseProjectId] = flavor;

    if (!RegExp(
      r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$',
    ).hasMatch(applicationId)) {
      errors.add('$prefix applicationId tidak valid: $applicationId');
    }
    if (!RegExp(
      r'^\d+\.\d+\.\d+$',
    ).hasMatch(properties['defaultVersionName']!)) {
      errors.add('$prefix defaultVersionName harus berbentuk x.y.z.');
    }
    if ((int.tryParse(properties['defaultVersionCode']!) ?? 0) < 1) {
      errors.add('$prefix defaultVersionCode harus bilangan positif.');
    }
    if (!RegExp(
      r'^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(properties['authEmailDomain']!)) {
      errors.add('$prefix authEmailDomain tidak valid.');
    }

    final requiredFiles = <String>[
      properties['dartEntryPoint']!,
      'lib/flavors/$flavor/app_config.dart',
      'lib/flavors/$flavor/curriculum.dart',
      'lib/flavors/$flavor/firebase_options.dart',
      'lib/flavors/$flavor/presentation/${flavor}_syahadah_template.dart',
      'assets/flavors/$flavor/images/logo.png',
      'assets/flavors/$flavor/images/logo_bg.png',
      'android/app/src/$flavor/google-services.json',
    ];
    for (final relativePath in requiredFiles) {
      if (!File('${root.path}/$relativePath').existsSync()) {
        errors.add('$prefix file wajib belum ada: $relativePath');
      }
    }

    for (final density in androidDensities) {
      final icon =
          'android/app/src/$flavor/res/mipmap-$density/launcher_icon.png';
      if (!File('${root.path}/$icon').existsSync()) {
        errors.add('$prefix launcher icon belum ada: $icon');
      }
    }

    final assetPath = 'assets/flavors/$flavor/images/';
    if (!pubspec.contains('path: $assetPath') ||
        !RegExp(
          'flavors:\\s*\\n\\s*-\\s*${RegExp.escape(flavor)}',
          multiLine: true,
        ).hasMatch(pubspec)) {
      errors.add('$prefix mapping aset flavor belum ada di pubspec.yaml.');
    }
    if (!resolver.contains("'$flavor' =>")) {
      errors.add('$prefix resolver Firebase background belum didaftarkan.');
    }

    if (firebaseAliases[flavor] != firebaseProjectId) {
      errors.add(
        '$prefix alias .firebaserc harus memetakan $flavor ke '
        '$firebaseProjectId.',
      );
    }

    final appConfigFile = File(
      '${root.path}/lib/flavors/$flavor/app_config.dart',
    );
    if (appConfigFile.existsSync()) {
      final source = appConfigFile.readAsStringSync();
      final expectedLiterals = <String, String>{
        'flavor': flavor,
        'appName': properties['appName']!,
        'institutionName': properties['institutionName']!,
        'authEmailDomain': properties['authEmailDomain']!,
        'bankName': properties['paymentBankName']!,
        'accountNumber': properties['paymentAccountNumber']!,
        'accountHolder': properties['paymentAccountHolder']!,
      };
      for (final entry in expectedLiterals.entries) {
        final pattern = RegExp(
          "${RegExp.escape(entry.key)}:\\s*['\"]"
          '${RegExp.escape(entry.value)}'
          "['\"]",
        );
        if (!pattern.hasMatch(source)) {
          errors.add(
            '$prefix ${entry.key} pada app_config.dart tidak cocok properties.',
          );
        }
      }
    }

    final googleServicesFile = File(
      '${root.path}/android/app/src/$flavor/google-services.json',
    );
    final dartFirebaseFile = File(
      '${root.path}/lib/flavors/$flavor/firebase_options.dart',
    );
    if (googleServicesFile.existsSync()) {
      try {
        final googleServices =
            jsonDecode(googleServicesFile.readAsStringSync())
                as Map<String, dynamic>;
        final projectInfo = Map<String, dynamic>.from(
          googleServices['project_info'] as Map,
        );
        if (projectInfo['project_id'] != firebaseProjectId) {
          errors.add(
            '$prefix project_id google-services.json tidak cocok properties.',
          );
        }

        final clients = (googleServices['client'] as List? ?? const [])
            .cast<Map<String, dynamic>>();
        Map<String, dynamic>? matchingClient;
        for (final client in clients) {
          final info = Map<String, dynamic>.from(client['client_info'] as Map);
          final androidInfo = Map<String, dynamic>.from(
            info['android_client_info'] as Map? ?? const {},
          );
          if (androidInfo['package_name'] == applicationId) {
            matchingClient = client;
            break;
          }
        }
        if (matchingClient == null) {
          errors.add(
            '$prefix google-services.json tidak memiliki client '
            '$applicationId.',
          );
        } else if (dartFirebaseFile.existsSync()) {
          final clientInfo = Map<String, dynamic>.from(
            matchingClient['client_info'] as Map,
          );
          final appId = clientInfo['mobilesdk_app_id']?.toString() ?? '';
          final dartOptions = dartFirebaseFile.readAsStringSync();
          if (!dartOptions.contains("projectId: '$firebaseProjectId'")) {
            errors.add('$prefix projectId firebase_options.dart tidak cocok.');
          }
          if (appId.isNotEmpty && !dartOptions.contains("appId: '$appId'")) {
            errors.add('$prefix appId Firebase Android tidak cocok.');
          }
        }
      } catch (error) {
        errors.add('$prefix google-services.json tidak valid: $error');
      }
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('Validasi flavor gagal (${errors.length} masalah):');
    for (final error in errors) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
    return;
  }

  final names = configFiles
      .map(
        (file) => normalizedPath(
          file.path,
        ).split('/').last.replaceAll('.properties', ''),
      )
      .join(', ');
  stdout.writeln('Semua flavor valid dan terisolasi: $names');
}
