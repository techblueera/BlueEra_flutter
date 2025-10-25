import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';

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
  Future<ResponseModel> getServiceRepo({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      businessServices,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///DELETE SERVICES....
  Future<ResponseModel> deleteServiceRepo({required String serviceId}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      businessServicesById(serviceId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
