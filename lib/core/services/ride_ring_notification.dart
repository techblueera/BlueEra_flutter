/// Shared helpers for the incoming-ride RING notification.
///
/// Lives outside `AppNotificationHandler` because the background/terminated
/// FCM isolate in `main.dart` is a top-level function with no access to the
/// handler's instance state, and both sides must agree on the notification id.
library;

import 'dart:convert';
import 'dart:developer' as developer;

/// One tag for the whole ride-notification path — ring, tap, route, dismiss.
///
/// Filter the device log with `RIDE_NOTIF` to follow a single
/// `broadcast_ride_request` from FCM delivery through to which screen opened.
/// Deliberately covers BOTH isolates: the background/terminated handler in
/// `main.dart` runs in its own isolate, so without a shared tag its half of the
/// story is easy to miss.
///
/// `adb logcat | grep RIDE_NOTIF`
void rideNotifLog(String message) => developer.log('[RIDE_NOTIF] $message');

/// Dump a ride push's full payload, decoded and readable.
///
/// The raw `message.data` map is not enough on its own: `payload` arrives as a
/// **JSON string**, so printing the map shows it escaped on one unreadable
/// line, and `metadata` — where `orderId`, `rideDetails` and `assignedRider`
/// live — stays buried inside it. This decodes and prints it separately.
///
/// [where] labels the entry point (`bg isolate`, `foreground`, `tap`) so the
/// same push can be followed across the isolate boundary.
void rideNotifDumpPayload(String where, Map<dynamic, dynamic> data) {
  // Everything except `payload`, which is printed decoded below — otherwise
  // the interesting part is duplicated as an escaped blob.
  final top = Map<dynamic, dynamic>.from(data)..remove('payload');
  _dumpChunked('$where: data', top.toString());

  final raw = data['payload'];
  dynamic decoded = raw;
  if (raw is String && raw.isNotEmpty) {
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      rideNotifLog('$where: payload is a String but not valid JSON ($e)');
      _dumpChunked('$where: payload(raw)', raw);
      return;
    }
  }
  if (decoded == null) {
    rideNotifLog('$where: payload absent');
    return;
  }

  _dumpChunked('$where: payload', _pretty(decoded));
  if (decoded is Map && decoded['metadata'] != null) {
    _dumpChunked('$where: metadata', _pretty(decoded['metadata']));
  }
}

String _pretty(dynamic value) {
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return value.toString(); // non-encodable (nested non-JSON types)
  }
}

/// logcat drops anything past ~4 KB on a single line, which is exactly where a
/// ride payload with rideDetails lands. Split so nothing is silently lost.
void _dumpChunked(String label, String body) {
  const chunk = 800;
  if (body.length <= chunk) {
    rideNotifLog('$label=$body');
    return;
  }
  final parts = (body.length / chunk).ceil();
  for (var i = 0; i < parts; i++) {
    final start = i * chunk;
    final end = (start + chunk).clamp(0, body.length);
    rideNotifLog('$label[${i + 1}/$parts]=${body.substring(start, end)}');
  }
}

/// FCM `operation` values that must RING like an incoming call rather than
/// ding like a chat message.
///
/// `broadcast_ride_request` is the broadcast-dispatch ping: the server rings
/// every nearby rider at once and the first to accept wins. It reuses the
/// existing `fare_ride_incoming_call` presentation wholesale — same channel,
/// same ringtone, same full-screen intent — so riders get one consistent
/// experience. See docs/backend/RIDER_BROADCAST_DISPATCH_FRONTEND_GUIDE.md §7.
const Set<String> kRingingRideOperations = {
  'fare_ride_incoming_call',
  'broadcast_ride_request',
};

/// Silent push telling a LOSING rider that the race is over. Must dismiss the
/// ring without ever showing a banner. Guide §7.4.
const String kBroadcastRideClosedOperation = 'broadcast_ride_closed';

/// Channel + sound for the incoming-ride ring.
///
/// The tone is `new_order_mu` — the SAME chime the shop/grocery order alerts
/// use (`order_alerts_v3`), so a rider hears one consistent "there is work for
/// you" sound whether the job arrives as a shop order or a ride request.
///
/// **The id is versioned because Android freezes a channel's sound at creation
/// time.** Editing the sound on `…_v2` would change nothing on any device that
/// already has that channel — every install since the last release would keep
/// ringing with `hangouts_call`. Only a fresh id picks up the new tone, so bump
/// this whenever the sound changes and never edit an existing channel's sound.
const String kRideRingChannelId = 'fare_ride_incoming_ringtone_v3';
const String kRideRingChannelName = 'Ride Requests';
const String kRideRingChannelDescription = 'Incoming ride request alerts';

/// Raw resource under `android/app/src/main/res/raw/`.
const String kRideRingSound = 'new_order_mu';

/// Notification action-button ids, with the order id appended.
///
/// The id has to carry the order because the action is handled in the
/// background isolate, where there is no open screen and no controller holding
/// "which ride is ringing". Without it, Decline could only dismiss the banner
/// locally while the server went on waiting for an answer.
String rideDeclineActionId(String? orderId) => 'fare_ride_decline_${orderId ?? ''}';
String rideViewActionId(String? orderId) => 'fare_ride_view_${orderId ?? ''}';

/// Prefixes accepted for the Decline button — ours plus the server's own
/// spelling from the push's `actions` array (`decline_fare_ride_ORD-…`), so a
/// backend-rendered button works identically.
const List<String> kRideDeclineActionPrefixes = [
  'fare_ride_decline_',
  'decline_fare_ride_',
];

/// Same for View / View Details.
const List<String> kRideViewActionPrefixes = [
  'fare_ride_view_',
  'view_fare_ride_details_',
  'view_fare_ride_',
];

/// Order id embedded in an action id, or null when [actionId] doesn't match
/// any of [prefixes].
String? orderIdFromRideActionId(String actionId, List<String> prefixes) {
  for (final prefix in prefixes) {
    if (actionId.startsWith(prefix)) {
      final id = actionId.substring(prefix.length);
      return id.isEmpty ? null : id;
    }
  }
  return null;
}

/// True when [actionId] is one of the ride buttons, regardless of producer.
bool isRideDeclineAction(String actionId) =>
    actionId == 'fare_ride_decline' ||
    kRideDeclineActionPrefixes.any(actionId.startsWith);

bool isRideViewAction(String actionId) =>
    actionId == 'fare_ride_view' ||
    kRideViewActionPrefixes.any(actionId.startsWith);

/// Notification id for a ride request, derived from its `orderId`.
///
/// Deterministic on purpose: a broadcast loser is dismissed by a separate
/// silent push that only carries the `orderId`, so the id must be
/// recomputable rather than the timestamp it used to be. It also means a
/// re-delivered FCM for the same order replaces its notification instead of
/// stacking a second ringing copy.
///
/// Falls back to a stable non-zero constant when the payload has no order id,
/// so the notification is still cancellable.
int ringNotificationIdFor(String? orderId) {
  final id = (orderId ?? '').trim();
  if (id.isEmpty) return 987654321;
  // Sum code units rather than String.hashCode — the latter is not guaranteed
  // stable across Dart releases, and the background isolate may be running a
  // different app build than the one that posted the notification.
  var sum = 0;
  for (final unit in id.codeUnits) {
    sum = (sum * 31 + unit) % 2147483647;
  }
  return sum == 0 ? 987654321 : sum;
}

/// Keys that carry the customer-facing `ORD-…` order id.
///
/// `Order_id` is deliberately NOT here. `payload.metadata.Order_id` exists in
/// the live broadcast push but holds the Mongo `_id`
/// (`6a5f6cce225ffe42a97b3ff2`), a different id space from the `ORD-…` value
/// every `fare/orders/{orderId}/*` route expects. Accepting it would turn a
/// missing id into a confidently wrong one, which 404s instead of degrading.
const List<String> _orderIdKeys = ['orderId', 'order_id', 'rideId', 'ride_id'];

/// Pull the ride's order id out of an FCM data payload.
///
/// Search order matters. The live `broadcast_ride_request` puts the real id at
/// the **root of the decoded `payload`** — not in `metadata`, and not in the
/// top-level data map:
///
/// ```jsonc
/// data: {
///   operation: "broadcast_ride_request",
///   payload: "{\"orderId\":\"ORD-1784638670140\", … ,\"metadata\":{\"Order_id\":\"6a5f…\"}}"
/// }
/// ```
///
/// Only `metadata` and `data` used to be searched, so every broadcast resolved
/// to `null` and the ring fell back to the shared constant notification id —
/// meaning two concurrent requests collided and `broadcast_ride_closed` could
/// not reliably cancel the ring it was sent to cancel.
///
/// [metadata] may be supplied by callers that already decoded it; the payload
/// is decoded here regardless so no caller has to remember to look.
String? orderIdFromRidePayload(Map<dynamic, dynamic> data, {Map? metadata}) {
  final payload = decodeRidePayload(data);

  for (final source in <Map?>[payload, metadata, payload?['metadata'] as Map?, data]) {
    if (source == null) continue;
    for (final key in _orderIdKeys) {
      final value = source[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
  }

  // Last resort: the server's own action-button ids embed it, e.g.
  // `decline_fare_ride_ORD-1784638670140`.
  return _orderIdFromActionsBlock(data['actions']);
}

/// Decode the `payload` field, which arrives as a JSON string from FCM but as
/// a Map when the push is replayed in-process. Null when absent/malformed.
Map<dynamic, dynamic>? decodeRidePayload(Map<dynamic, dynamic> data) {
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

/// Scrape an `ORD-…` id out of the notification's `actions` array.
String? _orderIdFromActionsBlock(dynamic actions) {
  var list = actions;
  if (list is String && list.isNotEmpty) {
    try {
      list = jsonDecode(list);
    } catch (_) {
      return null;
    }
  }
  if (list is! List) return null;
  for (final action in list) {
    final id = (action is Map ? action['id'] : action)?.toString() ?? '';
    final match = RegExp(r'(ORD-[A-Za-z0-9_-]+)').firstMatch(id);
    if (match != null) return match.group(1);
  }
  return null;
}
