/// All `subscription-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
mixin SubscriptionServiceApi {
  /// Legacy recharge — status read only. The catalog / purchase endpoints went
  /// with the old contribution flow; buying happens on `accountPlan*` below.
  final String rechargeCurrent = 'subscription-service/recharge/current';

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

  /// `GET /security-deposit/videos` — explainer videos shown on top of the
  /// security-deposit (contribution v2) screen.
  final String securityDepositVideos =
      'subscription-service/security-deposit/videos';

  /// `GET /security-deposit/gst` — the CURRENT tax rate for security deposits.
  /// Display only: the amount actually charged is always `final_amount` off
  /// `/initiate`, which the backend freezes per order.
  /// See docs/backend/SECURITY_DEPOSIT_GST_INVOICE_FLUTTER_GUIDE.md.
  final String securityDepositGst =
      'subscription-service/security-deposit/gst';

  /// Account Plans — the dynamic paid plans that replace a flat deposit with
  /// what the account actually buys: visibility radius, gig call types,
  /// service area, lead/booking tier. One catalog endpoint serves all 138
  /// account types; the app renders whatever `plans[]` come back and never
  /// hard-codes a price.
  /// See docs/backend/ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md.
  final String accountPlanPlans = 'subscription-service/account-plan/plans';
  final String accountPlanMyPlans =
      'subscription-service/account-plan/my-plans';

  /// `GET /account-plan/sales/usage` — how much of an A1 sales plan's cap the
  /// shop has spent.
  ///
  /// **A1 sales-shops with an ACTIVE plan only.** It answers
  /// `has_sales_plan: false` for every other archetype, so calling it from a
  /// generic load would be a request that can never say anything. Guide §2.2.1.
  final String accountPlanSalesUsage =
      'subscription-service/account-plan/sales/usage';
  final String accountPlanInitiate =
      'subscription-service/account-plan/initiate';
  final String accountPlanVerifyPayment =
      'subscription-service/account-plan/verify-payment';
  final String accountPlanInvoices =
      'subscription-service/account-plan/invoices';

  /// `GET /account-plan/{id}/invoice` — one purchase's GST invoice.
  String accountPlanInvoiceById(String id) =>
      'subscription-service/account-plan/$id/invoice';

  /// `POST /account-plan/{id}/refund-request` — ask for a refund on a paid
  /// plan. Body `{ tnc_accepted: true, note?: String }`.
  ///
  /// The app never decides WHETHER a refund can be asked for: every my-plans
  /// item carries a `refund` object whose `can_request_refund` is the only
  /// answer, so the window (activation + 6 months, open for 10 days) and the
  /// earnings test both stay server-side.
  /// See docs/backend/ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md §2.2.2.
  String accountPlanRefundRequest(String id) =>
      'subscription-service/account-plan/$id/refund-request';

  /// Deposit → account-plan MIGRATION. An existing security-deposit holder is
  /// offered the matching account plan for free; the deposit itself stays
  /// refundable and is auto-refunded on its original date.
  /// See docs/backend/DEPOSIT_MIGRATION_FLUTTER_GUIDE.md.
  ///
  /// `GET /migration/eligibility` — drives the popup (never show it unless this
  /// answers `eligible: true`).
  final String accountPlanMigrationEligibility =
      'subscription-service/account-plan/migration/eligibility';

  /// `POST /migration/migrate` — `{ tnc_accepted: true }`. Idempotent: a second
  /// call answers `already: true`, which counts as success.
  final String accountPlanMigrate =
      'subscription-service/account-plan/migration/migrate';

  /// UPGRADE WITH CREDIT — for a user who already holds a plan. What they have
  /// already paid (their current plan, or the deposit they migrated from) is
  /// credited against the higher tier, so they pay only the difference.
  ///
  /// `GET /migration/upgrade-options` — the active plan, the credit, and one
  /// `price_breakdown` per higher tier. The breakdown is the ONLY source for
  /// the numbers shown at confirmation; the app never computes a total.
  final String accountPlanUpgradeOptions =
      'subscription-service/account-plan/migration/upgrade-options';

  /// `POST /migration/upgrade` — `{ option_code, buyer_state, tnc_accepted? }`.
  /// Answers either an order for the DIFFERENCE, `upgraded: true` when the
  /// credit covers it outright, or `requires_tnc: true` when the credit comes
  /// from a refundable deposit and has to be spent knowingly.
  final String accountPlanUpgrade =
      'subscription-service/account-plan/migration/upgrade';

  /// `POST /migration/upgrade/verify` — the upgrade's own verify. Separate from
  /// [accountPlanVerifyPayment]: that one settles a fresh plan purchase, this
  /// one settles an order that was priced against a credit.
  final String accountPlanUpgradeVerify =
      'subscription-service/account-plan/migration/upgrade/verify';

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
