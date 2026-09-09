# Why a migrated user's Active Plan doesn't show — diagnosis & fix

**Reported by:** users who moved from the old **Security Deposit** to the new
**Account Plan** system (e.g. Rahul kumar, `6a086443a38e8cd3861ac4b6`,
9494985993). They hold an active plan, but the app shows "no active plan" —
go‑live is blocked and the plan status reads empty.

**Scope of this document:** this is a **frontend (Flutter) issue only**. The
backend is verified correct (see §2). No API or backend change is required — the
data needed to fix this is already in the `my-plans` response.

---

## 1. Symptom

- A deposit‑migrated user's plan does **not** register as "active".
- On rider/delivery and business/professional screens the **go‑live gate stays
  closed** ("you need an active plan").
- Profile "active plan" indicators read false.
- It looks intermittent ("worked yesterday, not today") because it only bites
  accounts whose **only** active plan is a **free** one — which is exactly what a
  deposit migration grants.

---

## 2. The backend is correct (verified)

Calling the **live production** API with the user's own session token:

```
GET /account-plan/my-plans
  → { success:true, count:1, has_active_plan:true,
      active_plan:{ option_code:"GIG_BIKE_PASSENGER", option_label:"Passenger",
                    status:"active", isActive:true, base_amount:0, total_amount:0,
                    source:"deposit_migration", archetype:"A2_GIG_CALLS" } }

GET /account-plan/my-plans?status=active   → count:1, the Passenger plan
GET /account-plan/entitlement/active       → has_active_plan:true
```

So the server **does** return the active plan. The plan is real; it is simply
**free** (`total_amount = 0`) because migration grants the mapped plan at ₹0
while the security deposit stays refundable. The app receives it and then drops
it. This is a client‑side bug.

---

## 3. Root cause

File: **`lib/features/account_plan/controller/account_plan_entitlement.dart`**,
method `publish()`:

```
hasActivePlan.value = plans.any((p) => p.isActive && p.totalAmount > 0);
```

The `totalAmount > 0` clause was added to stop the **default free social profile**
(`A0_SOCIAL_FREE`) from counting as a paid entitlement — otherwise every account
would "have a plan" and the go‑live gate would be meaningless.

But that clause is too broad. It excludes **every** free plan, including a
**legitimate** free plan created by deposit migration. The migrated plan is a
real entitlement (the user paid a deposit and was moved to a free plan by
promise), yet `total_amount == 0`, so `p.totalAmount > 0` is `false` and
`hasActivePlan` is set to **false**.

In short: the code treats "free" as "not a real plan", but after the deposit→plan
migration, **free no longer means fake**.

### Why "worked yesterday, not today"
Nothing time‑based changed on the server. The confusion comes from unpaid
checkout attempts (`status: created`) piling up and from the free‑plan exclusion —
the account genuinely has an active (free) plan the whole time, but this gate
never counted it.

---

## 4. Where the bug bites (and where it doesn't)

**Affected — all read `AccountPlanEntitlement.to.hasActivePlan`:**

| File | Line | What breaks |
| --- | --- | --- |
| `lib/features/common/delivery_partner/controller/delivery_partner_controller.dart` | ~519‑520 | Rider/delivery **go‑live gate** stays closed (`allowed = approved && hasActivePlan`) |
| `lib/features/business/auth/controller/view_business_details_controller.dart` | ~146 | Business profile "active plan" flag reads false |
| `lib/features/personal/auth/controller/view_personal_details_controller.dart` | ~486 | Personal/rider profile "active plan" flag reads false |

**NOT affected by this specific bug — the Contribution/catalog card:**
The green **Active Plan card** on the Contribution screen is drawn from
`AccountPlanController.ownsPlan()` →
`account_plan_controller.dart` `activeOptionCodes` (line ~204), which keys off
`p.isActive` (status == "active") **only**, with no price check. So for a free
migrated plan whose `option_code` exists in the catalog, that card **does**
render.

> If the Contribution card is *also* missing for a specific user, it is a
> different cause — see §6.

---

## 5. The fix (frontend, one condition)

Use the **archetype** to tell a real plan from the default free profile, instead
of the price. `A0_SOCIAL_FREE` is the only archetype that should ever be ignored;
every migrated or purchased plan carries a real archetype (`A1_…`, `A2_…`, …).
The `archetype` field is **already parsed** on `UserAccountPlan`
(`account_plan_models.dart`) and `PlanArchetype.socialFree` already exists — no
model or API change is needed.

In `account_plan_entitlement.dart` `publish()`, change the test from
"has a positive price" to "is active and is not the default social‑free plan":

- **Before (intent):** active **and** `totalAmount > 0`
- **After (intent):** active **and** `archetype != PlanArchetype.socialFree`

This keeps the original guarantee (the default `A0_SOCIAL_FREE` profile still
does **not** unlock go‑live) while correctly counting free plans granted by
deposit migration (which are `A2_GIG_CALLS`, `A1_SALES_SHOP`, etc.).

**Optional, extra‑explicit:** if you prefer to also key off provenance, expose
`source` on `UserAccountPlan.fromJson` (`j['source']`) and treat
`source == 'deposit_migration'` as active too. The archetype rule already covers
it, so this is belt‑and‑suspenders only.

### Also update the comment
The doc‑comment on `publish()` says "A FREE plan does not satisfy the gate". After
the fix it should read: *"The default `A0_SOCIAL_FREE` plan does not satisfy the
gate; every other active plan does, including a free plan granted by deposit
migration."*

---

## 6. If the Contribution Active‑Plan card is missing for one user

That card uses `isActive` (not price), so this bug is not the cause. Check, in
order:

1. **Stale state / cache** — pull‑to‑refresh the Contribution screen, or log out
   and back in. `fetchMyPlans()` re‑reads `/my-plans?status=active`.
2. **Catalog tag mismatch** — the card only appears if the held plan's
   `option_code` exists in the catalog for the resolved tag
   (`AccountPlanTag.resolve()`). Confirm `GET /account-plan/plans` for the user
   returns a card with the same `option_code` as the active plan (for this user
   it does: `GIG_BIKE_PASSENGER`).
3. **API host** — confirm the build points at
   `be.beapp.in/api/subscription-service/...`. An old/staging host may not have
   the plan.
4. **`myPlans` populated** — `fetchMyPlans()` in `account_plan_controller.dart`
   has no try/catch around parsing; verify it completes and `myPlans` is
   non‑empty in the logs.

---

## 7. Test checklist after the fix

- A deposit‑migrated user (free `A2/A1/…` plan) → `hasActivePlan == true`,
  go‑live gate opens, profile shows the plan.
- A brand‑new social account with only `A0_SOCIAL_FREE` → `hasActivePlan == false`
  (unchanged — must still be blocked).
- A user with a paid active plan → `hasActivePlan == true` (unchanged).
- A user with only `created`/`failed` (abandoned checkout) → `hasActivePlan == false`.

---

## 8. One‑line summary

The go‑live gate counts a plan only when `totalAmount > 0`, so **free plans
granted by deposit migration are wrongly ignored**. Count a plan as active when
it is `isActive` **and** its archetype is not `A0_SOCIAL_FREE` — the API already
sends everything needed, so this is a single frontend condition change with no
backend work.
