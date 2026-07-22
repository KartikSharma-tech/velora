import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===========================================================
  // Preferred Orientation
  // ===========================================================

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // ===========================================================
  // System UI
  // ===========================================================

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // ===========================================================
  // Firebase
  // ===========================================================

  // await Firebase.initializeApp();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

  // ===========================================================
  // Hive
  // ===========================================================

  await Hive.initFlutter();

  // ===========================================================
  // Error Handling
  // ===========================================================

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            details.exceptionAsString(),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  // ===========================================================
  // Run App
  // ===========================================================

  runApp(
    const ProviderScope(
      child: VeloraApp(),
    ),
  );
}