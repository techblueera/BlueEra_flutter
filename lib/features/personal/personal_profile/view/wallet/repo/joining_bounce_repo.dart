import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// API layer for the Joining Bounce (joining bonus) flow.
/// See `docs/backend/JOINING_BOUNCE_FLUTTER_GUIDE.md`.
class JoiningBounceRepo extends BaseService {
  /// `GET /joining-bounce/my-bounces?status=` — the user's bounce records.
  /// [status] is optional (in_progress | eligible | credited | cancelled | expired).
  Future<ResponseModel> getMyBounces({String? status}) async {
    final response = await ApiBaseHelper().getHTTP(
      joiningBounceMyBounces,
      showProgress: false,
      params: status != null ? {'status': status} : null,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// `GET /joining-bounce/current` — the active in_progress/eligible record.
  Future<ResponseModel> getCurrent() async {
    final response = await ApiBaseHelper().getHTTP(
      joiningBounceCurrent,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// `GET /joining-bounce/plans?account_type=` — catalog of plans.
  Future<ResponseModel> getPlans({String? accountType, String? tagId}) async {
    final response = await ApiBaseHelper().getHTTP(
      joiningBouncePlans,
      showProgress: false,
      params: {
        if (accountType != null) 'account_type': accountType,
        if (tagId != null) 'tag_id': tagId,
      },
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// `POST /joining-bounce/enroll` — enroll into a plan (idempotent per tag).
  Future<ResponseModel> enroll({
    required String tagId,
    required String accountType,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      joiningBounceEnroll,
      params: {'tag_id': tagId, 'account_type': accountType},
      isMultipart: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// `POST /joining-bounce/claim` — credit an eligible bonus into the wallet.
  /// [joiningBounceId] is optional; the backend resolves the eligible record.
  Future<ResponseModel> claim({String? joiningBounceId}) async {
    final response = await ApiBaseHelper().postHTTP(
      joiningBounceClaim,
      params: {
        if (joiningBounceId != null) 'joiningBounceId': joiningBounceId,
      },
      isMultipart: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// `POST /joining-bounce/cancel` — cancel an in_progress/eligible record.
  Future<ResponseModel> cancel({required String joiningBounceId}) async {
    final response = await ApiBaseHelper().postHTTP(
      joiningBounceCancel,
      params: {'joiningBounceId': joiningBounceId},
      isMultipart: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
