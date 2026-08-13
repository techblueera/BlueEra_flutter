# Deposit → Account-Plan Migration — Flutter Guide (UI + flow)

How the app moves an existing **security-deposit holder** onto the new account-plan
system: an **opt-in** bottom sheet (Skip / Migrate → T&C), and a buy-page **active
plan + upgrade-with-credit** section. Backend-only; this doc is the flow/UI contract —
no backend code here.

> **Backend is READY for everything here** — the migrate popup (§1–§3) via
> `GET /migration/eligibility` + `POST /migration/migrate`, and the buy-page
> upgrade-with-credit (§5) via `GET /migration/upgrade-options`,
> `POST /migration/upgrade`, `POST /migration/upgrade/verify`. (All ship once
> `be_subscribe_service` is deployed with the migration code.)

---

## 0. The promise the UI must communicate

- Migration is **free** — the mapped plan activates at ₹0.
- The **deposit is NOT lost** — it stays **refundable** and is **auto-refunded to the
  original payment method on its original date** (held_at + 6 months). Say this
  clearly on both the popup and the T&C sheet, or users will fear losing money.
- Nothing here charges the user. (Charging only happens in the optional §5 upgrade.)

---

## 1. Endpoints

Add to `subscription_service_api.dart`:
```dart
final String accountPlanMigrationEligibility =
    'subscription-service/account-plan/migration/eligibility';
final String accountPlanMigrate =
    'subscription-service/account-plan/migration/migrate';
```

### 1a. `GET /migration/eligibility` — drives the popup
```json
{
  "success": true,
  "data": {
    "eligible": true,
    "already_migrated": false,
    "has_active_plan": false,
    "deposit": {
      "deposit_id": "665f…",
      "amount_inr": 150,
      "refund_eligible_at": "2026-02-11T00:00:00.000Z",
      "refund_after_months": 6,
      "refundable": true
    },
    "plan": {
      "option_code": "RAD_NOGST_1KM",
      "label": "1 km",
      "sublabel": "visible to nearby buyers",
      "archetype": "A1_RADIUS_SHOP",
      "plan_value_inr": 200,
      "deposit_paid_inr": 150,
      "bonus_value_inr": 50,
      "radius_km": 1, "job_types": null, "tier": null
    },
    "tnc_version": "v1"
  }
}
```
- `eligible:false` with `reason` (`no_deposit` | `already_on_plan` | `no_matching_plan`)
  ⇒ **don't show the popup**.
- `plan` = the free plan they'll get (nearest tier **at or above** their deposit).

### 1b. `POST /migration/migrate` — the action (T&C required)
Body: `{ "tnc_accepted": true }`
```json
{
  "success": true,
  "message": "Your plan is now active — free. Your deposit stays refundable and returns automatically on its original date.",
  "data": {
    "account_plan_id": "…",
    "option_code": "RAD_NOGST_1KM",
    "option_label": "1 km",
    "plan_free": true,
    "deposit_refund": {
      "refundable": true, "amount_inr": 150,
      "refund_eligible_at": "2026-02-11T…", "automatic": true,
      "method": "original_payment_method"
    }
  }
}
```
- `success:false` + `message` → show the message, don't proceed. Idempotent: a second
  tap returns `{ already: true }` — treat as success.

Repo methods (match `AccountPlanRepo extends BaseService`):
```dart
Future<ResponseModel> migrationEligibility() =>
    ApiBaseHelper().getHTTP(api.accountPlanMigrationEligibility);

Future<ResponseModel> migrate() => ApiBaseHelper()
    .postHTTP(api.accountPlanMigrate, {"tnc_accepted": true});
```

---

## 2. When/where the popup appears

On the **profile / "me" page** (`initState` / controller `onReady`), call
`migrationEligibility()` **once per session**. If `eligible == true` and the user
hasn't dismissed it this session, show the bottom sheet (`showModalBottomSheet`,
same pattern as `account_plan_gst_sheet.dart`). Persist a "skip" locally so Skip
isn't nagged repeatedly (re-offer on next app open is fine).

---

## 3. The two sheets

### Sheet A — the offer (Skip / Migrate)
```
┌─────────────────────────────────────────────┐
│              Good news 🎉                     │
│                                               │
│  You paid a ₹150 security deposit.            │
│  Upgrade to a FREE lifetime "1 km" plan.      │
│                                               │
│  ✓ Plan activates free                        │
│  ✓ Your ₹150 deposit is safe — auto-refunded  │
│    to your original payment on 11 Feb 2026    │
│                                               │
│   [  Skip  ]           [  Migrate  ]          │
└─────────────────────────────────────────────┘
```
- Values straight from `data.deposit.amount_inr`, `data.plan.label`,
  `data.deposit.refund_eligible_at`.
- **Skip** → dismiss + remember for the session.
- **Migrate** → open Sheet B.

### Sheet B — T&C (accept → migrate)
```
┌─────────────────────────────────────────────┐
│           Terms & Conditions                  │
│  • Your "1 km" plan is activated free.        │
│  • Your ₹150 deposit remains refundable and   │
│    is automatically refunded to your original │
│    payment method on 11 Feb 2026.             │
│  • The plan is a one-time lifetime benefit.   │
│  • {full T&C text — from backend/config}      │
│                                               │
│   ☐ I have read and accept the T&C            │
│   [ Cancel ]        [ Accept & Migrate ]      │
└─────────────────────────────────────────────┘
```
- The **Accept & Migrate** button is enabled only when the checkbox is ticked.
- On tap → `migrate()`. On success → dismiss both sheets, `commonSnackBar` the
  `message`, and refresh the plan/profile (`fetchMyPlans()` / profile reload) so the
  new active plan shows immediately.
- Show `tnc_version` somewhere small; the backend records the accepted version.

Use existing widgets: `CustomText`, `CustomBtn`, `AppColors`, `AppStrings.tr`.

---

## 4. Frontend edge cases

| Case | UI |
|---|---|
| `eligible:false` | no popup at all |
| `already_migrated:true` / `has_active_plan:true` | no popup; the buy page shows the active plan (§5) |
| `migrate()` returns `already:true` | treat as success, refresh |
| network error | keep the sheet, show retry — never leave a half state |
| user taps Migrate twice fast | disable the button while the call is in flight |

---

## 5. Buy / Contribution page — active plan + upgrade-with-credit  ✅ LIVE

For any user **with an active plan**, the buy page shows their active plan and an
**Upgrade** section. The user's **already-paid amount is credited** toward the higher
tier, so they pay only the difference. The credit comes from one of two sources
(the backend decides — the app just renders `price_breakdown`):
- **`current_plan`** — they paid for their current plan (normal proration). **No T&C.**
- **`deposit`** — they migrated from a deposit; the refundable deposit funds the
  upgrade. **T&C required** (using it means it won't be refunded).

### 5a. `GET /account-plan/migration/upgrade-options`
```json
{ "success": true, "data": {
  "has_active_plan": true,
  "active": { "option_code": "RAD_NOGST_1KM", "label": "1 km", "plan_value_inr": 200 },
  "credit_inr": 200, "credit_source": "current_plan", "requires_tnc_if_credit": false,
  "options": [
    { "option_code": "RAD_NOGST_3KM", "label": "3 km",
      "requires_tnc": false,
      "price_breakdown": {
        "plan_price_inr": 450, "current_plan_inr": 200, "credit_applied_inr": 200,
        "credit_source": "current_plan", "taxable_inr": 250,
        "gst_percent": 18, "gst_inr": 45, "pay_total_inr": 295 } }
  ] } }
```
Render each row straight from `price_breakdown`:
```
┌───────────────────────────── Your plan ─────────────────────────────┐
│  ✓ Active: 1 km                                                      │
├──────────────────────────── Upgrade ────────────────────────────────┤
│  3 km    ₹450  − ₹200 already paid  + ₹45 GST  =  Pay ₹295  [Upgrade]│
│  6 km    …                                                           │
└──────────────────────────────────────────────────────────────────────┘
```

### 5b. Upgrade tap → confirmation (always) → T&C (only if `requires_tnc`)
1. Show a **confirmation sheet** with the `price_breakdown`: “Plan ₹450 − already paid
   ₹200 + GST ₹45 = **Pay ₹295**”. This covers edge-case #1 (active plan → upgrade).
2. `POST /account-plan/migration/upgrade { option_code, buyer_state }`.
   - If the response is **`{ requires_tnc: true, data:{ price_breakdown } }`** (deposit
     credit) → show the **T&C sheet** (“your deposit funds this plan and won’t be
     refunded”), then re-POST with **`tnc_accepted: true`**.
   - Else you get the order (below).
3. Success response:
   ```json
   { "order_id": "order_…", "key_id": "rzp_live_…", "total_amount": 29500,
     "total_amount_inr": 295, "credit_source": "current_plan",
     "price_breakdown": { … } }
   ```
   `total_amount` is the **difference only** — open `RazorpayService.openCheckout` with
   that `order_id`/amount, then on success `POST /account-plan/migration/upgrade/verify
   { razorpay_order_id, razorpay_payment_id, razorpay_signature }`. If credit fully
   covers it, the response instead has `upgraded: true` (no Razorpay).

**Critical UX:** at Razorpay the user sees only the difference (`total_amount`). The
confirmation always shows the full breakdown. Only the **deposit** path shows T&C, and
only there does upgrading “spend” refundable money.

---

## 6. Communication (no app work)
Migration also triggers a **push/email** ("Plan activated — deposit safe") and an
in-app **broadcast** in the BlueEra announcement thread, sent by the backend. The app
doesn't send these; it just renders the announcement like any other broadcast.

---

## 7. Build order
1. Ship §1–§4 (migrate popup).
2. Ship §5 (buy-page active plan + upgrade-with-credit). Both halves are backed by
   live endpoints — no flag needed once `be_subscribe_service` is deployed.
