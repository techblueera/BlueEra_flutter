# OSM Maps — Frontend Guide

**Audience:** anyone touching a map, an address field, or a route line in this
app.

Google Maps is gone. All 38 map screens render through one widget, `BlueMap`,
over `flutter_osm_plugin`. This is what replaced what, why it is shaped this way,
and the traps that cost time during the migration.

---

## 1. The layer — `lib/core/map/`

| File | Responsibility |
|---|---|
| `osm_config.dart` | **The only place a map host name appears.** Endpoints + the production checklist. |
| `blue_map.dart` | `BlueMap` widget + `BlueMapController`. Declarative markers/polylines/circles. |
| `marker_cluster.dart` | Client-side grid clustering. The plugin has none. |
| `osm_geocoder.dart` | Photon (type-ahead) + Nominatim (reverse). |
| `osrm_routing.dart` | Routing + polyline decoder + the `PointLatLng`/`PolylineResult` types. |
| `lat_lng.dart` | `LatLng`, `LatLngBounds`, `distanceBetweenMetres`. No plugin dependency. |
| `osm_http_client.dart` | A **separate Dio** for OSM traffic. |

### Why a separate HTTP client

`ApiBaseHelper`'s Dio attaches `Authorization: Bearer $authTokenGlobal` to every
request, because everything it was built for goes to our own backend. The Google
calls it used to make went to `maps.googleapis.com` **wearing that header** — a
BlueEra session token handed to a third party on every address keystroke.

That was survivable when the third party was Google. It is not something to carry
forward to a community-run geocoder, so OSM traffic gets its own client with no
app credentials on it. It also means a wedged geocoder can never occupy a
connection the rest of the app needs, and that a failed address search shows "no
results" rather than triggering the 401-logout interceptor.

---

## 2. `BlueMap` — the three problems it exists to solve

`OSMFlutter` is imperative and asynchronous in ways that are easy to get wrong.
Thirty-eight screens getting them wrong independently is what this widget
prevents.

### 2.1 Nothing works before the map is ready

Markers added, roads drawn or cameras moved before the platform view has
initialised are **silently dropped** — no error, no log. The natural place to add
a marker is `initState`, which is always too early.

`BlueMap` queues every controller call until the map reports ready, then replays
them in order. So this just works:

```dart
onMapCreated: (c) {
  _mapController = c;
  c.moveTo(target, zoom: 16);   // safe immediately
}
```

**This is why you will find no `Future.delayed(500ms)` in the map code.** Three
screens had one, each guessing at readiness. All are gone.

### 2.2 Markers are addressed by coordinate, not identity

The plugin's `removeMarker` takes the **position** of the marker to remove. So a
screen that moves a marker must remember where it used to be. Miss that and you
leak a marker on every update — on a live rider-tracking screen at one GPS tick
per 10 s, that is ~180 stale pins over a 30-minute ride.

All four live-tracking screens had exactly this shape (`_markers.removeWhere(...)`
then `.add(...)`) before migration.

**The fix is to stop tracking it at all.** Describe the markers that *should*
exist; `BlueMap` diffs by `id` and works out the rest:

```dart
List<BlueMapMarker> get _markers => [
  BlueMapMarker(id: 'pickup', position: _pickup, icon: Icons.location_on, color: Colors.green),
  if (_riderPos != null)
    BlueMapMarker(id: 'rider', position: _riderPos!, child: _riderIcon, angle: _headingRadians),
];
```

### 2.3 Declarative UI over an imperative map

Flutter screens rebuild; the map does not. Diffing the requested lists against
what is drawn keeps the two in step without every screen writing a reconciler.

---

## 3. Rules that will bite you

### Marker ids must be stable

**Never derive an id from the coordinate.** A marker whose id changes when it
moves reads to the diff as "one deleted, a different one added" — slower, and it
visibly flickers. Use `'pickup'`, `'drop'`, `'rider'`, or a model id.

### Marker children are compared by identity

`BlueMapMarker.child` is compared with `identical()`, not `==`. Build icon
widgets **once and hold them in a field**:

```dart
static const Widget _riderIcon = LocalAssets(
  imagePath: 'assets/svg/2_wheeler.svg',
  width: kVehicleMarkerSize, height: kVehicleMarkerSize,
);
```

Building it inside `build()` makes every frame look like a visual change and
redraws every marker continuously.

### Angles are radians, in `[0, 2π)`

`Position.heading` from geolocator is **degrees** and can be negative. The plugin
asserts the range, so a raw heading throws:

```dart
final degrees = position.heading % 360;
_headingRadians = (degrees < 0 ? degrees + 360 : degrees) * math.pi / 180.0;
```

### Coordinate order

GeoJSON (Photon) and OSRM both use `[longitude, latitude]`. Google used
`lat,lng`. `LatLng.fromGeoJson` exists for exactly this. Getting it wrong puts
Dehradun in the Indian Ocean and produces no error.

### Attribution is a licence condition

ODbL requires it. `BlueMap` and `StaticMapPreview` render
`OsmConfig.attribution` by default. Only pass `showAttribution: false` where the
surrounding UI already credits OSM — the one current case is the 180×200 floating
mini-map, whose full-screen counterpart carries it.

---

## 4. Migration crib sheet

| Google Maps | BlueMap |
|---|---|
| `GoogleMap(initialCameraPosition: CameraPosition(target: t, zoom: z))` | `BlueMap(initialCenter: t, initialZoom: z)` |
| `GoogleMapController` | `BlueMapController` |
| `Set<Marker>` / `Marker(markerId: MarkerId(…))` | `List<BlueMapMarker>` / `BlueMapMarker(id: …)` |
| `BitmapDescriptor` (async raster) | any `Widget` via `child:`, or `icon:` + `color:` |
| `anchor: Offset(0.5, 1.0)` | `anchor: BlueMarkerAnchor.bottom` |
| `Set<Polyline>` / `PolylineId` | `List<BlueMapPolyline>` / `id:` |
| two stacked lines for a casing | one line + `borderColor` / `borderWidth` |
| `patterns: [PatternItem.dash(…)]` | `isDotted: true` |
| `Set<Circle>` / `CircleId` | `List<BlueMapCircle>` / `id:`, `radiusMetres:` |
| `animateCamera(CameraUpdate.newLatLngZoom(p, z))` | `moveTo(p, zoom: z)` |
| `animateCamera(CameraUpdate.newLatLngBounds(b, pad))` | `fitBounds(b, padding: pad)` / `fitPoints(points, padding:)` |
| `onCameraMove` + `onCameraIdle` | `onCameraMoved` + `onCameraIdle` (debounced internally) |
| `onCameraMoveStarted` | first `onCameraMoved` after a rest — that is all the flag ever meant |
| `ClusterManager` / `clusterManagerId` | `BlueMap(clusterMarkers: true)` |
| `InfoWindow` | none — use `onMarkerTap` + an id→model map, then show a sheet |
| `MapType.hybrid`, `trafficEnabled` | **no equivalent** — see §6 |

---

## 5. Clustering

Google shipped a platform-side `ClusterManager`. The plugin has nothing, and five
Discover screens plot hundreds of pins — un-clustered that is unreadable and
slow, since each marker is a platform view.

`marker_cluster.dart` does grid clustering in Dart: O(n), stable between frames,
cluster centres are the **mean** of their members so a badge sits among its pins
rather than at a cell corner. Cell size is derived from **screen pixels** at the
current zoom, so clusters dissolve naturally as the user zooms in.

Enable with `clusterMarkers: true`. Tapping a cluster frames its members.
Covered by tests in `test/osm_map_test.dart`, including "no marker is ever
dropped at any zoom".

---

## 6. What we lost, honestly

- **Live traffic.** No OSM equivalent. `passenger_destination_screen` lost its
  traffic toggle — removed rather than left as a dead button.
- **Satellite / hybrid basemap.** Needs a separate imagery provider; would be a
  second `tileUrlTemplate`. Same screen lost that toggle too.
- **Traffic-aware ETAs.** OSRM durations are free-flow, so ride drop-ETAs read
  optimistically at rush hour. **Fare distance is unaffected** — pricing is as
  accurate as before. See `RideBookingController._resolveRoute`.
- **Info windows.** Marker taps now resolve through an id→model map and open a
  sheet, which is what most screens were doing anyway.

## 7. What we gained

- **Place Details is free.** Photon returns coordinates inline with each
  suggestion, so `PlaceRepo.resolvePlace` is now string parsing with **no network
  call**. The single most expensive pattern in the old app — five billed lookups
  per keystroke burst to render distance labels — is now free rather than merely
  discouraged.
- **Static previews cache better.** Tiles are addressed by a fixed grid, so two
  shops on one street share tiles. Google's Static API gave each coordinate a
  unique URL and shared nothing.
- **Icons are correct on the first frame.** No async raster encode, so live
  tracking no longer shows default pins for the first few frames of a ride.

---

## 8. Before you ship

`OsmConfig` still defaults to public demo servers that forbid consumer-app
traffic. `main()` calls `_assertOsmConfigured()`, which debug-warns until the
self-hosted hosts are set. See `docs/OSM_DEVOPS_GUIDE.md`.

Separately: **the old Google Maps API key must be revoked in the Cloud Console.**
It is compiled into every build shipped to date and keeps working — and billing —
for anyone who has extracted it. Deleting it from the repo does not stop that.

---

## Related

- `docs/OSM_DEVOPS_GUIDE.md` — self-hosting the four services
- `docs/OSM_BACKEND_GUIDE.md` — work the backend should absorb
- `docs/GOOGLE_MAPS_*.md` — **historical**; they describe a system that no longer
  exists, kept for the reasoning behind the cost decisions
