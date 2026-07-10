# Recent Shops — Flutter Integration Guide

Integration guide for the **`GET /api/orders/recent-shops`** endpoint, which exists in
three services with an (almost) identical contract:

| Vertical | Service | Business enrichment |
|---|---|---|
| Grocery | `be_grocery_service` | `getBusinessByUserId` |
| Product | `be_product_service_v2` | `getBusinessByUserId` |
| Food | `be_food_service` | `getBusinessById` → `getBusinessByUserId` fallback |

The endpoint scans the authenticated user's recent orders, groups the ordered products
**store-wise** (by seller), aggregates the quantity per product/variant, and returns each
shop with its business profile — ready to power a **"Recent shops / Order again"** section.

---

## 1. Endpoint, auth & query params

**Method / path (same on every service):**

```
GET /api/orders/recent-shops
Authorization: Bearer <JWT>
```

**Gateway base URLs.** The app talks to services through the API gateway. The reference
is the rider call you already use — `https://be.beapp.in/api/rider-service/fare/orders` —
so each service follows `https://be.beapp.in/api/<service-slug>/<internal-path>`. Confirm
the exact slug per service with your gateway config; the internal path is always
`/api/orders/recent-shops`.

| Vertical | Full URL (verify the slug) |
|---|---|
| Grocery | `https://be.beapp.in/api/grocery-service/api/orders/recent-shops` |
| Product | `https://be.beapp.in/api/product-service-v2/api/orders/recent-shops` |
| Food | `https://be.beapp.in/api/food-service/api/orders/recent-shops` |

**Query params (all optional):**

| Param | Type | Default | Meaning |
|---|---|---|---|
| `limit` | int | `10` | Max shops to return. |
| `orderScan` | int | `50` (capped 200) | How many of the user's most recent orders to compile from. |
| `status` | csv string | excludes `cancelled,expired` | Filter orders by `orderStatus`. |
| `deliveryType` | `self-pickup` \| `rider` | — | Only compile orders of this fulfilment type. |

---

## 2. Response shape

```jsonc
{
  "success": true,
  "data": {
    "count": 2,
    "ordersScanned": 14,
    "filters": { "status": "exclude:cancelled,expired", "deliveryType": null, "limit": 10, "orderScan": 50 },
    "shops": [
      {
        "businessId": "6a086443a38e8cd3861ac4b6",
        "business": {                       // may be null if the profile can't be resolved
          "businessId": "…",
          "businessName": "Fresh Mart",
          "logo": "https://…",
          "address": "…",
          "cityStatePincode": "Lucknow, UP, 226002",
          "location": { "lat": 26.81, "lon": 80.97 },   // may be null
          "contactNumber": "8980…",         // null on Food (field reserved)
          "isVerified": true,
          "avgRating": 4.3
        },
        "orderCount": 3,
        "distinctProducts": 2,
        "totalItems": 9,
        "lastOrderedAt": "2026-07-10T10:00:00.000Z",
        "items": [ /* see below */ ]
      }
    ]
  }
}
```

### `items[]` — the one place the verticals differ

**Grocery & Product** items:

```jsonc
{
  "productVariantId": "…",
  "inventoryId": "…",          // may be null
  "productName": "Milk",
  "brand": "Amul",             // grocery/product only
  "variantName": "500 ml",
  "unit": "ml",                // grocery/product only
  "images": [ { "url": "https://…", "altText": "…" } ],
  "mrp": 30, "sellingPrice": 27,
  "quantity": 3,               // aggregated across the scanned orders
  "timesOrdered": 2,
  "lastOrderedAt": "2026-07-10T10:00:00.000Z"
}
```

**Food** items (no `brand`/`unit`; has `quantityLabel`; images are plain URL strings):

```jsonc
{
  "productVariantId": "…",
  "inventoryId": "…",
  "productName": "Chicken Biryani",
  "variantName": "Full",
  "quantityLabel": "1 plate",  // food only
  "images": [ "https://…" ],
  "mrp": 260, "sellingPrice": 240,
  "quantity": 3, "timesOrdered": 2,
  "lastOrderedAt": "2026-07-10T10:00:00.000Z"
}
```

> **Two things to handle defensively in Dart:** `images` may be a list of **objects
> `{url, altText}`** (grocery/product) or **plain strings** (food); and `brand`/`unit`
> (grocery/product) vs `quantityLabel` (food) are mutually exclusive. The models below
> normalise both.

---

## 3. Dart models

```dart
// recent_shops_models.dart
import 'package:flutter/foundation.dart';

enum GroceryVertical { grocery, product, food }

extension GroceryVerticalX on GroceryVertical {
  /// TODO: confirm each gateway slug (mirrors `.../api/rider-service/...`).
  String get recentShopsUrl {
    const host = 'https://be.beapp.in/api';
    switch (this) {
      case GroceryVertical.grocery:
        return '$host/grocery-service/api/orders/recent-shops';
      case GroceryVertical.product:
        return '$host/product-service-v2/api/orders/recent-shops';
      case GroceryVertical.food:
        return '$host/food-service/api/orders/recent-shops';
    }
  }

  /// Re-order (create order) target on the same service.
  String get createOrderUrl =>
      recentShopsUrl.replaceFirst('/orders/recent-shops', '/orders');

  String get label => switch (this) {
        GroceryVertical.grocery => 'Grocery',
        GroceryVertical.product => 'Shop',
        GroceryVertical.food => 'Food',
      };
}

DateTime? _parseDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

double? _toDouble(dynamic v) =>
    v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));

/// Images come as `["url", ...]` (food) OR `[{url, altText}, ...]` (grocery/product).
List<String> _parseImages(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map<String>((e) {
        if (e is String) return e;
        if (e is Map && e['url'] != null) return e['url'].toString();
        return '';
      })
      .where((s) => s.isNotEmpty)
      .toList();
}

class RecentShopsResponse {
  final int count;
  final int ordersScanned;
  final List<RecentShop> shops;

  const RecentShopsResponse({
    required this.count,
    required this.ordersScanned,
    required this.shops,
  });

  factory RecentShopsResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    return RecentShopsResponse(
      count: (data['count'] as num?)?.toInt() ?? 0,
      ordersScanned: (data['ordersScanned'] as num?)?.toInt() ?? 0,
      shops: ((data['shops'] as List?) ?? const [])
          .map((e) => RecentShop.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecentShop {
  final String businessId;
  final BusinessSummary? business;
  final int orderCount;
  final int distinctProducts;
  final int totalItems;
  final DateTime? lastOrderedAt;
  final List<RecentShopItem> items;

  const RecentShop({
    required this.businessId,
    required this.business,
    required this.orderCount,
    required this.distinctProducts,
    required this.totalItems,
    required this.lastOrderedAt,
    required this.items,
  });

  String get displayName => business?.businessName ?? 'Shop';

  factory RecentShop.fromJson(Map<String, dynamic> json) => RecentShop(
        businessId: json['businessId']?.toString() ?? '',
        business: json['business'] == null
            ? null
            : BusinessSummary.fromJson(json['business'] as Map<String, dynamic>),
        orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
        distinctProducts: (json['distinctProducts'] as num?)?.toInt() ?? 0,
        totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
        lastOrderedAt: _parseDate(json['lastOrderedAt']),
        items: ((json['items'] as List?) ?? const [])
            .map((e) => RecentShopItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class BusinessSummary {
  final String? businessId;
  final String? businessName;
  final String? logo;
  final String? address;
  final String? cityStatePincode;
  final double? lat;
  final double? lon;
  final String? contactNumber; // null on Food
  final bool? isVerified;
  final double? avgRating;

  const BusinessSummary({
    this.businessId,
    this.businessName,
    this.logo,
    this.address,
    this.cityStatePincode,
    this.lat,
    this.lon,
    this.contactNumber,
    this.isVerified,
    this.avgRating,
  });

  factory BusinessSummary.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>?;
    return BusinessSummary(
      businessId: json['businessId']?.toString(),
      businessName: json['businessName']?.toString(),
      logo: json['logo']?.toString(),
      address: json['address']?.toString(),
      cityStatePincode: json['cityStatePincode']?.toString(),
      lat: _toDouble(loc?['lat']),
      lon: _toDouble(loc?['lon']),
      contactNumber: json['contactNumber']?.toString(),
      isVerified: json['isVerified'] as bool?,
      avgRating: _toDouble(json['avgRating']),
    );
  }
}

class RecentShopItem {
  final String productVariantId;
  final String? inventoryId;
  final String productName;
  final String? brand;         // grocery/product
  final String variantName;
  final String? unit;          // grocery/product
  final String? quantityLabel; // food
  final List<String> images;
  final num mrp;
  final num sellingPrice;
  final int quantity;
  final int timesOrdered;
  final DateTime? lastOrderedAt;

  const RecentShopItem({
    required this.productVariantId,
    required this.inventoryId,
    required this.productName,
    required this.brand,
    required this.variantName,
    required this.unit,
    required this.quantityLabel,
    required this.images,
    required this.mrp,
    required this.sellingPrice,
    required this.quantity,
    required this.timesOrdered,
    required this.lastOrderedAt,
  });

  /// One pack-size label that works across verticals (unit or quantityLabel).
  String? get sizeLabel =>
      (quantityLabel?.isNotEmpty ?? false) ? quantityLabel : unit;

  String? get firstImage => images.isNotEmpty ? images.first : null;

  factory RecentShopItem.fromJson(Map<String, dynamic> json) => RecentShopItem(
        productVariantId: json['productVariantId']?.toString() ?? '',
        inventoryId: json['inventoryId']?.toString(),
        productName: json['productName']?.toString() ?? '',
        brand: json['brand']?.toString(),
        variantName: json['variantName']?.toString() ?? '',
        unit: json['unit']?.toString(),
        quantityLabel: json['quantityLabel']?.toString(),
        images: _parseImages(json['images']),
        mrp: (json['mrp'] as num?) ?? 0,
        sellingPrice: (json['sellingPrice'] as num?) ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        timesOrdered: (json['timesOrdered'] as num?)?.toInt() ?? 1,
        lastOrderedAt: _parseDate(json['lastOrderedAt']),
      );

  /// Line-item payload for re-ordering via `POST /api/orders`.
  Map<String, dynamic> toOrderLine({int? quantityOverride}) => {
        if (inventoryId != null) 'inventory': inventoryId,
        'productVariant': productVariantId,
        'quantity': quantityOverride ?? quantity,
        'mrp': mrp,
        'sellingPrice': sellingPrice,
      };
}
```

---

## 4. API client (Dio)

```dart
// recent_shops_api.dart
import 'package:dio/dio.dart';
import 'recent_shops_models.dart';

class RecentShopsException implements Exception {
  final String message;
  final int? statusCode;
  RecentShopsException(this.message, {this.statusCode});
  @override
  String toString() => 'RecentShopsException($statusCode): $message';
}

class RecentShopsApi {
  final Dio _dio;
  RecentShopsApi(this._dio);

  Future<RecentShopsResponse> fetch({
    required GroceryVertical vertical,
    required String token,
    int limit = 10,
    int orderScan = 50,
    List<String>? status,
    String? deliveryType,
  }) async {
    try {
      final res = await _dio.get(
        vertical.recentShopsUrl,
        queryParameters: {
          'limit': limit,
          'orderScan': orderScan,
          if (status != null && status.isNotEmpty) 'status': status.join(','),
          if (deliveryType != null) 'deliveryType': deliveryType,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          // Treat only 2xx as success; inspect others ourselves.
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (res.statusCode == 401) {
        throw RecentShopsException('Session expired. Please sign in again.',
            statusCode: 401);
      }
      final body = res.data as Map<String, dynamic>;
      if (body['success'] != true) {
        throw RecentShopsException(
          body['message']?.toString() ?? 'Could not load recent shops.',
          statusCode: res.statusCode,
        );
      }
      return RecentShopsResponse.fromJson(body);
    } on DioException catch (e) {
      throw RecentShopsException(
        e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout
            ? 'Network is slow. Please try again.'
            : 'Network error. Please check your connection.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Fetch several verticals at once (e.g. a combined "Order again" rail).
  Future<Map<GroceryVertical, RecentShopsResponse>> fetchAll({
    required List<GroceryVertical> verticals,
    required String token,
    int limit = 10,
  }) async {
    final results = await Future.wait(
      verticals.map((v) => fetch(vertical: v, token: token, limit: limit)
          .then<RecentShopsResponse?>((r) => r)
          .catchError((_) => null)), // one failing vertical shouldn't kill the rail
    );
    final map = <GroceryVertical, RecentShopsResponse>{};
    for (var i = 0; i < verticals.length; i++) {
      final r = results[i];
      if (r != null) map[verticals[i]] = r;
    }
    return map;
  }
}
```

> If you use `http` instead of `dio`: `http.get(Uri.parse(url).replace(queryParameters: {...}), headers: {'Authorization': 'Bearer $token'})`, then `jsonDecode(res.body)` and feed into `RecentShopsResponse.fromJson`.

---

## 5. Using it (FutureBuilder example)

Framework-agnostic — swap the `FutureBuilder` for a Riverpod `FutureProvider` / Bloc if
that's your stack.

```dart
class RecentShopsSection extends StatefulWidget {
  final GroceryVertical vertical;
  final RecentShopsApi api;
  final String token;
  const RecentShopsSection({
    super.key,
    required this.vertical,
    required this.api,
    required this.token,
  });

  @override
  State<RecentShopsSection> createState() => _RecentShopsSectionState();
}

class _RecentShopsSectionState extends State<RecentShopsSection> {
  late Future<RecentShopsResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetch(vertical: widget.vertical, token: widget.token);
  }

  void _reload() => setState(() {
        _future =
            widget.api.fetch(vertical: widget.vertical, token: widget.token);
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RecentShopsResponse>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 180, child: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          final msg = snap.error is RecentShopsException
              ? (snap.error as RecentShopsException).message
              : 'Something went wrong.';
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: Text(msg)),
                TextButton(onPressed: _reload, child: const Text('Retry')),
              ],
            ),
          );
        }
        final shops = snap.data?.shops ?? const [];
        if (shops.isEmpty) return const SizedBox.shrink(); // no recent shops → hide

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Order again',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            ...shops.map((shop) => ShopCard(shop: shop)),
          ],
        );
      },
    );
  }
}
```

---

## 6. Shop card widget

```dart
class ShopCard extends StatelessWidget {
  final RecentShop shop;
  const ShopCard({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    final biz = shop.business;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- shop header ----
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      (biz?.logo != null) ? NetworkImage(biz!.logo!) : null,
                  child: biz?.logo == null ? const Icon(Icons.store) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (biz?.cityStatePincode != null)
                        Text(biz!.cityStatePincode!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (biz?.avgRating != null)
                  Row(children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    Text(' ${biz!.avgRating!.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 12)),
                  ]),
              ],
            ),
            const SizedBox(height: 10),
            // ---- items you ordered here ----
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: shop.items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ReorderItemTile(item: shop.items[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReorderItemTile extends StatelessWidget {
  final RecentShopItem item;
  const ReorderItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.firstImage != null
                ? Image.network(item.firstImage!,
                    height: 64, width: 104, fit: BoxFit.cover)
                : Container(height: 64, width: 104, color: Colors.grey.shade200),
          ),
          const SizedBox(height: 4),
          Text(item.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          Text(item.sizeLabel ?? item.variantName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          Text('₹${item.sellingPrice}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
```

---

## 7. Re-order (create order) from a recent shop

Each `RecentShopItem` already carries everything `POST /api/orders` needs. Build the body
from one shop's items and post it to the **same service** (`vertical.createOrderUrl`):

```dart
Future<void> reorderShop({
  required Dio dio,
  required GroceryVertical vertical,
  required String token,
  required RecentShop shop,
  String deliveryType = 'self-pickup', // or 'rider'
}) async {
  final body = {
    'items': shop.items.map((i) => i.toOrderLine()).toList(),
    'deliveryType': deliveryType,
    'discount': 0,
  };
  final res = await dio.post(
    vertical.createOrderUrl,
    data: body,
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  // 201 → order created. Response is the saved order (see createOrder).
}
```

- `toOrderLine()` emits `{ inventory, productVariant, quantity, mrp, sellingPrice }` — the
  exact line shape `createOrder` expects (it re-validates stock and re-prices server-side).
- To re-order a **single item** instead of the whole shop, post `items: [item.toOrderLine(quantityOverride: 1)]`.
- Prices in the recent-shops payload are the **last-paid** prices; the backend recomputes
  against current inventory, so treat them as display hints, not the source of truth.

---

## 8. Checklist & edge cases

- **Auth:** send `Authorization: Bearer <JWT>` (same token as your other calls). A 401
  means re-authenticate — the client surfaces this distinctly.
- **`business` can be null** (gRPC lookup failed / circuit open). Always fall back to
  `shop.displayName` and guard `logo`/`avgRating`/`location`.
- **`inventoryId` can be null** on an item — `toOrderLine()` omits `inventory` in that case,
  which is valid (createOrder treats inventory as optional).
- **Food differences:** no `brand`/`unit` (use `quantityLabel` via `sizeLabel`); `images`
  are plain URL strings; `contactNumber` is null. The models handle all three transparently.
- **Empty state:** `shops == []` means the user has no qualifying recent orders — hide the
  section rather than showing an empty card.
- **`status` filter:** by default cancelled/expired orders are excluded. Pass
  `status: ['completed']` if you only want fulfilled purchases in "Order again".
- **Combined rail:** use `RecentShopsApi.fetchAll([grocery, product, food])` to build one
  cross-vertical "Order again" strip; a failing vertical is dropped, not fatal.

---

## 9. Quick manual test (curl)

```bash
curl -s "https://be.beapp.in/api/grocery-service/api/orders/recent-shops?limit=5" \
  -H "Authorization: Bearer <JWT>" | jq '.data.shops[] | {shop: .business.businessName, items: [.items[].productName]}'
```

Swap the base for `product-service-v2` / `food-service` to exercise the other two.
