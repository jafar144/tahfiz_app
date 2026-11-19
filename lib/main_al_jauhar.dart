import 'package:khoirunnasyien/bootstrap.dart';
import 'package:khoirunnasyien/flavors/al_jauhar/app_config.dart';
import 'package:khoirunnasyien/flavors/al_jauhar/presentation/al_jauhar_syahadah_template.dart';

Future<void> main() => bootstrap(
  config: alJauharAppConfig,
  syahadahTemplateBuilder: (data) => AlJauharSyahadahTemplate(data: data),
);
