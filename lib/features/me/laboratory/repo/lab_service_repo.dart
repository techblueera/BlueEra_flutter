import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class LabServiceRepo extends BaseService {
  ///GET AI LAB SERVICE DETAILS...
  Future<ResponseModel> aiLabFetchDetailsRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP(aiLabsService,
        params: reqBody, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
}
