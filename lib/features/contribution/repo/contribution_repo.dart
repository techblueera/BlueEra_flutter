import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class ContributionRepo extends BaseService {
  /// `GET /recharge/plans?entity_type=...`
  Future<ResponseModel> fetchPlans({String? entityType}) {
    return ApiBaseHelper().getHTTP(
      rechargePlans,
      showProgress: false,
      params: entityType != null && entityType.isNotEmpty
          ? {'entity_type': entityType}
          : null,
    );
  }

  /// `POST /recharge/initiate-order`
  Future<ResponseModel> initiateOrder({
    required String rechargePlanId,
    String? referralCode,
  }) {
    final body = <String, dynamic>{
      'rechargePlanId': rechargePlanId,
      if (referralCode != null && referralCode.isNotEmpty)
        'referralCode': referralCode,
    };
    return ApiBaseHelper().postHTTP(
      rechargeInitiateOrder,
      params: body,
      showProgress: false,
    );
  }

  /// `POST /recharge/verify-payment`
  Future<ResponseModel> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) {
    return ApiBaseHelper().postHTTP(
      rechargeVerifyPayment,
      params: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
      showProgress: false,
    );
  }

  /// `GET /recharge/current` — returns 404 if no active recharge.
  Future<ResponseModel> fetchCurrent() {
    return ApiBaseHelper().getHTTP(rechargeCurrent, showProgress: false);
  }

  /// `POST /recharge/cancel`
  Future<ResponseModel> cancel({required String rechargeId}) {
    return ApiBaseHelper().postHTTP(
      rechargeCancel,
      params: {'rechargeId': rechargeId},
      showProgress: false,
    );
  }
}
