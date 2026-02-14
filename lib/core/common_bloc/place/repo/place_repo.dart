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


}
