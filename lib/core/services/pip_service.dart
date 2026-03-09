import 'package:flutter/services.dart';

/// Service to manage Picture-in-Picture mode via native Android method channel.
class PipService {
  static const MethodChannel _channel = MethodChannel('com.vahcare.lab/pip');

  /// Enable or disable PiP auto-entry when user leaves the app (home/recents).
  static Future<void> updatePipStatus(bool isEnabled) async {
    try {
      await _channel.invokeMethod('updatePipStatus', {'isEnabled': isEnabled});
    } catch (_) {}
  }

  /// Manually enter PiP mode (e.g. minimize button).
  static Future<bool> enterPip() async {
    try {
      final result = await _channel.invokeMethod<bool>('enterPip');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check if the app is currently in PiP mode.
  static Future<bool> isInPipMode() async {
    try {
      final result = await _channel.invokeMethod<bool>('isInPipMode');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
