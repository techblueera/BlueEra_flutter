import 'dart:async';

import 'location_update_service.dart';

/// Publishes the rider's live position to the map-service during an ACTIVE
/// ride, feeding the customer's live-tracking SSE
/// (`/provider/live-stream/$riderId`).
///
/// Why this exists instead of "POST on every GPS tick":
/// a naive per-tick publish only covers the moving-with-good-network case and
/// leaves the customer's map frozen in the three cases that matter most on a
/// real trip — the same cases Zomato/Swiggy handle:
///
///  1. **Stationary rider** (red light, waiting at pickup) — `getPositionStream`
///     stops firing once the rider stops moving (10 m distanceFilter), so the
///     last position must be *re-sent on a heartbeat*. This also keeps the
///     map-service from auto-closing the provider stream after silence.
///  2. **Network blip / rejected POST** — a single dropped ping must be retried,
///     otherwise the customer marker jumps/stalls until the next movement.
///  3. **Screen handoff** (pickup-navigation → passenger-destination) — the
///     publisher must survive one screen disposing while the next starts, so
///     start/stop is **reference counted**: it only truly stops once every ride
///     screen has released it.
///
/// Cadence: a fresh GPS fix is sent immediately (throttled to [_minSendGap]);
/// when no fix arrives (stationary) the [_heartbeat] resends the last known
/// coordinate every [_heartbeatInterval]. Net effect is a steady ~3–5 s update
/// stream to the customer whether the rider is moving or not.
class RideLocationPublisher {
  RideLocationPublisher._();
  static final RideLocationPublisher _instance = RideLocationPublisher._();
  factory RideLocationPublisher() => _instance;

  /// Heartbeat cadence — resends the last coordinate when the rider is
  /// stationary and keeps the server-side provider stream alive.
  static const Duration _heartbeatInterval = Duration(seconds: 5);

  /// Minimum gap between two sends, so a burst of GPS fixes (or a
  /// movement-send immediately followed by a heartbeat) doesn't hammer the API.
  static const Duration _minSendGap = Duration(seconds: 3);

  Timer? _heartbeat;

  /// Number of live ride screens currently using the publisher. The publisher
  /// runs while this is > 0 and stops when it returns to 0 — this is what keeps
  /// it alive across the pickup → destination screen handoff.
  int _refCount = 0;

  double? _lastLat;
  double? _lastLng;

  /// Timestamp of the last *successful* send. `null` means "nothing sent yet"
  /// or "last attempt failed" — either way the next opportunity should send.
  DateTime? _lastSentAt;

  /// Guards against overlapping in-flight POSTs.
  bool _inFlight = false;

  bool get isActive => _refCount > 0;

  /// Register a ride screen and start publishing if not already running.
  /// Balance every [start] with exactly one [stop] (initState / dispose).
  void start() {
    _refCount++;
    if (_heartbeat != null) return;
    _heartbeat = Timer.periodic(_heartbeatInterval, (_) => _tick());
  }

  /// Release a ride screen. The publisher keeps running until the last screen
  /// stops it, then clears its cached position.
  void stop() {
    if (_refCount == 0) return;
    _refCount--;
    if (_refCount > 0) return;
    _heartbeat?.cancel();
    _heartbeat = null;
    _lastLat = null;
    _lastLng = null;
    _lastSentAt = null;
    _inFlight = false;
  }

  /// Feed a fresh GPS fix from a ride screen. Cached as the latest known
  /// position and sent immediately if the throttle window has elapsed;
  /// otherwise the heartbeat will pick it up.
  void updatePosition(double lat, double lng) {
    _lastLat = lat;
    _lastLng = lng;
    if (!isActive) return;
    final last = _lastSentAt;
    if (last == null || DateTime.now().difference(last) >= _minSendGap) {
      _send();
    }
  }

  /// Heartbeat: resend the last known coordinate when the rider hasn't moved
  /// (or retry after a failed send) so the customer's stream never goes stale.
  void _tick() {
    final last = _lastSentAt;
    if (last != null && DateTime.now().difference(last) < _minSendGap) return;
    _send();
  }

  Future<void> _send() async {
    if (_inFlight) return;
    final lat = _lastLat;
    final lng = _lastLng;
    if (lat == null || lng == null) return;
    _inFlight = true;
    try {
      final ok = await LiveLocationService().publishLocation(lat, lng);
      // Only stamp on success — a failed send leaves _lastSentAt untouched so
      // the next heartbeat retries the same (last known) coordinate.
      if (ok) _lastSentAt = DateTime.now();
    } finally {
      _inFlight = false;
    }
  }
}
