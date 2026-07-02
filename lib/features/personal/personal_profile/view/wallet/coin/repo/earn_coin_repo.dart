import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// Earn-Coin API layer. Endpoint constants come from [EarnServiceApi] via
/// [BaseService]. Contract: docs/backend/FLUTTER-MASTER-GUIDE.md.
class EarnCoinRepo extends BaseService {
  Future<ResponseModel> getBalance() => ApiBaseHelper().getHTTP(
        earnBalance,
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );

  Future<ResponseModel> getDashboard() => ApiBaseHelper().getHTTP(
        earnDashboard,
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );

  Future<ResponseModel> getTasks() => ApiBaseHelper().getHTTP(
        earnTasks,
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );

  /// Cursor-based paging: pass [cursor] from the previous page's `nextCursor`.
  Future<ResponseModel> getHistory({String? cursor, int limit = 20}) =>
      ApiBaseHelper().getHTTP(
        earnHistory,
        params: {
          'limit': limit,
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        },
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );

  Future<ResponseModel> getLeaderboard({int limit = 50}) =>
      ApiBaseHelper().getHTTP(
        earnLeaderboard,
        params: {'limit': limit},
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );

  Future<ResponseModel> getStreak() => ApiBaseHelper().getHTTP(
        earnStreak,
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );

  /// Redeem coins → ₹ (credited to the money wallet). `coins` must be ≥ 5000
  /// and a multiple of 100. [requestId] is an optional idempotency key.
  Future<ResponseModel> redeem({required int coins, String? requestId}) =>
      ApiBaseHelper().postHTTP(
        earnRedeem,
        params: {
          'coins': coins,
          if (requestId != null) 'request_id': requestId,
        },
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );
}
