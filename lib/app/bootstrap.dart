import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/services/hive_service.dart';
import '../firebase_options.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set error handlers FIRST, before anything else can fail
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(details.exceptionAsString(), textAlign: TextAlign.center),
        ),
      ),
    );
  };

  try {
    debugPrint('bootstrap: orientation');
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    debugPrint('bootstrap: system UI');
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    debugPrint('bootstrap: firebase init — starting');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('bootstrap: firebase init — DONE');

    debugPrint('bootstrap: hive init — starting');
    await Hive.initFlutter();
    debugPrint('bootstrap: hive.initFlutter — DONE');
    await HiveService.instance.init();
    debugPrint('bootstrap: HiveService.init — DONE');

    debugPrint('bootstrap: runApp — calling');
    runApp(const ProviderScope(child: VeloraApp()));
    debugPrint('bootstrap: runApp — called');
  } catch (e, st) {
    debugPrint('BOOTSTRAP FAILED: $e');
    debugPrint('STACK:\n$st');
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Bootstrap error: $e'))),
      ),
    );
  }
}
