import 'package:flutter/material.dart';
import 'package:tahfiz_app/core/di/injection.dart';
import 'package:tahfiz_app/core/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tahfiz_app/core/theme/app_theme.dart';
import 'package:tahfiz_app/firebase_options.dart';
  
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  initDI();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Khoirunnasyien',
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}