import 'dart:io';
import 'package:BlueEra/env.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

firebaseInitializeApp() async {
  if (Platform.isAndroid) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: Env.androidFirebaseAPIKey,
          appId: Env.androidFirebaseAppId,
          messagingSenderId: Env.messagingSenderId,
          projectId: Env.projectFireBaseId,
        ));
  } else if (Platform.isIOS) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: Env.iosFirebaseAPIKey,
            appId: Env.iosFirebaseAppId,
            messagingSenderId: Env.messagingSenderId,
            projectId: Env.projectFireBaseId));
  } else {
    await Firebase.initializeApp();
  }
}

firebaseCrashServiceInit() {
  const fatalError = true;
  // Non-async exceptions
  FlutterError.onError = (errorDetails) {
    if (fatalError) {
      // If you want to record a "fatal" exception
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      // ignore: dead_code
    } else {
      // If you want to record a "non-fatal" exception
      FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
    }
  };
  // Async exceptions
  PlatformDispatcher.instance.onError = (error, stack) {
    if (fatalError) {
      // If you want to record a "fatal" exception
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      // ignore: dead_code
    } else {
      // If you want to record a "non-fatal" exception
      FirebaseCrashlytics.instance.recordError(error, stack);
    }
    return true;
  };
}
