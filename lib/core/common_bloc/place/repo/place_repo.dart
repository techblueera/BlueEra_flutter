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
