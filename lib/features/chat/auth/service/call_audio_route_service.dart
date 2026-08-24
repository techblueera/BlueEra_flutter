import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android-only bridge to flutter_webrtc's shared `AudioSwitchManager`.
///
/// `Helper.selectAudioOutput(...)` alone is not reliable in this app: the
/// plugin re-creates its `AudioSwitchManager` static on EVERY Flutter engine
/// attach, and the app runs up to four engines (MainActivity, CallActivity, the
/// FCM background isolate, the overlay window). When one of them attaches
/// mid-call the singleton is replaced by an instance that was never activated,
/// so the plugin records the new selection but never applies it — the speaker
/// button flips in the UI while the audio stays on the earpiece, silently.
///
/// [selectOutput] re-activates whichever instance is current before selecting,
/// and returns the route that is *actually* live afterwards so the caller can
/// render the truth instead of its request. See CallAudioBridge.kt.
class CallAudioRouteService {
  static const MethodChannel _channel =
      MethodChannel('com.bluehr.call/audio_route');

  /// Re-activate the plugin's audio switch, select [typeName], and read back
  /// the route that ended up active.
  ///
  /// [typeName] uses the plugin's own names: `speaker`, `earpiece`,
  /// `bluetooth`, `wired-headset`.
  ///
  /// Returns null when the read-back is unavailable — non-Android, the channel
  /// is not registered on this engine, or the plugin internals moved. Null
  /// means "unknown", never "failed": callers should fall back to optimism
  /// rather than showing an error.
  static Future<String?> selectOutput(String typeName) async {
    if (!Platform.isAndroid) return null;
    try {
      final result =
          await _channel.invokeMethod('selectOutput', {'name': typeName});
      return result as String?;
    } catch (e) {
      if (kDebugMode) print('CallAudioRouteService.selectOutput failed: $e');
      return null;
    }
  }

  /// The route the plugin currently has selected, or null if unreadable.
  static Future<String?> currentOutput() async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMethod('currentOutput');
      return result as String?;
    } catch (e) {
      if (kDebugMode) print('CallAudioRouteService.currentOutput failed: $e');
      return null;
    }
  }
}
