# Frontend Integration Guide — `GET /api/nearby/discover`

One call answers "what's around me": nearby **stores** bucketed by business category, plus nearby **workers** split into **services** (plumbers, electricians…) and **riders** (bike riders, taxi drivers…).

`data` comes back as five sections in a fixed render order: **riders → grocery → food → services → product**.

Source: `src/controllers/discover.controller.js`, mounted at `src/routes/index.js` (`/api` → `/nearby` → `/discover`).

---

## 1. Request

```
GET /api/nearby/discover?lat=28.6139&lng=77.2090&radius=5
Authorization: Bearer <token>
```

Auth is **required** (`protect` middleware). A missing or revoked token returns 401.

### Query parameters

| Param | Required | Default | Range | Notes |
|---|---|---|---|---|
| `lat` | yes | — | -90…90 | Search centre latitude |
| `lng` | yes | — | -180…180 | Search centre longitude |
| `radius` | no | `5` | 0.1…100 | Kilometres. Out-of-range values are clamped, not rejected |
| `per_category` | no | `2` | 1…3 | Max stores per business category |
| `per_profession` | no | `2` | 1…3 | Max workers per profession |
| `types` | no | all three | subset of `Grocery,Food,Product` | Comma-separated, case-insensitive on input |

Only `lat`/`lng` validity and an empty `types` intersection produce a 400. Everything else is clamped silently, so you don't need to pre-validate `radius` or the `per_*` caps client-side.

The authenticated user is **excluded from their own results** — their businesses and their own worker profile never come back.

---

## 2. Response

```jsonc
{
  "success": true,
  "data": {
    "riders":   [ /* buckets */ ],
    "grocery":  [ /* buckets */ ],
    "food":     [ /* buckets */ ],
    "services": [ /* buckets */ ],
    "product":  [ /* buckets */ ]
  },
  "meta": { /* see §4 */ }
}
```

**The key order is the intended render order**, and the backend emits it deliberately: riders, grocery, food, services, product. Iterating `Object.keys(data)` gives you the section sequence for free — you don't need to hardcode it client-side. (JSON preserves insertion order; if your client parses into a structure that doesn't, keep the list above.)

`riders` and `services` are always present. The three store keys are **the types you requested**: pass `types=Food` and only `food` appears. A requested type is always present, possibly as an empty array — so `data.food.length === 0` is a valid "nothing nearby", while a *missing* `data.food` means you didn't ask for it.

### 2.1 Store bucket

```jsonc
{
  "category": {
    "id": "68a1...",
    "name": "Kirana Store",
    "image_url": "https://…",
    "type": "Grocery"              // matches the section key, title-cased
  },
  "count": 2,                       // === items.length
  "items": [ /* store cards, max per_category */ ]
}
```

Buckets are ordered **nearest-first** by their closest store.

### 2.2 Store card (`items[]`)

| Field | Type | Notes |
|---|---|---|
| `id` | string | Business id |
| `user_id` | string \| null | Merchant's user id |
| `business_name` | string | |
| `logo` | string | `""` when unset — don't assume a URL |
| `type` | string | `Grocery` \| `Food` \| `Product` |
| `type_of_business` | string | Free text, may be `""` |
| `address` | string | May be `""` |
| `business_location` | `{ lat, lon }` \| null | Note **`lon`**, not `lng` |
| `distance` | number | Kilometres from the search centre, 2 dp |
| `avg_rating` | number | `0` when there are no ratings |
| `total_ratings` | number | |
| `total_product_count` | number | Always ≥ 1 (see below) |
| `total_category_count` | number | Can be `0` for `Product` stores |
| `sub_category` | `{ id, name }` \| null | |

Two behaviours worth designing around:

- **Stores with no inventory are dropped entirely.** Every card you receive has at least one product, so you never need an "empty store" state.
- **A store's `type` is derived from which inventory service answers for it**, not from a category lookup. In the rare case a merchant stocks two domains, the store appears under one type only.

### 2.3 Service / rider bucket

```jsonc
{
  "profession": {
    "id": "68b2...",              // may be undefined when served from the built-in table
    "name": "Electrician",
    "tag_id": "ELECTRICIAN",
    "image_url": "",
    "profileType": "Self Employed" // or "GigWork" for riders
  },
  "count": 2,
  "items": [ /* worker cards, max per_profession */ ]
}
```

Use `tag_id` as your stable key for icons and grouping — `profession.id` is absent when the backend falls back to its vendored profession table (which is the default deployment state).

`services` holds `profileType: "Self Employed"`; `riders` holds `"GigWork"`. Both arrays are sorted nearest-first by their closest worker.

### 2.4 Worker card

| Field | Type | Notes |
|---|---|---|
| `user_id` | string | |
| `name`, `username` | string | May be `""` |
| `profile_image` | string | May be `""` |
| `designation` | string | Title-cased, e.g. `"Bike Rider"` |
| `profession` | string | Coarse enum, e.g. `"SELF_EMPLOYED"` — **not** for display |
| `distance` | number | Kilometres, 2 dp |
| `live` | boolean | See below |
| `contact_no` | string | May be `""` |
| `location` | `{ lat, lon }` \| null | Live position when `live: true`, registered otherwise |
| `service` | object \| null \| **absent** | Services only — see §2.5 |

**`live` is the field that drives your UI.** `true` means the worker is currently OPEN and actively pinging, and `location` is their real-time position. `false` means this is their registered home location and they may not be available right now. Within each bucket, live workers are sorted ahead of closer offline ones — so don't re-sort purely by distance or you'll bury the available people.

Show `designation` to users, never `profession`.

### 2.5 The `service` field (three states, not two)

On service worker cards only:

- **object** — the worker's earn listing
- **`null`** — the worker genuinely has no listing
- **key absent** — the earn service was unavailable; you don't know either way

Check with `'service' in item` rather than truthiness if you want to distinguish "no listing" from "couldn't load". When present:

```jsonc
{
  "id": "…", "title": "AC Repair", "category": "…", "sub_category": "…",
  "photos": ["https://…"],
  "price_type": "SINGLE" | "RANGE" | "",
  "single_price": 500,
  "price_range": { /* … */ } | null,
  "per_unit": "",
  "minimum_booking_amount": 0
}
```

Render price off `price_type`: `single_price` when single, `price_range` when a range. Riders never carry `service`.

---

## 3. Field-name gotchas

- Locations use **`lon`**, not `lng` — but the **request** takes `lng`. Mixing these up is the most common integration bug here. Map libraries mostly want `{ lat, lng }`, so convert at the boundary.
- Strings default to `""`, not `null`. `logo`, `profile_image`, `image_url`, `contact_no`, `address` all need empty-string fallbacks, not just null checks.
- Objects (`business_location`, `sub_category`, `price_range`, `service`) default to `null`.

---

## 4. `meta` and partial failures

```jsonc
"meta": {
  "lat": 28.6139, "lng": 77.209, "radius": 5,
  "types": ["Grocery", "Food", "Product"],
  "per_category": 2, "per_profession": 2,
  "counts": { "store_categories": 4, "stores": 7, "services": 3, "riders": 2 },
  "degraded": ["food_inventory"],
  "took_ms": 412
}
```

**Every upstream is best-effort.** A failure degrades its slice to empty and names itself in `meta.degraded` — the response is still `200 success: true`. This is the important thing to handle: an empty `data.food` with `"food_inventory"` in `degraded` means *an outage*, not *no restaurants nearby*. Showing "No restaurants in your area" there is wrong and unrecoverable from the user's side.

Recommended: if a slice is empty **and** its label is in `degraded`, show a "couldn't load, retry" state instead of an empty state.

| `degraded` label | Slice affected |
|---|---|
| `businesses` | all of `grocery` + `food` + `product` |
| `grocery_inventory` | `grocery` |
| `food_inventory` | `food` |
| `product_inventory` | `product` |
| `profession_master` | all of `services` + `riders` |
| `live_providers` | live workers (fallback still fills registered ones) |
| `live_user_hydration` | live workers |
| `registered_worker_fallback`, `registered_workers_*` | offline/registered workers |
| `earn_listings` | `service` key omitted on service cards |

`took_ms` is useful for your own perf logging. The backend caps the whole request at ~8s, so an 8s-ish response with several `degraded` entries means upstreams were slow, not that the request failed.

---

## 5. Errors

| Status | Body | When |
|---|---|---|
| 400 | `{ success: false, message }` | Missing/non-numeric `lat`/`lng`, out-of-earth-range coords, or `types` matching nothing |
| 401 | `{ success: false, message, code? }` | No token, expired token, or `code: "SESSION_REVOKED"` (signed in on another device) |
| 500 | `{ success: false, message, error }` | Unexpected failure — rare, since partial failures return 200 |

Treat `code: "SESSION_REVOKED"` as a hard logout — retrying won't help.

---

## 6. Example client

```ts
type LatLon = { lat: number; lon: number };

type StoreCard = {
  id: string;
  user_id: string | null;
  business_name: string;
  logo: string;
  type: "Grocery" | "Food" | "Product";
  type_of_business: string;
  address: string;
  business_location: LatLon | null;
  distance: number;
  avg_rating: number;
  total_ratings: number;
  total_product_count: number;
  total_category_count: number;
  sub_category: { id: string; name: string } | null;
};

type WorkerCard = {
  user_id: string;
  name: string;
  username: string;
  profile_image: string;
  designation: string;
  profession: string;
  distance: number;
  live: boolean;
  contact_no: string;
  location: LatLon | null;
  service?: EarnListing | null; // absent when earn_listings degraded
};

type Bucket<T, M> = { count: number; items: T[] } & M;

type StoreBucket = Bucket<StoreCard,
  { category: { id: string; name: string; image_url: string; type: string } }>;
type WorkerBucket = Bucket<WorkerCard, { profession: Profession }>;

// Declared in render order. Store sections are optional — absent when excluded
// by ?types.
type DiscoverResponse = {
  success: true;
  data: {
    riders: WorkerBucket[];
    grocery?: StoreBucket[];
    food?: StoreBucket[];
    services: WorkerBucket[];
    product?: StoreBucket[];
  };
  meta: {
    lat: number; lng: number; radius: number; types: string[];
    per_category: number; per_profession: number;
    counts: { store_categories: number; stores: number; services: number; riders: number };
    degraded: string[];
    took_ms: number;
  };
};

async function discoverNearby(
  { lat, lng, radius = 5, types, perCategory, perProfession }: DiscoverParams,
  token: string,
  signal?: AbortSignal
): Promise<DiscoverResponse> {
  const qs = new URLSearchParams({ lat: String(lat), lng: String(lng), radius: String(radius) });
  if (types?.length) qs.set("types", types.join(","));
  if (perCategory) qs.set("per_category", String(perCategory));
  if (perProfession) qs.set("per_profession", String(perProfession));

  const res = await fetch(`${API_BASE}/api/nearby/discover?${qs}`, {
    headers: { Authorization: `Bearer ${token}` },
    signal,
  });

  if (res.status === 401) throw new AuthError(await res.json());
  if (!res.ok) throw new ApiError(await res.json());
  return res.json();
}
```

Rendering a slice with the degraded distinction intact:

```ts
const foodBuckets = data.food ?? [];
if (foodBuckets.length === 0) {
  return meta.degraded.includes("food_inventory") || meta.degraded.includes("businesses")
    ? <RetryState onRetry={refetch} />
    : <EmptyState message="No food stores within 5 km" />;
}
```

Rendering every section in the backend's order, without hardcoding it:

```tsx
{Object.entries(data).map(([key, buckets]) => (
  <Section key={key} title={SECTION_TITLES[key]} buckets={buckets} />
))}
```

---

## 7. Practical notes

- **Debounce on map pan.** Results are cached backend-side in ~45–60s buckets keyed to ~110 m of geo precision, so small movements re-serve the same payload. Refetching more often than every few seconds just burns battery.
- **`live` goes stale fast.** Live positions come from workers actively pinging. If your screen stays open, refetch every 30–60s to keep rider positions honest, or drop the live badge after a minute.
- **Caps are hard.** `per_category` and `per_profession` are clamped at 3. This is a discovery surface, not a listing one — link out to the per-category endpoints for full lists.
- **Don't re-sort worker buckets by distance.** The backend deliberately puts live workers first.
- **Narrow `types` when you can.** It shrinks the payload, though not the backend's work.
