# Auto Go-Live + First Ride Free — Frontend Integration

Backend for both features is implemented (per
`RIDER_AUTO_GOLIVE_AND_FREE_FIRST_RIDE_GUIDE.md`). Everything is backward
compatible — current app builds keep working unchanged.

> **Status (2026-07-15): all three frontend changes below are now implemented.**
> Each section is marked ✅ **DONE** with the exact code that landed. The
> forward-looking prose is kept for context.

## What the backend now provides

### Part 2 — First ride free: NO frontend change needed
`GET rider-service/riders/onboarding/status` now returns:

```jsonc
{ "...": "...", "freeRideUsed": false }
```

- `false` → rider has **zero completed rides** → deposit gate waived
- `true` → at least one completed ride → deposit enforced
- Computed live from ride history; flips automatically on the first completed
  ride. The app's existing `isFirstRideFree` / `freeRideUsed` reading works
  as-is the moment this deploys.

### Part 1 — Auto go-live: backend pieces

1. **Schedule endpoints** (Bearer auth, rider's own record):
   ```
   GET rider-service/riders/auto-golive
   → { "data": { "enabled": false, "windowStart": "10:00",
                 "windowEnd": "12:00", "timezone": "Asia/Kolkata",
                 "manualOffDate": null } }

   PUT rider-service/riders/auto-golive
   body: { "enabled": true }                     // opt in
         { "manualOffToday": true }              // opted out for today (IST)
         { "windowStart": "10:00", "windowEnd": "12:00" }  // optional
   → 200 with the updated schedule; 400 on bad HH:MM; 404 no rider doc
   ```

2. **Authoritative cron** (rider-service, every 2 min):
   - Inside the window: opens eligible riders (verified + deposit-paid OR
     free-first-ride) via map-service `SetUserStatus(OPEN)` — same
     `availabilityStatus` the app reads from
     `GET map-service/api/provider/status/{userId}`.
   - After the window: closes ONLY sessions the cron itself opened. Manual
     sessions are never touched. Manual-off-today riders are never re-opened.
   - On each auto-open it sends a push, operation **`AUTO_GOLIVE_OPENED`**
     (data: `title`, `message`, `windowEnd`).

## Frontend changes (3 small ones)

The endpoint is wired through the normal service/repo layers (not a raw
`ApiBaseHelper` call at the call site):

- Constant: `RiderServiceApi.ridersAutoGoLive` = `rider-service/riders/auto-golive`
  (`lib/core/api/apiService/rider_service_api.dart`).
- Repo: `DeliveryPartnerRepo.getRiderAutoGoLiveRepo()` (GET) and
  `updateRiderAutoGoLiveRepo({params})` (PUT)
  (`lib/features/common/delivery_partner/repo/delivery_partner_repo.dart`).

### 1. Sync the opt-in to the server — ✅ DONE
`RiderAutoGoLiveScheduler` now mirrors both opt-in actions to the server via a
fire-and-forget `_syncToServer(params)` helper
(`lib/features/common/delivery_partner/service/rider_auto_golive_scheduler.dart`):

```dart
// enableAfterManualGoLive() — after persisting the local flag:
_syncToServer({'enabled': true});

// noteManualOffDuringWindow() — after writing today's manual-off key:
_syncToServer({'manualOffToday': true});
```

`_syncToServer` never throws and never blocks the caller — until the PUT lands
the cron simply doesn't know about the rider (behaves like today), and the next
launch's reconcile (below) heals a missed sync.

### 2. Read the schedule on launch — ✅ DONE
`ensureStartedIfEnabled()` now calls `_reconcileEnabledFromServer()` before it
decides whether to start: it `GET`s the schedule and lets the server `enabled`
win over the local flag (covers reinstall / second device). Best-effort — on
any failure it keeps the local flag as-is. It reads `data.enabled` from the
response body (`{ "data": { "enabled": ... } }`).

### 3. Handle the `AUTO_GOLIVE_OPENED` push — ✅ DONE
The cron can only mark the rider available; **location freshness needs the
app** (map-service auto-closes providers with a stale `lastSeen` after ~5
min). Matched case-insensitively as `auto_golive_opened`. Three entry points:

- **Foreground** (`AppNotificationHandler.onMsgOpen` → `onMessage`, in
  `lib/core/services/app_notification.dart`): calls
  `ViewPersonalDetailsController.getServiceProviderStatus()` when the
  controller is registered (it flips the toggle AND starts the location pinger
  when the server says OPEN), then falls through to render the banner.
- **Tap while backgrounded-but-alive** (`onMessageOpenedApp`, same file): same
  `getServiceProviderStatus()` refresh before the tap routing, so tapping the
  banner brings the rider genuinely live.
- **Background / terminated** (`firebaseMessagingBackgroundHandler` in
  `lib/main.dart`): the bg isolate has no UI/GetX, so it can't flip the
  toggle. It persists `serviceProviderStatus = OPEN` to secure storage and
  falls through to the generic renderer to show the "You're live!" banner. On
  the next launch, `ViewPersonalDetailsController.onInit →
  restoreProviderLiveState()` reads that cached OPEN and re-asserts live
  (re-PATCH OPEN + restart the pinger).

> Note: `restoreProviderLiveState()` reads the **local** cached
> `serviceProviderStatus` (via `getServiceProviderStatusUtils()`), not the
> server — which is why the bg handler persists OPEN. Without that write, a
> rider who went offline the previous day would launch with a stale CLOSED
> cache and the restore would not bring them live.

## Behaviour notes / edge cases

- If the rider never opens the app during the window, map-service's stale
  sweep closes them ~5 min after the auto-open. That is guide option (a) +
  (c): primed availability plus a wake-up push. No suppression of the sweep —
  a rider with no live GPS shouldn't receive orders.
- The deposit gate re-checks server-side on every auto-open, including the
  free-first-ride waiver — the cron can never open an ineligible rider.
- Old builds: everything is opt-in (`enabled` defaults false) and `freeRideUsed`
  absent-handling is already safe in shipped builds. No forced upgrade.
