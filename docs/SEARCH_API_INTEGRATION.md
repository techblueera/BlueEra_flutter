# Search API — Flutter integration guide

**One endpoint for every search screen in the app.** Products, groceries, shops,
videos, the user feed — all of it is `GET /search`, and a `category` query
parameter decides which vertical you get back.

```
GET {BASE}/search?q=<query>&category=<vertical>
```

| environment | BASE |
| --- | --- |
| prod | `https://be.blueera.ai/api/search-service` |
| local | `http://localhost:3000` |

No auth header required — the endpoint is public.

> **If you integrated against `/search/content`, `/search/grocery` or
> `/search/shops`:** those routes no longer exist. Replace the path with
> `/search` and move the vertical into `category` — see
> [Migration](#migration-from-the-old-scoped-endpoints) at the bottom. Everything
> else (response shape, `type`, `page`, `limit`) is unchanged.

> **Before you test a tab:** a category returns results only once its data has
> been loaded into the search index. The backend runs one backfill per vertical
> (`INDEXING_RUNBOOK.md`), and until a vertical's backfill has run, its category
> is a valid request that returns `total: 0`. An empty tab is far more likely to
> mean "not indexed yet" than "your call is wrong" — check with the backend
> before debugging the client. `GET /health` reports `indexedDocs`.

---

## 1. Pick your category

`category` is the only thing that changes between screens. Same request shape,
same response shape, every time.

### The 15 UI categories

| # | UI category | `category` | what comes back |
| --- | --- | --- | --- |
| 1 | Grocery & General Store | `grocery` | grocery products, packs, grocery shops |
| 2 | Restaurant & Food Service | `food` | dishes, portions, restaurants |
| 3 | Home Made Food | `homemade_food` | home-cooked items + the kitchens that make them |
| 4 | Book Your Stay | `stay` | hotels, home stays, hotel businesses |
| 5 | Home Made Products | `homemade_products` | home product sellers |
| 6 | Shopping & Sales | `shopping` | products, variants, retail stores |
| 7a | Rent & Properties | `rentals` | property / vehicle / equipment listings |
| 7b | Automotive Showroom & Services | `automotive` | spare parts, vehicle models, showrooms |
| 8 | Healthcare Services | `healthcare` | medicines, hospitals, departments, clinics |
| 9 | Find Services | `services` | service listings + service businesses |
| 10 | Book Home Services | `home_services` | home service providers + their services |
| 11 | Home Services | `home_services` | *(same scope as 10)* |
| 12 | Professional Consultant | `consultants` | consultant profiles |
| 13 | Financial Sectors | `finance` | finance businesses |
| 14 | Job Near Me | `jobs` | open job postings |
| 15 | Educational, Training & Sectors | `education` | institutions, courses, education businesses |

Your item 7 bundled two verticals ("Rent & Properties, Automotive Showroom &
Services"); they are separate scopes on the backend, hence 7a / 7b.

Plus the ones that already existed:

| screen / tab | `category` | what comes back |
| --- | --- | --- |
| Global search bar | *omit* (or `all`) | everything |
| Content / Explore | `content` | posts + videos |
| Video tab | `video` | videos only |
| User feed tab | `userfeed` | posts only (`post` is an accepted alias) |
| Shops / Stores tab | `shops` | every business, any vertical, never their stock |

**Categories 11 and 12 map to the same scope** — the backend does not distinguish
"Book Home Services" from "Home Services"; both are the same providers.

```dart
{BASE}/search?q=phones%20under%2015k                              // global
{BASE}/search?q=aashirvaad%20atta%20under%20300&category=grocery
{BASE}/search?q=paneer%20tikka&category=food
{BASE}/search?q=besan%20laddoo&category=homemade_food
{BASE}/search?q=hotel%20near%20clock%20tower&category=stay
{BASE}/search?q=2bhk%20rajpur%20road&category=rentals
{BASE}/search?q=brake%20pad%20swift&category=automotive
{BASE}/search?q=ac%20service&category=home_services
{BASE}/search?q=corporate%20lawyer&category=consultants
{BASE}/search?q=delivery%20job&category=jobs
{BASE}/search?q=cbse%20school%20dehradun&category=education
```

**Why a category returns more than one kind of thing.** Most verticals pair the
**catalogue** with the **businesses** that sell it, because one query means both:
"atta" should find the packet *and* the kirana store. Switch your card on
`entityType` (see [Rendering](#rendering)) and use `type` if a screen genuinely
wants only one side.

**A category cannot leak.** `category=content` will never return a product, no
matter what else you put in the query string. The scope is fixed on the server.

---

## 2. Query parameters

| param | required | default | notes |
| --- | --- | --- | --- |
| `q` | **yes** | — | URL-encoded search text. Blank / whitespace-only → `400`. |
| `category` | no | `all` | One of the 21 names in the table below. Anything else → `400`. |
| `type` | no | whole category | Narrows **within** the category. Single value or comma-separated list. Out-of-category value → `400`. |
| `page` | no | `1` | 1-based. Values `< 1` are clamped to `1`. |
| `limit` | no | `20` | Max `50`; anything higher is silently clamped. |

### `type` — optional sub-filter

Only reach for `type` when you need a slice *inside* a category — e.g. a "Shops"
chip on the grocery tab. Most screens just set `category` and ignore `type`.

| `category` | `type` may be |
| --- | --- |
| `all` | any entity type below |
| `content` | `post`, `video` |
| `video` | `video` |
| `userfeed` / `post` | `post` |
| `grocery` | `grocery_product`, `grocery_variant`, `grocery_shop` |
| `food` | `food_product`, `food_variant`, `food_business` |
| `shopping` | `product`, `variant`, `retail_business` |
| `healthcare` | `health_product`, `health_variant`, `hospital`, `hospital_department`, `healthcare_business` |
| `automotive` | `auto_part`, `vehicle`, `automotive_business` |
| `stay` | `hotel`, `home_stay`, `hotel_business` |
| `homemade_food` | `home_made_food`, `home_food_center` |
| `homemade_products` | `home_product_seller` |
| `home_services` | `home_service_provider`, `service` |
| `consultants` | `professional` |
| `services` | `service`, `service_business` |
| `rentals` | `rental` |
| `finance` | `finance_business` |
| `jobs` | `job` |
| `education` | `school`, `course`, `education_business` |
| `shops` | `grocery_shop`, `food_business`, `retail_business`, `service_business`, `healthcare_business`, `hotel_business`, `education_business`, `finance_business`, `automotive_business`, `business` |

```
# grocery tab, "Shops" chip selected
{BASE}/search?q=kirana&category=grocery&type=grocery_shop

# grocery tab, buyable packs only, under ₹300
{BASE}/search?q=atta%20under%20300&category=grocery&type=grocery_variant

# content tab, comma-separated list is fine
{BASE}/search?q=bike&category=content&type=post,video

# 400 — product is not in the grocery category
{BASE}/search?q=atta&category=grocery&type=product
```

The `400` is deliberate: it means the app sent a filter that screen can't honour,
and you should hear about it rather than get a silently different result set.

### Natural language in `q`

`q` accepts plain language. Constraints like `under 15k`, `between 40k and 60k`,
`above 2000`, `₹1,500`, `1.5 lakh`, `red`, `near me` are parsed out of the text
and echoed back under `parsed.filters` — useful for rendering "filters we
applied" chips, but you can ignore the field entirely. Typos are tolerated
(fuzzy matching, edit distance ≤ 2) and results are semantically ranked, so
"smartphone" finds documents titled "mobile".

---

## 3. Response

Identical for every category.

```json
{
  "success": true,
  "query": "aashirvaad atta under 300",
  "parsed": {
    "residualText": "aashirvaad atta",
    "filters": { "price": { "lte": 300 } }
  },
  "category": "grocery",
  "types": ["grocery_product", "grocery_variant", "grocery_shop"],
  "total": 37,
  "page": 1,
  "limit": 20,
  "facets": { "grocery_variant": 22, "grocery_product": 11, "grocery_shop": 4 },
  "cached": false,
  "results": [
    {
      "_id": "66f0a1...",
      "entityType": "grocery_variant",
      "sourceId": "6512ab...",
      "sourceService": "be_grocery_service",
      "title": "Aashirvaad Atta - 5 kg Pack",
      "subtitle": "Aashirvaad",
      "imageUrl": "https://...",
      "deepLink": "blueera://grocery/6512ab...",
      "brand": "Aashirvaad",
      "category": "Atta & Flours",
      "price": 285,
      "currency": "INR",
      "city": "Dehradun",
      "pincode": "248001",
      "_score": 0.0324
    }
  ]
}
```

### Top-level fields

| field | notes |
| --- | --- |
| `success` | `true` on `200`. |
| `query` | Your raw `q`, echoed. |
| `parsed.residualText` | The text left after constraints were pulled out. |
| `parsed.filters` | What the parser understood — `price.gte` / `price.lte`, `color`, `geo`. `{}` when nothing was parsed. |
| `category` | The scope that actually ran. Echoed so you can confirm the tab requested what it thinks it did. |
| `types` | The entity types this response was scoped to. `null` means every type (`category=all`). |
| `total` | Total fused matches, **not** the page size. Use for "N results". |
| `page`, `limit` | Echoed back. |
| `facets` | `{entityType: count}` over the whole result set — drives per-type counts on chips. |
| `cached` | `true` if served from Redis. Informational only. |
| `results` | This page's items, already ranked. |

### Result fields

| field | notes |
| --- | --- |
| `_id` | Search-index document id. **Do not** use it to fetch the entity. |
| `entityType` | Which kind of thing this is — switch your card widget on this. |
| `sourceId` | **The real id in the owning service.** Use this to fetch details / open the entity. |
| `sourceService` | Which service owns it (`be_grocery_service`, `be_video_service`, …). |
| `title`, `subtitle`, `imageUrl` | Ready to render. `subtitle` / `imageUrl` may be absent. |
| `deepLink` | `blueera://<kind>/<sourceId>` when the source provided one — may be absent, so always be able to route from `entityType` + `sourceId`. |
| `brand`, `category` | Catalogue metadata; absent for posts / videos. |
| `price`, `currency` | `price` is `null` for anything not priced (posts, videos, shops). For a `grocery_product` it is the **cheapest across its variants**. |
| `city`, `pincode` | Present for shops and location-bearing variants. |
| `_score` | Internal fused rank. Results are already sorted by it — don't re-sort. |

**Every field except `_id`, `entityType`, `sourceId`, `sourceService`, `title`
and `_score` can be missing.** Model them as nullable.

---

## 4. Errors

| status | body | when |
| --- | --- | --- |
| `400` | `{"success": false, "message": "q is required"}` | `q` missing / blank. |
| `400` | `{"success": false, "message": "category must be one of: all, content, video, userfeed, post, grocery, food, shopping, healthcare, automotive, stay, homemade_food, homemade_products, home_services, consultants, services, rentals, finance, jobs, education, shops"}` | Unknown `category`. |
| `400` | `{"success": false, "message": "type product is not valid for category=grocery. type must be one of: ..."}` | `type` outside the category. |
| `500` | `{"success": false, "message": "search failed"}` | Server-side failure. Retry once, then show a generic error. |

Both `400`s indicate a **client bug** — surface them in dev builds rather than
swallowing them into an empty state.

---

## 5. Type-ahead

Autosuggest is a separate, deliberately fast endpoint with **no** category
scoping — it suggests across everything:

```
GET {BASE}/suggest?q=iph&limit=8
```

```json
{
  "success": true,
  "suggestions": [
    {
      "entityType": "product",
      "title": "iPhone 15",
      "subtitle": "Apple",
      "sourceId": "651f...",
      "deepLink": "blueera://product/651f...",
      "imageUrl": "https://..."
    }
  ]
}
```

`limit` defaults to `8`, max `15`. Debounce ~250 ms and cancel the in-flight
request on each keystroke. When the user commits the query, call `/search` with
the tab's `category`.

---

## 6. Dart reference implementation

One client, one enum, every screen.

```dart
enum SearchCategory {
  all('all'),

  // content
  content('content'),
  video('video'),
  userfeed('userfeed'),

  // commerce
  grocery('grocery'),
  food('food'),
  shopping('shopping'),
  healthcare('healthcare'),
  automotive('automotive'),

  // stay
  stay('stay'),

  // earn-with-blueera
  homemadeFood('homemade_food'),
  homemadeProducts('homemade_products'),
  homeServices('home_services'),
  consultants('consultants'),

  // standalone verticals
  services('services'),
  rentals('rentals'),
  finance('finance'),
  jobs('jobs'),
  education('education'),

  // every business, any vertical
  shops('shops');

  const SearchCategory(this.value);
  final String value;
}

class SearchApi {
  SearchApi(this._dio, {required this.baseUrl});

  final Dio _dio;
  final String baseUrl;

  Future<SearchResponse> search(
    String query, {
    SearchCategory category = SearchCategory.all,
    List<String>? types,     // optional narrowing within the category
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final res = await _dio.get(
      '$baseUrl/search',
      queryParameters: {
        'q': query,
        // omit for `all` — the server default; sending it is also fine
        if (category != SearchCategory.all) 'category': category.value,
        if (types != null && types.isNotEmpty) 'type': types.join(','),
        'page': page,
        'limit': limit,
      },
      cancelToken: cancelToken,
    );
    return SearchResponse.fromJson(res.data as Map<String, dynamic>);
  }
}

class SearchResponse {
  SearchResponse({
    required this.total,
    required this.page,
    required this.limit,
    required this.facets,
    required this.results,
    this.category,
    this.types,
  });

  final int total;
  final int page;
  final int limit;
  final String? category;
  final List<String>? types;          // null when category = all
  final Map<String, int> facets;      // entityType -> count
  final List<SearchResult> results;

  factory SearchResponse.fromJson(Map<String, dynamic> j) => SearchResponse(
        total: j['total'] as int? ?? 0,
        page: j['page'] as int? ?? 1,
        limit: j['limit'] as int? ?? 20,
        category: j['category'] as String?,
        types: (j['types'] as List?)?.cast<String>(),
        facets: Map<String, int>.from(j['facets'] as Map? ?? const {}),
        results: (j['results'] as List? ?? const [])
            .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SearchResult {
  SearchResult({
    required this.id,
    required this.entityType,
    required this.sourceId,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.deepLink,
    this.brand,
    this.category,
    this.price,
    this.currency,
    this.city,
    this.pincode,
  });

  final String id;
  final String entityType;
  final String sourceId;   // use THIS to open the entity, never `id`
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? deepLink;
  final String? brand;
  final String? category;
  final num? price;        // null for posts, videos, shops
  final String? currency;
  final String? city;
  final String? pincode;

  factory SearchResult.fromJson(Map<String, dynamic> j) => SearchResult(
        id: j['_id'] as String,
        entityType: j['entityType'] as String,
        sourceId: j['sourceId'] as String,
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
      );
}
```

Per-screen usage is a one-liner:

```dart
final videos    = await api.search(q, category: SearchCategory.video);
final feed      = await api.search(q, category: SearchCategory.userfeed);
final grocery   = await api.search(q, category: SearchCategory.grocery);
final stays     = await api.search(q, category: SearchCategory.stay);
final rentals   = await api.search(q, category: SearchCategory.rentals);
final jobs      = await api.search(q, category: SearchCategory.jobs);
final colleges  = await api.search(q, category: SearchCategory.education);
final everything = await api.search(q); // global search bar
```

If your tab list is already data-driven, map it once instead of branching:

```dart
const categoryByTabSlug = <String, SearchCategory>{
  'GROCERY_SECTOR':      SearchCategory.grocery,
  'FOOD_SECTOR':         SearchCategory.food,
  'HOME_MADE_FOOD':      SearchCategory.homemadeFood,
  'HOTEL_STAY':          SearchCategory.stay,
  'HOME_MADE_PRODUCTS':  SearchCategory.homemadeProducts,
  'SHOPPING_SECTOR':     SearchCategory.shopping,
  'RENT_PROPERTY':       SearchCategory.rentals,
  'AUTOMOTIVE_SERVICE':  SearchCategory.automotive,
  'HEALTH_CARE':         SearchCategory.healthcare,
  'FIND_SERVICE':        SearchCategory.services,
  'HOME_SERVICES':       SearchCategory.homeServices,
  'BOOK_HOME_SERVICES':  SearchCategory.homeServices, // same scope
  'PROFESSIONAL':        SearchCategory.consultants,
  'FINANCE_SECTOR':      SearchCategory.finance,
  'JOBS_NEAR_ME_SECTOR': SearchCategory.jobs,
  'EDUCATION_TRAINING':  SearchCategory.education,
};
```

### Rendering

Switch the card on `entityType`, not on which tab you're in — `category=grocery`
returns products, variants **and** shops in one list:

```dart
Widget cardFor(SearchResult r) {
  switch (r.entityType) {
    // content
    case 'video':                   return VideoCard(r);
    case 'post':                    return PostCard(r);

    // every business / shop, whatever the vertical
    case 'grocery_shop':
    case 'food_business':
    case 'retail_business':
    case 'service_business':
    case 'healthcare_business':
    case 'hotel_business':
    case 'education_business':
    case 'finance_business':
    case 'automotive_business':
    case 'business':                return ShopCard(r);

    // anything with a price you can buy
    case 'grocery_product':
    case 'grocery_variant':
    case 'food_product':
    case 'food_variant':
    case 'health_product':
    case 'health_variant':
    case 'product':
    case 'variant':
    case 'auto_part':
    case 'home_made_food':          return ProductCard(r);

    // places
    case 'hospital':
    case 'hospital_department':     return HospitalCard(r);
    case 'hotel':
    case 'home_stay':               return StayCard(r);
    case 'school':
    case 'course':                  return EducationCard(r);

    // people / providers
    case 'professional':
    case 'home_food_center':
    case 'home_product_seller':
    case 'home_service_provider':   return ProviderCard(r);

    // listings
    case 'rental':                  return RentalCard(r);
    case 'job':                     return JobCard(r);
    case 'service':                 return ServiceCard(r);
    case 'vehicle':                 return VehicleCard(r);

    default:                        return GenericCard(r);
  }
}
```

**Handle `default`.** New entity types are added server-side without a client
release, and an unknown type must render as a generic card rather than throw.

### What `price` means per entity type

`price` is `null` for anything not directly priced — hotels, shops, providers,
schools, vehicles. Where it is set, it is not always "the price":

| entityType | `price` is | `status` carries |
| --- | --- | --- |
| `grocery_product`, `food_product`, `health_product`, `product`, `auto_part` | cheapest variant | — |
| `*_variant` | that pack's price | — |
| `home_stay` | the charge | `chargeType` |
| `rental` | rent **per `status` unit** — never normalised | `Hour`/`Day`/`Week`/`Month`/`Year` |
| `job` | **minimum** salary | `Open` |
| `service` | lowest of range / options | `priceType` |
| `professional` | consulting rate | `Hourly`/`Project`/`Fixed` |
| `course` | yearly fee, else monthly | `yearly` / `monthly` |

For `rental` especially: render `₹18000 / Month` using `status` — a bare
`₹18000` next to a daily rental is misleading.

### Pagination

`total` is the full match count; keep requesting until you've collected it.

```dart
final hasMore = page * limit < total;
```

### Notes

- **Debounce** typing (~250–300 ms) and pass a `CancelToken` so a stale response
  can't overwrite a newer one.
- **Cache is server-side** (60 s per query+scope+page). No client caching needed
  for repeat queries.
- `facets` gives per-type counts for the whole result set — use it to label chips
  ("Shops 4", "Products 11") without extra requests.

---

## Migration from the old scoped endpoints

| was | now |
| --- | --- |
| `GET /search/content?q=X` | `GET /search?q=X&category=content` |
| `GET /search/content?q=X&type=video` | `GET /search?q=X&category=video` *(or `category=content&type=video`)* |
| `GET /search/content?q=X&type=post` | `GET /search?q=X&category=userfeed` *(or `category=content&type=post`)* |
| `GET /search/grocery?q=X` | `GET /search?q=X&category=grocery` |
| `GET /search/grocery?q=X&type=grocery_shop` | `GET /search?q=X&category=grocery&type=grocery_shop` |
| `GET /search/shops?q=X` | `GET /search?q=X&category=shops` |
| `GET /search/shops?q=X&type=business` | `GET /search?q=X&category=shops&type=business` |
| `GET /search?q=X` (global) | unchanged |
| `GET /suggest?q=X` | unchanged |

**The response shape did not change** — same `results`, same `facets`, same
fields, plus a new `category` echo. Only the URL moves. `/search/content`,
`/search/grocery` and `/search/shops` now return `404`.
