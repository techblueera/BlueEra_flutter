# Recharge Service — Flutter Integration Guide

> **Service base URL:** `http://<host>/recharge`
> **Auth:** All endpoints (except the webhook) require a `Bearer <JWT>` token in the `Authorization` header.
> **Razorpay mode:** Currently in **TEST** mode. Switch to LIVE before production.
> **Razorpay product used:** Razorpay **Orders API** (one-time payment) — NOT subscriptions. Recharge plans live only in this service's DB; Razorpay never sees them.

---

## Table of Contents

1. [Entity Types & Plan Tiers](#1-entity-types--plan-tiers)
2. [Full Recharge Flow (Overview)](#2-full-recharge-flow-overview)
3. [Step-by-Step Integration](#3-step-by-step-integration)
   - [3.1 Fetch Recharge Plans](#31-fetch-recharge-plans)
   - [3.2 Initiate Recharge Order](#32-initiate-recharge-order)
   - [3.3 Open Razorpay Checkout in Flutter](#33-open-razorpay-checkout-in-flutter)
   - [3.4 Verify Recharge Payment](#34-verify-recharge-payment)
   - [3.5 Check Current Active Recharge](#35-check-current-active-recharge)
   - [3.6 Get All User Recharges](#36-get-all-user-recharges)
   - [3.7 Cancel Recharge](#37-cancel-recharge)
4. [Recharge Statuses](#4-recharge-statuses)
5. [Referral Discount UX](#5-referral-discount-ux)
6. [Error Handling](#6-error-handling)
7. [Data Models Reference](#7-data-models-reference)
8. [Quick Reference — All Endpoints](#8-quick-reference--all-endpoints)

---

## 1. Entity Types & Plan Tiers

### Entity Types
Recharge plans use the same entity type bucket as subscriptions. Pass the user's category as `entity_type` when fetching plans.

| Entity Type    | Perk Type | Description                  |
|----------------|-----------|------------------------------|
| `Gig Worker`   | rides     | Delivery / ride workers      |
| `Skill Worker` | leads     | Electricians, plumbers, etc. |
| `Food`         | sales     | Food businesses              |
| `Grocery`      | sales     | Grocery stores               |
| `Product`      | sales     | Product sellers              |
| `Other`        | leads     | All other categories         |

### Plan Tiers
Plans are returned in this order:

```
basic → popular → advance → pro → proplus
```

> **Recharge vs Subscription:** A recharge is a **one-shot purchase** that grants a perk quota (`perk_value + perk_bonus`). Perks are consumed by other services via gRPC. There is **no expiry** — a recharge stays `active` until all perks are consumed, then flips to `consumed`.

---

## 2. Full Recharge Flow (Overview)

```
┌─────────────────────────────────────────────────────────────┐
│  1. Fetch recharge plans filtered by entity_type            │
│     GET /recharge/plans?entity_type=...                     │
└─────────────────────────┬───────────────────────────────────┘
                          │ User picks a plan
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Create Razorpay order                                   │
│     POST /recharge/initiate-order                           │
│     ← returns order_id, key_id, final_amount,               │
│       discount_amount, gross_amount                         │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Open Razorpay checkout in Flutter                       │
│     Pass order_id (NOT subscription_id)                     │
│     ← returns payment_id, order_id, signature               │
└─────────────────────────┬───────────────────────────────────┘
                          │ Checkout success callback
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Verify payment                                          │
│     POST /recharge/verify-payment                           │
│     ← recharge marked active, perks initialised             │
│       (server-side webhook is the source of truth and runs  │
│        the same activation idempotently)                    │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  5. User now has perks_remaining = perk_value + perk_bonus  │
│     Other services consume perks via gRPC. When            │
│     perks_remaining hits 0 → status = consumed              │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Step-by-Step Integration

### 3.1 Fetch Recharge Plans

Fetch active plans filtered by the user's entity type. Plans are pre-sorted: `basic → popular → advance → pro → proplus`.

**Request**
```
GET /recharge/plans?entity_type=Gig Worker
Authorization: Bearer <token>
```

**Query Params**

| Param         | Required | Description                              |
|---------------|----------|------------------------------------------|
| `entity_type` | No       | Filter by entity type (see table above). If omitted, returns all active plans for the current Razorpay mode. |

**Response `200`**
```json
{
  "success": true,
  "message": "Fetched successfully",
  "data": [
    {
      "_id": "60c72b2f9b1d8b001c8e4d1a",
      "name": "Gig Worker Recharge - Basic",
      "description": "25 Rides + 5 Bonus Rides",
      "amount": 9900,
      "tax_percent": 18,
      "tax_amount": 1782,
      "total_amount": 11682,
      "amountBeforeDiscount": 39900,
      "sac_code": "998314",
      "currency": "INR",
      "tier": "basic",
      "entity_type": "Gig Worker",
      "perk_type": "rides",
      "perk_value": 25,
      "perk_bonus": 5,
      "perks": [
        "25 Rides",
        "5 Bonus Rides",
        "No hidden commissions"
      ],
      "active": true
    }
  ]
}
```

> **Note:** All amount fields are in **paise**. Divide by 100 for display. `9900` = ₹99.
>
> **Tax breakdown:** `amount` is the **base price** (pre-tax). `tax_percent` is the GST rate applied (0 if untaxed). `tax_amount` = `amount × tax_percent / 100`. `total_amount` is the gross — what Razorpay would charge if no referral discount applies.
>
> **Display suggestion:** show `₹{amount/100} + ₹{tax_amount/100} GST ({tax_percent}%) = ₹{total_amount/100}` when `tax_percent > 0`, otherwise just `₹{amount/100}`.

---

### 3.2 Initiate Recharge Order

Creates a Razorpay order and a local `UserRecharge` in `created` state. Returns `order_id` for the Razorpay checkout. If the user supplies a valid referral code, the configured discount is applied at this step.

**Request**
```
POST /recharge/initiate-order
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**
```json
{
  "rechargePlanId": "60c72b2f9b1d8b001c8e4d1a",
  "referralCode": "FRIEND123"
}
```

| Field            | Type   | Required | Description                                                                                                                                                                                       |
|------------------|--------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `rechargePlanId` | String | Yes      | The `_id` from the plan you fetched.                                                                                                                                                              |
| `referralCode`   | String | No       | Optional. If the user entered a code at onboarding (the `referred_by_code` field in `updateIndividualAccountUser` / `updateBusinessAccount`), the server will auto-apply that code even when this field is omitted. Send a value here only if the user is entering one via a dialog at recharge time — it takes precedence over the onboarding-captured code. |

> **Referral UX note.** Show the referral-code dialog only when the user did NOT enter a code at onboarding. The server-driven way to know this is the wallet-service endpoint `GET /wallet/pending-referral` (same as the subscription flow — see the Subscription Flutter Guide §3.2.1). Otherwise the server already has a code parked and will apply it automatically when `referralCode` is omitted from this request.

**Response `200`**
```json
{
  "success": true,
  "message": "Recharge order created. Open Razorpay checkout with order_id.",
  "data": {
    "order_id": "order_Lv32q9c9XQM8bX",
    "key_id": "rzp_test_XXXXXXXXXXXXXX",
    "currency": "INR",
    "base_amount": 9900,
    "tax_percent": 18,
    "tax_amount": 1782,
    "gross_amount": 11682,
    "discount_amount": 1168,
    "referral_discount_percent": 10,
    "final_amount": 10514,
    "local_recharge_id": "60c72b2f9b1d8b001c8e4d1a"
  }
}
```

| Field                       | Type   | Description                                                                              |
|-----------------------------|--------|------------------------------------------------------------------------------------------|
| `order_id`                  | String | Razorpay order ID. Pass this to the checkout SDK.                                         |
| `key_id`                    | String | Razorpay public key ID. Pass to checkout SDK as `key`.                                    |
| `currency`                  | String | Always `INR`.                                                                             |
| `base_amount`               | Number | Pre-tax, pre-discount, in paise.                                                          |
| `tax_percent` / `tax_amount`| Number | GST breakdown.                                                                            |
| `gross_amount`              | Number | `base + tax`, in paise (what the user would have paid without discount).                  |
| `discount_amount`           | Number | Referral discount in paise. `0` if no referral applied.                                   |
| `referral_discount_percent` | Number | Discount % applied (`0` if none).                                                         |
| `final_amount`              | Number | What Razorpay actually charges = `gross - discount`, in paise.                            |
| `local_recharge_id`         | String | Mongo `_id` of the `UserRecharge` row. Use to navigate to `/recharge/{id}/details`.       |

> Store `order_id`, `key_id`, and `final_amount` — pass them to Razorpay checkout in step 3.3.

**Response `400`** — User already has an active recharge.
```json
{
  "success": false,
  "message": "You already have an active recharge. Please consume it before purchasing a new one.",
  "data": { "active_recharge_id": "60c72b2f9b1d8b001c8e4d1a" }
}
```

---

### 3.3 Open Razorpay Checkout in Flutter

Use the [`razorpay_flutter`](https://pub.dev/packages/razorpay_flutter) package — the same one as the subscription flow. The crucial difference: pass `order_id`, **not** `subscription_id`.

**Install**
```yaml
# pubspec.yaml
dependencies:
  razorpay_flutter: ^1.3.6
```

**Flutter Code**
```dart
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RechargePaymentService {
  late Razorpay _razorpay;

  void init() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openRechargeCheckout({
    required String orderId,        // order_XXXXXXXXXXXXXX from /recharge/initiate-order
    required String keyId,          // key_id from /recharge/initiate-order
    required int finalAmountPaise,  // final_amount in paise
    required String planName,       // for the description label
    required String userEmail,
    required String userPhone,
    required String userName,
  }) {
    var options = {
      'key': keyId,
      'order_id': orderId,           // CRITICAL: order_id, NOT subscription_id
      'amount': finalAmountPaise,    // in paise, must match the order amount
      'currency': 'INR',
      'name': 'Beyonder',
      'description': '$planName Recharge',
      'prefill': {
        'contact': userPhone,
        'email': userEmail,
        'name': userName,
      },
      'theme': {
        'color': '#your_brand_color',
      },
    };

    _razorpay.open(options);
  }

  // Called by Razorpay on successful payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Send these three values to your backend's /recharge/verify-payment endpoint
    final paymentId = response.paymentId;   // pay_XXXXXXXXXXXXXX
    final orderId   = response.orderId;     // order_XXXXXXXXXXXXXX
    final signature = response.signature;   // HMAC signature string

    // Call verifyRechargePayment(orderId, paymentId, signature)
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Show error to user — do NOT call /recharge/verify-payment
    print('Recharge payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External wallet: ${response.walletName}');
  }

  void dispose() {
    _razorpay.clear();
  }
}
```

> **Pass `order_id`, not `subscription_id`.** Razorpay treats this as a one-time payment, not a recurring mandate. The amount must match the order amount you created in step 3.2 (`final_amount`). Razorpay will reject the checkout if these don't match.

---

### 3.4 Verify Recharge Payment

Call this immediately after Razorpay's `EVENT_PAYMENT_SUCCESS` callback. Verifies the payment signature and idempotently activates the recharge (initialises the perk quota).

**Request**
```
POST /recharge/verify-payment
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**
```json
{
  "razorpay_order_id":   "order_Lv32q9c9XQM8bX",
  "razorpay_payment_id": "pay_Lv32q9c9XQM8bX",
  "razorpay_signature":  "2b83499fdd8ecb89c2cf5f..."
}
```

| Field                 | Type   | Source                                          |
|-----------------------|--------|-------------------------------------------------|
| `razorpay_order_id`   | String | `response.orderId` from Razorpay success         |
| `razorpay_payment_id` | String | `response.paymentId` from Razorpay success       |
| `razorpay_signature`  | String | `response.signature` from Razorpay success       |

**Response `200`**
```json
{
  "status": "ok",
  "message": "Verified successfully"
}
```

> **Idempotent.** This endpoint and the server-side webhook (`/recharge/webhook/razorpay`) both perform the same activation. The first one wins — duplicates are silently ignored. The frontend can rely on this call returning before showing the "recharge active" UI.

**Response `400`** — Invalid signature OR missing fields.
**Response `404`** — Recharge not found for this order.

---

### 3.5 Check Current Active Recharge

Use this on app launch or before letting the user purchase a new recharge.

**Request**
```
GET /recharge/current
Authorization: Bearer <token>
```

**Response `200`**
```json
{
  "success": true,
  "message": "Current active recharge fetched successfully",
  "data": {
    "_id": "60c72b2f9b1d8b001c8e4d1a",
    "status": "active",
    "isActive": true,
    "razorpay_order_id": "order_Lv32q9c9XQM8bX",
    "razorpay_payment_id": "pay_Lv32q9c9XQM8bX",
    "base_amount": 9900,
    "gross_amount": 11682,
    "discount_amount": 1168,
    "final_amount": 10514,
    "total_perks": 30,
    "perks_remaining": 27,
    "perks_consumed": 3,
    "rechargePlanId": { /* full plan object */ }
  }
}
```

**Response `404`** — No active recharge found.

> **Display suggestion:** show `perks_remaining / total_perks` as a progress indicator. When `perks_remaining` hits 0, the recharge flips to `consumed` and the user can buy a new one.

---

### 3.6 Get All User Recharges

Returns the recharge history for the authenticated user.

**Request**
```
GET /recharge/user-recharges?status=active
Authorization: Bearer <token>
```

**Query Params**

| Param    | Required | Values                                                          |
|----------|----------|-----------------------------------------------------------------|
| `status` | No       | `created`, `active`, `consumed`, `failed`, `cancelled`, `expired` |

**Response `200`**
```json
{
  "success": true,
  "message": "User recharges fetched successfully",
  "data": [ /* array of recharge objects */ ]
}
```

---

### 3.7 Cancel Recharge

Cancels a `created` (unpaid) or `active` recharge in the local DB. Razorpay refunds (for paid recharges) must be handled separately via the dashboard or a future refund flow.

**Request**
```
POST /recharge/cancel
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**
```json
{
  "rechargeId": "60c72b2f9b1d8b001c8e4d1a"
}
```

| Field        | Type   | Description                                                         |
|--------------|--------|---------------------------------------------------------------------|
| `rechargeId` | String | Local MongoDB `_id` of the recharge (NOT the Razorpay order_id).    |

**Response `200`**
```json
{
  "success": true,
  "message": "Recharge cancelled successfully. Note: Razorpay refunds (if applicable) must be processed separately."
}
```

**Response `400`** — Recharge already in a terminal state (`cancelled`, `consumed`, `expired`, `failed`).

---

## 4. Recharge Statuses

| Status      | `isActive` | Meaning                                                  |
|-------------|:----------:|----------------------------------------------------------|
| `created`   | false      | Order created, payment not yet captured                  |
| `active`    | true       | Paid; perks initialised; consumable                      |
| `consumed`  | false      | All perks used up — `perks_remaining = 0`                |
| `failed`    | false      | Razorpay reported `payment.failed`                       |
| `cancelled` | false      | Cancelled via `/recharge/cancel`                         |
| `expired`   | false      | Stale `created` cleaned up by cron after 10 min inactivity |

```
created ──► active ──► consumed
   │           │
   │           └─► cancelled (admin/user)
   │
   ├─► failed   (payment.failed webhook)
   ├─► cancelled (user cancelled before paying)
   └─► expired   (cron cleanup)
```

> A `consumed` recharge does NOT block a new purchase. Only a recharge with `status: 'active'` and `isActive: true` blocks `/recharge/initiate-order`.

---

## 5. Referral Discount UX

The recharge flow supports a configurable referred-user discount that the subscription flow does not offer. The discount is controlled server-side by the env var `RECHARGE_REFERRAL_DISCOUNT_PERCENT` (e.g. `10` = 10% off).

**When the discount applies**
- The user provides (or has parked) a valid referral code.
- The env var is `> 0`.

**When it doesn't**
- No referral code is on the request and no code is parked on the wallet.
- The env var is unset or `0`.

**What the response carries**

When the discount applies, `/recharge/initiate-order` returns:
```
gross_amount      = 11682  (₹116.82 — base + tax)
discount_amount   = 1168   (₹11.68)
final_amount      = 10514  (₹105.14 — what user pays)
referral_discount_percent = 10
```

**Recommended UI**

In the checkout summary, show:
```
Plan price                   ₹99.00
GST 18%                      ₹17.82
Subtotal                     ₹116.82
Referral discount (-10%)    -₹11.68
─────────────────────────────────────
Total payable                ₹105.14
```

When the discount is `0`, hide the discount row entirely.

> The **referrer** still receives a 30% commission of `base_amount` (pre-tax, pre-discount) on payment success — same as the subscription flow. This is paid out of the platform's revenue, not deducted from the buyer's payment.

---

## 6. Error Handling

All error responses follow this shape:

```json
{
  "success": false,
  "message": "Human-readable error message",
  "error": "Technical detail (only in some cases)"
}
```

| HTTP Code | Meaning                                                     |
|-----------|-------------------------------------------------------------|
| `400`     | Bad request — missing fields, invalid data, active recharge already exists |
| `401`     | Unauthorized — missing or expired JWT token                |
| `404`     | Resource not found (plan, recharge)                         |
| `500`     | Server error — retry or contact backend team                |

**Common error cases:**

| Scenario                            | Code | Message                                                                 |
|-------------------------------------|------|-------------------------------------------------------------------------|
| Already has active recharge         | 400  | "You already have an active recharge. Please consume it before purchasing a new one." |
| Invalid Razorpay signature          | 400  | "Invalid signature"                                                     |
| Plan not found                      | 404  | "Recharge plan not found."                                              |
| Plan inactive                       | 400  | "This recharge plan is no longer active."                               |
| Missing required fields             | 400  | "rechargePlanId is required."                                           |
| Recharge already terminal           | 400  | "Recharge is already cancelled and cannot be cancelled."                |

---

## 7. Data Models Reference

### RechargePlan
```
_id              String   — Local MongoDB ID (use as rechargePlanId)
name             String   — Display name
description      String?  — Short description
amount           Number   — Base price in paise, pre-tax
tax_percent      Number   — GST rate (0-100). 0 = no tax.
tax_amount       Number   — Tax portion in paise (amount × tax_percent / 100)
total_amount     Number   — Gross in paise = amount + tax_amount
sac_code         String?  — Service Accounting Code for GST invoice
currency         String   — Always "INR"
tier             String   — basic | popular | advance | pro | proplus
entity_type      String   — Gig Worker | Skill Worker | Food | Grocery | Product | Other
perk_type        String   — rides | leads | sales | range
perk_value       Number   — Primary perk quantity
perk_bonus       Number   — Bonus perk quantity
perks            Array    — Human-readable perks list for display
active           Boolean  — Whether the plan is purchasable
mode             String   — live | test (matches Razorpay mode at creation)
```

### UserRecharge
```
_id                       String   — Local MongoDB ID (use as rechargeId)
user_id                   String   — Owner user ID
rechargePlanId            Object   — Populated plan reference
status                    String   — See status table above
isActive                  Boolean  — true only when status === 'active'
razorpay_order_id         String   — Razorpay order ID (order_XXX)
razorpay_payment_id       String?  — Razorpay payment ID once paid (pay_XXX)
base_amount               Number   — Snapshot of plan.amount at order creation (paise)
tax_percent               Number   — Snapshot of plan.tax_percent at order creation
tax_amount                Number   — Snapshot of plan.tax_amount at order creation (paise)
gross_amount              Number   — base + tax at order creation (paise, pre-discount)
referral_discount_percent Number   — Discount % applied
discount_amount           Number   — Discount in paise (0 if no referral)
final_amount              Number   — gross − discount, in paise (what Razorpay charged)
total_perks               Number   — Frozen at activation = perk_value + perk_bonus
perks_remaining           Number   — Decreases as services consume perks
perks_consumed            Number   — Increases as services consume perks
mode                      String   — live | test
```

---

## 8. Quick Reference — All Endpoints

| Method | Endpoint                              | Auth | Description                              |
|--------|---------------------------------------|:----:|------------------------------------------|
| GET    | `/recharge/plans`                     | ✅   | Fetch active plans (filter by entity_type) |
| POST   | `/recharge/create-plan`               | ✅   | Admin: create a recharge plan            |
| DELETE | `/recharge/plan/:planId`              | ✅   | Admin: delete a recharge plan            |
| POST   | `/recharge/initiate-order`            | ✅   | Create Razorpay order (with optional discount) |
| POST   | `/recharge/verify-payment`            | ✅   | Verify checkout signature → activate recharge |
| GET    | `/recharge/current`                   | ✅   | Get current active recharge              |
| GET    | `/recharge/user-recharges`            | ✅   | List all user recharges                  |
| GET    | `/recharge/:rechargeId/details`       | ✅   | Get one recharge (local + Razorpay)      |
| POST   | `/recharge/cancel`                    | ✅   | Cancel an active or unpaid recharge      |
| POST   | `/recharge/webhook/razorpay`          | —    | Razorpay webhook (server-to-server)      |

---

*Last updated: May 2026 — recharge feature launch*
