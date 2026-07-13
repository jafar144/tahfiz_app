import 'package:khoirunnasyien/bootstrap.dart';
import 'package:khoirunnasyien/flavors/khoirunnasyien/app_config.dart';
import 'package:khoirunnasyien/flavors/khoirunnasyien/presentation/khoirunnasyien_syahadah_template.dart';

Future<void> main() => bootstrap(
  config: khoirunnasyienAppConfig,
  syahadahTemplateBuilder: (data) => KhoirunnasyienSyahadahTemplate(data: data),
);
