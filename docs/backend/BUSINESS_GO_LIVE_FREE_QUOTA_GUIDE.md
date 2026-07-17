# Business Go-Live — Free Intro Quota (`freeOrdersUsed`)

**One-line ask:** waive the security deposit for a business's **first N orders /
enquiries** (policy: **N = 2**), exactly as `freeRideUsed` does for riders and
`freeServiceUsed` does for self-work providers. Expose one boolean on the
business profile; the client already reads it.

**Client status: done and merged.** Ship the field and the waiver goes live with
no app release. Until then `freeOrdersUsed` is absent → the waiver never fires →
today's behaviour is unchanged (deposit enforced as now).

Companion docs — read alongside, don't duplicate:
- `BUSINESS_GO_LIVE_BACKEND_GUIDE.md` — the deposit gate + availability endpoints this extends.
- `SELF_WORK_GO_LIVE_GUIDE.md` — the individual twin (`freeServiceUsed`); this doc mirrors its §2.
- `RIDER_GO_LIVE_GUIDE.md` — the original waiver (`freeRideUsed`).
- `SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md` — the deposit *purchase* flow. ⚠️ see §6.

---

## 1. Why

Today a business must pay the security deposit before it can go live at all —
so a new merchant pays before earning a single rupee. The free quota lets them
take their first **2 orders/enquiries** first, then pay.

This is the same shape the other two profile types already have. Business was
the only one missing it:

| Profile | Waiver flag | Where it lives | Status |
|---|---|---|---|
| Rider | `freeRideUsed` | rider onboarding status | ✅ live |
| Self-work / professional | `freeServiceUsed` | individual profile | ✅ live |
| **Business** | **`freeOrdersUsed`** | **business profile** | ❌ **this doc** |

---

## 2. The one field

Add to the business profile read, **top-level on `data`, beside
`securityDeposit`**:

```jsonc
{
  "data": {
    "business_name": "RK Medical Store",
    "securityDeposit": {
      "required": true,
      "paid": false,
      "paymentStatus": "pending",
      "depositId": "dep_123",
      "refundEligibleAt": null
    },

    // ── ADD THIS ──
    "freeOrdersUsed": false,      // false = quota REMAINS → deposit waived
    "freeOrdersRemaining": 2      // optional, display copy only (see 2.3)
  }
}
```

### 2.1 Semantics — must match exactly

| `freeOrdersUsed` | Meaning | Effect on go-live |
|---|---|---|
| `false` | Free quota remains | **Deposit waived** — allow go-live |
| `true` | Quota spent | Deposit enforced normally |
| absent / `null` | Unknown | **Deposit enforced** (safe default) |

**Absence must mean enforce.** The client is fail-**closed** here:

```dart
bool get isFreeQuotaAvailable => freeOrdersUsed == false;
```

⚠️ **This is the opposite of `securityDeposit`, deliberately.** The deposit
object fails **open** (`paid` defaults to `true`; absent deposit → allowed) so a
backend outage never locks merchants out. The waiver fails **closed** so a
backend outage never hands out free access. Both asymmetries are intentional and
match the rider / self-work contracts — please don't "fix" either.

### 2.2 The client is N-agnostic — on purpose

**N (=2) lives entirely in the backend.** The client never counts, never sees a
threshold, and must never need a release to change it. It asks one question —
*"is there quota left?"* — and you answer with the boolean. Want to move to 5
free orders, or run a promo? Change the policy server-side; the app follows.

So: **do not** send `freeOrdersLimit` expecting the client to compare it against
a count. The boolean is the contract.

### 2.3 `freeOrdersRemaining` — optional, display only

Send it if you want the UI to say "1 free order left". It is **never** gated on:
a backend that ships `freeOrdersUsed` but omits the count still behaves
correctly. If you send it, it must agree with the boolean
(`freeOrdersRemaining > 0` ⇔ `freeOrdersUsed == false`) — the app will not
reconcile a contradiction, it will just trust the boolean.

---

## 3. When does it flip to `true`?

Compute **live** on every business-profile read. Per business id. **Monotonic** —
once `true`, never back to `false` (barring a deliberate admin/promo reset).

⚠️ **Consumed = the order / enquiry actually happened — NOT "went live".**

This is the single most important line in the doc, and the one the rider and
self-work guides both call out. If the flag flips when the merchant *goes live*,
they burn the quota by toggling the pill, get locked out on the very next tap,
and never receive the free orders you promised. Count **completed orders /
received enquiries**, not availability changes.

Concretely, with N = 2: `freeOrdersUsed = (completedOrderOrEnquiryCount >= 2)`.

**Decide and document what counts as one unit** — the app can't tell, and the
merchant-facing copy says "orders or enquiries":
- a completed self-pickup order?
- an order placed but later cancelled?
- an enquiry that never converts?

Whatever you choose, apply it identically to the counter and to any UI copy
driven by `freeOrdersRemaining`.

---

## 4. Enforce it server-side too

The client gate is UX, not security. `PUT /availability/hours` and
`PUT /availability/today` must apply the same rule and return **402** with the
unchanged `securityDeposit` body when it fails:

```
allow go-live  ⇔  !securityDeposit.required
                   || securityDeposit.paid
                   || freeOrdersUsed == false      // ← the waiver
```

### 4.1 Truth table

| `required` | `paid` | `freeOrdersUsed` | Result |
|---|---|---|---|
| `false` | — | — | ✅ 200 — no deposit needed |
| `true` | `true` | — | ✅ 200 — paid |
| `true` | `false` | `false` | ✅ 200 — **waived by quota** |
| `true` | `false` | `true` | ⛔ 402 — quota spent, unpaid |
| `true` | `false` | absent | ⛔ 402 — unknown → enforce |

### 4.2 Scope

Return `freeOrdersUsed` **only on the owner's own business profile read**. Omit
it from discovery / list / map / other-user reads — it's private merchant
billing state, and no customer-facing surface needs it.

---

## 5. Frontend — already implemented

| File | Change |
|---|---|
| `viewBusinessProfileModel.dart` | parses `freeOrdersUsed` + `freeOrdersRemaining`; `bool get isFreeQuotaAvailable => freeOrdersUsed == false` |
| `view_business_details_controller.dart` | `isFreeQuotaAvailable` proxy + `bool get isGoLiveAllowed => canGoLive \|\| isFreeQuotaAvailable` |
| `view_business_details_controller.dart` | `ensureCanGoLive()` → gates on `isGoLiveAllowed`; on return from the deposit screen, refreshes the profile |
| `view_business_details_controller.dart` | `_recomputeShopStatus()` → `isLive` uses `isGoLiveAllowed` |
| `view_business_details_controller.dart` | `_applyTodayOverride()` → same gate |

> **One gate, 13 screens.** Every business home screen (grocery, food, medical,
> hotel, hospital, lab, school, vehicle, product, manufacturer, automotive ×2,
> others) delegates its Go-Live pill to `openAvailabilityControl()`, which runs
> `ensureCanGoLive()`. No per-screen work was needed and none should be added.

> **Three consumers, not one.** `canGoLive` is read in the gate, in the pill's
> `isLive` computation, and in the today-override. All three now read
> `isGoLiveAllowed` — if only the gate had the waiver, a quota-covered merchant
> would pass the sheet but the pill would still render "not live". Worth knowing
> if you touch this.

**Professionals** (`professionals_main.dart`) are individuals, not businesses:
they gate on the *personal* profile and already have the waiver via
`freeServiceUsed` (see `SELF_WORK_GO_LIVE_GUIDE.md`). They do **not** read
`freeOrdersUsed`. If professionals should also get 2 free instead of 1, change
the threshold behind `freeServiceUsed` — no client change, same N-agnostic
contract as §2.2.

---

## 6. ⚠️ Open question — collision with `first_day_free_limit`

`SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md` already documents a **different**
"first N free" concept on the deposit plan catalog:

```jsonc
"first_day_free_text": "Unlimited Orders (Day 1)",
"first_day_free_limit": null,          // null = unlimited
"first_day_free_unlimited": true,
"postpaid_charge_per_unit": 1000,      // paise, beyond the free limit
"base_metric": "Per Completed Order"
```

It is **display-only today** — the client renders "First N free" on the plan card
and nothing reads it for gating. But note the mismatch:

| | `first_day_free_limit` | `freeOrdersUsed` (this doc) |
|---|---|---|
| Period | **per day** | **lifetime** (first 2 ever) |
| Purpose | plan marketing copy | go-live gate |
| Enforced? | no | yes (§4) |

**Please decide explicitly** whether the new quota replaces, composes with, or is
orthogonal to `first_day_free_limit` — and say so in whichever doc wins.
Otherwise two "first N free" concepts coexist with different periods and neither
doc says which applies. If they're meant to be the same thing, this quota should
probably derive from the plan's limit rather than being a second hard-coded 2.

---

## 7. Acceptance checklist

**Field**
- [ ] `freeOrdersUsed` (bool) on the owner's business-profile read, beside `securityDeposit`
- [ ] Omitted from discovery / list / map / other-user reads
- [ ] Optional `freeOrdersRemaining` (int) agrees with the boolean, if sent
- [ ] N lives server-side only — no threshold shipped to the client

**Counting**
- [ ] Flips on the 2nd **completed order / received enquiry** — NOT on go-live
- [ ] Monotonic; per business id; computed live on each read
- [ ] "One unit" defined and documented (cancelled orders? unconverted enquiries?)

**Enforcement**
- [ ] `PUT /availability/hours` applies the §4 rule
- [ ] `PUT /availability/today` applies the §4 rule
- [ ] 402 + unchanged `securityDeposit` body when it fails
- [ ] Absent flag ⇒ enforce (never waive)

**Verify end-to-end**
- [ ] Fresh business, deposit `required && !paid`, `freeOrdersUsed: false` → pill goes live, sheet opens, hours save (200)
- [ ] Same business after 2 orders → `freeOrdersUsed: true` → tap shows the deposit message, routes to the deposit screen, `PUT` returns 402
- [ ] Pay the deposit → returning from the deposit screen refreshes the profile → go-live works
- [ ] Omit `freeOrdersUsed` entirely → behaviour identical to today (deposit enforced)
- [ ] Quota-covered business: the pill actually **renders live** inside its scheduled hours (catches the `isLive` path, §5)
