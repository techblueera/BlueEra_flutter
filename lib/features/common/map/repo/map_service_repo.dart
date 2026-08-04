import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class MapServiceRepo extends BaseService{

  ///View Channel details...
  Future<ResponseModel> fetchAllHomeServices({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      servicesByLatLng,
      showProgress: true,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///View Channel details...
  Future<ResponseModel> fetchAllFoodServices({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      foodServicesByLatLng,
      showProgress: false,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  /// Publish the signed-in provider's current position while they are live.
  ///
  /// `POST map-service/api/provider/location` with a body of EXACTLY
  /// `{ "lat": …, "lng": … }`. The provider is resolved from the bearer token
  /// server-side — the call sites used to also send `userId`, which is at best
  /// ignored and at worst lets a client publish someone else's position.
  ///
  /// This feeds two things: the discovery/nearby index (whose `lastSeen` the
  /// map-service auto-closes after 5 minutes of silence) and the customer's
  /// live-tracking stream.
  Future<ResponseModel> publishProviderLocationRepo({
    required double lat,
    required double lng,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      mapServiceLocationProvider,
      showProgress: false,
      params: {ApiKeys.lat: lat, ApiKeys.lng: lng},
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  ///GET RENTAL SERVICE...
  Future<ResponseModel> bookingGetRentalServiceMapRepo({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      bookingGetRentalServiceMap,
      showProgress: true,
      params: queryParams,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}