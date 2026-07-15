# be_search_service — Flutter Integration Guide

Global hybrid search (Atlas lexical + vector semantic) with natural-language
constraint parsing, typo tolerance, and type-ahead autosuggest.

- **Base URL (prod):** `https://be.beapp.in/api/search-service`
- **Content type:** `application/json`
- **Auth:** none required on these endpoints (public read). Send your standard
  gateway headers if the platform requires them.

> The platform ALB routes `/api/search-service/*` to the service and **strips**
> that prefix internally. As a client you always use the full prefixed URL
> above — you never see the stripped path.

---

## 1. Endpoints at a glance

| Route | Method | Purpose | When to call from Flutter |
|-------|--------|---------|---------------------------|
| `/search` | GET | Full hybrid search: lexical + semantic ranking, NL constraint parsing (price/color/geo), grouped results with facet counts, paginated. | When the user submits a query or scrolls for the next page. |
| `/suggest` | GET | Fast type-ahead autocomplete (prefix + fuzzy, **no** semantic stage, target < 50 ms). | On every keystroke (debounced) while the user is typing. |
| `/health` | GET | Liveness + embedder readiness + indexed doc count + uptime. | Diagnostics / startup ping only. Not on the hot path. |

**Rule of thumb:** use `/suggest` *while typing*, use `/search` *when the user
commits* (taps a suggestion, presses enter/search, or paginates).

> **Data freshness.** New/updated/deleted items in the source catalogs propagate
> into search within seconds and are immediately findable by **keyword,
> autocomplete and filters**. Their **semantic** (meaning-based) ranking can lag
> briefly — a just-created item is findable by its name right away but may not
> surface for a vaguely-worded query until the periodic embedding job runs. No
> client handling needed; just don't assume "didn't match a fuzzy query the
> instant it was created" means the item is missing.

---

## 2. `GET /search` — main search

### Query parameters

| Param | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `q` | ✅ | string | — | Raw natural-language query, e.g. `phones under 15k`. |
| `type` | ❌ | string | (all) | Scope to one entity type (see enum below). |
| `page` | ❌ | int | `1` | 1-based. Clamped to ≥ 1. |
| `limit` | ❌ | int | `20` | Max `50` (server clamps). |

**Entity types.** Pass any value below as `type` to scope a search; every result
carries one as `entityType`. An **unscoped** search is heterogeneous — a single
query can return products, food, medicines, hospitals and posts together — so
always branch your rendering on `entityType`.

| Group | `entityType` values | What to expect in the result |
|-------|---------------------|------------------------------|
| Catalog | `product`, `variant`, `service` | `price`, `brand`, `category`, `imageUrl`. `service` = a bookable service, not a physical item. |
| Grocery | `grocery_product`, `grocery_variant` | Variants also carry `city` + `pincode` (a location-scoped offer). |
| Food | `food_product`, `food_variant` | `price`/`brand` may be null; `imageUrl` present. |
| Health / pharmacy | `health_product`, `health_variant` | `brand` may be a marketer/manufacturer name; variants carry `city`/`pincode`. |
| Hospitals | `hospital`, `hospital_department` | **No `price`.** `city` set; `subtitle` is the address / city. |
| Social feed | `post` | **No `price`.** `brand` = author name, `category` = post nature, `tags` = hashtags, `imageUrl` = thumbnail. |

Reserved (defined but not yet populated — you may start seeing them later):
`grocery_shop`, `user`, `business`. Treat any unknown `entityType` gracefully.

### Natural-language constraints (parsed server-side, no LLM)

The server extracts filters from `q` and searches on the *residual* text:

| You type | Parsed filter |
|----------|---------------|
| `phones under 15k` / `below 15000` / `upto 1.5 lakh` / `< 15000` | `price.lte` |
| `laptops over 40k` / `above`, `more than`, `min 40000` / `> 40000` | `price.gte` |
| `tv between 40k and 60k` | `price.gte` + `price.lte` |
| `tv 40000-60000` (dash range) | `price.gte` + `price.lte` |
| `red shoes` | `color: "red"` |
| `salon near me` / `nearby` | `geo: true` |

Units supported: `k`/`thousand` (×1e3), `lac`/`lakh` (×1e5), `cr`/`crore` (×1e7),
plus `₹`/`rs` prefixes and comma grouping (`15,000`).

### Example request

```
GET https://be.beapp.in/api/search-service/search?q=phones%20under%2015k&page=1&limit=20
```

### Example 200 response

```json
{
  "success": true,
  "query": "phones under 15k",
  "parsed": {
    "residualText": "phones",
    "filters": { "price": { "lte": 15000 } }
  },
  "total": 42,
  "page": 1,
  "limit": 20,
  "facets": { "product": 30, "variant": 12 },
  "cached": true,
  "results": [
    {
      "_id": "665f...",
      "entityType": "product",
      "sourceId": "abc123",
      "sourceService": "product_service_v2",
      "title": "Redmi Note 13",
      "subtitle": "Xiaomi",
      "imageUrl": "https://.../redmi.jpg",
      "deepLink": "blueera://product/abc123",
      "brand": "Xiaomi",
      "category": "Mobiles",
      "price": 13999,
      "currency": "INR",
      "city": "Mumbai",
      "pincode": "400001",
      "_score": 0.0163
    }
  ]
}
```

Notes:
- `facets` = count of results per `entityType` across the **whole** result set
  (use it to render type tabs/chips with counts).
- `cached` is `true` only on a cache hit; it is **absent** on a fresh (miss) response — treat missing as `false`.
- `_score` is the fused RRF rank score (higher = better). Results are pre-sorted.
- Paginate with `page`/`limit`; `total` is the full fused count.

### Errors
- `400` → `{ "success": false, "message": "q is required" }` (empty/blank `q`).
- `500` → `{ "success": false, "message": "search failed" }`.

---

## 3. `GET /suggest` — type-ahead autocomplete

### Query parameters

| Param | Required | Type | Default | Notes |
|-------|----------|------|---------|-------|
| `q` | ✅ | string | — | Prefix the user is typing. Empty/blank → empty list (no error). |
| `limit` | ❌ | int | `8` | Max `15`. |

### Example

```
GET https://be.beapp.in/api/search-service/suggest?q=iph&limit=8
```

```json
{
  "success": true,
  "suggestions": [
    {
      "entityType": "product",
      "title": "iPhone 15",
      "subtitle": "Apple",
      "sourceId": "p_991",
      "deepLink": "blueera://product/p_991",
      "imageUrl": "https://.../iphone15.jpg"
    }
  ]
}
```

Suggestions carry no price/score — they are lightweight display rows. On tap,
either navigate via `deepLink` or run a full `/search` with the chosen `title`.

---

## 4. `GET /health`

```json
{
  "success": true,
  "service": "be_search_service",
  "embedderReady": true,
  "indexedDocs": 15234,
  "uptime": 128.4
}
```

`embedderReady: false` means the semantic model is still loading — search still
works (lexical only) but semantic ranking is degraded until it flips to `true`.

---

## 5. Flutter integration

Uses [`dio`](https://pub.dev/packages/dio). (`http` works too — swap the client.)

```yaml
# pubspec.yaml
dependencies:
  dio: ^5.4.0
```

### 5.1 Models

```dart
// lib/search/search_models.dart

class SearchResultItem {
  final String id;
  final String entityType;
  final String? sourceId;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? deepLink;
  final String? brand;
  final String? category;
  final num? price;
  final String? currency;
  final String? city;
  final String? pincode;
  final List<String> tags;
  final double? score;

  SearchResultItem({
    required this.id,
    required this.entityType,
    required this.title,
    this.sourceId,
    this.subtitle,
    this.imageUrl,
    this.deepLink,
    this.brand,
    this.category,
    this.price,
    this.currency,
    this.city,
    this.pincode,
    this.tags = const [],
    this.score,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> j) => SearchResultItem(
        id: j['_id'] as String,
        entityType: j['entityType'] as String? ?? 'unknown',
        sourceId: j['sourceId'] as String?,
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String?,
        imageUrl: j['imageUrl'] as String?,
        deepLink: j['deepLink'] as String?,
        brand: j['brand'] as String?,
        category: j['category'] as String?,
        price: j['price'] as num?,
        currency: j['currency'] as String?,
        city: j['city'] as String?,
        pincode: j['pincode'] as String?,
        tags: ((j['tags'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        score: (j['_score'] as num?)?.toDouble(),
      );
}

class SearchResponse {
  final String query;
  final int total;
  final int page;
  final int limit;
  final Map<String, int> facets; // entityType -> count
  final bool cached;
  final List<SearchResultItem> results;

  SearchResponse({
    required this.query,
    required this.total,
    required this.page,
    required this.limit,
    required this.facets,
    required this.cached,
    required this.results,
  });

  bool get hasMore => page * limit < total;

  factory SearchResponse.fromJson(Map<String, dynamic> j) => SearchResponse(
        query: j['query'] as String? ?? '',
        total: j['total'] as int? ?? 0,
        page: j['page'] as int? ?? 1,
        limit: j['limit'] as int? ?? 20,
        facets: (j['facets'] as Map?)?.map(
              (k, v) => MapEntry(k as String, v as int),
            ) ??
            {},
        cached: j['cached'] as bool? ?? false,
        results: ((j['results'] as List?) ?? [])
            .map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Suggestion {
  final String entityType;
  final String title;
  final String? subtitle;
  final String? sourceId;
  final String? deepLink;
  final String? imageUrl;

  Suggestion({
    required this.entityType,
    required this.title,
    this.subtitle,
    this.sourceId,
    this.deepLink,
    this.imageUrl,
  });

  factory Suggestion.fromJson(Map<String, dynamic> j) => Suggestion(
        entityType: j['entityType'] as String? ?? 'unknown',
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String?,
        sourceId: j['sourceId'] as String?,
        deepLink: j['deepLink'] as String?,
        imageUrl: j['imageUrl'] as String?,
      );
}
```

### 5.2 API client

```dart
// lib/search/search_api.dart
import 'package:dio/dio.dart';
import 'search_models.dart';

class SearchApi {
  final Dio _dio;

  SearchApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://be.beapp.in/api/search-service',
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 8),
              headers: {'accept': 'application/json'},
            ));

  /// Full hybrid search. [type] scopes to a single entityType (optional).
  Future<SearchResponse> search(
    String q, {
    String? type,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final res = await _dio.get('/search', queryParameters: {
      'q': q,
      if (type != null) 'type': type,
      'page': page,
      'limit': limit,
    }, cancelToken: cancelToken);
    return SearchResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// Type-ahead suggestions (call while typing, debounced).
  Future<List<Suggestion>> suggest(
    String q, {
    int limit = 8,
    CancelToken? cancelToken,
  }) async {
    if (q.trim().isEmpty) return [];
    final res = await _dio.get('/suggest', queryParameters: {
      'q': q,
      'limit': limit,
    }, cancelToken: cancelToken);
    final list = (res.data['suggestions'] as List?) ?? [];
    return list
        .map((e) => Suggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

### 5.3 Debounced suggest (avoid a call per keystroke)

```dart
import 'dart:async';
import 'package:dio/dio.dart';

class SuggestController {
  final SearchApi api;
  Timer? _debounce;
  CancelToken? _inFlight;

  SuggestController(this.api);

  void onChanged(String text, void Function(List<Suggestion>) onResult) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      _inFlight?.cancel('superseded');   // drop the previous request
      _inFlight = CancelToken();
      try {
        final s = await api.suggest(text, cancelToken: _inFlight);
        onResult(s);
      } on DioException catch (e) {
        if (!CancelToken.isCancel(e)) onResult(const []);
      }
    });
  }

  void dispose() => _debounce?.cancel();
}
```

### 5.4 Search + pagination usage

```dart
final api = SearchApi();

// initial query
var res = await api.search('phones under 15k');
render(res.results);

// build type tabs from facets, e.g. "Products (30)"
res.facets.forEach((type, count) => addTab(type, count));

// infinite scroll
if (res.hasMore) {
  final next = await api.search('phones under 15k', page: res.page + 1);
  appendResults(next.results);
}

// scope to one type when a facet tab is tapped
final products = await api.search('phones under 15k', type: 'product');
```

### 5.5 Handling results on tap

Every result comes with a fully-formed `deepLink` — prefer it for navigation and
fall back to `entityType` + `sourceId`:

```dart
void openResult(SearchResultItem item) {
  if (item.deepLink != null) {
    // e.g. blueera://product/abc123  ->  route with your deep-link handler
    navigateToDeepLink(item.deepLink!);
  } else {
    navigateByType(item.entityType, item.sourceId);
  }
}
```

**Deep-link schemes by entity type** — your deep-link router must recognise all
of these (`{id}` is the item's `sourceId`):

| `entityType` | `deepLink` pattern |
|--------------|--------------------|
| `product`, `service` | `blueera://product/{id}` |
| `variant` | `blueera://variant/{id}` |
| `grocery_product` | `blueera://grocery/product/{id}` |
| `grocery_variant` | `blueera://grocery/variant/{id}` |
| `food_product` | `blueera://food/product/{id}` |
| `food_variant` | `blueera://food/variant/{id}` |
| `health_product` | `blueera://health/product/{id}` |
| `health_variant` | `blueera://health/variant/{id}` |
| `hospital` | `blueera://hospital/{id}` |
| `hospital_department` | `blueera://hospital/department/{id}` |
| `post` | `blueera://post/{id}` |

---

## 6. Client-side best practices

1. **Debounce `/suggest`** (~250 ms) and **cancel** the in-flight request when a
   newer keystroke arrives (see 5.3) — prevents out-of-order results.
2. **Rate limit:** the `/api` gateway allows ~1000 req/min per client. Debouncing
   keeps you well under it; back off on `429`.
3. Only send `q` to `/search` — do **not** pre-parse price/color on the client;
   the server does it and returns what it parsed in `parsed.filters` (show it as
   an "applied filters" chip if you like).
4. Use `facets` to render entity-type tabs with counts; re-query with `type=` to
   drill into one.
5. `cached: true` is informational only (served from Redis) — no client action.
6. Treat `results` as already ranked; don't re-sort by `_score` unless you need to.
7. Show a graceful empty state when `total == 0` and an error toast on `500`.

---

## 7. Quick reference

| Task | Call |
|------|------|
| User is typing | `GET /suggest?q=<prefix>&limit=8` (debounced) |
| User submits / paginates | `GET /search?q=<query>&page=<n>&limit=<n>[&type=<t>]` |
| Drill into a type | add `&type=product` (etc.) |
| Health check | `GET /health` |
