import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart' as geo;

/// Re-exported so a call site only has to swap its `package:geocoding` import
/// for this one — `Placemark`, `Location` and friends keep resolving.
export 'package:geocoding/geocoding.dart';

/// Exported too so callers can name a locale for [setGeocodingLocale] without
/// reaching for a Flutter import of their own.
export 'dart:ui' show Locale;

/// geocoding 5.0 moved every top-level function onto a `Geocoding` instance
/// and turned the process-wide locale into a per-call argument. This keeps the
/// old free-function shape (used from ~11 call sites) on top of one shared
/// instance, so the migration didn't have to touch the callers' logic.
///
/// The locale is passed on EVERY call rather than to the constructor on
/// purpose: geocoding 5.0.0's `Geocoding({Locale? locale})` forwards to a
/// private constructor without passing the locale through, so a
/// constructor-supplied locale is silently dropped. Per-call is the only shape
/// that actually reaches the platform.
Locale? _locale;
geo.Geocoding? _instance;

geo.Geocoding get _geocoding => _instance ??= geo.Geocoding();

/// Sets the locale every later lookup uses, replacing 4.x's
/// `setLocaleIdentifier`. Call once; results stay in this language regardless
/// of the device locale.
void setGeocodingLocale(Locale locale) => _locale = locale;

Future<List<geo.Placemark>> placemarkFromCoordinates(
  double latitude,
  double longitude, {
  Locale? locale,
}) =>
    _geocoding.placemarkFromCoordinates(
      latitude,
      longitude,
      locale: locale ?? _locale,
    );

Future<List<geo.Placemark>> placemarkFromAddress(
  String address, {
  Locale? locale,
}) =>
    _geocoding.placemarkFromAddress(address, locale: locale ?? _locale);

Future<List<geo.Location>> locationFromAddress(
  String address, {
  Locale? locale,
}) =>
    _geocoding.locationFromAddress(address, locale: locale ?? _locale);
