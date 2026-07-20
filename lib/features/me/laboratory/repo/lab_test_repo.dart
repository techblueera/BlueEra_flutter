import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class LabTestRepo extends BaseService {

  // Lab-scoped listing — mandatory for the create form. The unscoped
  // `GET /test-categories` returns every lab's categories (~257 docs with
  // ~8 rows named "Hematology"), so matching by name picks another lab's
  // id, and the backend rejects the create with
  // "testCategory does not belong to your laboratory". See guide §4.
  Future<ResponseModel> getTestCategoriesByLab(String labId) async {
    return await ApiBaseHelper().getHTTP("$testCategories/laboratory/$labId");
  }

  // Lab-scoped parameters — same reason as `getTestCategoriesByLab` above.
  Future<ResponseModel> getTestParametersByLab(String labId) async {
    return await ApiBaseHelper().getHTTP("$testParameters/laboratory/$labId");
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

  Future<ResponseModel> getPathologyTestsByLab(String labId, String collection) async {
    return await ApiBaseHelper().getHTTP("$testPathology/laboratory/$labId?collection=$collection");
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
  Future<ResponseModel> selectCatalogTests(List<String> catalogTestIds, {Map<String, dynamic>? overrides}) async {
    return await ApiBaseHelper()
        .postHTTP(testCatalogSelect, params: {
          "catalogTestIds": catalogTestIds,
          if (overrides != null) ...overrides,
        });
  }
}
