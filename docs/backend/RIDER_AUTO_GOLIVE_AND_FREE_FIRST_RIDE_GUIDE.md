# Rider Go-Live Enhancements — Backend Guide

Two rider go-live features shipped on the frontend today. Both need backend
support to be fully reliable. This is the single source of truth for both.

1. **Daily auto go-live** — auto-open the rider's status every day 10:00–12:00, then auto-close.
2. **First ride free** — waive the security-deposit go-live gate until the rider completes their first ride.

Frontend refs:
- `lib/features/common/delivery_partner/service/rider_auto_golive_scheduler.dart`
- `lib/features/common/delivery_partner/view/rider_service_screen.dart` (`handleGoLiveTap`)
- `lib/features/common/delivery_partner/controller/delivery_partner_controller.dart` (`isFirstRideFree`)
- `lib/features/common/delivery_partner/model/rider_onboarding_status.dart` (`freeRideUsed`)

---

# Part 1 — Daily Auto Go-Live (10:00–12:00)

**Goal:** once a rider goes live for the first time (after clearing document
verification + security-deposit payment — or the free first ride, see Part 2),
auto-open their go-live status every day **10:00 to 12:00** and auto-close after,
**without the rider tapping anything, even when the app is closed.**

## 1.1 Why the backend is mandatory

A mobile app can't run code on a schedule when it's killed (iOS freezes timers in
the background; Android freezes the process). The frontend ships a **best-effort**
scheduler that only fires while the app is open. The **authoritative** open/close
must be a **server-side cron** that flips the rider's `serviceProviderStatus`. The
app already reflects that status on launch/resume
(`ViewPersonalDetailsController.restoreProviderLiveState` re-asserts OPEN from the
server), so once the cron flips it, the app follows.

## 1.2 Schedule model (persist per rider)

```jsonc
{
  "autoGoLiveEnabled": true,                         // opted in (set on first manual go-live)
  "window": { "start": "10:00", "end": "12:00" },    // 24h
  "timezone": "Asia/Kolkata",                        // evaluate the window in IST
  "manualOffDate": "2026-07-14"                       // rider opted out for this date (optional)
}
```

- Defaults: `10:00`–`12:00`, `Asia/Kolkata`.
- The client hard-codes 10:00–12:00 in **device local time**; keep the server on
  **IST** to match. If the window becomes rider-editable later, expose it here and
  the client will read it.

### Endpoints

```
PUT  /api/rider-service/riders/auto-golive     # save (enable/disable, window)
GET  /api/rider-service/riders/auto-golive     # read current schedule
```

PUT body: `{ "enabled": true, "windowStart": "10:00", "windowEnd": "12:00" }`

> The client will call PUT `{enabled:true}` right after the rider's first
> successful manual go-live. Until this endpoint exists the opt-in is stored
> **locally** (the best-effort scheduler still works while the app is open).

## 1.3 The cron (authoritative open/close)

1. **At 10:00 IST:** for every rider with `autoGoLiveEnabled == true` who is
   **eligible** (§1.4) and hasn't opted out today (`manualOffDate != today`) → set
   `serviceProviderStatus = OPEN`.
2. **At 12:00 IST:** for every rider auto-opened by job 1 → set `CLOSED`.

- Run every 1–5 min so a rider who onboards mid-window still opens.
- **Idempotent:** never OPEN an already-OPEN rider; never clobber a rider who went
  OPEN manually before 10:00 — track "opened-by-schedule" so job 2 only closes
  those (mirrors the client's "only auto-close what it auto-opened").

## 1.4 Eligibility — enforce the gates server-side

Before auto-opening, re-check the same gates the client enforces:

1. **Document verification** — `verificationStatus == "approved"`.
2. **Security deposit** — `securityDeposit.paid == true` **OR** the rider still has
   the **free first ride** available (`freeRideUsed == false`, see Part 2). Only
   for deposit professions (`BIKE_RIDER`, `CAR_TAXI_DRIVER`); other roles skip it.

If a gate fails, skip the rider.

## 1.5 Location freshness while auto-live (decision needed)

A rider auto-opened while the app is **closed** has no fresh GPS, so
`ProviderStatus.lastSeen` goes stale and **map-service auto-closes the provider
after ~5 min**. Pick one:

- **(a) Primed availability:** auto-open just marks them available; the rider must
  open the app to hold a live location + receive orders. Simplest.
- **(b) Suppress the 5-min auto-close** for riders flagged scheduled-live during
  their window.
- **(c) Silent/data FCM at 10:00** to wake the app and start `LiveLocationService`
  so location stays fresh through the window. Best UX — **recommended.**

## 1.6 Manual override

If a rider manually goes offline during the window, don't re-open them: set
`manualOffDate = today` and have job 1 skip riders whose `manualOffDate == today`
(resets next day). The client already does this locally.

## 1.7 Client behaviour already shipped

`RiderAutoGoLiveScheduler` — a 1-minute evaluator (runs while the app is open):
opt-in persisted on first manual go-live; inside 10:00–12:00 auto-opens via
`toggleShopOnlyStatus(true)` — guarded by still-verified, still-deposit-paid (or
free ride), permissions already granted, and no manual opt-out today; auto-closes
only sessions it opened. **Does nothing when the app is closed — that's what the
cron in §1.3 covers.**

---

# Part 2 — First Ride Free (deposit gate waiver)

**Behaviour:** a rider's **first ride is free** — the security-deposit gate on
**Go Live** is *waived* until they complete that first ride. After the first
completed ride, the deposit is enforced on every subsequent go-live.

## 2.1 What the app already does

`handleGoLiveTap` blocks go-live on the deposit only when:

```
isRiderRole (BIKE_RIDER | CAR_TAXI_DRIVER)
  && !securityDeposit.paid
  && freeRideUsed != false        // the free first ride is NOT available
```

So while the free ride is available the rider goes live **without paying**; once
it's used, the normal deposit gate returns.

## 2.2 Backend dependency — per-rider `freeRideUsed` flag

Add `freeRideUsed` to the rider **onboarding-status** response (the same payload
that already carries `securityDeposit.paid` / `verificationStatus`):

```jsonc
{
  // …existing onboarding-status fields…
  "securityDeposit": { "paid": false, "paymentStatus": "pending" },
  "freeRideUsed": false   // false → free first ride available (waive deposit)
                          // true  → used → enforce deposit
                          // omitted → app treats as "used" (deposit enforced) — SAFE default
}
```

Rules:
1. **Return `false`** for a verified rider with **0 completed rides** who hasn't
   paid the deposit → the app lets them go live for the first ride.
2. **Flip to `true`** the moment the rider **completes their first ride** (status
   `completed`/`delivered`). From then the deposit gate applies.
3. If the deposit is already `paid`, `freeRideUsed` is irrelevant.
4. **Omitting the field is safe** — the app treats absent/`null` as "used" and
   keeps enforcing the deposit, so shipping the flag is what *enables* the free
   ride (no risk of accidentally giving everyone free go-live).

> The app reads this via `DeliveryPartnerController.isFirstRideFree` (`== false`)
> and re-fetches onboarding status after the deposit flow, so a flip from
> first-ride completion is picked up on the next status refresh.

---

## Combined backend checklist

**Auto go-live**
- [ ] Persist `autoGoLiveEnabled` + window + timezone per rider.
- [ ] `PUT`/`GET /riders/auto-golive` endpoints.
- [ ] Cron opens 10:00 IST / closes 12:00 IST (idempotent, opened-by-schedule tracked).
- [ ] Re-check verification + (deposit **or** free ride) before auto-open.
- [ ] Decide + implement §1.5 location freshness (recommend silent FCM).
- [ ] Honour manual opt-out (`manualOffDate`).
- [ ] Cron writes the same `serviceProviderStatus` the app reads.

**First ride free**
- [ ] Add `freeRideUsed` to the rider onboarding-status response.
- [ ] `false` for verified rider with 0 completed rides + unpaid deposit.
- [ ] Flip to `true` on first completed ride.
