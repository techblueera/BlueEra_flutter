# Self-Work Go-Live — Single Integration Guide

The **one** guide for the self-employed (**selfWork** / `INDIVIDUAL`) provider's
*"Go Live"* story. It consolidates what used to be three separate docs:

1. the **security-deposit gate** (a provider must have paid before going live),
2. the **first-service-free waiver** (`freeServiceUsed`) that waives the gate for
   the first go-live, and
3. the **client-side auto go-live** scheduler (daily auto open/close).

> Deposit purchase itself (plans, Razorpay, refunds) lives in
> **be_subscribe_service** — see
> [`SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md`](./SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md)
> (shared across business / professional / self-work / rider). This guide covers
> only the **go-live gate + waiver + auto-scheduler**. The rider analogue is
> [`RIDER_GO_LIVE_GUIDE.md`](./RIDER_GO_LIVE_GUIDE.md).

Owning service: **`be_earn_with_blueera_service`** (individual profile + go-live).
Deposit state lives in **`be_subscribe_service`**.

---

# Part 1 — The security-deposit gate

## 1.1 How it works

```
be_earn service                                be_subscribe_service
─────────────────────────────                  ─────────────────────
selfWork Service { category }  ── gRPC ──▶ SecurityDepositService
      account_type = INDIVIDUAL              • GetDepositRequirementByTag(tag,INDIVIDUAL)
      tag_id       = category                • CheckUserDepositStatus(user_id, tag)
                                              └─▶ is_held ⇔ user has paid
```

- Every selfWork provider is an **`INDIVIDUAL`** account whose deposit **`tag_id`
  is their `category`** (their profession — e.g. `Electrician`). The backend
  normalises casing/spacing.
- The backend **does not store** deposit state. On every **individual-profile
  read** it asks the subscribe service *"has this user paid?"* and returns the
  answer as a **`securityDeposit`** object **on the profile** (same pattern as the
  business gate).
- It also **enforces** the gate server-side: an unpaid provider **cannot save an
  "open" availability / go live** (§1.4).

## 1.2 The `securityDeposit` object

Returned as a **top-level sibling on the individual profile** (next to `user`).

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
| `required` | `bool` | `false` → no deposit owed; **do not gate**. |
| `paid` | `bool` | **The gate.** `true` → allow Go-Live. `false` → block + deposit CTA. |
| `paymentStatus` | `string?` | Raw status (`created`/`held`/`refund_requested`/…) for messaging. |
| `depositId` | `string?` | Deposit id (deep-link to deposit/refund screen). |
| `refundEligibleAt` | `string?` | ISO date the deposit becomes refundable (once `held`). |

**Fail-open contract:** if the subscribe service is unreachable or the tag can't
be resolved, the backend returns `paid: true` (never traps a provider on an
outage). Exempt / zero-deposit tags return `required: false, paid: true`. So a
missing or `paid:true` value **always means "let them go live."**

> **Rule of thumb:** allowed when `securityDeposit == null || paid == true`;
> blocked **only** when `paid == false`.

## 1.3 Which endpoint returns it

The provider's **own individual-profile read** (the `PersonalProfileDetailsModel`
read), `Authorization: Bearer <JWT>`, top-level next to `user`. Discovery / list
/ map / search intentionally **omit** it — the gate is about the caller's **own**
account.

```dart
// PersonalProfileDetailsModel (lib/core/api/model/personal_profile_details_model.dart):
final sd = json['securityDeposit'];
securityDeposit = sd is Map ? SecurityDepositStatus.fromJson(...) : null;
bool get canGoLive => securityDeposit?.canGoLive ?? true; // null = allow
// SecurityDepositStatus.canGoLive:  !required || paid   (block only when required && !paid)
```

`ViewPersonalDetailsController.canGoLive` proxies
`personalProfileDetails.value.canGoLive`.

## 1.4 Going live (and the 402)

"Going live" = a `PUT /services/:id` whose `availability` has **at least one open
day** (`schedule[].isOpen == true`) or an open `specialOverride`. The gate fires
**only** on such a request — editing price/photos never triggers it.

- **Paid / exempt → 200**, service saved.
- **Unpaid → 402 Payment Required:**
```json
{
  "message": "Your payment is incomplete. Please complete the security deposit to go live and receive service enquiries.",
  "securityDeposit": { "required": true, "paid": false, "paymentStatus": "created", "depositId": null, "refundEligibleAt": null }
}
```

Treat **402** as *"send them to the deposit screen"*, not a generic toast. Best
UX: read `securityDeposit.paid` on load and pre-disable the toggle; the 402 is
the backstop.

## 1.5 Sending the user to pay

Purchase against **be_subscribe_service** with `account_type = "INDIVIDUAL"`,
`tag_id = category`:
```
POST /security-deposit/initiate { tag_id: <category>, account_type: "INDIVIDUAL" }
   → Razorpay checkout → POST /security-deposit/verify-payment → deposit "held"
```
After success, re-fetch the profile/service; `paid` flips to `true`.

---

# Part 2 — First service free (`freeServiceUsed`)

**Goal:** give every selfWork provider **one free go-live**. While available, the
deposit gate is **waived**. After it's used, the deposit is enforced on every
subsequent go-live. Self-employed analogue of the rider **first-ride-free**
waiver (`freeRideUsed`).

## 2.1 The one field

Add a single boolean **`freeServiceUsed`** to the **individual-profile response**,
top-level next to `securityDeposit`:

```jsonc
{ "...": "...",
  "securityDeposit": { "required": true, "paid": false, "...": "..." },
  "freeServiceUsed": false }   // false → first free go-live available
```

## 2.2 Semantics (must match exactly)

| `freeServiceUsed` | Meaning | Deposit gate |
|---|---|---|
| `false` | first go-live is free | **waived** (allow even if `required && !paid`) |
| `true` | free go-live used | **enforced** (normal deposit gate) |
| omitted / `null` | unknown / old data | **enforced** (safe default) |

**Rule:** only an explicit `false` waives the gate. **Absence must mean
"enforce."** Note the deliberate asymmetry with `securityDeposit`, which
fail-**opens** — `freeServiceUsed` fail-**closes** because it's the permissive
side and must not leak.

## 2.3 When does it flip to `true`?

Flip to `true` once the provider **completes/accepts their first job** (first
accepted service/artist enquiry, accepted home-stay booking, or completed
home-made-food/tiffin order). Requirements:
- **Compute live** from history on each profile read (don't rely on a one-time
  write that can drift). Same approach as the rider `freeRideUsed`.
- **Monotonic**: once `true`, stays `true`.
- Per provider account (`INDIVIDUAL`, keyed by user id).
- ⚠️ **"Consumed" = completed/accepted a job, NOT went live.** Going live must
  not flip the flag, or the provider is blocked the moment they re-open the
  toggle.

## 2.4 Enforce the waiver server-side on go-live

```
allow go-live  ⇔  !securityDeposit.required
                   || securityDeposit.paid
                   || freeServiceUsed == false        // ← waiver
```
- `freeServiceUsed == false` → the go-live PUT must **succeed (200)** even when
  unpaid.
- Otherwise → **402** with the `securityDeposit` body (message unchanged).

The profile `freeServiceUsed` and the go-live enforcement **must use the same
rule**. Server stays authoritative; the frontend pre-checks the same condition to
avoid a surprise 402.

## 2.5 Go-live truth table

| `required` | `paid` | `freeServiceUsed` | Go-live result |
|---|---|---|---|
| false | — | — | **200** (no deposit owed) |
| true | true | — | **200** (paid) |
| true | false | `false` | **200** (first free) |
| true | false | `true` | **402** (enforce) |
| true | false | absent/`null` | **402** (safe default) |

---

# Part 3 — Client-side auto go-live (scheduler)

**Best-effort, client-only.** Unlike the rider auto-go-live (which has an
authoritative backend cron), the self-work auto-scheduler currently runs **only
while the app is open**. If the app is killed, nothing fires. A backend cron is
NOT yet built for self-work — see [To build](#to-build-backend-cron-optional).

## 3.1 Behaviour (implemented)

`SelfWorkAutoGoLiveScheduler`
(`lib/features/personal/personal_profile/service/self_work_auto_golive_scheduler.dart`):

- **Opt-in:** after the provider's **first successful manual go-live**, they're
  opted into a recurring daily window (persisted per-user in secure storage).
- **Window:** **08:00–22:00** (8 AM → 10 PM) device-local, end-exclusive. Same
  window as the rider scheduler.
- **Per-minute evaluator** while the self-employed screen is open: auto-opens
  inside the window and auto-closes at window end.
- **Gate parity:** auto-open uses the **same gate as the manual tap** —
  `canGoLive || isFirstServiceFree` + required permissions granted.
- **Mid-session close:** if the deposit/gate stops holding (payment expiry,
  first-service-free consumed), window ends, or the provider manually goes
  offline, its own auto-session is closed. Never force-closes a manual session.
- **Manual-off = that day only:** tapping offline inside the window suppresses
  auto-open for the rest of the day; it resumes the next day.
- **Idempotent:** the go-live API is sent once per auto-session.
- Logs everything under the `[SelfWorkAutoGoLive]` tag.

## 3.2 To build (backend cron — optional)

To cover the **app-killed** case (auto go-live when the provider isn't in the
app), mirror the rider design from
[`RIDER_GO_LIVE_GUIDE.md`](./RIDER_GO_LIVE_GUIDE.md):

- Schedule endpoints + opt-in / manual-off-today persistence for `INDIVIDUAL`.
- An authoritative cron over `[08:00, 22:00)` IST that opens eligible providers
  (`canGoLive || freeServiceUsed == false`) and closes at window end.
- Same gate + per-day manual-off + mid-session-close rules as the client.

Until that exists, self-work auto go-live is foreground-only best-effort.

---

# Part 4 — Frontend status (already implemented)

For reference so both sides agree on the contract.

- **Model** — `PersonalProfileDetailsModel`
  (`lib/core/api/model/personal_profile_details_model.dart`): parses
  `securityDeposit` and `freeServiceUsed` (accepts `freeRideUsed` alias);
  `canGoLive = !required || paid` (null → allow), `isFirstServiceFree =
  freeServiceUsed == false`. Neither is serialized back (cache-safe).
- **Controller** — `ViewPersonalDetailsController`: `canGoLive`,
  `isFirstServiceFree` proxies.
- **Manual gate** — `self_employee_screen.dart` `_handleGoLiveTap()`:
  `depositBlocked = !canGoLive && !isFirstServiceFree` → deposit snackbar +
  `ContributionScreenV2`, then `viewPersonalProfile(forceRefresh: true)`.
- **Auto-scheduler** — `SelfWorkAutoGoLiveScheduler` wired in
  `self_employee_screen.dart` (`initState` resume, opt-in on first go-live,
  manual-off note).

> **Field naming:** canonical key is **`freeServiceUsed`**; the app also accepts
> **`freeRideUsed`** as an alias, but please emit `freeServiceUsed` on the
> individual profile.

---

# Part 5 — Backend acceptance checklist

Deposit gate:
- [ ] Return & parse `securityDeposit` on the **individual profile** (top-level).
- [ ] Allow go-live when `securityDeposit == null || paid == true`; block only on
      `required && !paid`.
- [ ] `PUT /services/:id` returns **402** (not a toast) when blocked.
- [ ] Buy deposit with `tag_id = category`, `account_type = "INDIVIDUAL"`.

First service free:
- [ ] `GET` own profile returns `freeServiceUsed` (boolean), next to
      `securityDeposit`; `absent ⇒ enforce`.
- [ ] Computed live + monotonic; flips on **first completed/accepted job**, NOT
      on going live.
- [ ] Go-live PUT returns **200** when `freeServiceUsed == false` even if unpaid;
      **402** otherwise (body unchanged). Same rule as the profile flag.
- [ ] Both fields omitted on discovery / list / map / other-user reads.

Auto go-live (only if the optional cron is built):
- [ ] Schedule endpoints + opt-in / manual-off-today for `INDIVIDUAL`.
- [ ] Cron window `[08:00, 22:00)` IST, same gate + manual-off + mid-session-close
      as the client.
