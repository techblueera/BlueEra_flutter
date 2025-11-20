import 'package:flutter/services.dart';

class DefaultRingtone {
  static const MethodChannel _channel =
  MethodChannel("com.bluehr.ringtone/default");

  static Future<void> play() async {
    await _channel.invokeMethod("playRingtone");
  }

  static Future<void> stop() async {
    await _channel.invokeMethod("stopRingtone");
  }
}
