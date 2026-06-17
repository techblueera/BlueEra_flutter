# Multi-Shop (Multi-Stop) Orders — Frontend Integration Guide

Lets a user pick **several shops** in one order. The service sorts the shops
**furthest → nearest** from the user, shows riders near the **furthest** shop
(where the route begins), and — once a rider is booked — drives a multi-stop
navigation through every shop, ending at the **user's location**.

> Fully additive. All existing endpoints, payloads and single-stop orders are
> unchanged. Multi-stop behaviour only activates on the new endpoints below
> (orders flagged `isMultiStop: true`).

Base path: `/api/rider-service`
Auth: `Authorization: Bearer <jwt>` on every call.

---

## Route model

```
furthest shop (sequence 0)  ->  ...  ->  nearest shop (sequence n-1)  ->  USER (drop)
        = pickupLocation                                                    = dropLocation
```

The rider starts at the furthest shop and collects shop-by-shop while heading
toward the user, minimising backtracking.

---

## 1. Sort shops + find riders

`POST /fare/multi-shop/riders`

```json
{
  "userLocation": { "address": "Home", "latitude": 12.9300, "longitude": 77.6300 },
  "shops": [
    { "businessId": "shopA", "name": "Shop A", "address": "...", "latitude": 12.9700, "longitude": 77.5900 },
    { "businessId": "shopB", "name": "Shop B", "address": "...", "latitude": 12.9500, "longitude": 77.6100 }
  ],
  "orderFor": "grocery",
  "range_in_km": 5,
  "pincode": "560001"
}
```

- `pincode` is only required when `orderFor` is `InCity` or `Parcel` (used for
  fare-policy lookup). For `grocery` it is ignored.

**Response**

```json
{
  "sortedShops": [
    { "businessId": "shopA", "name": "Shop A", "address": "...", "latitude": 12.97, "longitude": 77.59, "sequence": 0, "distanceFromUserKm": 5.1 },
    { "businessId": "shopB", "name": "Shop B", "address": "...", "latitude": 12.95, "longitude": 77.61, "sequence": 1, "distanceFromUserKm": 3.2 }
  ],
  "furthestShop": { "businessId": "shopA", "name": "Shop A", "latitude": 12.97, "longitude": 77.59, "address": "..." },
  "routeDistanceKm": 9.4,
  "riders": {
    "Bike": {
      "users": [
        { "riderId": "...", "name": "...", "profile_image": "...", "distance": "0.80 km", "rating": 4.7, "vehicleInformation": { "...": "..." }, "totalOrders": 120 }
      ],
      "fare": 95
    }
  }
}
```

- `sequence` `0` = furthest (visited first). `distance` on each rider is the
  distance from the **furthest shop**.
- `riders` is grouped by vehicle type (same shape as `GET /fare/riders`).
- `riders` is `{}` when none are nearby.

---

## 2. Create the order (book a rider)

`POST /fare/multi-shop/orders`

```json
{
  "selectedRiders": ["riderUserId1", "riderUserId2"],
  "userLocation": { "address": "Home", "latitude": 12.93, "longitude": 77.63 },
  "shops": [
    {
      "businessId": "shopA", "name": "Shop A", "address": "...",
      "latitude": 12.97, "longitude": 77.59,
      "items": [ { "variantId": "v1", "inventoryId": "i1" } ]
    },
    {
      "businessId": "shopB", "name": "Shop B", "address": "...",
      "latitude": 12.95, "longitude": 77.61,
      "items": [ { "variantId": "v2", "inventoryId": "i2" } ]
    }
  ],
  "orderFor": "grocery",
  "modeOfPayment": "prepaid",
  "fare": 95,
  "orderType": "standard",
  "orderForWhom": "myself"
}
```

- `orderType`:
  - `standard` → all `selectedRiders` are notified; first to accept wins via
    `PATCH /fare/orders/:orderId/status` `{ "action": "accept" }`.
  - `fare-call` → riders are called sequentially (WebRTC). Same flow/events as
    existing fare-call orders.
- `orderForWhom: "someoneElse"` requires `contactNo`.
- `items` per shop are optional but recommended (stored on the `GroceryOrder`,
  reusing all existing grocery item/payment/availability endpoints).
- Returns the created `RideOrder` (`isMultiStop: true`, with the ordered
  `stops[]`). `pickupLocation` = furthest shop, `dropLocation` = user.

Server enforces the existing 3-minute per-user order cooldown (`429`).

---

## 3. Booking → navigation

Booking uses the **existing** lifecycle endpoints unchanged:

| Step | Endpoint |
|------|----------|
| Accept (standard) | `PATCH /fare/orders/:orderId/status` `{ "action": "accept" }` |
| Accept (fare-call) | rider accepts the call (existing flow) |
| Start ride | `POST /fare/orders/:orderId/start` `{ "pickupOTP" }` |
| Complete (final drop) | `POST /fare/orders/:orderId/complete` `{ "latitude", "longitude" }` |

On accept (and again on start), the server emits the additive socket event
**`ride:navigation`** to both rider and user with the full waypoint list.

---

## 4. Per-stop progress (rider app)

As the rider reaches / finishes each shop:

`PATCH /fare/multi-shop/orders/:orderId/stops/:businessId/arrive`
`PATCH /fare/multi-shop/orders/:orderId/stops/:businessId/pickup`

- Only the assigned rider may call these.
- Each emits **`ride:stop:update`** to rider + user.
- The final drop is still the existing `complete` endpoint.

---

## 5. Socket events (additive)

Delivered via the chat service Socket.IO connection (`wss://chat.blueera.ai`),
same transport as existing ride events.

### `ride:navigation`
Fired on booking accept and on ride start.

```json
{
  "orderId": "ORD-1776407315262",
  "isMultiStop": true,
  "totalStops": 2,
  "waypoints": [
    { "type": "shop", "businessId": "shopA", "name": "Shop A", "address": "...", "lat": 12.97, "lng": 77.59, "sequence": 0, "status": "pending" },
    { "type": "shop", "businessId": "shopB", "name": "Shop B", "address": "...", "lat": 12.95, "lng": 77.61, "sequence": 1, "status": "pending" },
    { "type": "drop", "address": "Home", "lat": 12.93, "lng": 77.63, "sequence": 2, "status": "pending" }
  ]
}
```

Feed `waypoints` (in order) straight into the maps SDK as the multi-stop route.

### `ride:stop:update`
Fired when a stop advances.

```json
{
  "orderId": "ORD-1776407315262",
  "businessId": "shopB",
  "sequence": 1,
  "status": "picked-up",
  "arrivedAt": "2026-06-17T06:30:00.000Z",
  "pickedUpAt": "2026-06-17T06:34:00.000Z"
}
```

`ride:started` / `ride:completed` keep their existing shape; for multi-stop
orders `rideDetails` additionally carries `isMultiStop: true` and `stops`
(the waypoint array). Old clients ignore the extra keys.

---

## Backward compatibility

- New optional schema fields only (`RideOrder.isMultiStop`, `RideOrder.stops[]`,
  geo fields on `GroceryOrder.businesses[]`). Existing documents are valid as-is.
- New routes under `/fare/multi-shop`; no existing route changed.
- Existing socket payloads only gain optional keys, guarded by `isMultiStop`.
- Single-stop orders never set `isMultiStop`, so every multi-stop code path is a
  no-op for them.
