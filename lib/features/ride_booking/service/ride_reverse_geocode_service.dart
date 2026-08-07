import 'dart:collection';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Reverse geocoding for the map pin pickers, with the lookups actually paid
/// for kept to a minimum.
///
/// The naive version — geocode on every camera-idle — is expensive in a way
/// that isn't obvious from the Dart side. `placemarkFromCoordinates` is the
/// PLATFORM geocoder: Android's `Geocoder` and iOS's `CLGeocoder`. Apple rate
/// limits CLGeocoder per app and starts failing with `kCLErrorDomain 2` when
/// hammered, and Android's is backed by a network service that throttles just
/// as happily. A user nudging the pin around a junction for ten seconds can
/// fire a dozen lookups, and the ones that get throttled come back as "no
/// address" — so the naive version doesn't just cost more, it degrades exactly
/// when the user is being most deliberate about the point they want.
///
/// Four layers, cheapest first. Each one returns without touching the platform:
///
///  1. **Movement threshold.** The pin landed within [_minMoveMetres] of the
///     last point we resolved → reuse that address. Covers the settle-jitter
///     after a fling and the one-finger nudge, which are the same *place*.
///  2. **Grid cache.** Coordinates snapped to a ~11 m grid key, LRU. Covers
///     panning back over ground already seen — extremely common while someone
///     compares two possible corners.
///  3. **In-flight de-duplication.** Two idles landing on the same grid cell
///     while the first lookup is still out share one Future instead of racing.
///  4. The actual platform lookup.
///
/// **Cached addresses are re-stamped with the live coordinate.** The cache
/// holds address TEXT only; the returned [RidePlace] always carries the exact
/// point the caller asked about. Handing back the cached coordinate would mean
/// a 20 m nudge silently books the previous spot — the whole reason someone
/// opened a map picker instead of typing.
///
/// Process-wide and deliberately not tied to a controller: the pickup picker
/// and the drop picker resolve the same neighbourhood minutes apart in one
/// booking, and there is no reason for the second one to pay again.
class RideReverseGeocodeService {
  RideReverseGeocodeService._();

  static final RideReverseGeocodeService instance =
      RideReverseGeocodeService._();

  /// Decimal places the cache key is snapped to. 4 dp ≈ 11 m of latitude —
  /// finer than a building, coarser than the jitter a fling leaves behind.
  static const int _gridDecimals = 4;

  /// Below this, a new pin position is treated as the same place as the last
  /// one resolved. 25 m is about the width of a road junction: still the same
  /// address, and well inside what a customer means by "here".
  static const double _minMoveMetres = 25;

  /// LRU cap. Each entry is two short strings, so this is a few KB at most; the
  /// bound exists to stop a long session of panning growing without limit.
  static const int _maxEntries = 120;

  /// Snapped-key → resolved address text. A [LinkedHashMap] preserves insertion
  /// order, which is what makes the cheap LRU eviction below correct.
  final LinkedHashMap<String, _Address> _cache = LinkedHashMap<String, _Address>();

  /// Lookups currently out, keyed the same way, so concurrent idles on one cell
  /// share a single platform call.
  final Map<String, Future<_Address>> _inFlight = <String, Future<_Address>>{};

  /// The last point actually resolved, for the movement threshold.
  double? _lastLat;
  double? _lastLng;
  _Address? _lastAddress;

  /// Resolve [point] to a place, consulting all four layers.
  ///
  /// [fallbackTitle] names the point when the geocoder gives us nothing usable
  /// ('Selected pickup point' / 'Selected drop point') — it is the only thing
  /// that differs between the two pickers.
  Future<RidePlace> resolve(
    LatLng point, {
    required String fallbackTitle,
  }) async {
    final address = await _addressFor(point, fallbackTitle);
    // Always the LIVE coordinate, never the cached one — see the class doc.
    return RidePlace(
      title: address.title.isNotEmpty ? address.title : fallbackTitle,
      subtitle: address.subtitle,
      latitude: point.latitude,
      longitude: point.longitude,
    );
  }

  Future<_Address> _addressFor(LatLng point, String fallbackTitle) async {
    // ── 1. Movement threshold ────────────────────────────────────────────────
    final last = _lastAddress;
    if (last != null && _lastLat != null && _lastLng != null) {
      final metres = calculateDistanceKm(
            _lastLat!,
            _lastLng!,
            point.latitude,
            point.longitude,
          ) *
          1000;
      if (metres < _minMoveMetres) return last;
    }

    final key = _keyFor(point);

    // ── 2. Grid cache ────────────────────────────────────────────────────────
    final cached = _cache[key];
    if (cached != null) {
      // Touch: re-inserting moves it to the end, so eviction takes the genuinely
      // least-recently-used entry rather than the oldest-inserted one.
      _cache.remove(key);
      _cache[key] = cached;
      _remember(point, cached);
      return cached;
    }

    // ── 3. In-flight de-duplication ──────────────────────────────────────────
    final pending = _inFlight[key];
    if (pending != null) return pending;

    // ── 4. Platform lookup ───────────────────────────────────────────────────
    final future = _lookup(point, fallbackTitle);
    _inFlight[key] = future;
    try {
      final address = await future;
      _store(key, address);
      _remember(point, address);
      return address;
    } finally {
      _inFlight.remove(key);
    }
  }

  /// The one call that actually costs something.
  Future<_Address> _lookup(LatLng point, String fallbackTitle) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        // Nearest thing to a name, falling back down to the street.
        final title =
            _firstNonEmpty([p.name, p.street, p.subLocality]) ?? fallbackTitle;
        // Everything else, de-duped against the title so we don't render
        // "Jodhpur, Jodhpur, Rajasthan".
        final subtitle = <String?>[
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
        ]
            .whereType<String>()
            .where((s) => s.isNotEmpty && s != title)
            .toSet()
            .join(', ');

        return _Address(title, subtitle);
      }
    } catch (_) {
      // Geocoder unavailable, offline, or throttled — fall through.
    }

    // Never leave the card empty: coordinates are a poor address but they are
    // honest, and the caller's `hasCoordinates` check still lets the user
    // confirm the point.
    //
    // NOT cached: a throttled or offline lookup is a temporary failure, and
    // caching it would pin a lat/lng string onto that cell for the rest of the
    // session even after connectivity comes back.
    return _Address(
      fallbackTitle,
      '${point.latitude.toStringAsFixed(5)}, '
          '${point.longitude.toStringAsFixed(5)}',
      cacheable: false,
    );
  }

  void _store(String key, _Address address) {
    if (!address.cacheable) return;
    _cache[key] = address;
    while (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  void _remember(LatLng point, _Address address) {
    // A non-cacheable (failed) result must not arm the movement threshold —
    // otherwise one offline lookup makes every pin within 25 m report raw
    // coordinates instead of retrying.
    if (!address.cacheable) return;
    _lastLat = point.latitude;
    _lastLng = point.longitude;
    _lastAddress = address;
  }

  String _keyFor(LatLng point) =>
      '${point.latitude.toStringAsFixed(_gridDecimals)},'
      '${point.longitude.toStringAsFixed(_gridDecimals)}';

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Drops everything. Only for tests and a hard sign-out — the cache is
  /// address text keyed by coordinate, so there is nothing user-specific in it.
  void clear() {
    _cache.clear();
    _inFlight.clear();
    _lastLat = null;
    _lastLng = null;
    _lastAddress = null;
  }
}

/// Just the two text lines. Coordinates deliberately absent — see the class doc
/// on [RideReverseGeocodeService].
class _Address {
  const _Address(this.title, this.subtitle, {this.cacheable = true});

  final String title;
  final String subtitle;

  /// False for the coordinate fallback produced by a failed lookup, which must
  /// neither be stored nor allowed to satisfy the movement threshold.
  final bool cacheable;
}
