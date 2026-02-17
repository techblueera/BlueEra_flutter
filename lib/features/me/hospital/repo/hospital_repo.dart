import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class HospitalRepo extends BaseService {
  ///GET AI LAB SERVICE DETAILS...
  Future<ResponseModel> aiHospitalFetchDetailsRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP(createAISearch,
        params: reqBody, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> createHospitalRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP(aiCreateHospital,
        params: reqBody, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> getHospitalFullDetailsRepo(
   ) async {
    final response = await ApiBaseHelper().getHTTP(userSelfHospital,
    onError: (error) {}, onSuccess: (data) {});
    return response;
  }
}
