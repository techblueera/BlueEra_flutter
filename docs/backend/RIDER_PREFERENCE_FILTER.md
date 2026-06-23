# Rider Preference Filter — Frontend Integration Guide

## What changed (backend)

Nearby-rider lookups now filter riders by the preference each rider picked during
onboarding (`vehicleInformation.vehicleUsesType`). A rider is only returned for an
order whose category matches their preference.

- Ride (passenger) orders → riders with `passenger` or `passenger&delivery`
- Goods (delivery) orders → riders with `delivery`, `goodsTransport`, or `passenger&delivery`

Backend logic: `src/utils/riderPreference.js`. Applied in:
- `GET  /fare/riders`            (`findRidersWithFare`)
- `POST /fare/multi-shop/riders` (`findRidersForMultiShop`)

## Order category mapping

| `orderFor` value | Category | Riders shown (`vehicleUsesType`) |
|------------------|----------|----------------------------------|
| `InCity`         | Ride     | `passenger`, `passenger&delivery` |
| `OutStation`     | Ride     | `passenger`, `passenger&delivery` |
| `HourlyRental`   | Ride     | `passenger`, `passenger&delivery` |
| `product`        | Goods    | `delivery`, `goodsTransport`, `passenger&delivery` |
| `grocery`        | Goods    | `delivery`, `goodsTransport`, `passenger&delivery` |
| `food`           | Goods    | `delivery`, `goodsTransport`, `passenger&delivery` |
| `medical`        | Goods    | `delivery`, `goodsTransport`, `passenger&delivery` |
| `Parcel`         | Goods    | `delivery`, `goodsTransport`, `passenger&delivery` |

Unknown `orderFor` → no filtering (all riders returned).

## Frontend impact

**No required code changes.** Same request shape, same response shape. The only
difference: the riders list returned by the two endpoints is now narrower —
riders whose preference does not match the order category are omitted.

### Request — unchanged

`GET /fare/riders` (query params, existing):

```
orderFor=InCity
pickupLatitude, pickupLongitude, dropLatitude, dropLongitude
range_in_km   (optional, default 5)
pincode       (required when orderFor = InCity | Parcel)
distance_in_km (optional)
```

`POST /fare/multi-shop/riders` (body, existing):

```json
{
  "userLocation": { "latitude": 0, "longitude": 0 },
  "shops": [{ "businessId": "...", "latitude": 0, "longitude": 0 }],
  "orderFor": "grocery",
  "range_in_km": 5,
  "pincode": "110001"
}
```

### Response — unchanged shape

Still grouped by `vehicleType`. Just fewer entries when riders don't match:

```json
{
  "twoWheelerRider": { "users": [ ... ], "fare": 60 },
  "autoTempo":       { "users": [ ... ], "fare": 90 }
}
```

### Behaviour to handle

- **Empty result is normal.** If no nearby rider matches the order's preference,
  the endpoint returns `{}` (single) or `{ ..., "riders": {} }` (multi-shop).
  Frontend should already show a "no riders available" state — confirm it does.
- **Pass the correct `orderFor`.** The filter keys entirely off `orderFor`. Send
  the real order category (e.g. `Parcel` for parcel delivery, `InCity` for a
  passenger ride) so the right riders surface. Wrong `orderFor` → wrong riders.

## Onboarding requirement

For the filter to work the rider must have `vehicleUsesType` set. It is collected
in the existing vehicle-information onboarding step (Flutter:
`vehicle_information_widget.dart`, key `vehicleUsesType`). No change needed —
just keep submitting it.

## Backward compatibility

- Riders onboarded **before** this field existed (no `vehicleUsesType`) are
  **always returned** — never filtered out. Existing production riders keep
  working.
- Unknown / unmapped `orderFor` → no filtering.
- No request/response contract change → old app builds keep functioning.
