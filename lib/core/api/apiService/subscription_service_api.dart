/// All `subscription-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin SubscriptionServiceApi {
  /// Recharge / Contribution (subscription-service/recharge/...)
  /// See lib/docs/RECHARGE_FLUTTER_GUIDE.md.
  final String rechargePlans = 'subscription-service/recharge/plans';
  final String rechargeInitiateOrder =
      'subscription-service/recharge/initiate-order';
  final String rechargeVerifyPayment =
      'subscription-service/recharge/verify-payment';
  final String rechargeCurrent = 'subscription-service/recharge/current';
  final String rechargeCancel = 'subscription-service/recharge/cancel';
}
