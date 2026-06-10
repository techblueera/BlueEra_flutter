import 'dart:io';
import 'package:flutter/services.dart';

/// Service to manage Picture-in-Picture mode for calls.
/// Works with both CallActivity (separate task) and MainActivity (fallback).
class CallPipService {
  // CallActivity PiP channel
  static const _callPipChannel = MethodChannel('com.bluehr.call/pip');
  // MainActivity PiP channel (fallback for in-app call flow)
  static const _mainPipChannel = MethodChannel('com.vahcare.lab/pip');

  static Function(bool)? onPipModeChanged;
  static Function(String)? onPipAction;

  /// Initialize PiP listeners (call from ActiveCallScreen).
  /// Registers on BOTH channels: the CallActivity engine (`com.bluehr.call/pip`)
  /// and the MainActivity in-app flow (`com.vahcare.lab/pip`). The in-app flow
  /// is the active path on Android — without the MainActivity handler the call
  /// screen never learns it is in PiP and the PiP action buttons do nothing.
  static void init() {
    if (!Platform.isAndroid) return;

    Future<dynamic> handler(MethodCall call) async {
      switch (call.method) {
        case 'onPipModeChanged':
          final isInPip = call.arguments as bool;
          onPipModeChanged?.call(isInPip);
          break;
        case 'onPipAction':
          final action = call.arguments as String;
          onPipAction?.call(action);
          break;
      }
    }

    _callPipChannel.setMethodCallHandler(handler);
    _mainPipChannel.setMethodCallHandler(handler);
  }

  /// Enter PiP mode. Tries CallActivity channel first, falls back to MainActivity.
  static Future<bool> enterPipMode() async {
    if (!Platform.isAndroid) return false;

    try {
      // Try CallActivity PiP channel first
      final result = await _callPipChannel.invokeMethod('enterPip');
      return result == true;
    } catch (_) {
      try {
        // Fallback to MainActivity PiP channel
        final result = await _mainPipChannel.invokeMethod('enterPip');
        return result == true;
      } catch (_) {
        return false;
      }
    }
  }

  /// Exit PiP when a call ends. Android can't pop a single-activity app out of
  /// PiP to fullscreen, so the native side moves the task to the background —
  /// the PiP window closes and the user returns to whatever they were doing
  /// (WhatsApp-style). No-op (native-guarded) when not actually in PiP.
  static Future<void> exitPipMode() async {
    if (!Platform.isAndroid) return;
    try {
      await _mainPipChannel.invokeMethod('exitPip');
    } catch (_) {
      try {
        await _callPipChannel.invokeMethod('exitPip');
      } catch (_) {}
    }
  }

  /// Send the whole app to the background (without killing it). Used when a
  /// call accepted from a background notification ends — returns the user to
  /// whatever they were doing while the app keeps running.
  static Future<void> moveAppToBackground() async {
    if (!Platform.isAndroid) return;
    try {
      await _mainPipChannel.invokeMethod('moveToBack');
    } catch (_) {}
  }

  /// Finish & remove the app task from Recents. Used when the app was
  /// cold-started only to handle an incoming call (killed state) — avoids
  /// landing on a stuck splash and gives a clean relaunch next time.
  static Future<void> finishAndRemoveTask() async {
    if (!Platform.isAndroid) return;
    try {
      await _mainPipChannel.invokeMethod('finishAndRemoveTask');
    } catch (_) {}
  }

  /// Check if currently in PiP mode.
  static Future<bool> isInPipMode() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _callPipChannel.invokeMethod('isInPipMode');
      return result == true;
    } catch (_) {
      try {
        final result = await _mainPipChannel.invokeMethod('isInPipMode');
        return result == true;
      } catch (_) {
        return false;
      }
    }
  }

  /// Cleanup listeners
  static void dispose() {
    onPipModeChanged = null;
    onPipAction = null;
  }
}
