# Open backend questions — ride fares, food inventory & notifications

Written for the backend team. Each item is either a **gap** (app is correct, response
is missing something) or a **question** (app needs a contract confirmed before the
feature can ship).

Captured against a live response on 2026-08-26, business `6a7d5d716ffa659bc012ec07`.

---

## 1. Ride — `GET rider-service/fare/riders/dynamic`

### 1a. GAP — `allVehicleTypes=true` returns 8 of the 12 vehicle types

Request:

```
GET /api/rider-service/fare/riders/dynamic
    ?pickupLatitude=26.275142049058374&pickupLongitude=72.99725610762835
    &dropLatitude=26.2772956&dropLongitude=73.01202450000001
    &orderFor=InCity&range_in_km=20&pincode=342003
    &distance_in_km=2.023&allVehicleTypes=true
```

`fares` came back keyed by:

| Returned | Missing |
| --- | --- |
| `twoWheelerRider`, `autoTempo`, `eRickshaw`, `carMini`, `carSedan`, `suvCar`, `miniBus`, `pickupGoods` | `goods3Wheeler`, `goods4Wheeler`, `miniTruckGoods`, `largeTruckGoods` |

The app's catalogue is driven entirely by this response — a `vehicleType` absent from
`fares` renders **no tile at all**, because the client must never offer a type the
server would reject at booking time.

**Effect:** the whole **Parcel/Goods** section is nearly empty. Its tiles are
`twoWheelerRider`, `goods3Wheeler`, `goods4Wheeler` (covering `pickupGoods`) and
`miniTruckGoods` (covering `largeTruckGoods`) — three of the four resolve only via
their fallbacks or not at all.

**Ask:** with `allVehicleTypes=true`, price **every** type in the vehicle enum
(`GET rider-service/riders/onboarding/vehicle-enums`), including the four goods
classes — even where `ridersAvailable: false`. If a type is genuinely retired,
please drop it from the enum too so the two agree.

### 1b. GAP — `serviceFares` only carries the requested `orderFor` for most types

`twoWheelerRider.serviceFares` carried both `InCity` **and** `Parcel`:

```json
"serviceFares": {
  "InCity":  { "fare": 30, "fareBreakdown": { "baseFare": 18, ... } },
  "Parcel":  { "fare": 50, "fareBreakdown": { "baseFare": 40, ... } }
}
```

Every other type carried only `InCity` — the `orderFor` the request was made with.

The app shows three sections in one screen, each booking a different `orderFor`
(`InCity`, `Parcel`, `OutStation`). Since only the bike is priced per-service, the
Parcel/Goods and Out Station tiles currently display the **InCity** fare, which is
the wrong number for those trips (the bike's own data proves the gap: ₹30 InCity vs
₹50 Parcel, a 66% difference).

**Ask:** when `allVehicleTypes=true`, populate `serviceFares` with every `orderFor`
the type can be booked under, for every type — not just for the one in the query.
That makes the single catalog call sufficient for the whole screen, which is the
point of the flag.

### 1c. NOT a backend issue — `ridersAvailable: false` on 7 of 8 types

This is correct data (only one bike was online) and the app now treats it as a
**note**, not a block: every tile shows its fare and is tappable, and the tile
prints "None nearby" instead of the distance/ETA line. Dispatch is a broadcast, so
a rider coming on shift can still answer. No change needed.

---

## 2. Food — `PATCH food-service/api/kitchen-inventory/{inventoryId}`

### 2a. QUESTION — confirm the route for a published-variant price update

The app now lets a restaurant owner change a **published** dish variant's price from
the variant sheet. There is no documented endpoint for it, so this is what the client
currently sends — please confirm or correct:

```
PATCH /api/food-service/api/kitchen-inventory/{inventoryId}
Content-Type: application/json

{ "baseSellingPrice": 120, "mrp": 150 }
```

Chosen by analogy: same path as the existing `DELETE` on that id, and food-service's
other inventory mutation (`stock/flip-out-of-stock`) is a `PATCH`; automotive's
equivalent is `PATCH automotive-service/api/inventory/{id}`.

**Please confirm:** the verb (`PATCH` vs `PUT`), the field names
(`baseSellingPrice` / `mrp` vs `sellingPrice` / `mrp`), and whether it is a true
partial update — the client relies on unsent keys (variant name, quantity label,
`isOutOfStock`) being left untouched.

We could not test it: the only token available had been revoked
(`401 SESSION_REVOKED`).

### 2b. GAP — `GET food-service/api/home/{businessId}` variants carry no `inventoryId`

A variant in the home payload looks like this:

```json
{
  "_id": "6a7d7f18c54c3674b281f74c",
  "productVariant": { "variantName": "Half Plate", "quantityLabel": "Half Serving",
                      "mrp": 85, "baseSellingPrice": 85, ... },
  "price": { "mrp": 85, "sellingPrice": 85, "currency": "INR", "packingCharges": 20 },
  "isOutOfStock": false
}
```

Two mismatches against every other food endpoint the app consumes:

1. **No `inventoryId` key.** The inventory record id is the outer `_id`. The
   discount-products endpoint returns it as `inventoryId`, so the client has to
   special-case this shape.
2. **Prices are nested** under `productVariant` / `price`, not flat on the variant.
   Elsewhere `mrp` and `baseSellingPrice` sit directly on the variant object.

Everything the owner can do to a variant — change the price, flip stock, delete it —
is keyed on the inventory id, so a payload that omits it makes those actions
impossible from any screen fed by it.

**Ask (either is fine, the first is cheaper for you):**

- add `"inventoryId": "<same value as _id>"` alongside `_id`, and flat
  `"mrp"` / `"baseSellingPrice"` on the variant; **or**
- tell us this shape is intentional and permanent, and we will map it client-side.

---

## 3. Notifications — what key does a STORED inbox row use for its deep link?

### 3a. QUESTION — two guides disagree, and nobody has captured a real row

`FLUTTER_NOTIFICATION_ROUTING_GUIDE.md` §5 says the stored inbox metadata uses
snake_case `deep_link`, and gives this reader:

```dart
(m['deepLink'] ?? m['deep_link'] ?? m['link'] ?? m['url'] ?? '')
```

But the only **captured** stored row anywhere in our repo —
`FLUTTER_VIDEO_PROMO_NOTIFICATION_GUIDE.md` §7 — shows a *per-operation prefix*:

```jsonc
"metadata": {
  "video_id": "68f0a1b2c3d4e5f60718293a",
  "video_thumbnail": "https://…",
  "video_deep_link": "https://beapp.in/app/video/68f0…",   // ← not `deep_link`
  "broadcast_id": "68f1…"
}
```

The §5 reader would **not** match `video_deep_link`. Video promos are unaffected
because they route off `video_id`, not the link — but `admin_promotion` has no
id to fall back on. Its destination *is* the link, so if the stored key is
`promotion_deep_link` (or anything else prefixed), the push opens the right
screen and the inbox row it leaves behind silently dead-ends on the list the
user tapped it from.

We have shipped a tolerant reader — exact keys first, then any key ending in
`deep_link` / `deepLink` — so the app is correct under either answer. We would
still like the contract confirmed rather than inferred.

**Ask — a one-line answer to each:**

1. For an `admin_promotion` row from `GET /notification-service/notifications`,
   what is the exact `metadata` key holding the destination?
2. Is it flat inside `metadata`, or nested (e.g. `metadata.data.deep_link`)?
3. Is the value absolute (`https://beapp.in/app/jobs`) or a path (`/app/jobs`)?
   We currently pass it straight to the App-Links resolver, which expects the
   absolute form.
4. Same three for `broadcast_id` — we read `broadcast_id` / `broadcastId` /
   `bulkNotificationId`, and campaign open-rates depend on hitting the right one.

**Better than an answer:** paste one real `admin_promotion` row from the list
endpoint, with `metadata` intact. That settles all four at once, and we will
pin it as a fixture so it cannot drift again.

### 3b. GAP — two referenced guides are not in the repo

`FLUTTER_NOTIFICATION_ROUTING_GUIDE.md` links to
`ADMIN_NOTIFICATION_CENTER_GUIDE.md` and `ENGAGEMENT_ENGINE_PLAN.md`. Neither
exists under `docs/backend/`. If the stored shape is documented in either,
that alone likely answers §3a.

---

## Reference: what the app calls, and when

| Screen | Endpoint | Notes |
| --- | --- | --- |
| Ride — vehicle select (on entry) | `GET rider-service/fare/riders/dynamic?...&allVehicleTypes=true` | one call, prices the whole grid |
| Ride — vehicle select (per tap) | `GET rider-service/riders/live-in-radius?lat&lng&radius&vehicleType&limit` | fills the map with that class |
| Food — owner variant sheet | `PATCH food-service/api/kitchen-inventory/stock/flip-out-of-stock` | inverts; sends ids only, no value |
| Food — owner variant sheet | `PATCH food-service/api/kitchen-inventory/{inventoryId}` | **§2a — unconfirmed** |
| Food — owner variant sheet | `DELETE food-service/api/kitchen-inventory/{inventoryId}` | working |
| Notifications — inbox list | `GET notification-service/notifications` | **§3a — `metadata` deep-link key unconfirmed** |
| Notifications — campaign engagement | `POST notification-service/notifications/track` | open / click / convert |
