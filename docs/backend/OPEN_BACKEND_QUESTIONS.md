# Open backend questions — ride fares & food inventory

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

## Reference: what the app calls, and when

| Screen | Endpoint | Notes |
| --- | --- | --- |
| Ride — vehicle select (on entry) | `GET rider-service/fare/riders/dynamic?...&allVehicleTypes=true` | one call, prices the whole grid |
| Ride — vehicle select (per tap) | `GET rider-service/riders/live-in-radius?lat&lng&radius&vehicleType&limit` | fills the map with that class |
| Food — owner variant sheet | `PATCH food-service/api/kitchen-inventory/stock/flip-out-of-stock` | inverts; sends ids only, no value |
| Food — owner variant sheet | `PATCH food-service/api/kitchen-inventory/{inventoryId}` | **§2a — unconfirmed** |
| Food — owner variant sheet | `DELETE food-service/api/kitchen-inventory/{inventoryId}` | working |
