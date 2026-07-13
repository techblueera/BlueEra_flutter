# Vehicle Enums by Profession — Backend Guide

**Goal:** move the per-profession filtering of the rider onboarding vehicle
enums from the Flutter client to the backend. The client sends the rider's
profession `type`; the server returns **only** the options valid for that
profession for all three dropdowns (Vehicle Type, Vehicle Use, Registration).
The app then renders the response as-is — no client-side filtering.

Today the client fetches the full enum catalog and filters it locally against a
hard-coded map. That map has to be kept in sync with the backend by hand and
duplicates business rules in the app. This guide makes the backend the single
source of truth.

---

## 1. Current endpoint (unfiltered)

```
GET /api/rider-service/riders/onboarding/vehicle-enums
```

Returns the **full** catalog (every option, all professions):

```json
{
  "vehicleType": [
    { "slug_id": "twoWheelerRider",  "slug_value": "Two Wheeler Rider" },
    { "slug_id": "autoTempo",        "slug_value": "Auto Tempo" },
    { "slug_id": "eRickshaw",        "slug_value": "E Rickshaw" },
    { "slug_id": "carMini",          "slug_value": "Car Mini" },
    { "slug_id": "carSedan",         "slug_value": "Car Sedan" },
    { "slug_id": "suvCar",           "slug_value": "Suv Car" },
    { "slug_id": "miniBus",          "slug_value": "Mini Bus" },
    { "slug_id": "pickupGoods",      "slug_value": "Pickup Goods" },
    { "slug_id": "miniTruckGoods",   "slug_value": "Mini Truck Goods" },
    { "slug_id": "largeTruckGoods",  "slug_value": "Large Truck Goods" }
  ],
  "vehicleUsesType": [
    { "slug_id": "passenger",           "slug_value": "Passenger" },
    { "slug_id": "delivery",            "slug_value": "Delivery" },
    { "slug_id": "passenger&delivery",  "slug_value": "Passenger & Delivery" },
    { "slug_id": "goodsTransport",      "slug_value": "Goods Transport" }
  ],
  "registrationType": [
    { "slug_id": "Personal",         "slug_value": "Personal" },
    { "slug_id": "Commercial",       "slug_value": "Commercial" },
    { "slug_id": "commercialGoods",  "slug_value": "Commercial Goods" }
  ],
  "fuelType": [
    { "slug_id": "Petrol",   "slug_value": "Petrol" },
    { "slug_id": "Diesel",   "slug_value": "Diesel" },
    { "slug_id": "Electric", "slug_value": "Electric" },
    { "slug_id": "Hybrid",   "slug_value": "Hybrid" },
    { "slug_id": "CNG",      "slug_value": "C N G" },
    { "slug_id": "LPG",      "slug_value": "L P G" }
  ]
}
```

> **Note:** `slug_id` is the stable key the app persists and matches on;
> `slug_value` is only the display label. Filtering MUST be on `slug_id`.

---

## 2. Proposed change — accept a `type` (profession) query param

```
GET /api/rider-service/riders/onboarding/vehicle-enums?type=<PROFESSION>
```

- `type` — the rider's profession. One of:
  `BIKE_RIDER`, `AUTO_TAXI`, `CAR_TAXI_DRIVER`, `GOODS_TAXI`.
- When `type` is present and recognised → return **only** the allowed options
  for `vehicleType`, `vehicleUsesType`, and `registrationType` per §3.
- When `type` is **absent or unrecognised** → return the **full** catalog
  (unchanged). This keeps the endpoint backward-compatible.
- `fuelType` is **not** filtered by profession — always return the full list.

The response shape is **identical** to today's — same keys, same
`{ slug_id, slug_value }` objects — just with the arrays pre-filtered. The app
does not need any new parsing.

---

## 3. Filtering rules (source of truth)

For each profession, return only these `slug_id`s. **Preserve the catalog order.**

| Profession        | `vehicleType`                                      | `vehicleUsesType`                          | `registrationType`        |
|-------------------|----------------------------------------------------|--------------------------------------------|---------------------------|
| `BIKE_RIDER`      | `twoWheelerRider`                                  | `passenger`, `delivery`, `passenger&delivery` | `Personal`, `Commercial` |
| `AUTO_TAXI`       | `autoTempo`, `eRickshaw`                           | `passenger`                                | `Commercial`              |
| `CAR_TAXI_DRIVER` | `carMini`, `carSedan`, `suvCar`, `miniBus`        | `passenger`                                | `Commercial`              |
| `GOODS_TAXI`      | `pickupGoods`, `miniTruckGoods`, `largeTruckGoods`, `goods3Wheeler`, `goods4Wheeler` | `goodsTransport`                           | `commercialGoods`         |

`fuelType`: always full list (all professions).

> These are the exact rules the Flutter client currently applies locally. Keep
> them here on the server; the app will drop its local copy once this ships.

### New `vehicleType` options (to be added to the master catalog)

`GOODS_TAXI` gains two additional goods vehicle types. These are **not yet in
the `/vehicle-enums` catalog** (§1) — the backend must add them to the master
`vehicleType` list, then include them for `GOODS_TAXI`:

| `slug_id` (proposed — confirm) | `slug_value` (display) |
|--------------------------------|------------------------|
| `goods3Wheeler`                | `Goods(3 wheeler)`     |
| `goods4Wheeler`                | `Goods(4 wheeler)`     |

> The `slug_id`s above follow the existing camelCase convention
> (`pickupGoods`, `miniTruckGoods`, …). If the backend assigns different keys,
> update this table and §4 accordingly — the app matches on `slug_id`, so both
> ends must agree exactly.

---

## 4. Example responses

### `?type=BIKE_RIDER`

```json
{
  "vehicleType": [
    { "slug_id": "twoWheelerRider", "slug_value": "Two Wheeler Rider" }
  ],
  "vehicleUsesType": [
    { "slug_id": "passenger",          "slug_value": "Passenger" },
    { "slug_id": "delivery",           "slug_value": "Delivery" },
    { "slug_id": "passenger&delivery", "slug_value": "Passenger & Delivery" }
  ],
  "registrationType": [
    { "slug_id": "Personal",   "slug_value": "Personal" },
    { "slug_id": "Commercial", "slug_value": "Commercial" }
  ],
  "fuelType": [ /* full list */ ]
}
```

### `?type=AUTO_TAXI`

```json
{
  "vehicleType": [
    { "slug_id": "autoTempo", "slug_value": "Auto Tempo" },
    { "slug_id": "eRickshaw", "slug_value": "E Rickshaw" }
  ],
  "vehicleUsesType": [
    { "slug_id": "passenger", "slug_value": "Passenger" }
  ],
  "registrationType": [
    { "slug_id": "Commercial", "slug_value": "Commercial" }
  ],
  "fuelType": [ /* full list */ ]
}
```

### `?type=CAR_TAXI_DRIVER`

```json
{
  "vehicleType": [
    { "slug_id": "carMini",  "slug_value": "Car Mini" },
    { "slug_id": "carSedan", "slug_value": "Car Sedan" },
    { "slug_id": "suvCar",   "slug_value": "Suv Car" },
    { "slug_id": "miniBus",  "slug_value": "Mini Bus" }
  ],
  "vehicleUsesType": [
    { "slug_id": "passenger", "slug_value": "Passenger" }
  ],
  "registrationType": [
    { "slug_id": "Commercial", "slug_value": "Commercial" }
  ],
  "fuelType": [ /* full list */ ]
}
```

### `?type=GOODS_TAXI`

```json
{
  "vehicleType": [
    { "slug_id": "pickupGoods",     "slug_value": "Pickup Goods" },
    { "slug_id": "miniTruckGoods",  "slug_value": "Mini Truck Goods" },
    { "slug_id": "largeTruckGoods", "slug_value": "Large Truck Goods" },
    { "slug_id": "goods3Wheeler",   "slug_value": "Goods(3 wheeler)" },
    { "slug_id": "goods4Wheeler",   "slug_value": "Goods(4 wheeler)" }
  ],
  "vehicleUsesType": [
    { "slug_id": "goodsTransport", "slug_value": "Goods Transport" }
  ],
  "registrationType": [
    { "slug_id": "commercialGoods", "slug_value": "Commercial Goods" }
  ],
  "fuelType": [ /* full list */ ]
}
```

---

## 5. Behaviour / edge cases

1. **Unknown / missing `type`** → return the full catalog (do **not** error).
   Old app builds that don't send `type` keep working.
2. **Order matters** → return options in the same order as the master catalog;
   the app renders them in the received order.
3. **A profession maps to exactly one option** (e.g. `BIKE_RIDER` →
   `vehicleType` has one entry) → still return a **single-element array**. The
   app auto-selects the only option and locks the field, so an empty array must
   never be returned for a valid profession.
4. **Never return an empty array for a supported profession/enum** — if a
   mapping yields nothing, treat it as a config error and fall back to the full
   list for that enum so onboarding is never blocked.
5. **Casing / exact `slug_id`** — match `slug_id` exactly (case-sensitive). Do
   not normalise; the app persists these verbatim.

---

## 6. Auth / caching

- Same auth as the existing endpoint (Bearer token).
- Safe to cache per `type` (the catalog is effectively static). If cached,
  key the cache by `type` so professions don't cross-contaminate.

---

## 7. Frontend migration (for reference)

Once this ships, the app will:

1. Call `GET …/vehicle-enums?type=<userProfessionGlobal>`.
2. Render `vehicleType`, `vehicleUsesType`, `registrationType` **directly** from
   the response (drop `getFilteredVehicles` / `getFilteredVehicleUseTypes` /
   `getFilteredRegistrationTypes` and the local `_vehicleEnumFilters` map in
   `delivery_partner_controller.dart`).
3. Keep the single-option auto-select (works purely off list length, so it
   still applies to the server-filtered lists).

No response-shape change is needed on the client — only the added `type` query
param and the removal of the local filter map.
```
