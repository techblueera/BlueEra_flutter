/// Shared helpers for the incoming-ride RING notification.
///
/// Lives outside `AppNotificationHandler` because the background/terminated
/// FCM isolate in `main.dart` is a top-level function with no access to the
/// handler's instance state, and both sides must agree on the notification id.
library;

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

/// Pull the ride's order id out of an FCM data payload.
///
/// The broadcast and fare-call payloads both nest it under `payload.metadata`,
/// but spellings differ between producers, so several keys are tried.
String? orderIdFromRidePayload(Map<dynamic, dynamic> data, {Map? metadata}) {
  for (final source in [metadata, data]) {
    if (source == null) continue;
    for (final key in const ['orderId', 'order_id', 'rideId', 'ride_id']) {
      final value = source[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
  }
  return null;
}
