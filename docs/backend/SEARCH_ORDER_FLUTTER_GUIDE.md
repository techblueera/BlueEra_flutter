# Search‑Order — Flutter Integration Guide

_Client integration for the grocery **Search‑Order** flow._
_Last updated: 2026‑07‑15_

Build a flow where the user starts from a **product**, sees which nearby **stores**
stock it, picks a store, and checks out through the normal order flow.

```
Search product ──▶ Search its inventory ──▶ Pick a store ──▶ Add to cart ──▶ Place order ──▶ Track
  (product API)     (NEW search-by-product)  (business-products)             (/api/orders)   (/track)
```

> **Gotcha:** `deliveryType` is `"self-pickup"` or `"rider"` (hyphen). Never
> `self_pickup`.

All calls use `Authorization: Bearer <jwt>` unless the endpoint is a `/public/` one.
Base URL example: `https://api.blueera.example/api`.

---

## 0. Tiny API client

```dart
class Api {
  Api(this.baseUrl, this.token);
  final String baseUrl;
  final String token;

  Future<dynamic> _send(String method, String path, {Map<String, dynamic>? body, Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final headers = {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final res = await switch (method) {
      'GET' => http.get(uri, headers: headers),
      'POST' => http.post(uri, headers: headers, body: jsonEncode(body ?? {})),
      'PUT' => http.put(uri, headers: headers, body: jsonEncode(body ?? {})),
      _ => throw ArgumentError(method),
    };
    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, decoded?['message'] ?? 'Request failed');
    }
    return decoded;
  }

  Future<dynamic> get(String p, {Map<String, String>? query}) => _send('GET', p, query: query);
  Future<dynamic> post(String p, {Map<String, dynamic>? body}) => _send('POST', p, body: body);
  Future<dynamic> put(String p, {Map<String, dynamic>? body}) => _send('PUT', p, body: body);
}

class ApiException implements Exception {
  ApiException(this.status, this.message);
  final int status;
  final String message;
  @override
  String toString() => 'ApiException($status): $message';
}
```

---

## 1. Step 1 — Search product

`GET /api/products/user/search` — pass **either** `pincode` **or** `lat`+`lng`+`range`.

```dart
Future<List<dynamic>> searchProducts(Api api, {
  required String searchTerm,
  String? pincode,
  double? lat,
  double? lng,
  int? rangeMeters,
  int page = 1,
  int limit = 20,
}) async {
  final query = <String, String>{
    'searchTerm': searchTerm,
    'page': '$page',
    'limit': '$limit',
    if (pincode != null) 'pincode': pincode,
    if (lat != null) 'lat': '$lat',
    if (lng != null) 'lng': '$lng',
    if (rangeMeters != null) 'range': '$rangeMeters',
  };
  final res = await api.get('/products/user/search', query: query);
  return res['data'] as List<dynamic>; // products; each variant has _id you can reuse
}
```

From a tapped result keep:
- `product['_id']` → **productId**
- `product['variants'][i]['_id']` → **productVariantId** (optional, to pin one size)

---

## 2. Step 2 — Search inventory by product / variant  **(NEW API)**

`POST /api/inventory/search-by-product` (or public `/public/search-by-product`).
Returns **stores** (grouped by business) that stock the product, filtered by location.

```dart
class StoreMatch {
  StoreMatch({
    required this.businessId,
    required this.matchingVariantCount,
    required this.minSellingPrice,
    required this.totalStock,
    required this.inventories,
  });

  final String businessId;
  final int matchingVariantCount;
  final num minSellingPrice;
  final int totalStock;
  final List<dynamic> inventories; // each has inventoryId, productVariant, product, batches...

  factory StoreMatch.fromJson(Map<String, dynamic> j) => StoreMatch(
        businessId: j['businessId'] as String,
        matchingVariantCount: (j['matchingVariantCount'] ?? 0) as int,
        minSellingPrice: (j['minSellingPrice'] ?? 0) as num,
        totalStock: (j['totalStock'] ?? 0) as int,
        inventories: (j['inventories'] ?? []) as List<dynamic>,
      );
}

Future<List<StoreMatch>> searchInventoryByProduct(Api api, {
  String? productId,          // one of productId / productVariantId is required
  String? productVariantId,
  String? pincode,
  String? cityName,
  bool? inStock,
  String sortBy = 'price_low_to_high',
  int page = 1,
  int limit = 20,
}) async {
  assert(productId != null || productVariantId != null,
      'Provide productId or productVariantId');
  final res = await api.post('/inventory/search-by-product', body: {
    if (productId != null) 'productId': productId,
    if (productVariantId != null) 'productVariantId': productVariantId,
    if (pincode != null) 'pincode': pincode,
    if (cityName != null) 'cityName': cityName,
    if (inStock != null) 'inStock': inStock,
    'sortBy': sortBy,       // price_low_to_high | price_high_to_low | discount_high_to_low | stock_high_to_low | newest
    'page': page,
    'limit': limit,
  });
  return (res['data'] as List).map((e) => StoreMatch.fromJson(e)).toList();
}
```

UI: render each `StoreMatch` as a store card ("Available at N stores near 342003"),
showing `minSellingPrice`, `totalStock`, and the store profile. Tapping a card advances
to step 3 with its `businessId`.

> **Location = pincode/cityName**, not GPS radius (grocery inventory has no coordinates).
> If the user only granted GPS, first resolve their pincode (reverse geocode or your
> existing pincode picker) and pass `pincode`.

---

## 3. Step 3 — Pick a store (get inventory by business id)

`POST /api/inventory/public/business-products` — load the tapped store's browsable
catalogue.

```dart
Future<Map<String, dynamic>> getStoreInventory(Api api, {
  required String businessId,
  String? pincode,
  String? categoryId,
  String? search,
  bool? inStock,
  String sortBy = 'newest',
  int page = 1,
  int limit = 10,
}) async {
  final res = await api.post('/inventory/public/business-products', body: {
    'businessId': businessId,           // REQUIRED
    if (pincode != null) 'pincode': pincode,
    if (categoryId != null) 'categoryId': categoryId,
    if (search != null) 'search': search,
    if (inStock != null) 'inStock': inStock,
    'sortBy': sortBy,
    'page': page,
    'limit': limit,
  });
  return res as Map<String, dynamic>; // { data: [products], pagination }
}
```

Each product in `data[]` has `variants[]`; each variant carries
`variant['inventory']['inventoryId']` — the value you attach to a cart line in step 4.

```dart
CartLine toCartLine(Map product, Map variant) {
  final inv = variant['inventory'] as Map;
  final batch = (inv['batches'] as List).isNotEmpty ? inv['batches'][0] as Map : null;
  return CartLine(
    inventoryId: inv['inventoryId'] as String,       // -> order item.inventory
    productVariantId: variant['_id'] as String,       // -> order item.productVariant
    name: product['name'] as String,
    mrp: (batch?['mrp'] ?? variant['pricing']?[0]?['mrp'] ?? 0) as num,
    sellingPrice: (batch?['sellingPrice'] ?? variant['pricing']?[0]?['sellingPrice'] ?? 0) as num,
    quantity: 1,
  );
}
```

---

## 4. Step 4 — Place the order

`POST /api/orders`. Server recomputes all totals from each line's `mrp`/`sellingPrice` —
send them accurately.

```dart
class CartLine {
  CartLine({required this.inventoryId, required this.productVariantId,
    required this.name, required this.mrp, required this.sellingPrice, required this.quantity});
  final String inventoryId, productVariantId, name;
  final num mrp, sellingPrice;
  int quantity;
}

Future<Map<String, dynamic>> placeOrder(Api api, {
  required List<CartLine> cart,
  required String deliveryType,  // 'self-pickup' | 'rider'
  num discount = 0,
}) async {
  final res = await api.post('/orders', body: {
    'items': cart.map((c) => {
      'inventory': c.inventoryId,
      'productVariant': c.productVariantId,
      'quantity': c.quantity,
      'mrp': c.mrp,
      'sellingPrice': c.sellingPrice,
    }).toList(),
    'deliveryType': deliveryType,
    'discount': discount,
  });
  return res as Map<String, dynamic>; // full order + orderNumber + contact_no (+ businessLocation for self-pickup)
}
```

The response includes `_id` (orderId), `orderNumber` (e.g. `GRO250708153012K7QP4M`),
and `orderStatus: "placed"`.

---

## 5. Step 5 — Track & progress the order

### 5.1 Unified tracking (both delivery types)
`GET /api/orders/:orderId/track` returns a `stages[]` timeline you can render directly.

```dart
Future<Map<String, dynamic>> trackOrder(Api api, String orderId) async {
  final res = await api.get('/orders/$orderId/track');
  return res['data'] as Map<String, dynamic>;
  // { currentStage, isTerminal, stages:[{key,label,done,at}], payment, pickup, rider, order }
}
```
Stage keys you may see: `placed, ready_for_pickup, rider_assigned, payment_confirmed,
picked_up, delivered, completed, cancelled, expired, rejected`. Render `stages` as a
vertical stepper using `label` + `done` + `at`; highlight `currentStage`.

### 5.2 Self‑pickup UI
- Poll `/track` (or refresh on screen focus). When `currentStage == "ready_for_pickup"`,
  show "Ready — collect at the store". The customer push already arrives via the chat
  service (`GROCERY_ORDER_READY`).
- On collection, call `PUT /api/orders/:orderId/complete`.

```dart
Future<void> completeSelfPickup(Api api, String orderId) async {
  await api.put('/orders/$orderId/complete');
}
```

### 5.3 Rider UI
For `deliveryType == "rider"`, `/track` merges the rider leg (`rider` block:
`assignedRider`, `status`, `pickedUpAt`, `deliveredAt`; `payment.toShop[]`). For **live
rider movement**, subscribe to the rider service SSE stream instead of polling:

```dart
// GET {riderBaseUrl}/riders/orders/stream/grocery/:userId  (Server-Sent Events)
final request = http.Request('GET', Uri.parse('$riderBaseUrl/riders/orders/stream/grocery/$userId'))
  ..headers['Authorization'] = 'Bearer $token'
  ..headers['Accept'] = 'text/event-stream';
final response = await request.send();
response.stream.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
  if (line.startsWith('data:')) {
    final event = jsonDecode(line.substring(5).trim());
    // event carries the populated rider (name, contact, profileImage) + distanceToPickup
  }
});
```
The rider's first known location also arrives in the `RIDE_ORDER_ACCEPTED` push
notification metadata.

### 5.4 Helpful list endpoints
- `GET /api/orders/status/me` → is there an ongoing order? (banner / resume)
- `GET /api/orders/me?orderStatus=placed,in-progress&page=1&limit=10` → order history
- `GET /api/orders/recent-shops` → store‑wise re‑order shortcuts
- `GET /api/orders/:orderId/alternatives?filter=cheapest|nearest` → cheaper/closer store
  for an existing order (needs `latitude`/`longitude` for `nearest`)

---

## 6. Screen ↔ API map

| Screen | API |
|---|---|
| Product search | `GET /products/user/search` |
| "Available at N stores" | `POST /inventory/search-by-product` **(NEW)** |
| Store page / catalogue | `POST /inventory/public/business-products` |
| Cart → checkout | `POST /orders` |
| Order tracking | `GET /orders/:id/track` (+ rider SSE for live GPS) |
| Ready / Complete (self‑pickup) | `PUT /orders/:id/ready` (shop) · `PUT /orders/:id/complete` |

---

## 7. Error handling checklist

- **400 "Either productId or productVariantId is required."** — you called
  search‑by‑product with neither id.
- **400 "A valid businessId is required…"** — store‑inventory call missing `businessId`.
- **Empty `data: []` from search‑by‑product** — nobody stocks it at that `pincode`; offer
  to retry without the pincode filter (broaden search) or show "not available near you".
- **deliveryType validation** — must be exactly `self-pickup` or `rider`.
- **Stock** — create‑order does not reject insufficient stock; treat `/track` and the
  shop's ready/availability updates as the source of truth, not the cart snapshot.
- Wrap SSE in reconnect‑with‑backoff; fall back to polling `/track` if the stream drops.
