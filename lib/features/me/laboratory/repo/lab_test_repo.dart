import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class LabTestRepo extends BaseService {

  Future<ResponseModel> getTestCategories() async {
    return await ApiBaseHelper().getHTTP(testCategories);
  }

  Future<ResponseModel> getTestParameters() async {
    return await ApiBaseHelper().getHTTP(testParameters);
  }

  Future<ResponseModel> getPathologyTests(String collection) async {
    return await ApiBaseHelper().getHTTP("$testPathology?collection=$collection");
  }

  Future<ResponseModel> createPathologyTest(Map<String, dynamic> data) async {
    return await ApiBaseHelper().postHTTP(testPathology, params: data);
  }

  Future<ResponseModel> updatePathologyTest(String id, Map<String, dynamic> data) async {
    return await ApiBaseHelper().putHTTP("$testPathology/$id", params: data);
  }

  Future<ResponseModel> deletePathologyTest(String id) async {
    return await ApiBaseHelper().deleteHTTP("$testPathology/$id");
  }
}
