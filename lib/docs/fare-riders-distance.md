# `GET /fare/riders` — Client-Provided Road Distance

**Audience:** Frontend / Mobile team
**Status:** Available
**Endpoint:** `GET /api/rider-service/fare/riders`

## Why this exists

The fare for `findRidersWithFare` is computed using the trip distance between
pickup and drop. Until now, the backend computed this distance using the
**haversine formula** (great-circle straight-line distance between two
lat/lng points). Haversine systematically *underestimates* the actual
distance a rider has to travel because it ignores roads, one-ways,
diversions, flyovers, water bodies, etc.

The frontend already has access to accurate **road distance** via map SDKs
(Google Directions, Mapbox Directions, OSRM, etc.). To make fares reflect
reality, the API now accepts an optional `distance_in_km` query parameter.
When the frontend sends this value, the backend uses it as-is and skips the
haversine calculation entirely.

## Contract change (backwards compatible)

A single new **optional** query parameter has been added. No existing
fields, behaviour, or response shapes have changed. Existing clients keep
working without modification.

| Param            | Type     | Required | Description                                                                 |
| ---------------- | -------- | -------- | --------------------------------------------------------------------------- |
| `distance_in_km` | `number` | No       | Accurate road distance in kilometres between pickup and drop (e.g. `10.3`). |

### Server-side behaviour

```text
if (distance_in_km is provided AND is a finite number AND > 0)
    tripDistance = distance_in_km           ← haversine SKIPPED
else
    tripDistance = haversine(pickup, drop)  ← legacy fallback
```

The resulting `tripDistance` is then fed into the existing fare formula
(see `src/controllers/fare.controller.js` → `findRidersWithFare`):

```text
billableDistance = max(0, tripDistance - 1)
fare             = baseFare + perKilometerRate × billableDistance
fare             = max(fare, minimumFare)
fare             = fare × nightMultiplier   (if night window active)
fare             = round(fare)
```

> The first 1 km is covered by `baseFare` — only distance **beyond** 1 km is
> charged at `perKilometerRate`. This is unchanged.

## Request example

### Without `distance_in_km` (legacy — uses haversine)

```http
GET /api/rider-service/fare/riders
    ?orderFor=InCity
    &pickupLatitude=11.671963311701802
    &pickupLongitude=78.015041872859
    &dropLatitude=11.729241137420212
    &dropLongitude=77.93084297329187
    &range_in_km=5
    &pincode=636013
Authorization: Bearer <token>
```

### With `distance_in_km` (recommended — uses accurate road distance)

```http
GET /api/rider-service/fare/riders
    ?orderFor=InCity
    &pickupLatitude=11.671963311701802
    &pickupLongitude=78.015041872859
    &dropLatitude=11.729241137420212
    &dropLongitude=77.93084297329187
    &range_in_km=5
    &pincode=636013
    &distance_in_km=10.3
Authorization: Bearer <token>
```

### cURL

```bash
curl -G 'https://be.blueera.ai/api/rider-service/fare/riders' \
  --data-urlencode 'orderFor=InCity' \
  --data-urlencode 'pickupLatitude=11.671963311701802' \
  --data-urlencode 'pickupLongitude=78.015041872859' \
  --data-urlencode 'dropLatitude=11.729241137420212' \
  --data-urlencode 'dropLongitude=77.93084297329187' \
  --data-urlencode 'range_in_km=5' \
  --data-urlencode 'pincode=636013' \
  --data-urlencode 'distance_in_km=10.3' \
  -H "Authorization: Bearer $TOKEN"
```

## Response shape (unchanged)

```json
{
  "twoWheelerRider": {
    "users": [
      {
        "riderId": "692fe31a1d502666b445737b",
        "name": "rohit singh",
        "profile_image": "https://...",
        "distance": "10.53 km",
        "rating": 0,
        "vehicleInformation": { "vehicleType": "twoWheelerRider" },
        "totalOrders": 0
      }
    ],
    "fare": 89
  }
}
```

The `distance` shown inside each `users[]` entry is the rider-to-pickup
distance (still haversine — not affected by `distance_in_km`). The new
parameter only affects the **trip** distance used for the `fare` field.

## Worked examples

Assume policy:

```json
{ "vehicleType": "twoWheelerRider", "serviceType": "InCity",
  "baseFare": 20, "perKilometerRate": 10, "perMinuteRate": 1, "minimumFare": 50 }
```

| Trip distance (km) | `billableDistance` | Calculation             | Final fare |
| ------------------ | ------------------ | ----------------------- | ---------- |
| 10.3               | 9.3                | `20 + 10 × 9.3 = 113`   | ₹113       |
| 7.92               | 6.92               | `20 + 10 × 6.92 = 89.2` | ₹89        |
| 0.5                | 0                  | `20 + 10 × 0 = 20`      | ₹50 (min)  |

With policy `baseFare=20, perKilometerRate=6, minimumFare=25`:

| Trip distance (km) | Calculation             | Final fare |
| ------------------ | ----------------------- | ---------- |
| 10.3               | `20 + 6 × 9.3 = 75.8`   | ₹76        |
| 7.92               | `20 + 6 × 6.92 = 61.52` | ₹62        |

## Validation rules

- `distance_in_km` is **optional**. Omit it to keep the legacy behaviour.
- Must be a finite number (parseable as float).
- Must be **> 0**. Values that are `0`, negative, `NaN`, or non-numeric are
  silently ignored and the server falls back to haversine. The request will
  **not** fail because of a bad `distance_in_km`.
- The unit is **kilometres**, not metres. Send `10.3`, not `10300`.
- Decimal precision is preserved — send as much precision as your map
  provider returns (e.g. `10.342`).

## Frontend implementation guidance

1. After the user picks pickup + drop, call your map provider's directions
   API to get the actual road distance.
2. Convert it to kilometres if needed (most APIs return metres).
3. Pass it as `distance_in_km` on the `GET /fare/riders` request.
4. If the directions call fails or times out, **omit** the parameter — the
   backend will transparently fall back to haversine and the request still
   succeeds.

```ts
// Example (TypeScript / fetch)
const km = directions ? directions.distanceMeters / 1000 : undefined;

const params = new URLSearchParams({
  orderFor: 'InCity',
  pickupLatitude: String(pickup.lat),
  pickupLongitude: String(pickup.lng),
  dropLatitude: String(drop.lat),
  dropLongitude: String(drop.lng),
  range_in_km: '5',
  pincode,
});
if (km && km > 0) params.set('distance_in_km', km.toFixed(3));

const res = await fetch(`/api/rider-service/fare/riders?${params}`, {
  headers: { Authorization: `Bearer ${token}` },
});
```

## FAQ

**Q. Will the same `distance_in_km` be used later when the order is created?**
No. This parameter only affects the *quote* shown by `GET /fare/riders`.
The actual stored fare on `POST /fare/orders` is whatever the client sends
in the `fare` field of the create-order request body. Make sure the value
shown to the user matches the value posted.

**Q. What if I send a wildly inflated `distance_in_km` to inflate the fare?**
The endpoint trusts the client value. Server-side sanity bounds (e.g. cap
at OSRM road distance ± tolerance) are out of scope for this change and
can be added in a follow-up if abuse becomes a concern.

**Q. Does this affect `OutStation`, `HourlyRental`, or `Parcel` flows?**
The same controller handles all `orderFor` values, so `distance_in_km`
applies uniformly wherever `tripDistance` feeds into the fare-policy
calculation in `findRidersWithFare`.

**Q. Is haversine being removed?**
No. It remains as the fallback path so older clients and failure cases
keep working.

## References

- Controller: `src/controllers/fare.controller.js` → `findRidersWithFare`
- Route + swagger: `src/routes/fare.route.js` → `GET /fare/riders`
- Haversine helper: `src/utils/ride.utils.js` → `haversineDistance`
