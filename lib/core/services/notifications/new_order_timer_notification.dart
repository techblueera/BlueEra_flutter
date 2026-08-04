/// Countdown ("timer") notification for **new order received** pushes.
///
/// Implements docs/timer_notification.md for the one operation family the
/// product asked for — a seller being told an order just came in — and nothing
/// else. Every other push keeps rendering through
/// `AppNotificationHandler.showFromData` exactly as before; this file is the
/// only place the countdown presentation lives.
///
/// What the user sees (Android):
/// ```
/// ┌──────────────────────────────────────────────┐
/// │ ⬤ BlueEra                            00:47   │  ← live countdown
/// │ New order received                           │
/// │ 2 item(s) • Total ₹340                       │
/// │ [ order image, when the push carries one   ] │
/// │  VIEW ORDER            DISMISS               │
/// └──────────────────────────────────────────────┘
/// ```
///
/// **The alert is built to be un-skippable, with one platform caveat.** It is
/// posted `ongoing`, with `FLAG_NO_CLEAR`, as `CATEGORY_CALL`, and with a
/// full-screen intent — so it outranks everything else and takes over the
/// screen instead of waiting in the shade. The intended exits are the two the
/// user asked for: tapping the body (which opens the order) or pressing
/// Dismiss. It also does NOT expire on its own — "removes itself after 60s"
/// and "stays until clicked" cannot both be true, and an unanswered order
/// alert silently disappearing is the worse failure.
///
/// **The caveat: on Android 14+ `ongoing` and `FLAG_NO_CLEAR` are advisory.**
/// developer.android.com/about/versions/14/behavior-changes-all — users can
/// dismiss ongoing notifications, and the ONLY exempt categories are
/// `CallStyle`, media, device-policy-controller and search-selector
/// notifications. A foreground service is not exempt either. `CallStyle` needs
/// native code (`flutter_local_notifications` cannot build one — MaikuB/
/// flutter_local_notifications#2367), so on Android 14+ a determined swipe
/// still removes this banner. Everything above is what is achievable in Dart;
/// making it literally impossible means porting this notification to a native
/// `NotificationCompat.CallStyle` builder.
///
/// **Why there is no per-second `show()` loop.** The countdown is rendered by
/// Android itself (`usesChronometer` + `chronometerCountDown` + `when`), so it
/// ticks once a second in every app state — foreground, background and
/// terminated — without this isolate being alive. Once the deadline passes, a
/// countdown chronometer starts rendering negative time, so when the app is
/// alive the banner is rewritten once into a static "still waiting" form (see
/// [NewOrderTimerNotification._showExpired]). A killed app can't do that
/// rewrite and will show the overrun counter until the seller acts.
///
/// iOS cannot make a notification non-dismissible — no API exists — so there
/// the banner is `timeSensitive` with the deadline in the subtitle, and a
/// swipe still removes it. Android carries the guarantee.
///
/// Lives outside `AppNotificationHandler` deliberately — the background /
/// terminated FCM isolate in `main.dart` cannot reach that class's instance
/// state, and both isolates must agree on the notification id and action ids.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:new_order_call_notification/new_order_call_notification.dart';

/// `adb logcat | grep NEW_ORDER_TIMER` to follow one order push across both
/// isolates.
void newOrderTimerLog(String message) =>
    developer.log('[NEW_ORDER_TIMER] $message');

/// FCM `operation` values that mean *an order has just been placed and the
/// recipient has to act on it*.
///
/// Deliberately excludes the `*_ready` twins: those go to the CUSTOMER ("your
/// order is ready for pickup") and there is nothing to count down. Ride
/// requests are excluded too — they already ring through
/// `ride_ring_notification.dart` and must not be shown twice.
///
/// Trim or extend this set to change which pushes get the countdown; it is the
/// single switch for the whole feature.
const Set<String> kNewOrderTimerOperations = {
  'food_pickup_order',
  'selfpickup_order',
  'grocery_order',
  'product_pickup_order',
  'homemade_food_pickup_order',
  'tiffin_pickup_order',
  'medical_pickup_order',
  // Spellings the backend may send for the same event.
  'new_order',
  'new_order_received',
  'order_received',
};

/// Channel carrying the order chime as an Android raw resource.
///
/// Same tone as `order_alerts_v3` (`new_order_mu`) so a new order sounds
/// identical whether or not it got the countdown treatment. Separate channel
/// because this one is `Importance.max` with its own description, and because
/// **Android freezes a channel's settings at creation time** — a versioned id
/// is the only way to change them later. Bump to `_v2` if the sound changes;
/// editing the constants alone will not affect devices that already have it.
const String kNewOrderTimerChannelId = 'new_order_timer_v1';
const String kNewOrderTimerChannelName = 'New Orders';
const String kNewOrderTimerChannelDescription =
    'New order alerts with a response countdown';

/// android/app/src/main/res/raw/new_order_mu.mp3 (no extension).
const String kNewOrderTimerSound = 'new_order_mu';

/// iOS bundle sound. Must be in the Runner target to play; iOS falls back to
/// the default alert sound if it is missing.
const String kNewOrderTimerIosSound = 'new_order_mu.mp3';

/// Countdown length when the push carries no expiry of its own.
const int kNewOrderTimerDefaultSeconds = 60;

/// Longest countdown we will honour from a payload, so a bad `expiryTime`
/// can't pin a notification to the shade for hours.
const int kNewOrderTimerMaxSeconds = 15 * 60;

/// Android flag `Notification.FLAG_NO_CLEAR` — the notification survives
/// "Clear all". Paired with `ongoing: true` (FLAG_ONGOING_EVENT, which blocks
/// the swipe) this is what makes the alert unskippable.
///
/// Caveat worth knowing: on Android 14+ the system lets the user dismiss even
/// ongoing notifications from apps that aren't running a foreground service.
/// These two flags are the strongest guarantee available without promoting the
/// order alert to a foreground service.
const int kFlagNoClear = 32;

/// Copy appended when the response window runs out but the seller still hasn't
/// acted. See [NewOrderTimerNotification._showExpired].
const String kNewOrderTimerExpiredNote = 'Still waiting for your response';

/// Brand sky blue (`AppColors.primaryColor`) used for the whole alert — both
/// call buttons and the notification accent. Hard-coded rather than imported
/// so this file stays usable from the FCM background isolate without pulling
/// the theme layer in behind it.
const int kNewOrderTimerAccentColor = 0xFF0086FF;
const Color kNewOrderTimerAccent = Color(kNewOrderTimerAccentColor);

// ─── Push / action identification ────────────────────────────────────────

/// True when this data payload is a new-order push that should get the
/// countdown presentation.
bool isNewOrderTimerPush(Map<dynamic, dynamic> data) {
  final operation = (data['operation'] ?? data['type'] ?? '')
      .toString()
      .trim()
      .toLowerCase();
  return kNewOrderTimerOperations.contains(operation);
}

const String _kViewActionPrefix = 'new_order_view_';
const String _kDismissActionPrefix = 'new_order_dismiss_';

String newOrderViewActionId(String key) => '$_kViewActionPrefix$key';
String newOrderDismissActionId(String key) => '$_kDismissActionPrefix$key';

bool isNewOrderViewAction(String actionId) =>
    actionId.startsWith(_kViewActionPrefix);

bool isNewOrderDismissAction(String actionId) =>
    actionId.startsWith(_kDismissActionPrefix);

bool isNewOrderTimerAction(String actionId) =>
    isNewOrderViewAction(actionId) || isNewOrderDismissAction(actionId);

/// Identity of one order push, used for the notification id and baked into the
/// action ids.
///
/// The action buttons are handled in the background isolate, where there is no
/// screen and no controller to ask "which order?" — so the id has to carry it.
/// Falls back through every id the order pushes are known to send
/// (`homemade_food_pickup_order` & friends carry `message_id` /
/// `conversation_id`, not an order id) before giving up on a constant, so a
/// re-delivered FCM replaces its notification instead of stacking a duplicate.
String newOrderTimerKey(Map<dynamic, dynamic> data) {
  final payload = _decodePayload(data);
  const keys = [
    'orderId',
    'order_id',
    'notificationId',
    'message_id',
    'messageId',
    'conversation_id',
    'conversationId',
  ];
  for (final source in <Map<dynamic, dynamic>?>[
    data,
    payload,
    payload?['metadata'] as Map<dynamic, dynamic>?,
  ]) {
    if (source == null) continue;
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
  }
  return 'new_order';
}

/// Stable numeric notification id for [key].
///
/// Sums code units rather than using `String.hashCode`: the latter is not
/// guaranteed stable across Dart releases, and the isolate that cancels the
/// notification may be running a different build than the one that posted it.
int newOrderTimerNotificationId(String key) {
  final id = key.trim();
  if (id.isEmpty) return 771100;
  var sum = 0;
  for (final unit in id.codeUnits) {
    sum = (sum * 31 + unit) % 2147483647;
  }
  return sum == 0 ? 771100 : sum;
}

/// [FlutterLocalNotificationsPlugin.cancelAll], minus any live new-order
/// alert.
///
/// The order alert is deliberately unskippable, so the app's own tray
/// housekeeping must not become the thing that skips it. Two existing paths
/// wipe the whole tray: the FCM background handler clears it before rendering
/// each incoming push, and the chat actions (mark-as-read, inline reply, tap
/// routing) clear it when they finish. Either one landing while a seller had
/// an unanswered order would have taken that alert down with it.
///
/// Falls back to a plain `cancelAll()` when no order alert is showing or the
/// shade cannot be read — byte-for-byte the old behaviour in every case that
/// does not involve one. Cancels by `(id, tag)` so notifications the Firebase
/// SDK posted with a tag are still removed.
Future<void> cancelAllExceptNewOrderAlerts(
    FlutterLocalNotificationsPlugin plugin) async {
  try {
    final active = await plugin.getActiveNotifications();
    final protectedIds = active
        .where((notification) => notification.channelId == kNewOrderTimerChannelId)
        .map((notification) => notification.id)
        .toSet();

    if (protectedIds.isEmpty) {
      await plugin.cancelAll();
      return;
    }

    for (final notification in active) {
      final id = notification.id;
      if (id == null || protectedIds.contains(id)) continue;
      await plugin.cancel(id, tag: notification.tag);
    }
    newOrderTimerLog('tray cleared, kept ${protectedIds.length} order alert(s)');
  } catch (e) {
    newOrderTimerLog('selective clear failed ($e) — falling back to cancelAll');
    await plugin.cancelAll();
  }
}

/// Channel definition, so `firebaseNotificationSetup()` can pre-create it on a
/// warm start with exactly the settings the background isolate would use.
const AndroidNotificationChannel kNewOrderTimerChannel =
    AndroidNotificationChannel(
  kNewOrderTimerChannelId,
  kNewOrderTimerChannelName,
  description: kNewOrderTimerChannelDescription,
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound(kNewOrderTimerSound),
  audioAttributesUsage: AudioAttributesUsage.notification,
);

// ─── The service ─────────────────────────────────────────────────────────

class NewOrderTimerNotification {
  NewOrderTimerNotification._();

  static final NewOrderTimerNotification instance =
      NewOrderTimerNotification._();

  /// Deadline timers, keyed by notification id. They only rewrite the banner
  /// into its "still waiting" form — nothing here removes a notification, so
  /// losing the map when the isolate dies costs the user nothing.
  final Map<int, Timer> _expiryTimers = {};

  /// Post (or replace) the countdown notification for a new-order push.
  ///
  /// [plugin] lets the caller hand over the already-initialised instance —
  /// the FCM background isolate initialises its own, and reusing it is what
  /// makes the tap/action callbacks resolve there.
  ///
  /// Returns **false** when nothing was posted (the push arrived past its own
  /// expiry, or rendering threw). The caller must then fall back to the
  /// ordinary banner: a seller silently missing a new order is far worse than
  /// one shown without a countdown.
  Future<bool> show(
    Map<String, dynamic> data, {
    FlutterLocalNotificationsPlugin? plugin,
  }) async {
    final notifications = plugin ?? FlutterLocalNotificationsPlugin();

    try {
      final key = newOrderTimerKey(data);
      final notificationId = newOrderTimerNotificationId(key);
      final deadline = _resolveDeadline(data);
      final remaining = deadline.difference(DateTime.now());

      // Already expired on arrival (a push delayed past its own window): a
      // countdown to a past instant renders as negative time, so there is
      // nothing to show. Hand it back to the plain renderer instead — the
      // seller still gets the order, just without a timer.
      if (remaining.inSeconds <= 0) {
        newOrderTimerLog('key=$key arrived expired — falling back to banner');
        return false;
      }

      final title = (data['title'] ?? 'New order received').toString();
      final body =
          (data['body'] ?? data['message'] ?? 'You have a new order').toString();
      final imageUrl = (data['imageUrl'] ?? data['image'] ?? '').toString();

      newOrderTimerLog(
        'key=$key id=$notificationId window=${remaining.inSeconds}s '
        'op=${data['operation']}',
      );

      // Android: try the native CallStyle alert FIRST. It is the only
      // rendering the OS will not let the seller swipe away (see the class
      // doc), and it works from this isolate or the FCM background one
      // because the plugin registers on every engine. Everything else — iOS,
      // notification permission denied, a build without the native side —
      // falls through to the flutter_local_notifications rendering below.
      if (Platform.isAndroid) {
        final posted = await NewOrderCallNotification.show(
          id: notificationId,
          title: title,
          // The CallStyle template owns its layout and may not render the
          // chronometer, so the deadline is spelled out in the text as well.
          body: '$body • Respond within ${_humanRemaining(remaining)}',
          caller: _callerFor(data, title),
          payload: jsonEncode(data),
          deadlineMillis: deadline.millisecondsSinceEpoch,
          sound: kNewOrderTimerSound,
          icon: 'ic_stat',
          // Both buttons in one brand colour, replacing the template's stock
          // red/green.
          accentColor: kNewOrderTimerAccentColor,
        );
        if (posted) {
          newOrderTimerLog('key=$key posted as CallStyle — not dismissible');
          return true;
        }
        newOrderTimerLog('key=$key CallStyle unavailable — plain banner');
      }

      // Big-picture style when the push carries an image (the product shot),
      // big-text otherwise so a long order summary isn't truncated.
      final bigPicture =
          imageUrl.isEmpty ? null : await _downloadImage(imageUrl);
      final StyleInformation styleInformation = bigPicture != null
          ? BigPictureStyleInformation(
              bigPicture,
              contentTitle: title,
              summaryText: body,
              hideExpandedLargeIcon: false,
            )
          : BigTextStyleInformation(body, contentTitle: title);

      final androidDetails = AndroidNotificationDetails(
        kNewOrderTimerChannelId,
        kNewOrderTimerChannelName,
        channelDescription: kNewOrderTimerChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        // Passing the sound here also creates the channel on demand, which is
        // what makes a KILLED-state order chime — the background isolate never
        // runs firebaseNotificationSetup(). Must stay identical to
        // [kNewOrderTimerChannel] or the two isolates would fight over the
        // channel's frozen settings.
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(kNewOrderTimerSound),
        enableVibration: true,
        icon: '@drawable/ic_stat',
        color: kNewOrderTimerAccent,
        styleInformation: styleInformation,
        // ── The countdown itself ──────────────────────────────────────────
        // `when` = the deadline, and the chronometer counts DOWN to it, once a
        // second, rendered by the system. No Dart timer, no re-posting.
        when: deadline.millisecondsSinceEpoch,
        showWhen: true,
        usesChronometer: true,
        chronometerCountDown: true,
        // NO `timeoutAfter`, deliberately: the alert must outlive its own
        // countdown and wait for the seller. See the class doc.
        //
        // ── Hard to skip ──────────────────────────────────────────────────
        // `ongoing` + FLAG_NO_CLEAR block the swipe and "Clear all" up to
        // Android 13, and on the lock screen at any version. On Android 14+
        // they are ADVISORY (see the class doc), so the alert leans on the
        // call presentation instead: CATEGORY_CALL ranks it above everything
        // else, and the full-screen intent makes it take over the screen
        // rather than sit in the shade waiting to be flicked away.
        ongoing: true,
        additionalFlags: Int32List.fromList([kFlagNoClear]),
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        // A re-delivered FCM for the same order refreshes the countdown
        // silently instead of chiming a second time.
        onlyAlertOnce: true,
        actions: _actionsFor(key),
      );

      // iOS gets the deadline as text — no chronometer exists there, and no
      // API can stop the user swiping a banner away.
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: kNewOrderTimerIosSound,
        subtitle: 'Respond within ${_humanRemaining(remaining)}',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      await notifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        // The unchanged push payload, so a tap on the body routes through the
        // existing `_onTapNotificationFromStatusBar` switch exactly as it did
        // before this file existed.
        payload: jsonEncode(data),
      );

      _armExpiry(
        notifications,
        key: key,
        notificationId: notificationId,
        remaining: remaining,
        title: title,
        body: body,
        styleInformation: styleInformation,
        payload: jsonEncode(data),
      );
      return true;
    } catch (e, st) {
      // A failure here must never take the FCM handler down with it, and must
      // never cost the user the alert — the caller re-renders it plainly.
      newOrderTimerLog('show FAILED: $e\n$st');
      return false;
    }
  }

  /// Cancel the countdown for [data]'s order — used by the Dismiss button, the
  /// View button, and the notification-body tap.
  Future<void> dismiss(
    Map<dynamic, dynamic> data, {
    FlutterLocalNotificationsPlugin? plugin,
  }) =>
      cancel(newOrderTimerNotificationId(newOrderTimerKey(data)),
          plugin: plugin);

  /// Cancel by notification id and drop its deadline timer.
  ///
  /// This is the ONLY way the notification leaves the shade, and every caller
  /// is a deliberate user action: the body tap, View Order, or Dismiss.
  Future<void> cancel(
    int notificationId, {
    FlutterLocalNotificationsPlugin? plugin,
  }) async {
    _expiryTimers.remove(notificationId)?.cancel();
    // Same id in both renderings, and only one of them is ever showing — but
    // cancelling both is two cheap no-ops and removes any doubt about which
    // path posted this particular order.
    await NewOrderCallNotification.cancel(notificationId);
    try {
      await (plugin ?? FlutterLocalNotificationsPlugin())
          .cancel(notificationId);
    } catch (_) {
      // Best effort: a cancel for an already-gone notification is a no-op, and
      // must never break the tap/action path that called it.
    }
  }

  /// Schedule the one-shot rewrite that replaces the countdown with a static
  /// "still waiting" banner the moment the response window closes.
  ///
  /// Android only: a `chronometerCountDown` that passes its target starts
  /// counting UP in negative time, and since the notification now stays until
  /// the seller acts, that overrun would otherwise sit there indefinitely. iOS
  /// has no chronometer to correct, and re-showing there would re-alert.
  void _armExpiry(
    FlutterLocalNotificationsPlugin plugin, {
    required String key,
    required int notificationId,
    required Duration remaining,
    required String title,
    required String body,
    required StyleInformation styleInformation,
    required String payload,
  }) {
    if (!Platform.isAndroid) return;
    _expiryTimers.remove(notificationId)?.cancel();
    _expiryTimers[notificationId] = Timer(remaining, () {
      _expiryTimers.remove(notificationId);
      _showExpired(
        plugin,
        key: key,
        notificationId: notificationId,
        title: title,
        body: body,
        styleInformation: styleInformation,
        payload: payload,
      );
    });
  }

  /// Re-post the same notification without the countdown, keeping it sticky
  /// and keeping both buttons.
  ///
  /// Checks the shade first: the Dismiss button is handled in the FCM
  /// background isolate even while this one is alive, so without the check a
  /// notification the seller just dismissed would come back from the dead.
  Future<void> _showExpired(
    FlutterLocalNotificationsPlugin plugin, {
    required String key,
    required int notificationId,
    required String title,
    required String body,
    required StyleInformation styleInformation,
    required String payload,
  }) async {
    try {
      final active = await plugin.getActiveNotifications();
      if (!active.any((notification) => notification.id == notificationId)) {
        newOrderTimerLog('id=$notificationId already acted on — no rewrite');
        return;
      }

      await plugin.show(
        notificationId,
        title,
        '$body • $kNewOrderTimerExpiredNote',
        NotificationDetails(
          android: AndroidNotificationDetails(
            kNewOrderTimerChannelId,
            kNewOrderTimerChannelName,
            channelDescription: kNewOrderTimerChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
            // Silent: this is the same alert, re-rendered — not a new one.
            playSound: false,
            enableVibration: false,
            onlyAlertOnce: true,
            icon: '@drawable/ic_stat',
            color: kNewOrderTimerAccent,
            styleInformation: styleInformation,
            // Still unskippable, still only leaves on a tap.
            ongoing: true,
            additionalFlags: Int32List.fromList([kFlagNoClear]),
            autoCancel: true,
            actions: _actionsFor(key),
          ),
        ),
        payload: payload,
      );
      newOrderTimerLog('id=$notificationId countdown ended — banner rewritten');
    } catch (e) {
      // The overrun counter is cosmetic; failing to fix it must not surface.
      newOrderTimerLog('expiry rewrite failed for id=$notificationId: $e');
    }
  }

  /// View / Cancel — the only two exits, shared by both renders.
  ///
  /// Plain brand-blue text, no red/green. Only the fallback rendering uses
  /// these; the native CallStyle path draws its own buttons.
  List<AndroidNotificationAction> _actionsFor(String key) =>
      <AndroidNotificationAction>[
        AndroidNotificationAction(
          newOrderViewActionId(key),
          'View',
          titleColor: kNewOrderTimerAccent,
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          newOrderDismissActionId(key),
          'Cancel',
          titleColor: kNewOrderTimerAccent,
          // Pure dismissal — must not drag the app to the foreground.
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ];

  /// When the countdown ends.
  ///
  /// Reads, in order: an absolute `expiryTime` / `expiresAt` (ISO-8601 or
  /// epoch millis) and a relative `ttl_seconds` / `timer_seconds` /
  /// `countdown_seconds`, from the data map first and the decoded `payload`
  /// second. Anything absent, unparseable, or beyond
  /// [kNewOrderTimerMaxSeconds] falls back to
  /// [kNewOrderTimerDefaultSeconds] — a broken timestamp must not pin a
  /// notification to the shade.
  DateTime _resolveDeadline(Map<dynamic, dynamic> data) {
    final now = DateTime.now();
    final fallback = now.add(const Duration(seconds: kNewOrderTimerDefaultSeconds));
    final payload = _decodePayload(data);
    final sources = <Map<dynamic, dynamic>>[
      data,
      if (payload != null) payload,
      if (payload?['metadata'] is Map)
        payload!['metadata'] as Map<dynamic, dynamic>,
    ];

    for (final source in sources) {
      for (final key in const ['expiryTime', 'expiresAt', 'expires_at']) {
        final parsed = _parseInstant(source[key]);
        if (parsed != null) {
          return _clampDeadline(parsed, now, fallback);
        }
      }
      for (final key in const [
        'ttl_seconds',
        'ttlSeconds',
        'timer_seconds',
        'countdown_seconds',
      ]) {
        final seconds = _parseInt(source[key]);
        if (seconds != null && seconds > 0) {
          return _clampDeadline(
              now.add(Duration(seconds: seconds)), now, fallback);
        }
      }
    }
    return fallback;
  }

  /// Keeps a payload-supplied deadline inside a sane window.
  DateTime _clampDeadline(DateTime deadline, DateTime now, DateTime fallback) {
    if (!deadline.isAfter(now)) return deadline; // already expired — show() bails
    final seconds = deadline.difference(now).inSeconds;
    return seconds > kNewOrderTimerMaxSeconds ? fallback : deadline;
  }

  Future<ByteArrayAndroidBitmap?> _downloadImage(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return ByteArrayAndroidBitmap(response.bodyBytes);
      }
    } catch (e) {
      newOrderTimerLog('image download failed ($url): $e');
    }
    return null;
  }

  /// The name the call template shows most prominently.
  ///
  /// The customer, when the push names them — that is the useful thing on a
  /// call-shaped alert. Falls back to the notification title so the slot is
  /// never the bare app name.
  String _callerFor(Map<dynamic, dynamic> data, String title) {
    for (final key in const [
      'senderName',
      'customerName',
      'customer_name',
      'userName',
    ]) {
      final value = (data[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return title;
  }

  String _humanRemaining(Duration remaining) {
    final minutes = remaining.inMinutes;
    if (minutes < 1) return '${remaining.inSeconds}s';
    final seconds = remaining.inSeconds % 60;
    return seconds == 0 ? '${minutes}m' : '${minutes}m ${seconds}s';
  }
}

/// Hand "the seller opened this order" events from the native CallStyle alert
/// to [onOpen], which gets the original FCM data map.
///
/// Covers both entry paths: [NewOrderCallNotification.setOrderOpenedListener]
/// for a running app, and one drain of [readPendingAction] for a cold start,
/// where the intent lands before the Dart engine can listen. Each event
/// cancels its own notification first — with `ongoing` + `autoCancel(false)`
/// the OS will not do it for us, which is the point.
///
/// [coldStart] is invoked instead of [onOpen] for the launch-time drain, so
/// callers can push a home shell underneath before routing.
void bindNewOrderAlertRouting({
  required void Function(Map<String, dynamic> data) onOpen,
  Future<void> Function(Map<String, dynamic> data)? coldStart,
}) {
  NewOrderCallNotification.setOrderOpenedListener((action) {
    final data = _decodeAlertPayload(action);
    if (data != null) onOpen(data);
  });

  unawaited(NewOrderCallNotification.readPendingAction().then((action) async {
    if (action == null) return;
    final data = _decodeAlertPayload(action);
    if (data == null) return;
    if (coldStart != null) {
      await coldStart(data);
    } else {
      onOpen(data);
    }
  }));
}

Map<String, dynamic>? _decodeAlertPayload(NewOrderOpenedAction action) {
  unawaited(NewOrderCallNotification.cancel(action.notificationId));
  try {
    final decoded = jsonDecode(action.payload);
    if (decoded is Map) {
      newOrderTimerLog('order opened from alert id=${action.notificationId}');
      return Map<String, dynamic>.from(decoded);
    }
  } catch (e) {
    newOrderTimerLog('opened-alert payload unreadable: $e');
  }
  return null;
}

/// `payload` arrives as a JSON string over FCM, but as a Map when a push is
/// replayed in-process. Null when absent or malformed.
Map<dynamic, dynamic>? _decodePayload(Map<dynamic, dynamic> data) {
  final raw = data['payload'];
  if (raw is Map) return raw;
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded;
    } catch (_) {
      // Malformed — callers fall back to the top-level keys.
    }
  }
  return null;
}

DateTime? _parseInstant(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final epoch = int.tryParse(text);
  // Seconds-vs-millis: a 10-digit epoch is seconds.
  if (epoch != null) {
    return DateTime.fromMillisecondsSinceEpoch(
        text.length <= 10 ? epoch * 1000 : epoch);
  }
  return DateTime.tryParse(text)?.toLocal();
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString().trim());
}
