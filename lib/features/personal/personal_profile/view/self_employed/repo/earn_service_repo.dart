import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/services/location/location_service.dart';

class EarnServiceRepo extends BaseService {

  /// Earn Services
  Future<ResponseModel> addServiceRepo({required Map<String, dynamic> params}) async {
    // Stamp the provider's current location on every create so the service is
    // discoverable by nearby search. Every caller funnels through here, so this
    // is the single place it needs to happen. `location` is GeoJSON — its
    // coordinates are ordered [long, lat]; the flat `lat`/`long` fields are kept
    // alongside it because the backend reads both.
    final double lat = LocationService.lat;
    final double long = LocationService.lng;
    params[ApiKeys.lat] = lat;
    params[ApiKeys.long] = long;
    params[ApiKeys.location] = {
      ApiKeys.type: 'Point',
      ApiKeys.coordinates: [long, lat],
    };

    final response = await ApiBaseHelper().postHTTP(
      earnServices,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Get Earn Services
  Future<ResponseModel> getEarnServiceRepo({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      earnServices,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///DELETE Earn SERVICE....
  Future<ResponseModel> deleteServiceRepo({required String serviceId}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      earnServicesById(serviceId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Fetch Earn SERVICE Data....
  Future<ResponseModel> fetchProfessionDataRepo(Map<String, dynamic> parms) async {
    final response = await ApiBaseHelper().getHTTP(
      earnServices,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Upload Profession Photo...
  Future<ResponseModel> uploadProfessionImage(
      {required String serviceId, required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
        params: params,
        earnServicesImages(serviceId),
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///Delete Profession Photos...
  Future<ResponseModel> deleteProfessionImage(
      {required String serviceId, required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().deleteHTTP(
        params: params,
        showProgress: false,
        earnServicesImages(serviceId),
        onError: (error) {},
        onSuccess: (data) {});

    return response;
  }

  ///Fetch Predefined services Data...
  Future<ResponseModel> predefinedServiceCategoryRepo(
      {required String professionCategory, required Map<String, String> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
        predefinedServiceCategory(professionCategory),
        params: queryParams,
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {});

    return response;
  }

  /// Self Profession Desc Via AI
  Future<ResponseModel> aiGenerateDescriptionRepo(
      {required Map<String, dynamic> bodyParam}) async {
    final response = await ApiBaseHelper().postHTTP(
      "$aiGenerateSelfProfession",
      params: bodyParam,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Earn Services
  Future<ResponseModel> updateServiceRepo({required String serviceId, required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().putHTTP(
      earnServicesById(serviceId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Skilled-worker statistics dashboard (Statics tab on the self-employed
  /// home). [period] is `today` | `week` | `month`. The worker is resolved
  /// from the JWT server-side — deliberately no userId param, so one worker
  /// can't read another's earnings by editing a URL.
  Future<ResponseModel> getSelfWorkStatisticsRepo({
    required String period,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      selfWorkStatistics,
      params: {'period': period},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}