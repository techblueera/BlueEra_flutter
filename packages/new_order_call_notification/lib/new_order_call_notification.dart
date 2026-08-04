/// Android-only, non-dismissible new-order alert.
///
/// Wraps a native `NotificationCompat.CallStyle` notification — the only
/// template Android 14+ still exempts from "users can dismiss ongoing
/// notifications", and therefore the only way to post an order alert a seller
/// cannot swipe away. See the Kotlin side for the full rationale.
///
/// Every entry point degrades quietly: on iOS, on an old build without the
/// native side, or on any platform error, [show] reports `false` and the
/// caller is expected to fall back to its ordinary notification.
library;

import 'dart:async';

import 'package:flutter/services.dart';

/// What the user tapped, handed back to the app.
class NewOrderOpenedAction {
  const NewOrderOpenedAction({required this.payload, required this.notificationId});

  /// The FCM data map, JSON-encoded exactly as it was passed to [show].
  final String payload;

  /// Id of the notification to cancel now that it has been acted on.
  final int notificationId;

  static NewOrderOpenedAction? fromMap(dynamic value) {
    if (value is! Map) return null;
    final payload = (value['payload'] ?? '').toString();
    if (payload.isEmpty) return null;
    return NewOrderOpenedAction(
      payload: payload,
      notificationId: (value['notificationId'] as num?)?.toInt() ?? 0,
    );
  }
}

class NewOrderCallNotification {
  NewOrderCallNotification._();

  static const MethodChannel _channel =
      MethodChannel('ai.bluecs/new_order_call_notification');

  static void Function(NewOrderOpenedAction action)? _onOrderOpened;

  /// Register the callback fired when a **running** app is re-entered through
  /// the alert (its Answer button, body tap, or full-screen intent).
  ///
  /// A cold start doesn't come through here — the engine is still booting when
  /// the intent lands — so callers must also drain [readPendingAction] once at
  /// startup.
  static void setOrderOpenedListener(
    void Function(NewOrderOpenedAction action)? listener,
  ) {
    _onOrderOpened = listener;
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method != 'onOrderOpened') return null;
    final action = NewOrderOpenedAction.fromMap(call.arguments);
    if (action != null) _onOrderOpened?.call(action);
    return null;
  }

  /// Post the alert. Returns false when the native side is unavailable (iOS,
  /// missing plugin) or refused to post (notification permission denied).
  ///
  /// [caller] is the name the call template shows most prominently — use the
  /// customer or the order summary, not the app name. [deadlineMillis] is the
  /// response deadline as epoch millis; pass 0 for no countdown. [sound] and
  /// [icon] are resource names in the HOST app (`res/raw/<sound>.mp3`,
  /// `res/drawable/<icon>`), resolved natively at runtime.
  ///
  /// [accentColor] is an ARGB int applied to BOTH call buttons and the
  /// notification accent — the only styling the system's call template
  /// accepts. Pass 0 to keep the stock red/green call colours. The button
  /// LABELS and their phone icons are drawn by the platform and cannot be
  /// changed; see the Kotlin side.
  static Future<bool> show({
    required int id,
    required String title,
    required String body,
    required String caller,
    required String payload,
    int deadlineMillis = 0,
    String sound = '',
    String icon = '',
    int accentColor = 0,
  }) async {
    try {
      final posted = await _channel.invokeMethod<bool>('show', <String, dynamic>{
        'id': id,
        'title': title,
        'body': body,
        'caller': caller,
        'payload': payload,
        'deadlineMillis': deadlineMillis,
        'sound': sound,
        'icon': icon,
        'accentColor': accentColor,
      });
      return posted ?? false;
    } on MissingPluginException {
      return false; // iOS, or a build without the native side
    } catch (_) {
      return false;
    }
  }

  /// Take the alert down. This is the only way it leaves the shade besides the
  /// native Dismiss button.
  static Future<void> cancel(int id) async {
    try {
      await _channel.invokeMethod<void>('cancel', <String, dynamic>{'id': id});
    } on MissingPluginException {
      // Nothing was ever posted natively.
    } catch (_) {
      // Best effort — a failed cancel must not break the caller's tap path.
    }
  }

  /// The alert the app was launched from, or null. Clears it, so a second call
  /// (or a later relaunch) does not replay the same order.
  static Future<NewOrderOpenedAction?> readPendingAction() async {
    try {
      final result = await _channel.invokeMethod<dynamic>('readPendingAction');
      return NewOrderOpenedAction.fromMap(result);
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
