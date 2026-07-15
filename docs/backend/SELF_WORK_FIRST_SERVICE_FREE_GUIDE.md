# Self-Work "First Service Free" — Integration Guide

**Goal:** give every self-employed (selfWork / `INDIVIDUAL`) provider **one free
go-live**. While the free go-live is available, the security-deposit gate is
**waived** — the provider can go live and receive service enquiries without
paying the deposit. After it's used, the deposit is enforced on every subsequent
go-live, exactly as today.

This is the self-employed analogue of the rider **first-ride-free** waiver
(`freeRideUsed`) already live in `be_rider_service`. **The frontend is already
implemented** (§7); the backend work is §1–§6 + §8.

- Owning service: **`be_earn_with_blueera_service`** (individual profile +
  go-live). Deposit state lives in **`be_subscribe_service`** (unchanged).
- Prior context: `SELF_WORK_GO_LIVE_FRONTEND_INTEGRATION.md` (the deposit gate),
  `RIDER_AUTO_GOLIVE_AND_FREE_FIRST_RIDE_GUIDE.md` Part 2 (the rider waiver this
  mirrors).

---

## 1. The one field: `freeServiceUsed`

Add a single boolean, **`freeServiceUsed`**, to the **individual-profile
response**, as a **top-level sibling of `securityDeposit`** (next to `user`,
`earnProfileTypes`, `securityDeposit`).

```jsonc
{
  "status": true,
  "user": { /* … */ },
  "earnProfileTypes": ["home_made_food"],
  "securityDeposit": {
    "required": true,
    "paid": false,
    "paymentStatus": "created",
    "depositId": null,
    "refundEligibleAt": null
  },
  "freeServiceUsed": false        // ← NEW
}
```

| Field | Type | Meaning |
|---|---|---|
| `freeServiceUsed` | `boolean` | `false` → first free go-live **still available**. `true` → already used. |

---

## 2. Semantics (must match exactly)

| `freeServiceUsed` | Meaning | Deposit gate |
|---|---|---|
| `false` | first go-live is free | **waived** (allow go-live even if `required && !paid`) |
| `true` | free go-live used | **enforced** (normal deposit gate) |
| omitted / `null` | unknown / old data | **enforced** (safe default) |

**Rule:** only an explicit `false` waives the gate. **Absence must mean
"enforce."** This keeps old app builds and any pre-deploy state from accidentally
handing everyone a free go-live.

> Note the deliberate asymmetry with `securityDeposit`, which fail-**opens**
> (absent ⇒ allow). `freeServiceUsed` fail-**closes** (absent ⇒ enforce),
> because it's the permissive side of the waiver and must not leak.

---

## 3. Which endpoint returns it

Only the provider's **own individual-profile read** — the same endpoint that
already returns `user`, `earnProfileTypes`, and `securityDeposit`. Auth:
`Authorization: Bearer <JWT>`.

- **Include** on: `GET` individual profile (own).
- **Do NOT include** on: discovery / list / map / search / any "other user"
  view. The waiver is about the caller's **own** account only.

Compute and attach it in the same place you already compute `securityDeposit`
for the profile response.

---

## 4. When does `freeServiceUsed` flip to `true`?

Flip it to `true` once the provider has **completed their first paid service /
booking** (the individual analogue of "completed first ride"). Definition of
"completed" is your call — pick the event that marks a real fulfilled job (e.g.
first booking/enquiry that reaches a completed/paid terminal state).

Requirements:
- **Compute it live** from history on each profile read (don't rely on a
  one-time write that can drift). Same approach as the rider `freeRideUsed`.
- It is **monotonic**: once `true`, it stays `true` (the free go-live is spent).
- It is **per provider account** (`INDIVIDUAL`, keyed by user id).
- ⚠️ **"Consumed" = completed a service, NOT went live.** Going live must not
  itself flip the flag — otherwise the provider is blocked the moment they open
  the toggle a second time. The free go-live is spent by *fulfilling* a job.

---

## 5. Enforce the waiver server-side on go-live (the important one)

"Going live" is a **`PUT /services/:id`** whose `availability` has at least one
open day (`schedule[].isOpen == true`) or an open `specialOverride`. Today that
returns **402 Payment Required** when the deposit is `required && !paid`.

Add the waiver to that decision:

```
allow go-live  ⇔  !securityDeposit.required
                   || securityDeposit.paid
                   || freeServiceUsed == false        // ← NEW waiver
```

- If `freeServiceUsed == false`: the go-live PUT must **succeed (200)** even when
  the deposit is unpaid.
- Otherwise: keep the current behaviour (**402** with the `securityDeposit`
  body, message unchanged).

The frontend pre-checks the same condition to avoid a surprise 402, but the
**server stays authoritative** — the 402 is the backstop for stale clients. The
profile's `freeServiceUsed` and the go-live enforcement **must use the same
rule** so they never disagree.

**402 body (unchanged):**
```json
{
  "message": "Your payment is incomplete. Please complete the security deposit to go live and receive service enquiries.",
  "securityDeposit": { "required": true, "paid": false, "paymentStatus": "created", "depositId": null, "refundEligibleAt": null }
}
```

---

## 6. Compatibility & edge cases

- **Old app builds:** ignore `freeServiceUsed`, read only `securityDeposit` —
  unaffected (they just don't get the waiver).
- **New app + old backend (field absent):** frontend treats absent as
  "enforce" — safe, behaves like today.
- **Purely additive:** no change to any existing field/endpoint — one new field
  plus one extra OR-clause in the go-live check.
- **Deposit not required** (`required == false`): already allowed; the waiver is
  irrelevant.
- **Fail-open on outage:** if the deposit lookup to `be_subscribe_service` fails,
  keep the existing fail-open (`paid: true`) — that already allows go-live.
- **Offline → online:** going offline never hits the gate. Going back online
  re-checks — if the free go-live was consumed and the deposit is still unpaid,
  it's a 402 (correct).
- **After paying the deposit:** normal enforcement applies regardless of
  `freeServiceUsed` (allowed because `paid == true`).

---

## 7. Frontend (already implemented — for reference)

No further app work needed; listed so both sides agree on the contract.

**Model** — `PersonalProfileDetailsModel`
(`lib/core/api/model/personal_profile_details_model.dart`)
```dart
// Parse (accepts freeRideUsed as an alias for cross-service consistency):
freeServiceUsed =
    json['freeServiceUsed'] as bool? ?? json['freeRideUsed'] as bool?;
// Derived gate — false ⇔ still free:
bool get isFirstServiceFree => freeServiceUsed == false;
```
`freeServiceUsed` is read-only / not serialized (like `securityDeposit`): on a
cache replay it's absent, which is safe because `canGoLive` fail-opens from cache
and the fresh read re-populates both.

**Controller** — `ViewPersonalDetailsController`
```dart
bool get canGoLive => personalProfileDetails.value.canGoLive;
bool get isFirstServiceFree => personalProfileDetails.value.isFirstServiceFree;
```

**Go-live gate** — self-employed dashboard `_handleGoLiveTap()`
(`lib/features/personal/personal_profile/view/self_employed/view/self_employee_screen.dart`)
```dart
final depositBlocked = !_viewCtrl.canGoLive && !_viewCtrl.isFirstServiceFree;
if (depositBlocked) {
  commonSnackBar(message: 'Your payment is incomplete. …');
  await Get.to(() => const ContributionScreenV2());          // deposit flow
  await _viewCtrl.viewPersonalProfile(forceRefresh: true);   // pick up fresh deposit + flag
  return;
}
```

This mirrors the rider gate
`depositBlocked = isRiderRole && !isSecurityDepositPaid && !isFirstRideFree`
(`rider_service_screen.dart`), where the self-employed `canGoLive` already folds
in the rider's `isRiderRole` + `isSecurityDepositPaid` (via
`securityDeposit.required` / `.paid`).

> **Field naming:** canonical key is **`freeServiceUsed`**. The app also accepts
> **`freeRideUsed`** as an alias, but please emit `freeServiceUsed` on the
> individual profile.

---

## 8. Acceptance checklist (backend)

- [ ] `GET` own individual profile returns `freeServiceUsed` (boolean),
      top-level next to `securityDeposit`.
- [ ] `false` ⇔ first free go-live available; `true` ⇔ used; **absent ⇒ enforce**.
- [ ] Value is computed live and is monotonic (never flips back to `false`).
- [ ] Flip to `true` on **first completed paid service/booking**, NOT on the act
      of going live.
- [ ] `PUT /services/:id` go-live returns **200** when `freeServiceUsed == false`
      even if the deposit is unpaid; **402** otherwise (body unchanged).
- [ ] Profile `freeServiceUsed` and go-live enforcement use the **same rule**.
- [ ] Field omitted on discovery / list / map / search / other-user reads.
- [ ] No change to `securityDeposit` shape, the deposit purchase flow, or any
      existing field.

---

## Appendix — Go-live truth table

| `required` | `paid` | `freeServiceUsed` | Go-live result |
|---|---|---|---|
| false | — | — | **200** (no deposit owed) |
| true | true | — | **200** (paid) |
| true | false | `false` | **200** (first free) |
| true | false | `true` | **402** (enforce) |
| true | false | absent/`null` | **402** (safe default) |
