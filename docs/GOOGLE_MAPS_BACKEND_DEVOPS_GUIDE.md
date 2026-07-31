# Google Maps Billing — Backend & DevOps Guide

Companion to `GOOGLE_MAPS_COST_GUIDE.md`, which covers the Flutter app. This one
is for whoever owns the **Cloud Console project** and the **backend services**.

Split of concerns:

| Guide | Audience | Question it answers |
|---|---|---|
| `GOOGLE_MAPS_COST_GUIDE.md` | Flutter devs | "Which of our calls are wasteful?" |
| **this one** | DevOps + backend | "Is this traffic even ours, and why is it structurally expensive?" |

**Do Part A first.** Every client-side optimisation assumes the traffic is ours.
If the key is being used by someone else, or by our own dev builds, no amount of
app tuning will move the number — and you will have spent a sprint proving it.

## What the app already does (as of this round)

So the server work below complements it rather than duplicating it:

| In the app now | Effect |
|---|---|
| Place Details requests a Basic-tier `fields` list | Every such call dropped from the top price tier to the cheapest |
| Address search resolves only the **tapped** row | ~15-20 Place Details per address entry became 1 |
| `PlaceRepo.resolvePlace` caches by `place_id` | **Session-lifetime, in-memory only** — deliberately not persisted, see §B2 |
| `PlaceRepo` caches autocomplete replies by query + ~1 km location | Repeat/backspaced queries bill once |
| Autocomplete is location-biased, 3-char minimum, 600 ms debounce | Fewer, better-targeted searches |
| `RoutePolylineService` fronts all 11 map/tracking Directions calls | ~110 m rounding, session cache, 30 s floor — and the rider's and customer's screens now **share** one call for the same leg |
| Chat location cards use Maps **Static** API images, disk-cached | Was a Dynamic Maps load every time a bubble scrolled into view |

> **Action for DevOps:** the last row needs **Maps Static API enabled** on the
> project. It is a separately-enabled API; if it is off those cards degrade to a
> grey placeholder. Add it to the allowed-APIs list in §A3.2 as well.

Two things to carry into the server design:

- The app's caches are **in-memory and per-session**. They die with the process
  and are not shared between users. Durable, cross-user caching is §B2, and it is
  a backend responsibility for licensing reasons as much as technical ones.
- `RoutePolylineService` is an explicit **stopgap**. §B3 supersedes it: once the
  route is in the ride payload, the app stops calling Directions for tracking at
  all and that class can be deleted.

---

# Part A — DevOps / Cloud Console

## A1. Triage: is this our traffic?

Work through this in order. Stop when a step explains the spike.

**1. Break the bill down by SKU.**
Console → Google Maps Platform → **Metrics** → group by **SKU**, range covering
the spike.

Group by API and you will learn nothing useful — one API spans several SKUs at
very different prices. "Place Details – Basic" and "Place Details – Atmosphere"
are the same API and materially different money. The SKU names map directly onto
the sections of the frontend guide:

| SKU you see dominating | Read |
|---|---|
| Place Details (any tier) | frontend guide §3.1, §3.3 |
| Places Autocomplete – Per Request | frontend guide §3.2 |
| Directions | frontend guide §3.4, this guide §B3 |
| Dynamic Maps | frontend guide §3.5, this guide §B5 |
| Geocoding | should be near zero — see A2 |

**2. Break it down by credential.**
Console → **Metrics**, filter by API key. If there is only one key for
everything, you cannot answer "Android or iOS? prod or dev? app or leak?" — fix
that first (§A3), then wait a day for clean data.

**3. Compare volume against your own numbers.**
Take a known figure from our backend — daily rides completed, daily active users
— and divide the Google call count by it. If the app makes N Directions calls per
ride and Console shows 50×N per ride, the calls are not coming from the ride
flow. That ratio is the single most useful diagnostic and nobody ever computes
it.

**4. Check the traffic shape.**
Genuine user traffic follows daily peaks and troughs. A flat 24-hour line, or
traffic at 3am local, is a script — either ours (a runaway retry loop, a cron) or
somebody else's.

## A2. Red flags that point away from the app

- **Geocoding volume above ~zero.** The app uses the native OS geocoder for
  reverse geocoding (`geocoding` package), which costs nothing. `PlaceRepo.getGeoCode`
  has exactly one caller. Significant Geocoding spend means something outside the
  Flutter app is using this key — a backend job, an old app version, or a leak.
- **Traffic from platforms we don't ship.** Web/browser referrers, or a
  user-agent mix that doesn't match our Android/iOS split.
- **Requests for APIs we don't call.** Distance Matrix, Roads, Elevation, Static
  Maps, Street View. We call none of these today. Any spend on them is not ours.
- **Old app versions.** A version from before a fix keeps costing until users
  upgrade. Check the release-adoption curve before concluding a fix didn't work.

## A3. Key hygiene — the single most important section

### The constraint you need to know about

`GOOGLE_MAP_KEY` is compiled into the app via `envied` (`lib/env.dart:7`).
**`envied` obfuscates; it does not secure.** The key can be recovered from a
shipped APK/IPA with standard tooling.

Worse, and this is the part that surprises people: the app calls
`maps.googleapis.com` **directly over HTTPS** (Places Autocomplete, Place
Details, Geocoding, and Directions via `flutter_polyline_points`). Those are *web
service* requests. Google's "Android apps" / "iOS apps" application restrictions
are designed for the native SDKs and are **not reliably enforced for web service
calls made from arbitrary HTTP clients** — which is exactly what our Dio calls
are.

Practical consequence: **the portion of our key used for REST calls cannot be
meaningfully locked down while those calls originate on the device.** Confirm the
current behaviour against Google's docs for your APIs, but plan on this being
true. It is the strongest argument for the backend proxy in §B1: once those calls
come from our servers, an **IP restriction** becomes possible and the key stops
shipping at all.

### Do these now, regardless

1. **Split the key.** One key per platform per environment:
   - `maps-android-prod`, `maps-ios-prod`, `maps-android-dev`, `maps-ios-dev`
   - Application restriction on each (package name + SHA-1 / bundle ID) — this
     *does* work for the Maps SDK map loads, which are a real share of spend.
   - Without this split, Metrics can never tell you where money goes, and
     rotating a compromised key takes down every platform at once.
2. **API restrictions.** Each key allows only what it needs: Maps SDK for
   Android/iOS, Places, Geocoding, Directions, **Maps Static API**. Nothing else.
   This alone bounds the damage from a leak to APIs we already pay for.
3. **Per-API daily quotas.** Set a ceiling somewhere above normal peak. A quota
   converts a runaway bug or an abused key into "a feature broke today, someone
   noticed" instead of "an invoice arrived next month". This is the highest
   value-per-minute action in this entire document.
4. **Budget alerts** on the billing account at 50% / 90% / 100% of expected
   monthly spend, emailing a human who will act.
5. **Debug builds must not use the prod key.** Verify what
   `projectKeys(environmentType:)` selects per build flavour, and confirm
   `Env.googleMapKey` differs between dev and prod. Developers hot-reloading a
   search screen all day is real, invisible money on the prod key.

### If you conclude the key leaked

Rotate first, optimise later. Create the new restricted keys, ship them, then
delete the old key once adoption is high enough. Keep the old key alive but
heavily quota-limited during the transition so old installs degrade rather than
break.

## A4. Ongoing monitoring

- **Billing export to BigQuery.** Turn it on. It is the only way to slice spend
  by SKU over time and to answer "when exactly did this start" months later.
- **A dashboard with the ratio from A1.3** — calls per ride, calls per DAU —
  rather than raw call counts. Raw counts grow with the business; ratios only
  move when something is wrong.
- **Alert on the ratio, not the total.**
- **Re-run the SKU breakdown after each release** that touches search or ride
  flows, so a regression is caught in days rather than at invoice time.

---

# Part B — Backend engineering

Ordered by leverage. §B1 and §B2 together are the structural fix; the rest are
individually worthwhile.

## B1. Proxy all Google calls through our API

Today every device holds the key and talks to Google directly. Move the four
call types behind our own endpoints:

```
POST /maps/autocomplete    { input, sessionToken?, lat?, lng? }
POST /maps/place-details   { placeId, sessionToken? }
POST /maps/route           { origin, destination, mode }
GET  /maps/geocode         ?lat=&lng=
```

What this buys, in one change:

- **The key stops shipping.** It lives in server config. Combined with an IP
  restriction, the leak vector in §A3 closes completely — and as established
  there, that vector *cannot* be closed while the calls come from the device.
- **Server-enforced field whitelists and session tokens.** A new screen
  physically cannot forget them; today it is a code-review promise.
- **Caching becomes possible** (§B2). Impossible per-device.
- **Per-user and global rate limits.** A client bug hits our limit, not our
  invoice. This is the backstop the Console quota (§A3.3) can't give you, because
  it can be per-user rather than project-wide.
- **Attribution.** Log which user, screen and feature drove each call. Console
  Metrics gives you the SKU; only our logs give you the *cause*.

The client side is genuinely small — `PlaceRepo`
(`lib/core/common_bloc/place/repo/place_repo.dart`) already funnels all three
REST calls through `ApiBaseHelper`, so it is a base-URL swap plus dropping the
`key` param. Directions is the one exception: it is currently made inside the
`flutter_polyline_points` package, so moving it means calling our endpoint and
decoding the polyline ourselves (the package exposes a decoder).

**Migration:** run both paths behind a remote-config flag, compare results and
latency on a sample, then cut over. Keep the direct path as a fallback for one
release.

## B2. Cache Place Details server-side

Once §B1 exists, put a cache in front of it keyed on `place_id`.

Expect a high hit rate: within one city, users search the same landmarks —
stations, malls, hospitals, well-known localities. Place geometry does not
change.

**Respect the Maps Platform Terms**, which are stricter than ordinary HTTP
caching. Broadly: `place_id` may be stored indefinitely, while other Places
*content* has a limited caching window (historically 30 days). Confirm the
current terms before choosing a TTL, and make sure entries actually expire.

The app now has a **session-lifetime, in-memory** cache
(`PlaceRepo.resolvePlace`) as a stopgap. It dies with the process and is
deliberately not persisted — durable caching is a backend responsibility,
precisely because of those terms.

## B3. Compute ride routes server-side — remove Directions from the app

The backend is **already in this loop**. It receives rider location
(`fare/orders/{orderId}/rider-location`) and already returns computed
`pickupEtaMinutes`, `dropEtaMinutes` and `captainDistanceMeters` on the ride
payload (`lib/features/ride_booking/model/ride_booking_models.dart:143,146,391`).
So the server is already doing route maths — while the rider app and the customer
app each separately pay Google for the same answer.

**Add an encoded polyline to the ride payload.** Then:

- Both apps draw the line from a payload they already poll. **Two Directions
  calls per tick become zero.**
- The server fetches Directions once per leg and throttles it centrally — one
  place, not ten screens.
- Rider and customer can no longer see disagreeing routes or ETAs. That is a
  correctness win independent of cost.

**Throttling on the server** should key off route validity, not time: refetch
when the captain has deviated from the stored polyline (wrong turn, reroute) or
when an endpoint changes — not merely because they moved. This is the guard the
app deliberately does *not* implement, because doing it per-screen means doing it
several times per ride; doing it here means once.

When this ships, `RoutePolylineService` and its 11 call sites can be deleted.

**One thing to confirm now, before any of this:**
`lib/features/ride_booking/view/ride_tracking_screen.dart` carries a comment
saying the payload "only ever sends a pickup ETA", which is why that screen
measures the drop ETA off its own Directions reply — even though `dropEtaMinutes`
exists in the model. **Is the backend populating that field?** If yes, one client
screen can stop calling Directions immediately, with no new backend work.

## B4. Serve static datasets ourselves

`PlaceRepo.getCitiesByState` resolves an Indian state's cities through **Places
Autocomplete** — a static dataset (the cities of Uttarakhand do not change between
releases) bought from Google on every lookup.

**It currently has zero callers**, so it is costing nothing today. Treat it as a
trap rather than a live cost: delete it, or replace its body with our own stored
list before someone wires it up. Cost then stays at zero permanently and it works
offline. There is precedent for not defaulting to Google — pincode lookup uses
the free `api.postalpincode.in` (`lib/environment_config.dart:36`).

Audit for others: anything where the answer is the same for every user and does
not change is a candidate.

## B5. Cache map imagery

For non-interactive map previews — chat location cards, business profile location
blocks, visiting cards — render the image **once** server-side via the Maps
Static API, store it in our own bucket, and serve our URL.

Google is then paid once per distinct location instead of once per view. A
popular business's location card is currently a billed map load for every single
person who opens it.

Rule of thumb: **if the user cannot pan or zoom it, it should not be a live map.**

## B6. Attach distances server-side

The "x km away" labels in search results were the only reason the app resolved
every autocomplete prediction (frontend guide §3.1 — now removed, and the labels
with them).

If the product wants them back, the proxy (§B1) can attach distance from the
geometry it already fetched, or our existing geo-query infrastructure — the same
that ranks nearby stores for discover — can compute it. What must never come back
is the client resolving N places to label a list.

---

# Priority order

| # | Item | Owner | Effort | Why this order |
|---|---|---|---|---|
| 1 | SKU + credential breakdown (§A1) | DevOps | hours | Everything else is guesswork without it |
| 2 | Daily quotas + budget alerts (§A3.3-4) | DevOps | hours | Caps the bleeding today, whatever the cause |
| 3 | Split keys per platform/env (§A3.1) | DevOps | ~a day | Makes attribution possible; prerequisite for rotation |
| 4 | Confirm `dropEtaMinutes` is populated (§B3) | Backend | hours | May remove a Directions call for free |
| 5 | Static city list (§B4) | Backend | ~a day | Small, permanent, removes a whole call path |
| 6 | Route + polyline in ride payload (§B3) | Backend | ~a week | Removes the app's Directions usage entirely |
| 7 | Proxy + cache (§B1, §B2) | Backend | ~2 weeks | The structural fix; also closes the key exposure |
| 8 | Static map thumbnails (§B5) | Backend | ~a week | Scales with viewers, so it grows if left |

Items 1-3 are pure DevOps and can start immediately, in parallel with everything
else. Item 4 is a question, not a project — ask it today.
