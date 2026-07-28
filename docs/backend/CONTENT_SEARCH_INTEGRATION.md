# Content Search API — frontend integration

Search across **posts and videos only**. Products, groceries, food, health items,
hospitals and every other catalogue entity are excluded and cannot be re-enabled
through a query parameter.

This is an **addition**, not a replacement — `/search` (global, everything) and
`/suggest` are unchanged. If you already call `/search?type=post`, that keeps
working exactly as before.

---

## Endpoint

```
GET {BASE}/search/content?q=<query>
```

| environment | BASE |
| --- | --- |
| prod | `https://be.blueera.ai/api/search-service` |
| local | `http://localhost:3000` |

No auth header required — the endpoint is public.

### Examples

```
# posts + videos
{BASE}/search/content?q=bike%20ride%20dehradun

# videos only
{BASE}/search/content?q=bike%20ride&type=video

# posts only, page 2, 10 per page
{BASE}/search/content?q=bike%20ride&type=post&page=2&limit=10
```

### Query parameters

| param | required | default | notes |
| --- | --- | --- | --- |
| `q` | **yes** | — | URL-encoded search text. Blank / whitespace-only → `400`. |
| `type` | no | both | `post` or `video` **only**. Any other value → `400`. Omit for both. |
| `page` | no | `1` | 1-based. Values `< 1` are clamped to `1`. |
| `limit` | no | `20` | Max `50`; anything higher is silently clamped. |

**Omitting `type` returns posts + videos — never other entity types.** The scope
is fixed server-side; there is no query parameter that widens this endpoint to
the catalogue. Compare:

| request | returns |
| --- | --- |
| `/search` (no `type`) | everything — products, food, hospitals, posts, videos… |
| `/search/content` (no `type`) | posts + videos |
| `/search/content?type=video` | videos |
| `/search/content?type=product` | `400` |

`q` accepts natural language. Constraints like `under 15k`, `between 40k and 60k`,
`red`, `near me` are parsed out of the text and echoed back under `parsed.filters`
— useful for showing "filters we applied", but you can ignore it entirely.

---

## Response

```json
{
  "success": true,
  "query": "bike ride dehradun",
  "parsed": {
    "residualText": "bike ride dehradun",
    "filters": {}
  },
  "types": ["post", "video"],
  "total": 37,
  "page": 1,
  "limit": 20,
  "facets": { "video": 22, "post": 15 },
  "results": [
    {
      "_id": "68f1a2c4e91b4d3a7c0f2211",
      "entityType": "video",
      "sourceId": "68f0b1aa39c7e2f10d4b8890",
      "sourceService": "video",
      "title": "Morning ride",
      "subtitle": "RideOn · 3:07",
      "imageUrl": "https://cdn.blueera.ai/videos/thumb/abc.jpg",
      "deepLink": "blueera://video/68f0b1aa39c7e2f10d4b8890",
      "brand": "Rahul",
      "category": "Travel",
      "tags": ["bike", "ride", "dehradun"],
      "popularity": 332,
      "price": null,
      "currency": "INR",
      "_score": 0.0312
    },
    {
      "_id": "68e77b10c2a91f4402ad6633",
      "entityType": "post",
      "sourceId": "68e77a01c2a91f4402ad55aa",
      "sourceService": "userfeed",
      "title": "Sunday ride to Mussoorie",
      "subtitle": "Rahul Kumar · Travel & Leisure",
      "imageUrl": "https://cdn.blueera.ai/posts/xyz.jpg",
      "deepLink": "blueera://post/68e77a01c2a91f4402ad55aa",
      "brand": "Rahul Kumar",
      "category": "Travel & Leisure",
      "tags": ["bikelife"],
      "popularity": 74,
      "price": null,
      "currency": "INR",
      "_score": 0.0287
    }
  ]
}
```

### Top-level fields

| field | notes |
| --- | --- |
| `success` | Always check this first. `false` ⇒ read `message`. |
| `types` | The scope actually applied, e.g. `["post","video"]`. On global `/search` with no `type` this is `null`. |
| `facets` | Counts **per type across the whole ranked pool**, not just the current page. Use for "Posts (15) / Videos (22)" tabs. |
| `total` | Size of the ranked candidate pool — **not** a global match count. See [Pagination](#pagination). |
| `page`, `limit` | Echoed back as applied (after clamping). |
| `results` | Ranked, best first. |
| `cached` | Present and `true` on a cache hit (60s TTL). Ignore. |
| `parsed` | What the NL parser extracted. Optional to use. |

### Result fields

| field | notes |
| --- | --- |
| `entityType` | `"post"` or `"video"` — switch your card renderer on this. |
| `sourceId` | The id in the origin service (userfeed post id / video id). Use this to build your own route. |
| `deepLink` | Ready-made: `blueera://post/<id>` or `blueera://video/<id>`. |
| `title` | Display title. Posts fall back to the poll question or a body snippet; videos to the subheading or a description snippet. Never empty. |
| `subtitle` | **Pre-formatted for display.** Videos: `"<channel or creator> · <duration>"`. Posts: `"<author> · <nature of post>"`. |
| `imageUrl` | Thumbnail. May be `""` — render a placeholder. |
| `brand` | Creator / author name. Despite the name, this is *who made it*. |
| `category` | Video category, or the post's "nature of post". May be `""`. |
| `tags` | Lowercased. Videos: tags + keywords merged. Posts: hashtags from the body. |
| `popularity` | Engagement score (likes/comments/shares/views weighted). Only a ranking tiebreak — don't display it as a count. |
| `price`, `currency` | **Meaningless here.** Content always has `price: null`. They exist only because the index is shared with the product catalogue. Ignore both. |
| `_score`, `_lexScore`, `_vecScore` | Internal ranking values. **Ignore any `_`-prefixed field** — not part of the contract, may change. |

`_id` is the search-index row id, not the content id. Use `sourceId` (or
`deepLink`) for navigation.

---

## Pagination

`total` is **not** a global match count. The engine fuses a bounded candidate
pool per request (~100 max), so `total` caps out around there and grows slightly
with `page`.

Do:

- paginate by requesting the next page until `results.length < limit`, then stop;
- stop infinite scroll at roughly `page * limit ≈ 100` — there is nothing useful past it.

Don't:

- render `total` as "37 results found";
- compute `totalPages = total / limit`.

---

## Errors

Every error response has `success: false` and a human-readable `message`.

| status | body | cause |
| --- | --- | --- |
| `400` | `{ "success": false, "message": "q is required" }` | `q` missing, empty, or whitespace only. |
| `400` | `{ "success": false, "message": "type must be one of: post, video" }` | `type` was something else (e.g. `product`, `reel`). |
| `500` | `{ "success": false, "message": "search failed" }` | Server-side failure. Safe to retry once. |

A search that simply matches nothing is **not** an error — it returns `200` with
`results: []` and `total: 0`.

---

## Client examples

### TypeScript / fetch

```ts
type ContentType = "post" | "video";

interface ContentResult {
  _id: string;
  entityType: ContentType;
  sourceId: string;
  sourceService: string;
  title: string;
  subtitle: string;
  imageUrl: string;
  deepLink: string;
  brand: string;
  category: string;
  tags: string[];
  popularity: number;
}

interface ContentSearchResponse {
  success: boolean;
  message?: string;
  types: ContentType[] | null;
  total: number;
  page: number;
  limit: number;
  facets: Partial<Record<ContentType, number>>;
  results: ContentResult[];
}

const BASE = "https://be.blueera.ai/api/search-service";

export async function searchContent(
  q: string,
  { type, page = 1, limit = 20 }: { type?: ContentType; page?: number; limit?: number } = {}
): Promise<ContentSearchResponse> {
  const params = new URLSearchParams({ q, page: String(page), limit: String(limit) });
  if (type) params.set("type", type);

  const res = await fetch(`${BASE}/search/content?${params}`);
  const json = (await res.json()) as ContentSearchResponse;
  if (!json.success) throw new Error(json.message || "search failed");
  return json;
}
```

Infinite scroll:

```ts
let page = 1;
const items: ContentResult[] = [];
const LIMIT = 20;

async function loadMore(q: string) {
  const { results } = await searchContent(q, { page, limit: LIMIT });
  items.push(...results);
  page += 1;
  return results.length === LIMIT && items.length < 100; // hasMore
}
```

### Dart / Flutter

```dart
const base = 'https://be.blueera.ai/api/search-service';

Future<Map<String, dynamic>> searchContent(
  String q, {
  String? type,          // 'post' | 'video'
  int page = 1,
  int limit = 20,
}) async {
  final uri = Uri.parse('$base/search/content').replace(queryParameters: {
    'q': q,
    'page': '$page',
    'limit': '$limit',
    if (type != null) 'type': type,
  });

  final res = await http.get(uri);
  final body = jsonDecode(res.body) as Map<String, dynamic>;
  if (body['success'] != true) {
    throw Exception(body['message'] ?? 'search failed');
  }
  return body;
}
```

Rendering:

```dart
for (final r in body['results'] as List) {
  final isVideo = r['entityType'] == 'video';
  // title / subtitle are display-ready; navigate with r['deepLink'] or r['sourceId']
}
```

---

## Notes

- **Debounce** typing by ~250–300ms before firing a request. Identical queries are
  Redis-cached for 60s server-side, so repeats are cheap, but don't fire per keystroke.
- **Type-ahead** should use `/suggest?q=<prefix>` instead — it's the fast
  autocomplete path (no semantic stage). Note it is **not** scoped to content and
  will return catalogue suggestions too; filter client-side on `entityType` if
  you need content-only suggestions.
- **Freshness**: new posts and videos are searchable within seconds of being
  created (live change-stream sync). Semantic/vector recall for a brand-new item
  lags until the next embedding pass; lexical and autocomplete matching is
  immediate.
- **Videos** only appear once they are `published`/`approved_published` **and**
  `public`. Drafts, private, unlisted, rejected and processing videos are never
  returned, and a video that is unpublished or made private disappears from
  search automatically.
- Full API reference (all endpoints, live schemas): `{BASE}/api-docs`.
