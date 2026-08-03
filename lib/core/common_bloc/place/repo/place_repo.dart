import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

/// A `place_id` resolved to something usable — the only part of a Place Details
/// response any screen in this app actually reads.
class ResolvedPlace {
  const ResolvedPlace({
    required this.lat,
    required this.lng,
    this.formattedAddress,
  });

  final double lat;
  final double lng;
  final String? formattedAddress;
}

class PlaceRepo{

  // ---------------------------------------------------------------- sessions

  /// Places **session token** for the search currently in progress.
  ///
  /// Google bills Places two ways. Without a token, every autocomplete keystroke
  /// bills as *Autocomplete – Per Request* AND the Place Details that follows
  /// bills separately at full price. With one token threaded through the whole
  /// typing session and its closing details call, the lot bills once as
  /// *Autocomplete – Per Session*. For a user typing a 10-character address that
  /// is several requests plus a details lookup, versus one session.
  ///
  /// **Why this lives in the repo and not in the screens.** The obvious
  /// implementation hands every search screen a token to hold, create on focus
  /// and pass to two different methods — six screens of fiddly state, each able
  /// to get it subtly wrong. But the flow is always the same shape:
  /// *n searches, then one resolve*. That is exactly a session, and both halves
  /// already funnel through this class, so it can own the lifecycle and no
  /// screen needs to know tokens exist.
  ///
  /// Lifecycle: created on the first [autoCompleteSearch] of a session, reused
  /// by every later search, sent on the closing [getCompletePlaceDetails], then
  /// discarded. Also rotated after [_kSessionMaxAge] so an abandoned search does
  /// not keep one token alive forever, which Google treats as abuse.
  ///
  /// **Known imprecision, and why it is safe.** Two screens searching at once
  /// would share a token, and resolving a *recent/favourite* place (rather than
  /// a freshly searched one) can close a session early. Both are rare, and the
  /// worst outcome is that Google bills those calls per-request — which is
  /// exactly what happened before this existed. It degrades to the old
  /// behaviour, never to something broken.
  static String? _sessionToken;
  static DateTime? _sessionStartedAt;

  /// How long one search session may stay open. Comfortably longer than anyone
  /// spends typing an address, short enough that an abandoned search starts
  /// fresh rather than reusing a stale token.
  static const Duration _kSessionMaxAge = Duration(minutes: 3);

  /// The token for the session in progress, starting one if needed.
  static String _currentSessionToken() {
    final started = _sessionStartedAt;
    final expired =
        started == null || DateTime.now().difference(started) > _kSessionMaxAge;
    if (_sessionToken == null || expired) {
      _sessionToken = const Uuid().v4();
      _sessionStartedAt = DateTime.now();
    }
    return _sessionToken!;
  }

  /// End the session — called once its Place Details has been requested, which
  /// is what closes a session as far as Google's billing is concerned.
  static void _endSession() {
    _sessionToken = null;
    _sessionStartedAt = null;
  }


  // "geocode" → Returns only addresses. Good for street addresses, not POIs or establishments.
  //
  // "address" → Similar to geocode.
  //
  // "establishment" → Returns businesses, shops, etc.
  //
  // "regions" → Cities, neighborhoods, political regions.
  //
  // "cities" → Only cities.


  ///Auto complete Search....
  ///
  /// Biased towards the user's current location when we have one. This costs
  /// NOTHING extra — `location`/`radius` are free parameters — and it is what
  /// lets the result lists drop their per-row "x km away" labels: the nearest
  /// matches simply come back first. Those labels used to be computed by firing
  /// a Place Details lookup for every prediction, which was the single most
  /// expensive pattern in the app (`docs/GOOGLE_MAPS_COST_GUIDE.md` §3.1).
  ///
  /// A bias, not a filter: `strictbounds` is deliberately NOT sent, so a user in
  /// Dehradun can still search an address in Delhi — those results just rank
  /// below the local ones.
  /// Autocomplete replies for this session, keyed by query + rough location.
  ///
  /// Typing "deh", backspacing and typing it again used to buy the same search
  /// twice. So did two screens searching the same thing. The location is part of
  /// the key because the request is location-biased — the same text genuinely
  /// returns different results in a different city — but only to ~1 km, so
  /// walking around does not invalidate it.
  static final Map<String, ResponseModel> _autocompleteCache = {};

  /// Bound on [_autocompleteCache]. Queries are short-lived by nature; this
  /// only exists so a very long session cannot grow it without limit.
  static const int _kMaxAutocompleteEntries = 100;

  Future<ResponseModel> autoCompleteSearch({
    required String query,

  }) async {
    final hasFix = LocationService.lat != 0.0 || LocationService.lng != 0.0;
    final cacheKey = '${query.trim().toLowerCase()}'
        '@${LocationService.lat.toStringAsFixed(2)},'
        '${LocationService.lng.toStringAsFixed(2)}';

    final cached = _autocompleteCache[cacheKey];
    if (cached != null) return cached;

    ResponseModel response = await ApiBaseHelper().getHTTP(
      googleAutocomplete,
      showProgress: false,
      params: {
        "input": query,
        "key": googleMapKey,
        "types": "geocode|establishment", // You can customize this
        "language": "en",
        "components": "country:in", // only India
        // Bills this and every other search in the session as ONE session
        // rather than one request each — see [_sessionToken].
        "sessiontoken": _currentSessionToken(),
        if (hasFix) ...{
          "location": "${LocationService.lat},${LocationService.lng}",
          // 30 km — wide enough to cover a whole city and its outskirts, tight
          // enough that local results actually win.
          "radius": "30000",
        },
      },
      onError: (error) {},
      onSuccess: (data) {},
    );

    // Only cache a real answer — caching a failure would make one dropped
    // connection look like "no results" for the rest of the session.
    if (response.statusCode == 200) {
      if (_autocompleteCache.length >= _kMaxAutocompleteEntries) {
        _autocompleteCache.remove(_autocompleteCache.keys.first);
      }
      _autocompleteCache[cacheKey] = response;
    }
    return response;
  }


  Future<ResponseModel> getCitiesByState(String state) async {
    return await ApiBaseHelper().getHTTP(
      googleAutocomplete,
      showProgress: false,
      params: {
        "input": "$state",
        "key": googleMapKey,
        "types": "(cities)",
        "components": "country:in",
        "language": "en",
      },
    );
  }

  /// Fields requested from Place Details.
  ///
  /// BILLING — do not widen this casually. Place Details is priced by the most
  /// expensive *class* of field in the request, and these four are all "Basic
  /// Data", the cheapest tier:
  ///
  ///   geometry, formatted_address, address_components, name
  ///
  /// Adding anything from Contact Data (`website`, `formatted_phone_number`) or
  /// Atmosphere (`rating`, `reviews`, `opening_hours`, `price_level`) re-prices
  /// EVERY call in the app, because all ~20 call sites share this one method.
  ///
  /// Sending no `fields` at all — which is what this did until the billing audit
  /// (see `docs/GOOGLE_MAPS_COST_GUIDE.md` §3.3) — makes Google return the full
  /// payload and bill at the top tier. That was the default, and it was silent.
  ///
  /// This list is everything [PlaceDetailsResponse] can actually parse, minus
  /// `website`, which the model has a slot for but no screen ever reads.
  static const String _detailsFields =
      'geometry,formatted_address,address_components,name';

  Future<ResponseModel> getCompletePlaceDetails({
    required String placeId,
  }) async {
    // The token must be the SAME one the autocomplete requests carried, or
    // Google bills both halves separately — worse than sending none at all.
    // Sent only when a session is actually open: resolving a saved place with
    // no preceding search legitimately has none.
    final token = _sessionToken;

    ResponseModel response = await ApiBaseHelper().getHTTP(
      googlePlaceId,
      showProgress: false,
      params: {
        'place_id': placeId,
        'key': googleMapKey,
        'fields': _detailsFields,
        if (token != null) 'sessiontoken': token,
      },
      onError: (error) {},
      onSuccess: (data) {},
    );

    // Session closes on the details request whether or not it succeeded — the
    // next search starts a new one.
    _endSession();
    return response;
  }

  Future<ResponseModel> getGeoCode({
    required Position position,
  }) async {
    ResponseModel response = await ApiBaseHelper().getHTTP(
      googleGeoCode,
      showProgress: false,
      params: {
        'latlng': '${position.latitude},${position.longitude}',
        'key': googleMapKey,
      },
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Resolved coordinates per `place_id`, for the life of the app session.
  ///
  /// Place geometry does not change, so the second lookup of the same place is
  /// free. Users search the same landmarks repeatedly (home, office, the station
  /// they always travel from), and every screen shares this map, so a place
  /// resolved while setting a pickup is already resolved when setting the drop.
  ///
  /// In-memory only, deliberately: Google's Maps Platform Terms restrict how
  /// long Places content may be persisted, and a process-lifetime map sidesteps
  /// that question entirely. A durable cache belongs on our backend — see
  /// `docs/GOOGLE_MAPS_COST_GUIDE.md` §3A.2.
  static final Map<String, ResolvedPlace> _resolvedPlaces = {};

  /// Turn a `place_id` into coordinates, hitting Place Details at most once per
  /// place per session. Returns null when the lookup fails or carries no
  /// geometry.
  ///
  /// Call this from the row's TAP handler — never in a loop over autocomplete
  /// predictions. Resolving every prediction to render the list was the single
  /// most expensive pattern in the app: it bought 5 Place Details per keystroke
  /// burst to answer a question the user asks about exactly one of them
  /// (`docs/GOOGLE_MAPS_COST_GUIDE.md` §3.1).
  Future<ResolvedPlace?> resolvePlace(String? placeId) async {
    final id = placeId ?? '';
    if (id.isEmpty) return null;

    final cached = _resolvedPlaces[id];
    if (cached != null) return cached;

    try {
      final response = await getCompletePlaceDetails(placeId: id);
      final data = response.response?.data;
      if (data is! Map) return null;
      final result =
          PlaceDetailsResponse.fromJson(Map<String, dynamic>.from(data)).result;
      final location = result?.geometry?.location;
      final lat = location?.lat;
      final lng = location?.lng;
      if (lat == null || lng == null) return null;

      final resolved = ResolvedPlace(
        lat: lat,
        lng: lng,
        formattedAddress: result?.formattedAddress,
      );
      _resolvedPlaces[id] = resolved;
      return resolved;
    } catch (_) {
      // Caller decides what a failed resolve means for its screen; nothing is
      // cached, so a retry can still succeed.
      return null;
    }
  }

  Future<ResponseModel> fetchLocationFromPinCodeRepo({
    required String pinCode,
  }) async {
    ResponseModel response = await ApiBaseHelper().getHTTP(
      pinCodeUrl(pinCode),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }





}
