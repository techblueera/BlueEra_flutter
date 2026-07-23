# Broadcast Ride — End-to-End Test Guide (customer + rider)

How to run a **real** end-to-end test of the Rapido-style broadcast ride across
two devices, what each side must observe at every step, and the staging support
the backend needs to expose so the test is repeatable instead of a 60-second
waiting game.

Companion to `RIDER_BROADCAST_DISPATCH_FRONTEND_GUIDE.md` (the integration
contract). That guide says *what to build*; this one says *how to prove it
works*.

> **Why this document exists.** The app's automated coverage
> (`test/ride_booking_broadcast_e2e_test.dart`, 21 tests) verifies every pure
> decision point on both sides — status mapping, captain hydration, and the
> notification-id plumbing that decides whether a losing rider's ring can be
> cancelled. What it cannot verify is anything that needs a server: the wave
> fan-out, the accept race, FCM delivery, and the OTP handshake. Those need two
> handsets and a live backend, and §5 lists what would make that practical.

---

## 0. Cast and setup

| Role | Account | Device | Notes |
|---|---|---|---|
| **Customer** | any user | A | Opens `RideHomeScreen` (Discover → bike icon, or any Book-Your-Transport tile) |
| **Rider (winner)** | onboarded + **live** rider | B | Must be within the first wave radius of the pickup |
| **Rider (loser)** | onboarded + live rider | C | Optional but required for §3 — the race is the part most likely to be wrong |

Preconditions on every rider device:

- onboarding `status` complete, go-live ON, and a **fresh GPS fix near pickup** —
  the waves select on last known position, so a rider whose location is an hour
  old is not in the first wave no matter where they are standing;
- notification permission granted, battery optimisation off (the ring uses a
  full-screen intent);
- security deposit satisfied **or** `freeRideUsed == false` (first ride is free
  — see the go-live gate).

Log filter for the whole ride-notification path, on both rider devices:

```
adb logcat | grep RIDE_NOTIF
```

That tag deliberately spans the background isolate too, so a push that arrives
while the app is killed still tells its half of the story.

---

## 1. Happy path — the ledger

Each row is one observable step. "Assert" is what must be true before moving on;
if a row fails, stop there — every later row inherits the failure.

### 1.1 Quote

| | |
|---|---|
| **Actor** | Customer (A) |
| **Call** | `GET rider-service/fare/riders/dynamic?pickupLatitude=…&pickupLongitude=…&dropLatitude=…&dropLongitude=…&orderFor=InCity&range_in_km=20&pincode=…&distance_in_km=…` |
| **UI** | Vehicle-select sheet lists one row per vehicle type with a fare |

**Assert**

- every row's `vehicleType` is a value from the real enum (`twoWheelerRider`,
  `autoTempo`, `eRickshaw`, `carMini`, `carSedan`, `suvCar`, `miniBus`,
  `pickupGoods`, `miniTruckGoods`, `largeTruckGoods`, `goods3Wheeler`,
  `goods4Wheeler`). Anything else is unbookable — the create call will be
  rejected with a `vehicleType` the server does not accept;
- `distance_in_km` is **road** distance (measured off the driving polyline), not
  straight-line. Slabs are built for road distance; sending the crow-flies number
  is how a quote ends up disagreeing with the order created from it;
- `orderFor` here is the same value §1.2 will send. Quoting under one and
  ordering under another is the other way the price moves between the button and
  the order.

### 1.2 Create

| | |
|---|---|
| **Actor** | Customer (A) |
| **Call** | `POST rider-service/fare/orders` |

```jsonc
{
  "orderType": "broadcast",        // ← the only thing that makes it a race
  "orderFor": "InCity",
  "pickupLocation": { "address": "…", "latitude": 23.23, "longitude": 77.43 },
  "dropLocation":   { "address": "…", "latitude": 23.20, "longitude": 77.46 },
  "fare": 120,
  "modeOfPayment": "postpaid",     // CASH → postpaid, ONLINE → prepaid
  "orderForWhom": "myself",
  "vehicleType": "twoWheelerRider"
  // NO selectedRiders — its presence turns this back into the hand-picked flow
}
```

**Assert**

- response carries `orderId` (`ORD-…`) **at the top level**, not wrapped in
  `data`. The app reads `response.data ?? response.response?.data` precisely
  because this service does not wrap; if that ever changes, say so before
  shipping it — a successful 201 would otherwise parse as a failure;
- `status` is `pending`;
- the customer lands on the searching screen. Record the `orderId` — **every
  later step on both devices is keyed on it**.

### 1.3 Waves ring the riders

| | |
|---|---|
| **Actor** | Server → Riders (B, C) |
| **Push** | data-only FCM, `operation: "broadcast_ride_request"` |
| **Socket** | `ride:broadcast:searching` → customer |

**Assert — customer**

- the searching screen shows wave progress (`wave N/total`, riders notified)
  from the socket, and the status poll continues to report `pending` in
  parallel. Polling is the source of truth; the socket only removes lag.

**Assert — every rung rider**

- the phone **rings** (loud, insistent, full-screen), it does not ding like a
  chat message. Verify in all three app states: foreground, background, killed;
- the push carries the customer-facing `orderId` **at the root of the decoded
  `payload`**:

```jsonc
data: {
  operation: "broadcast_ride_request",
  payload: "{\"orderId\":\"ORD-1784638670140\", …, \"metadata\":{\"Order_id\":\"6a5f…\"}}"
}
```

> ⚠️ **`metadata.Order_id` is not a substitute.** It holds the Mongo `_id`, a
> different id space; every `fare/orders/{orderId}/*` route 404s on it. The app
> deliberately refuses to fall back to it, so a push without the real `orderId`
> at the payload root degrades to a shared notification id — two concurrent
> requests then collide and §3's dismissal cannot target the right ring. If the
> root `orderId` is ever dropped from the payload, the ring becomes
> uncancellable. Treat it as a required field.

- the ring notification is posted under an id derived from that `orderId`, so a
  re-delivered FCM **replaces** the ring instead of starting a second ringing
  copy. Test this by re-sending the same push.

### 1.4 Accept — the race

| | |
|---|---|
| **Actor** | Rider B |
| **Call** | `POST rider-service/fare/orders/{orderId}/ride-action` `{"action":"accept"}` |

**Assert**

- 200 for the first rider;
- customer's `GET fare/orders/{orderId}/status` flips to `payment-pending` (then
  `confirmed`), with `metadata.assignedRider` populated;
- `metadata.assignedRider` carries enough to draw the captain card — at minimum
  `riderId` and `name`, ideally `vehicleInformation.registrationNo` /
  `.vehicleName` / `.vehicleType`, `profile_image`, `contact_no`, `rating`. A
  bare id is handled (the card renders and fills in from the location poll and
  the socket) but reads as a blank captain for the first few seconds;
- the customer screen switches from searching to tracking **without a manual
  refresh**, within one 3s poll — or instantly if `ride:queue:accepted` lands
  first.

Rider-side statuses that must all map to "captain attached" on the customer:
`payment-pending`, `confirmed`, `assigned`, `accepted`. See §4 for the full
table.

### 1.5 Pickup OTP

| | |
|---|---|
| **Actor** | Customer reads the OTP aloud → Rider B enters it |
| **Call** | `POST rider-service/fare/orders/{orderId}/start` `{"pickupOTP":"4821"}` |

**Assert**

- for a **passenger ride** (`jobInfo.isRide == true`), the OTP is returned to the
  **customer only** — the rider's order payload must not contain the digits, and
  the rider UI must not display them. Verification always goes through the
  server. Goods/parcel are the opposite: the rider holds the OTP and reads it to
  the shop/sender;
- on success the order becomes `in-progress` and the customer's tracking screen
  follows within one poll;
- a wrong OTP fails cleanly and does **not** advance the status.

### 1.6 Trip and completion

| | |
|---|---|
| **Actor** | Rider B |
| **Poll** | Customer: `GET fare/orders/{orderId}/rider-location` every ~5s |
| **Call** | `POST rider-service/fare/orders/{orderId}/complete` `{latitude, longitude}` |

**Assert**

- `rider-location` returns `{ rideActive, rider: { location, … } }` and the
  captain marker moves on the customer map;
- status reaches `completed`; the customer's polls **stop** (this is the signal
  the app uses to tear down every timer) and the completion screen appears;
- the ongoing-ride overlay clears on both devices.

---

## 2. Status vocabulary — the contract that must not drift

The customer app maps the server's `status` string onto the screen the user
sees. Anything unlisted falls back to `searching`, deliberately: an unknown
*terminal* state would strand a user with a live captain and no tracking. That
fallback means **a new status string is silently invisible** — coordinate before
introducing one.

| server `status` | customer screen | active? | captain attached? |
|---|---|---|---|
| `pending` | searching (waves running) | yes | no |
| `payment-pending` | tracking | yes | yes |
| `confirmed` | tracking | yes | yes |
| `in-progress` | on trip | yes | yes |
| `picked-up` | on trip | yes | yes |
| `completed` | completed | no | — |
| `rejected` | no riders found → rebook | no | — |
| `cancelled` | cancelled | no | — |

Hyphen, underscore and case are normalised (`payment-pending` ≡
`PAYMENT_PENDING`). `arrived`, `assigned`, `accepted`, `started`, `on-trip`,
`expired` and `no-riders-found` are also accepted as aliases.

Cancellation extras the customer needs, on the status payload:

| field | why |
|---|---|
| `cancelledBy` | `rider` / `captain` / `driver` vs `customer`. Without it a captain-cancelled ride reads to the customer like their own booking silently failed |
| `cancellationReason` | e.g. `TAKING_LONGER`, rendered as "Taking longer" |
| `cancelledAt` | ISO 8601 |

---

## 3. Negative paths — test these, they are where it breaks

### 3.1 Losing the race (rider C)

| | |
|---|---|
| **Call** | C's accept → **409** |
| **Push** | silent data push `operation: "broadcast_ride_closed"` |
| **Socket** | `ride:broadcast:closed` `{ orderId, reason }` |

**Assert on C**

- the ring **stops** and the incoming screen closes **quietly** — no error toast,
  no banner. A losing rider must never be alerted about a ride they cannot take;
- the 409 body should carry a machine-readable reason (`ALREADY_TAKEN`) so the
  client is not matching on the English string;
- the silent push must be `background` on iOS with no alert/sound, and must carry
  the `orderId` — it is the only thing identifying which ring to cancel;
- **both** the 409 and the push must work standing alone. A rider who never
  pressed accept only gets the push; a rider who pressed accept at the same
  moment as B only gets the 409. Test each in isolation.

### 3.2 No rider takes it

| | |
|---|---|
| **Trigger** | let every wave expire (~60s) |

**Assert** — status becomes `rejected`, socket emits `ride:broadcast:exhausted`,
and the customer gets a rebook prompt rather than an error. The socket ends the
search instantly; the poll must reach the same conclusion on its own if the
socket is dropped (test with the socket disconnected).

### 3.3 Customer cancels

`POST rider-service/fare/orders/{orderId}/cancel` `{ reason, comment? }` — from
both **before** assignment (during waves) and **after** a rider has accepted.

**Assert** — the assigned rider's screen and any ringing rider's notification
both clear; status is `cancelled` with `cancelledBy: "customer"`.

> The cancel-reason list is shipped in the app, not fetched — there is no
> `getCancelReasons` endpoint. If ops want to reword reasons without an app
> release, that endpoint is the ask.

### 3.4 Rider cancels after accepting

**Assert** — customer sees `cancelled` with `cancelledBy: "rider"` **and** a
reason, so the UI can explain it. Decide and document whether the order
re-broadcasts to a new wave or terminates; the app currently treats `cancelled`
as terminal and offers a rebook.

### 3.5 Delivery edge cases

- **App killed** on the rider device — the ring must still fire (background
  isolate) and tapping it must open the incoming screen with the right order;
- **Two concurrent requests** to the same rider — two distinct rings, and
  dismissing one must not dismiss the other;
- **Socket dropped** on the customer — polling alone must carry the whole
  lifecycle;
- **Push arrives after the race is over** (slow FCM) — the ring must be
  cancellable by the already-sent `broadcast_ride_closed`, or must self-expire
  (`timeoutAfter` 45s).

---

## 4. What the backend must guarantee

A short list of invariants the app depends on. Each one has already been the
cause of a bug, or is load-bearing enough to be worth stating.

1. **`orderId` at the root of the push payload.** Not only in `metadata`, and
   never only as the Mongo `_id`. It is the notification id, the dismissal key
   and the accept key.
2. **The create response is unwrapped.** `orderId` at the top level.
3. **`pickupOTP` goes to the customer for passenger rides**, and only to the
   rider for goods/parcel.
4. **`metadata.assignedRider` is populated the moment a rider wins** — ideally
   the full rider shape, not a bare id.
5. **409 on a lost accept** — not 400, not 200-with-an-error-body. The client
   branches on the status code.
6. **`broadcast_ride_closed` is silent** — data-only, `background` on iOS.
7. **Status strings stay in the §2 table.** Adding one without telling the app
   makes it invisible, not an error.
8. **`rideActive` on the rider-location response** so the customer map knows when
   to stop drawing a captain.

---

## 5. Staging support needed (the actual ask)

None of the below exists today, and each one is the difference between a test
that can run on every deploy and one that needs two people, a car park and a
stopwatch.

| # | Hook | Why | Suggested shape |
|---|---|---|---|
| 1 | **Wave timing override** | Every negative-path test currently costs a 60s wait. Ten test runs = ten minutes of watching a spinner | `POST fare/orders` accepts `debugWaveMs` in staging, or a per-env config |
| 2 | **Rider allowlist for a broadcast** | On a shared staging box the waves ring whoever is live; QA can't guarantee their own handset is rung, and real testers get spammed | staging-only `debugRiderIds: ["…"]` that scopes the race without turning it into the hand-picked flow |
| 3 | **Force-status (admin)** | Reaching `in-progress` needs a physical OTP handshake; reaching `completed` needs a trip. Testing the customer's completion screen shouldn't require both | `POST fare/orders/{orderId}/admin/status {status}` (the pattern already exists for `riders/orders/{id}/admin/status`) |
| 4 | **Seed a rider position** | The location poll and the moving marker can't be tested without physically moving | `POST riders/{riderId}/debug/location {lat,lng}` |
| 5 | **Replay a push** | Verifying the ring, and the silent dismissal, currently means re-running the whole flow | `POST debug/push {userId, operation, payload}` echoing exactly what dispatch would send |
| 6 | **Deterministic OTP in staging** | Reading a random OTP off a second device is the slowest step in the happy path | fixed `0000` when the env flag is set |
| 7 | **Bulk cleanup** | Aborted test runs leave `pending` orders that keep ringing riders | `POST debug/orders/cancel-all {userId}` |
| 8 | **A record of what was pushed** | When a ring doesn't fire, there is no way to tell "not sent" from "not delivered" from "delivered but not displayed" | `GET debug/notifications?orderId=…` returning the exact FCM body sent |

With 1, 3 and 5 alone the whole of §1 and §3 becomes a scripted run rather than a
manual one.

---

## 6. Known gaps (frontend side, for completeness)

Four features have no backend and are handled on-device — they are **not**
defects to file against the app:

| Feature | Current handling |
|---|---|
| Place search / recents / saved | Google Places + SharedPreferences on-device |
| Cancel reasons | Shipped list in the app |
| Fare raise ("+₹20") | **Disabled** (`kFareRaiseEnabled = false`) — there is no fare-bump endpoint, and shipping the chips would charge the user more for nothing |
| `quoteId` | Not issued by `fare/riders/dynamic`; the app carries `{vehicleType, fare}` instead. This means nothing binds the quoted fare to the created order — if fares are ever recomputed server-side on create, a quote token is the fix |

---

## 7. Automated coverage that already exists

`test/ride_booking_broadcast_e2e_test.dart` — `flutter test`, no backend needed.
21 tests walking the same lifecycle as §1 against the documented payloads:

- create with no `data` envelope → booking with `orderId` + OTP;
- `pending` → `payment-pending` (+ `assignedRider`) → `in-progress` →
  `completed`, plus the `rejected` and captain-cancelled branches;
- socket winner merging over poll data without blanking the captain card;
- the rider half: `broadcast_ride_request` is a ringing op, the `ORD-…` id is
  read from the payload root and never from `metadata.Order_id`, the ring's
  notification id is recomputable so `broadcast_ride_closed` can cancel it across
  the isolate boundary, and the action-button ids round-trip in both our own and
  the server's spelling;
- a cross-side assertion that the id the customer created is the id the rider's
  push names.

It does **not** cover: the wave fan-out, the accept race, FCM delivery, the OTP
handshake, or anything else that needs a server — those are §1 and §3, and §5 is
what would make them cheap to run.
