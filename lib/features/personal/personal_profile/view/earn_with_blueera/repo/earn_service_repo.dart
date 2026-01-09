import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class EarnServiceRepo extends BaseService {

  /// Earn Services
  Future<ResponseModel> addServiceRepo({required Map<String, dynamic> params}) async {
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

  /// CHECK ANY EARN SERVICE CREATED OR NOT
  Future<ResponseModel> getEarnServiceExistsStatusRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      "${checkAnyEarnServiceCreated}",
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
  Future<ResponseModel> uploadProfessionImages(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        isMultipart: true,
        params: params,
        businessLivePhotos,
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  ///Delete Profession Photos...
  Future<ResponseModel> deleteProfessionImage(
      Map<String, dynamic> params) async {
    final response = await ApiBaseHelper().deleteHTTP(
        params: params,
        removeBusinessLivePhotos,
        onError: (error) {},
        onSuccess: (data) {});

    return response;
  }


}