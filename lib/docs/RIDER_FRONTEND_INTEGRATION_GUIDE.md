# Rider Service — Frontend Integration Guide (complete & self-contained)

Covers every rider-facing flow and its APIs: job-type awareness, booking (standard /
chat self-pickup / multi-shop / fare-call), en-route order discovery & claim, the
incoming-call screen, notifications, and the OTP handoff (current flipped direction),
including multi-shop per-shop pickup OTPs.

- **Base URL:** `https://be.beapp.in/api/rider-service`
- **Auth:** `Authorization: Bearer <jwt>` on every endpoint unless stated. The JWT identifies the caller (rider / customer / shop) — the backend authorizes by role.
- **IDs:** `orderId` is the human id (`ORD-...`); endpoints that take `:orderId` accept the Mongo `_id` **or** the `orderId`.
- All new response fields are **additive** — older app builds can ignore them.

---

## 1. Job descriptor — "what is this job?"

Every order a rider sees now carries a descriptor derived from `orderFor`, so the rider
knows whether it is a passenger **ride**, a **goods** pickup, or a **parcel** delivery.

| `orderFor` | `jobType` | `jobLabel` | `riderTask` |
|---|---|---|---|
| `InCity` / `OutStation` / `HourlyRental` | `ride` | Passenger / Outstation / Hourly rental ride | Pick up and drop the passenger |
| `Parcel` | `parcel` | Parcel delivery | Collect the parcel and deliver it |
| `grocery` / `food` / `medical` / `product` | `goods` | Grocery / Food / Medicine / Goods pickup | Collect the order from the shop and deliver it |

Two extra fields are used on the call screen: `callTitle` (e.g. "Incoming Pickup Request")
and `callBody` (e.g. "Incoming grocery pickup request").

**`jobInfo` object** (attached to route-order list/claim responses):
```json
{ "jobType":"goods", "orderFor":"grocery", "jobLabel":"Grocery pickup",
  "riderTask":"Collect the order from the shop and deliver it",
  "callTitle":"Incoming Pickup Request", "callBody":"Incoming grocery pickup request" }
```
The same `jobType` / `jobLabel` / `riderTask` are also flattened into notification `data`
and into fare-call `metadata.rideDetails`. **UI rule:** header = `jobLabel`, sub-line = `riderTask`.
If `jobInfo` is absent (legacy), derive it client-side from `orderFor` using the table above.

---

## 2. Booking flows at a glance

| Flow | How a rider receives it | Create endpoint |
|---|---|---|
| **Standard** | push `RIDE_ORDER_RECEIVED` to the customer-selected riders | `POST /fare/orders` |
| **Chat self-pickup → delivery** | customer dispatches a rider from a self-pickup chat card | `POST /fare/chat-dispatch/orders` |
| **Multi-shop** | one order visiting several shops, then the customer | `POST /fare/multi-shop/orders` |
| **Fare-call (call queue)** | sequential WebRTC call to each selected rider | `POST /fare/orders` with `orderType:"fare-call"` |
| **En-route** | rider claims an open order on their declared route | `POST /riders/orders/:id/claim` |

---

## 3. Find riders & create orders

### 3.1 Find nearby riders (with fare)
`GET /fare/riders`
Query: `orderFor`, `pickupLatitude`, `pickupLongitude`, `dropLatitude`, `dropLongitude`,
`range_in_km` (opt, default 5), `pincode` (required for `InCity`/`Parcel`), `distance_in_km` (opt).
Response — grouped by vehicle type, only preference-matching riders:
```json
{ "twoWheelerRider": { "users": [ { "riderId":"...", "name":"...", "distance":"1.2 km",
   "rating":4.6, "vehicleInformation":{...}, "totalOrders":12 } ], "fare": 60 } }
```
`{}` is valid → "no riders available".

### 3.2 Create standard ride order
`POST /fare/orders` (Bearer = customer). `orderFor` ∈ `InCity|OutStation|HourlyRental|Parcel`.
```json
{ "selectedRiders":["riderId1"], "pickupLocation":{"address":"","latitude":0,"longitude":0},
  "dropLocation":{"address":"","latitude":0,"longitude":0}, "receiverUserId":null,
  "orderFor":"InCity", "modeOfPayment":"prepaid", "fare":60,
  "orderForWhom":"myself", "contactNo":null, "orderType":"standard",
  "tripType":null, "returnDate":null, "intermediateStops":null,
  "packageHours":null, "packageKilometers":null,
  "parcels":null, "recipientName":null, "recipientPhone":null }
```
`201` → the `RideOrder` (incl. `pickupOTP`, `deliveryOTP`, `status:"pending"`). Selected riders
get `RIDE_ORDER_RECEIVED`. `429` if the customer created an order in the last 3 min.

### 3.3 Rider accept / reject
`PATCH /fare/orders/:orderId/status` (Bearer = rider) body `{ "action":"accept" }` or `"reject"`.
Only a rider in `selectedRiders`/`potentialRiders` may act. On accept: `status → payment-pending`,
`assignedRider` set, customer notified `RIDE_ORDER_ACCEPTED`.

---

## 4. Chat self-pickup → rider delivery

Customer turns a self-pickup order (grocery/food/product/homemade) into a delivery:
**shop = pickup, customer = drop**.

1. Find riders near the shop: `GET /fare/riders` with `pickupLatitude/Longitude = shop`,
   `dropLatitude/Longitude = customer`, `orderFor = grocery|food|product|medical`.
2. `POST /fare/chat-dispatch/orders` (Bearer = customer):
```json
{ "selfpickupOrderId":"GROCERY_ORDER_ID", "selfpickupType":"selfpickup",
  "businessId":"SHOP_USER_ID",
  "shopLocation":{"latitude":0,"longitude":0,"address":"Shop"},
  "dropLocation":{"latitude":0,"longitude":0,"address":"Home"},
  "orderFor":"grocery", "selectedRiders":["riderId1"],
  "modeOfPayment":"prepaid", "fare":45 }
```
`201` → `RideOrder` with `orderSource:"chat-dispatch"`. `400` invalid · `429` recent dup.
3. Rider accepts (§3.3) → OTP cards appear in chat (see §8).

---

## 5. Multi-shop orders (one order, several shops)

1. `POST /fare/multi-shop/riders` (Bearer = customer):
```json
{ "userLocation":{"latitude":0,"longitude":0,"address":"Home"},
  "shops":[{"businessId":"A","latitude":0,"longitude":0,"name":"Shop A","items":[]}],
  "orderFor":"grocery", "range_in_km":5, "pincode":"248001" }
```
→ `{ sortedShops:[...furthest→nearest], furthestShop, routeDistanceKm, riders:{ <vehicleType>:{users,fare} } }`.

2. `POST /fare/multi-shop/orders` (Bearer = customer):
```json
{ "selectedRiders":["riderId1"], "userLocation":{...}, "shops":[...],
  "orderFor":"grocery", "modeOfPayment":"prepaid", "fare":80,
  "orderType":"standard", "orderForWhom":"myself" }
```
`201` → `RideOrder` with `isMultiStop:true` and a `stops[]` array (each: `businessId`,
`shopName`, `address`, `location`, `sequence` [0 = furthest, visited first], `status`,
`pickupOTP` — one OTP per shop).

3. Per-shop progress (see §8.3 for the OTP rules):
`PATCH /fare/multi-shop/orders/:orderId/stops/:businessId/:action`
- `action=arrive` (Bearer = **rider**), no body.
- `action=pickup` (Bearer = **shop**; `businessId` must equal the caller) body `{ "pickupOTP":"4821" }`.

---

## 6. Fare-call (call-queue booking)

Create with `orderType:"fare-call"` (§3.2). The backend rings each selected rider in
sequence over WebRTC; the rider receives an **incoming call** notification (§9) carrying
`metadata.rideDetails` (pickup/drop/fare + the job descriptor). The customer gets socket
`ride:queue:calling` progress. Cancel the queue: `POST /fare/orders/:orderId/cancel-queue`.

---

## 7. En-route route orders (rider earns on their path)

A rider declares a route (pickup→drop). Any open order whose **pickup AND drop both fall
within `radiusKm` (default 1 km)** of the route corridor — and matches the rider's
preference — becomes claimable.

| Action | Endpoint | Method |
|---|---|---|
| Create / activate route (supersedes prior) | `/riders/routes` | POST |
| Get active route | `/riders/routes/active` | GET |
| End active route | `/riders/routes/active/end` | PATCH |
| List on-route orders (each has `jobInfo`) | `/riders/routes/orders` | GET |
| Live on-route orders (SSE) | `/riders/routes/orders/stream` | GET |
| Claim an order | `/riders/orders/:orderId/claim` | POST |

**Create body:**
```json
{ "pickup":{"latitude":30.35,"longitude":78.07,"address":"Start"},
  "drop":{"latitude":30.31,"longitude":78.03,"address":"End"},
  "path":[[78.07,30.35],[78.05,30.34],[78.03,30.31]],
  "radiusKm":1, "expiresInMinutes":240 }
```
`path` is optional (`[[lng,lat],...]`, GeoJSON order); omit it for a straight corridor.

**List response:** `{ "routeId":"...", "count":N, "orders":[ { ...RideOrder, "jobInfo":{...} } ] }`.
**SSE frames:** `{ "routeId":"...", "orders":[...] }` (keep-alive comments sent; reconnect on drop).

**Claim** `POST /riders/orders/:orderId/claim` (Bearer = rider):
- `200` → claimed order (incl. `jobInfo`); becomes the rider's active order.
- `409` → already taken → refresh list.
- `422` → not on route / preference mismatch.
- `400` → rider has no active route.

---

## 8. OTP handoff  — current flipped direction

The OTP always travels from the person **receiving the service** to the person
**performing the action**:

| Step | Holds OTP (sees digits) | Enters / confirms | Direction |
|---|---|---|---|
| **Pickup** | **Rider** (rider app shows it) | **Shopkeeper** | rider → tells OTP → shop enters → goods released |
| **Delivery** | **Customer** (chat card shows it) | **Rider** | customer → tells OTP → rider enters → delivered |

So: the **verifier** sees an *input* (no digits); the **holder** sees the digits.

### 8.1 The `rider_otp` chat card
New chat `message_type` / `sub_type` = `rider_otp`. Each card is private (server enforces
`visible_to` — pickup card → shop only, delivery card → customer only). `metadata.otp`:
```
otp        : the digits — present ONLY for the holder (delivery card). NULL on pickup cards.
mode       : "show"  → display the digits (delivery / customer side)
             "enter" → render an OTP input + confirm button (pickup / shop side)
holder     : "rider" (pickup) | "customer" (delivery)
verifier   : "shop"  (pickup) | "rider" (delivery)
kind       : "pickup" | "delivery"
role       : "shop" | "customer"
status     : "active" | "consumed"
businessId, shopName, sequence, isMultiStop   (multi-shop: identify the shop)
```
Render: `mode:"show"` → show `otp` ("Give this OTP to the rider on delivery"); `mode:"enter"`
→ OTP field + confirm (no digits, "Enter the pickup OTP the rider gives you"); `consumed` →
struck-through / "✓".

**Real-time socket events** (chat socket): `newRiderOtpReceived` `{ message }` (append the
card); `riderOtpUpdated` `{ messageId, rideOrderId, kind, status }` (flip to consumed).

### 8.2 Single-shop verification
- **Pickup — SHOP enters** the OTP the rider reads out:
  `POST /riders/orders/:orderId/pickup` body `{ "pickupOTP":"4821" }` (Bearer = **shop**).
- **Delivery — RIDER enters** the OTP the customer reads out:
  `POST /riders/orders/:orderId/deliver` body `{ "deliveryOTP":"7390" }` (Bearer = **rider**).

Rider app: show **pickupOTP** (from the order) so the rider can read it to the shop. Show a
delivery OTP **input** — **do NOT display deliveryOTP** to the rider.

### 8.3 Multi-shop — one pickup OTP per shop, confirmed BY THAT SHOP
A 3-shop order = 3 pickup OTPs (one per shop, in `stops[].pickupOTP`) + 1 delivery OTP.
1. **Rider** arrives → `PATCH /fare/multi-shop/orders/:orderId/stops/:businessId/arrive` (Bearer = rider).
2. Rider reads that shop's pickup OTP (from `stops[]`) to the shopkeeper.
3. **Shopkeeper** enters it → `PATCH /fare/multi-shop/orders/:orderId/stops/:businessId/pickup`
   body `{ "pickupOTP":"4821" }` (Bearer = the shop; path `businessId` must equal the caller).
   `400` missing/invalid · `403` caller isn't this shop. On success that shop's card → consumed.
4. After all shops, the **customer** reads the delivery OTP to the rider, who enters it via
   `POST /riders/orders/:orderId/deliver` to complete.

> Ride-start OTP (passenger rides only): for `jobType:"ride"` the customer still holds the
> pickup/ride-start OTP and gives it to the rider on arrival — that is the one case where the
> rider enters the pickup OTP. Goods/parcel never reveal the pickup OTP to the customer/shop.

---

## 9. Notifications

All carry a `data` payload; buttons/actions use the id convention `<action>_<entity>_<id>`
(e.g. `view_order_ORD-1`, `claim_order_ORD-1`, `open_chat_<convId>`) — split off the trailing
id and map `action_entity` to a route/API.

| Operation | When | Key `data` | Buttons → action |
|---|---|---|---|
| `RIDE_ORDER_RECEIVED` | order offered to selected riders | `orderId`, `title`, `message`, `jobType`, `jobLabel`, `riderTask` | view / accept order |
| `ROUTE_ORDER_AVAILABLE` | order appears on the rider's route | `orderId`, `jobType`, `jobLabel`, `riderTask` | `view_order_*` → detail · `claim_order_*` → `POST /riders/orders/:id/claim` |
| `rider_otp` | OTP card created in chat | `conversationId`, `messageId` | `open_chat_*` → open chat |
| `fare_ride_incoming_call` | fare-call ringing (VoIP) | `call_id`, `room_id`, `callTitle`, `jobType`, `jobLabel`, `riderTask`, `metadata.rideDetails` | `view_fare_ride_*` / `decline_fare_ride_*` |
| `RIDE_ORDER_ACCEPTED` | rider accepted | `orderId`, rider details | track / contact |
| `RIDE_ORDER_PICKED_UP` / `RIDE_ORDER_COMPLETED` | status updates | `orderId` | view order |

Titles/bodies are already job-specific server-side. When opening any order/route/claim UI from
a notification, show `jobLabel` as the header. Tapping the body (no button) routes by
`data.jobType` (order detail) / `data.type` (`rider_otp` → chat).

### Incoming call screen (fare-call)
On `fare_ride_incoming_call`, read `metadata.rideDetails`:
```json
{ "pickup":{"address","lat","lng"}, "drop":{"address","lat","lng"},
  "fare":60, "distance":4.2, "orderFor":"grocery", "modeOfPayment":"prepaid",
  "jobType":"goods", "jobLabel":"Grocery pickup",
  "riderTask":"Collect the order from the shop and deliver it",
  "callTitle":"Incoming Pickup Request", "callBody":"Incoming grocery pickup request",
  "eta":{"distanceKm":2.1,"durationMin":7} }
```
Title = `callTitle`; primary = `jobLabel`; secondary = `riderTask`; optionally icon/color by
`jobType` (person / bag / parcel). The OTP is **never** in the call payload.

---

## 10. Socket events

| Event | Payload | Direction |
|---|---|---|
| `newRiderOtpReceived` | `{ message }` | new OTP card → recipient |
| `riderOtpUpdated` | `{ messageId, rideOrderId, kind, status }` | card consumed |
| `ride:queue:calling` | `{ orderId, riderIndex, totalRiders, riderId, call_id, room_id, ... }` | fare-call progress → customer |
| `ride:stop:update` | `{ order, stop }` | multi-stop per-shop status → rider/customer |

---

## 11. Order status lifecycle

```
pending → payment-pending → confirmed → in-progress → picked-up → completed
                                   (rejected / cancelled are terminal)
```
- Accept moves `pending → payment-pending` and sets `assignedRider`.
- Pickup (shop verifies OTP) → `picked-up`. Multi-shop tracks per-stop `status`
  (`pending → arrived → picked-up`) while the order stays in progress.
- Deliver (rider verifies OTP) → `completed`.

---

## 12. Backward compatibility
- New fields (`jobInfo`, `jobType`/`jobLabel`/`riderTask`, `stops[].pickupOTP`,
  OTP card `mode`/`holder`/`verifier`/`businessId`/`shopName`/`sequence`/`isMultiStop`) are
  additive; old builds ignore them.
- The incoming-call operation is unchanged (`fare_ride_incoming_call`) — only its title/body/data
  became job-aware.
- OTP direction is flipped only for goods/parcel pickups; passenger ride-start OTP is unchanged.
- Legacy multi-stop orders without per-stop OTPs fall back to the order-level `pickupOTP`.

---

## 13. Endpoint quick reference

```
GET    /fare/riders
POST   /fare/orders
PATCH  /fare/orders/:orderId/status            { action: accept|reject }
GET    /fare/orders/:orderId/status
POST   /fare/orders/:orderId/start             (rider) ride-start OTP for passenger rides { pickupOTP }
POST   /fare/orders/:orderId/complete          (rider) complete a ride
POST   /fare/orders/:orderId/cancel            cancel a ride order
POST   /fare/orders/:orderId/cancel-queue      cancel the fare-call queue
POST   /fare/orders/:orderId/ride-action       accept/reject from the fare-call screen
POST   /fare/chat-dispatch/orders
POST   /fare/multi-shop/riders
POST   /fare/multi-shop/orders
PATCH  /fare/multi-shop/orders/:orderId/stops/:businessId/arrive     (rider)
PATCH  /fare/multi-shop/orders/:orderId/stops/:businessId/pickup     (shop)  { pickupOTP }
POST   /riders/routes
GET    /riders/routes/active
PATCH  /riders/routes/active/end
GET    /riders/routes/orders
GET    /riders/routes/orders/stream            (SSE)
POST   /riders/orders/:orderId/claim
POST   /riders/orders/:orderId/pickup          (shop)  { pickupOTP }
POST   /riders/orders/:orderId/deliver         (rider) { deliveryOTP }
```
