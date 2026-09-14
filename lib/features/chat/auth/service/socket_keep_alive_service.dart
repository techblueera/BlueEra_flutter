import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../socket/chat_socket.dart';

/// Keeps the socket alive during calls.
///
/// **Android:** holds the process — and with it the Flutter engine and the chat
/// WebSocket — up via `CallKeepAliveService`, a `phoneCall` foreground service.
/// Without it Android freezes a backgrounded call and the socket drops.
///
/// **iOS:** runs a periodic ping on the socket to detect disconnections early
/// and trigger reconnection. iOS keeps the process alive via CallKit's VoIP
/// entitlement while a call is active, but the socket can still silently drop.
///
/// ## History
///
/// The Android branch called this same channel from the day it was written, but
/// nothing ever registered a handler for it, so every call threw
/// `MissingPluginException` into an empty `catch` and did nothing. The branch
/// was removed once that was found, and is restored here now that
/// `CallKeepAliveService` and the `MainActivity` handler actually exist.
class SocketKeepAliveService {
  static const _channel = MethodChannel('com.bluehr.socket/service');

  static Timer? _iosKeepAliveTimer;

  /// While a provider (rider/shop) is LIVE, iOS keep-alive must stay up even
  /// after a call ends — the map-service auto-closes providers whose app stops
  /// pinging location for 5 minutes. The hold makes a call-end [stop] a no-op
  /// on iOS until the provider goes offline.
  ///
  /// **iOS-only by design.** On Android a live provider is covered by
  /// `RiderLocationForegroundService`, which pings without the Flutter engine;
  /// the hold must NOT keep the call keep-alive up there, or a rider who is
  /// merely online would be shown a "Call in progress" notification.
  static bool _riderLiveHold = false;

  /// Acquire/release the provider-live hold.
  ///
  /// Note this does **not** route through [start]/[stop] any more. It used to,
  /// which was harmless only while the Android branch was inert: now that
  /// [start] posts a call notification, a live rider would get one for a call
  /// they are not on.
  static Future<void> setRiderLiveHold(bool active) async {
    _riderLiveHold = active;
    if (!Platform.isIOS) return;
    if (active) {
      _startIosKeepAlive();
    } else {
      _stopIosKeepAlive();
    }
  }

  /// Start keeping the socket alive. Call when a call starts.
  ///
  /// Returns false when Android refused to start the foreground service. The
  /// call still proceeds — the keep-alive is protection, not a precondition —
  /// but the socket may drop if the user backgrounds the app.
  static Future<bool> start() async {
    if (Platform.isAndroid) {
      try {
        final started = await _channel.invokeMethod<bool>('startService');
        if (started != true) {
          debugPrint('[SocketKeepAliveService] Android refused the call '
              'keep-alive; a backgrounded call may drop its socket.');
        }
        return started ?? false;
      } catch (e) {
        // Logged, not swallowed. Silence here is what hid the missing channel
        // for the entire life of the feature.
        debugPrint('[SocketKeepAliveService] startService failed: $e');
        return false;
      }
    }
    if (Platform.isIOS) {
      _startIosKeepAlive();
      return true;
    }
    return false;
  }

  /// Stop the keep-alive. Call when the call ends.
  static Future<void> stop() async {
    if (Platform.isAndroid) {
      // Unconditional — the provider-live hold deliberately does NOT apply.
      // The call has ended, and leaving a `phoneCall` foreground service up
      // would strand an ongoing notification the user cannot swipe away
      // (Android 14 exempts call-type services from swipe-to-dismiss).
      // A live rider keeps publishing through RiderLocationForegroundService,
      // which is a separate service and unaffected by this.
      try {
        await _channel.invokeMethod('stopService');
      } catch (e) {
        debugPrint('[SocketKeepAliveService] stopService failed: $e');
      }
      return;
    }
    if (Platform.isIOS) {
      // Provider still live — keep the socket-health timer running.
      if (_riderLiveHold) return;
      _stopIosKeepAlive();
    }
  }

  /// Whether the Android keep-alive service is currently holding the process.
  /// Always false on other platforms.
  static Future<bool> isRunning() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isRunning') ?? false;
    } catch (_) {
      return false;
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
