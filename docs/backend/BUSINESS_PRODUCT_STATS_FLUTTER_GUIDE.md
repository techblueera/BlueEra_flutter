# Business Product Stats — Flutter Integration Guide

Per-owner **product count** and **level 0 (root) category count**, batched.
One request shape, one response shape, three services.

---

## 1. The three endpoints

All three take the **same request body** and return the **same response shape**, so a single
Dart client covers all of them.

| Service | Method + path | Counts |
|---|---|---|
| `be_grocery_service` | `POST /api/inventory/business-product-stats` | grocery products |
| `be_food_service` | `POST /api/kitchen-inventory/business-product-stats` | food products |
| `be_product_service_v2` | `POST /api/inventory/business-product-stats` | catalogue products |

Headers on all three:

```
Content-Type: application/json
Authorization: Bearer <token>
```

> Grocery and Product v2 share the **identical path** and differ only by host. Swapping the two
> base URLs in a `.env` silently returns the wrong catalogue's numbers — no error, just wrong
> data. Double-check the mapping.

---

## 2. Request → Response

### Send

One object per owner. Send both ids whenever you have them.

```json
{
  "businesses": [
    { "businessId": "69c3eba84521749855e5d215", "userId": "664f1a2b3c4d5e6f7a8b9c0d" },
    { "businessId": "664f1a2b3c4d5e6f7a8b9c0e" },
    { "userId": "664f1a2b3c4d5e6f7a8b9c0f" }
  ]
}
```

* At least one of `businessId` / `userId` is required per entry.
* Max **100** entries per request.
* A legacy flat form `{ "businessIds": ["...", "..."] }` is still accepted (one entry per id,
  no `userId`) — prefer the paired form above.

### Receive

Exactly one row per request entry, **in the same order**. Always `200` with a full row set —
owners with nothing are returned as zeros, never omitted.

```json
{
  "data": [
    {
      "businessId": "69c3eba84521749855e5d215",
      "userId": "664f1a2b3c4d5e6f7a8b9c0d",
      "matchedIds": ["664f1a2b3c4d5e6f7a8b9c0d"],
      "productCount": 42,
      "categoryCount": 5
    },
    {
      "businessId": "664f1a2b3c4d5e6f7a8b9c0e",
      "userId": null,
      "matchedIds": [],
      "productCount": 0,
      "categoryCount": 0
    }
  ]
}
```

| Field | Meaning |
|---|---|
| `businessId` / `userId` | echoed back from the request (`null` if not sent) |
| `matchedIds` | which of the supplied ids inventory was actually filed under; empty = nothing in this catalogue |
| `productCount` | distinct **products** — not variants, not inventory rows |
| `categoryCount` | distinct **level 0 (root)** categories those products span |

### Why both ids

Inventory is stored under a **businessId** for some records and a **userId** for others. Send
both and the endpoint matches either, de-duplicating across them: a product stocked under both
ids counts **once**, never twice. `matchedIds` reports which id actually resolved.

### Errors

Always `{ "message": "..." }`.

| Status | Cause |
|---|---|
| 400 | `businesses` missing/empty, an entry with neither id, invalid ObjectId, more than 100 entries |
| 401 | missing or invalid bearer token |
| 500 | server error (also carries an `error` field) |

---

## 3. Models

```dart
// lib/api/business_product_stats.dart

/// One owner to look up. At least one of the two ids must be non-null.
class OwnerRef {
  final String? businessId;
  final String? userId;

  const OwnerRef({this.businessId, this.userId})
      : assert(businessId != null || userId != null,
            'OwnerRef needs at least one of businessId / userId');

  Map<String, dynamic> toJson() => {
        if (businessId != null) 'businessId': businessId,
        if (userId != null) 'userId': userId,
      };
}

class BusinessProductStats {
  final String? businessId;
  final String? userId;

  /// Which of the supplied ids inventory was actually found under.
  /// Empty means this owner has nothing in this service's catalogue.
  final List<String> matchedIds;

  /// Distinct products — NOT variants, NOT inventory rows.
  final int productCount;

  /// Distinct level 0 (root) categories those products span.
  final int categoryCount;

  const BusinessProductStats({
    this.businessId,
    this.userId,
    required this.matchedIds,
    required this.productCount,
    required this.categoryCount,
  });

  bool get hasInventory => matchedIds.isNotEmpty;

  /// The id the backend actually resolved — cache it and send only that one next time.
  String? get resolvedId => matchedIds.isEmpty ? null : matchedIds.first;

  factory BusinessProductStats.fromJson(Map<String, dynamic> json) =>
      BusinessProductStats(
        businessId: json['businessId'] as String?,
        userId: json['userId'] as String?,
        matchedIds:
            (json['matchedIds'] as List?)?.map((e) => e as String).toList() ??
                const [],
        productCount: (json['productCount'] as num?)?.toInt() ?? 0,
        categoryCount: (json['categoryCount'] as num?)?.toInt() ?? 0,
      );

  static const empty =
      BusinessProductStats(matchedIds: [], productCount: 0, categoryCount: 0);
}

class BusinessStatsException implements Exception {
  final int? statusCode;
  final String message;
  const BusinessStatsException(this.statusCode, this.message);

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'BusinessStatsException($statusCode): $message';
}
```

---

## 4. The API client

Chunks the 100-per-request cap transparently, so callers never think about it.

```dart
// lib/api/business_product_stats_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'business_product_stats.dart';

enum CatalogService { grocery, food, product }

extension CatalogServicePath on CatalogService {
  String get path => switch (this) {
        CatalogService.grocery => '/api/inventory/business-product-stats',
        CatalogService.food => '/api/kitchen-inventory/business-product-stats',
        CatalogService.product => '/api/inventory/business-product-stats',
      };
}

class BusinessProductStatsApi {
  static const _maxPerRequest = 100; // server rejects >100 entries with a 400

  final http.Client _client;
  final Map<CatalogService, String> baseUrls;
  final Future<String?> Function() tokenProvider;
  final Duration timeout;

  BusinessProductStatsApi({
    required this.baseUrls,
    required this.tokenProvider,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  /// Returns one row per owner, in the same order as [owners].
  Future<List<BusinessProductStats>> fetch(
    CatalogService service,
    List<OwnerRef> owners,
  ) async {
    if (owners.isEmpty) return const [];

    final base = baseUrls[service];
    if (base == null) {
      throw StateError('No base URL configured for $service');
    }
    final uri = Uri.parse('$base${service.path}');
    final token = await tokenProvider();

    final results = <BusinessProductStats>[];
    for (var i = 0; i < owners.length; i += _maxPerRequest) {
      final chunk = owners.skip(i).take(_maxPerRequest).toList();
      results.addAll(await _post(uri, token, chunk));
    }
    return results;
  }

  Future<List<BusinessProductStats>> _post(
      Uri uri, String? token, List<OwnerRef> chunk) async {
    late final http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(
                {'businesses': chunk.map((o) => o.toJson()).toList()}),
          )
          .timeout(timeout);
    } catch (e) {
      throw BusinessStatsException(null, 'Network error: $e');
    }

    final decoded = res.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode != 200) {
      throw BusinessStatsException(
        res.statusCode,
        decoded['message'] as String? ?? 'Request failed (${res.statusCode})',
      );
    }

    return (decoded['data'] as List? ?? [])
        .map((e) => BusinessProductStats.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() => _client.close();
}
```

Wire it up once (DI / provider / singleton):

```dart
final statsApi = BusinessProductStatsApi(
  baseUrls: const {
    CatalogService.grocery: 'https://grocery.yourdomain.com',
    CatalogService.food: 'https://food.yourdomain.com',
    CatalogService.product: 'https://product.yourdomain.com',
  },
  tokenProvider: () async => await secureStorage.read(key: 'access_token'),
);
```

> Using **dio** instead? Swap `_post` for a `dio.post(...)` call and read the message off
> `DioException.response?.data['message']`. Nothing else changes.

---

## 5. Calling it

### Single service, single owner

```dart
final rows = await statsApi.fetch(CatalogService.grocery, [
  OwnerRef(businessId: business.id, userId: business.ownerUserId),
]);
final stats = rows.first;
print('${stats.productCount} products in ${stats.categoryCount} categories');
```

### All three services at once

They're independent services — fire them in parallel.

```dart
class CombinedStats {
  final BusinessProductStats grocery, food, product;
  const CombinedStats(this.grocery, this.food, this.product);

  int get totalProducts =>
      grocery.productCount + food.productCount + product.productCount;
}

Future<CombinedStats> fetchAll(OwnerRef owner) async {
  final results = await Future.wait([
    statsApi.fetch(CatalogService.grocery, [owner]),
    statsApi.fetch(CatalogService.food, [owner]),
    statsApi.fetch(CatalogService.product, [owner]),
  ]);
  return CombinedStats(
    results[0].firstOrNull ?? BusinessProductStats.empty,
    results[1].firstOrNull ?? BusinessProductStats.empty,
    results[2].firstOrNull ?? BusinessProductStats.empty,
  );
}
```

To show partial results when one service is down, wrap each future individually:

```dart
Future<BusinessProductStats> _safe(CatalogService s, OwnerRef o) => statsApi
    .fetch(s, [o])
    .then((r) => r.firstOrNull ?? BusinessProductStats.empty)
    .catchError((_) => BusinessProductStats.empty);
```

### In a widget

```dart
class StatsRow extends StatefulWidget {
  const StatsRow({super.key, required this.owner});
  final OwnerRef owner;

  @override
  State<StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<StatsRow> {
  late Future<CombinedStats> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchAll(widget.owner); // build the future ONCE, never in build()
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CombinedStats>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            final e = snap.error;
            return Text(e is BusinessStatsException
                ? e.message
                : 'Something went wrong');
          }
          final s = snap.data!;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _tile('Grocery', s.grocery),
              _tile('Food', s.food),
              _tile('Products', s.product),
            ],
          );
        },
      );

  Widget _tile(String label, BusinessProductStats s) => Column(
        children: [
          Text(label),
          Text('${s.productCount}', style: const TextStyle(fontSize: 24)),
          Text('${s.categoryCount} categories'),
        ],
      );
}
```

### List screens — batch, don't loop

For a store directory or admin table, collect the visible page's owners and make **one** call.
Never one call per row.

```dart
final rows = await statsApi.fetch(
  CatalogService.grocery,
  businesses.map((b) => OwnerRef(businessId: b.id, userId: b.userId)).toList(),
);

// Response order matches request order, so a positional zip is safe:
final byBusiness = {
  for (var i = 0; i < businesses.length; i++) businesses[i].id: rows[i]
};
```

---

## 6. Gotchas

* **Send both ids.** Inventory lives under a businessId for some records and a userId for
  others. Sending both is the whole point — it matches either and de-duplicates. Sending only
  one risks a false `0`.
* **Rows are never omitted.** An owner with nothing comes back as
  `productCount: 0, categoryCount: 0, matchedIds: []`. Check `hasInventory`, don't look for a
  missing key.
* **Order is guaranteed**, so positional zipping works. Prefer key-based lookup? Key on
  `businessId ?? userId` from the echoed fields.
* **`productCount` is distinct products** — not variants, not listings. A product sold in 3
  sizes across 2 pincodes counts as **1**. Label the UI accordingly.
* **`categoryCount` is level 0 roots only.** A store with items in `Grocery & Cooking > Dals`
  and `Grocery & Cooking > Atta` shows `1`, not `2`.
* **Cache `matchedIds`.** Once you know which id resolved, send just that one next time —
  smaller payload, less server work.
* **Chunking is automatic** above 100 owners, but each chunk is a round trip. Don't hand it
  5,000 owners on a scroll event; debounce and request only what's visible.
* **Counts are point-in-time**, not live. Refresh on pull-to-refresh or screen focus rather
  than polling.
* **401 handling is identical across all three** — route it through your existing token-refresh
  interceptor.

---

## 7. Quick cURL check

Useful for confirming base URLs and tokens before wiring up Dart.

```bash
curl -X POST https://grocery.yourdomain.com/api/inventory/business-product-stats \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"businesses":[{"businessId":"69c3eba84521749855e5d215","userId":"664f1a2b3c4d5e6f7a8b9c0d"}]}'
```

Swap the host and path for the other two services:

```
https://food.yourdomain.com/api/kitchen-inventory/business-product-stats
https://product.yourdomain.com/api/inventory/business-product-stats
```
