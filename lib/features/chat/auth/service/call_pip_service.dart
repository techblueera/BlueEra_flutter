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

  /// Initialize PiP listeners (call from ActiveCallScreen)
  static void init() {
    if (!Platform.isAndroid) return;

    _callPipChannel.setMethodCallHandler((call) async {
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
    });
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
