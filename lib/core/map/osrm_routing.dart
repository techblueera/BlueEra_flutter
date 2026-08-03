import 'package:BlueEra/core/map/lat_lng.dart';
import 'package:BlueEra/core/map/osm_config.dart';
import 'package:BlueEra/core/map/osm_http_client.dart';

/// Road routing over OSRM, plus the handful of value types the app's routing
/// call sites already speak.
///
/// ## Why these types look like someone else's
///
/// [PointLatLng], [PolylineResult], [PolylineWayPoint] and [TravelMode] are
/// deliberate re-implementations of `flutter_polyline_points`' public API —
/// same names, same fields, same constructor shapes. Twelve screens construct
/// and read these types. Keeping the names means each of those screens changes
/// its **import line and nothing else**, which is the difference between a
/// mechanical migration and twelve chances to introduce a bug in live ride
/// tracking.
///
/// The package itself is gone: it was a thin wrapper over Google's Directions
/// API and there is nothing left for it to wrap.

/// A coordinate, in the shape the routing call sites already use.
///
/// Distinct from [LatLng] only because the call sites already write
/// `PointLatLng(...)`. Convert freely with [toLatLng].
class PointLatLng {
  const PointLatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  LatLng toLatLng() => LatLng(latitude, longitude);

  factory PointLatLng.from(LatLng value) =>
      PointLatLng(value.latitude, value.longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointLatLng &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'PointLatLng($latitude, $longitude)';
}

/// An intermediate stop. Used by the multi-stop goods flow.
class PolylineWayPoint {
  const PolylineWayPoint({required this.location, this.stopOver = true});

  /// `"lat,lng"`. The string form is what the old package took and what
  /// `goods_multi_order_booking_main.dart` still passes.
  final String location;
  final bool stopOver;

  /// Null when the string is not a parseable `lat,lng` pair, so a malformed
  /// stop is skipped rather than sent to OSRM as garbage.
  PointLatLng? toPoint() {
    final parts = location.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return PointLatLng(lat, lng);
  }

  @override
  String toString() => 'PolylineWayPoint($location)';
}

/// How to travel. OSRM calls these "profiles".
enum TravelMode { driving, walking, bicycling, transit }

/// A computed route.
///
/// Field names match what the twelve call sites already read: [points],
/// [totalDistanceValue] (metres) and [totalDurationValue] (seconds).
class PolylineResult {
  const PolylineResult({
    this.points = const [],
    this.totalDistanceValue = 0,
    this.totalDurationValue = 0,
    this.distanceTexts = const [],
    this.durationTexts = const [],
    this.errorMessage,
    this.status,
  });

  /// The route geometry, densely sampled — this is what gets drawn.
  final List<PointLatLng> points;

  /// Whole-route distance in **metres**.
  final int totalDistanceValue;

  /// Whole-route duration in **seconds**.
  final int totalDurationValue;

  /// Per-leg human-readable values, populated only for multi-stop routes.
  final List<String> distanceTexts;
  final List<String> durationTexts;

  final String? errorMessage;
  final String? status;

  bool get isUsable => points.length >= 2;
}

/// Routes over an OSRM server.
///
/// Most callers should go through `RoutePolylineService.fetch` instead, which
/// adds the session cache and rate floor that keep a moving vehicle from
/// requesting a fresh route every tick.
class OsrmRouting {
  const OsrmRouting._();

  /// OSRM profile names. The demo server hosts the car profile; a self-hosted
  /// instance is normally built for one profile at a time, so check yours
  /// supports walking/cycling before relying on them.
  ///
  /// `transit` has no OSRM equivalent — OSRM routes roads, not timetables — so
  /// it falls back to driving, which is what the one transit-ish call site
  /// (goods transport) actually wants anyway.
  static String _profile(TravelMode mode) {
    switch (mode) {
      case TravelMode.walking:
        return 'walking';
      case TravelMode.bicycling:
        return 'cycling';
      case TravelMode.driving:
      case TravelMode.transit:
        return 'driving';
    }
  }

  /// Fetch a route. Returns null on any failure — network, a non-`Ok` OSRM
  /// code, or a reply with no usable geometry.
  ///
  /// Null means "no route this time", and callers keep whatever line they are
  /// already drawing rather than clearing it. That contract is inherited from
  /// the service this replaced and several tracking screens depend on it.
  static Future<PolylineResult?> route({
    required PointLatLng origin,
    required PointLatLng destination,
    TravelMode mode = TravelMode.driving,
    List<PolylineWayPoint> wayPoints = const [],
  }) async {
    // OSRM takes coordinates as `lon,lat` pairs separated by semicolons — the
    // reverse of Google's `lat,lng`. Getting this backwards yields a route
    // through the Indian Ocean rather than an error, so it is worth being
    // explicit about.
    final stops = <PointLatLng>[
      origin,
      ...wayPoints.map((w) => w.toPoint()).whereType<PointLatLng>(),
      destination,
    ];
    final path = stops.map((p) => '${p.longitude},${p.latitude}').join(';');

    try {
      final response = await OsmHttpClient.instance.get(
        '${OsmConfig.osrmBaseUrl}/route/v1/${_profile(mode)}/$path',
        queryParameters: OsmHttpClient.withKey({
          // Full geometry, not the simplified overview — these lines are drawn
          // at street zoom during navigation and a simplified route visibly
          // cuts corners through buildings.
          'overview': 'full',
          'geometries': 'polyline',
          'steps': 'false',
          'alternatives': 'false',
        }),
      );

      final body = response.data;
      if (body is! Map) return null;
      if (body['code'] != 'Ok') {
        return PolylineResult(
          status: body['code']?.toString(),
          errorMessage: body['message']?.toString(),
        );
      }

      final routes = body['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final first = routes.first;
      if (first is! Map) return null;

      final geometry = first['geometry'];
      if (geometry is! String) return null;

      final points = decodePolyline(geometry);
      if (points.length < 2) return null;

      return PolylineResult(
        points: points,
        // OSRM returns metres and seconds as doubles; the call sites treat both
        // as whole numbers.
        totalDistanceValue: (first['distance'] as num?)?.round() ?? 0,
        totalDurationValue: (first['duration'] as num?)?.round() ?? 0,
        status: 'Ok',
      );
    } catch (_) {
      return null;
    }
  }

  /// Decodes an encoded polyline into coordinates.
  ///
  /// This is Google's polyline algorithm at precision 5, which OSRM also emits
  /// when asked for `geometries=polyline` — so the same decoder serves both and
  /// the routes drawn before and after this migration are pixel-identical in
  /// resolution.
  ///
  /// Kept here rather than pulled from a package because it is thirty lines
  /// that will never change, and it was the only thing the app still needed
  /// `flutter_polyline_points` for.
  static List<PointLatLng> decodePolyline(String encoded,
      {int precision = 5}) {
    final points = <PointLatLng>[];
    final factor = _pow10(precision);

    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;

      // Latitude delta.
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;

      // Longitude delta.
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(PointLatLng(lat / factor, lng / factor));
    }

    return points;
  }

  static double _pow10(int exponent) {
    var value = 1.0;
    for (var i = 0; i < exponent; i++) {
      value *= 10;
    }
    return value;
  }
}
