import 'dart:io';
import 'package:flutter/services.dart';

/// Window behaviour the host Activity applies for the duration of a call:
/// visible over the lock screen, screen turned on for an incoming ring, and no
/// screen timeout while the call runs.
///
/// This was `CallPipService` and also drove Picture-in-Picture. PiP is gone:
/// the call screen used to enter it on Back, and because a killed-state call
/// made the call screen the app's only screen, leaving PiP closed the app.
/// Back now minimises to the top call strip instead, which is both what users
/// expect and recoverable.
class CallWindowService {
  static const _channel = MethodChannel('com.bluehr.call/pip');

  /// Turn the call window behaviour on for the duration of a call, off when it
  /// ends. Driven off callStatus by CallController.
  static Future<void> setCallWindowActive(bool active) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setCallWindowActive', {'active': active});
    } catch (_) {}
  }
}
