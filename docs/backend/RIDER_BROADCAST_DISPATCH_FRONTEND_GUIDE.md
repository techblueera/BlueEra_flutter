# Rapido Broadcast Dispatch — Frontend Integration Guide

How to wire the already-built `lib/features/ride_booking/` screens (currently
`_useStub = true`) to the **real** broadcast backend.

> **⚠️ Read this first — contract reconciliation.**
> The stub screens were written against an imagined `ride-booking-service/*`
> REST API (see the older `RIDE_BOOKING_FRONTEND_INTEGRATION.md`). **That
> service does not exist.** The broadcast dispatch was built on the EXISTING
> **`rider-service/fare/*`** endpoints, adding one field: `orderType:
> "broadcast"`. This guide maps the stub calls onto the real endpoints.
>
> **Both dispatch flows coexist — nothing is removed:**
> - **Old flow** (customer hand-picks riders): `Discover/` +
>   `DiscoverController.selectedRiders`, `orderType: "standard" | "fare-call"`.
>   Untouched. Keep as-is.
> - **New flow** (server finds riders, they race): `ride_booking/`,
>   `orderType: "broadcast"`. This guide.

---

## 0. What "broadcast" means on the wire

Customer creates a ride WITHOUT selecting riders. The server discovers nearby
riders in **expanding waves** (~3 → 6 → 10 km), rings all of them at once with
a call-style FCM popup, and the **first to accept wins** (atomic — everyone
else gets dismissed). Customer just polls status (or listens on the socket)
until a rider is attached.

Customer lifecycle: `create (pending)` → *waves ring riders* → `payment-pending`
(a rider won) → `confirmed` → `in-progress` (rider started, pickup OTP) →
`completed`. No winner in ~60s → `rejected`.

---

## 1. Endpoint remap (the core of the integration)

Rewire `RideBookingRepo` + `ride_booking_service_api.dart` from the imaginary
`ride-booking-service/*` paths to these real ones. All under the standard
`Authorization: Bearer` + `ResponseModel` envelope already used by the app.

| Stub repo method | Real endpoint | Notes |
|---|---|---|
| `getFareQuote()` | `GET rider-service/fare/riders/dynamic` | Returns riders grouped by vehicle type + a dynamic fare per type. Build `vehicleOptions` from these. **No `quoteId`** — synthesize one client-side or just carry `{vehicleType, fare}`. |
| `createBooking()` | `POST rider-service/fare/orders` with `orderType: "broadcast"` | See §2. Returns the order (`orderId`, status `pending`). Use `orderId` as `rideId`. |
| `getBookingStatus(rideId)` | `GET rider-service/fare/orders/{orderId}/status` | Returns `{ status, pickupOTP?, metadata }`. Drives searching→assigned→tracking. See §3. |
| `getCaptainLocation(rideId)` | `GET rider-service/fare/orders/{orderId}/rider-location` | Returns `{ rideActive, rider: { location, ... } }`. Poll ~5s once assigned. |
| `cancelBooking(rideId)` | `POST rider-service/fare/orders/{orderId}/cancel` | Customer cancels. |
| `raiseFare()` | **no backend** | Broadcast has no fare-bump yet. Hide the "+₹20" chips, or leave stubbed. Do NOT ship live. |
| `getRecentPlaces` / `searchPlaces` / `getPickupPoints` / saved places | **no backend** | Place search is not part of this backend. Reuse the app's existing Google-Places/geocoder path (the old booking screens already resolve places) or keep these stubbed until a places service ships. Decisions needed — see §6. |
| `getCancelReasons()` | **no backend** | Keep the built-in `_stubCancelReasons()` list (already the fallback). |

Path constants live in `lib/core/api/apiService/rider_service_api.dart` — most
already exist (`makeTransportBookOrder`, `getRideOrderStatus`,
`getRiderLiveLocation`, `cancelRide`). Reuse them; you do **not** need the
`ride_booking_service_api.dart` mixin for the live wiring.

---

## 2. Creating a broadcast ride

`POST rider-service/fare/orders`:

```jsonc
{
  "orderType": "broadcast",          // ← the only thing that makes it a race
  "orderFor": "InCity",              // InCity | OutStation | HourlyRental | Parcel
  "pickupLocation": { "address": "…", "latitude": 23.23, "longitude": 77.43 },
  "dropLocation":   { "address": "…", "latitude": 23.20, "longitude": 77.46 },
  "fare": 120,                       // from the dynamic-fare quote
  "modeOfPayment": "prepaid",        // prepaid | postpaid  (map CASH→postpaid, ONLINE→prepaid)
  "orderForWhom": "myself",
  "vehicleType": "twoWheelerRider"   // optional — restrict the race to one type
  // NO selectedRiders — omit it entirely
}
```

- `pickupLocation` is **required** for broadcast (the waves centre on it).
- Multi-stop / goods variants: `POST /fare/multi-shop/orders` and
  `POST /fare/chat-dispatch/orders` also accept `orderType: "broadcast"` with
  the same rule (omit `selectedRiders`). Not needed for the passenger
  `ride_booking` flow, but available.
- Response is the created order. Store `order.orderId` as the controller's
  `rideId`. Then start polling (§3) or open the socket (§4).

Map the controller's `RideVehicleOption.code` (`BIKE`, `AUTO`, `CAB_ECONOMY`…)
to the backend `vehicleType` values the dynamic-fare response returns
(`twoWheelerRider`, `carSedan`, …). Keep that mapping in one place.

## 3. Status poll (works today, no socket needed)

`GET rider-service/fare/orders/{orderId}/status` → `{ status, pickupOTP?, metadata }`.

Map backend `status` → the existing `RideStatus` enum (already handled by
`RideStatus.fromString`, just confirm the strings):

| backend `status` | `RideStatus` | UI |
|---|---|---|
| `pending` | `searching` | searching screen (waves running) |
| `payment-pending` / `confirmed` | `assigned` | a rider won → tracking screen |
| `in-progress` | `onTrip` | ride started (pickup OTP verified) |
| `completed` | `completed` | done |
| `rejected` | `noRidersFound` | no rider took it — offer rebook |
| `cancelled` | `cancelled` | cancelled |

`metadata.assignedRider` gives the winning rider id; hydrate captain details
from it. `pickupOTP` (passenger rides) is returned to the customer here — show
it on the tracking card for the rider to verify at pickup.

The existing 3s poll in `RideBookingController._pollStatus()` already does the
right thing; only the endpoint + field mapping change.

## 4. Socket (optional — instant assignment, no poll lag)

The backend also emits customer socket events via the existing chat-service
socket (`ChatSocketService`, `lib/features/chat/auth/socket/chat_socket.dart`).
Subscribe the same way the old flow subscribes to `ride:queue:*`:

| Event | Payload | Do |
|---|---|---|
| `ride:broadcast:searching` | `{ orderId, wave, totalWaves, radiusKm, ridersNotified }` | update "finding riders… (wave N)" |
| `ride:broadcast:accepted` | `{ orderId, riderId }` | a rider won → switch to tracking |
| `ride:queue:accepted` | `{ orderId, riderId, riderInfo, pickupOTP, jobInfo }` | full winner payload — reuse the old handler to fill the captain card |
| `ride:broadcast:exhausted` | `{ orderId }` | no winner → rebook prompt |

Recommended: **poll as the source of truth** (already built, robust to socket
drops) and treat the socket as a latency optimisation that finishes the search
bar the instant `ride:broadcast:accepted` arrives. Both can run together —
polling reconciles whatever the socket missed.

## 5. Flipping off the stub

1. Set `_useStub = false` in `RideBookingController` (line 24).
2. Rewire `RideBookingRepo` methods to the §1 endpoints (reuse the
   `RiderServiceApi` constants; the `ride-booking-service` mixin can stay
   unused or be deleted).
3. In `createBooking`, send the §2 body with `orderType: "broadcast"`; read
   back `orderId` as `rideId`.
4. In `_pollStatus` / `_pollCaptainLocation`, parse the §3 / rider-location
   shapes.
5. Gate `raiseFare` and place-search on the §6 decisions (keep stubbed until
   their backends exist — don't ship them live).
6. Delete the `// stubs` block only after every method above is live.

The old `Discover` flow needs **zero** changes — it keeps sending
`orderType: "standard"`/`"fare-call"` and its own `selectedRiders`.

## 6. Decisions needed (no backend yet)

| Feature | Options |
|---|---|
| **Place search / recents / pickup-points / saved** | (a) reuse the existing places/geocoder the old `book_your_transport` screens use; (b) keep stubbed until a places service ships. Broadcast dispatch itself only needs pickup+drop lat/lng — the source is your choice. |
| **Raise fare ("+₹20")** | Not implemented in broadcast. Hide the chips, or leave stubbed. |
| **Cancel reasons** | Keep the built-in list (already the offline fallback). |

## 7. Rider side — ring the dispatch notification

The winning-rider experience reuses the **existing** incoming-ride machinery —
no new rider screen needed. The one thing to wire is that
`broadcast_ride_request` must **RING** (loud, insistent, full-screen) exactly
like `fare_ride_incoming_call`, not ding like a chat message.

### 7.1 The trick: route the new op through the EXISTING ring path

The app already has a fully-built ringing path for `fare_ride_incoming_call`
(ringtone channel + `CATEGORY_CALL` + insistent repeating ring + full-screen
intent). Do **not** rebuild it — just make `broadcast_ride_request` fall into
the same branch. Two touch points:

**A. Background / terminated FCM isolate — `lib/main.dart`** (the
`fare_ride_incoming_call` branch, ~line 259). Widen the condition so both ops
take it:

```dart
// was:  if (operation == 'fare_ride_incoming_call') {
if (operation == 'fare_ride_incoming_call' ||
    operation == 'broadcast_ride_request') {
  // …unchanged body: builds the local notification on the RINGTONE channel…
}
```

The body already builds the ring notification with these exact settings —
inherit them as-is:

| Setting | Value | Why |
|---|---|---|
| channel id | `fare_ride_incoming_ringtone_v2` | pre-created WITH the ringtone; Android channel sound is immutable after creation, so the ringtone only works on this id |
| `sound` | `RawResourceAndroidNotificationSound('hangouts_call')` | the ring asset (`android/app/src/main/res/raw/hangouts_call.mp3`) |
| `importance` / `priority` | `max` / `max` | heads-up + full-screen |
| `category` | `AndroidNotificationCategory.call` | OS treats it as a call |
| `fullScreenIntent` | `true` | shows over lock screen |
| `additionalFlags` | `[4]` (FLAG_INSISTENT) | ringtone REPEATS until the rider acts |
| `audioAttributesUsage` | `notificationRingtone` | routes to the ring stream, not media |
| `timeoutAfter` | `45000` | auto-stops the ring (request is stale by then) |
| iOS `interruptionLevel` | `timeSensitive` | rings through Focus/DND |

**B. Foreground operation router — `lib/core/services/app_notification.dart`**
(~line 2621, the `case 'fare_ride_incoming_call'`). Add the broadcast op to the
same case so it opens `IncomingRiderOrderScreen`:

```dart
case 'fare_ride_incoming_call':
case 'broadcast_ride_request':          // ← add
  _showRiderOrderScreen(data);
  break;
```

`_showRiderOrderScreen` already parses both the new `metadata.rideDetails`
shape and the legacy `metadata['Pickup address']` shape — the broadcast payload
sends both (see §2 of the backend guide), so nothing else changes.

### 7.2 Channel must be pre-created with the sound

The ringtone only plays if the channel was **created with** the sound (Android
locks channel settings after first creation). The app already pre-creates
`fare_ride_incoming_ringtone_v2` in `AppNotificationHandler.init` for
`fare_ride_incoming_call`. Because broadcast reuses the **same channel id**,
no new channel is needed — it rings on first install with zero extra setup.

> If you ever want a SEPARATE channel/sound for broadcast, create a new id
> (e.g. `broadcast_ride_ringtone_v1`) in `init` with the same
> `RawResourceAndroidNotificationSound(...)` config, and use it in the main.dart
> branch. Reusing `fare_ride_incoming_ringtone_v2` is simpler and recommended.

### 7.3 Backend already sends ring-config

`be_notification_service` classifies `broadcast_ride_request` as a call
operation: high-priority APNs alert, `apns-push-type: alert`, `ttl_seconds` =
ring window, Android channel `fare_ride_calls`, category
`FARE_RIDE_INCOMING_CALL`. Data-only FCM (no `notification` block) so the
Flutter handler above owns display. No `call_id` is sent (there's no real VoIP
call behind a broadcast), so iOS rings via the high-priority alert path, not
CallKit — same as standard ride requests today.

### 7.4 Accept race + silent dismissal

- **Accept/reject**: same endpoint — `POST fare/orders/{orderId}/ride-action`
  with `{action: "accept"|"reject"}` (`call_controller.dart`
  `acceptFareCallRide`/`rejectFareCallRide`). Accept is the RACE: first rider
  gets 200, everyone else gets **409 "Ride already taken by another rider."** —
  handle 409 by **stopping the ring and closing the popup quietly** (not an
  error toast).
- **Dismiss losers**: on a loss/expiry the backend sends socket
  `ride:broadcast:closed` `{ orderId, reason }` **and** a silent data push
  `operation: "broadcast_ride_closed"` (iOS `background` push, no alert/sound).
  Route `broadcast_ride_closed` in the operation router to **cancel the ringing
  notification and dismiss the incoming screen** for that `orderId` — never
  show a banner. Cancel via the same `notifId`/`FlutterLocalNotificationsPlugin`
  used to post it, and pop `IncomingRiderOrderScreen` if it's open for that
  order.

That's the rider-side work: widen one `if` (main.dart) and one `case`
(app_notification.dart) so broadcast rings on the existing path, add a
`broadcast_ride_closed` dismissal branch, and handle the 409 on accept.
Everything downstream (OTP cards, start, complete) is the existing flow
unchanged.

---

## File touch list (frontend)

| File | Change |
|---|---|
| `ride_booking/controller/ride_booking_controller.dart` | `_useStub=false`; body/field mapping per §2–3 |
| `ride_booking/repo/ride_booking_repo.dart` | point methods at `rider-service/fare/*` (§1) |
| `ride_booking/model/ride_booking_models.dart` | confirm `RideStatus.fromString` covers `pending`/`payment-pending`/`confirmed`/`in-progress`/`rejected` |
| `core/services/app_notification.dart` | add `case 'broadcast_ride_request'` to the `fare_ride_incoming_call` case (→ `_showRiderOrderScreen`); add `broadcast_ride_closed` case (→ cancel ring + dismiss) — §7.1/7.4 |
| `main.dart` | widen the `fare_ride_incoming_call` bg branch to also match `broadcast_ride_request` so it rings on `fare_ride_incoming_ringtone_v2` — §7.1 |
| `features/chat/.../call_controller.dart` | handle **409** on broadcast accept (stop ring, silent close) — §7.4 |
| chat socket subscriber | optional `ride:broadcast:*` events (§4) |

**No new channel, no new sound asset, no new screen** — broadcast rides ring by
reusing the `fare_ride_incoming_ringtone_v2` channel and
`IncomingRiderOrderScreen` that already ship for `fare_ride_incoming_call`.

Backend deploy order: **be_notification_service** (ring + silent ops) → **be_rider_service** (broadcast flow). Both additive, backward compatible — old flow unaffected until the app opts in with `orderType: "broadcast"`.
