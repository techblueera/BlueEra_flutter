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
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///Add Service...
  Future<ResponseModel> addService({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      createService,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET SERVICES....
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

  ///Get Single Service...
  Future<ResponseModel> fetchSingleServiceDataApi({required String serviceId}) async {
    final response = await ApiBaseHelper().getHTTP(
      businessServicesById(serviceId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}
