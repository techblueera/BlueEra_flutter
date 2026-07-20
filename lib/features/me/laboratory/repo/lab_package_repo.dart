import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// Wraps `/packages` — see lib/docs/LABORATORY_INTEGRATION.md §1.
class LabPackageRepo extends BaseService {
  /// POST /packages — create a package. Server derives userId/laboratoryId
  /// from the token; body carries name/description/imageUrl/tests[]/
  /// packageMrp/customerPrice/gender.
  Future<ResponseModel> createPackage(Map<String, dynamic> data) async {
    return await ApiBaseHelper().postHTTP(labPackages, params: data);
  }

  /// GET /packages/laboratory/:labId — public list; `tests` is NOT
  /// populated (raw ids only).
  Future<ResponseModel> getPackagesByLab(String labId) async {
    return await ApiBaseHelper().getHTTP('$labPackagesByLab/$labId');
  }

  /// GET /packages/me — owner's own packages, token-scoped, with `tests`
  /// **populated**. This is the correct list per
  /// FLUTTER_CATALOGUE_INTEGRATION.md PART 6/7 — do NOT use `GET /packages`
  /// (unscoped, returns every lab's packages) or `GET /packages/laboratory/:id`
  /// (public view of some other lab; unpopulated tests).
  Future<ResponseModel> getMyPackages() async {
    return await ApiBaseHelper().getHTTP(labPackagesMe);
  }

  /// GET /packages/:id — populated tests.
  Future<ResponseModel> getPackageById(String id) async {
    return await ApiBaseHelper().getHTTP('$labPackages/$id');
  }

  /// PUT /packages/:id — accepts any subset of create fields; sending the
  /// full `tests` array replaces membership.
  Future<ResponseModel> updatePackage(
      String id, Map<String, dynamic> data) async {
    return await ApiBaseHelper().putHTTP('$labPackages/$id', params: data);
  }

  /// DELETE /packages/:id — ownership-scoped; 404 = not owned by token.
  Future<ResponseModel> deletePackage(String id) async {
    return await ApiBaseHelper().deleteHTTP('$labPackages/$id');
  }
}
