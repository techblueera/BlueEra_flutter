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
    return await ApiBaseHelper().getHTTP("$testPathology?groupCategory=$collection");
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

  // Catalog: GET predefined tests
  Future<ResponseModel> getTestCatalog({
    required String groupCategory,
    int page = 1,
    int limit = 20,
  }) async {
    final encoded = Uri.encodeComponent(groupCategory);
    return await ApiBaseHelper()
        .getHTTP("$testCatalog?groupCategory=$encoded&page=$page&limit=$limit");
  }

  // Catalog: POST select tests by catalog IDs
  Future<ResponseModel> selectCatalogTests(List<String> catalogTestIds) async {
    return await ApiBaseHelper()
        .postHTTP(testCatalogSelect, params: {"catalogTestIds": catalogTestIds});
  }
}
