/// Models for the Account Plan flow — the dynamic paid plans that replace a
/// flat security deposit with what the account actually buys.
///
/// See docs/backend/ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md.
///
/// **Every money field is PAISE.** The `*_inr` rupee values the API also sends
/// are convenience only; [PlanCard.priceTotal] is what gets charged and is
/// never re-computed on the client.
library;

/// Lenient int parse — the API sends num-or-string depending on the field, and
/// a price that silently became 0 would be charged as 0.
int _asInt(dynamic v, [int d = 0]) => v == null
    ? d
    : (v is int ? v : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? d));

num _asNum(dynamic v, [num d = 0]) => v == null
    ? d
    : (v is num ? v : num.tryParse(v.toString()) ?? d);

/// A day count that keeps NULL distinct from zero, unlike [_asInt].
///
/// `days_until_eligible` uses null for "the window is open, or already gone" —
/// collapsing that to 0 would be indistinguishable from "opens today" and would
/// word the button wrongly in both directions. Negative values are read as null
/// for the same reason: a countdown that has run out is not a countdown.
int? _asDays(dynamic v) {
  if (v == null) return null;
  final n = v is num ? v.toInt() : int.tryParse(v.toString());
  if (n == null || n <= 0) return null;
  return n;
}

String? _asStr(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

/// The shapes a plan can take. The archetype is what tells the UI which
/// attribute matters on the card — radius, job types, or tier — so one screen
/// can render every account type without knowing any of them by name.
abstract class PlanArchetype {
  /// Shops, as they are sold TODAY: a sales subscription, valid until the
  /// shop's cumulative sales cross the plan's `sale_limit`, at which point the
  /// backend auto-deactivates it and the shop upgrades.
  ///
  /// This replaced [radiusShop] — same accounts, different rule. The old
  /// constant stays because a plan bought under the radius ladder is still on
  /// the account and still comes back on `my-plans`; nothing re-writes history.
  static const String salesShop = 'A1_SALES_SHOP';

  /// The retired radius ladder (1/3/6/10/25 km). See [salesShop].
  static const String radiusShop = 'A1_RADIUS_SHOP';
  static const String gigCalls = 'A2_GIG_CALLS';
  static const String localService = 'A3_LOCAL_SERVICE';
  static const String leadPro = 'A4_LEAD_PRO';
  static const String booking = 'A5_BOOKING';
  static const String wideReach = 'A6_WIDE_REACH';
  static const String socialFree = 'A0_SOCIAL_FREE';
}

/// `GET /account-plan/plans` → `data`.
class PlanCatalog {
  final String accountType;
  final String tagId;
  final String archetype;
  final String currency;
  final String? group;
  final String? vehicleClass;
  final bool earnsInApp;
  final bool hasGst;
  final int gstPercent;
  final List<PlanCard> plans;

  const PlanCatalog({
    required this.accountType,
    required this.tagId,
    required this.archetype,
    required this.currency,
    required this.group,
    required this.vehicleClass,
    required this.earnsInApp,
    required this.hasGst,
    required this.gstPercent,
    required this.plans,
  });

  factory PlanCatalog.fromJson(Map<String, dynamic> j) => PlanCatalog(
        accountType: j['account_type']?.toString() ?? '',
        tagId: j['tag_id']?.toString() ?? '',
        archetype: j['archetype']?.toString() ?? '',
        currency: j['currency']?.toString() ?? 'INR',
        group: _asStr(j['group']),
        vehicleClass: _asStr(j['vehicle_class']),
        earnsInApp: j['earns_in_app'] == true,
        hasGst: j['has_gst'] == true,
        gstPercent: _asInt(j['gst_percent'], 18),
        plans: ((j['plans'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => PlanCard.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

/// One purchasable card.
class PlanCard {
  final String optionCode;
  final String label;
  final String archetype;
  final String gstTrack;
  final String billing;
  final String? sublabel;
  final String? vehicleClass;
  final String? tier;

  /// `-1` means all-India, not "unset" — see [isAllIndia].
  final int? radiusKm;
  final int? validityDays;
  final List<String>? jobTypes;

  /// The sales cap an A1 plan is valid up to, in RUPEES — the one money field
  /// here that is not paise, because the backend states it that way
  /// (`sale_limit: 600000` = ₹6 Lakh). Null for every other archetype.
  final int? saleLimit;

  final int priceBase;
  final int gstPercent;
  final int gstAmount;

  /// Base + GST, in paise. **This is the charged amount.**
  final int priceTotal;

  final num priceBaseInr;
  final num gstAmountInr;
  final num priceTotalInr;
  final bool isFree;

  /// The backend's one recommended pick per group (e.g. the 3 km radius plan).
  ///
  /// Earns a "POPULAR" badge + amber card treatment, and is the card the pay
  /// bar starts on (`_syncSelection`). It changes nothing about pricing or the
  /// purchase path — the guide calls it cosmetic, and defaulting the selection
  /// is a default, not a decision: the user can still pick any other card.
  /// See the guide, §2.1.
  final bool popular;

  /// The bullet points the card shows. Stored per plan in the DB and returned
  /// by the catalog — rendered VERBATIM, never hardcoded, so copy can change
  /// backend-side without an app release.
  final List<String> features;

  /// Per-plan terms, same contract as [features]. Shown behind the `*T&C` link.
  final List<String> termsAndConditions;

  const PlanCard({
    required this.optionCode,
    required this.label,
    required this.archetype,
    required this.gstTrack,
    required this.billing,
    required this.sublabel,
    required this.vehicleClass,
    required this.tier,
    required this.radiusKm,
    required this.validityDays,
    required this.jobTypes,
    required this.saleLimit,
    required this.priceBase,
    required this.gstPercent,
    required this.gstAmount,
    required this.priceTotal,
    required this.priceBaseInr,
    required this.gstAmountInr,
    required this.priceTotalInr,
    required this.isFree,
    required this.popular,
    required this.features,
    required this.termsAndConditions,
  });

  static List<String> _asStrList(dynamic v) => (v is List)
      ? v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
      : const <String>[];

  factory PlanCard.fromJson(Map<String, dynamic> j) {
    final attrs = j['attributes'];
    final Map attributes = attrs is Map ? attrs : const {};
    return PlanCard(
      optionCode: j['option_code']?.toString() ?? '',
      label: j['label']?.toString() ?? '',
      archetype: j['archetype']?.toString() ?? '',
      gstTrack: j['gst_track']?.toString() ?? 'NA',
      billing: j['billing']?.toString() ?? 'one_time',
      sublabel: _asStr(j['sublabel']),
      vehicleClass: _asStr(j['vehicle_class']),
      tier: _asStr(attributes['tier']),
      radiusKm:
          attributes['radius_km'] == null ? null : _asInt(attributes['radius_km']),
      validityDays:
          j['validity_days'] == null ? null : _asInt(j['validity_days']),
      jobTypes: (attributes['job_types'] as List?)
          ?.map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      // Sent at both levels; the attribute is the documented home and the
      // top-level copy is the fallback.
      saleLimit: (attributes['sale_limit'] ?? j['sale_limit']) == null
          ? null
          : _asInt(attributes['sale_limit'] ?? j['sale_limit']),
      priceBase: _asInt(j['price_base']),
      gstPercent: _asInt(j['gst_percent'], 18),
      gstAmount: _asInt(j['gst_amount']),
      priceTotal: _asInt(j['price_total']),
      priceBaseInr: _asNum(j['price_base_inr']),
      gstAmountInr: _asNum(j['gst_amount_inr']),
      priceTotalInr: _asNum(j['price_total_inr']),
      isFree: j['is_free'] == true,
      popular: j['popular'] == true,
      features: _asStrList(j['features']),
      termsAndConditions: _asStrList(j['terms_and_conditions']),
    );
  }

  /// The catalog encodes "everywhere" as a radius of -1.
  bool get isAllIndia => radiusKm == -1;

  /// A sales-capped shop plan — the A1 rule as it stands now. See
  /// [PlanArchetype.salesShop].
  bool get isSalesShop => archetype == PlanArchetype.salesShop;

  /// Whether this plan is only sold to a GST-registered account. The catalog
  /// splits shop radius into a GST and a no-GST track; the card says so out
  /// loud because it is the one condition a buyer can fail after paying
  /// attention only to the price.
  bool get requiresGst => gstTrack.toUpperCase() == 'GST';

  /// Nothing to charge for — a free entitlement, or a card the backend priced
  /// at zero. Either way checkout must not open.
  bool get isPurchasable => !isFree && priceTotal > 0;
}

/// `POST /account-plan/initiate` → `data`.
///
/// Also covers the two non-checkout outcomes the guide calls out:
/// a free/zero-price option comes back with a null [orderId] and
/// `status: "active"`, and a resumed unpaid order sets [resumed].
class InitiatePlanResponse {
  final String orderId;
  final String keyId;
  final String currency;
  final String optionCode;
  final String optionLabel;
  final String accountPlanId;
  final String status;
  final int baseAmount;
  final int gstAmount;
  final int totalAmount;
  final bool resumed;

  const InitiatePlanResponse({
    required this.orderId,
    required this.keyId,
    required this.currency,
    required this.optionCode,
    required this.optionLabel,
    required this.accountPlanId,
    required this.status,
    required this.baseAmount,
    required this.gstAmount,
    required this.totalAmount,
    required this.resumed,
  });

  factory InitiatePlanResponse.fromJson(Map<String, dynamic> j) =>
      InitiatePlanResponse(
        orderId: j['order_id']?.toString() ?? '',
        keyId: j['key_id']?.toString() ?? '',
        currency: j['currency']?.toString() ?? 'INR',
        optionCode: j['option_code']?.toString() ?? '',
        optionLabel: j['option_label']?.toString() ?? '',
        accountPlanId: j['account_plan_id']?.toString() ?? '',
        status: j['status']?.toString() ?? 'created',
        baseAmount: _asInt(j['base_amount']),
        gstAmount: _asInt(j['gst_amount']),
        totalAmount: _asInt(j['total_amount']),
        resumed: j['resumed'] == true,
      );

  /// Nothing to pay — the backend already activated it, so checkout must NOT
  /// open. True for free options and for a resumed order that was in fact
  /// already paid.
  bool get isAlreadyActive => status == 'active' || orderId.isEmpty;
}

/// `GET /account-plan/my-plans` → one row.
class UserAccountPlan {
  final String id;
  final String optionCode;
  final String optionLabel;
  final String archetype;
  final String status;
  final String? tier;
  final int? radiusKm;
  final List<String>? jobTypes;
  final int totalAmount;
  final DateTime? activatedAt;

  /// The refund window on this purchase — see [PlanRefund]. Never absent in
  /// practice, but parsed leniently: a backend that has not shipped the block
  /// yet reads as "refunds are off", which hides the control.
  final PlanRefund refund;

  const UserAccountPlan({
    required this.id,
    required this.optionCode,
    required this.optionLabel,
    required this.archetype,
    required this.status,
    required this.tier,
    required this.radiusKm,
    required this.jobTypes,
    required this.totalAmount,
    required this.activatedAt,
    required this.refund,
  });

  factory UserAccountPlan.fromJson(Map<String, dynamic> j) => UserAccountPlan(
        id: (j['_id'] ?? j['id'])?.toString() ?? '',
        optionCode: j['option_code']?.toString() ?? '',
        optionLabel: j['option_label']?.toString() ?? '',
        archetype: j['archetype']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        tier: _asStr(j['tier']),
        radiusKm: j['radius_km'] == null ? null : _asInt(j['radius_km']),
        jobTypes: (j['job_types'] as List?)?.map((e) => e.toString()).toList(),
        totalAmount: _asInt(j['total_amount']),
        activatedAt: DateTime.tryParse(j['activated_at']?.toString() ?? ''),
        refund: PlanRefund.fromJson(j['refund']),
      );

  bool get isActive => status == 'active';

  /// Whether this purchase is a sales-capped shop plan — the gate on calling
  /// `sales/usage` at all. See [PlanArchetype.salesShop].
  bool get isSalesShop => archetype == PlanArchetype.salesShop;
}

/// `my-plans[].refund` — the refund window on one purchase.
///
/// Plans are refundable, but narrowly: the fee (GST excluded) can be returned
/// only after **6 months**, for a **10-day window**, and only if the account
/// earned less than the plan cost. All three tests are the server's — this
/// object is the answer, and [canRequestRefund] is the only thing that decides
/// whether the button works.
///
/// Nothing here is computed client-side on purpose. Comparing
/// [refundEligibleAt] against the device clock would put the decision on a
/// clock the user can change, and re-deriving "6 months" would hard-code a
/// policy the backend is free to move. The dates below are for the DISABLED
/// label only ("available after…"), never for enabling anything.
class PlanRefund {
  /// Server kill-switch. False hides the refund control entirely — the guide is
  /// explicit that the whole feature can be turned off backend-side.
  final bool refundSystemEnabled;

  /// Whether this plan is refundable at all. False for free plans, which never
  /// took money to give back.
  final bool refundable;

  /// `none | requested | approved | refunded | rejected | expired`.
  final String refundStatus;

  /// When the window opens (activation + 6 months) and closes (+10 days).
  final DateTime? refundEligibleAt;
  final DateTime? refundWindowClosesAt;

  final bool windowOpen;

  /// Days left before the window opens, counted by the SERVER. `> 0` is what
  /// words the disabled button ("available in N days"); null means the window
  /// is already open or long closed, and the label falls to those cases.
  ///
  /// Server-counted on purpose — the same reason the dates are not compared
  /// here: a day count derived from the device clock would drift with it.
  final int? daysUntilEligible;

  /// **The only enable condition.** Everything else on this object explains a
  /// disabled button; this one turns it on.
  final bool canRequestRefund;

  /// Base fee only — GST is not refunded. RUPEES.
  final int refundableAmountInr;

  final String? razorpayRefundId;
  final DateTime? refundedAt;

  const PlanRefund({
    required this.refundSystemEnabled,
    required this.refundable,
    required this.refundStatus,
    required this.refundEligibleAt,
    required this.refundWindowClosesAt,
    required this.windowOpen,
    required this.daysUntilEligible,
    required this.canRequestRefund,
    required this.refundableAmountInr,
    required this.razorpayRefundId,
    required this.refundedAt,
  });

  /// A missing block reads as "refunds are off" rather than as an error: a
  /// backend that has not shipped this yet, and one that has switched it off,
  /// should look the same to the user — no control.
  factory PlanRefund.fromJson(dynamic raw) {
    final j = raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
    return PlanRefund(
      refundSystemEnabled: j['refund_system_enabled'] == true,
      refundable: j['refundable'] == true,
      refundStatus: j['refund_status']?.toString() ?? 'none',
      refundEligibleAt:
          DateTime.tryParse(j['refund_eligible_at']?.toString() ?? ''),
      refundWindowClosesAt:
          DateTime.tryParse(j['refund_window_closes_at']?.toString() ?? ''),
      windowOpen: j['window_open'] == true,
      daysUntilEligible: _asDays(j['days_until_eligible']),
      canRequestRefund: j['can_request_refund'] == true,
      refundableAmountInr: _asInt(j['refundable_amount_inr']),
      razorpayRefundId: _asStr(j['razorpay_refund_id']),
      refundedAt: DateTime.tryParse(j['refunded_at']?.toString() ?? ''),
    );
  }

  /// Whether to draw the control at all. Off when the feature is disabled
  /// server-side, and off for a free plan — "request a refund" on something
  /// nobody paid for is a question with no answer.
  bool get isVisible => refundSystemEnabled && refundable;

  bool get isRequested => refundStatus == 'requested';
  bool get isSettled =>
      refundStatus == 'approved' || refundStatus == 'refunded';
  bool get isRejected => refundStatus == 'rejected';

  /// Window has been and gone — either the server said so, or the close date
  /// is in the past with nothing having been asked for.
  bool get isExpired {
    if (refundStatus == 'expired') return true;
    if (refundStatus != 'none') return false;
    final closes = refundWindowClosesAt;
    return closes != null && DateTime.now().isAfter(closes);
  }

  /// Still waiting for the window to open.
  ///
  /// [daysUntilEligible] is the authority when the server sends it — that is
  /// the guide's rule (`refund_status == "none"` & `days_until_eligible > 0`),
  /// and it is the number the disabled label quotes. The date comparison is
  /// only a fallback for a backend that ships the dates without the count;
  /// without it such a response would fall through to "window closed", which
  /// is the opposite of the truth.
  bool get isPending {
    if (refundStatus != 'none' || canRequestRefund) return false;
    if (daysUntilEligible != null) return true;
    final opens = refundEligibleAt;
    return opens != null && DateTime.now().isBefore(opens);
  }
}

/// `GET /account-plan/sales/usage` → `data`.
///
/// How much of an A1 shop plan's sales cap has been used. **Every amount here
/// is RUPEES**, unlike the paise everywhere else in this file — the endpoint
/// states it that way, and converting would only invite a second unit to get
/// wrong.
///
/// [hasSalesPlan] false means the account holds no active sales plan; the UI
/// shows nothing rather than an empty bar, which is also how a failed read is
/// treated (guide §2.2.1: fail-quiet).
class SalesUsage {
  final bool hasSalesPlan;
  final String optionLabel;
  final int saleLimitInr;
  final int salesAccruedInr;
  final int salesRemainingInr;

  /// 0–100, clamped server-side. Clamped again here because a progress bar is
  /// one of the few widgets that throws on an out-of-range value.
  final int percentUsed;

  const SalesUsage({
    required this.hasSalesPlan,
    required this.optionLabel,
    required this.saleLimitInr,
    required this.salesAccruedInr,
    required this.salesRemainingInr,
    required this.percentUsed,
  });

  factory SalesUsage.fromJson(Map<String, dynamic> j) => SalesUsage(
        hasSalesPlan: j['has_sales_plan'] == true,
        optionLabel: j['option_label']?.toString() ?? '',
        saleLimitInr: _asInt(j['sale_limit_inr']),
        salesAccruedInr: _asInt(j['sales_accrued_inr']),
        salesRemainingInr: _asInt(j['sales_remaining_inr']),
        percentUsed: _asInt(j['percent_used']).clamp(0, 100),
      );

  /// Nothing worth drawing: no plan, or a cap of zero (which would make the
  /// bar a division by zero as well as a meaningless statement).
  bool get isRenderable => hasSalesPlan && saleLimitInr > 0;

  /// The fraction for the bar itself.
  double get fraction => (percentUsed / 100).clamp(0.0, 1.0);

  /// Close enough to the cap that the shop should be told it is about to stop
  /// receiving orders, rather than finding out when it does.
  bool get isNearLimit => percentUsed >= 80;

  /// Spent. The server has already deactivated the plan (or is about to), so
  /// the copy stops warning and starts telling them to upgrade.
  bool get isExhausted => percentUsed >= 100 || salesRemainingInr <= 0;
}
