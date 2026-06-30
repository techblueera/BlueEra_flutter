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

  /// Joining Bounce (joining bonus) — the inverse of the Security Deposit:
  /// the platform pays the user a one-time joining bonus once genuine
  /// onboarding is proven. No Razorpay / payment — it's a wallet payout.
  /// See docs/backend/JOINING_BOUNCE_FLUTTER_GUIDE.md.
  /// `GET  /joining-bounce/plans?tag_id=&account_type=` — catalog of plans.
  final String joiningBouncePlans = 'subscription-service/joining-bounce/plans';

  /// `POST /joining-bounce/enroll` — enroll into a plan ({ tag_id, account_type }).
  final String joiningBounceEnroll =
      'subscription-service/joining-bounce/enroll';

  /// `POST /joining-bounce/activity` — report hours/tasks/milestone progress.
  final String joiningBounceActivity =
      'subscription-service/joining-bounce/activity';

  /// `POST /joining-bounce/milestone` — toggle a single required milestone.
  final String joiningBounceMilestone =
      'subscription-service/joining-bounce/milestone';

  /// `GET  /joining-bounce/current` — the user's in_progress/eligible record.
  final String joiningBounceCurrent =
      'subscription-service/joining-bounce/current';

  /// `GET  /joining-bounce/my-bounces?status=` — array of the user's records.
  final String joiningBounceMyBounces =
      'subscription-service/joining-bounce/my-bounces';

  /// `POST /joining-bounce/claim` — pay an eligible bonus into the wallet.
  final String joiningBounceClaim = 'subscription-service/joining-bounce/claim';

  /// `POST /joining-bounce/createclaim` — activate/claim the joining bonus
  /// ({ tag_id, account_type? }). Idempotent: also returns the active record
  /// if it already exists.
  final String joiningBounceCreateClaim =
      'subscription-service/joining-bounce/createclaim';

  /// `POST /joining-bounce/cancel` — cancel an in_progress/eligible record.
  final String joiningBounceCancel =
      'subscription-service/joining-bounce/cancel';

  /// `GET  /joining-bounce/plan/:tagId?account_type=` — one plan by tag.
  String joiningBouncePlanByTag(String tagId) =>
      'subscription-service/joining-bounce/plan/$tagId';

  /// `GET  /joining-bounce/:joiningBounceId/progress` — detailed progress.
  String joiningBounceProgressById(String id) =>
      'subscription-service/joining-bounce/$id/progress';
}
