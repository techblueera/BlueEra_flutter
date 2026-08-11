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

String? _asStr(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

/// The shapes a plan can take. The archetype is what tells the UI which
/// attribute matters on the card — radius, job types, or tier — so one screen
/// can render every account type without knowing any of them by name.
abstract class PlanArchetype {
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

  final int priceBase;
  final int gstPercent;
  final int gstAmount;

  /// Base + GST, in paise. **This is the charged amount.**
  final int priceTotal;

  final num priceBaseInr;
  final num priceTotalInr;
  final bool isFree;

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
    required this.priceBase,
    required this.gstPercent,
    required this.gstAmount,
    required this.priceTotal,
    required this.priceBaseInr,
    required this.priceTotalInr,
    required this.isFree,
  });

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
      priceBase: _asInt(j['price_base']),
      gstPercent: _asInt(j['gst_percent'], 18),
      gstAmount: _asInt(j['gst_amount']),
      priceTotal: _asInt(j['price_total']),
      priceBaseInr: _asNum(j['price_base_inr']),
      priceTotalInr: _asNum(j['price_total_inr']),
      isFree: j['is_free'] == true,
    );
  }

  /// The catalog encodes "everywhere" as a radius of -1.
  bool get isAllIndia => radiusKm == -1;
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
      );

  bool get isActive => status == 'active';
}
