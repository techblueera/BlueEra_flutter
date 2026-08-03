import 'dart:math' as math;

/// A geographic coordinate.
///
/// This is a **drop-in replacement** for `google_maps_flutter`'s `LatLng`: same
/// class name, same positional `(latitude, longitude)` constructor, same field
/// names. Migrating a file off Google Maps is therefore usually a one-line
/// change to its import, not a rewrite — which is what made a 40-screen swap
/// tractable at all.
///
/// It is a plain value type with no plugin dependency, so controllers, models,
/// sockets and repos can hold coordinates without importing a map package.
class LatLng {
  const LatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// Both orderings appear in this codebase's payloads, so they get explicit
  /// names rather than one ambiguous `fromJson`.
  factory LatLng.fromLatLngJson(Map<String, dynamic> json) => LatLng(
        (json['lat'] ?? json['latitude'] ?? 0).toDouble(),
        (json['lng'] ?? json['lon'] ?? json['longitude'] ?? 0).toDouble(),
      );

  /// GeoJSON order — `[longitude, latitude]`. Note the reversal; getting this
  /// backwards puts Dehradun in the Indian Ocean, and it is the single most
  /// common bug when moving from Google's APIs to OSM's, because Google speaks
  /// `lat,lng` and GeoJSON speaks `lon,lat`.
  factory LatLng.fromGeoJson(List<dynamic> coords) => LatLng(
        (coords[1] as num).toDouble(),
        (coords[0] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'lat': latitude, 'lng': longitude};

  /// `lat,lng` — the order Nominatim and Google both use in query strings.
  String get asQueryPair => '$latitude,$longitude';

  /// `lng,lat` — the order OSRM uses in its path segments.
  String get asOsrmPair => '$longitude,$latitude';

  bool get isZero => latitude == 0.0 && longitude == 0.0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

/// A rectangular geographic region, matching `google_maps_flutter`'s
/// `LatLngBounds` field-for-field so camera-fitting call sites port unchanged.
class LatLngBounds {
  LatLngBounds({required this.southwest, required this.northeast});

  final LatLng southwest;
  final LatLng northeast;

  /// The tightest box containing every point.
  ///
  /// Screens used to build this by hand with four `reduce` calls over a marker
  /// list, and at least one got the min/max the wrong way round for longitude —
  /// which silently produces an inverted box that the camera then refuses to
  /// fit. Doing it once, here, removes that class of bug.
  ///
  /// Returns null for an empty list; a single point yields a zero-area box,
  /// which [padded] can inflate into something a camera can actually frame.
  static LatLngBounds? containing(Iterable<LatLng> points) {
    if (points.isEmpty) return null;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Grows the box by [degrees] on every side.
  ///
  /// A zero-area box — one marker, or a rider sitting exactly on the pickup —
  /// gives the map no scale to fit and it zooms to maximum. Padding gives it
  /// something to work with. The 0.005° default is roughly 500 m.
  LatLngBounds padded([double degrees = 0.005]) => LatLngBounds(
        southwest:
            LatLng(southwest.latitude - degrees, southwest.longitude - degrees),
        northeast:
            LatLng(northeast.latitude + degrees, northeast.longitude + degrees),
      );

  LatLng get center => LatLng(
        (southwest.latitude + northeast.latitude) / 2,
        (southwest.longitude + northeast.longitude) / 2,
      );

  bool contains(LatLng point) =>
      point.latitude >= southwest.latitude &&
      point.latitude <= northeast.latitude &&
      point.longitude >= southwest.longitude &&
      point.longitude <= northeast.longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLngBounds &&
          other.southwest == southwest &&
          other.northeast == northeast;

  @override
  int get hashCode => Object.hash(southwest, northeast);

  @override
  String toString() => 'LatLngBounds($southwest, $northeast)';
}

/// Great-circle distance in **metres** between two coordinates.
///
/// Available here so that measuring a gap never requires a map controller, a
/// plugin, or a network call. Several screens were spending a Directions
/// request purely to learn "how far apart are these two points" — which is
/// arithmetic.
double distanceBetweenMetres(LatLng a, LatLng b) {
  const earthRadiusMetres = 6371000.0;

  double toRadians(double degrees) => degrees * math.pi / 180.0;

  final dLat = toRadians(b.latitude - a.latitude);
  final dLng = toRadians(b.longitude - a.longitude);

  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(toRadians(a.latitude)) *
          math.cos(toRadians(b.latitude)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);

  return 2 * earthRadiusMetres * math.asin(math.min(1.0, math.sqrt(h)));
}
