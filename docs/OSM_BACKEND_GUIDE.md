# OSM Migration — Backend Guide

**Audience:** the API team.
**Status:** the app no longer calls Google Maps. Nothing here is required for the
app to work today — every item is the backend absorbing work the client is
currently doing itself, in the places where the client is a bad place to do it.

Ordered by value, not by effort.

---

## Why the backend matters more now, not less

Under Google, every one of these calls cost money, so the argument for moving
them server-side was a billing argument. Self-hosted OSM removes the per-request
cost — but it does **not** remove the reasons:

- The client's answer is **unshared**. Two phones on the same ride each compute
  the same route independently, from the same two points, and can disagree.
- The client's answer is **unauditable**. A fare dispute has no server-side
  record of the distance the quote was based on.
- The client's answer is **slow when it matters**. A route fetch sits between
  "user taps Book" and the fare appearing.

The load simply moved from Google's servers to ours. Everything below is about
making it not happen at all.

---

## B1. Put the ride route in the order payload — *highest value*

**Today:** during a ride, both the rider app and the customer app poll their own
routes from OSRM for the same journey, every few seconds. `RoutePolylineService`
caps this with a 30-second floor and a ~110 m coordinate-rounding cache, but
that is a client-side mitigation of a server-side omission.

**Ask:** include the computed route on the order/booking object.

```jsonc
{
  "orderId": "...",
  "route": {
    "polyline": "ee`xDgtg{MD_CRcCBW…",   // encoded polyline, precision 5
    "distanceMeters": 229120,
    "durationSeconds": 10920
  },
  "pickupEtaMinutes": 6,
  "dropEtaMinutes": 34
}
```

Precision 5 is what `OsrmRouting.decodePolyline` already reads — the app needs no
new parsing.

**Result:** both apps draw the identical line from a payload they already poll.
Two routing calls per tick become **zero**. `RoutePolylineService` and its call
sites can then be deleted outright.

### Confirm this first, it may be free

`ride_tracking_screen.dart` carries a comment saying the payload "only ever sends
a pickup ETA", which is why that screen measures the drop ETA off its own routing
reply — **even though `dropEtaMinutes` already exists in the model**. If the
backend is in fact populating it, one screen can stop routing immediately with no
new backend work at all. Worth a five-minute check before anything else here.

---

## B2. Serve the static city dataset

**Today:** `PlaceRepo.getCitiesByState` hits the geocoder to answer "which cities
are in this state" — a **static dataset**. The cities of Uttarakhand do not change
between releases, yet we re-derive them from a search index on every lookup.

**Ask:** a plain endpoint, or better, ship it as a bundled JSON asset in the app.

```
GET /geo/states/{state}/cities  →  [{ "name": "Dehradun", "lat": …, "lng": … }]
```

**Result:** zero geocoder load, instant, and it works offline. There is precedent
in the app already — pincode lookup uses `api.postalpincode.in` rather than a
geocoder (`environment_config.dart`).

---

## B3. Cache reverse geocodes server-side

**Today:** `OsmGeocoder.reverse` is called per drag-to-pin settle. Many users pin
the same handful of places — a shop entrance, an apartment gate, an office block.

**Ask:** a thin cached proxy, keyed on coordinates **rounded to ~5 decimals**
(~1 m), with a long TTL.

```
GET /geo/reverse?lat=&lng=  →  { formattedAddress, city, postcode, state, … }
```

Nominatim data is stable between weekly imports, so a 7-day TTL is safe and
collapses most of the load. Unlike Google's Places terms, **ODbL puts no
restriction on how long we cache this** — which is exactly why the client-side
cache in `PlaceRepo` is deliberately session-only and the durable one belongs
here.

---

## B4. Distance labels belong on the server

**Today:** several list screens compute "x km away" client-side from the device
fix. `ServiceData` already carries a server-computed `distance` for self-work
listings — but the consultant endpoint does **not**, so
`profession_consultant_discover_screen_v2.dart` runs its own haversine per row
and keys the results by consultant id to survive pagination.

**Ask:** return `distanceKm` on every listing endpoint that has a location,
computed against the `lat`/`lng` the client already sends.

**Result:** one implementation instead of several, correct sorting on the server
for "Nearest", and one less reason for a screen to hold a location.

---

## B5. Host the static map images

**Today:** `StaticMapPreview` composes raster tiles client-side for non-
interactive previews (chat location cards, business profiles, list rows).

This is already efficient — tiles are addressed by a fixed `{z}/{x}/{y}` grid, so
two shops on the same street share tiles and the second card costs nothing. But a
business's location is **identical for every viewer**, so a server-rendered PNG
per location, cached on our CDN, is rendered once ever rather than composed on
every device.

**Ask (low priority):**

```
GET /geo/staticmap?lat=&lng=&zoom=&w=&h=  →  image/png
```

Only worth doing if tile egress becomes a visible cost. Measure first.

---

## What the app sends today (contracts to preserve)

The client currently calls the OSM services directly. If you put a proxy in
front, keep these shapes — `OsmGeocoder` and `OsrmRouting` parse them exactly:

| Service | Request | Parsed fields |
|---|---|---|
| Photon | `GET /api?q=&limit=&lang=en&lat=&lon=` | `features[].geometry.coordinates` **`[lon, lat]`**, `features[].properties.{name,street,housenumber,district,city,state,postcode,country}` |
| Nominatim | `GET /reverse?lat=&lon=&format=jsonv2&addressdetails=1` | `display_name`, `address.{road,neighbourhood,city\|town\|village,state_district,state,postcode,country}` |
| OSRM | `GET /route/v1/driving/{lon,lat};{lon,lat}?overview=full&geometries=polyline` | `code`, `routes[0].{geometry,distance,duration}` |

**The coordinate order is the trap.** GeoJSON and OSRM both speak `[lon, lat]`;
Google spoke `lat,lng`. Getting it backwards puts Dehradun in the Indian Ocean
and does not error.

---

## Known gap the backend could close

**OSRM has no live traffic.** Ride drop-ETAs are now free-flow estimates and read
optimistically during rush hour. Fare *distance* is unaffected, so pricing is as
accurate as before — but if traffic-aware ETAs matter commercially, the options
are a routing provider that models traffic (Mapbox/HERE/TomTom all expose
OSRM-shaped APIs) or a **server-side multiplier by time of day and corridor**,
which we are better placed to derive than any vendor: we have the historical ride
durations.

---

## Related

- `docs/OSM_DEVOPS_GUIDE.md` — standing the services up
- `docs/OSM_FRONTEND_GUIDE.md` — how the app consumes them
