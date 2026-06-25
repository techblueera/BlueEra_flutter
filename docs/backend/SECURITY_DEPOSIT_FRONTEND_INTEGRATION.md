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

> ⚠️ **Payment (Razorpay) is NOT wired yet.** Today, `initiate` records intent and
> `confirm` simulates payment success. When Razorpay lands, `confirm` is replaced
> by a checkout + signature/webhook step — **the rest of the contract stays the
> same**, so build your UI against this now.

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
| `deposit_amount` | num | Snapshot of deposit, **paise** |
| `currency` | String | `INR` |
| `status` | String | See lifecycle below |
| `isActive` | bool | `true` while `held` |
| `held_at` | ISO date? | When deposit became `held` |
| `refund_after_months` | num | Snapshot (default `6`) |
| `refund_eligible_at` | ISO date? | Earliest refund date (`held_at + refund_after_months`) |
| `refund_requested_at` | ISO date? | When refund was requested |
| `refunded_at` | ISO date? | When refunded |
| `mode` | String | `live` / `test` |
| `created_at` / `updated_at` | ISO date | |

---

## 4. Status lifecycle (keyword: `status`)

```
created ──confirm──▶ held ──refund/request (after 6mo)──▶ refund_requested ──▶ refunded
   │                                                                              
   └──cancel──▶ cancelled

other terminal states the backend may set: forfeited, expired
```

| `status` | Meaning | UI hint |
|---|---|---|
| `created` | Intent recorded, **not paid** | Show "Pay deposit" CTA → call `confirm` |
| `held` | Deposit paid & active | Show "Active", show `refund_eligible_at` |
| `refund_requested` | Refund asked after lock | Show "Refund in progress" |
| `refunded` | Money returned | Show "Refunded" |
| `forfeited` | Deposit retained | Show "Forfeited" |
| `cancelled` | Unpaid intent cancelled | Allow re-initiate |
| `expired` | Stale `created` cleaned up | Allow re-initiate |

`isActive == true` only when `status == 'held'`.

---

## 5. Endpoint reference

### 5.1 List plans — `GET /security-deposit/plans`

Query params (both optional): **`tag_id`**, **`account_type`**.

```
GET /security-deposit/plans?account_type=BUSINESS
GET /security-deposit/plans?tag_id=GENERAL_STORE&account_type=BUSINESS
```

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

Records intent. Provide **either** `securityDepositPlanId` **or** both
`tag_id` + `account_type`.

```json
{ "tag_id": "GENERAL_STORE", "account_type": "BUSINESS" }
```

**200**
```json
{
  "success": true,
  "message": "Security deposit initiated. Payment integration (Razorpay) pending — call /confirm to simulate payment success.",
  "data": {
    "security_deposit_id": "66c1...",
    "tag_id": "GENERAL_STORE",
    "account_type": "BUSINESS",
    "deposit_amount": 100000,
    "currency": "INR",
    "refund_after_months": 6,
    "status": "created"
  }
}
```

Save **`data.security_deposit_id`** — it's the `depositId` for `confirm`,
`refund/request`, `cancel`, and `…/details`.

**Error cases**
| HTTP | When | Body |
|---|---|---|
| 400 | Neither id nor (tag_id+account_type) | `{ success:false, message:"Provide either securityDepositPlanId, or both tag_id and account_type." }` |
| 400 | User already has one for this tag | `{ success:false, message:"You already have a held security deposit for GENERAL_STORE.", data:{ security_deposit_id, status } }` |
| 400 | Plan inactive | `{ success:false, message:"This security deposit plan is no longer active." }` |
| 404 | Plan not found | `{ success:false, message:"Security deposit plan not found." }` |

> On the `400 already has` case, read `data.security_deposit_id` / `data.status`
> and route the user to the existing deposit instead of creating a new one.

### 5.6 Confirm deposit — `POST /security-deposit/confirm`

**Placeholder for payment success** (becomes Razorpay verify/webhook later).
Idempotent `created → held`.

```json
{ "depositId": "66c1..." }
```

**200** → `data` is the **full updated UserSecurityDeposit** with
`status: "held"`, `isActive: true`, `held_at`, and `refund_eligible_at` set.
If already held, returns 200 with the current record (message *"already held"*).

**400** if the deposit isn't in `created`. **404** if not found.

### 5.7 Get current held deposit — `GET /security-deposit/current`

**200** → `data` = the held deposit with **populated** `securityDepositPlanId`.
**404** `{ success:false, message:"No active security deposit found for this user." }`
— treat 404 as "no active deposit" (not an error toast).

### 5.8 List my deposits — `GET /security-deposit/my-deposits`

Optional `status` query (any lifecycle value). `data` is an array, newest first,
each with populated plan.

### 5.9 Deposit details — `GET /security-deposit/{depositId}/details`

**200** → `data: { "local": <UserSecurityDeposit with populated plan> }`.
*(When Razorpay is added, live order/payment will appear alongside `local`.)*

### 5.10 Request refund — `POST /security-deposit/refund/request`

```json
{ "depositId": "66c1..." }
```

- **200** → `data: { security_deposit_id, status: "refund_requested" }`
- **400** if not `held`:
  `"Only a held deposit can be refunded. Current status: created."`
- **400** if still within the lock window (the 6-month rule):
  ```json
  {
    "success": false,
    "message": "Refund is not available yet. The deposit is refundable on or after 2026-12-25 (after 6 months).",
    "data": { "refund_eligible_at": "2026-12-25T..." }
  }
  ```
  → Show the date from `data.refund_eligible_at`, disable the refund button until then.

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
│ 3. User taps "Pay Security Deposit"                                │
│      POST /security-deposit/initiate {tag_id, account_type}        │
│      → save data.security_deposit_id                               │
│                                                                    │
│ 4. (Razorpay later) → for now: POST /security-deposit/confirm      │
│      {depositId} → status becomes "held"                           │
│                                                                    │
│ 5. Show success → refund_eligible_at = held_at + 6 months          │
└────────────────────────────────────────────────────────────────────┘

Refund screen:
  POST /security-deposit/refund/request {depositId}
    400 within lock → show "Refundable on {refund_eligible_at}"
    200 → "Refund requested"
```

### Example: initiate → confirm

```dart
Future<String> initiateDeposit({
  required String tagId,
  required String accountType,
}) async {
  final res = await dio.post('/security-deposit/initiate', data: {
    'tag_id': tagId,
    'account_type': accountType,
  });
  final body = res.data as Map<String, dynamic>;
  if (body['success'] != true) {
    throw Exception(body['message']);
  }
  return body['data']['security_deposit_id'] as String;
}

// TODO: when Razorpay lands, replace this with checkout + verify.
Future<Map<String, dynamic>> confirmDeposit(String depositId) async {
  final res = await dio.post('/security-deposit/confirm', data: {
    'depositId': depositId,
  });
  return (res.data as Map<String, dynamic>)['data']; // held deposit
}
```

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

## 8. What changes when Razorpay is added (forward note)

The **only** step that changes is **§5.6 confirm**. It will be replaced by:
1. `initiate` will additionally return a Razorpay `order_id` + `key_id`.
2. Frontend opens the Razorpay checkout SDK with that order.
3. A `verify-payment` call (+ server webhook) flips `created → held`.

All other endpoints, fields, and statuses in this guide remain unchanged — so
anything you build now stays valid.
