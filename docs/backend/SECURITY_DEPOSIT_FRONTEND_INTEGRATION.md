# Security Deposit — Frontend Integration Guide (Flutter)

A complete guide for integrating the **Security Deposit** flow. All field names,
status values, and response keys below match the backend **exactly** — use them
verbatim when parsing JSON.

> Source of truth: [`securityDeposit.controller.js`](../src/controllers/securityDeposit.controller.js),
> [`securityDeposit.route.js`](../src/routes/securityDeposit.route.js),
> [`SecurityDepositPlan.js`](../src/model/SecurityDepositPlan.js),
> [`UserSecurityDeposit.js`](../src/model/UserSecurityDeposit.js).

---

## 1. What this feature is

Every business / profession is identified by a **`tag_id`** (e.g. `GENERAL_STORE`)
and an **`account_type`** (`BUSINESS` or `INDIVIDUAL`). For each combination there
is a **Security Deposit Plan** describing:

- A **first-day free** usage allowance (e.g. *Unlimited Orders (Day 1)* or
  *First 5 Bookings Free*).
- A **refundable security deposit** the user pays to keep operating from the next
  day onward.
- A **postpaid per-unit charge** beyond the free limit.
- The deposit is **refundable only after `refund_after_months` (default 6)** — no
  refund before that.

The user side is a **`UserSecurityDeposit`** record that moves through a
lifecycle: `created → held → refund_requested → refunded`.

> ✅ **Razorpay is LIVE + Refer & Earn is wired.** `initiate` creates a Razorpay
> order (and applies a referral discount when a valid `referralCode` is present);
> the app opens Razorpay checkout, then calls `/verify-payment` to flip the deposit
> to `held`. A webhook is the source of truth. `refund/request` issues a real
> Razorpay refund after the 6-month lock. Zero-deposit tags skip payment and are
> returned already `held`.

---

## 2. Base setup

| Item | Value |
|---|---|
| Base URL (local) | `http://localhost:3000` |
| Route prefix | `/security-deposit` |
| Auth | `Authorization: Bearer <JWT>` on **every** endpoint |
| Content-Type | `application/json` for POST bodies |
| Money unit | **paise** (₹1 = 100). `deposit_amount: 100000` → ₹1000 |

**Standard response envelope** (all endpoints):

```json
{ "success": true, "message": "Fetched successfully", "data": { } }
```

On error:

```json
{ "success": false, "message": "Something went wrong", "error": "..." }
```

Always branch on the **`success`** boolean + the HTTP status code.

### Dart HTTP client base

```dart
import 'package:dio/dio.dart';

final dio = Dio(BaseOptions(
  baseUrl: 'http://localhost:3000',
  headers: {'Content-Type': 'application/json'},
));

void setAuthToken(String jwt) {
  dio.options.headers['Authorization'] = 'Bearer $jwt';
}
```

---

## 3. Data models (match backend field-for-field)

### 3.1 SecurityDepositPlan (catalog)

| Field | Type | Meaning |
|---|---|---|
| `_id` | String | Mongo id of the plan |
| `ui_tab` | String | Flutter top tab: `Business` / `Social / Professional` / `Manufacturing` |
| `ui_category_group` | String | Section header, e.g. `Grocery & Stationary Stores` |
| `name` | String | Display name, e.g. `General Store` |
| `tag_id` | String | Entity id (UPPERCASE), e.g. `GENERAL_STORE` |
| `account_type` | String | `BUSINESS` or `INDIVIDUAL` |
| `avg_volume` | num | Reference avg volume |
| `deposit_amount` | num | Refundable deposit, **paise** |
| `base_metric` | String | e.g. `Per Completed Order`, `Per Appointment/Booking` |
| `first_day_free_text` | String | Raw label, e.g. `Unlimited Orders (Day 1)` |
| `first_day_free_limit` | num? | Numeric free count; **`null` = unlimited** |
| `first_day_free_unlimited` | bool | `true` when unlimited |
| `postpaid_charge_per_unit` | num | Charge per unit beyond free limit, **paise** |
| `activation_condition` | String | e.g. `Pay (Orders * 10) to mark store OPEN` |
| `refund_after_months` | num | Refund lock duration (default `6`) |
| `terms_and_conditions` | List\<String\> | UI-ready T&C lines |
| `currency` | String | `INR` |
| `active` | bool | Plan is purchasable |
| `mode` | String | `live` / `test` (Razorpay env) |
| `created_at` / `updated_at` | ISO date | |

```dart
class SecurityDepositPlan {
  final String id;
  final String uiTab;
  final String uiCategoryGroup;
  final String name;
  final String tagId;
  final String accountType;
  final int depositAmount;            // paise
  final String baseMetric;
  final String firstDayFreeText;
  final int? firstDayFreeLimit;       // null = unlimited
  final bool firstDayFreeUnlimited;
  final int postpaidChargePerUnit;    // paise
  final String activationCondition;
  final int refundAfterMonths;
  final List<String> termsAndConditions;
  final String currency;

  SecurityDepositPlan.fromJson(Map<String, dynamic> j)
      : id = j['_id'],
        uiTab = j['ui_tab'] ?? '',
        uiCategoryGroup = j['ui_category_group'] ?? '',
        name = j['name'] ?? '',
        tagId = j['tag_id'] ?? '',
        accountType = j['account_type'] ?? '',
        depositAmount = (j['deposit_amount'] ?? 0) as int,
        baseMetric = j['base_metric'] ?? '',
        firstDayFreeText = j['first_day_free_text'] ?? '',
        firstDayFreeLimit = j['first_day_free_limit'],
        firstDayFreeUnlimited = j['first_day_free_unlimited'] ?? false,
        postpaidChargePerUnit = (j['postpaid_charge_per_unit'] ?? 0) as int,
        activationCondition = j['activation_condition'] ?? '',
        refundAfterMonths = (j['refund_after_months'] ?? 6) as int,
        termsAndConditions =
            (j['terms_and_conditions'] as List?)?.cast<String>() ?? const [],
        currency = j['currency'] ?? 'INR';

  // Convenience for display: paise → rupees
  double get depositRupees => depositAmount / 100.0;
  double get postpaidRupees => postpaidChargePerUnit / 100.0;
}
```

### 3.2 UserSecurityDeposit (the user's record)

| Field | Type | Meaning |
|---|---|---|
| `_id` | String | Deposit id (use as `depositId` in later calls) |
| `user_id` | String | Owner |
| `securityDepositPlanId` | String \| Object | Plan id, or the **populated plan object** on `current` / `my-deposits` / `details` |
| `tag_id` | String | Denormalized tag |
| `account_type` | String | `BUSINESS` / `INDIVIDUAL` |
| `deposit_amount` | num | Catalog deposit snapshot, **paise** |
| `base_amount` | num | Pre-discount base (referral commission base), **paise** |
| `referralCode` | String? | Applied code; **cleared** after the referrer is credited |
| `referral_discount_percent` | num | e.g. `10` |
| `discount_amount` | num | Referral discount, **paise** |
| `final_amount` | num | **Amount actually paid AND refunded**, paise (`base − discount`) |
| `currency` | String | `INR` |
| `status` | String | See lifecycle below |
| `isActive` | bool | `true` while `held` |
| `razorpay_order_id` | String | Order created at `initiate` |
| `razorpay_payment_id` | String? | Set on payment success |
| `razorpay_refund_id` | String? | Set when a refund is issued |
| `held_at` | ISO date? | When deposit became `held` |
| `refund_after_months` | num | Snapshot (default `6`) |
| `refund_eligible_at` | ISO date? | Earliest refund date (`held_at + refund_after_months`) |
| `refund_requested_at` | ISO date? | When refund was requested |
| `refunded_at` | ISO date? | When refunded |
| `mode` | String | `live` / `test` |
| `created_at` / `updated_at` | ISO date | |

> **Money fields:** show `final_amount` as the price (what the user pays and later
> gets back). `base_amount`/`discount_amount` let you render a struck-through
> original + the referral saving.

---

## 4. Status lifecycle (keyword: `status`)

```
created ──Razorpay pay → /verify-payment (or webhook)──▶ held ──refund/request (after 6mo)──▶ refund_requested ──refund.processed──▶ refunded
   │                                                                              
   ├──payment.failed──▶ failed
   └──cancel / cron──▶ cancelled / expired
```

| `status` | Meaning | UI hint |
|---|---|---|
| `created` | Order created, **payment not captured** | Open Razorpay checkout → `/verify-payment` |
| `held` | Deposit paid & active | Show "Active", show `refund_eligible_at` |
| `refund_requested` | Razorpay refund initiated after lock | Show "Refund in progress" |
| `refunded` | Money returned (refund processed) | Show "Refunded" |
| `failed` | Payment failed | Allow retry / re-initiate |
| `forfeited` | Deposit retained | Show "Forfeited" |
| `cancelled` | Unpaid intent cancelled | Allow re-initiate |
| `expired` | Stale `created` cleaned up by cron | Allow re-initiate |

`isActive == true` only when `status == 'held'`.

---

## 5. Endpoint reference

> ### 🔁 Tag / account_type input is tolerant
> Every endpoint that accepts a **`tag_id`** or **`account_type`** (plans, plan-by-tag,
> initiate, and the gRPC tag lookups) normalises the value, so the frontend can send
> the **display name** or any casing and still get a match:
>
> | Frontend sends | Backend resolves to |
> |---|---|
> | `General Store`, `general store`, `general-store`, `GENERAL_STORE` | `GENERAL_STORE` |
> | `Vegetable & Fruit` | `VEGETABLE_FRUIT` |
> | `Multi-Cuisine Restaurant` | `MULTICUISINE_RESTAURANT` (matched by name) |
> | `Car / Taxi Driver` | `CAR_TAXI_DRIVER` |
> | `business`, `Business`, `BUSINESS` | `BUSINESS` |
>
> Rule: input is upper-cased and any run of non-alphanumeric chars → `_`; if that
> doesn't match a `tag_id`, the backend also matches the exact **display name**
> (case-insensitive). **You must still URL-encode** spaces/`&`/`/` in the query string
> (see the Dart helper below) — Dio/Uri do this for you.

### 5.1 List plans — `GET /security-deposit/plans`

Query params (both optional): **`tag_id`**, **`account_type`**.

```
GET /security-deposit/plans?account_type=BUSINESS
GET /security-deposit/plans?tag_id=GENERAL_STORE&account_type=BUSINESS
# Display name also works (URL-encoded):
GET /security-deposit/plans?tag_id=General%20Store&account_type=BUSINESS
```

**Always pass query values via the client's `queryParameters` (not string concat)** so
spaces and `&`/`/` are encoded correctly:

```dart
// ✅ Correct — Dio encodes "General Store" → "General%20Store"
Future<List<SecurityDepositPlan>> fetchPlans({String? tagId, String? accountType}) async {
  final res = await dio.get('/security-deposit/plans', queryParameters: {
    if (tagId != null) 'tag_id': tagId,            // e.g. "General Store" or "GENERAL_STORE"
    if (accountType != null) 'account_type': accountType,
  });
  final list = (res.data['data'] as List);
  return list.map((e) => SecurityDepositPlan.fromJson(e)).toList();
}

// For a path param (plan-by-tag), encode the segment explicitly:
Future<SecurityDepositPlan> fetchPlanByTag(String tag, {String? accountType}) async {
  final res = await dio.get(
    '/security-deposit/plan/${Uri.encodeComponent(tag)}',   // "Vegetable & Fruit" → "Vegetable%20%26%20Fruit"
    queryParameters: { if (accountType != null) 'account_type': accountType },
  );
  return SecurityDepositPlan.fromJson(res.data['data']);
}
```

> ⚠️ Do **not** build URLs by string interpolation
> (`'/plans?tag_id=$tag'`) — a `&` or space in the name will corrupt the query.
> Use `queryParameters` / `Uri.encodeComponent` as above.

**200**
```json
{
  "success": true,
  "message": "Fetched successfully",
  "data": [
    {
      "_id": "66c0...",
      "ui_tab": "Business",
      "ui_category_group": "Grocery & Stationary Stores",
      "name": "General Store",
      "tag_id": "GENERAL_STORE",
      "account_type": "BUSINESS",
      "deposit_amount": 100000,
      "base_metric": "Per Completed Order",
      "first_day_free_text": "Unlimited Orders (Day 1)",
      "first_day_free_limit": null,
      "first_day_free_unlimited": true,
      "postpaid_charge_per_unit": 1000,
      "activation_condition": "Pay (Orders * 10) to mark store OPEN",
      "refund_after_months": 6,
      "terms_and_conditions": ["...", "..."],
      "currency": "INR",
      "active": true,
      "mode": "live"
    }
  ]
}
```

> Plans are **scoped to the current Razorpay mode** (`live`/`test`). The frontend
> does not pass `mode` — the backend picks it.

### 5.2 Get plan by tag — `GET /security-deposit/plan/{tagId}`

Optional query `account_type`. Use this on the onboarding/detail screen when you
already know the user's tag.

**200** → `data` is a **single plan object**. **404** if not found.

### 5.3 Create plan — `POST /security-deposit/create-plan`

Admin/local tooling (catalog is normally CSV-seeded). Body requires
`name`, `tag_id`, `account_type`, `deposit_amount` (paise). Returns **201** with
`data` = the new plan. *(Most Flutter apps won't call this.)*

### 5.4 Delete plan — `DELETE /security-deposit/plan/{planId}`

By Mongo `_id`. Returns `data: { "deletedPlanId": "<id>" }`. *(Admin only.)*

---

### 5.5 Initiate deposit — `POST /security-deposit/initiate`

Creates a **Razorpay order**. Provide **either** `securityDepositPlanId` **or**
both `tag_id` + `account_type`. Optional **`referralCode`** for the discount.

```json
{ "tag_id": "GENERAL_STORE", "account_type": "BUSINESS", "referralCode": "REF12345" }
```

**200** (paid deposit)
```json
{
  "success": true,
  "message": "Security deposit order created. Open Razorpay checkout with order_id.",
  "data": {
    "order_id": "order_Lv32q9c9XQM8bX",
    "key_id": "rzp_live_XXXXXXXXXXXX",
    "currency": "INR",
    "base_amount": 100000,
    "discount_amount": 10000,
    "referral_discount_percent": 10,
    "final_amount": 90000,
    "refund_after_months": 6,
    "security_deposit_id": "66c1...",
    "status": "created"
  }
}
```

**200** (zero-deposit tag, e.g. Social Profile) → `order_id: null`, `final_amount: 0`,
`status: "held"` (no payment needed; already active).

Open Razorpay checkout with `data.order_id` + `data.key_id` for `data.final_amount`.
Save **`data.security_deposit_id`** — the `depositId` for `refund/request`,
`cancel`, and `…/details`.

**Error cases**
| HTTP | When | Body |
|---|---|---|
| 400 | Neither id nor (tag_id+account_type) | `{ success:false, message:"Provide either securityDepositPlanId, or both tag_id and account_type." }` |
| 400 | User already has one for this tag | `{ success:false, message:"You already have a held security deposit for GENERAL_STORE.", data:{ security_deposit_id, status } }` |
| 400 | Plan inactive | `{ success:false, message:"This security deposit plan is no longer active." }` |
| 404 | Plan not found | `{ success:false, message:"Security deposit plan not found." }` |

> Referral: an invalid/absent code simply yields `discount_amount: 0` /
> `final_amount == base_amount` — the call still succeeds.

### 5.6 Verify payment — `POST /security-deposit/verify-payment`

Call after Razorpay checkout succeeds. Idempotently activates the deposit
(`created → held`), sets `held_at` / `refund_eligible_at`, and credits the referrer.

```json
{
  "razorpay_order_id": "order_Lv32q9c9XQM8bX",
  "razorpay_payment_id": "pay_Lv32q9c9XQM8bX",
  "razorpay_signature": "2b83499fdd8ecb89c2cf5f..."
}
```

**200** → `{ "status": "ok", "message": "Verified successfully" }`.
**400** invalid signature / missing fields. **404** no deposit for that order.

> The **webhook** (`/security-deposit/webhook/razorpay`) is the source of truth and
> performs the same activation — so even if the app dies before calling
> verify-payment, the deposit still becomes `held`. Both are idempotent.

### 5.7 Get current held deposit — `GET /security-deposit/current`

**200** → `data` = the held deposit with **populated** `securityDepositPlanId`.
**404** `{ success:false, message:"No active security deposit found for this user." }`
— treat 404 as "no active deposit" (not an error toast).

### 5.8 List my deposits — `GET /security-deposit/my-deposits`

Optional `status` query (any lifecycle value). `data` is an array, newest first,
each with populated plan.

### 5.9 Deposit details — `GET /security-deposit/{depositId}/details`

**200** → `data: { "local": <UserSecurityDeposit + populated plan>, "razorpay_order": {…}|null, "razorpay_payment": {…}|null }`.
Live Razorpay objects are best-effort (null when unreachable or zero-deposit).

### 5.10 Request refund — `POST /security-deposit/refund/request`

Issues a **real Razorpay refund** of `final_amount` after the lock passes.

```json
{ "depositId": "66c1..." }
```

- **200** → `data: { security_deposit_id, status: "refund_requested" | "refunded", razorpay_refund_id, refund_amount }`.
  Status is `refunded` if Razorpay processed instantly; otherwise `refund_requested`
  and the `refund.processed` webhook flips it to `refunded` shortly after.
- **400** if not `held`: `"Only a held deposit can be refunded. Current status: created."`
- **400** if no captured payment: `"No captured payment found for this deposit…"`
- **400** if still within the lock window (the 6-month rule):
  ```json
  {
    "success": false,
    "message": "Refund is not available yet. The deposit is refundable on or after 2026-12-25 (after 6 months).",
    "data": { "refund_eligible_at": "2026-12-25T..." }
  }
  ```
  → Show the date from `data.refund_eligible_at`, disable the refund button until then.
- **502** if Razorpay rejects the refund (transient) → ask the user to retry.

### 5.11 Cancel deposit — `POST /security-deposit/cancel`

Only a **`created`** (unpaid) deposit can be cancelled.

```json
{ "depositId": "66c1..." }
```

**200** `{ success:true, message:"Security deposit cancelled successfully." }`.
**400** if `held`/terminal (use the refund flow for a held deposit). **404** if not found.

---

## 6. Recommended Flutter flow

```
┌─ Onboarding / Dashboard ──────────────────────────────────────────┐
│ 1. GET /security-deposit/current                                   │
│      200 → user already has a HELD deposit → show "Active" card    │
│      404 → no deposit yet → continue                               │
│                                                                    │
│ 2. GET /security-deposit/plan/{tagId}?account_type=...             │
│      → show deposit_amount (₹), first_day_free_text,               │
│        base_metric, terms_and_conditions, refund_after_months      │
│                                                                    │
│ 3. User taps "Pay Security Deposit" (optionally enters referralCode)│
│      POST /security-deposit/initiate {tag_id, account_type,        │
│                                       referralCode?}               │
│      → returns { order_id, key_id, final_amount, security_deposit_id }│
│      → (order_id == null → zero-deposit, already held → go to 6)   │
│                                                                    │
│ 4. Open Razorpay checkout (order_id, key_id, final_amount)         │
│      on success → handler gives order_id, payment_id, signature    │
│                                                                    │
│ 5. POST /security-deposit/verify-payment {order_id, payment_id,    │
│                                           signature}               │
│      → status becomes "held" (webhook also does this, idempotent)  │
│                                                                    │
│ 6. Show success → refund_eligible_at = held_at + 6 months          │
└────────────────────────────────────────────────────────────────────┘

Refund screen:
  POST /security-deposit/refund/request {depositId}
    400 within lock → show "Refundable on {refund_eligible_at}"
    200 → real Razorpay refund issued (status refund_requested → refunded)
```

### Example: initiate → Razorpay checkout → verify

```dart
import 'package:razorpay_flutter/razorpay_flutter.dart';

// 1. Create the order (referralCode optional)
Future<Map<String, dynamic>> initiateDeposit({
  required String tagId,
  required String accountType,
  String? referralCode,
}) async {
  final res = await dio.post('/security-deposit/initiate', data: {
    'tag_id': tagId,
    'account_type': accountType,
    if (referralCode != null) 'referralCode': referralCode,
  });
  final body = res.data as Map<String, dynamic>;
  if (body['success'] != true) throw Exception(body['message']);
  return body['data'] as Map<String, dynamic>; // { order_id, key_id, final_amount, ... }
}

// 2. Open Razorpay checkout
final _razorpay = Razorpay();
void openCheckout(Map<String, dynamic> order) {
  if (order['order_id'] == null) return; // zero-deposit: already held
  _razorpay.open({
    'key': order['key_id'],
    'order_id': order['order_id'],
    'amount': order['final_amount'], // paise
    'currency': order['currency'],
    'name': 'BlueEra Security Deposit',
  });
}

// 3. On success, verify with the backend
void onPaymentSuccess(PaymentSuccessResponse r) async {
  await dio.post('/security-deposit/verify-payment', data: {
    'razorpay_order_id': r.orderId,
    'razorpay_payment_id': r.paymentId,
    'razorpay_signature': r.signature,
  });
  // status is now "held"; refresh the deposit screen
}
// _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onPaymentSuccess);
// _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, ...);
```

> Even if the app is killed before step 3, the **webhook** activates the deposit
> server-side. On next launch, `GET /security-deposit/current` will return it as
> `held`.

### Example: current deposit (handle 404 as "none")

```dart
Future<UserSecurityDeposit?> fetchCurrentDeposit() async {
  try {
    final res = await dio.get('/security-deposit/current');
    return UserSecurityDeposit.fromJson(res.data['data']);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null; // no active deposit
    rethrow;
  }
}
```

### Example: refund with lock handling

```dart
Future<void> requestRefund(String depositId) async {
  try {
    await dio.post('/security-deposit/refund/request',
        data: {'depositId': depositId});
    // success → status: refund_requested
  } on DioException catch (e) {
    final data = e.response?.data;
    if (e.response?.statusCode == 400 && data?['data']?['refund_eligible_at'] != null) {
      final eligibleAt = DateTime.parse(data['data']['refund_eligible_at']);
      // show: "Refundable on ${eligibleAt}"
      return;
    }
    rethrow;
  }
}
```

---

## 7. Display tips

- **Always divide paise by 100** for display: `₹${(deposit_amount / 100)}`.
- **First-day free badge:** if `first_day_free_unlimited == true` show
  `first_day_free_text` ("Unlimited Orders (Day 1)"); else show
  "First `first_day_free_limit` free".
- **Postpaid line:** `activation_condition` is already a ready-made sentence
  ("Pay (Orders * 10) to mark store OPEN") — show it as-is.
- **T&C:** render `terms_and_conditions` as a bullet list before the pay button.
- **Zero deposit:** some tags (e.g. Social Profile) have `deposit_amount == 0` —
  hide the pay CTA / show "No deposit required".

---

## 8. Refer & Earn (how it works for the frontend)

- Pass an optional **`referralCode`** in `/initiate`. If valid, `data.final_amount`
  is already discounted by `referral_discount_percent` — just charge `final_amount`.
- If the user has a code parked at onboarding (server-side wallet), you can omit
  `referralCode` and the server auto-applies it.
- The **referrer's** earning is handled entirely server-side on payment success —
  the frontend does nothing extra. The buyer just sees the discounted `final_amount`.
- Show savings with `base_amount` (struck-through) vs `final_amount` (payable).
- The full `final_amount` is what gets refunded after the 6-month lock.

## 9. Razorpay & mode notes

- Razorpay runs in **LIVE** mode by default; the backend can toggle live/test
  globally (`/razorpay/toggle`). Plans and deposits are scoped per mode, so test
  in test mode and go live in live mode.
- `final_amount` and all money fields are **paise** — pass `amount: final_amount`
  straight to the Razorpay SDK.
- Webhook is authoritative; `/verify-payment` is your instant-feedback path. Never
  mark a deposit "paid" purely on the client — always confirm via verify-payment
  (or re-fetch `current`).
