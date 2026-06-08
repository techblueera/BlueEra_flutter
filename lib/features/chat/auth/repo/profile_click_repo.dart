import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class ProfileClickRepo extends BaseService {
  /// Records a profile visit against a business/individual profile.
  ///
  /// Fire-and-forget like [ChatClickRepo.recordChatClick] — callers should
  /// not await nor surface errors. No request body is sent; the server records
  /// the visit from the path id + auth context. `showProgress: false` keeps the
  /// global loader hidden.
  Future<ResponseModel> recordProfileVisit({required String userId}) async {
    final response = await ApiBaseHelper().postHTTP(
      profileVisitRecord(userId),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
    return response;
  }

  /// Get profile-visit analytics (summary of total / unique visits).
  Future<ResponseModel> fetchProfileVisitStatsRepo({
    required String userId,
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      profileVisitStats(userId),
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
