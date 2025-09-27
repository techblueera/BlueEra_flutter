
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:dio/dio.dart' as dio;

class FoodAiRepo extends BaseService
{
  Future<ResponseModel> aiFoodGenerateRepo({Map<String, dynamic>? queryParam}) async {

    final response = await ApiBaseHelper().postHTTP(
      aiFoodGenerateContent,
      params:queryParam,
      isMultipart: true,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}