/// Safe indexed access to the `coordinates` lists the APIs return.
///
/// `coordinates.coordAt(0)` reads as null-safe and is not: `?[]` guards the list
/// being null but still evaluates the index, so a location saved without
/// coordinates — which serialises as `coordinates: []` far more often than as
/// `null` — gives
///   RangeError (length): Invalid value: Valid value range is empty: 0
/// Most of these accesses sit in `build` methods, where that takes the frame
/// rather than one call.
///
/// Deliberately INDEXED rather than named `latitude` / `longitude`: this app's
/// endpoints do not agree on the order. Most read `[0]` as longitude (GeoJSON),
/// while the social profile, school overview and event screens read `[0]` as
/// latitude — and [FinanceLocation.fromBusinessLocation] documents emitting
/// `[lat, lon]` on purpose to match its screen. Naming the halves here would
/// force one convention onto call sites that disagree, which would put pins in
/// the wrong hemisphere. Whether those readings are each correct is a separate
/// question from whether they crash.
library;

extension SafeCoordinateList on List<dynamic>? {
  /// Element [index] as a double, or null when the list is null, too short, or
  /// holds something unparseable there.
  ///
  /// Coordinates arrive as `num` from JSON, and occasionally as strings, which
  /// is why the call sites are littered with `.toDouble()` and
  /// `double.parse(...toString())`. Both are handled here.
  double? coordAt(int index) {
    final list = this;
    if (list == null || index < 0 || index >= list.length) return null;

    final value = list[index];
    if (value is num) return value.toDouble();
    if (value == null) return null;
    return double.tryParse(value.toString());
  }
}
