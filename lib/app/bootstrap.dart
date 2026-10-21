import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/services/hive_service.dart';
import '../core/services/notification_service.dart';
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
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
      } catch (e, st) {
        // Protected backend calls reject requests without a valid App Check token.
        debugPrint('App Check initialization failed: $e\n$st');
      }
    }
    debugPrint('bootstrap: firebase init — DONE');

    debugPrint('bootstrap: hive init — starting');
    await Hive.initFlutter();
    debugPrint('bootstrap: hive.initFlutter — DONE');
    await HiveService.instance.init();
    debugPrint('bootstrap: HiveService.init — DONE');

    debugPrint('bootstrap: runApp — calling');
    runApp(const ProviderScope(child: VeloraApp()));
    debugPrint('bootstrap: runApp — called');
    await WidgetsBinding.instance.endOfFrame;
    try {
      await NotificationService.instance.initialize();
    } catch (e, st) {
      // Notifications are optional and must not prevent the existing app from opening.
      debugPrint('Notification initialization failed: $e\n$st');
    }
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
