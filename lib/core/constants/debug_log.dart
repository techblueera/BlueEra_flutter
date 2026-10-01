import 'package:flutter/foundation.dart';

/// Console output for development only.
///
/// Silent in release builds: a bare `print` there goes to the device log
/// (readable with `adb logcat` / Console.app), and this app's diagnostics
/// include API payloads, FCM / VoIP token errors and signaling state that
/// shouldn't leave the device. In debug it prints exactly as `print` did.
void debugLog(Object? message) {
  if (kDebugMode) debugPrint('$message');
}
