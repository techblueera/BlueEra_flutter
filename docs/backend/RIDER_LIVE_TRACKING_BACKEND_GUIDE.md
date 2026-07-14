# Rider Live Location Tracking — Backend Confirmation Guide

**Purpose:** During an active ride/order, the customer's app shows a live map that
should track the rider in real time. This document describes the exact contract
the Flutter app now implements so the **backend team can confirm the server side
relays the data correctly**.

**Status of the Flutter side:** ✅ Done. The rider app now publishes its position
throughout the ride (heartbeat + retry, ~3–5 s cadence). The customer app already
consumes the live-stream and rebuilds its map reactively. What remains is to
**verify the server relays rider POSTs onto the customer's SSE** (items in
[§5 Checklist](#5-backend-confirmation-checklist)).

---

## 1. The two endpoints in play

| Role | Direction | Method | Endpoint |
|------|-----------|--------|----------|
| **Rider → server** (producer) | write | `POST` | `map-service/api/provider/location` |
| **Server → customer** (consumer) | read | `GET` (SSE) | `https://map.beapp.in/api/provider/live-stream/{riderId}` |

The server is the bridge between them: it must take each rider POST and push it
out on the SSE for that rider, so every customer subscribed to that rider's
`live-stream` receives the update.

---

## 2. Write contract — what the rider sends

Every ~3–5 seconds during a ride the rider app calls:

```
POST map-service/api/provider/location
Authorization: Bearer <riderJwt>
Content-Type: application/json

{
  "userId": "<riderUserId>",   // the rider's own user id (global userId)
  "lat": 26.7841,              // flat decimal degrees
  "lng": 80.9018
}
```

Notes:
- `userId` is the **rider's** user id (the logged-in rider's global `userId`).
- Coordinates are sent as **flat `lat` / `lng`**, NOT GeoJSON.
- This is the **same endpoint** already used by the discovery "go live" service,
  so ingestion almost certainly already works — please confirm anyway.

---

## 3. Read contract — what the customer expects

The customer app opens an SSE stream:

```
GET https://map.beapp.in/api/provider/live-stream/{riderId}
Authorization: Bearer <customerJwt>
Accept: text/event-stream
```

`{riderId}` is the **rider's user id** (the customer knows it from the accepted
order — the `rider.userId` on the order/ride object).

The app parses each `data:` line as JSON and expects this shape:

```
data: {
  "location": {
    "coordinates": [80.9018, 26.7841]   // GeoJSON order: [lng, lat]
  },
  "status": "in_progress"               // optional; see below
}
```

Parsing rules the app enforces (do not change without telling frontend):
- `location.coordinates[0]` → **longitude**
- `location.coordinates[1]` → **latitude**
- If `status` is `"completed"` or `"delivered"`, the app treats the ride as
  finished, closes the stream, and stops updating the map.

> ⚠️ **Format mismatch to bridge:** the rider POSTs **flat `lat`/`lng`**, but the
> customer SSE expects **GeoJSON `location.coordinates: [lng, lat]`**. The server
> is responsible for this reshape. Please confirm the live-stream emits the
> GeoJSON shape above.

---

## 4. Behaviours the backend must guarantee

1. **Real-time relay.** When a rider POST lands, the update should be pushed onto
   that rider's `live-stream` **immediately** (or within ~1 s), not only on a
   server-side polling interval. The customer cadence is only as fast as the
   server flushes.

2. **ID symmetry.** The rider posts keyed by `userId`; the customer subscribes on
   `live-stream/{riderId}`. These must resolve to the **same provider identity**
   server-side. If the customer's `riderId` and the rider's `userId` are different
   id spaces, the stream will be empty even though POSTs succeed.

3. **Stream not gated shut during a ride.** If the `live-stream` only emits when
   the backend considers the provider "active", please confirm an **accepted ride**
   counts as active (not only discovery "go live"). Otherwise the customer gets
   nothing even while the rider is posting.

4. **Heartbeat / TTL tolerance.** The rider app re-sends its **last known
   coordinate every ~5 s even when stationary** (red light, waiting at pickup),
   specifically so the provider stream is not auto-closed after silence. Please
   confirm the provider auto-close timeout is **longer than ~30 s** so a couple of
   missed pings don't drop the stream. (The discovery service already relies on a
   ~5-minute window — same mechanism.)

5. **Completion signal (nice to have).** If the server emits
   `{"status":"completed"}` (or `"delivered"`) on the stream when the ride ends,
   the customer map cleanly stops. Without it, the app falls back to closing on
   `onDone` when the server ends the SSE.

---

## 5. Backend confirmation checklist

Please confirm each item:

- [ ] `POST map-service/api/provider/location` accepts `{ userId, lat, lng }` and
      returns 2xx.
- [ ] A successful POST is **relayed onto** `GET /api/provider/live-stream/{userId}`
      in real time.
- [ ] The live-stream emits `{"location":{"coordinates":[lng,lat]}, ...}`
      (GeoJSON, lng first) — i.e. the server reshapes flat lat/lng → GeoJSON.
- [ ] `riderId` used by the customer to subscribe == `userId` the rider posts with
      (same identity).
- [ ] An **accepted/active ride** is sufficient for the stream to emit (not gated
      on discovery "go live").
- [ ] Provider auto-close timeout is comfortably longer than the ~5 s heartbeat
      (≥ 30 s recommended).
- [ ] (Optional) A completion event `{"status":"completed"|"delivered"}` is emitted
      when the ride/order finishes.

---

## 6. How to test end-to-end (two devices)

1. Device A (rider) accepts a ride → opens the pickup navigation screen.
2. Device B (customer) opens the live-tracking map for that order.
3. Move Device A (or mock-move GPS). Watch:
   - **Backend log:** `POST /provider/location` arriving every ~3–5 s with the
     rider's `userId` and moving coordinates.
   - **Customer map (Device B):** the rider marker should move within a few
     seconds of each POST.
4. Stop Device A (simulate a red light). Confirm POSTs **keep arriving** (heartbeat)
   and the customer stream stays open (marker holds position, doesn't disappear).
5. Complete the ride. Confirm the customer stream ends / emits a completion status.

**If POSTs return 2xx but the customer marker never moves**, the gap is one of the
[§4](#4-behaviours-the-backend-must-guarantee) items — most likely the ID mapping
(item 2) or a ride-state gate (item 3).

---

## 7. Flutter reference (for the frontend side)

| Concern | File |
|---------|------|
| Rider publishes (heartbeat + retry, ref-counted across screen handoff) | `lib/features/chat/auth/service/ride_location_publisher.dart` |
| POST helper (`publishLocation`) | `lib/features/chat/auth/service/location_update_service.dart` |
| Rider pickup-navigation screen (feeds GPS to publisher) | `lib/features/chat/view/call_screen/rider_call/rider_pickup_navigation_screen.dart` |
| Rider passenger-destination screen (feeds GPS to publisher) | `lib/features/chat/view/call_screen/rider_call/passenger_destination_screen.dart` |
| Customer SSE reader | `lib/features/chat/auth/stream/rider_response_stream.dart` |
| Customer stream → Rx lat/lng | `lib/features/chat/auth/controller/live_trach_rider_controller.dart` |
| Customer map widgets (rebuild on Rx change) | `track_rider_live_location_page.dart`, `fare_call_queue_screen.dart` |
