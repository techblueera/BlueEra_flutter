import 'dart:async';
import 'dart:io';

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

  /// While a provider (rider/shop) is LIVE, the foreground service must stay
  /// up even after a call ends — the map-service auto-closes providers whose
  /// app stops pinging location for 5 minutes, and a plain Dart timer dies as
  /// soon as Android freezes the backgrounded process. The hold makes
  /// call-end `stop()` calls a no-op until the provider goes offline.
  static bool _riderLiveHold = false;

  /// Acquire/release the provider-live hold on the foreground service.
  static Future<void> setRiderLiveHold(bool active) async {
    _riderLiveHold = active;
    if (active) {
      await start();
    } else {
      await stop();
    }
  }

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
  /// No-op while the provider-live hold is active (provider still online).
  static Future<void> stop() async {
    if (_riderLiveHold) return;
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
