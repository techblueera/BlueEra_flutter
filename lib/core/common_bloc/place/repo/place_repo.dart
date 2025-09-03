import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/environment_config.dart';

class PlaceRepo{

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
        "types": "geocode", // You can customize this
        "language": "en"
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


}
