# Business Go-Live — Backend Integration Guide

How the backend must gate a **business** account's *"Go Live"* toggle on a paid
**security deposit**. This is the business-account analogue of the selfWork
go-live gate ([`SELF_WORK_GO_LIVE_FRONTEND_INTEGRATION.md`](./SELF_WORK_GO_LIVE_FRONTEND_INTEGRATION.md)):
a business (grocery, food/restaurant, product, manufacturer, automotive-parts …)
must have **paid (a `held` deposit)** before it can go live and start receiving
orders / enquiries.

> This guide is **backend-facing**: it specifies the contract the app already
> consumes. The Flutter side reads `securityDeposit` off the business profile
> and blocks the toggle when the deposit is required-and-unpaid, routing the
> merchant to the deposit purchase flow (`ContributionScreenV2`). The backend
> must (1) **return** the `securityDeposit` object on the business profile and
> (2) **enforce** the gate on the go-live endpoints.
>
> The deposit itself (plans, payment, refunds) lives in **be_subscribe_service** —
> see [`SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md`](./SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md).
> **This guide only covers the go-live gate.**

---

## 1. How it works (the whole loop)

```
be_user / business service                     be_subscribe_service
──────────────────────────                     ─────────────────────
Business { category_of_business } ─ gRPC ─▶ SecurityDepositService
      account_type = BUSINESS                 • GetDepositRequirementByTag(tag, BUSINESS)
      tag_id       = category                 • CheckUserDepositStatus(user_id, tag)
                                               └─▶ is_held ⇔ business has paid
```

- Every business account is a **`BUSINESS`** account whose deposit **`tag_id` is
  its business `category`** (e.g. `Grocery`, `Restaurant`, `Manufacturer`). The
  subscribe service normalises casing/spacing, so `category` is passed as-is.
- The business service **does not store** deposit state. On every business
  profile read it asks the subscribe service *"has this user paid?"* and returns
  the answer as a **`securityDeposit`** object on the profile.
- It also **enforces** the gate: an unpaid business **cannot go live** (see §4).

The app therefore has **two touch-points**, both of which the backend owns:
1. **Read** `securityDeposit.paid` off the business profile to enable/disable the
   Go-Live toggle.
2. **402** returned by the go-live endpoints when an unpaid business tries to go
   live anyway (the backstop).

---

## 2. The `securityDeposit` object

Return it as a **sibling field on the business profile object**. Shape mirrors
the selfWork gate 1:1 so the app can reuse the same `SecurityDepositStatus`
model.

```jsonc
"securityDeposit": {
  "required": true,            // false ⇔ zero-deposit / exempt category (never blocked)
  "paid": false,              // true ⇔ user holds an active (held) deposit, OR exempt
  "paymentStatus": "created", // raw UserSecurityDeposit.status | null
  "depositId": "66c1...",     // deposit id (null if none yet)
  "refundEligibleAt": null    // ISO date once held; else null
}
```

| Field | Type | Meaning / app use |
|---|---|---|
| `required` | `bool` | `false` → this category owes **no** deposit; **never gate**. |
| `paid` | `bool` | **The gate.** `true` → allow Go-Live. `false` → block + show deposit CTA. |
| `paymentStatus` | `string?` | Raw deposit status (`created`/`held`/`refund_requested`/`refunded`/…). |
| `depositId` | `string?` | The user's deposit id (deep-link into the deposit/refund screen). |
| `refundEligibleAt` | `string?` | ISO date the deposit becomes refundable (once `held`). |

> **Rule of thumb (app side):** the toggle is allowed when
> `securityDeposit == null || securityDeposit.paid == true`.
> It is blocked **only** when `securityDeposit.paid == false`.

### Fail-open contract (required)

If the subscribe service is unreachable, or the tag can't be resolved, return
`paid: true` (never trap a business on an outage). Exempt / zero-deposit
categories also return `required: false, paid: true`. A missing or `paid:true`
value **always means "let them go live."** The app defaults `paid` to `true`
when parsing, so an omitted field is treated as allowed.

---

## 3. Which endpoints must return it

Base prefix: **`/user-service/business`**. Auth: `Authorization: Bearer <JWT>`.

| Endpoint | Where `securityDeposit` must sit |
|---|---|
| `GET /user-service/business/:id`  (own profile — `viewBusinessProfile`) | **top-level on `data`** |
| `GET /user-service/business/:userId` (by user — `bussinessProfileById`) | top-level on `data` |

> The app reads it from `businessProfileDetails.value.data.securityDeposit`
> (`ViewBusinessProfileModel.data`). Discovery / list / map / search endpoints
> intentionally **omit** it — the gate is about the merchant's **own** business.

### Dart model (already implemented in the app)

```dart
// On BusinessProfileDetails (viewBusinessProfileModel.dart):
final sd = json['securityDeposit'];
securityDeposit = sd is Map
    ? SecurityDepositStatus.fromJson(Map<String, dynamic>.from(sd))
    : null;

bool get canGoLive => securityDeposit?.canGoLive ?? true; // null = allow

// SecurityDepositStatus.canGoLive:
bool get canGoLive => !required || paid; // block only when required && !paid
```

`ViewBusinessDetailsController.canGoLive` proxies
`businessProfileDetails.value?.data?.canGoLive ?? true`, and every business
home screen's `handleGoLiveTap()` checks it before opening the shop-availability
form.

---

## 4. Going live (and the 402)

Two endpoints put a business live. The gate must fire on **both**:

| Endpoint | Method | Purpose |
|---|---|---|
| `/user-service/business/availability/hours`  | `PUT`  | Replace the weekly open/close schedule (`businessAvailabilityHours`). |
| `/user-service/business/availability/go-live` | `POST` | Mark the business live for today (`businessGoLive`). |

"Going live" = saving an availability with **at least one open day**
(`schedule[].isOpen == true`) or calling `go-live`. Editing price, photos, etc.
never triggers the gate.

**Request (saving hours → PUT `/availability/hours`):**
```json
{
  "timezone": "Asia/Kolkata",
  "schedule": [
    { "day": "Monday",  "isOpen": true,  "shopOpenTime": "09:00", "shopCloseTime": "21:00" },
    { "day": "Tuesday", "isOpen": false }
  ]
}
```

**If paid (or exempt) → 200**, availability saved.

**If unpaid → 402 Payment Required** — on both `PUT /availability/hours` (when it
opens any day) and `POST /availability/go-live`:
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

The app treats **402** as *"send them to the deposit screen"*, not a generic
error toast. It also pre-checks `securityDeposit.paid` before opening the
availability form, so the 402 is the backstop for a stale client.

---

## 5. Paying the deposit

Purchased against **be_subscribe_service** with the same tag the business service
checks:

- `account_type` = **`BUSINESS`**
- `tag_id` = the business's **`category`** (e.g. `"Grocery"`)

```
POST /security-deposit/initiate { tag_id: <category>, account_type: "BUSINESS" }
   → Razorpay checkout → POST /security-deposit/verify-payment
   → deposit becomes "held"
```

After a successful deposit, the app **re-fetches the business profile**;
`securityDeposit.paid` flips to `true` and Go-Live unlocks.

---

## 6. Checklist (backend)

- [ ] Resolve the deposit tag from the business `category` and check status via
      the subscribe service (`account_type = BUSINESS`).
- [ ] Attach `securityDeposit` (top-level on `data`) to
      `GET /user-service/business/:id` and the by-user profile read.
- [ ] Return `required: false, paid: true` for exempt / zero-deposit categories.
- [ ] Fail-open: on subscribe-service outage or unresolved tag, return
      `paid: true` (never trap a merchant offline).
- [ ] Enforce **402** on `PUT /availability/hours` (when it opens any day) and on
      `POST /availability/go-live`, with the `message` + `securityDeposit` body
      above.
- [ ] Buy the deposit with `tag_id = category`, `account_type = "BUSINESS"`; after
      payment the next profile read reports `paid: true`.
