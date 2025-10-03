import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class ServiceAiRepo extends BaseService {
  Future<ResponseModel> aiServiceGenerateRepo(
      {Map<String, dynamic>? queryParam}) async {
    final response = await ApiBaseHelper().postHTTP(
      aiServiceGenerateContent,
      params: queryParam,
      isMultipart: true,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///ADD SERVICES....
  Future<ResponseModel> getServiceRepo(
     ) async {
    final response = await ApiBaseHelper().getHTTP(
      "${businessServices}?all=true&type=service",
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
