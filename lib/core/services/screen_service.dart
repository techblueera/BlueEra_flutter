import 'package:flutter/services.dart';
import 'package:BlueEra/core/constants/debug_log.dart';

class ScreenService {
  static const MethodChannel _channel = MethodChannel('com.bluehr.video/keep_screen_on');

  /// Keep screen awake
  static Future<void> keepOn() async {
    try {
      await _channel.invokeMethod('keepOn');
    } catch (e) {
      debugLog("Error enabling keepOn: $e");
    }
  }

  /// Allow screen to sleep again
  static Future<void> keepOff() async {
    try {
      await _channel.invokeMethod('keepOff');
    } catch (e) {
      debugLog("Error disabling keepOn: $e");
    }
  }
}
