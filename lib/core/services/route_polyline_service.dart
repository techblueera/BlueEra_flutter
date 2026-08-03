import 'package:BlueEra/environment_config.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

/// The app's single entry point to the Google **Directions** API.
///
/// Directions is one of the most expensive things we buy, and before this
/// existed twelve screens called it directly, each with its own idea of when a
/// refetch was justified — or no idea at all. During a ride the rider's phone
/// and the customer's phone were both refetching the whole route every few
/// seconds, for the same journey. See `docs/GOOGLE_MAPS_COST_GUIDE.md` §3.4.
///
/// Everything goes through [fetch] now, which applies three protections that no
/// caller can forget:
///
///  1. **Coordinate rounding.** Origin/destination are rounded to
///     [_kKeyPrecision] decimals (~110 m) to form a cache key, so a vehicle
///     creeping forward does not buy a new route.
///  2. **A session cache.** A key that has been fetched before returns instantly
///     and for free — which also means re-entering a tracking screen, or two
///     screens drawing the same leg, costs nothing.
///  3. **A minimum interval.** Even a genuinely new key waits
///     [_kMinInterval] since the last network call. On a fast road 110 m passes
///     in seconds, so the distance guard alone is not a ceiling.
///
/// Returns the raw [PolylineResult] so call sites keep reading `points`,
/// `totalDistanceValue` and `totalDurationValue` exactly as before — but the
/// result is now **nullable**: null means "no route this time" (throttled or
/// failed), and callers should keep whatever line they are already drawing
/// rather than clearing it.
///
/// This is a stopgap. The real fix is the backend computing each ride's route
/// once and putting the encoded polyline in the order payload, so neither app
/// calls Directions at all — see `docs/GOOGLE_MAPS_BACKEND_DEVOPS_GUIDE.md` §B3.
class RoutePolylineService {
  RoutePolylineService._();

  /// Decimal places kept when building the cache key. 3 ≈ 110 m, which at the
  /// zoom these maps sit at is a few pixels of line.
  ///
  /// Was effectively 4 (~11 m) in the one screen that had a guard at all, which
  /// a moving vehicle clears every second or two — so that guard never held.
  static const int _kKeyPrecision = 3;

  /// Hard floor between two network calls, whatever the distance says.
  static const Duration _kMinInterval = Duration(seconds: 30);

  /// Cap on remembered routes, so a long session cannot grow this without
  /// bound. Oldest key is dropped first; routes are cheap to re-fetch if a
  /// dropped one is needed again.
  static const int _kMaxCacheEntries = 64;

  static final Map<String, PolylineResult> _cache = {};
  static DateTime? _lastNetworkCall;

  static String _point(PointLatLng p) =>
      '${p.latitude.toStringAsFixed(_kKeyPrecision)},'
      '${p.longitude.toStringAsFixed(_kKeyPrecision)}';

  static String _key(
    PointLatLng a,
    PointLatLng b,
    TravelMode mode,
    List<PolylineWayPoint> via,
    String suffix,
  ) {
    final stops = via.map((w) => w.location).join('|');
    return '${_point(a)}>${_point(b)}@${mode.name}'
        '${stops.isEmpty ? '' : '/via:$stops'}$suffix';
  }

  /// True when a network call is allowed right now. Stamps the clock when it
  /// says yes, so two callers in the same frame cannot both get through.
  static bool _claimSlot() {
    final last = _lastNetworkCall;
    if (last != null && DateTime.now().difference(last) < _kMinInterval) {
      return false;
    }
    _lastNetworkCall = DateTime.now();
    return true;
  }

  static PolylineResult? _remember(String key, PolylineResult result) {
    // Only a usable route is worth remembering — caching an empty result would
    // pin a failure in place for the rest of the session.
    if (result.points.length >= 2) {
      if (_cache.length >= _kMaxCacheEntries) {
        _cache.remove(_cache.keys.first);
      }
      _cache[key] = result;
    }
    return result;
  }

  /// Route between two points, subject to the cache and throttle described on
  /// the class. Null when nothing is available right now.
  ///
  /// [wayPoints] covers the multi-stop goods flow; they are part of the cache
  /// key, so changing a stop correctly counts as a different route.
  static Future<PolylineResult?> fetch({
    required PointLatLng origin,
    required PointLatLng destination,
    TravelMode mode = TravelMode.driving,
    List<PolylineWayPoint> wayPoints = const [],
  }) async {
    final key = _key(origin, destination, mode, wayPoints, '');

    // Seen this leg already — free, and instant.
    final cached = _cache[key];
    if (cached != null) return cached;

    // New leg, but we bought a route too recently. The caller keeps its current
    // line; the next position update will try again.
    if (!_claimSlot()) return null;

    try {
      final result =
          await PolylinePoints(apiKey: googleMapKey).getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: origin,
          destination: destination,
          mode: mode,
          wayPoints: wayPoints,
        ),
      );
      return _remember(key, result);
    } catch (_) {
      // Let the next update retry; nothing cached, nothing thrown at the UI.
      return null;
    }
  }

  /// ## Deliberately NOT routed through here
  ///
  /// `RideBookingController._resolveRoute` still calls Directions itself, and
  /// should keep doing so:
  ///
  ///  * It runs **once per fare quote**, when the user picks pickup + drop — not
  ///    on a timer, so it is not part of the per-tick problem this class exists
  ///    to solve.
  ///  * It already guards with its own pickup→drop cache key.
  ///  * It uses the **Routes API** (`getRouteBetweenCoordinatesV2`), a different
  ///    endpoint returning a different shape, with a legacy Directions fallback.
  ///
  /// Most importantly, [fetch] can return null when throttled, and that is the
  /// right answer for a map line but the wrong answer for a quote: the user
  /// tapped a button and is owed a distance. Silently rate-limiting that path
  /// would turn a cost optimisation into a broken booking.

  /// Drop everything remembered. For logout / account switch, where holding
  /// another user's journeys in memory serves no purpose.
  static void clear() {
    _cache.clear();
    _lastNetworkCall = null;
  }
}
