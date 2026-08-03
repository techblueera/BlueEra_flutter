import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:geolocator/geolocator.dart';

class PlaceRepo{

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
  Future<ResponseModel> autoCompleteSearch({
    required String query,

  }) async {
    ResponseModel response = await ApiBaseHelper().getHTTP(
      googleAutocomplete,
      showProgress: false,
      params: {
        "input": query,
        "key": googleMapKey,
        "types": "geocode|establishment", // You can customize this
        "language": "en",
        "components": "country:in" // only India
      },
      onError: (error) {},
      onSuccess: (data) {},
    );
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

  Future<ResponseModel> getCompletePlaceDetails({
    required String placeId,
  }) async {
    ResponseModel response = await ApiBaseHelper().getHTTP(
      googlePlaceId,
      showProgress: false,
      params: {
        'place_id': placeId,
        'key': googleMapKey,
      },
      onError: (error) {},
      onSuccess: (data) {},
    );
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

  /// Forward geocode — free-text address → lat/lng.
  ///
  /// The counterpart to [getGeoCode] (which goes the other way). Used when a
  /// user types an address by hand instead of picking a Places suggestion,
  /// so the record still carries coordinates.
  Future<ResponseModel> getGeoCodeFromAddress({
    required String address,
  }) async {
    ResponseModel response = await ApiBaseHelper().getHTTP(
      googleGeoCode,
      showProgress: false,
      params: {
        'address': address,
        'key': googleMapKey,
        'components': 'country:IN',
        'language': 'en',
      },
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
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
