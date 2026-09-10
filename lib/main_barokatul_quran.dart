import 'package:khoirunnasyien/bootstrap.dart';
import 'package:khoirunnasyien/flavors/barokatul_quran/app_config.dart';
import 'package:khoirunnasyien/flavors/barokatul_quran/presentation/barokatul_quran_syahadah_template.dart';

Future<void> main() => bootstrap(
  config: barokatulQuranAppConfig,
  syahadahTemplateBuilder: (data) => BarokatulQuranSyahadahTemplate(data: data),
);
