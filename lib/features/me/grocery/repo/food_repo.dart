import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class FoodRepo extends BaseService {
  ///GET SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> getFoodAiGenerateRepo({required Map<String,dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP("${foodAiGenerate}",
        params: reqBody,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
}
