# Ride Booking — Frontend Integration Guide

Backend contract for the Rapido-style customer ride-booking flow that lives in
`lib/features/ride_booking/`.

> **This is a new, standalone flow.** It does **not** reuse the older
> `rider-service/fare/*` endpoints that back the existing
> `Discover/view/book_your_transport/` screens. Both flows coexist; neither
> should be changed to accommodate the other.

**Service prefix:** `ride-booking-service/`
**Path constants:** `lib/core/api/apiService/ride_booking_service_api.dart`
**Repo:** `lib/features/ride_booking/repo/ride_booking_repo.dart`

---

## 0. Current app state

The Flutter side is complete and running against **stub data**. A single flag
gates it:

```dart
// lib/features/ride_booking/controller/ride_booking_controller.dart
static const bool _useStub = true;   // ← flip to false when the API is live
```

Every network method is written as `if (_useStub) return _stubX();`, so
flipping that one constant switches the whole flow onto the real API with no
other code change. The `// stubs` block at the bottom of the controller can be
deleted at that point.

---

## 1. Response envelope

All endpoints use the app's standard envelope. `ResponseModel.data` reads
`response.data['data']`, so the payloads below are what belongs under `data`.

```jsonc
{
  "status": true,
  "message": "OK",
  "data": { /* payload described per-endpoint below */ }
}
```

Auth: the standard `Authorization: Bearer <token>` header, applied by
`ApiBaseHelper` — no per-endpoint handling needed.

Errors: return a non-2xx with a human-readable `message`. The app surfaces it
directly, so write messages for end users, not developers.

---

## 2. Places

### `GET ride-booking-service/places/recent?limit=10`

Recent destinations for the home list (screenshot 1).

```jsonc
{
  "places": [
    {
      "id": "plc_9f1",
      "title": "Rani Kamlapati Railway Station",
      "subtitle": "Habib Ganj, Bhopal, Madhya Pradesh, India",
      "latitude": 23.2333,
      "longitude": 77.4344,
      "isSaved": false
    }
  ]
}
```

`title` is the short name, `subtitle` the full address — the UI renders them
as two distinct lines and never re-splits a single string.

The parser also accepts GeoJSON in place of the flat lat/lng:
`"location": { "type": "Point", "coordinates": [lng, lat] }`. Pick one and be
consistent.

### `GET ride-booking-service/places/search?q=&lat=&lng=`

Autocomplete, proxied server-side so the Google key stays off the device.
`lat`/`lng` are the user's current position and should **bias** results — a
search for "New Market" must return the one in their city first.

Same payload as `/recent`. Called on a 350ms debounce, minimum 2 characters.

### `POST ride-booking-service/places/search`

Records a chosen place into recents. Body is a `RidePlace`. Fire-and-forget on
the client — a failure is swallowed and never blocks navigation.

### `GET ride-booking-service/places/pickup-points?lat=&lng=`

Backs the confirm-pickup map (screenshot 2). Should return **both**:

1. the reverse-geocoded address for the exact coordinate, and
2. nearby snapped pickup points (gate entrances, corners) for the "Select a
   nearby point for easier pickup" affordance.

```jsonc
{
  "resolved": {
    "title": "315/2C",
    "subtitle": "Saket Nagar, Habib Ganj, Bhopal, Madhya Pradesh 462024, India",
    "latitude": 23.2076,
    "longitude": 77.4645
  },
  "nearby": [ /* RidePlace[] */ ]
}
```

> **Client TODO on wiring:** `_resolvePin()` in
> `ride_confirm_pickup_screen.dart` currently returns a synthetic address.
> Point it at this endpoint when the flag flips.

### `GET | POST | DELETE ride-booking-service/places/saved`

Hearted places. `POST` body is a `RidePlace`; `DELETE /places/saved/{id}`
removes one. The client updates the heart optimistically and rolls back on
failure, so respond quickly and idempotently.

---

## 3. Fare quotes

### `POST ride-booking-service/quotes`

```jsonc
// request
{
  "pickup": { "title": "…", "subtitle": "…", "latitude": 23.2076, "longitude": 77.4645 },
  "drop":   { "title": "…", "subtitle": "…", "latitude": 23.2599, "longitude": 77.4126 },
  "stops":  []
}
```

```jsonc
// response
{
  "options": [
    {
      "code": "BIKE",
      "name": "Bike",
      "description": "Quick Bike rides",
      "badge": "FASTEST",
      "fare": 40,
      "seats": 1,
      "pickupEtaMinutes": 2,
      "dropEtaMinutes": 12,
      "quoteId": "qt_7c2a91"
    }
  ]
}
```

| Field | Notes |
|---|---|
| `code` | Stable machine code. Known: `BIKE`, `AUTO`, `CAB_ECONOMY`, `CAB_DAILY`, `CAB_PREMIUM`, `PARCEL`. Unknown codes render with a generic cab icon — safe to add new ones. |
| `badge` | Optional. `FASTEST` / `CHEAPEST`. Rendered as a green pill. Omit for most rows. |
| `dropEtaMinutes` | Minutes from **now** to drop-off. The client converts this to the "Drop 3:16 pm" clock label, so do **not** send a formatted time. |
| `quoteId` | **Required.** Short-lived (suggest 3–5 min) token echoed back on booking so the fare shown is the fare charged. |

Return options in display order — the client does not re-sort, and it
pre-selects `options[0]`.

Empty `options` renders "No vehicles available for this route right now."

---

## 4. Booking

### `POST ride-booking-service/bookings`

```jsonc
// request
{ "quoteId": "qt_7c2a91", "vehicleCode": "BIKE", "paymentMode": "CASH" }
```

`paymentMode` is `CASH` | `ONLINE`.

Response is a full booking object (same shape as the status poll, §5), with
`status: "SEARCHING"`. The `rideId` keys everything that follows.

Reject an expired `quoteId` with a clear message — the client shows it and
returns the user to the vehicle list to re-quote.

### `GET ride-booking-service/bookings/{rideId}/status`

Polled **every 3s** while the booking is active. This is the single source of
truth for screen transitions.

```jsonc
{
  "rideId": "rd_4419",
  "status": "ASSIGNED",
  "pickup": { /* RidePlace */ },
  "drop":   { /* RidePlace */ },
  "vehicleCode": "BIKE",
  "vehicleName": "Bike",
  "fare": 91,
  "paymentMode": "CASH",
  "startOtp": "3464",
  "searchProgress": 0.4,
  "pickupEtaMinutes": 2,
  "captainDistanceMeters": 775,
  "captain": {
    "id": "cap_88",
    "name": "Akash Singh",
    "phone": "9876543210",
    "photoUrl": "https://…",
    "vehicleNumber": "MP04NW2444",
    "vehicleModel": "FZ",
    "rating": 4.8,
    "latitude": 23.2010,
    "longitude": 77.4580
  }
}
```

**Status values and what each does in the app:**

| `status` | App behaviour |
|---|---|
| `SEARCHING` | Stays on the searching screen (screenshot 4). |
| `ASSIGNED` / `ACCEPTED` | **Replaces** the searching screen with tracking (screenshot 5). Requires `captain` to be populated. |
| `ARRIVED` | Tracking screen; ETA banner still shown. |
| `ON_TRIP` / `STARTED` | Tracking screen; banner switches to "On the way to drop". |
| `COMPLETED` | Unwinds to the ride home screen with a completion message. |
| `CANCELLED` | Unwinds to home with a cancellation message. |
| `NO_RIDERS_FOUND` / `EXPIRED` | Pops back with "No captains available right now." |

Anything unrecognised falls back to `SEARCHING` — so never invent a status to
mean "finished", it will hang the user on the searching screen.

`startOtp` should be present from `ASSIGNED` onward — it renders as the four
boxed PIN digits.

`searchProgress` (0–1) is optional. The client already animates its own bar to
90% and only completes it on assignment, so this is advisory.

### `GET ride-booking-service/bookings/{rideId}/captain-location`

Polled **every 5s**, but only once a captain is assigned. Kept separate from
the status poll so the marker can move smoothly without re-sending the whole
booking.

```jsonc
{ "latitude": 23.2010, "longitude": 77.4580, "pickupEtaMinutes": 2, "distanceMeters": 775 }
```

Return the last known fix rather than 404-ing during a GPS gap — the client
keeps the previous marker and retries, so a transient null is harmless but an
error is noisier than it needs to be.

### `POST ride-booking-service/bookings/{rideId}/raise-fare`

```jsonc
{ "amount": 20 }
```

Backs the "+₹10 / +₹20 / +₹30 / +₹40" chips (screenshot 4). Should re-broadcast
the sweetened fare to nearby captains and return the new total. The client
updates optimistically and reconciles from the next status poll.

---

## 5. Cancellation

### `GET ride-booking-service/cancel-reasons`

Server-driven so ops can reword without an app release.

```jsonc
[
  { "code": "TAKING_LONGER",      "label": "Taking longer than expected" },
  { "code": "BETTER_PRICE",       "label": "Found better price elsewhere" },
  { "code": "CHANGE_OF_PLANS",    "label": "Change of plans" },
  { "code": "CAPTAIN_NOT_MOVING", "label": "Captain not moving towards pickup" },
  { "code": "OTHERS",             "label": "Others", "note": "A ₹10 fee may apply" }
]
```

`note` is optional secondary copy — use it for cancellation-fee warnings.

Cached for the session after the first successful fetch. If it fails, the app
falls back to the built-in list above so cancelling is never blocked.

### `POST ride-booking-service/bookings/{rideId}/cancel`

```jsonc
{ "reasonCode": "CHANGE_OF_PLANS", "comment": "optional free text" }
```

On success the client stops all polling and unwinds to the home screen.

Cancelling an already-cancelled or completed ride should return **success**,
not an error — the user's intent is satisfied either way, and a race between
the cancel tap and a status poll shouldn't surface as a failure.

---

## 6. Screen ↔ endpoint map

| # | Screen | File | Endpoints |
|---|---|---|---|
| 1 | Home / "Where do you want to go?" | `ride_home_screen.dart` | `places/recent`, `places/saved` |
| 2 | Destination search | `ride_destination_search_screen.dart` | `places/search` |
| 3 | Confirm pickup | `ride_confirm_pickup_screen.dart` | `places/pickup-points` |
| 4 | Vehicle + fare | `ride_vehicle_select_screen.dart` | `quotes`, `bookings` |
| 5 | Searching | `ride_searching_screen.dart` | `bookings/{id}/status`, `raise-fare` |
| 6 | Tracking | `ride_tracking_screen.dart` | `bookings/{id}/status`, `captain-location` |
| 7 | Trip details sheet | `ride_trip_details_sheet.dart` | — (renders cached booking) |
| 8 | Cancel reason + confirm | `ride_cancel_sheets.dart` | `cancel-reasons`, `bookings/{id}/cancel` |

---

## 7. Polling summary

| Endpoint | Interval | Active when |
|---|---|---|
| `bookings/{id}/status` | 3s | From booking creation until a terminal status |
| `bookings/{id}/captain-location` | 5s | Only from `ASSIGNED` onward |

Both stop permanently on `COMPLETED` / `CANCELLED` / `NO_RIDERS_FOUND`, and on
controller disposal. Overlapping requests are guarded client-side, so a slow
response delays the next tick rather than stacking.

If push (FCM) delivery of assignment events is added later, keep the status
endpoint as the reconciliation path — the client is built to poll and treats
the poll as authoritative.

---

## 8. Open items

- **Route geometry.** The vehicle screen currently draws a straight line
  between pickup and drop. If `quotes` returns an encoded polyline, the client
  can render the real road route — add `"polyline": "<encoded>"` to the quote
  response and it can be wired in.
- **Multi-stop.** `stops[]` is modelled end-to-end on the client but the
  "Add stop" button is a stub. Confirm whether quotes should price stops
  before that is enabled.
- **Offers.** The Offers button on the fare bar is a placeholder pending a
  promotions contract.
