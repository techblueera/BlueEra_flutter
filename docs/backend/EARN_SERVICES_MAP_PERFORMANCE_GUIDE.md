# Earn-Services `all/map` — Performance Guide (Node)

**Endpoint:** `GET /api/earn-service/services/all/map`
**Consumers:** `SelfProfessionDiscoverScreen` (paginated list, `limit=20`) and its
full-screen map (`limit=1000`), via `DiscoverController.fetchEarnServices` /
`fetchAllEarnServicesForMap`.

## 1. Measured today

Client-side timing (Stopwatch around the request + JSON decode only, logged as
`EARN_SERVICES_API`):

```
EARN_SERVICES_API: list took 2516ms
  (page=1, category=TECHNICIAN, lat=26.2751509, lng=72.9972754, radius=1500, success=true)
```

**2.5 s for 20 rows.** Target for a list this size is **≤ 400 ms** p50 /
≤ 800 ms p95 on 4G.

The client side of the delay has already been fixed (it was awaiting a fresh
GPS fix per item after the response landed). What remains is server time plus
payload size — everything below is backend work.

> **First action for whoever picks this up:** split server time from transfer
> time before optimising. `curl -w "ttfb=%{time_starttransfer}s total=%{time_total}s size=%{size_download}\n"`.
> A large `ttfb` means query/serialisation (§3, §5); a small `ttfb` with a large
> `total` means payload size (§2).

## 2. Trim the list payload (biggest, safest win)

The list endpoint currently returns the **full provider document**. The card
(`_buildSpecCard`) renders only:

| Card element | Field |
|---|---|
| Name, avatar | `name`, `profile_image` |
| Eyebrow | `profession` / `designation` |
| Hero image | `serviceMedia.photos[0]` |
| Distance | `distanceKm` |
| Address | `address` |
| Rating | `rating` |
| Price | `priceData.priceRange` / `feeType` |
| Hours chip | `service.availability` → min/max only |
| Availability pill | `isLive` |
| "Services offered" (max 6) | `service.servicesOffered` + `service.typesOfWork` |
| Routing | `id`, `serviceId`, `account_type` |

Everything else is dead weight on this endpoint. Currently shipped per row and
**never read by the list**:

- `device_token` — ~180 chars of FCM token
- `password` (empty string today, but the field should not exist in a response)
- `email`, `contact_no`, `referral_code`, `referred_by`, `referral_points`
- `bio` (up to ~400 chars), `objective`, `description`, `title`
- `date_of_birth`, `gender`, `language`, `deleted_at`, `is_ended`, `last_seen`
- `social_links`, `seoTags`, `qr_url`, `highest_education`, `school_or_college_name`,
  `sector`, `department`, `sub_division`, `current_organisation`, `specialization`
- `service.expertise`, `service.whyChooseMe`, `service.workCategories`,
  `service.facilities`, `service.timings`
- `service.availability.schedule` — **all 7 days with time slots**, where the card
  needs one min/max pair

### 2.1 `device_token` and `password` must go now

Independent of performance: an authenticated user listing electricians receives
every listed provider's push token. That is a push-spoofing vector and should be
projected out of every client-facing response, not just this one.

### 2.2 Suggested projection

```js
const LIST_PROJECTION = {
  id: 1, serviceId: 1, name: 1, profile_image: 1, account_type: 1,
  profession: 1, designation: 1, category: 1,
  address: 1, user_location: 1, rating: 1, reviewCount: 1,
  isLive: 1, priceData: 1,
  'serviceMedia.photos': { $slice: 1 },       // card shows one hero image
  'service.servicesOffered': { $slice: 8 },   // card caps at 6 + "N more"
  'service.typesOfWork': { $slice: 8 },
  'service.availability.schedule': 1,         // or precomputed openFrom/openTo
};
```

Even better for `availability`: precompute `openFrom` / `openTo` (or
`todayOpenFrom` / `todayOpenTo`) server-side. The client currently parses all 7
days and reduces them to a min/max pair — that reduction belongs on the server,
where it is done once instead of per device.

**Expected effect:** most of the response body disappears. Bytes are the part of
`total` that scales with a slow mobile uplink, so this helps p95 more than p50.

## 3. Presigned S3 URLs — cost *and* a caching bug

Every photo URL comes back presigned:

```
…/6a539628…/67017ced-…?X-Amz-Algorithm=…&X-Amz-Date=20260724T122030Z
&X-Amz-Expires=3600&X-Amz-Signature=44add6c7…&X-Amz-SignedHeaders=host…
```

Two problems:

1. **~600 chars per URL, up to 4 per row.** With `limit=1000` on the map call
   that is a large fraction of the response.
2. **It breaks image caching in the app.** `CachedNetworkImage` keys its cache on
   the full URL. `X-Amz-Date` and `X-Amz-Signature` change on *every* response,
   so the key never matches and **every hero image is re-downloaded on every
   fetch** — even one the user scrolled past 30 seconds ago. This is very likely
   the largest contributor to how slow the screen *feels* after the JSON arrives.

**Recommended:** serve list images from a CDN (CloudFront) with a stable path, and
keep presigning for private/detail assets only. If the bucket must stay private,
put CloudFront in front with an origin-access identity so the client-visible URL
is stable and cacheable.

**Interim (cheap):** presign only `photos[0]` for the list (§2.2 already slices
to one) and let the detail screen presign the rest. Cuts signing work and bytes
by ~4× without changing the storage model.

## 4. `radius` semantics — 1500 is not "nearby"

The app sends `radius=1500` (km, from `kmRadius1500`). In the sample response
from Jodhpur (26.27, 72.99) the results run:

```
196 km, 241 km, 367 km, 443 km, 467 km, 474 km, 477 km, 481 km, 486 km,
487 km, 491 km, 492 km, 502 km, 510 km, 672 km, 797 km, 1005 km, 1042 km, 1142 km
```

`total: 85`. So the query is effectively national and the nearest "local
electrician" is a 4-hour drive away.

Please confirm the unit the API expects (km vs m). Assuming km, the client should
send 25–50, and the sensible server behaviour is:

- Honour `radius` when sent, clamped to a sane max (say 200 km).
- If a radius yields fewer than N results, **widen once** server-side and flag it
  (`"widenedTo": 100`) rather than silently returning the whole country — the app
  can then say "no electricians within 25 km, showing wider results".

This also makes the query cheaper: a tight `$geoNear` bounded by `maxDistance`
scans far fewer documents than a national sort.

## 5. Query shape — `$geoNear` + indexes

If distance is currently computed in JS after fetching candidates, that is the
likely source of the `ttfb`. Let Mongo do it:

```js
db.services.aggregate([
  { $geoNear: {
      near: { type: 'Point', coordinates: [lng, lat] },  // NOTE: lng first
      distanceField: 'distanceMeters',
      maxDistance: radiusKm * 1000,
      spherical: true,
      query: { type: 'service', subType: 'selfWork', category, isDeleted: { $ne: true } },
  }},
  { $sort: { isLive: -1, distanceMeters: 1 } },   // current observed ordering
  { $skip: (page - 1) * limit },
  { $limit: limit },
  { $project: LIST_PROJECTION },
  { $addFields: { distanceKm: { $round: [{ $divide: ['$distanceMeters', 1000] }, 2] } } },
]);
```

`$geoNear` gives `distanceKm` for free — no post-processing pass — and must be the
**first** stage.

**Indexes required:**

```js
db.services.createIndex({ user_location: '2dsphere' });
db.services.createIndex({ type: 1, subType: 1, category: 1, isLive: -1 });
```

Store coordinates as GeoJSON (`{ type: 'Point', coordinates: [lon, lat] }`) if
they aren't already — a plain `{ lat, lon }` object cannot use a 2dsphere index,
which would force a collection scan and would explain 2.5 s on its own.

Verify with `.explain('executionStats')`: look for `IXSCAN` (not `COLLSCAN`) and
compare `totalDocsExamined` against `nReturned` — they should be within an order
of magnitude of the page size, not of the collection.

## 6. Pagination count

`pagination.total: 85` implies a `countDocuments` alongside the geo query — a
second full traversal for a number the UI only uses to decide "is there more".

Options, cheapest first:

- Return `hasMore: results.length === limit` and drop `total` (the app's
  `hasMoreEarnServiceData` already infers this from the page length).
- Keep `total` but compute it only for `page === 1` and let the client cache it.
- `$facet` the count into the same pipeline so the geo filter is traversed once.

## 7. Response envelope (optional, breaking)

The payload nests every row under `services[].data[]`, grouped by profession,
even when the request filters to one category — so the client flattens it back
out. A flat `{ data: [...], pagination: {...} }` would be simpler on both sides,
but this is cosmetic and needs a coordinated release; leave it unless you're
versioning the endpoint anyway.

## 8. Suggested order of work

| # | Change | Effort | Expected gain |
|---|---|---|---|
| 1 | Drop `device_token` / `password` from the response | XS | Security |
| 2 | Confirm `2dsphere` index + `$geoNear` first stage | S | Potentially most of the 2.5 s |
| 3 | List projection (§2.2) | S | Large byte reduction |
| 4 | Presign only `photos[0]`, or move to CDN URLs | M | Byte reduction **+ image cache actually works** |
| 5 | Sane radius handling + widen-once | S | Cheaper query, better results |
| 6 | Drop/defer `total` count | S | One less collection traversal |

## 9. Acceptance criteria

- `ttfb` ≤ 300 ms p50 for `limit=20` with a 25 km radius.
- `EARN_SERVICES_API: list took …` reports ≤ 800 ms p95 on 4G.
- Response for `limit=20` contains no `device_token` / `password`.
- `explain()` shows `IXSCAN`, with `totalDocsExamined` within ~10× of `nReturned`.
- Hero images are served from stable URLs (verify: the same provider's
  `photos[0]` is byte-identical across two consecutive requests).

## 10. What the client already does

So the backend work isn't duplicated:

- Sends `lat` / `lng` / `radius` on both the list and map calls — omitted entirely
  when there is no GPS fix, so the server should keep working without them.
- Reads `distanceKm` from the response; only computes distance locally (from the
  cached fix, no GPS call) when the server omits it.
- Reads `isLive` and renders an Online/Offline pill.
- Caches a fetched list for 5 minutes per `category + rounded lat/lng`, so tab
  switches and screen re-entry do not re-hit this endpoint.
