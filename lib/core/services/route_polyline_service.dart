import 'package:BlueEra/core/map/osrm_routing.dart';

/// The app's single entry point to road routing.
///
/// Before this existed twelve screens fetched routes directly, each with its own
/// idea of when a refetch was justified — or no idea at all. During a ride the
/// rider's phone and the customer's phone were both refetching the whole route
/// every few seconds, for the same journey.
///
/// Everything goes through [fetch], which applies three protections that no
/// caller can forget:
///
///  1. **Coordinate rounding.** Origin/destination are rounded to
///     [_kKeyPrecision] decimals (~110 m) to form a cache key, so a vehicle
///     creeping forward does not buy a new route.
///  2. **A session cache.** A key that has been fetched before returns instantly
///     — which also means re-entering a tracking screen, or two screens drawing
///     the same leg, costs nothing.
///  3. **A minimum interval.** Even a genuinely new key waits [_kMinInterval]
///     since the last network call. On a fast road 110 m passes in seconds, so
///     the distance guard alone is not a ceiling.
///
/// Returns [PolylineResult] so call sites keep reading `points`,
/// `totalDistanceValue` and `totalDurationValue` exactly as before — and the
/// result stays **nullable**: null means "no route this time" (throttled or
/// failed), and callers should keep whatever line they are already drawing
/// rather than clearing it.
///
/// ## Why the throttling survived the move off Google
///
/// These guards were built to control a **bill**. Routing now goes to OSRM,
/// where a self-hosted instance costs nothing per request — so the obvious move
/// is to delete them.
///
/// They stay, for two reasons that outlast the billing one:
///
///  * Until [OsmConfig.osrmBaseUrl] points somewhere we control, this traffic
///    lands on the **public OSRM demo server**, whose usage policy is far
///    stricter than anything Google enforced. Removing the throttle would get
///    the app's users IP-blocked, which fails harder than a bill.
///  * A self-hosted router still has a CPU. Two phones per ride, each asking
///    for a full route every few seconds, is load we would simply be moving
///    onto our own machine rather than eliminating.
///
/// The real fix is still the backend computing each ride's route once and
/// putting the encoded polyline in the order payload, so neither app routes at
/// all — see `docs/GOOGLE_MAPS_BACKEND_DEVOPS_GUIDE.md` §B3. That is now a
/// latency and simplicity win rather than a cost one, but it is still the right
/// destination.
class RoutePolylineService {
  RoutePolylineService._();

  /// Decimal places kept when building the cache key. 3 ≈ 110 m, which at the
  /// zoom these maps sit at is a few pixels of line.
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

    // New leg, but we routed too recently. The caller keeps its current line;
    // the next position update will try again.
    if (!_claimSlot()) return null;

    final result = await OsrmRouting.route(
      origin: origin,
      destination: destination,
      mode: mode,
      wayPoints: wayPoints,
    );
    if (result == null) return null;

    return _remember(key, result);
  }

  /// Drop everything remembered. For logout / account switch, where holding
  /// another user's journeys in memory serves no purpose.
  static void clear() {
    _cache.clear();
    _lastNetworkCall = null;
  }
}
