# Account Plans — Flutter Integration Guide (dynamic price cards → Razorpay → GST invoice)

This guide is written **against the real BlueEra Flutter app** (`C:\BlueEra\BlueEra_flutter`) and its
conventions: **GetX + Dio (`ApiBaseHelper`) + `razorpay_flutter` (`RazorpayService`) + `flutter_secure_storage` + `AppStrings.*.tr` i18n**.
It mirrors the existing **Security Deposit** flow (`lib/features/contribution/`), which is the closest working precedent.

> **The screen is 100% dynamic — one screen for all 138 account types.** The app never hard-codes a category or
> profession. It sends the user's token (→ `account_type`) + their `tag_id`, and renders whatever the backend
> returns: the header (from `archetype`), each plan card, its **`features`** bullets, its **`terms_and_conditions`**,
> the price + GST, and the entitlement chips (radius / job-types / tier). Everything — labels, features, T&C, prices —
> is **DB-driven and editable backend-side without an app release**. The same screen serves shops (radius), drivers
> (job-type), skilled workers (service area), professionals (listing), health/hotel/education (booking), and social
> profiles (free). Add a new category tomorrow → it just works, no app change.

---

## 0. Status — what's live vs contract

| Endpoint | State |
|---|---|
| `GET /account-plan/plans` | ✅ **LIVE** (Increment 1) |
| `GET /account-plan/my-plans` | ✅ **LIVE** |
| `GET /account-plan/sales/usage` | ✅ **LIVE** — A1 sales-shops only (see §2.2.1) |
| `POST /account-plan/initiate` | ✅ **LIVE** (Increment 2) |
| `POST /account-plan/verify-payment` | ✅ **LIVE** (Increment 2) |
| `POST /account-plan/webhook/razorpay` | ✅ **LIVE** — backend-only (source of truth) |
| `GET /account-plan/invoices`, `GET /account-plan/{id}/invoice`, `GET /account-plan/invoice/d/:token` | ✅ **LIVE** (Increment 3) |

The full **buy → pay → activate → GST invoice (chat + email)** path is live and mirrors the Security-Deposit flow the
app already talks to (idempotent atomic activation, HMAC webhook + amount/currency check, client-verify fallback,
auto-delivered GST tax invoice). Nothing in the payment/invoice path is pending.

---

## 1. Config (nothing new — already in the app)

- **Base URL** — global `baseUrl` from `lib/environment_config.dart` (set by `projectKeys()` from `Env.prod/devBaseUrl`).
  Every account-plan path is `subscription-service/account-plan/...` — the same gateway prefix the existing
  `securityDeposit*` constants use (`lib/core/api/apiService/subscription_service_api.dart`).
- **Razorpay key** — global `razorpayKey` (dev key forced in `kDebugMode`). The backend also returns `key_id` on
  `initiate`; prefer that.
- **Auth token** — `authTokenGlobal` (mirror of secure-storage `authToken`) is attached as `Bearer` by the Dio
  interceptor in `lib/core/api/apiService/api_base_helper.dart`. You do nothing — just call `ApiBaseHelper().getHTTP/postHTTP`.
- **Account type** is inside the JWT; the backend reads it from the token. The app only needs to pass the user's
  **`tag_id`** (category/profession) and, for a business, **`has_gst`** — both already known on the profile.

---

## 2. API reference

### 2.1 `GET subscription-service/account-plan/plans` — dynamic price cards ✅ LIVE
Query (all optional): `tag_id`, `has_gst=true|false`, `account_type`.
- **INDIVIDUAL**: `tag_id` optional (backend falls back to the profile's profession). Sending it is faster/safer.
- **BUSINESS**: **send `tag_id`** (the business category tag). `has_gst` is accepted but no longer filters the catalog — **every business now sees the full radius ladder (1/3/6/10/25 km)**. The 1 km & 3 km tiers are `gst_track: "NON_GST"` (buyable without GST); the larger tiers are `gst_track: "GST"` and require a valid GSTIN **at payment** (see 2.3). Show a small "GST" badge on `gst_track === "GST"` cards.

**200 response**
```json
{
  "success": true,
  "message": "Fetched successfully",
  "data": {
    "account_type": "BUSINESS",
    "tag_id": "GENERAL_STORE",
    "group": "Grocery & Stationary",
    "archetype": "A1_SALES_SHOP",
    "vehicle_class": null,
    "earns_in_app": true,
    "has_gst": false,
    "currency": "INR",
    "gst_percent": 18,
    "plans": [
      {
        "option_code": "SALES_6L",
        "label": "Sales 6 Lakh",
        "sublabel": "valid up to ₹6 Lakh sales",
        "archetype": "A1_SALES_SHOP",
        "vehicle_class": null,
        "gst_track": "NON_GST",
        "billing": "lifetime",
        "popular": false,
        "validity_days": null,
        "attributes": { "radius_km": null, "job_types": null, "tier": null, "sale_limit": 600000 },
        "sale_limit": 600000,
        "price_base": 359900,
        "gst_percent": 18,
        "gst_amount": 64782,
        "price_total": 424682,
        "hsn_sac_code": "998599",
        "price_base_inr": 3599,
        "gst_amount_inr": 647.82,
        "price_total_inr": 4246.82,
        "is_free": false,
        "features": ["Shop listed on BlueEra", "Receive customer orders", "Sell up to ₹6 Lakh", "Business visibility"],
        "terms_and_conditions": [
          "This plan is valid until your total sales reach the plan's sales limit.",
          "When your sales cross the limit, the plan automatically deactivates — upgrade to a higher plan to continue selling.",
          "Fees are non-refundable.",
          "Available without GST registration.",
          "Sales are counted from the date the plan is activated."
        ]
      }
    ]
  }
}
```
All money fields are **paise**; `*_inr` are the rupee convenience values.

**Card price display — show price + GST, not the total.** On the card, show the base price with the GST called out
separately, e.g. **“₹150 + ₹27 GST (18%)”** using `price_base_inr` + `gst_amount_inr` (+ `gst_percent`). Do **not**
headline `price_total_inr` on the card. The **total (`price_total` / `price_total_inr` = base + GST) is only shown at
payment time and is what actually gets charged** — computed entirely by the backend; the app never re-computes it.

**`popular`** — when `true`, render a **“Popular” ribbon/badge** on that card (one recommended pick per group, e.g. the
Sales 15 Lakh plan). Purely cosmetic; it does not change pricing or the purchase flow.

**`features`** (the bullet points the card shows) and
**`terms_and_conditions`** are **stored in the DB per plan and returned here** — the app renders them verbatim and
never hard-codes them, so they differ by plan/archetype and can be edited backend-side without an app update.

Archetype → what the card carries:
| archetype | key attribute | example labels |
|---|---|---|
| `A1_SALES_SHOP` | `attributes.sale_limit` (RUPEES cap) | "Valid up to ₹6 Lakh sales" |
| `A6_WIDE_REACH` | `attributes.radius_km` (`-1` = all-India) | "All India" |
| `A2_GIG_CALLS` | `attributes.job_types` (`["passenger","parcel"]`) + `vehicle_class` | "Passenger + Parcel" |
| `A3_LOCAL_SERVICE` | `attributes.radius_km` | "Local (5 km)" |
| `A4_LEAD_PRO` / `A5_BOOKING` | `attributes.tier` (`BASIC`/`PRO`) | "Basic", "Pro" |
| `A7_MANUFACTURING` | `attributes.sale_promise` (display string) | "₹30–40 Lakh orders" |
| `A0_SOCIAL_FREE` | `is_free` true for `SOC_FREE` | "Free", "Verified Badge" |

> **A1 shops are now SALES-BASED, not radius-based.** The old radius ladder
> (1/3/6/10/25 km) is retired. A shop buys a **sales subscription** — 5 tiers
> (Sales 6 Lakh ₹3,599 → Sales 1 Cr ₹19,999). The plan stays active until the
> shop's **cumulative sales cross `sale_limit`**, then it **auto-deactivates** and
> the shop must upgrade. Render the sales cap chip from `attributes.sale_limit`
> (e.g. `₹${sale_limit/100000} Lakh`), not a km radius. Use **`GET
> account-plan/sales/usage`** to show a "₹X of ₹Y sales used" progress bar on the
> shop's plan screen and warn as it approaches 100%. `attributes.radius_km` is
> null for these cards.

### 2.2 `GET subscription-service/account-plan/my-plans` — the user's purchases ✅ LIVE
Optional `?status=active` / `?archetype=`. Returns `{ success, count, data: [ UserAccountPlan ] }` where each item has
`option_code, option_label, archetype, radius_km, job_types, tier, total_amount, status, activated_at, ...`.

**How the app knows a plan is active:** an item's `status == "active"`. The app
already centralises this in `AccountPlanEntitlement` (reads `my-plans?status=active`,
exposes `hasActivePlan`). Nothing about that changes.

### 2.2.1 `GET subscription-service/account-plan/sales/usage` — A1 sales-shop usage ✅ LIVE
**⚠️ Call this ONLY for A1 sales-shops with an active plan — never for everyone.**
It is meaningless (and returns `has_sales_plan:false`) for every other archetype
(gig drivers, services, lead/booking, manufacturing, free, radius wide-reach). Do
NOT add it to the generic plan/home load.

**Gate (both conditions must hold before you call it):**
1. The account has an **active** plan — `AccountPlanEntitlement.hasActivePlan == true`
   (i.e. a `my-plans` item with `status == "active"`).
2. That active plan's **`archetype == "A1_SALES_SHOP"`**.

In code terms — from the already-fetched `my-plans` list, find the active plan and
check its archetype; only then hit `sales/usage`:
```dart
final active = myPlans.firstWhereOrNull((p) => p.status == 'active');
final isSalesShop = active?.archetype == 'A1_SALES_SHOP'; // add this const alongside A1_RADIUS_SHOP
if (isSalesShop) {
  // call sales/usage; render the usage bar. Otherwise skip entirely.
}
```

**Response** (no request body; auth = the user's JWT):
```json
{
  "success": true,
  "data": {
    "has_sales_plan": true,
    "option_label": "Sales 6 Lakh",
    "sale_limit_inr": 600000,
    "sales_accrued_inr": 240000,
    "sales_remaining_inr": 360000,
    "percent_used": 40
  }
}
```
- `has_sales_plan: false` ⇒ no active sales plan → show nothing (or the buy/upgrade
  CTA the screen already has). Treat a non-200 / error the same way (fail-quiet).
- All amounts are **RUPEES**. `percent_used` is 0–100 (server-clamped).
- Render a "**₹{sales_accrued_inr} of ₹{sale_limit_inr} sales used**" progress bar
  using `percent_used`; warn as it nears 100% ("plan pauses at the limit — upgrade
  to keep receiving orders"). When the plan auto-deactivates on the server, the next
  `my-plans` read returns it as no-longer-active, so `hasActivePlan` flips false and
  your existing go-live/active gates already react — no new UI wiring needed.

> This is the ONLY new API in the sales-shop change. Everything else on the
> contribution screen (menu → Contribution) is unchanged — same cards, same buy
> flow, same go-live gate. You are only *adding* an A1-conditional usage bar, not
> changing any existing UI.

### 2.2.2 Refund — request a refund on a paid plan ✅ LIVE
Plans are now **refundable** (not one-time/lifetime): a paid plan's fee (GST excluded)
can be refunded **only after 6 months, for a 10-day window**, and only if the user
earned/sold **less than the plan price**. The user *requests*; an admin approves and
the base amount is auto-refunded to the original payment method.

**Where the data comes from:** every item in `GET /account-plan/my-plans` now
carries a **`refund`** object — render the button straight from it, don't compute
dates yourself:
```json
"refund": {
  "refund_system_enabled": true,       // false ⇒ hide the button entirely
  "refundable": true,                   // paid plan (free plans: false)
  "refund_status": "none",              // none|requested|approved|refunded|rejected|expired
  "refund_eligible_at": "2027-02-19T…", // window OPENS (activation + 6 months)
  "refund_window_closes_at": "2027-03-01T…", // +10 days
  "window_open": false,                 // now within [eligible_at, closes_at]
  "can_request_refund": false,          // ← ENABLE the Refund button ONLY when true
  "refundable_amount_inr": 300,         // base only, no GST
  "razorpay_refund_id": null,
  "refunded_at": null
}
```

**Button rules (do exactly this):**
- `refund_system_enabled == false` → **don't show** the Refund control at all.
- `can_request_refund == true` → show an **enabled** "Request Refund" button.
- Otherwise show it **disabled** with a reason from `refund_status` / dates:
  - `refund_status == "none"` & now `< refund_eligible_at` → "Refund available after {date} (6 months)".
  - `refund_status == "none"` & now `> refund_window_closes_at` → "Refund window closed".
  - `requested` → "Refund requested — under review".
  - `approved`/`refunded` → "Refunded ₹{refundable_amount_inr}".
  - `rejected` → "Refund declined".

**Request API:**
```
POST subscription-service/account-plan/{id}/refund-request   (user JWT)
Body: { "tnc_accepted": true, "note": "optional reason" }
```
- `tnc_accepted` **must be true** — show a confirm sheet stating: *"Refundable only if your
  total earnings/sales are less than the plan price. Only the plan fee is refunded (GST
  is non-refundable). This is a one-time 10-day window."*
- **200** → `{ success, data: { refund: {...} } }` (status now `requested`); refresh my-plans.
- **400/403** → show `message` (outside window / already requested / refunds disabled).

> **No UI change to existing screens** beyond adding this button on the my-plans /
> contribution card. The whole feature can be turned off server-side
> (`refund_system_enabled:false`) — when it is, just hide the button.

### 2.3 `POST subscription-service/account-plan/initiate` — start a purchase ✅ LIVE
Body:
```json
{ "option_code": "RAD_GST_6KM", "tag_id": "GENERAL_STORE", "buyer_gstin": "03ABCDE1234F1Z5", "buyer_state": "Punjab" }
```
- `option_code` (required) — the card the user tapped.
- `tag_id` — re-priced server-side; never trust a client price.
- `buyer_gstin` — **required when the tapped card has `gst_track: "GST"`** (every radius tier except 1 km / 3 km, and all
  A6 wide-reach). NON_GST tiers don't need it. Validate the 15-char GSTIN client-side too for a nicer UX.
- `buyer_state` — optional, improves the CGST/SGST-vs-IGST split on the invoice (falls back to IGST).

**Payment-time GST validation (400).** If the option is `gst_track: "GST"` and `buyer_gstin` is missing/invalid, no order
is created and the response is:
```json
{ "success": false, "message": "GST required for this plan. Please add your GST number (GSTIN) to continue. The 1 km and 3 km plans are available without GST.", "data": { "requires_gst": true, "gst_track": "GST", "option_code": "RAD_GST_6KM" } }
```
Show `message` and focus a GSTIN input; on a valid GSTIN, retry `initiate`.

**200 response** (mirrors `InitiateSecurityDepositResponse`):
```json
{
  "success": true,
  "message": "Order created. Open Razorpay checkout with order_id.",
  "data": {
    "order_id": "order_XXXXXXXX",
    "key_id": "rzp_live_XXXX",
    "currency": "INR",
    "base_amount": 70000,
    "gst_percent": 18,
    "gst_amount": 12600,
    "total_amount": 82600,
    "option_code": "RAD_GST_6KM",
    "option_label": "6 km",
    "account_plan_id": "665f...",
    "status": "created"
  }
}
```
**Other responses the app must handle:**
- **Free / zero-price option** → `200` with `{ "order_id": null, "status": "active", ... }` — the backend activates it
  directly, **no Razorpay**. (In practice `is_free` cards are the default free profile; the app skips `initiate` for
  them — but if called, this is the shape.)
- **Already owned** → `400` `{ "success": false, "message": "You already have this plan active.", "data": { "account_plan_id", "status": "active" } }`. Show the message; don't open checkout.
- **Resume** (a prior unpaid order for the same option) → `200` with the same order fields **plus** `"resumed": true` —
  just open checkout with the returned `order_id` (no new order is created). If that order was already paid, the
  backend activates it and returns `{ "status": "active" }`.
- **Amount too low / bad option** → `400` with a message. Never open checkout on a non-200.

### 2.4 `POST subscription-service/account-plan/verify-payment` — client fallback ✅ LIVE
Body (same keys as security deposit): `{ "razorpay_order_id", "razorpay_payment_id", "razorpay_signature" }`.
Returns `{ "status": "ok" | "verification_failed", "message": "..." }`. The **webhook is source of truth**; this just
gives instant UI feedback. Always re-fetch `my-plans` after.

### 2.5 Invoice ✅ LIVE (Increment 3)
GST invoice is **auto-delivered** to the user's BlueEra chat + email (same as security deposit). Optional in-app:
`GET /account-plan/invoices` → `[{ invoice_number, invoice_url, status }]` and `GET /account-plan/{id}/invoice`.
`status ∈ generating|ready|failed`. Open `invoice_url` with `launchUrl(..., LaunchMode.externalApplication)` — the
link is unauthenticated + short-lived; **do not** add the `Authorization` header and **never** log it.

---

## 3. Endpoint constants — add to `SubscriptionServiceApi`

`lib/core/api/apiService/subscription_service_api.dart` (same mixin as `securityDeposit*`):
```dart
  /// Account Plans — dynamic paid plans (radius/call/service/lead/booking).
  /// See docs/backend/ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md.
  final String accountPlanPlans        = 'subscription-service/account-plan/plans';
  final String accountPlanMyPlans      = 'subscription-service/account-plan/my-plans';
  final String accountPlanSalesUsage   = 'subscription-service/account-plan/sales/usage'; // A1 sales-shops only
  final String accountPlanInitiate     = 'subscription-service/account-plan/initiate';
  final String accountPlanVerifyPayment= 'subscription-service/account-plan/verify-payment';
  final String accountPlanInvoices     = 'subscription-service/account-plan/invoices';
  String accountPlanInvoiceById(String id) => 'subscription-service/account-plan/$id/invoice';
```

---

## 4. Models — `lib/features/account_plan/model/account_plan_models.dart`

Follow the app's lenient parsing (`_asInt`) because the API may send num-or-string.
```dart
int _asInt(dynamic v, [int d = 0]) =>
    v == null ? d : (v is int ? v : int.tryParse(v.toString()) ?? (v is num ? v.toInt() : d));

class PlanCatalog {
  final String accountType, tagId, archetype, currency;
  final String? group, vehicleClass;
  final bool earnsInApp, hasGst;
  final int gstPercent;
  final List<PlanCard> plans;
  PlanCatalog.fromJson(Map<String, dynamic> j)
      : accountType = j['account_type'] ?? '',
        tagId = j['tag_id'] ?? '',
        group = j['group'],
        archetype = j['archetype'] ?? '',
        vehicleClass = j['vehicle_class'],
        earnsInApp = j['earns_in_app'] == true,
        hasGst = j['has_gst'] == true,
        currency = j['currency'] ?? 'INR',
        gstPercent = _asInt(j['gst_percent'], 18),
        plans = ((j['plans'] as List?) ?? []).map((e) => PlanCard.fromJson(e)).toList();
}

class PlanCard {
  final String optionCode, label, archetype, gstTrack, billing;
  final String? sublabel, vehicleClass, tier;
  final int? radiusKm, validityDays;
  final List<String>? jobTypes;
  final int priceBase, gstPercent, gstAmount, priceTotal;
  final num priceBaseInr, gstAmountInr, priceTotalInr;
  final bool isFree, popular;
  final List<String> features;             // DB-driven bullets — render verbatim
  final List<String> termsAndConditions;   // DB-driven T&C — render verbatim
  PlanCard.fromJson(Map<String, dynamic> j)
      : optionCode = j['option_code'] ?? '',
        label = j['label'] ?? '',
        sublabel = j['sublabel'],
        archetype = j['archetype'] ?? '',
        vehicleClass = j['vehicle_class'],
        gstTrack = j['gst_track'] ?? 'NA',
        billing = j['billing'] ?? 'lifetime',   // v1: always "lifetime" (one-time, never expires)
        validityDays = (j['validity_days'] == null) ? null : _asInt(j['validity_days']),
        radiusKm = (j['attributes']?['radius_km'] == null) ? null : _asInt(j['attributes']['radius_km']),
        jobTypes = (j['attributes']?['job_types'] as List?)?.map((e) => e.toString()).toList(),
        tier = j['attributes']?['tier'],
        priceBase = _asInt(j['price_base']),
        gstPercent = _asInt(j['gst_percent'], 18),
        gstAmount = _asInt(j['gst_amount']),
        priceTotal = _asInt(j['price_total']),
        priceBaseInr = (j['price_base_inr'] as num?) ?? 0,
        gstAmountInr = (j['gst_amount_inr'] as num?) ?? 0,
        priceTotalInr = (j['price_total_inr'] as num?) ?? 0,
        isFree = j['is_free'] == true,
        popular = j['popular'] == true,   // show a "Popular" ribbon when true
        features = ((j['features'] as List?) ?? const []).map((e) => e.toString()).toList(),
        termsAndConditions =
            ((j['terms_and_conditions'] as List?) ?? const []).map((e) => e.toString()).toList();
}

class InitiatePlanResponse {
  final String orderId, keyId, currency, optionCode, optionLabel, accountPlanId, status;
  final int baseAmount, gstAmount, totalAmount;
  InitiatePlanResponse.fromJson(Map<String, dynamic> j)
      : orderId = j['order_id'] ?? '',
        keyId = j['key_id'] ?? '',
        currency = j['currency'] ?? 'INR',
        optionCode = j['option_code'] ?? '',
        optionLabel = j['option_label'] ?? '',
        accountPlanId = j['account_plan_id'] ?? '',
        status = j['status'] ?? 'created',
        baseAmount = _asInt(j['base_amount']),
        gstAmount = _asInt(j['gst_amount']),
        totalAmount = _asInt(j['total_amount']);
}
```

---

## 5. Repo — `lib/features/account_plan/repo/account_plan_repo.dart`

```dart
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class AccountPlanRepo extends BaseService {
  Future<ResponseModel> getPlans({String? tagId, bool? hasGst}) {
    final q = <String, dynamic>{};
    if (tagId != null && tagId.isNotEmpty) q['tag_id'] = tagId;
    if (hasGst != null) q['has_gst'] = hasGst.toString();
    return ApiBaseHelper().getHTTP(accountPlanPlans, params: q, showProgress: false);
  }

  Future<ResponseModel> myPlans({String? status}) => ApiBaseHelper()
      .getHTTP(accountPlanMyPlans, params: status == null ? null : {'status': status}, showProgress: false);

  Future<ResponseModel> initiate({required String optionCode, String? tagId, bool? hasGst, String? buyerState}) =>
      ApiBaseHelper().postHTTP(accountPlanInitiate, params: {
        'option_code': optionCode,
        if (tagId != null) 'tag_id': tagId,
        if (hasGst != null) 'has_gst': hasGst,
        if (buyerState != null) 'buyer_state': buyerState,
      }, showProgress: false);

  Future<ResponseModel> verifyPayment({required String orderId, required String paymentId, required String signature}) =>
      ApiBaseHelper().postHTTP(accountPlanVerifyPayment, params: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      }, showProgress: false);
}
```

---

## 6. Controller — `lib/features/account_plan/controller/account_plan_controller.dart`

Mirrors `SecurityDepositController`: `Status` enum + `RxList` for the catalog, `RxBool isProcessing`, `RazorpayService`
wrapper, initiate → checkout → verify → re-fetch, and `dispose()` in `onClose()`.
```dart
import 'package:BlueEra/core/api/apiService/api_response.dart';           // Status
import 'package:BlueEra/core/constants/snackbar_helper.dart';            // commonSnackBar
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/razor_pay_services.dart';          // RazorpayService
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../repo/account_plan_repo.dart';
import '../model/account_plan_models.dart';

class AccountPlanController extends GetxController {
  final AccountPlanRepo _repo = AccountPlanRepo();
  final RazorpayService _razorpay = RazorpayService();

  // inputs (set by the screen from the user's profile)
  String? tagId;
  bool? hasGst;
  String? buyerState;
  String buyerName = '', buyerEmail = '', buyerPhone = '';

  final plansStatus = Status.INITIAL.obs;
  final Rxn<PlanCatalog> catalog = Rxn<PlanCatalog>();
  final isProcessing = false.obs;
  final purchasingCode = ''.obs; // which card is mid-purchase (for per-card spinner)

  @override
  void onInit() { super.onInit(); fetchPlans(); }

  Future<void> fetchPlans() async {
    plansStatus.value = Status.LOADING;
    final res = await _repo.getPlans(tagId: tagId, hasGst: hasGst);
    final data = res.response?.data?['data'];
    if (res.statusCode == 200 && data is Map<String, dynamic>) {
      catalog.value = PlanCatalog.fromJson(data);
      plansStatus.value = Status.COMPLETE;
    } else {
      plansStatus.value = Status.ERROR;
    }
  }

  Future<void> buyPlan(PlanCard card) async {
    if (isProcessing.value) return;
    if (card.isFree) { commonSnackBar(message: AppStrings.planAlreadyFree.tr); return; }

    isProcessing.value = true;
    purchasingCode.value = card.optionCode;
    final initRes = await _repo.initiate(
        optionCode: card.optionCode, tagId: tagId, hasGst: hasGst, buyerState: buyerState);
    final data = initRes.response?.data?['data'];
    if (initRes.statusCode != 200 || data is! Map<String, dynamic>) {
      _reset();
      commonSnackBar(message: initRes.message ?? AppStrings.couldNotStartPayment.tr);
      return;
    }
    final order = InitiatePlanResponse.fromJson(data);

    _razorpay.openCheckout(
      razorpayKeyId: order.keyId,
      name: AppStrings.appName,
      description: card.label,
      amount: order.totalAmount.toDouble(),  // PAISE, GST-inclusive — server-owned
      contact: buyerPhone, email: buyerEmail,
      subscriptionId: '',                    // '' → one-time order_id path
      orderId: order.orderId, currency: order.currency,
      onPaymentSuccess: _onSuccess,
      onPaymentError: _onError,
    );
  }

  Future<void> _onSuccess(PaymentSuccessResponse r) async {
    final res = await _repo.verifyPayment(
        orderId: r.orderId ?? '', paymentId: r.paymentId ?? '', signature: r.signature ?? '');
    _reset();
    final ok = res.statusCode == 200 &&
        (res.response?.data?['status'] == 'ok' || res.response?.data?['success'] == true);
    commonSnackBar(message: ok ? AppStrings.planActivated.tr : AppStrings.paymentVerifyPending.tr);
    await fetchPlans(); // + optionally refresh my-plans elsewhere
  }

  void _onError(PaymentFailureResponse r) {
    _reset();
    commonSnackBar(message: RazorpayService.humanReadableError(r));
  }

  void _reset() { isProcessing.value = false; purchasingCode.value = ''; }

  @override
  void onClose() { _razorpay.dispose(); super.onClose(); }
}
```

---

## 7. UI — `lib/features/account_plan/view/account_plan_screen.dart`

Fully dynamic: it renders whatever `plans[]` the backend returns and draws each card from its `archetype` + fields.
Uses the app's kit (`CustomText`, `CustomBtn`, `AppColors`, `SizeConfig`, `staggeredDotsWaveLoading`, `commonSnackBar`)
and `AppStrings.*.tr` for every string.
```dart
class AccountPlanScreen extends StatefulWidget {
  final String tagId; final bool hasGst; final String? buyerState;
  const AccountPlanScreen({super.key, required this.tagId, this.hasGst = false, this.buyerState});
  @override State<AccountPlanScreen> createState() => _AccountPlanScreenState();
}

class _AccountPlanScreenState extends State<AccountPlanScreen> {
  late final AccountPlanController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = getOrPut(() => AccountPlanController());   // lib/core/constants/getx_utils.dart
    _ctrl..tagId = widget.tagId
          ..hasGst = widget.hasGst
          ..buyerState = widget.buyerState;
    // hydrate buyer prefill from ViewPersonalDetailsController (see contribution_plans_view.dart)
    _hydrateBuyer();
    _ctrl.fetchPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.chooseYourPlan.tr),
      body: Obx(() {
        final st = _ctrl.plansStatus.value;
        if (st == Status.LOADING || st == Status.INITIAL) {
          return Center(child: staggeredDotsWaveLoading());
        }
        if (st == Status.ERROR) {
          return _RetryView(onRetry: _ctrl.fetchPlans);
        }
        final cat = _ctrl.catalog.value!;
        return ListView(
          padding: EdgeInsets.all(SizeConfig.size16),
          children: [
            CustomText(_archetypeHeadline(cat.archetype).tr,
                fontSize: SizeConfig.size18, fontWeight: FontWeight.w700, color: AppColors.mainTextColor),
            SizedBox(height: SizeConfig.size12),
            for (final p in cat.plans)
              _PlanCardTile(
                card: p,
                gstPercent: cat.gstPercent,
                isBusy: _ctrl.isProcessing.value && _ctrl.purchasingCode.value == p.optionCode,
                onBuy: () => _ctrl.buyPlan(p),
              ),
          ],
        );
      }),
    );
  }
}
```

### 7.1 Dynamic card tile (mirror `_ContributionPlanCard`)
```dart
class _PlanCardTile extends StatelessWidget {
  final PlanCard card; final int gstPercent; final bool isBusy; final VoidCallback onBuy;
  const _PlanCardTile({required this.card, required this.gstPercent, required this.isBusy, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size12),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: CustomText(card.label, fontSize: SizeConfig.size16, fontWeight: FontWeight.w700)),
          _PriceTag(card: card),
        ]),
        if ((card.sublabel ?? '').isNotEmpty) ...[
          SizedBox(height: SizeConfig.size4),
          CustomText(card.sublabel!, fontSize: SizeConfig.size12, color: AppColors.secondaryTextColor),
        ],
        // entitlement summary chips (radius km / job types / tier)
        if (_chips(card).isNotEmpty) ...[
          SizedBox(height: SizeConfig.size8),
          Wrap(spacing: 6, runSpacing: 6, children: _chips(card).map(_pill).toList()),
        ],
        // DB-driven feature bullets — rendered VERBATIM from the API (never hardcoded)
        SizedBox(height: SizeConfig.size10),
        ...card.features.map((f) => Padding(
              padding: EdgeInsets.only(bottom: SizeConfig.size6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check_circle, size: 16, color: AppColors.primaryColor),
                SizedBox(width: 6),
                Expanded(child: CustomText(f, fontSize: SizeConfig.size13, color: AppColors.mainTextColor)),
              ]),
            )),
        SizedBox(height: SizeConfig.size10),
        if (card.isFree)
          _FreeTag()
        else
          CustomBtn(
            title: isBusy ? AppStrings.processingEllipsis.tr : AppStrings.buyNow.tr,
            bgColor: AppColors.primaryColor,
            isLoading: isBusy,
            onTap: isBusy ? () {} : onBuy,
          ),
        // *T&C link — opens the terms sheet (also DB-driven, per plan)
        if (card.termsAndConditions.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showTermsSheet(context, card),
              child: CustomText('*${AppStrings.termsAndConditions.tr}',
                  fontSize: SizeConfig.size11, color: AppColors.primaryColor),
            ),
          ),
      ]),
    );
  }

  // Build human chips from whatever attributes the archetype carries — NO hardcoding.
  List<String> _chips(PlanCard c) {
    final out = <String>[];
    if (c.radiusKm != null) {
      out.add(c.radiusKm == -1 ? AppStrings.allIndia.tr : '${c.radiusKm} ${AppStrings.kmVisibility.tr}');
    }
    if (c.jobTypes != null) {
      for (final j in c.jobTypes!) out.add(j.replaceAll('_', ' '));  // passenger / food grocery / parcel
    }
    if (c.tier != null) out.add(c.tier!);          // BASIC / PRO
    return out;
  }
}

class _PriceTag extends StatelessWidget {
  final PlanCard card; const _PriceTag({required this.card});
  String _r(int paise) { final v = paise / 100; return v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2); }
  @override
  Widget build(BuildContext context) {
    if (card.isFree) return CustomText(AppStrings.free.tr, fontWeight: FontWeight.w700, color: AppColors.primaryColor);
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      CustomText('${AppConstants.rupeeSymbol}${_r(card.priceTotal)}',
          fontSize: SizeConfig.size16, fontWeight: FontWeight.w800, color: AppColors.mainTextColor),
      CustomText('${AppStrings.inclGstPrefix.tr} ${card.gstPercent}${AppStrings.gstSuffix.tr}',
          fontSize: SizeConfig.size10, color: AppColors.secondaryTextColor),
    ]);
  }
}
```
`_pill`, `_FreeTag`, `_RetryView`, `_archetypeHeadline` are trivial local helpers (mirror the existing perk-pill /
retry widgets in `contribution_plans_view.dart`). `_archetypeHeadline` maps `A1_..→'chooseVisibilityRadius'`,
`A2_..→'chooseYourCallPlan'`, `A4_../A5_..→'chooseYourListing'`, etc. — all `AppStrings` keys.

### 7.2 T&C sheet (renders the plan's `terms_and_conditions` verbatim)
```dart
void _showTermsSheet(BuildContext context, PlanCard card) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => Padding(
      padding: EdgeInsets.all(SizeConfig.size20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        CustomText(AppStrings.termsAndConditions.tr, fontSize: SizeConfig.size16, fontWeight: FontWeight.w700),
        SizedBox(height: SizeConfig.size12),
        ...card.termsAndConditions.map((t) => Padding(
              padding: EdgeInsets.only(bottom: SizeConfig.size8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CustomText('•  ', color: AppColors.secondaryTextColor),
                Expanded(child: CustomText(t, fontSize: SizeConfig.size13, color: AppColors.secondaryTextColor)),
              ]),
            )),
      ]),
    ),
  );
}
```

---

## 8. Razorpay — A to Z (uses the app's existing wrapper)

You do **not** create a `Razorpay()` yourself — use `RazorpayService` (`lib/core/services/razor_pay_services.dart`),
exactly as the deposit flow does:
1. `initiate` → get `order_id`, `key_id`, `total_amount` (paise).
2. `_razorpay.openCheckout(amount: order.totalAmount.toDouble(), orderId: order.orderId, subscriptionId: '', ...)`.
   - `amount` is **paise**; `openCheckout` divides by 100 internally for Razorpay.
   - `subscriptionId: ''` selects the one-time `order_id` path (not the recurring path).
   - `prefill` = buyer contact/email (hydrate from `ViewPersonalDetailsController` before pay).
3. `onPaymentSuccess` → `verifyPayment(order_id, payment_id, signature)` → re-fetch. Webhook is the real source of truth.
4. `onPaymentError` → `RazorpayService.humanReadableError(response)` (never raw errors).
5. Always `_razorpay.dispose()` in `onClose()`.

**Native setup is already done** (`razorpay_flutter` is a dependency and the deposit flow ships in production) — no
Android/iOS changes needed.

---

## 9. Invoice (GST) — optional in-app view
The backend auto-delivers the GST tax invoice PDF to the user's **chat thread + email** (same as security deposit), so
no in-app screen is required. If you want an in-app "Download invoice" on `my-plans`:
```dart
// list: GET /account-plan/invoices -> [{invoice_number, invoice_url, status}]
// open (status == 'ready'):
await launchURL(invoiceUrl);           // lib/core/constants/common_methods.dart (externalApplication)
// or in-app: Get.to(() => FullScreenPdfViewer(fileUrl: invoiceUrl, title: invoiceNumber));
```
Do **not** attach the auth header to `invoice_url`; do **not** log it.

---

## 10. i18n keys to add

Add to `lib/core/constants/app_strings.dart` and `assets/translations/en.json` (+ the backend language store). Every
visible string above is `AppStrings.key.tr`:
```
chooseYourPlan, chooseVisibilityRadius, chooseYourCallPlan, chooseServiceArea, chooseYourListing,
buyNow, processingEllipsis, free, planAlreadyFree, planActivated, paymentVerifyPending,
couldNotStartPayment, inclGstPrefix ("incl."), gstSuffix ("% GST"), kmVisibility ("km reach"),
allIndia ("All India"), noHiddenCharges, noAutoPay, termsAndConditions ("Terms & Conditions"),
lifetime ("Lifetime")  // billing badge — the API `billing` value is always "lifetime" in v1
```
`CustomBtn` already `.tr`s its title, so you may pass the raw key as the button title if you prefer.

---

## 11. Conventions & edge cases (do these or payments break)

1. **Server owns the price.** Send `order.totalAmount` (paise, GST-inclusive) to Razorpay — never a client-computed
   total. The catalog card shows `price_total` + "incl. 18% GST" only for display.
2. Branch on `res.statusCode`; read payload at `res.response?.data['data']`, errors at `res.message`
   (`badResponse` is returned, not thrown).
3. `getOrPut(() => AccountPlanController())`, `Obx` + `Status`, `commonSnackBar`, dispose Razorpay in `onClose()`.
4. **Free plans (A0 `is_free`)** never open Razorpay — the backend activates them without an order.
5. **Business** passes `tag_id` (individual may omit it — profile fallback). All radius tiers are shown to everyone;
   GST is validated at **payment** for `gst_track === "GST"` tiers, not by hiding plans.
6. **Re-purchase / resume**: `initiate` is idempotent per unpaid order (mirrors deposit resume) — safe to retry.
7. Show a **per-card** spinner via `purchasingCode` so only the tapped card shows loading.

---

## 12. Backend status
**Built (Increment 2 — LIVE):**
- `POST /account-plan/initiate` → re-prices server-side, Razorpay order for `total_amount` (base + 18% GST, frozen
  snapshot incl. CGST/SGST/IGST split), persists a `created` `UserAccountPlan`; free options activate directly; blocks
  duplicate-active; resumes unpaid intents.
- `POST /account-plan/verify-payment` → signature check → **idempotent atomic activation** (`created/failed → active`).
- `POST /account-plan/webhook/razorpay` → HMAC verify + amount/currency check → same activation (source of truth);
  ignores non-account-plan orders; marks `failed` on `payment.failed`.

**Built (Increment 3 — LIVE):**
- GST tax-invoice PDF (18%, CGST/SGST intra-state or IGST inter-state) in your sample layout (seller GSTIN/state/bank
  via env) — a separate `AccountPlanInvoice` queue + worker (the deposit invoice system is untouched). Auto-delivered
  to the user's **chat + email**; enqueued idempotently at activation.
- `GET /account-plan/invoices`, `GET /account-plan/{id}/invoice`, and the unauthenticated token download
  `GET /account-plan/invoice/d/:token`.
- **Config to set before go-live:** `ACCOUNT_PLAN_SELLER_GSTIN`, `ACCOUNT_PLAN_SELLER_STATE`, `ACCOUNT_PLAN_HSN_SAC`,
  `INVOICE_SELLER_*` (name/address/mobile/email/web/bank/upi), and the notification-service `account_plan_invoice`
  email template (already added).

**Still pending (ops hardening, optional):**
- A cleanup/recovery cron for stale unpaid `created` rows + missed-webhook/enqueue healing (mirror
  `securityDepositCleanup` / `depositRecovery` / `invoiceReconcile`).
- **Enforcement** — buying records the entitlement; applying it to map visibility / gig call-routing / enquiry access
  is the separate cross-service release (see `docs/DEPOSIT_TO_PAID_PLAN_REDESIGN.txt` §7–8).

> **Enforcement is intentionally NOT wired yet** (buying records the entitlement but does not yet change map
> visibility / gig call routing / enquiry access). That cross-service wiring is documented separately in
> `docs/DEPOSIT_TO_PAID_PLAN_REDESIGN.txt` (§7–8) and `docs/MONETIZATION_BY_ACCOUNT_TYPE.txt`, to ship as a
> coordinated release once this app flow is live.
