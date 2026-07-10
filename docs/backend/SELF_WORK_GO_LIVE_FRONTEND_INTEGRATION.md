# Self-Work Go-Live — Frontend Integration Guide (Flutter)

How to gate the **selfWork** provider's *"Go Live"* toggle on a paid **security
deposit**. This is the self-employed analogue of the rider go-live gate: a
selfWork provider must have **paid (a `held` deposit)** before they can go live
and start receiving **service enquiries**.

> Source of truth (this service — `be_earn_with_blueera_service`):
> [`service.controller.js`](./src/controllers/service.controller.js),
> [`securityDeposit.js`](./src/utils/securityDeposit.js),
> [`securityDeposit.client.js`](./src/grpc/clients/securityDeposit.client.js).
>
> The deposit itself (plans, payment, refunds) lives in **be_subscribe_service** —
> see [`SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md`](./SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md)
> for the purchase flow. **This guide only covers the go-live gate.**

---

## 1. How it works (the whole loop)

```
be_earn service (this repo)                    be_subscribe_service
─────────────────────────────                  ─────────────────────
selfWork Service { category }  ── gRPC ──▶ SecurityDepositService
      account_type = INDIVIDUAL              • GetDepositRequirementByTag(tag,INDIVIDUAL)
      tag_id       = category                • CheckUserDepositStatus(user_id, tag)
                                              └─▶ is_held ⇔ user has paid
```

- Every selfWork provider is an **`INDIVIDUAL`** account whose deposit **`tag_id`
  is their `category`** (their profession — e.g. `Electrician` → `ELECTRICIAN`).
  The backend normalises casing/spacing, so `category` is passed through as-is.
- The backend **does not store** deposit state. On every **individual-profile
  read** it asks the subscribe service *"has this user paid?"* and returns the
  answer as a **`securityDeposit`** object **on the profile** — exactly the same
  pattern the business gate uses on the business profile.
- It also **enforces** the gate server-side: an unpaid provider **cannot save an
  "open" availability / go live** (see §4).

> **Changed:** the `securityDeposit` object used to be returned on the **selfWork
> service** object (`GET /services`). It now lives on the **individual profile**
> so the app reads it from one place (mirroring business). The service object no
> longer needs to carry it.

You therefore have **two touch-points**:
1. **Read** `securityDeposit.paid` on the **individual profile** to decide whether
   to enable the Go-Live toggle (and what to show).
2. **Handle the 402** the backend returns if an unpaid provider tries to go live
   anyway.

---

## 2. The `securityDeposit` object

Returned as a **sibling field on the individual profile object** (top-level,
alongside `user`) — exactly where the business gate sits on the business profile.

```jsonc
"securityDeposit": {
  "required": true,            // false ⇔ zero-deposit / exempt tag (never blocked)
  "paid": false,              // true ⇔ user holds an active (held) deposit, OR exempt
  "paymentStatus": "created", // raw UserSecurityDeposit.status | null
  "depositId": "66c1...",     // deposit id (null if none yet)
  "refundEligibleAt": null    // ISO date once held; else null
}
```

| Field | Type | Meaning / UI use |
|---|---|---|
| `required` | `bool` | `false` → this profession owes **no** deposit; **do not gate**, treat as free to go live. |
| `paid` | `bool` | **The gate.** `true` → allow Go-Live. `false` → block + show the deposit CTA. |
| `paymentStatus` | `string?` | Raw deposit status (`created`/`held`/`refund_requested`/`refunded`/…) for precise messaging. |
| `depositId` | `string?` | The user's deposit id (useful to deep-link into the deposit/refund screen). |
| `refundEligibleAt` | `string?` | ISO date the deposit becomes refundable (once `held`). |

> **Rule of thumb:** the toggle is allowed when
> `securityDeposit == null || securityDeposit.paid == true`.
> It is blocked **only** when `securityDeposit.paid == false`.

### Fail-open contract

If the subscribe service is unreachable, or the tag can't be resolved, the
backend returns `paid: true` (never traps a provider on an outage). Exempt /
zero-deposit tags also return `required: false, paid: true`. So a missing or
`paid:true` value **always means "let them go live."**

---

## 3. Which endpoint returns it

The **individual profile** read — the same endpoint that already returns `user`,
`earnProfileTypes`, etc. Auth: `Authorization: Bearer <JWT>`.

| Endpoint | Where `securityDeposit` sits |
|---|---|
| `GET` individual profile (own — the `PersonalProfileDetailsModel` read) | **top-level** on the profile object, next to `user` |

```jsonc
{
  "status": true,
  "user": { /* … */ },
  "earnProfileTypes": ["home_made_food"],
  "securityDeposit": {          // ← the gate, here (not on /services anymore)
    "required": true,
    "paid": false,
    "paymentStatus": "created",
    "depositId": null,
    "refundEligibleAt": null
  }
}
```

> Discovery/list/map/search endpoints intentionally **omit** it — the gate is
> about the provider's **own** account. The selfWork **service** object
> (`GET /services`) no longer needs to carry `securityDeposit`.

### Dart model (already implemented in the app)

```dart
// PersonalProfileDetailsModel (lib/core/api/model/personal_profile_details_model.dart):
final sd = json['securityDeposit'];
securityDeposit = sd is Map
    ? SecurityDepositStatus.fromJson(Map<String, dynamic>.from(sd))
    : null;
bool get canGoLive => securityDeposit?.canGoLive ?? true; // null = allow

// SecurityDepositStatus.canGoLive:  !required || paid  (block only when required && !paid)
```

`ViewPersonalDetailsController.canGoLive` proxies
`personalProfileDetails.value.canGoLive`, and the self-employed dashboard's
`_handleGoLiveTap()` checks it before going live — identical to the business
`ViewBusinessDetailsController.canGoLive` gate.

---

## 4. Going live (and the 402)

"Going live" = a `PUT /services/:id` whose `availability` has **at least one open
day** (`schedule[].isOpen == true`) or an open `specialOverride`. The gate fires
**only** on such a request — editing price, photos, etc. never triggers it.

**Request (going live):**
```json
PUT /services/66c1...
{
  "availability": {
    "schedule": [
      { "day": "Monday", "isOpen": true,  "timeSlots": [{ "startTime": "10:00", "endTime": "19:00" }] },
      { "day": "Tuesday", "isOpen": false }
    ]
  }
}
```

**If paid (or exempt) → 200**, service saved, `response.service.securityDeposit`
reflects the current status.

**If unpaid → 402 Payment Required:**
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

Treat **402** as *"send them to the deposit screen"* — not a generic error toast.

```dart
Future<void> goLive(String serviceId, Map<String, dynamic> availability) async {
  try {
    final res = await dio.put('/services/$serviceId', data: {'availability': availability});
    // 200 → live. Refresh the service; res.data['service']['securityDeposit'] is fresh.
  } on DioException catch (e) {
    if (e.response?.statusCode == 402) {
      // Unpaid: open the security-deposit purchase flow (see §5).
      final sd = e.response?.data['securityDeposit'];
      openDepositFlow(paymentStatus: sd?['paymentStatus']);
      return;
    }
    rethrow;
  }
}
```

> **Best UX:** don't rely on the 402 alone. Read `securityDeposit.paid` when the
> screen loads and **pre-disable** the toggle (show a "Pay deposit to go live"
> banner) so the user never hits the 402 by surprise. The 402 is the backstop.

---

## 5. Sending the user to pay

The deposit is purchased against **be_subscribe_service**, using the same
`tag_id`/`account_type` this service used to check:

- `account_type` = **`INDIVIDUAL`**
- `tag_id` = the service's **`category`** (e.g. `"Electrician"`)

Drive the existing deposit purchase flow from
[`SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md`](./SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md):

```
POST /security-deposit/initiate { tag_id: <category>, account_type: "INDIVIDUAL" }
   → Razorpay checkout → POST /security-deposit/verify-payment
   → deposit becomes "held"
```

After a successful deposit, **re-fetch the service** (e.g. `GET /services/:id`);
`securityDeposit.paid` will now be `true` and Go-Live is unlocked.

---

## 6. Recommended Flutter flow

```
┌─ selfWork dashboard ──────────────────────────────────────────────┐
│ 1. GET individual profile                                          │
│      → read profile.securityDeposit                                │
│                                                                    │
│ 2. if securityDeposit == null || paid == true                      │
│        → enable "Go Live" toggle                                   │
│    else (required && !paid)                                        │
│        → disable toggle, show "Complete security deposit to go     │
│          live and receive service enquiries" + [Pay Deposit] CTA   │
│                                                                    │
│ 3. [Pay Deposit] → POST /security-deposit/initiate                 │
│        {tag_id: category, account_type: "INDIVIDUAL"}              │
│        → Razorpay → /verify-payment  (subscribe service)           │
│                                                                    │
│ 4. Re-fetch service → paid == true → enable toggle                 │
│                                                                    │
│ 5. Go Live → PUT /services/:id { availability: {schedule…isOpen} } │
│        200 → live   |   402 → back to step 3                       │
└────────────────────────────────────────────────────────────────────┘
```

---

## 7. Checklist

- [ ] Return & parse `securityDeposit` on the **individual profile** read
      (top-level, next to `user`) — not on the selfWork service anymore.
- [ ] Enable Go-Live when `securityDeposit == null || paid == true`; block only on
      `required && !paid`.
- [ ] Handle **402** on `PUT /services/:id` → open the deposit flow (don't toast).
- [ ] Buy the deposit with `tag_id = category`, `account_type = "INDIVIDUAL"`.
- [ ] After payment, re-fetch the service so `paid` flips to `true`.
- [ ] Never block when the field is absent (fail-open) or `required == false`
      (zero-deposit provider).
