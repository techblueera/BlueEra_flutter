import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../socket/chat_socket.dart';

/// Keeps the socket alive during calls.
///
/// **Android:** Starts a foreground service to prevent the OS from killing the
/// Flutter engine while the app is backgrounded.
///
/// **iOS:** Runs a periodic ping on the socket to detect disconnections early
/// and trigger reconnection. iOS keeps the process alive via CallKit's VoIP
/// entitlement while a call is active, but the socket can still silently drop.
class SocketKeepAliveService {
  static const _channel = MethodChannel('com.bluehr.socket/service');

  static Timer? _iosKeepAliveTimer;

  /// Start keeping the socket alive. Call when a call starts.
  static Future<void> start() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('startService');

      } catch (e) {

      }
    } else if (Platform.isIOS) {
      _startIosKeepAlive();
    }
  }

  /// Stop the keep-alive. Call when the call ends.
  static Future<void> stop() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('stopService');
      } catch (e) {
      }
    } else if (Platform.isIOS) {
      _stopIosKeepAlive();
    }
  }

  /// iOS: Periodically check socket health and reconnect if needed.
  /// During an active CallKit call, iOS keeps the app process alive,
  /// so these timers will fire even when backgrounded.
  static void _startIosKeepAlive() {
    _iosKeepAliveTimer?.cancel();
    _iosKeepAliveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final socket = ChatSocketService();
      if (!socket.isConnected) {
        socket.reconnectNow();
      }
    });
  }

  static void _stopIosKeepAlive() {
    _iosKeepAliveTimer?.cancel();
    _iosKeepAliveTimer = null;
  }
}
