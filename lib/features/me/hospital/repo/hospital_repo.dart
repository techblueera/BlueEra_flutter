import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class HospitalRepo extends BaseService {
  /// `showProgress: false` — a side effect of account creation, run while the
  /// Submit button already shows its own spinner. See the note on
  /// `OtherRepo.createOtherBusinessProfileRepo`.
  Future<ResponseModel> createHospitalRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP(aiCreateHospital,
        params: reqBody,
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  /// `showProgress: false` — the Hospital "Me" screen's own load: it runs from
  /// `HospitalHomeScreenV2.initState` and from its pull-to-refresh, both of
  /// which already show progress. A blocking dialog there greys out the screen
  /// the merchant just opened.
  Future<ResponseModel> getHospitalFullDetailsRepo() async {
    final response = await ApiBaseHelper().getHTTP(userSelfHospital,
        showProgress: false, onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  ///PUT  COURSE....
  Future<ResponseModel> updateHospitalInfoRepo({
    required Map<String, dynamic> reqBODY,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
        "${hospitalUpdate}$hospitalIDGlobal",
        params: reqBODY,
        onError: (error) {},
        onSuccess: (data) {});
    return response;
  }

  /// LIST: Laboratory Profiles (paginated)
  Future<ResponseModel> listHospitalProfiles({
    required int page,
    required int limit,
    required String type,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      "hospital-service/hospitals?page=$page&limit=$limit&category=$type",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// LIST: Hospitals via the shared business-filter endpoint —
  /// `GET user-service/business/filter?category=...&page=...&limit=...`
  ///
  /// Used by the hospital listing pipeline (`HospitalServiceAiController._fetch`)
  /// in place of `listHospitalProfiles`. Mirrors the same call shape as
  /// `MedicalRepo.fetchFilteredBusinessRepo` and `DiscoverRepo.fetchBusinessFilterRepo`.
  Future<ResponseModel> fetchHospitalsBusinessFilterRepo({
    required String category,
    required int page,
    required int limit,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      'user-service/business/filter',
      showProgress: false,
      params: {
        'category': category,
        'page': page,
        'limit': limit,
      },
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
