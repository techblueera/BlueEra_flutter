import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/map/lat_lng.dart';
import 'package:BlueEra/core/map/osm_geocoder.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

/// A `place_id` resolved to something usable — the only part of a place lookup
/// any screen in this app actually reads.
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

/// Address search, place resolution and reverse geocoding.
///
/// ## What changed, and what deliberately did not
///
/// This class used to front three Google products — Places Autocomplete, Place
/// Details and Geocoding — and most of its bulk was machinery for *not spending
/// money on them*: session tokens to collapse a typing session into one billed
/// unit, a field mask to avoid being priced at the top tier, and a warning
/// against ever resolving a prediction inside a loop.
///
/// It now runs on OSM services (see [OsmGeocoder]), and that machinery is gone
/// because the problems it solved are gone with it:
///
///  * **Session tokens** existed purely as a billing construct. Nothing outside
///    Google's pricing model has an opinion about them.
///  * **The `fields` mask** existed because Place Details was priced by the most
///    expensive class of field requested. There are no field tiers now.
///  * **Place Details itself** is no longer a network call at all. Photon
///    returns coordinates inline with every suggestion, so a tapped row is
///    resolved by parsing its id — see [OsmPlace.placeIdFor]. The single most
///    expensive pattern in the old app (five Place Details lookups per keystroke
///    burst, to render distance labels for rows the user would not tap) is now
///    *free*, not merely discouraged.
///
/// **The method signatures and response shapes are unchanged.** Every caller
/// still receives a [ResponseModel] whose body carries `predictions` /
/// `results` / `result` in Google's layout, because ~20 screens and three
/// response models parse exactly that. Swapping the provider was not a reason to
/// also rewrite them.
///
/// The autocomplete cache stays, for a different reason than it was built: it no
/// longer saves money, but it does keep the app inside the geocoder's rate limit
/// — which, on the public servers, is stricter than anything Google enforced.
/// See [OsmConfig].
class PlaceRepo {
  // ------------------------------------------------------------------- cache

  /// Autocomplete replies for this session, keyed by query + rough location.
  ///
  /// Typing "deh", backspacing and typing it again would otherwise repeat the
  /// same search. So would two screens searching the same thing. The location is
  /// part of the key because the request is location-biased — the same text
  /// genuinely returns different results in a different city — but only to
  /// ~1 km, so walking around does not invalidate it.
  static final Map<String, ResponseModel> _autocompleteCache = {};

  /// Bound on [_autocompleteCache]. Queries are short-lived by nature; this only
  /// exists so a very long session cannot grow it without limit.
  static const int _kMaxAutocompleteEntries = 100;

  /// Descriptions of places seen during this session, keyed by `place_id`.
  ///
  /// [resolvePlace] gets coordinates from the id itself, but callers also want a
  /// human-readable address, and re-deriving that would mean a reverse-geocode
  /// round trip for a string we already had in hand when we drew the row. So the
  /// row's own text is kept here as it goes past.
  static final Map<String, String> _descriptionsByPlaceId = {};

  /// Wraps a plain map in the [ResponseModel] shape callers expect. The Dio
  /// [Response] is synthesised rather than real — nothing downstream reads
  /// anything but `statusCode` and `data`.
  static ResponseModel _ok(Map<String, dynamic> body) => ResponseModel(
        statusCode: 200,
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: body,
        ),
      );

  static ResponseModel _empty({String status = 'ZERO_RESULTS'}) =>
      _ok({'status': status, 'predictions': const [], 'results': const []});

  // ---------------------------------------------------------------- searching

  /// Type-ahead address search.
  ///
  /// Biased towards the user's current location when we have one — a bias, not a
  /// filter, so a user in Dehradun can still search an address in Delhi; those
  /// results just rank below the local ones.
  ///
  /// Body shape is Google's: `{"predictions": [{"description", "place_id"}]}`.
  /// Predictions additionally carry `lat`/`lng`, which Google's never did — a
  /// caller that wants coordinates for a row no longer has to ask for them.
  Future<ResponseModel> autoCompleteSearch({
    required String query,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return _empty();

    final cacheKey = '${trimmed.toLowerCase()}'
        '@${LocationService.lat.toStringAsFixed(2)},'
        '${LocationService.lng.toStringAsFixed(2)}';

    final cached = _autocompleteCache[cacheKey];
    if (cached != null) return cached;

    final places = await OsmGeocoder.autocomplete(
      query: trimmed,
      near: LatLng(LocationService.lat, LocationService.lng),
    );

    // A failed lookup and a genuinely empty one are indistinguishable here by
    // design — both mean "nothing to show" to a search field. But only a real
    // answer is cached: caching a dropped connection would make it look like
    // "no results" for the rest of the session.
    if (places.isEmpty) return _empty();

    for (final place in places) {
      _descriptionsByPlaceId[place.placeId] = place.description;
    }

    final response = _ok({
      'status': 'OK',
      'predictions': places.map((p) => p.toPredictionJson()).toList(),
    });

    if (_autocompleteCache.length >= _kMaxAutocompleteEntries) {
      _autocompleteCache.remove(_autocompleteCache.keys.first);
    }
    _autocompleteCache[cacheKey] = response;
    return response;
  }

  /// Cities within an Indian state.
  ///
  /// Still a network call for what is a **static dataset** — the cities of
  /// Uttarakhand do not change between releases. Bundling this as a JSON asset
  /// remains the right answer (`docs/GOOGLE_MAPS_COST_GUIDE.md` §3A.4); it is
  /// now a latency and rate-limit argument rather than a billing one.
  Future<ResponseModel> getCitiesByState(String state) async {
    final places = await OsmGeocoder.searchCities(state: state);
    if (places.isEmpty) return _empty();

    for (final place in places) {
      _descriptionsByPlaceId[place.placeId] = place.description;
    }

    return _ok({
      'status': 'OK',
      'predictions': places.map((p) => p.toPredictionJson()).toList(),
    });
  }

  // --------------------------------------------------------------- resolving

  /// Full details for a `place_id`, in Google's Place Details shape.
  ///
  /// Reverse-geocodes the coordinates carried in the id to recover structured
  /// `address_components`, which is the one thing the id alone cannot supply.
  /// If you only need coordinates — which is what almost every caller actually
  /// wants — use [resolvePlace] instead and skip the network entirely.
  Future<ResponseModel> getCompletePlaceDetails({
    required String placeId,
  }) async {
    final location = OsmPlace.locationFromPlaceId(placeId);
    if (location == null) return _empty(status: 'INVALID_REQUEST');

    final address = await OsmGeocoder.reverse(location);
    if (address != null) return _ok(address.toGooglePlaceDetailsJson());

    // Reverse failed, but the id still holds real coordinates and we may have
    // the row's own text. Returning that beats returning nothing: every caller
    // reads geometry, and only some read the components.
    return _ok({
      'status': 'OK',
      'result': {
        'formatted_address': _descriptionsByPlaceId[placeId] ?? '',
        'address_components': const [],
        'geometry': {
          'location': {'lat': location.latitude, 'lng': location.longitude},
        },
        'place_id': placeId,
      },
    });
  }

  /// Turn a `place_id` into coordinates.
  ///
  /// **This no longer performs any network call.** The coordinates are encoded
  /// in the id when the suggestion is created, so this is string parsing. The
  /// old prohibition on calling it in a loop over predictions no longer applies
  /// — though rendering a distance for every row is still usually the wrong UI,
  /// it is no longer expensive.
  ///
  /// Returns null when the id is not one of ours — most likely a Google
  /// `place_id` persisted by an older app version, which cannot be resolved and
  /// should be re-searched.
  Future<ResolvedPlace?> resolvePlace(String? placeId) async {
    final id = placeId ?? '';
    if (id.isEmpty) return null;

    final location = OsmPlace.locationFromPlaceId(id);
    if (location == null) return null;

    return ResolvedPlace(
      lat: location.latitude,
      lng: location.longitude,
      formattedAddress: _descriptionsByPlaceId[id],
    );
  }

  /// Coordinates to an address, in Google's Geocoding shape.
  ///
  /// `LocationController.getAddressDetails` is the one caller, and it picks
  /// components out by Google's `types` strings. [OsmAddress.toGoogleGeocodeJson]
  /// emits those, so neither it nor `GeocodingResponse` changes.
  ///
  /// Prefer `placemarkFromCoordinates` (the `geocoding` package) where you can —
  /// it uses the on-device geocoder, works offline, and does not consume the
  /// shared Nominatim rate limit.
  Future<ResponseModel> getGeoCode({
    required Position position,
  }) async {
    final address = await OsmGeocoder.reverse(
      LatLng(position.latitude, position.longitude),
    );
    if (address == null) return _empty();
    return _ok(address.toGoogleGeocodeJson());
  }

  /// Indian postal-code lookup. Unchanged — `api.postalpincode.in` was never a
  /// Google service, and it is authoritative for this in a way a general
  /// geocoder is not.
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

  /// Drop everything remembered. For logout / account switch.
  static void clear() {
    _autocompleteCache.clear();
    _descriptionsByPlaceId.clear();
  }
}
