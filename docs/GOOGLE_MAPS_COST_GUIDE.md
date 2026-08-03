> **⚠️ HISTORICAL — describes a system that no longer exists.**
>
> BlueEra was migrated off Google Maps Platform to OpenStreetMap on 2026-08-03.
> There is no `google_maps_flutter`, no Places/Geocoding/Directions/Static Maps
> usage, and no Google Maps API key in the app any more.
>
> Kept because the cost analysis explains **why** the current design looks the
> way it does (session caches, rate floors, static previews). Do not follow it
> as instructions.
>
> Current docs: `OSM_DEVOPS_GUIDE.md`, `OSM_BACKEND_GUIDE.md`,
> `OSM_FRONTEND_GUIDE.md`.

# Google Maps Billing — What We Call, Why It Costs, How To Cut It

Written after an unexpectedly large bill on `GOOGLE_MAP_KEY`. This is an audit of
every Google-billed call in the Flutter app, ranked by expected cost, with the
fix for each.

**Scope:** this guide is the **Flutter app**. For Cloud Console checks (is the
traffic even ours?), key restrictions, quotas, and the server-side fixes, see
**`GOOGLE_MAPS_BACKEND_DEVOPS_GUIDE.md`**. Do its Part A triage first — client
optimisation assumes the traffic is ours, and that assumption is worth ten
minutes of checking.

## Status

| Fix | State |
|---|---|
| §3.3 `fields` on Place Details | **DONE** |
| §3.1 stop fanning out Place Details | **DONE** — all 4 screens |
| §3.4 Directions throttle | **DONE** — all 11 map/tracking sites now go through `RoutePolylineService`; the fare-quote call is deliberately excluded (see that class) |
| Autocomplete: location bias, 3-char minimum, 600 ms debounce, session cache | **DONE** |
| §3.5 static images for the chat location cards | **DONE** — ⚠️ needs **Maps Static API** enabled on the key |
| §3.2 session tokens | not done — belongs in the backend proxy |
| §3A backend items | not done — see the backend guide |

**None of this has been run.** `flutter analyze` is clean across every changed
file, but no manual testing has happened — see the handover notes at the end of
this section in the chat, or just exercise address search + a live ride.

Everything below is from reading the code. **Before changing anything, confirm
against Cloud Console → Maps Platform → Metrics, grouped by SKU** — that is the
only authoritative source for where the money actually went. See
[§6 Diagnosing the real bill](#6-diagnosing-the-real-bill).

Prices move (Google restructured Maps pricing in 2025), so this guide talks in
relative terms — "cheapest tier", "most expensive tier" — rather than quoting
dollar figures. Check the current pricing page for absolute numbers.

---

## 1. What is billed, and where

### REST endpoints (URLs live in `lib/environment_config.dart:29-34`)

| API | URL | Wrapper |
|---|---|---|
| Places Autocomplete | `maps.googleapis.com/maps/api/place/autocomplete/json` | `PlaceRepo.autoCompleteSearch`, `PlaceRepo.getCitiesByState` |
| Place Details | `maps.googleapis.com/maps/api/place/details/json` | `PlaceRepo.getCompletePlaceDetails` |
| Geocoding | `maps.googleapis.com/maps/api/geocode/json` | `PlaceRepo.getGeoCode` |

All three go through **`lib/core/common_bloc/place/repo/place_repo.dart`**. That
single file is the choke point for three of the five cost drivers below — most
of the fixes in this guide are edits to it, which is why they are cheap to make.

### Billed, but with no URL in our code

| API | How we call it | Sites |
|---|---|---|
| **Directions** | `RoutePolylineService.fetch(...)`, which wraps `flutter_polyline_points` | 11 + 1 direct |
| **Dynamic Maps** (map loads) | the `GoogleMap` widget from `google_maps_flutter` | 46 files |

Directions is easy to miss in an audit because the URL never appears in the repo.
It now has a single choke point — **`lib/core/services/route_polyline_service.dart`**
— which is where its caching and throttling live. The one intentional exception is
the fare quote in `RideBookingController._resolveRoute`; that class documents why.


---

## 2. What is NOT billed

Do not "optimise" these; they cost nothing and the app depends on them.

- **`LocationService.getAddressUsingLatLng` / `fetchCurrentLocation`**
  (`lib/core/services/location/location_service.dart:117,228`) use
  `placemarkFromCoordinates` from the **`geocoding` package**, which is the
  native Android/iOS geocoder. Free, offline-capable, never touches our key.
  This is why our reverse-geocoding volume is near zero despite running on every
  app launch.
- **`LiveLocationService`** (`lib/features/chat/auth/service/location_update_service.dart`)
  — its 60-second timer POSTs to *our own* backend, not Google.
- **`geolocator`** — raw GPS from the OS.

The rule this gives us: **reverse geocoding (lat/lng → address) is free via the
`geocoding` package; forward geocoding and place search cost money.** Prefer the
package wherever an address string is all you need.

---

## 3. The cost drivers, ranked

### 3.1 Address search buys Place Details for every row in the list ← worst · **FIXED**

**Where:**

| File | Line | Shape |
|---|---|---|
| `features/ride_booking/controller/ride_booking_controller.dart` | 521 | `Future.wait` over all predictions (parallel) |
| `features/common/Discover/view/book_your_transport/search_transport_address.dart` | 480 | `for` loop over all predictions |
| `features/common/Discover/view/book_your_transport/search_address_screen.dart` | 155 | `for` loop over all predictions |
| `features/common/map/widget/search_place_list.dart` | 118 | `for` loop over all predictions |

All four take the autocomplete predictions and immediately call
`getCompletePlaceDetails` on **every one of them**, to fill in lat/lng (and, in
three of them, to compute a "x km away" distance label).

**The cost.** Google returns up to 5 predictions. So one debounced keystroke
burst = 1 Autocomplete + **5 Place Details**. A user typing an address triggers
2-4 bursts before they see what they want, so a *single address entry* can cost
~4 Autocomplete + ~20 Place Details — and the user taps exactly one row. We are
paying to resolve 19 places nobody looked at, at the most expensive Place Details
tier (see §3.3).

**The fix, as applied.** All four now resolve only the tapped row, via
**`PlaceRepo.resolvePlace(placeId)`** — which additionally caches by `place_id`
for the session, so re-picking a place already used as a pickup costs nothing.
Each row shows a spinner while resolving and blocks a second tap.

Three screens already did it correctly and were the model:

- `features/common/Discover/view/book_your_transport/quick_rider_book_screen.dart:188`
  (`_selectPrediction`, wired to `onTap` at line 502)
- `widgets/common_location_search_field.dart:242`
- `features/chat/view/business_chat/widgets/ride_drop_location_sheet.dart:123`

One behavioural bug fell out of this: `search_place_list` used to fall back to
the **map centre** when a prediction had no coordinates, silently selecting the
wrong place. It now refuses to navigate without real coordinates.

```dart
// BEFORE — bills 5 Place Details per keystroke burst
final results = PlacePrediction.fromList(predictionsJson);
for (final prediction in results) {
  final details = await PlaceRepo()
      .getCompletePlaceDetails(placeId: prediction.placeId ?? '');
  // …lat/lng + distance…
}

// AFTER — bills 1 Place Details, when the user actually picks something
final results = PlacePrediction.fromList(predictionsJson);
setState(() => _predictions = results);   // render immediately; no lookups

Future<void> _onPredictionTap(PlacePrediction p) async {
  final details = await PlaceRepo()
      .getCompletePlaceDetails(placeId: p.placeId ?? '');
  // …lat/lng…
}
```

**The distance labels were the catch.** Three of these screens showed "2.4 km
away" per row, which is *why* they resolved everything up front. Resolved by
doing both of:

1. **The labels are gone.** They were decoration on a list the user scans by
   name.
2. **Autocomplete is now location-biased** — `location` + `radius=30000` on the
   request (`PlaceRepo.autoCompleteSearch`). Free parameters, and nearby results
   simply come back first, which is what the label actually communicated. A bias
   and not a filter: `strictbounds` is deliberately not sent, so a user in
   Dehradun can still search Delhi.

Note it was **not** solved by caching details per `place_id` alone — that helps
on repeat searches but still pays full price for the first pass of every new
query. The cache is a complement, not the fix.

### 3.1b Autocomplete itself · **PARTLY FIXED**

Separate from the fan-out, the search requests themselves were wasteful:

| Change | Was | Now |
|---|---|---|
| Minimum query length | 2 chars | **3** — a 2-char query is the user still typing, not a search, and could never return a row worth tapping |
| Debounce | 350 ms | **600 ms** — each surviving burst is a billed request; the extra quarter-second is barely perceptible |
| Repeat queries | re-bought every time | **session cache** keyed on query + location (~1 km), so "deh" → backspace → "deh" bills once, and two screens searching the same text share it |
| Ranking | unbiased | **location-biased** (free) |

All autocomplete call sites were already debounced; these tune what survives it.
The remaining waste on this path is §3.2.

### 3.2 No session tokens anywhere · **NOT FIXED**

**Evidence:** grep for `sessiontoken` / `sessionToken` across `lib/` returns
**zero hits**.

**The cost.** Places has two billing models. Without a session token, every
autocomplete request bills individually as *Autocomplete – Per Request*, and the
Place Details call that follows bills separately at full price. With a session
token, the whole typing session **plus** the closing Place Details call bills
once as *Autocomplete – Per Session*. For a user typing a 10-character address,
that is the difference between paying for ~4 requests + 1 details, and paying
for one session.

This multiplies on top of §3.1 — fix both.

**The fix.** A session token is any UUID. Generate one when the search field
gains focus, send it on every autocomplete request for that field, send the
*same* one on the Place Details call for the row the user picks, then throw it
away. A new search starts a new token.

```dart
// place_repo.dart
Future<ResponseModel> autoCompleteSearch({
  required String query,
  String? sessionToken,          // ← add
}) async =>
    ApiBaseHelper().getHTTP(googleAutocomplete, showProgress: false, params: {
      'input': query,
      'key': googleMapKey,
      'types': 'geocode|establishment',
      'language': 'en',
      'components': 'country:in',
      if (sessionToken != null) 'sessiontoken': sessionToken,   // ← add
    });

Future<ResponseModel> getCompletePlaceDetails({
  required String placeId,
  String? sessionToken,          // ← add — MUST match the one above
}) async => …
```

A token only closes the session if the Place Details call carries it. A token on
autocomplete but not on details bills as *both* models and is worse than nothing.

### 3.3 Place Details asks for every field · **FIXED**

**Where:** `lib/core/common_bloc/place/repo/place_repo.dart:55-69`.

The request sends only `place_id` and `key` — **no `fields` parameter**. Google
therefore returns the complete payload (Basic + Contact + Atmosphere: reviews,
opening hours, phone numbers, photos, price level…) and bills at the most
expensive tier.

**What we actually use.** Every caller I checked reads
`result.geometry.location` — lat/lng — and occasionally the formatted address.
That is all Basic data, the cheapest tier.

**The fix, as applied.** One constant in one file, covering ~20 call sites:

```dart
// place_repo.dart
static const String _detailsFields =
    'geometry,formatted_address,address_components,name';
```

All four are Basic Data, the cheapest tier. The list is exactly what
`PlaceDetailsResponse` can parse, **minus `website`** — the model has a slot for
it, no screen reads it, and it is Contact-tier, so requesting it would have
re-priced every call in the app.

**If you ever widen this list**, check the tier of what you are adding. Contact
(`website`, `formatted_phone_number`) or Atmosphere (`rating`, `reviews`,
`opening_hours`) re-prices every Place Details call the app makes, because they
all share this one method.

### 3.4 Directions re-fetched on every location tick during a ride · **FIXED**

**Where:** all 10 `PolylinePoints(...).getRouteBetweenCoordinates(...)` sites.
The clearest example is `features/ride_booking/view/ride_tracking_screen.dart:124`.

That one guards against redundant refetches with a cache key rounded to **4
decimal places** — about **11 metres**:

```dart
final key = '${captain.latitude.toStringAsFixed(4)},'
            '${captain.longitude.toStringAsFixed(4)}>' …
if (key == _routeKey) return;
```

A moving vehicle covers 11 m every second or two, so the guard never actually
holds during a ride: **every poll tick buys a fresh full-route Directions call.**
With a 10-second poll that is ~360 calls per riding hour — and the rider's
navigation screen and the customer's tracking screen each do it independently,
so double it per ride.

**The fix, as applied.** All 11 map/tracking sites now go through
**`lib/core/services/route_polyline_service.dart`**, which applies three things
no caller can forget or get subtly wrong:

1. **Coordinate rounding to 3 decimals (~110 m)** for the cache key. At the zoom
   these maps sit at, 110 m is a few pixels of line.
2. **A session cache.** A leg fetched once is free thereafter — which also makes
   re-entering a tracking screen free, and means **the rider's screen and the
   customer's screen drawing the same leg share one call** instead of buying two.
3. **A 30-second floor** between network calls regardless of distance, because
   110 m passes in seconds on a fast road.

`fetch()` returns **null** when throttled or failed, and every call site was
updated to keep the line it is already drawing rather than clearing the map.

Two things it deliberately does not do:

- **The fare quote is excluded.** `RideBookingController._resolveRoute` still
  calls Directions directly: it runs once per quote rather than on a timer, has
  its own cache key, uses a different API, and — decisively — a null return would
  leave a user who just tapped a button with no distance. Rate-limiting that path
  would turn a cost fix into a broken booking.
- **It does not do deviation detection.** The captain driving *along* the
  polyline we already hold does not invalidate it, so the ideal guard is "refetch
  only when they have left the route". That belongs server-side, where it can be
  done once per ride instead of per screen — see the backend guide §B3, which
  supersedes this section entirely.

### 3.5 Map loads across 46 screens · **PARTLY FIXED**

Every mount of a `GoogleMap` widget is a billed Dynamic Maps load.

**The chat location cards were the worst case, and are fixed.** Both
`live_location_message_card` and `rider_live_location_msg_card` embedded a full
interactive `GoogleMap` in a chat bubble. Chat rows are disposed when they scroll
out of view and rebuilt when they scroll back — and `addAutomaticKeepAlives: true`
on the list does **not** save you, because it only preserves children that opt in
via `AutomaticKeepAliveClientMixin`, which these did not. So every scroll past a
location message bought another map load, and a busy thread holds several.

Both now use **`lib/widgets/static_map_preview.dart`**: a Maps Static API image
through `CachedNetworkImage`. Cheaper SKU *and* written to disk, so the second
view onwards — same scroll, same session, next launch — is free. Nothing was
lost: the coordinate in the bubble is fixed at `initState` and never updated (the
live position lives on the page it taps through to), and the sender's avatar is
now drawn as a widget over the image instead of being rasterised into a marker.

> ⚠️ **Requires "Maps Static API" enabled on the Cloud project.** It is a
> separately-enabled API. If it is off, the request 403s and the card shows a
> grey placeholder with a pin — degraded, not broken, but verify before shipping.

**Still to audit:** the other ~44 `GoogleMap` sites, for maps rebuilt rather than
kept alive, and other previews the user cannot interact with —
`features/business/visiting_card/…/business_location_widget.dart` is a candidate.

**Found while doing this:** `rider_live_location_msg_card` renders a **hard-coded**
coordinate (26.7836, 80.9013 — a fixed point in Lucknow) for every user in every
thread, rather than the rider's actual position. Preserved verbatim in the swap so
it stayed like-for-like, but it needs wiring to real data or removing.

---

## 3A. Backend-side fixes

§3 is all client work. The items below need server changes, and two of them
(§3A.1, §3A.2) are higher-leverage than anything in the app — they cut cost
*structurally* rather than by calling less often.

### 3A.1 Proxy every Google call through our backend

Today the app calls `maps.googleapis.com` directly with a key compiled into the
binary. Moving these behind our own API (`/maps/autocomplete`,
`/maps/place-details`, `/maps/route`) buys, in one change:

- **The key stops shipping.** It lives in server config only. This eliminates the
  leaked-key risk in §6 outright — the failure mode that no amount of client
  optimisation can fix.
- **One place to enforce §3.2 and §3.3.** Session tokens and the `fields`
  whitelist get applied server-side, so a new screen physically cannot forget
  them.
- **Server-side caching becomes possible** (§3A.2). Impossible while each device
  talks to Google directly.
- **Per-user rate limiting.** A client bug or a hostile user hits our limit, not
  our invoice.
- **Real visibility.** Log which screen/user drove which call. Cloud Console
  Metrics can tell you the SKU; only our own logs can tell you the *feature*.

The client change is small — `PlaceRepo` already funnels all three REST calls
through `ApiBaseHelper`, so this is mostly swapping base URLs in
`environment_config.dart` and dropping the `key` param.

### 3A.2 Cache Place Details server-side by `place_id`

Place data barely changes. Once the proxy exists, a cache in front of it turns
repeated lookups of the same well-known places — railway stations, malls, popular
localities, which is what most searches resolve to — into zero Google calls.

Expect a high hit rate: users in one city search the same handful of landmarks.

**Respect Google's caching terms**, which are stricter than normal HTTP caching:
`place_id` may generally be stored indefinitely, while other Places *content* has
a limited caching window (historically 30 days). Confirm the current Maps
Platform Terms before choosing a TTL, and key the cache so entries expire.

### 3A.3 Compute the ride route once, server-side — the app should never call Directions

This is the fix for §3.4, and it is better than any client-side throttle.

The backend is **already in this loop**: it polls/receives rider location
(`fare/orders/{orderId}/rider-location`) and already returns computed
`pickupEtaMinutes`, `dropEtaMinutes` and `captainDistanceMeters` on the ride
payload (`features/ride_booking/model/ride_booking_models.dart:143,146,391`). So
the server is already doing route maths while every client pays Google
separately for the same answer.

**Add an encoded polyline (and a reliable drop ETA) to the ride payload.** Then:

- The rider app and the customer app both draw the line from the order payload
  they are already polling — **two Directions calls per tick become zero**.
- The backend fetches Directions once per leg, and can throttle it centrally with
  the deviation logic from §3.4.3, in one place instead of ten screens.
- One route means the rider and customer can never see disagreeing lines or ETAs,
  which is a correctness win independent of cost.

Note `ride_tracking_screen.dart:64-66` says the payload "only ever sends a pickup
ETA", which is why that screen measures the drop ETA off its own Directions
reply — even though `dropEtaMinutes` exists in the model. Worth confirming with
the backend team whether that field is populated; if it is, one client screen can
stop calling Directions immediately, before any of the above lands.

### 3A.4 `getCitiesByState` should not touch Google at all

`place_repo.dart:41` resolves an Indian state's cities through **Places
Autocomplete** (`types=(cities)`). This is a **static dataset** — the cities of
Uttarakhand do not change between releases — being re-bought from Google on every
lookup, forever.

Serve it from our own DB (or bundle it as a JSON asset). Cost goes to zero
permanently, and it works offline. There is already precedent for not defaulting
to Google: pincode lookup uses the free `api.postalpincode.in`
(`environment_config.dart:36`).

### 3A.5 Distance labels belong on the server

The "2.4 km away" labels are the only reason three search screens fan out Place
Details (§3.1). Our backend already does geo queries — the nearby-discover
endpoint ranks stores by distance from a lat/lng. If search results need a
distance, the proxy in §3A.1 can attach it from the geometry it already fetched,
and the client never needs a details call per row.

### 3A.6 Serve map thumbnails from our own storage

For the non-interactive map previews in §3.5, render the image once server-side
(Maps Static API) and store it. Every subsequent viewer of that chat card or
business profile is served our cached PNG — Google is paid once per location, not
once per view.

---

## 4. What is left

**Done (Flutter):** §3.1, §3.1b, §3.3, §3.4, and the chat-card half of §3.5.
Nothing further is required for those — the remaining wins there are structural
and belong on the server.

**Still open on the Flutter side, in priority order:**

1. **Enable "Maps Static API"** on the Cloud project. One toggle, and the chat
   location cards depend on it. Do this before the build ships.
2. **Test what has been done.** All of it passes `flutter analyze` and none of it
   has been run. Address search, ride tracking and the chat location cards all
   changed behaviour. This outranks every item below.
3. **§3.2 session tokens.** Real money, and doable in the app, but better done
   once inside the backend proxy than threaded through every search screen's
   state. Do it client-side only if the proxy is far off.
4. **Audit the other ~44 `GoogleMap` widgets** for maps rebuilt rather than kept
   alive, and for previews that could be static.
5. **Fix the hard-coded coordinate** in `rider_live_location_msg_card` (see
   §3.5). A correctness bug, not a cost one, but it was found here.

**Needs the backend** (see the backend guide): route in the ride payload (§B3),
proxy + cache (§B1/§B2), static map thumbnails (§B5). The client change for each
is small — swap a base URL, read a field already in the model, load an image URL.

---

## 5. Rules for new code

- **Never call Place Details in a loop over predictions.** One tap, one lookup.
  Use `PlaceRepo.resolvePlace(placeId)` from the row's tap handler.
- **Never call Place Details without `fields`** — and never widen
  `PlaceRepo._detailsFields` without checking the tier of what you add. It
  re-prices every call in the app.
- **Never call `PolylinePoints` directly.** Go through
  `RoutePolylineService.fetch(...)`, and handle its null return by keeping the
  line you already have.
- **Debounce every autocomplete field**, and do not search below
  `RideBookingController.minSearchChars`. A field with no debounce bills per
  keystroke.
- **Need an address from coordinates?** Use `placemarkFromCoordinates`
  (`geocoding` package, free) — not `PlaceRepo.getGeoCode`.
- **A map the user cannot pan or zoom** should be a static image, not a
  `GoogleMap`.
- **Always pass a session token** through an autocomplete → details pair, once
  §3.2 lands.

---

## 6. Diagnosing the real bill

1. Cloud Console → **Google Maps Platform → Metrics**.
2. Group by **SKU** (not by API — one API spans several SKUs at very different
   prices, which is the whole point of §3.3).
3. Set the range across a spike and read off which SKU carries the cost. Rank
   the fixes above against what you see rather than against my ranking.
4. Cross-check **Reports → Usage** by platform/credential to confirm the traffic
   is coming from our apps at all.

### Check the key restrictions too

`GOOGLE_MAP_KEY` is compiled into the app via `envied` (`lib/env.dart:7`).
`envied` **obfuscates, it does not secure** — the key can be recovered from a
shipped APK/IPA. An unrestricted key that leaks is the classic cause of a bill
that no code change explains.

Verify in Console → Credentials:

- **Application restrictions**: Android apps (package name + SHA-1) and iOS apps
  (bundle ID). The REST endpoints in §1 are called over HTTPS from the device, so
  also confirm whether they are covered by the restriction you set — if not, that
  key is callable by anyone who extracts it.
- **API restrictions**: allow only Maps SDK for Android/iOS, Places, Geocoding,
  Directions. Nothing else.
- **Quotas**: set a daily cap per API. A cap turns a runaway bug or an abused key
  into a broken feature you find out about, instead of an invoice you find out
  about a month later.
- **Budget alerts** on the billing account, at a fraction of the expected monthly
  spend.

If Metrics shows traffic that does not match our platform mix, rotate the key
before optimising anything — no amount of the above will fix someone else using
our quota.
