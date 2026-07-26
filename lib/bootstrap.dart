import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/notifications/notification_background_handler.dart';
import 'package:khoirunnasyien/core/notifications/notification_service.dart';
import 'package:khoirunnasyien/core/router/app_router.dart';
import 'package:khoirunnasyien/core/theme/app_theme.dart';
import 'package:khoirunnasyien/features/app_config/presentation/cubit/app_config_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/widgets/syahadah_template.dart';

Future<void> bootstrap({
  required AppConfig config,
  required SyahadahTemplateBuilder syahadahTemplateBuilder,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  const firebaseFlavor = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'khoirunnasyien',
  );
  if ((appFlavor != null && appFlavor != config.flavor) ||
      firebaseFlavor != config.flavor) {
    throw StateError(
      'Konfigurasi flavor tidak konsisten: Android=$appFlavor, '
      'entryPoint=${config.flavor}, Firebase=$firebaseFlavor.',
    );
  }

  AppConfig.configure(config);
  SyahadahTemplateRegistry.configure(syahadahTemplateBuilder);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  await Firebase.initializeApp(options: config.firebaseOptionsProvider());
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await initializeDateFormatting('id_ID', null);
  await initDI();
  unawaited(getIt<NotificationService>().init());

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthCubit>()),
        BlocProvider(create: (_) => getIt<AppConfigCubit>()),
      ],
      child: const TahfizApp(),
    ),
  );
}

class TahfizApp extends StatelessWidget {
  const TahfizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.current.appName,
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
