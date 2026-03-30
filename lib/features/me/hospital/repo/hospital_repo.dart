import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class HospitalRepo extends BaseService {

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
  ///PUT  COURSE....
  Future<ResponseModel> updateHospitalInfoRepo(
      {required Map<String, dynamic> reqBODY,}) async {
    final response = await ApiBaseHelper().putHTTP(
        "${hospitalUpdate}$hospitalIDGlobal",
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }
  /// LIST: Laboratory Profiles (paginated)
  Future<ResponseModel> listHospitalProfiles({
    required int page,
    required int limit,
    required String type,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      "hospital-service/hospitals?page=$page&limit=$limit&category=$type",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
