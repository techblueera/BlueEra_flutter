import 'package:flutter/services.dart';

class ScreenService {
  static const MethodChannel _channel = MethodChannel('com.bluehr.video/keep_screen_on');

  /// Keep screen awake
  static Future<void> keepOn() async {
    try {
      await _channel.invokeMethod('keepOn');
    } catch (e) {
      print("Error enabling keepOn: $e");
    }
  }

  /// Allow screen to sleep again
  static Future<void> keepOff() async {
    try {
      await _channel.invokeMethod('keepOff');
    } catch (e) {
      print("Error disabling keepOn: $e");
    }
  }
}
