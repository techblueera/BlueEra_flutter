import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// Repository for the Security Deposit ("contribution v2") flow.
/// See docs/backend/SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md.
class SecurityDepositRepo extends BaseService {
  /// `GET /security-deposit/plans` — both query params optional.
  Future<ResponseModel> fetchPlans({String? tagId, String? accountType}) {
    final query = <String, dynamic>{
      if (tagId != null && tagId.isNotEmpty) 'tag_id': tagId,
      if (accountType != null && accountType.isNotEmpty)
        'account_type': accountType,
    };
    return ApiBaseHelper().getHTTP(
      securityDepositPlans,
      showProgress: false,
      params: query.isEmpty ? null : query,
    );
  }

  /// `GET /security-deposit/plan/{tagId}` — single plan for a known tag.
  Future<ResponseModel> fetchPlanByTag(String tagId, {String? accountType}) {
    return ApiBaseHelper().getHTTP(
      '${securityDepositBase}plan/$tagId',
      showProgress: false,
      params: (accountType != null && accountType.isNotEmpty)
          ? {'account_type': accountType}
          : null,
    );
  }

  /// `POST /security-deposit/initiate` — provide either [securityDepositPlanId]
  /// or both [tagId] + [accountType]. Returns `data.security_deposit_id`.
  Future<ResponseModel> initiate({
    String? securityDepositPlanId,
    String? tagId,
    String? accountType,
  }) {
    final body = <String, dynamic>{
      if (securityDepositPlanId != null && securityDepositPlanId.isNotEmpty)
        'securityDepositPlanId': securityDepositPlanId,
      if (tagId != null && tagId.isNotEmpty) 'tag_id': tagId,
      if (accountType != null && accountType.isNotEmpty)
        'account_type': accountType,
    };
    return ApiBaseHelper().postHTTP(
      securityDepositInitiate,
      params: body,
      showProgress: false,
    );
  }

  /// `POST /security-deposit/confirm` — payment-success placeholder
  /// (`created → held`). Swapped for Razorpay verify/webhook later.
  Future<ResponseModel> confirm({required String depositId}) {
    return ApiBaseHelper().postHTTP(
      securityDepositConfirm,
      params: {'depositId': depositId},
      showProgress: false,
    );
  }

  /// `GET /security-deposit/current` — held deposit (404 = none).
  Future<ResponseModel> fetchCurrent() {
    return ApiBaseHelper().getHTTP(securityDepositCurrent, showProgress: false);
  }

  /// `GET /security-deposit/my-deposits` — optional [status] filter.
  Future<ResponseModel> fetchMyDeposits({String? status}) {
    return ApiBaseHelper().getHTTP(
      securityDepositMyDeposits,
      showProgress: false,
      params: (status != null && status.isNotEmpty) ? {'status': status} : null,
    );
  }

  /// `GET /security-deposit/{depositId}/details`.
  Future<ResponseModel> fetchDetails(String depositId) {
    return ApiBaseHelper().getHTTP(
      '$securityDepositBase$depositId/details',
      showProgress: false,
    );
  }

  /// `POST /security-deposit/refund/request`.
  Future<ResponseModel> requestRefund({required String depositId}) {
    return ApiBaseHelper().postHTTP(
      securityDepositRefundRequest,
      params: {'depositId': depositId},
      showProgress: false,
    );
  }

  /// `POST /security-deposit/cancel` — only a `created` (unpaid) deposit.
  Future<ResponseModel> cancel({required String depositId}) {
    return ApiBaseHelper().postHTTP(
      securityDepositCancel,
      params: {'depositId': depositId},
      showProgress: false,
    );
  }
}
