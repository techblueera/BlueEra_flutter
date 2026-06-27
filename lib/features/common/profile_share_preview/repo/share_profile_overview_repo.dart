import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class ShareProfileOverviewRepo extends BaseService {
  /// GET the public share-card overview for [userId]. Used by the deep-link
  /// landing screen (`/app/profile/{id}` and `/app/business/{id}`).
  Future<ResponseModel> getShareProfileOverview(String userId) async {
    return ApiBaseHelper().getHTTP(
      shareProfileOverview(userId),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }
}
