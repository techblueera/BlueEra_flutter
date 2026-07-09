# Backend Request — Business Go-Live Security-Deposit Gate

**To:** Backend team
**From:** Flutter app team
**Service:** be_user / business service (+ be_subscribe_service for the deposit check)
**Related full spec:** [`BUSINESS_GO_LIVE_BACKEND_INTEGRATION.md`](./BUSINESS_GO_LIVE_BACKEND_INTEGRATION.md)

---

## Summary

The app now gates a **business** account's *"Go Live"* toggle on a paid
**security deposit** — same as the existing selfWork gate. **The client side is
already shipped.** It reads a `securityDeposit` object off the business profile
and blocks go-live when the deposit is required-and-unpaid.

Right now the backend does **not** return that object and does **not** enforce
the gate, so the client is fail-open (never blocks). We need the two changes
below to make the gate real. Until then behaviour is unchanged for merchants.

This applies to all business-account services that use the go-live flow:
**grocery, food/restaurant, product, manufacturer, automotive-parts.**

---

## What's missing (please implement)

### 1. Return `securityDeposit` on the business profile  ⬅ MISSING

Add a `securityDeposit` object **top-level on `data`** in the business-profile
read responses:

- `GET /user-service/business/:id`   (own profile)
- `GET /user-service/business/:userId` (by user)

Resolve it by asking be_subscribe_service whether this user has paid, using:

- `account_type` = **`BUSINESS`**
- `tag_id` = the business's **`category`** (`category_of_business`), passed as-is
  (subscribe service normalises casing/spacing)

**Object shape** (mirror the selfWork gate exactly — the app reuses the same model):

```jsonc
"securityDeposit": {
  "required": true,            // false ⇔ zero-deposit / exempt category (never blocked)
  "paid": false,              // true ⇔ user holds an active (held) deposit, OR exempt
  "paymentStatus": "created", // raw UserSecurityDeposit.status | null
  "depositId": "66c1...",     // deposit id (null if none yet)
  "refundEligibleAt": null    // ISO date once held; else null
}
```

| Field | Type | Rule |
|---|---|---|
| `required` | `bool` | `false` → category owes no deposit; never gate. |
| `paid` | `bool` | The gate. `true` → allow go-live. `false` → block. |
| `paymentStatus` | `string?` | Raw deposit status, for messaging. |
| `depositId` | `string?` | Deposit id (null if none yet). |
| `refundEligibleAt` | `string?` | ISO date, once `held`; else null. |

**Fail-open (required):** if be_subscribe_service is unreachable or the tag can't
be resolved, return `paid: true`. Exempt / zero-deposit categories return
`required: false, paid: true`. Never trap a merchant offline on an outage.

### 2. Enforce the gate with 402 on go-live  ⬅ MISSING

Return **402 Payment Required** when an unpaid business tries to go live, on
**both** endpoints:

| Endpoint | Method | Fires when |
|---|---|---|
| `/user-service/business/availability/hours`  | `PUT`  | the saved schedule opens **any** day (`schedule[].isOpen == true`) |
| `/user-service/business/availability/go-live` | `POST` | always (this call means "go live now") |

Editing price / photos / closed-only schedules must **not** trigger it.

**402 body** (the app routes this to the deposit screen — do not send a generic error):

```json
{
  "message": "Your payment is incomplete. Please complete the security deposit to go live and receive service enquiries.",
  "securityDeposit": {
    "required": true,
    "paid": false,
    "paymentStatus": "created",
    "depositId": null,
    "refundEligibleAt": null
  }
}
```

---

## Deposit purchase (already exists — for reference)

The merchant pays via be_subscribe_service with the same tag you check:

```
POST /security-deposit/initiate { tag_id: <category>, account_type: "BUSINESS" }
   → Razorpay → POST /security-deposit/verify-payment  → deposit becomes "held"
```

After payment the next business-profile read must report `paid: true`, which
unlocks go-live in the app.

---

## Acceptance checklist

- [ ] `securityDeposit` present, top-level on `data`, for `GET /business/:id` and the by-user read.
- [ ] Tag resolved from `category_of_business`; `account_type = BUSINESS`.
- [ ] Exempt / zero-deposit categories → `required: false, paid: true`.
- [ ] Fail-open on subscribe-service outage / unresolved tag → `paid: true`.
- [ ] `PUT /availability/hours` returns 402 (body above) when it opens any day and the deposit is `required && !paid`.
- [ ] `POST /availability/go-live` returns 402 (body above) when `required && !paid`.
- [ ] After a successful deposit, the next profile read flips `paid` to `true`.

---

## How the app consumes it (context, no action needed)

```dart
// BusinessProfileDetails.securityDeposit parsed from data.securityDeposit
bool get canGoLive => securityDeposit?.canGoLive ?? true;      // null = allow
// SecurityDepositStatus
bool get canGoLive => !required || paid;                        // block only when required && !paid
```

`handleGoLiveTap()` on every business home screen checks
`viewBusinessDetailsController.canGoLive` first; if `false` it shows the message
and opens the deposit flow instead of the shop-availability form. The 402 is the
server-side backstop for a stale client.
