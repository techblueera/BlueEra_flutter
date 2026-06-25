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

  /// Security Deposit — the v2 "contribution" flow.
  /// See docs/backend/SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md.
  /// Base path for `plan/{tagId}` and `{depositId}/details`; the repo appends
  /// the path segment.
  final String securityDepositBase = 'subscription-service/security-deposit/';
  final String securityDepositPlans =
      'subscription-service/security-deposit/plans';
  final String securityDepositInitiate =
      'subscription-service/security-deposit/initiate';
  final String securityDepositVerifyPayment =
      'subscription-service/security-deposit/verify-payment';
  final String securityDepositCurrent =
      'subscription-service/security-deposit/current';
  final String securityDepositMyDeposits =
      'subscription-service/security-deposit/my-deposits';
  final String securityDepositRefundRequest =
      'subscription-service/security-deposit/refund/request';
  final String securityDepositCancel =
      'subscription-service/security-deposit/cancel';
}
