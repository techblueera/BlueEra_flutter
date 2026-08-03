# OSM Self-Hosting — DevOps Guide

**Audience:** whoever owns the servers.
**Status:** the app is fully migrated off Google Maps. Nothing here is optional
if BlueEra is going to production — the app currently points at public community
servers that forbid the traffic we generate.

---

## 0. The one-paragraph version

The app needs four services: **map tiles**, **address search**, **reverse
geocoding**, and **road routing**. All four are OpenStreetMap-based and all four
are currently pointed at free public demo servers that will rate-limit and
IP-block us under real load. Stand up our own, put the four URLs into
`OsmConfig.configure()` in `lib/main.dart`, and the app needs no other change —
no screen, repo or service knows a host name.

---

## 1. What the app asks for

| Need | Service | App calls it via | Volume driver |
|---|---|---|---|
| Map imagery | **Tile server** (raster `{z}/{x}/{y}.png`) | `OsmConfig.tileUrlTemplate` | every map screen + every `StaticMapPreview` in a list |
| Address type-ahead | **Photon** | `OsmGeocoder.autocomplete` | every keystroke in a search field (debounced 350–600 ms) |
| Coordinates → address | **Nominatim** | `OsmGeocoder.reverse` | drag-to-pin screens, on camera idle |
| Road route + distance + ETA | **OSRM** | `OsrmRouting.route` | fare quotes, and live tracking during rides |

### Why Photon *and* Nominatim

They are not redundant. **Nominatim's usage policy explicitly forbids
autocomplete** — it is built for one-shot lookups, and keystroke traffic gets you
banned. Photon exists specifically for type-ahead and is what every search field
in the app hits. Nominatim handles the one-off reverse lookups where its richer
`address` breakdown matters (the app reads `city` and `postcode` out of it).

Do not "simplify" by pointing both at Nominatim.

---

## 2. Do NOT ship against the public servers

The current defaults in `lib/core/map/osm_config.dart`:

```
photon.komoot.io                 demo instance; Komoot ask you to self-host
nominatim.openstreetmap.org      ~1 req/sec, autocomplete forbidden, will IP-block
router.project-osrm.org          "for testing, not production" per the project
tile.openstreetmap.org           no heavy/commercial use per the tile policy
```

This does not fail loudly in QA. It fails in production, in whichever city is
busiest, as rate-limit errors and IP bans — and because our users share egress
IPs behind carrier NAT, one heavy user can get a whole region blocked.

`main()` calls `_assertOsmConfigured()`, which prints a debug warning while any
endpoint still points at a demo host. It is **debug-only on purpose** — a release
build must never be taken down by a config check — so it will not save you if
nobody reads the console. Treat this document as the gate, not the warning.

---

## 3. Sizing — India-only extract

All four services run from a single OSM extract. Use the **India** extract from
Geofabrik (~1.5 GB PBF), not the planet file.

| Service | RAM | Disk | Notes |
|---|---|---|---|
| Nominatim | 16–32 GB | ~150 GB SSD | The import is the expensive part, not serving. PostgreSQL-backed. |
| Photon | 8–16 GB | ~60 GB SSD | Elasticsearch-backed. Can import *from* a Nominatim DB. |
| OSRM | 8–16 GB | ~30 GB SSD | RAM scales with profile + extract; `osrm-partition`/`osrm-customize` (MLD) is lighter to update than CH. |
| Tile server | 8 GB | ~200 GB SSD (with tile cache) | The disk hog is rendered-tile cache, not the DB. |

**Practical shape:** one 32 GB / 8 vCPU / 500 GB NVMe box runs all four for
India comfortably. Two boxes if you want tiles isolated — tiles are the highest
request-rate service by a wide margin and the least latency-sensitive.

**SSD is not optional.** Nominatim import on spinning disk takes days instead of
hours, and query latency is dominated by random reads.

---

## 4. Standing them up

Docker images that are actively maintained and take a `.osm.pbf` directly:

- **Nominatim** — `mediagis/nominatim`
- **Photon** — `rtuszik/photon-docker` (or build from the Komoot jar; it can
  import from an existing Nominatim DB, which saves a second full import)
- **OSRM** — `osrm/osrm-backend` (run `osrm-extract` → `osrm-partition` →
  `osrm-customize`, then `osrm-routed --algorithm mld`)
- **Tiles** — `overv/openstreetmap-tile-server`

Order matters: import Nominatim first if you intend to seed Photon from it.

### Profiles

OSRM is built **per profile**. `car.lua` is what BlueEra needs — every routing
call in the app is `TravelMode.driving` (see `OsrmRouting._profile`; `transit`
deliberately falls back to driving because OSRM routes roads, not timetables).
Do not build foot/bike unless a product need appears; each is a separate dataset.

---

## 5. Update cadence

OSM data changes constantly; our tolerance for staleness differs per service.

| Service | Suggested cadence | Why |
|---|---|---|
| Nominatim | weekly, via replication diffs | New addresses/buildings matter for reverse geocode accuracy |
| Photon | weekly, follows Nominatim | Search results should agree with reverse lookups |
| OSRM | monthly, full rebuild | New/closed roads change routes; rebuild is all-or-nothing |
| Tiles | continuous re-render or expiry | Cosmetic; stale tiles are survivable |

**OSRM cannot be updated incrementally** in the way the others can — plan a
rebuild window and swap containers behind the proxy rather than taking routing
down. Routing down means **no fare quotes**, which means no bookings.

---

## 6. Reverse proxy, TLS, and what to lock down

Put all four behind one nginx/Caddy with TLS. Suggested layout:

```
https://maps.<domain>/tiles/{z}/{x}/{y}.png   → tile server
https://maps.<domain>/photon/api              → Photon
https://maps.<domain>/nominatim/              → Nominatim
https://maps.<domain>/osrm/                   → OSRM
```

Then in `lib/main.dart`:

```dart
OsmConfig.configure(
  tileUrlTemplate:  'https://maps.<domain>/tiles/{z}/{x}/{y}.png',
  photonBaseUrl:    'https://maps.<domain>/photon',
  nominatimBaseUrl: 'https://maps.<domain>/nominatim',
  osrmBaseUrl:      'https://maps.<domain>/osrm',
);
```

**Rate-limit per IP at the proxy.** Not to save money — these are our servers —
but because a buggy client build or a scraper can otherwise saturate Nominatim
and take address entry down app-wide. Sensible starting points: tiles 200 r/s,
Photon 20 r/s, Nominatim 5 r/s, OSRM 10 r/s, all per IP with burst.

**Cache tiles aggressively at the proxy** (`proxy_cache`, long TTL). Tiles are
immutable enough that a week of caching is fine and it removes most load from
the renderer.

---

## 7. Monitoring — what actually predicts an outage

- **OSRM 5xx rate** — the sharpest signal. Routing failures mean fare quotes
  fail, which means bookings fail. Alert on any sustained non-zero rate.
- **Nominatim p99 latency** — climbs before it falls over. Above ~1 s means the
  DB is not holding its working set in RAM.
- **Photon query latency** — sits directly under a typing user; above ~300 ms the
  search field feels broken.
- **Tile cache hit ratio** — below ~90 % means the renderer is doing work the
  proxy should absorb.
- **Disk free on the Nominatim volume** — a full disk during a replication update
  corrupts the import and costs a full re-import.

---

## 8. Attribution is a licence condition

OSM data is ODbL. Attribution is **required**, not a courtesy. The app renders
`OsmConfig.attribution` on every visible map (`BlueMap` and `StaticMapPreview`
both do this). Do not strip it to tidy up a screen. The one place it is
deliberately off is the 180×200 floating mini-map, which has no room and whose
full-screen counterpart carries it.

---

## 9. Cost reality

The data is free. The servers are not.

- **Self-hosted:** one box, roughly $40–80/month, flat at any request volume.
  Nothing per-request, ever, and no third party sees our users' addresses.
- **Managed alternative** (Geoapify / LocationIQ / Stadia / MapTiler): all expose
  Nominatim/Photon/OSRM-compatible endpoints, so switching is a host + `apiKey`
  change in `OsmConfig` and nothing else. Free tiers run a few thousand
  requests/day; beyond that you pay, but far below Google Maps Platform.

Either way this is a large reduction versus Google. It is **not** "free, point at
the public servers and ship".

---

## 10. Related

- `docs/OSM_BACKEND_GUIDE.md` — what the backend should serve so the app makes
  fewer of these calls at all
- `docs/OSM_FRONTEND_GUIDE.md` — how the app consumes these services
- `docs/GOOGLE_MAPS_COST_GUIDE.md`, `docs/GOOGLE_MAPS_BACKEND_DEVOPS_GUIDE.md` —
  **historical**; they describe a system that no longer exists. Kept for the
  reasoning behind the cost decisions, not as instructions.
