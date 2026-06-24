# Rider Route + En-Route Order Discovery & Claim — Frontend Integration Guide

## What this feature does

A rider already driving a fixed pickup→drop path (e.g. a Zomato/Swiggy run) can declare
that **route**. Any open order whose **pickup AND drop both fall within `radiusKm`
(default 1 km) of that route corridor** — and that matches the rider's vehicle-use
preference (ride vs goods) — becomes visible and claimable, so the rider earns extra
without leaving their path.

Purely additive: existing booking/accept flows are unchanged. All endpoints are under the
existing rider service (`https://be.beapp.in/api/rider-service`), Bearer-auth as the rider.

---

## Flow

```
1. Rider starts a run → POST /riders/routes (pickup, drop, optional road polyline)
2. Rider opens "orders on my route":
     GET  /riders/routes/orders          (list, poll)
     GET  /riders/routes/orders/stream   (SSE, live)
   + push notification ROUTE_ORDER_AVAILABLE when a new matching order is created
3. Rider taps an order → POST /riders/orders/:orderId/claim  (first claim wins)
4. Claimed order behaves like any accepted order (same chat card / notifications / OTP cards).
5. Rider finishes / goes off-route → PATCH /riders/routes/active/end
```

---

## Endpoints

### 1. Create / activate a route
`POST /riders/routes`
```json
{
  "pickup": { "latitude": 30.3502, "longitude": 78.0770, "address": "Start" },
  "drop":   { "latitude": 30.3165, "longitude": 78.0322, "address": "End" },
  "path":   [[78.0770,30.3502], [78.06,30.34], [78.0322,30.3165]],
  "radiusKm": 1,
  "expiresInMinutes": 240
}
```
- `path` optional — pass the app's road polyline as `[[lng,lat], ...]` (GeoJSON order!).
  Omit it to use a straight pickup→drop corridor.
- Creating a route **supersedes** the rider's previous active route (one active at a time).
- `201` → the route doc (includes `corridor` polygon, `expiresAt`).

### 2. Get active route
`GET /riders/routes/active` → `{ "route": {...} | null }`

### 3. End active route
`PATCH /riders/routes/active/end` → `{ "message": "Route ended.", "ended": 1 }`

### 4. List en-route orders
`GET /riders/routes/orders` → `{ "routeId": "...", "count": N, "orders": [ RideOrder, ... ] }`
- Returns pending, unassigned, **standard** orders on the corridor (pickup+drop) that match
  the rider's preference. `{ orders: [] }` when none / no active route.

### 5. Live stream of en-route orders
`GET /riders/routes/orders/stream` — `text/event-stream`.
- Each `data:` frame: `{ "routeId": "...", "orders": [...] }` (or `{ route: null, orders: [] }`).
- Re-emits whenever a relevant order changes. Mirrors the existing
  `GET /riders/orders/requested/stream` SSE pattern — reuse the same client handling
  (EventSource + keep-alive comments).

### 6. Claim an en-route order
`POST /riders/orders/:orderId/claim`  (`:orderId` = RideOrder `_id` or `orderId`)
- `200` → claimed order (status `payment-pending`, `assignedRider` = you).
- `409` → already taken / claimed by another rider (first-claim-wins race; show "just taken").
- `422` → order not on your route, or preference mismatch.
- `400` → you have no active route. `404` → order not found.

> After a successful claim the order proceeds through the **normal** lifecycle — the same
> accept notifications, chat accept card, multi-stop navigation, and chat-dispatch OTP cards
> fire. No special-casing needed downstream.

---

## Push notification

`operation: "ROUTE_ORDER_AVAILABLE"` with `data.metadata.Order_id` + `data.metadata.orderFor`.
Sent to riders whose active route corridor covers a newly created order (pickup+drop) and
whose preference matches. Tapping it should open the order and offer **Claim**.

---

## Matching rules (so the UI can set expectations)
- Order **pickup AND drop** must both be within `radiusKm` of the route corridor.
- Order must be `pending`, unassigned, `orderType: "standard"` (fare-call queue orders are excluded).
- Rider preference must match the order category (ride: InCity/OutStation/HourlyRental;
  goods: product/grocery/food/medical/Parcel) — same `vehicleUsesType` rule as `/fare/riders`.
- The rider's own orders and orders they previously rejected are excluded.

## Backward compatibility
- New endpoints + a new `RiderRoute` collection + additive 2dsphere indexes. Nothing removed.
- Existing accept endpoint (`PATCH /fare/orders/:id/status`) and its selected-rider auth are
  unchanged; `claim` is a separate, parallel path.
- Old app builds keep working; routes feature is opt-in per new build.

## Quick reference
| Action | Call |
|---|---|
| Start route | `POST /riders/routes` |
| Active route | `GET /riders/routes/active` |
| End route | `PATCH /riders/routes/active/end` |
| List en-route orders | `GET /riders/routes/orders` |
| Live en-route orders | `GET /riders/routes/orders/stream` (SSE) |
| Claim order | `POST /riders/orders/:orderId/claim` |
| Push | `ROUTE_ORDER_AVAILABLE` |
