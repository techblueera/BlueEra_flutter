# Self-Work "First Service Free" — Frontend Integration

Backend is LIVE-ready (be_user_service + be_earn_with_blueera_service, per
`be_user_service/docs/backend/SELF_WORK_FIRST_SERVICE_FREE_GUIDE.md`). The
backend guide's §7 claimed the app already implements this — it does **not**
(no `freeServiceUsed` anywhere in `lib/`). This is the actual to-do list.
Three small edits, all additive; old builds keep working unchanged.

## What the backend now sends

`GET` own profile (the call behind `viewPersonalProfile`) — for INDIVIDUAL
accounts only, top-level next to `securityDeposit`:

```jsonc
{ "...": "...",
  "securityDeposit": { "required": true, "paid": false, "...": "..." },
  "freeServiceUsed": false }   // false → first free go-live available
```

- `false` → provider has never fulfilled a job → **deposit gate waived**
- `true` → free go-live spent → enforce deposit
- **absent/null → enforce** (fail-close; never waive on missing data)

Server is authoritative: the go-live `PUT /services/:id` already returns
**200** under the waiver and **402** otherwise — the app change below only
removes the local pre-block so eligible providers aren't stopped before the
request.

## Edit 1 — model (`lib/core/api/model/personal_profile_details_model.dart`)

```dart
// field (next to securityDeposit):
bool? freeServiceUsed;

// in fromJson (accept freeRideUsed as cross-service alias):
freeServiceUsed =
    json['freeServiceUsed'] as bool? ?? json['freeRideUsed'] as bool?;

// derived gate — ONLY an explicit false waives:
bool get isFirstServiceFree => freeServiceUsed == false;
```

Do **not** serialize it back in `toJson` (same treatment as
`securityDeposit`): on a cache replay it's absent → `isFirstServiceFree`
false → safe.

## Edit 2 — controller (`view_personal_details_controller.dart`)

```dart
bool get isFirstServiceFree =>
    personalProfileDetails.value.isFirstServiceFree;
```

## Edit 3 — go-live gate (`self_employee_screen.dart` `_handleGoLiveTap`, ~line 204)

```dart
// OLD:
if (!_viewCtrl.canGoLive) {

// NEW — deposit blocked only when the free first go-live is also spent:
final depositBlocked =
    !_viewCtrl.canGoLive && !_viewCtrl.isFirstServiceFree;
if (depositBlocked) {
```

After returning from `ContributionScreenV2`, keep (or add) a
`viewPersonalProfile(forceRefresh: true)` so a fresh `freeServiceUsed` +
deposit state is picked up.

Note: `hideLiveState` / any other place gated purely on `canGoLive`
(controller line ~247/304) should get the same `|| isFirstServiceFree`
loosening ONLY if it blocks going live; leave display-only logic alone.

## Behaviour summary (must match server truth table)

| deposit required | paid | freeServiceUsed | Go-live |
|---|---|---|---|
| false | — | — | allowed |
| true | true | — | allowed |
| true | false | `false` | **allowed (free first)** |
| true | false | `true` / absent | blocked → deposit flow |

## How the flag flips

Server computes it live: `true` once the provider has any **accepted**
service/artist enquiry, **accepted** home-stay booking, or **completed**
home-made-food/tiffin order. Going live does NOT consume it. After the first
fulfilled job, the next go-live attempt hits the normal deposit gate — the app
needs no logic for this beyond re-fetching the profile.

## Test checklist

1. Fresh INDIVIDUAL provider (deposit unpaid, no jobs) → Go Live succeeds; no
   snackbar; server returns 200.
2. Same provider accepts one enquiry → refresh profile → `freeServiceUsed:
   true` → next go-live (after going offline) shows the deposit snackbar +
   `ContributionScreenV2`; server 402 if forced.
3. Deposit-paid provider → unchanged.
4. Old app build against new backend → unchanged (field ignored).
5. New app build against old backend → field absent → gate enforced
   (unchanged behaviour).
