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

  /// `POST /security-deposit/initiate` — creates a Razorpay order. Provide
  /// either [securityDepositPlanId] or both [tagId] + [accountType]; an optional
  /// [referralCode] applies the refer-&-earn discount. Returns
  /// `data` = { order_id, key_id, final_amount, security_deposit_id, ... }.
  /// A zero-deposit tag comes back with `order_id: null`, `status: "held"`.
  Future<ResponseModel> initiate({
    String? securityDepositPlanId,
    String? tagId,
    String? accountType,
    String? referralCode,
  }) {
    final body = <String, dynamic>{
      if (securityDepositPlanId != null && securityDepositPlanId.isNotEmpty)
        'securityDepositPlanId': securityDepositPlanId,
      if (tagId != null && tagId.isNotEmpty) 'tag_id': tagId,
      if (accountType != null && accountType.isNotEmpty)
        'account_type': accountType,
      if (referralCode != null && referralCode.isNotEmpty)
        'referralCode': referralCode,
    };
    return ApiBaseHelper().postHTTP(
      securityDepositInitiate,
      params: body,
      showProgress: false,
    );
  }

  /// `POST /security-deposit/verify-payment` — called after Razorpay checkout
  /// succeeds. Idempotently activates the deposit (`created → held`). The
  /// webhook is the source of truth and performs the same activation.
  Future<ResponseModel> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) {
    return ApiBaseHelper().postHTTP(
      securityDepositVerifyPayment,
      params: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
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

  /// `GET /security-deposit/videos` — explainer videos for the deposit screen.
  Future<ResponseModel> fetchVideos() {
    return ApiBaseHelper().getHTTP(securityDepositVideos, showProgress: false);
  }
}
