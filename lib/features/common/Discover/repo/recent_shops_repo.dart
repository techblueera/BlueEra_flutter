import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/Discover/model/recent_shops_models.dart';

/// Recent shops ("recently visited stores" / "order again") — the same
/// `/api/orders/recent-shops` endpoint on the grocery, product and food
/// services. See docs/backend/RECENT_SHOPS_FLUTTER_INTEGRATION.md.
class RecentShopsRepo extends BaseService {
  /// Fetch recent shops for a single [vertical]. The bearer token is injected
  /// by the Dio interceptor; no global progress dialog (the section shows its
  /// own inline loader).
  Future<ResponseModel> getRecentShops(
    GroceryVertical vertical, {
    int limit = 10,
  }) async {
    return await ApiBaseHelper().getHTTP(
      vertical.recentShopsPath,
      params: {'limit': limit},
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }
}
