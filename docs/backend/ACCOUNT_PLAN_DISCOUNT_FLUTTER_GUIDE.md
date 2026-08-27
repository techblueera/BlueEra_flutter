# Account-Plan Discounts — Flutter Integration Guide

**Audience:** the BlueEra Flutter app team (`C:\BlueEra\BlueEra_flutter`).
**Scope:** rendering and paying for admin-created discount campaigns — festive sales, flash sales, launch
offers, coupon codes — inside the existing Account Plan screens.

> **Written against the app's real conventions:** GetX + Dio (`ApiBaseHelper`) + `razorpay_flutter`
> (`RazorpayService`) + `AppStrings.*.tr`. It extends
> [ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md](ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md) — read that first.

---

## 0. TL;DR for the Flutter dev

**No new endpoints. No new screens. No breaking change.**

1. `GET /account-plan/plans` gained `campaign`, `discount_enabled`, `server_time`, and per-card
   `has_discount` + `discount` + `final_price_*`.
2. Read **`final_price_*`** for every price you display. It always exists and always equals what will be
   charged — equal to the list price when there's no discount.
3. Show a themed campaign banner, a strike-through price, a "you save" line and a countdown — **all driven by
   the payload**, nothing hard-coded.
4. Send `expected_total_amount` on `initiate` and handle one new **409 `price_changed`**.
5. Everything is DB-driven: a new festival appears with no app release.

**If you do nothing at all, the app keeps working** — it will show list prices and charge the discounted
total. Nothing crashes. But you'd lose the sale's visual pull, so do the work.

---

## Table of contents

1. [How discounts work (60 seconds)](#1-how-discounts-work-60-seconds)
2. [What changed in the API](#2-what-changed-in-the-api)
3. [Models](#3-models)
4. [Repo & controller changes](#4-repo--controller-changes)
5. [UI — banner, card, countdown, checkout](#5-ui--banner-card-countdown-checkout)
6. [Payment flow with discounts](#6-payment-flow-with-discounts)
7. [My Plans & upgrades](#7-my-plans--upgrades)
8. [i18n keys](#8-i18n-keys)
9. [Edge cases — all of them](#9-edge-cases--all-of-them)
10. [Rules that break money if ignored](#10-rules-that-break-money-if-ignored)
11. [QA checklist](#11-qa-checklist)

---

## 1. How discounts work (60 seconds)

An admin creates a **campaign** in the admin console. At checkout the server picks the single best campaign
matching this buyer and this plan, subtracts it from the pre-tax base, charges GST on what's left, and freezes
it onto the purchase.

```
   plan list price
        │
        ├─ minus DISCOUNT      ← the winning campaign
        ├─ minus CREDIT        ← upgrades only
        ▼
    taxable base ──► + 18% GST ──► TOTAL ──► Razorpay
```

**GST is charged on the discounted amount.** A ₹1,000 plan at 50% off is `₹500 + ₹90 = ₹590`.

Three things the server guarantees, so you don't have to defend against them:

- **You never compute a discount.** Every number you show comes from the payload.
- **History is frozen.** A campaign ending never changes an order, invoice or refund already made.
- **Discounts can't produce a broken price.** Never negative, never fractional paise, never an unpayable
  sub-₹1 order (a ≥99.9% discount becomes a clean free activation).

---

## 2. What changed in the API

### 2.1 `GET subscription-service/account-plan/plans`

**New at `data` level:**

```json
{
  "server_time": "2026-11-09T18:30:00.000Z",
  "discount_enabled": true,
  "campaign": {
    "code": "DIWALI2026",
    "name": "Diwali Dhamaka",
    "kind": "FESTIVE",
    "banner_text": "Diwali Dhamaka — 30% off on all plans",
    "banner_subtext": "Light up your business this festive season",
    "badge_text": "30% OFF",
    "theme": {
      "accent_color": "#C2410C", "background_color": "#FFF7ED",
      "text_color": "#7C2D12", "icon": "🪔", "image_url": null
    },
    "starts_at": "2026-11-05T00:00:00.000Z",
    "ends_at": "2026-11-12T23:59:59.000Z",
    "ends_in_seconds": 251400,
    "show_countdown": true,
    "terms_and_conditions": ["Offer valid only for the campaign period shown.", "…"]
  }
}
```

- `campaign` is `null` when nothing is running → render no banner.
- `discount_enabled: false` → the whole system is off; hide **every** discount affordance.
- `server_time` drives countdowns so a wrong device clock can't lie.

**New on every plan card:**

```json
{
  "price_base": 359900,       // ← UNCHANGED: still the LIST price
  "gst_amount": 64782,        // ← UNCHANGED: GST on the LIST price
  "price_total": 424682,      // ← UNCHANGED: LIST total

  "has_discount": true,
  "final_price_base": 251930,
  "final_gst_amount": 45347,
  "final_price_total": 297277,
  "final_price_base_inr": 2519.30,
  "final_gst_amount_inr": 453.47,
  "final_price_total_inr": 2972.77,

  "discount": {
    "code": "DIWALI2026", "name": "Diwali Dhamaka", "kind": "FESTIVE",
    "discount_type": "PERCENT", "value": 30,
    "discount_amount": 107970, "discount_amount_inr": 1079.70,
    "percent_off": 30,
    "final_price_base": 251930, "final_price_total": 297277,
    "final_price_base_inr": 2519.30, "final_gst_amount_inr": 453.47, "final_price_total_inr": 2972.77,
    "starts_at": "…", "ends_at": "…", "ends_in_seconds": 251400, "show_countdown": true,
    "badge_text": "30% OFF", "banner_text": "…", "banner_subtext": "…",
    "theme": { … },
    "terms_and_conditions": ["…"],
    "requires_coupon": false
  }
}
```

> ### The one rule that matters
>
> **`price_base` / `gst_amount` / `price_total` always stay the LIST price.** That's why the current app build
> doesn't break — it shows list price and gets charged less.
>
> **`final_price_*` always exists and always equals what will be charged.** With no discount it equals the
> list values exactly. **Read `final_price_*` everywhere and you are always correct.**

**Coupon campaigns:** pass `?coupon_code=XYZ` to unlock campaigns with `auto_apply:false`. Without the code
they're invisible.

### 2.2 `POST subscription-service/account-plan/initiate`

**New optional request fields:**

| Field | Purpose |
|---|---|
| `coupon_code` | Applies a coupon-only campaign |
| `expected_total_amount` | The total your UI displayed (**paise**). Overcharge guard — always send it |

**New response fields (200):**

```json
{ "data": {
  "order_id": "order_XXXX", "key_id": "…", "currency": "INR",
  "base_amount": 251930,
  "gst_percent": 18, "gst_amount": 45347,
  "total_amount": 297277,             // ← the ONLY amount for Razorpay

  "list_base_amount": 359900, "list_base_amount_inr": 3599,
  "discount_code": "DIWALI2026",
  "discount_label": "Diwali Dhamaka",
  "discount_amount": 107970, "discount_amount_inr": 1079.70,
  "discount_ends_at": "2026-11-12T23:59:59.000Z",

  "option_code": "SALES_6L", "option_label": "Sales 6 Lakh",
  "account_plan_id": "…", "status": "created"
} }
```

All discount fields are `null`/`0` when no campaign applied.

**New 409 — `price_changed`.** Returned only when you sent `expected_total_amount` **and the price went up**
(the campaign ended while the buyer was deciding). Paying *less* never errors.

```json
{ "success": false,
  "message": "This offer has changed since you opened the page. Please review the updated price and try again.",
  "data": { "reason": "price_changed",
            "expected_total_amount": 297277, "total_amount": 424682, "total_amount_inr": 4246.82,
            "discount_amount": 0, "discount_code": null,
            "option_code": "SALES_6L", "option_label": "Sales 6 Lakh" } }
```

**100% discount** → `total_amount: 0`, `order_id: null`, `status: "active"`, message
`This plan is fully covered by the offer — activated.` **Skip Razorpay entirely.**

**Resume changed safely:** a pending unpaid order is only resumed when its frozen total still matches today's
price. If a campaign started or ended since, you get a fresh order instead of `resumed:true`. **No app change
needed** — just use the returned `order_id`.

### 2.3 `GET /account-plan/my-plans`

Each purchase carries its frozen snapshot: `list_base_amount`, `discount_code`, `discount_label`,
`discount_kind`, `discount_type`, `discount_value`, `discount_amount`, `discount_applied_at`,
`discount_ends_at`. `list_base_amount` is `null` on purchases made before discounts existed.

### 2.4 `GET /account-plan/migration/upgrade-options`

`price_breakdown` gained `discount_inr` and `price_after_discount_inr`; each row gained `has_discount` and a
`discount` block. Order: **list → minus discount → minus credit → GST**.

### 2.5 Invoice

The GST invoice PDF now prints `Gross Value → Discount (name) → Taxable Value → GST → Total`. **Server-side —
no app change.**

---

## 3. Models

Add to `lib/features/account_plan/model/account_plan_models.dart`. Keep the app's lenient parsing.

```dart
num _asNum(dynamic v, [num d = 0]) =>
    v == null ? d : (v is num ? v : num.tryParse(v.toString()) ?? d);

int _asInt(dynamic v, [int d = 0]) =>
    v == null ? d : (v is int ? v : int.tryParse(v.toString()) ?? (v is num ? v.toInt() : d));

/// Campaign colours/icon. EVERY field is optional — a campaign created without a
/// theme must fall back to the app palette, never render null.
class DiscountTheme {
  final String? accentColor, textColor, backgroundColor, icon, imageUrl;
  const DiscountTheme({this.accentColor, this.textColor, this.backgroundColor, this.icon, this.imageUrl});

  factory DiscountTheme.fromJson(Map<String, dynamic>? j) => DiscountTheme(
        accentColor: j?['accent_color'],
        textColor: j?['text_color'],
        backgroundColor: j?['background_color'],
        icon: j?['icon'],
        imageUrl: j?['image_url'],
      );

  /// Parse "#RRGGBB" / "#AARRGGBB" safely. Returns [fallback] on anything odd —
  /// an admin typo must never crash the plans screen.
  static Color colorOf(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return fallback;
    final v = int.tryParse(h, radix: 16);
    return v == null ? fallback : Color(v);
  }

  Color accent(Color fb) => colorOf(accentColor, fb);
  Color text(Color fb) => colorOf(textColor, fb);
  Color background(Color fb) => colorOf(backgroundColor, fb);
}

/// The banner above the plan grid. null ⇒ render nothing.
class PlanCampaign {
  final String code, name, kind, bannerText, bannerSubtext, badgeText;
  final DiscountTheme theme;
  final DateTime? startsAt, endsAt;
  final int? endsInSeconds;
  final bool showCountdown;
  final List<String> termsAndConditions;

  PlanCampaign.fromJson(Map<String, dynamic> j)
      : code = j['code'] ?? '',
        name = j['name'] ?? '',
        kind = j['kind'] ?? 'PROMO',
        bannerText = j['banner_text'] ?? j['name'] ?? '',
        bannerSubtext = j['banner_subtext'] ?? '',
        badgeText = j['badge_text'] ?? '',
        theme = DiscountTheme.fromJson(j['theme'] as Map<String, dynamic>?),
        startsAt = DateTime.tryParse(j['starts_at']?.toString() ?? ''),
        endsAt = DateTime.tryParse(j['ends_at']?.toString() ?? ''),
        endsInSeconds = j['ends_in_seconds'] == null ? null : _asInt(j['ends_in_seconds']),
        showCountdown = j['show_countdown'] == true,
        termsAndConditions =
            ((j['terms_and_conditions'] as List?) ?? const []).map((e) => e.toString()).toList();

  /// Only run a timer when the server actually gave us an end.
  bool get hasCountdown => showCountdown && endsInSeconds != null && endsInSeconds! > 0;
}

/// The per-card discount block.
class CardDiscount {
  final String code, name, kind, discountType, badgeText;
  final num value, percentOff;
  final int discountAmount, finalPriceBase, finalGstAmount, finalPriceTotal;
  final num discountAmountInr, finalPriceBaseInr, finalGstAmountInr, finalPriceTotalInr;
  final DateTime? endsAt;
  final int? endsInSeconds;
  final bool showCountdown, requiresCoupon;
  final DiscountTheme theme;
  final List<String> termsAndConditions;

  CardDiscount.fromJson(Map<String, dynamic> j)
      : code = j['code'] ?? '',
        name = j['name'] ?? '',
        kind = j['kind'] ?? 'PROMO',
        discountType = j['discount_type'] ?? 'PERCENT',
        badgeText = j['badge_text'] ?? '',
        value = _asNum(j['value']),
        // The REALISED percentage. Differs from `value` when a cap applied —
        // always show this one, never `value`.
        percentOff = _asNum(j['percent_off']),
        discountAmount = _asInt(j['discount_amount']),
        discountAmountInr = _asNum(j['discount_amount_inr']),
        finalPriceBase = _asInt(j['final_price_base']),
        finalGstAmount = _asInt(j['final_gst_amount']),
        finalPriceTotal = _asInt(j['final_price_total']),
        finalPriceBaseInr = _asNum(j['final_price_base_inr']),
        finalGstAmountInr = _asNum(j['final_gst_amount_inr']),
        finalPriceTotalInr = _asNum(j['final_price_total_inr']),
        endsAt = DateTime.tryParse(j['ends_at']?.toString() ?? ''),
        endsInSeconds = j['ends_in_seconds'] == null ? null : _asInt(j['ends_in_seconds']),
        showCountdown = j['show_countdown'] == true,
        requiresCoupon = j['requires_coupon'] == true,
        theme = DiscountTheme.fromJson(j['theme'] as Map<String, dynamic>?),
        termsAndConditions =
            ((j['terms_and_conditions'] as List?) ?? const []).map((e) => e.toString()).toList();

  bool get hasCountdown => showCountdown && endsInSeconds != null && endsInSeconds! > 0;
}
```

**Extend `PlanCard`** (keep every existing field untouched):

```dart
class PlanCard {
  // … all existing fields stay exactly as they are …

  final bool hasDiscount;
  final CardDiscount? discount;
  // ALWAYS present. Equal to the list values when there is no discount, so
  // reading only these is always correct.
  final int finalPriceBase, finalGstAmount, finalPriceTotal;
  final num finalPriceBaseInr, finalGstAmountInr, finalPriceTotalInr;

  PlanCard.fromJson(Map<String, dynamic> j)
      : // … existing initialisers …
        hasDiscount = j['has_discount'] == true,
        discount = (j['discount'] is Map<String, dynamic>)
            ? CardDiscount.fromJson(j['discount'])
            : null,
        // Defensive fallbacks: an older backend (or a cached response) that has
        // no final_* fields degrades to the list price instead of showing ₹0.
        finalPriceBase   = _asInt(j['final_price_base'],   _asInt(j['price_base'])),
        finalGstAmount   = _asInt(j['final_gst_amount'],   _asInt(j['gst_amount'])),
        finalPriceTotal  = _asInt(j['final_price_total'],  _asInt(j['price_total'])),
        finalPriceBaseInr  = _asNum(j['final_price_base_inr'],  _asNum(j['price_base_inr'])),
        finalGstAmountInr  = _asNum(j['final_gst_amount_inr'],  _asNum(j['gst_amount_inr'])),
        finalPriceTotalInr = _asNum(j['final_price_total_inr'], _asNum(j['price_total_inr']));

  /// True only when there is a real saving to display.
  bool get showsOffer => hasDiscount && discount != null && discount!.discountAmount > 0;
}
```

**Extend `PlanCatalog`:**

```dart
class PlanCatalog {
  // … existing fields …
  final bool discountEnabled;
  final PlanCampaign? campaign;
  final DateTime? serverTime;

  PlanCatalog.fromJson(Map<String, dynamic> j)
      : // … existing initialisers …
        // Default TRUE so an older backend without the flag behaves normally.
        discountEnabled = j['discount_enabled'] != false,
        campaign = (j['campaign'] is Map<String, dynamic>)
            ? PlanCampaign.fromJson(j['campaign'])
            : null,
        serverTime = DateTime.tryParse(j['server_time']?.toString() ?? '');

  /// The single gate for every discount affordance on this screen.
  bool get showCampaign => discountEnabled && campaign != null;
}
```

**Extend `InitiatePlanResponse`:**

```dart
class InitiatePlanResponse {
  // … existing fields …
  final int listBaseAmount, discountAmount;
  final num discountAmountInr;
  final String? discountCode, discountLabel;
  final DateTime? discountEndsAt;

  InitiatePlanResponse.fromJson(Map<String, dynamic> j)
      : // … existing initialisers …
        listBaseAmount = _asInt(j['list_base_amount'], _asInt(j['base_amount'])),
        discountAmount = _asInt(j['discount_amount']),
        discountAmountInr = _asNum(j['discount_amount_inr']),
        discountCode = j['discount_code'],
        discountLabel = j['discount_label'],
        discountEndsAt = DateTime.tryParse(j['discount_ends_at']?.toString() ?? '');

  bool get hasDiscount => (discountCode ?? '').isNotEmpty && discountAmount > 0;
  /// A campaign covered the whole price — activate without Razorpay.
  bool get isFreeAfterDiscount => totalAmount == 0;
}
```

---

## 4. Repo & controller changes

### 4.1 Repo

```dart
class AccountPlanRepo extends BaseService {
  Future<ResponseModel> getPlans({String? tagId, bool? hasGst, String? couponCode}) {
    final q = <String, dynamic>{};
    if (tagId != null && tagId.isNotEmpty) q['tag_id'] = tagId;
    if (hasGst != null) q['has_gst'] = hasGst.toString();
    // Only unlocks campaigns the admin marked "coupon only".
    if (couponCode != null && couponCode.isNotEmpty) q['coupon_code'] = couponCode;
    return ApiBaseHelper().getHTTP(accountPlanPlans, params: q, showProgress: false);
  }

  Future<ResponseModel> initiate({
    required String optionCode,
    String? tagId,
    String? buyerGstin,
    String? buyerState,
    String? couponCode,
    int? expectedTotalAmount,   // paise — the total the UI displayed
  }) =>
      ApiBaseHelper().postHTTP(accountPlanInitiate, params: {
        'option_code': optionCode,
        if (tagId != null) 'tag_id': tagId,
        if (buyerGstin != null) 'buyer_gstin': buyerGstin,
        if (buyerState != null) 'buyer_state': buyerState,
        if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
        // ALWAYS send this — it is the overcharge guard.
        if (expectedTotalAmount != null) 'expected_total_amount': expectedTotalAmount,
      }, showProgress: false);
}
```

### 4.2 Controller

```dart
class AccountPlanController extends GetxController {
  // … existing fields …

  final couponCode = ''.obs;
  /// Set when the server rejects a stale price (409). Drives the re-confirm sheet.
  final Rxn<Map<String, dynamic>> priceChanged = Rxn<Map<String, dynamic>>();

  Future<void> fetchPlans() async {
    plansStatus.value = Status.LOADING;
    final res = await _repo.getPlans(
      tagId: tagId, hasGst: hasGst,
      couponCode: couponCode.value.isEmpty ? null : couponCode.value,
    );
    final data = res.response?.data?['data'];
    if (res.statusCode == 200 && data is Map<String, dynamic>) {
      catalog.value = PlanCatalog.fromJson(data);
      plansStatus.value = Status.COMPLETE;
    } else {
      plansStatus.value = Status.ERROR;
    }
  }

  /// Called when a countdown hits zero — the offer is over, get honest prices.
  Future<void> onOfferExpired() async {
    if (isProcessing.value) return;   // never yank prices mid-checkout
    await fetchPlans();
  }

  Future<void> buyPlan(PlanCard card, {String? gstin}) async {
    if (isProcessing.value) return;
    if (card.isFree) { commonSnackBar(message: AppStrings.planAlreadyFree.tr); return; }

    isProcessing.value = true;
    purchasingCode.value = card.optionCode;
    priceChanged.value = null;

    final initRes = await _repo.initiate(
      optionCode: card.optionCode,
      tagId: tagId,
      buyerGstin: gstin,
      buyerState: buyerState,
      couponCode: couponCode.value.isEmpty ? null : couponCode.value,
      // What the card promised. If the server now wants MORE, it 409s.
      expectedTotalAmount: card.finalPriceTotal,
    );

    // ── 409: the offer changed while the user was deciding ──
    if (initRes.statusCode == 409) {
      final d = initRes.response?.data?['data'];
      _reset();
      if (d is Map<String, dynamic> && d['reason'] == 'price_changed') {
        priceChanged.value = d;            // show the re-confirm sheet
        await fetchPlans();                // refresh the cards
        return;                            // NEVER auto-retry
      }
      commonSnackBar(message: initRes.message ?? AppStrings.somethingWentWrong.tr);
      return;
    }

    final data = initRes.response?.data?['data'];
    if (initRes.statusCode != 200 || data is! Map<String, dynamic>) {
      _reset();
      commonSnackBar(message: initRes.message ?? AppStrings.couldNotStartPayment.tr);
      return;
    }

    final order = InitiatePlanResponse.fromJson(data);

    // ── A campaign covered the entire price: no Razorpay at all ──
    if (order.isFreeAfterDiscount || (order.orderId).isEmpty) {
      _reset();
      commonSnackBar(message: AppStrings.planActivatedFreeOffer.tr);
      await fetchPlans();
      return;
    }

    _razorpay.openCheckout(
      razorpayKeyId: order.keyId,
      name: AppStrings.appName,
      description: card.label,
      amount: order.totalAmount.toDouble(),   // PAISE, discount + GST applied server-side
      contact: buyerPhone, email: buyerEmail,
      subscriptionId: '',
      orderId: order.orderId, currency: order.currency,
      onPaymentSuccess: _onSuccess,
      onPaymentError: _onError,
    );
  }
}
```

---

## 5. UI — banner, card, countdown, checkout

### 5.1 Countdown widget (anchored to server time)

Device clocks are wrong often enough to matter, so the server sends **`ends_in_seconds`** and you tick down
locally instead of comparing against `ends_at`.

```dart
class OfferCountdown extends StatefulWidget {
  final int endsInSeconds;          // from the server
  final VoidCallback? onExpired;
  final Color color;
  const OfferCountdown({super.key, required this.endsInSeconds, this.onExpired, required this.color});
  @override State<OfferCountdown> createState() => _OfferCountdownState();
}

class _OfferCountdownState extends State<OfferCountdown> {
  late int _left;
  Timer? _timer;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant OfferCountdown old) {
    super.didUpdateWidget(old);
    // A refetch delivers a fresh server value — restart from it.
    if (old.endsInSeconds != widget.endsInSeconds) _start();
  }

  void _start() {
    _timer?.cancel();
    _fired = false;
    _left = widget.endsInSeconds;
    if (_left <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left = _left > 0 ? _left - 1 : 0);
      if (_left == 0 && !_fired) {
        _fired = true;
        _timer?.cancel();
        widget.onExpired?.call();
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }   // never leak a timer

  String get _label {
    final d = _left ~/ 86400, h = (_left % 86400) ~/ 3600, m = (_left % 3600) ~/ 60, s = _left % 60;
    if (d > 0) return '${d}d ${h}h ${m}m';
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    if (_left <= 0) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.timer_outlined, size: 14, color: widget.color),
      SizedBox(width: SizeConfig.size4),
      CustomText('${AppStrings.offerEndsIn.tr} $_label',
          fontSize: SizeConfig.size11, fontWeight: FontWeight.w600, color: widget.color),
    ]);
  }
}
```

> **Always `_timer?.cancel()` in `dispose()`.** A festival screen left open with a leaked 1-second timer is a
> battery and rebuild problem.

### 5.2 Campaign banner

```dart
class CampaignBanner extends StatelessWidget {
  final PlanCampaign campaign;
  final VoidCallback onExpired;
  const CampaignBanner({super.key, required this.campaign, required this.onExpired});

  @override
  Widget build(BuildContext context) {
    // Every theme field is optional — always pass an app-palette fallback.
    final accent = campaign.theme.accent(AppColors.primaryColor);
    final bg     = campaign.theme.background(AppColors.primaryColor.withOpacity(0.08));
    final fg     = campaign.theme.text(AppColors.mainTextColor);

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(SizeConfig.size12),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Row(children: [
        // Icon is an emoji string from the DB — render as text, not an asset.
        CustomText(campaign.theme.icon ?? '🏷️', fontSize: SizeConfig.size22),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CustomText(campaign.bannerText,
                fontSize: SizeConfig.size14, fontWeight: FontWeight.w700, color: fg),
            if (campaign.bannerSubtext.isNotEmpty) ...[
              SizedBox(height: SizeConfig.size2),
              CustomText(campaign.bannerSubtext, fontSize: SizeConfig.size11, color: fg.withOpacity(0.75)),
            ],
            if (campaign.hasCountdown) ...[
              SizedBox(height: SizeConfig.size6),
              OfferCountdown(
                endsInSeconds: campaign.endsInSeconds!,
                onExpired: onExpired,
                color: accent,
              ),
            ],
          ]),
        ),
        if (campaign.termsAndConditions.isNotEmpty)
          TextButton(
            onPressed: () => _showTermsList(context, campaign.termsAndConditions, campaign.name),
            child: CustomText('*${AppStrings.termsAndConditions.tr}',
                fontSize: SizeConfig.size10, color: accent),
          ),
      ]),
    );
  }
}
```

Wire it in the screen:

```dart
final cat = _ctrl.catalog.value!;
return ListView(
  padding: EdgeInsets.all(SizeConfig.size16),
  children: [
    // Single gate: system enabled AND a campaign is running.
    if (cat.showCampaign)
      CampaignBanner(campaign: cat.campaign!, onExpired: _ctrl.onOfferExpired),
    CustomText(_archetypeHeadline(cat.archetype).tr, /* … */),
    SizedBox(height: SizeConfig.size12),
    for (final p in cat.plans)
      _PlanCardTile(card: p, gstPercent: cat.gstPercent, /* … */),
  ],
);
```

### 5.3 Discounted price tag

Replaces `_PriceTag`. **One widget, both states.**

```dart
class _PriceTag extends StatelessWidget {
  final PlanCard card;
  const _PriceTag({required this.card});

  String _r(num v) => v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    if (card.isFree) {
      return CustomText(AppStrings.free.tr,
          fontWeight: FontWeight.w700, color: AppColors.primaryColor);
    }

    final offer = card.showsOffer ? card.discount! : null;
    final accent = offer?.theme.accent(AppColors.primaryColor) ?? AppColors.primaryColor;

    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      // Struck-through LIST price, only when there is a real saving.
      if (offer != null)
        CustomText('${AppConstants.rupeeSymbol}${_r(card.priceBaseInr)}',
            fontSize: SizeConfig.size12,
            color: AppColors.secondaryTextColor,
            textDecoration: TextDecoration.lineThrough),

      // The live price — ALWAYS final_*, correct with or without a discount.
      CustomText('${AppConstants.rupeeSymbol}${_r(card.finalPriceBaseInr)}',
          fontSize: SizeConfig.size18, fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor),

      CustomText(
        '+ ${AppConstants.rupeeSymbol}${_r(card.finalGstAmountInr)} ${AppStrings.gstLabel.tr} (${card.gstPercent}%)',
        fontSize: SizeConfig.size10, color: AppColors.secondaryTextColor,
      ),

      if (offer != null) ...[
        SizedBox(height: SizeConfig.size2),
        CustomText(
          '${AppStrings.youSave.tr} ${AppConstants.rupeeSymbol}${_r(offer.discountAmountInr)}',
          fontSize: SizeConfig.size11, fontWeight: FontWeight.w700, color: accent,
        ),
      ],
    ]);
  }
}
```

### 5.4 Offer ribbon on the card

```dart
if (card.showsOffer)
  Container(
    padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8, vertical: SizeConfig.size3),
    decoration: BoxDecoration(
      color: card.discount!.theme.accent(AppColors.primaryColor),
      borderRadius: BorderRadius.circular(SizeConfig.size6),
    ),
    child: CustomText(
      // badge_text is admin copy; fall back to the REALISED percentage
      // (percent_off, not value — they differ when a cap applies).
      card.discount!.badgeText.isNotEmpty
          ? card.discount!.badgeText
          : '${card.discount!.percentOff.toStringAsFixed(0)}% ${AppStrings.off.tr}',
      fontSize: SizeConfig.size10, fontWeight: FontWeight.w700, color: AppColors.white,
    ),
  ),
```

Card layout:

```
┌──────────────────────────┐
│ 🪔 30% OFF   ★ POPULAR   │
│ Sales 15 Lakh            │
│ valid up to ₹15L sales   │
│ [15 Lakh sales]          │
│                          │
│              ₹̶6̶,̶9̶9̶9̶       │
│              ₹4,899      │
│              + ₹881.82 GST│
│              You save ₹2,100│
│                          │
│ ⏱ Offer ends in 2d 21h   │
│ ✓ Shop listed            │
│ ✓ Get orders             │
│ [    Buy Now         ]   │
│ *T&C        *Offer T&C   │
└──────────────────────────┘
```

Show a **second** T&C link when `card.discount!.termsAndConditions.isNotEmpty` — the campaign's own terms are
separate from the plan's.

### 5.5 Checkout confirmation sheet

Show it **after** `initiate` returns, built from `InitiatePlanResponse` — that's the authoritative price.

```
┌───────────────────────────────────────────┐
│  Confirm your plan                        │
│  Sales 15 Lakh                            │
│  ───────────────────────────────────────  │
│  Plan price                    ₹6,999.00  │
│  🪔 Diwali Dhamaka            -₹2,100.00  │
│  Price after offer             ₹4,899.00  │
│  GST (18%)                       ₹881.82  │
│  ═════════════════════════════════════    │
│  Total payable                 ₹5,780.82  │
│                                           │
│  [        Pay ₹5,780.82         ]         │
└───────────────────────────────────────────┘
```

Show the discount rows only when `order.hasDiscount`.

### 5.6 "Price changed" re-confirm sheet (409)

```dart
Obx(() {
  final pc = _ctrl.priceChanged.value;
  if (pc == null) return const SizedBox.shrink();
  final newTotal = (pc['total_amount_inr'] as num?) ?? 0;
  return AlertDialog(
    title: CustomText(AppStrings.offerChangedTitle.tr),
    content: CustomText(
      '${AppStrings.offerChangedBody.tr}\n\n'
      '${AppStrings.newTotal.tr}: ${AppConstants.rupeeSymbol}$newTotal',
    ),
    actions: [
      TextButton(
        onPressed: () => _ctrl.priceChanged.value = null,
        child: CustomText(AppStrings.cancel.tr),
      ),
      TextButton(
        onPressed: () {
          _ctrl.priceChanged.value = null;
          // Re-buy from the REFRESHED card — never replay the old amount.
          final fresh = _ctrl.catalog.value?.plans
              .firstWhereOrNull((p) => p.optionCode == pc['option_code']);
          if (fresh != null) _ctrl.buyPlan(fresh);
        },
        child: CustomText(AppStrings.continueAtNewPrice.tr),
      ),
    ],
  );
});
```

### 5.7 Coupon field (optional)

Only if you run coupon campaigns. A text field → `couponCode.value = code` → `fetchPlans()`. If no card comes
back with a matching `discount.code`, show *"This code isn't valid for your plans."* **Never write your own
validity rules** — the server decides.

---

## 6. Payment flow with discounts

```
Plans screen  →  GET /plans (+ coupon_code?)
     │              renders banner + discounted cards from the payload
     │ tap Buy Now
     ▼
POST /initiate { option_code, …, expected_total_amount: card.finalPriceTotal }
     │
     ├── 200, total_amount == 0  ──► activated free, NO Razorpay → refresh
     ├── 200, order_id           ──► confirmation sheet → RazorpayService.openCheckout(order.totalAmount)
     │                                  ├─ success  → verify-payment → refresh
     │                                  ├─ dismiss  → "cancelled" (order stays resumable)
     │                                  └─ failed   → retry re-calls /initiate
     ├── 409 price_changed       ──► refresh catalog + re-confirm sheet (NEVER auto-retry)
     └── 400                     ──► show `message` (GSTIN / already active / downgrade)
```

**Unchanged:** Razorpay setup, verification, the webhook as source of truth, `RazorpayService`, disposal. The
only difference is that `total_amount` is now discount-inclusive — and you were already required to send the
server's amount, never a computed one.

---

## 7. My Plans & upgrades

### 7.1 Permanent savings line

```dart
// Each my-plans item now carries its FROZEN snapshot.
final code   = plan['discount_code'] as String?;
final label  = plan['discount_label'] as String?;
final saved  = _asInt(plan['discount_amount']);

if (code != null && saved > 0)
  CustomText(
    '${AppStrings.boughtInOffer.tr} ${label ?? code} — '
    '${AppStrings.youSaved.tr} ${AppConstants.rupeeSymbol}${(saved / 100).toStringAsFixed(2)}',
    fontSize: SizeConfig.size11, color: AppColors.primaryColor,
  ),
```

This stays true forever — the campaign ending never changes it.

### 7.2 Upgrades

`price_breakdown` gained two rows. Render the receipt in this exact order:

```
Plan price                ₹700
Diwali Dhamaka           -₹100     ← discount_inr, only when > 0
Price after offer         ₹600     ← price_after_discount_inr
Already paid             -₹150     ← credit_applied_inr
Taxable                   ₹450
GST (18%)                  ₹81
────────────────────────────────
You pay                   ₹531     ← pay_total_inr
```

`active` also gained `plan_paid_inr` (what they paid) beside `plan_value_inr` (the tier's list value). For a
discounted purchase these differ — show `plan_value_inr` as the tier and `plan_paid_inr` in a receipt context.

---

## 8. i18n keys

Add to `lib/core/constants/app_strings.dart`, `assets/translations/en.json` and the backend language store:

```
offerEndsIn            "Offer ends in"
youSave                "You save"
youSaved               "you saved"
off                    "OFF"
gstLabel               "GST"
boughtInOffer          "Bought in"
planActivatedFreeOffer "Your plan is active — the offer covered the full price."
offerChangedTitle      "Offer changed"
offerChangedBody       "This offer changed while you were on this page. Please review the updated price."
newTotal               "New total"
continueAtNewPrice     "Continue at new price"
priceAfterOffer        "Price after offer"
totalPayable           "Total payable"
offerTerms             "Offer Terms"
couponHint             "Have a coupon code?"
couponInvalid          "This code isn't valid for your plans."
somethingWentWrong     "Something went wrong. Please try again."
```

**Never translate `banner_text`, `badge_text`, `name` or `terms_and_conditions`** — those are admin-authored
content, rendered verbatim.

---

## 9. Edge cases — all of them

### Rendering

| Case | Payload | App must |
|---|---|---|
| Discounts globally off | `discount_enabled: false` | Hide **every** discount affordance; plain list prices |
| No campaign running | `campaign: null`, cards have `has_discount:false` | Render the old card exactly |
| Campaign live, some cards out of scope | Banner present, only some cards discounted | **Show the banner anyway.** Per-card is `has_discount` |
| Campaign with no theme | `theme` all-null | Fall back to `AppColors` — never crash |
| Malformed colour (`"red"`, `"#XYZ"`) | — | `DiscountTheme.colorOf` returns the fallback |
| No `badge_text` | `""` | Fall back to `percent_off` + "OFF" |
| Cap applied (30% but max ₹1,000) | `value:30`, `percent_off:28` | **Show `percent_off`**, never `value` |
| `ends_at: null` (open-ended) | `ends_in_seconds: null`, `show_countdown:false` | No timer |
| `show_countdown: false` with an end date | — | No timer; the offer still applies |
| Countdown hits 0 with screen open | — | Stop timer, refetch, drop the banner |
| Countdown hits 0 mid-checkout | — | **Don't refetch** while `isProcessing` — the 409 guard handles it |
| Wrong device clock | `ends_in_seconds` + `server_time` | Tick down from the server value; never diff against `ends_at` |
| Free card during a sale | `is_free:true`, no discount | Show "Free", no ribbon |
| Older backend without the new fields | `final_*` absent | Model fallbacks use the list price |

### Payment

| Case | Response | App must |
|---|---|---|
| Normal discounted buy | 200 + `order_id` | Charge `total_amount` |
| 100% discount | `total_amount:0`, `order_id:null`, `status:"active"` | **Skip Razorpay**, refresh, success message |
| ≥99.9% leaving < ₹1 | Same as 100% (Razorpay minimum is ₹1) | Same |
| Offer ended mid-checkout | **409 `price_changed`** | Refresh + re-confirm. **Never auto-retry** |
| Offer started mid-checkout | 200, cheaper | Proceed; show the receipt from `initiate` |
| Pending order + campaign changed | Fresh `order_id`, no `resumed:true` | Nothing — just use it |
| Pending order, price unchanged | `resumed:true` | Existing behaviour |
| `max_per_user` exhausted | No discount for this buyer | List price; no error |
| `max_redemptions` exhausted | Campaign disappears | Refetch shows list price |
| Coupon code wrong | No campaign returned | "This code isn't valid for your plans." |
| GST-track plan + discount | GSTIN still required first | Existing GSTIN dialog, unchanged |

### Plan cycle

| Case | Behaviour |
|---|---|
| ₹700 plan bought at 50% off, tries a ₹500 plan | **Blocked** — tier is the list price. Show the 400 `message` |
| Upgrading from a discounted plan | Only tiers above ₹700 **list** are offered |
| Refund on a discounted plan | Refunds `base_amount` — what they paid, ex-GST |
| Invoice for a discounted plan | Shows Gross → Discount → Taxable → GST → Total (server-rendered) |
| Campaign ends after purchase | Purchase, invoice and refund **unchanged** — frozen |

---

## 10. Rules that break money if ignored

1. **Never compute a discount in Dart.** No `price * (1 - value/100)`. Read `final_price_*`. Caps, clamps,
   rounding and the sub-₹1 rule all live server-side, and `value` is not the realised percentage.
2. **Charge `order.totalAmount` from `initiate`.** Never a card value, never a computed total.
3. **Always send `expected_total_amount`.** Without it, an expired offer silently charges the buyer more.
4. **Never auto-retry a 409 `price_changed`.** The buyer must see and accept the new price.
5. **`total_amount == 0` means skip Razorpay.** Opening checkout with 0 fails at the gateway.
6. **Show `percent_off`, not `value`.** A capped campaign realises less than its headline percentage.
7. **Every `theme` field can be null.** Always pass a fallback colour.
8. **Never hard-code a campaign code, name, colour, festival or copy.** `if (code == "DIWALI2026")` is the
   bug. New festivals must need no app release.
9. **Cancel countdown timers in `dispose()`.**
10. **`price_base` is the LIST price; `final_price_base` is what's charged.** Using `price_base` as the live
    price shows the buyer the wrong number during every sale.

---

## 11. QA checklist

**No campaign / system off**
- [ ] `discount_enabled:false` → no banner, no ribbons, no strike-through anywhere
- [ ] Prices and the whole buy flow identical to the current build
- [ ] Existing app build (before this work) still buys correctly during a live sale

**Catalog**
- [ ] Banner renders with the campaign's colours, icon, text, subtext
- [ ] Countdown ticks and matches the server's `ends_in_seconds`
- [ ] Countdown correct with the device clock set a day off
- [ ] Ribbon shows `badge_text`, or `percent_off` + "OFF" when empty
- [ ] Strike-through list price + bold final price + "You save"
- [ ] GST line uses `final_gst_amount_inr`
- [ ] Capped campaign shows the realised `percent_off`
- [ ] Out-of-scope cards in the same catalog stay plain, banner still shows
- [ ] Free cards show "Free", never a discount
- [ ] Campaign with null theme renders in app colours
- [ ] Offer T&C sheet renders the campaign's terms verbatim
- [ ] Countdown hitting 0 refetches and clears the offer

**Buy**
- [ ] Confirmation sheet shows price → offer → after-offer → GST → total
- [ ] Razorpay is charged exactly `order.totalAmount`
- [ ] `expected_total_amount` sent on every initiate
- [ ] 409 `price_changed` → re-confirm sheet, catalog refreshed, no auto-retry
- [ ] 100% discount → activates with no Razorpay
- [ ] Dismissing checkout leaves the order resumable
- [ ] GST-track plan still demands a GSTIN before the discount is applied
- [ ] Buying a cheaper plan while holding a discounted higher tier → blocked with the server message

**After**
- [ ] My Plans shows "Bought in {campaign} — you saved ₹X"
- [ ] The line survives the campaign ending
- [ ] Invoice PDF shows the discount deduction
- [ ] Refund shows the discounted base, not the list price
- [ ] Upgrade list starts above the held plan's **list** tier
- [ ] Upgrade receipt shows the discount row when one applies

**Robustness**
- [ ] No timer leaks (open/close the plans screen 20×)
- [ ] Malformed theme colours don't crash
- [ ] Missing `final_*` (older backend) falls back to list prices
- [ ] Airplane mode mid-countdown doesn't crash; refetch recovers
