/// Models for the Account Plan flow — the dynamic paid plans that replace a
/// flat security deposit with what the account actually buys.
///
/// See docs/backend/ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md.
///
/// **Every money field is PAISE.** The `*_inr` rupee values the API also sends
/// are convenience only; [PlanCard.priceTotal] is what gets charged and is
/// never re-computed on the client.
library;

// The one Flutter type this file needs: [DiscountTheme] parses admin-authored
// hex into a real [Color] so no caller has to repeat the fallback rules.
import 'dart:ui' show Color;

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

/// A list of non-empty strings — feature bullets, plan T&C, campaign terms.
List<String> _asStrList(dynamic v) => (v is List)
    ? v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
    : const <String>[];

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

// ═══════════════════════════════════════════════════════════════
// DISCOUNTS — admin-created campaigns (festive / flash / launch /
// coupon), layered onto the same catalog.
//
// See docs/backend/ACCOUNT_PLAN_DISCOUNT_FLUTTER_GUIDE.md.
//
// **The one rule:** `price_base` / `gst_amount` / `price_total` are always the
// LIST price; `final_price_*` is always what will be charged and always exists
// (equal to the list values when nothing is running). Every live price the user
// is shown reads `final_*`; the list values survive only as the struck-through
// "was" number. Nothing here is computed — caps, clamps, rounding and the
// sub-₹1 rule all live server-side.
// ═══════════════════════════════════════════════════════════════

/// A campaign's colours and icon, all admin-authored and all optional.
///
/// Every field can be null and every colour can be a typo — a campaign created
/// without a theme, or with `"red"` in a hex field, must fall back to the app
/// palette rather than render null or crash a screen that sells things.
class DiscountTheme {
  final String? accentColor;
  final String? textColor;
  final String? backgroundColor;

  /// An EMOJI string from the DB (🪔, ⚡), not an asset name — rendered as text.
  final String? icon;

  final String? imageUrl;

  const DiscountTheme({
    this.accentColor,
    this.textColor,
    this.backgroundColor,
    this.icon,
    this.imageUrl,
  });

  factory DiscountTheme.fromJson(dynamic raw) {
    final j = raw is Map ? Map<String, dynamic>.from(raw) : const {};
    return DiscountTheme(
      accentColor: _asStr(j['accent_color']),
      textColor: _asStr(j['text_color']),
      backgroundColor: _asStr(j['background_color']),
      icon: _asStr(j['icon']),
      imageUrl: _asStr(j['image_url']),
    );
  }

  /// `#RRGGBB` / `#AARRGGBB` → a colour, or [fallback] on anything else.
  ///
  /// Deliberately total: an admin typing a colour name into a hex field is a
  /// content mistake, and it must cost a wrong tint, never the plans screen.
  static Color colorOf(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return fallback;
    final v = int.tryParse(h, radix: 16);
    return v == null ? fallback : Color(v);
  }

  Color accent(Color fallback) => colorOf(accentColor, fallback);
  Color text(Color fallback) => colorOf(textColor, fallback);
  Color background(Color fallback) => colorOf(backgroundColor, fallback);
}

/// The campaign banner above the catalog. Null on the catalog ⇒ render nothing.
class PlanCampaign {
  final String code;
  final String name;

  /// `FESTIVE | FLASH | LAUNCH | PROMO | …` — free-form, never branched on by
  /// name. A new festival must never need an app release.
  final String kind;

  final String bannerText;
  final String bannerSubtext;
  final String badgeText;
  final DiscountTheme theme;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// Seconds left **as counted by the SERVER**. The countdown ticks down from
  /// this rather than diffing [endsAt] against the device clock, which the user
  /// can set to anything.
  final int? endsInSeconds;

  final bool showCountdown;

  /// The campaign's OWN terms — separate from any plan's, and rendered
  /// verbatim like every other piece of admin copy.
  final List<String> termsAndConditions;

  const PlanCampaign({
    required this.code,
    required this.name,
    required this.kind,
    required this.bannerText,
    required this.bannerSubtext,
    required this.badgeText,
    required this.theme,
    required this.startsAt,
    required this.endsAt,
    required this.endsInSeconds,
    required this.showCountdown,
    required this.termsAndConditions,
  });

  factory PlanCampaign.fromJson(Map<String, dynamic> j) => PlanCampaign(
        code: j['code']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        kind: j['kind']?.toString() ?? 'PROMO',
        bannerText: _asStr(j['banner_text']) ?? _asStr(j['name']) ?? '',
        bannerSubtext: _asStr(j['banner_subtext']) ?? '',
        badgeText: _asStr(j['badge_text']) ?? '',
        theme: DiscountTheme.fromJson(j['theme']),
        startsAt: DateTime.tryParse(j['starts_at']?.toString() ?? ''),
        endsAt: DateTime.tryParse(j['ends_at']?.toString() ?? ''),
        endsInSeconds:
            j['ends_in_seconds'] == null ? null : _asInt(j['ends_in_seconds']),
        showCountdown: j['show_countdown'] == true,
        termsAndConditions: _asStrList(j['terms_and_conditions']),
      );

  /// Only run a timer when the server actually gave us a remaining time. An
  /// open-ended campaign (`ends_at: null`) still applies — it just has no clock.
  bool get hasCountdown =>
      showCountdown && endsInSeconds != null && endsInSeconds! > 0;
}

/// The discount block on one plan card — what THIS card saves, which is not
/// necessarily what the banner advertises: a campaign can be scoped to some
/// tiers only, and a cap can make the realised percentage smaller.
class CardDiscount {
  final String code;
  final String name;
  final String kind;

  /// `PERCENT | FLAT` — display only; the app never applies either.
  final String discountType;

  final String badgeText;

  /// The campaign's headline value (e.g. 30 for "30%"). **Never shown** — see
  /// [percentOff].
  final num value;

  /// The REALISED percentage, after any cap. The only percentage the UI may
  /// print: a "30% off, max ₹1,000" campaign on a ₹6,999 plan realises 14%,
  /// and saying 30% there is a promise the price does not keep.
  final num percentOff;

  /// PAISE.
  final int discountAmount;
  final int finalPriceBase;
  final int finalGstAmount;
  final int finalPriceTotal;

  /// RUPEES — the convenience values the display reads.
  final num discountAmountInr;
  final num finalPriceBaseInr;
  final num finalGstAmountInr;
  final num finalPriceTotalInr;

  final DateTime? endsAt;
  final int? endsInSeconds;
  final bool showCountdown;

  /// True when this discount exists only because a coupon code unlocked it.
  final bool requiresCoupon;

  final DiscountTheme theme;
  final List<String> termsAndConditions;

  const CardDiscount({
    required this.code,
    required this.name,
    required this.kind,
    required this.discountType,
    required this.badgeText,
    required this.value,
    required this.percentOff,
    required this.discountAmount,
    required this.finalPriceBase,
    required this.finalGstAmount,
    required this.finalPriceTotal,
    required this.discountAmountInr,
    required this.finalPriceBaseInr,
    required this.finalGstAmountInr,
    required this.finalPriceTotalInr,
    required this.endsAt,
    required this.endsInSeconds,
    required this.showCountdown,
    required this.requiresCoupon,
    required this.theme,
    required this.termsAndConditions,
  });

  factory CardDiscount.fromJson(Map<String, dynamic> j) => CardDiscount(
        code: j['code']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        kind: j['kind']?.toString() ?? 'PROMO',
        discountType: j['discount_type']?.toString() ?? 'PERCENT',
        badgeText: _asStr(j['badge_text']) ?? '',
        value: _asNum(j['value']),
        percentOff: _asNum(j['percent_off']),
        discountAmount: _asInt(j['discount_amount']),
        finalPriceBase: _asInt(j['final_price_base']),
        finalGstAmount: _asInt(j['final_gst_amount']),
        finalPriceTotal: _asInt(j['final_price_total']),
        discountAmountInr: _asNum(j['discount_amount_inr']),
        finalPriceBaseInr: _asNum(j['final_price_base_inr']),
        finalGstAmountInr: _asNum(j['final_gst_amount_inr']),
        finalPriceTotalInr: _asNum(j['final_price_total_inr']),
        endsAt: DateTime.tryParse(j['ends_at']?.toString() ?? ''),
        endsInSeconds:
            j['ends_in_seconds'] == null ? null : _asInt(j['ends_in_seconds']),
        showCountdown: j['show_countdown'] == true,
        requiresCoupon: j['requires_coupon'] == true,
        theme: DiscountTheme.fromJson(j['theme']),
        termsAndConditions: _asStrList(j['terms_and_conditions']),
      );

  bool get hasCountdown =>
      showCountdown && endsInSeconds != null && endsInSeconds! > 0;

  /// The ribbon's number: the admin's own copy when there is any, otherwise the
  /// REALISED percentage. Callers append the localised "OFF".
  String get badgeOrPercent {
    if (badgeText.isNotEmpty) return badgeText;
    final p = percentOff;
    return '${p == p.truncateToDouble() ? p.toInt() : p}%';
  }
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

  /// The server's kill-switch for the whole discount system. When false there
  /// is no banner, no ribbon, no strike-through anywhere — see [showCampaign].
  final bool discountEnabled;

  /// The campaign running right now, or null when nothing is.
  final PlanCampaign? campaign;

  /// When the server produced this catalog. Countdowns are anchored to the
  /// server's own `ends_in_seconds` rather than to this, but it is what makes a
  /// device-clock discrepancy diagnosable.
  final DateTime? serverTime;

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
    required this.discountEnabled,
    required this.campaign,
    required this.serverTime,
  });

  /// The single gate for every discount affordance on the screen: the system is
  /// on AND something is actually running.
  ///
  /// The banner shows whenever a campaign is live, even if only some cards are
  /// in its scope — per-card eligibility is [PlanCard.showsOffer]'s business.
  bool get showCampaign => discountEnabled && campaign != null;

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
        // Default TRUE: a backend that predates the flag is not a backend with
        // discounts switched off, and reading its absence as "off" would hide a
        // live sale.
        discountEnabled: j['discount_enabled'] != false,
        campaign: j['campaign'] is Map
            ? PlanCampaign.fromJson(
                Map<String, dynamic>.from(j['campaign'] as Map))
            : null,
        serverTime: DateTime.tryParse(j['server_time']?.toString() ?? ''),
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

  /// How many days the plan runs for, or null when it does not expire on a
  /// date at all.
  ///
  /// Read from `validity_days_count`. The older `validity_days` is a
  /// **display string** now (`"Life Time"`, and days as text elsewhere), so
  /// parsing it as a number is what produced "Valid for 0 days" on a lifetime
  /// plan: `_asInt` falls back to 0 on an unparseable string, and 0 is not
  /// null, so the chip rendered. [_asDays] is used instead precisely because
  /// it answers null for both a non-numeric label and a zero.
  final int? validityDays;

  /// The backend's own words for the validity — `"Life Time"`. Rendered
  /// verbatim wherever it exists, in preference to anything computed here:
  /// it is the one statement about duration the server actually authored.
  final String? validityLabel;

  /// Whether the plan simply never expires.
  final bool isLifetime;

  final List<String>? jobTypes;

  /// The sales cap an A1 plan is valid up to, in RUPEES — the one money field
  /// here that is not paise, because the backend states it that way
  /// (`sale_limit: 600000` = ₹6 Lakh). Null for every other archetype.
  final int? saleLimit;

  /// The LIST price, in paise — what the plan costs with no campaign running.
  ///
  /// **Not the live price.** During a sale this is the struck-through "was"
  /// number and nothing else; [finalPriceBase] is what the buyer pays. Showing
  /// this as the price is the single easiest way to quote the wrong figure for
  /// the whole length of a campaign.
  final int priceBase;

  final int gstPercent;

  /// GST on the LIST price. See [finalGstAmount] for the charged tax — GST is
  /// levied on the DISCOUNTED base, so during a sale these differ.
  final int gstAmount;

  /// List base + list GST, in paise. See [finalPriceTotal].
  final int priceTotal;

  final num priceBaseInr;
  final num gstAmountInr;
  final num priceTotalInr;

  /// Whether a campaign applies to THIS card. A campaign can be live and this
  /// card still be out of its scope.
  final bool hasDiscount;

  /// The winning campaign as it lands on this card, or null. Carries the badge,
  /// the theme, the countdown and the campaign's own terms.
  final CardDiscount? discount;

  /// **What will actually be charged.** Always present: with no discount these
  /// equal the list values exactly, so reading only `final*` is always right.
  final int finalPriceBase;
  final int finalGstAmount;
  final int finalPriceTotal;
  final num finalPriceBaseInr;
  final num finalGstAmountInr;
  final num finalPriceTotalInr;

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
    required this.validityLabel,
    required this.isLifetime,
    required this.jobTypes,
    required this.saleLimit,
    required this.priceBase,
    required this.gstPercent,
    required this.gstAmount,
    required this.priceTotal,
    required this.priceBaseInr,
    required this.gstAmountInr,
    required this.priceTotalInr,
    required this.hasDiscount,
    required this.discount,
    required this.finalPriceBase,
    required this.finalGstAmount,
    required this.finalPriceTotal,
    required this.finalPriceBaseInr,
    required this.finalGstAmountInr,
    required this.finalPriceTotalInr,
    required this.isFree,
    required this.popular,
    required this.features,
    required this.termsAndConditions,
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
      // `validity_days_count` is the number; `validity_days` is the label. The
      // legacy numeric `validity_days` is kept as a fallback so a backend that
      // still sends days-as-a-number keeps working.
      validityDays: _asDays(j['validity_days_count'] ?? j['validity_days']),
      // Only a NON-numeric `validity_days` is a label — "30" is a day count
      // that [validityDays] already carries, and echoing it here would print
      // a bare "30" next to the price.
      validityLabel: _asDays(j['validity_days']) == null
          ? _asStr(j['validity_days'])
          : null,
      isLifetime: j['is_lifetime'] == true,
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
      hasDiscount: j['has_discount'] == true,
      discount: j['discount'] is Map
          ? CardDiscount.fromJson(Map<String, dynamic>.from(j['discount'] as Map))
          : null,
      // Every `final_*` falls back to its LIST counterpart. A backend that
      // predates discounts — or a cached response from one — then reads as
      // "full price", which is the truth there; without the fallback the card
      // would offer the plan at ₹0 and the pay bar would say so.
      finalPriceBase: _asInt(j['final_price_base'], _asInt(j['price_base'])),
      finalGstAmount: _asInt(j['final_gst_amount'], _asInt(j['gst_amount'])),
      finalPriceTotal: _asInt(j['final_price_total'], _asInt(j['price_total'])),
      finalPriceBaseInr:
          _asNum(j['final_price_base_inr'], _asNum(j['price_base_inr'])),
      finalGstAmountInr:
          _asNum(j['final_gst_amount_inr'], _asNum(j['gst_amount_inr'])),
      finalPriceTotalInr:
          _asNum(j['final_price_total_inr'], _asNum(j['price_total_inr'])),
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
  ///
  /// Deliberately on the LIST total: a card discounted to nothing is still a
  /// plan the user has to *buy* (the backend activates it free at `initiate`),
  /// not a free entitlement, and rendering it as "Free" would hide the offer
  /// that made it free.
  bool get isPurchasable => !isFree && priceTotal > 0;

  /// Whether this card has a real saving to display. Guards every discount
  /// affordance on the card: a `has_discount` with a zero amount buys the buyer
  /// nothing and must not draw a ribbon or a strike-through.
  bool get showsOffer =>
      hasDiscount && discount != null && discount!.discountAmount > 0;
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
  /// The taxable base AFTER any discount and any upgrade credit — paise.
  final int baseAmount;

  final int gstAmount;

  /// The rate the tax was levied at, for the receipt's "GST (18%)" row.
  final int gstPercent;

  /// **The only amount Razorpay may be opened with.** Discount- and
  /// GST-inclusive, computed server-side.
  final int totalAmount;

  final bool resumed;

  /// What the plan would have cost with no campaign — paise. Falls back to
  /// [baseAmount] when the backend sends none, so the receipt never invents a
  /// discount out of a missing field.
  final int listBaseAmount;

  /// The campaign that applied to this order, frozen onto it. Null/0 when none
  /// did.
  final String? discountCode;
  final String? discountLabel;
  final int discountAmount;
  final num discountAmountInr;
  final DateTime? discountEndsAt;

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
    required this.gstPercent,
    required this.totalAmount,
    required this.resumed,
    required this.listBaseAmount,
    required this.discountCode,
    required this.discountLabel,
    required this.discountAmount,
    required this.discountAmountInr,
    required this.discountEndsAt,
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
        gstPercent: _asInt(j['gst_percent'], 18),
        totalAmount: _asInt(j['total_amount']),
        resumed: j['resumed'] == true,
        listBaseAmount: _asInt(j['list_base_amount'], _asInt(j['base_amount'])),
        discountCode: _asStr(j['discount_code']),
        discountLabel: _asStr(j['discount_label']),
        discountAmount: _asInt(j['discount_amount']),
        discountAmountInr: _asNum(j['discount_amount_inr']),
        discountEndsAt:
            DateTime.tryParse(j['discount_ends_at']?.toString() ?? ''),
      );

  /// Nothing to pay — the backend already activated it, so checkout must NOT
  /// open. True for free options and for a resumed order that was in fact
  /// already paid.
  bool get isAlreadyActive => status == 'active' || orderId.isEmpty;

  /// A campaign applied to THIS order. The receipt's discount rows hang off it.
  bool get hasDiscount =>
      (discountCode ?? '').isNotEmpty && discountAmount > 0;

  /// The campaign covered the entire price — the backend has activated the plan
  /// outright. **Razorpay must not be opened**: a gateway order of ₹0 fails,
  /// and there is nothing to collect anyway.
  bool get isFreeAfterDiscount => totalAmount <= 0;
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

  /// The campaign this plan was BOUGHT under, frozen onto the purchase.
  ///
  /// Frozen is the whole point: the campaign ending — or being deleted — never
  /// rewrites what the user paid, so "Bought in Diwali Dhamaka — you saved
  /// ₹1,079" stays true forever. Null on a purchase made at list price, and on
  /// every purchase made before discounts existed.
  final String? discountCode;
  final String? discountLabel;
  final int discountAmount;

  /// The list price at the time of purchase, paise. Null (parsed as 0) on
  /// pre-discount purchases — do not present it as ₹0.
  final int listBaseAmount;

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
    required this.discountCode,
    required this.discountLabel,
    required this.discountAmount,
    required this.listBaseAmount,
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
        discountCode: _asStr(j['discount_code']),
        discountLabel: _asStr(j['discount_label']),
        discountAmount: _asInt(j['discount_amount']),
        listBaseAmount: _asInt(j['list_base_amount']),
        refund: PlanRefund.fromJson(j['refund']),
      );

  bool get isActive => status == 'active';

  /// Whether this purchase has a saving worth stating. Needs BOTH a campaign
  /// and an amount — a code with nothing behind it says nothing to the user.
  bool get boughtOnOffer =>
      (discountCode ?? '').isNotEmpty && discountAmount > 0;

  /// What to call the campaign on the saved-line: the admin's label, falling
  /// back to the raw code, which is at least identifiable.
  String get discountTitle => discountLabel ?? discountCode ?? '';

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
