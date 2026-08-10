# Medical Stock Management — Flutter Integration Guide

Stock health for a pharmacy dashboard: what's **out of stock**, **running low**, **about to
expire**, and an overall **summary** — plus a manual "mark out of stock" toggle that doesn't
delete batch data. Ported from grocery's Stock Management, adapted for the medical catalogue
(product cards carry the **Rx** flag and `product_form`).

**Base URL:** `https://be.beapp.in/api/medical-service`
**Auth:** all 5 endpoints are **BUSINESS-only** (`Authorization: Bearer <token>` + BUSINESS
role). `businessId` is taken from the token — the app **never sends it**.

---

## 1. Quick reference

| # | Method | Endpoint | Purpose |
|---|--------|----------|---------|
| 1 | PATCH | `/inventory/stock/toggle-out-of-stock` | Bulk mark items in/out of stock |
| 2 | GET | `/inventory/stock/out-of-stock` | List out-of-stock items |
| 3 | GET | `/inventory/stock/low-stock` | List items below reorder point |
| 4 | GET | `/inventory/stock/expiring-soon` | List items with batches expiring soon |
| 5 | GET | `/inventory/stock/summary` | Dashboard summary counts |

---

## 2. The `isOutOfStock` field

Every inventory record now has a boolean `isOutOfStock` (defaults `false`). When a pharmacy
toggles it `true`, the item is treated as out of stock **even if batches still have quantity**
(damaged goods, supplier issues).

It also appears inside the `inventory` sub-object of the existing product endpoints —
`POST /inventory/business-products`, `POST /inventory/public/business-products`, and
`GET /inventory/my-products`:

```jsonc
"inventory": { "inventoryId": "…", "pincode": "…", "batches": [ … ], "totalStock": 50, "isOutOfStock": false }
```

**Badge rule:** an item is effectively out of stock when `totalStock <= 0` **OR**
`isOutOfStock === true`.

```dart
bool isEffectivelyOutOfStock(dynamic inv) =>
    (inv.isOutOfStock == true) || ((inv.totalStock ?? 0) <= 0);
```

---

## 3. Endpoints

### 1. Toggle out of stock — `PATCH /inventory/stock/toggle-out-of-stock`

Bulk. Send the `inventoryId` values you already have from the product lists
(`variant.inventory.inventoryId`).

**Body:**
```json
{ "inventoryIds": ["664f…0d", "664f…0e"], "isOutOfStock": true }
```

**200:**
```json
{ "message": "Successfully updated isOutOfStock to true.", "matchedCount": 2, "modifiedCount": 2 }
```
- `matchedCount` — how many of the ids belong to this pharmacy.
- `modifiedCount` — how many actually changed (already-in-target items don't count).

**Errors:** `400` (empty/invalid ids, or `isOutOfStock` not boolean), `404` (none belong to
this pharmacy). After success, refresh the affected list + summary.

### 2. Out of stock — `GET /inventory/stock/out-of-stock`

Items where `isOutOfStock === true` **OR** `totalStock <= 0`. Sorted by `updatedAt` desc.

Query: `pincode`, `categoryId` (includes sub-categories), `search` (product name), `page`
(1), `limit` (10).

**200:**
```json
{
  "data": [
    {
      "_id": "664f…0d", "pincode": "560001", "cityName": "Bengaluru",
      "totalStock": 0, "isOutOfStock": true, "reorderPoint": 10, "batches": [ … ],
      "productVariant": { "_id": "…", "variantName": "Strip of 15", "unit": "strip", "sku": "DOLO-15", "images": [ … ] },
      "product": { "_id": "…", "name": "Dolo 650", "brand": "Micro Labs", "images": [ … ],
                   "product_form": "Tablet", "is_prescription_required": false },
      "category": { "_id": "…", "name": "Analgesics", "image": "…" },
      "updatedAt": "2026-07-24T10:30:00.000Z"
    }
  ],
  "pagination": { "total": 12, "page": 1, "limit": 10, "totalPages": 2 }
}
```
Use `isOutOfStock` to label "manually marked" vs "zero quantity". This list is where you put
a **"Mark back in stock"** button → toggle with `isOutOfStock: false`.

### 3. Low stock — `GET /inventory/stock/low-stock`

Items where `0 < totalStock <= reorderPoint`, excluding manually-out-of-stock. Same row shape
as #2, plus `reorderPoint`.

Query: `pincode`, `categoryId`, `search`, `sortBy` (`stock_low_to_high` default,
`stock_high_to_low`, `newest`, `oldest`), `page`, `limit`.

Show "Stock: 5 / Reorder at: 10". Highlight `totalStock <= 3` more urgently.

### 4. Expiring soon — `GET /inventory/stock/expiring-soon`

Items with at least one batch expiring within `days` (default 30). Sorted by
`nearestExpiryDate` asc. Two extra fields per row:

```jsonc
{
  "nearestExpiryDate": "2026-07-28T00:00:00.000Z",
  "expiringBatches": [ { "batchNumber": "B1", "quantity": 15, "expiryDate": "2026-07-28T…", "mrp": 120, "sellingPrice": 99 } ],
  "batches": [ … ],   // ALL batches, for reference
  "totalStock": 100, "productVariant": { … }, "product": { … }, "category": { … }
}
```
Query: `days`, `pincode`, `categoryId`, `search`, `page`, `limit`. A "7 / 14 / 30 days"
quick-filter changes `days`. Colour by `daysUntilExpiry(nearestExpiryDate)`: ≤7 red, ≤14
orange, ≤30 yellow.

### 5. Summary — `GET /inventory/stock/summary`

Query: `pincode` (optional).

```json
{
  "totalItems": 150, "outOfStockCount": 12, "lowStockCount": 25, "inStockCount": 138,
  "expiringSoonCount": 8, "totalStockValue": 245000.50, "totalUnits": 5200
}
```
- `outOfStockCount + inStockCount = totalItems` (mutually exclusive).
- `lowStockCount` is a subset of `inStockCount`.
- `totalStockValue` = Σ(batch qty × sellingPrice) in ₹; `totalUnits` = Σ batch quantities.
- Make each count a clickable card → its list endpoint.

---

## 4. Models

```dart
// lib/api/medical_stock.dart

class StockSummary {
  final int totalItems, outOfStockCount, lowStockCount, inStockCount, expiringSoonCount, totalUnits;
  final double totalStockValue;
  const StockSummary({
    required this.totalItems, required this.outOfStockCount, required this.lowStockCount,
    required this.inStockCount, required this.expiringSoonCount, required this.totalUnits,
    required this.totalStockValue,
  });
  factory StockSummary.fromJson(Map<String, dynamic> j) => StockSummary(
        totalItems: (j['totalItems'] as num?)?.toInt() ?? 0,
        outOfStockCount: (j['outOfStockCount'] as num?)?.toInt() ?? 0,
        lowStockCount: (j['lowStockCount'] as num?)?.toInt() ?? 0,
        inStockCount: (j['inStockCount'] as num?)?.toInt() ?? 0,
        expiringSoonCount: (j['expiringSoonCount'] as num?)?.toInt() ?? 0,
        totalUnits: (j['totalUnits'] as num?)?.toInt() ?? 0,
        totalStockValue: (j['totalStockValue'] as num?)?.toDouble() ?? 0,
      );
  static const empty = StockSummary(totalItems: 0, outOfStockCount: 0, lowStockCount: 0,
      inStockCount: 0, expiringSoonCount: 0, totalUnits: 0, totalStockValue: 0);
}

class StockItem {
  final String id;
  final String? pincode, cityName;
  final int totalStock, reorderPoint;
  final bool isOutOfStock;
  final String productName, variantName;
  final List<String> images;
  final bool isPrescriptionRequired;
  final String? productForm, categoryName;
  final DateTime? nearestExpiryDate;          // expiring-soon only
  final List<dynamic> expiringBatches;        // expiring-soon only
  final Map<String, dynamic> raw;

  const StockItem({
    required this.id, required this.totalStock, required this.reorderPoint,
    required this.isOutOfStock, required this.productName, required this.variantName,
    required this.images, required this.isPrescriptionRequired, required this.raw,
    this.pincode, this.cityName, this.productForm, this.categoryName,
    this.nearestExpiryDate, this.expiringBatches = const [],
  });

  bool get effectivelyOut => totalStock <= 0 || isOutOfStock;
  int? get daysToExpiry => nearestExpiryDate == null
      ? null
      : nearestExpiryDate!.difference(DateTime.now()).inDays;

  factory StockItem.fromJson(Map<String, dynamic> j) {
    final v = (j['productVariant'] as Map?) ?? const {};
    final p = (j['product'] as Map?) ?? const {};
    final imgs = ((p['images'] ?? v['images']) as List?)
            ?.map((e) => (e is Map ? e['url'] : e)?.toString())
            .whereType<String>()
            .toList() ??
        const [];
    return StockItem(
      id: j['_id'] as String,
      pincode: j['pincode'] as String?,
      cityName: j['cityName'] as String?,
      totalStock: (j['totalStock'] as num?)?.toInt() ?? 0,
      reorderPoint: (j['reorderPoint'] as num?)?.toInt() ?? 0,
      isOutOfStock: j['isOutOfStock'] == true,
      productName: (p['name'] ?? '') as String,
      variantName: (v['variantName'] ?? '') as String,
      images: imgs,
      isPrescriptionRequired: p['is_prescription_required'] == true,
      productForm: p['product_form'] as String?,
      categoryName: (j['category'] as Map?)?['name'] as String?,
      nearestExpiryDate: j['nearestExpiryDate'] != null
          ? DateTime.tryParse(j['nearestExpiryDate'].toString())
          : null,
      expiringBatches: (j['expiringBatches'] as List?) ?? const [],
      raw: j,
    );
  }
}

class Paginated<T> {
  final List<T> data;
  final int total, page, limit, totalPages;
  const Paginated(this.data, this.total, this.page, this.limit, this.totalPages);
}

class StockException implements Exception {
  final int? statusCode;
  final String message;
  const StockException(this.statusCode, this.message);
  bool get isUnauthorized => statusCode == 401;
  @override
  String toString() => 'StockException($statusCode): $message';
}
```

---

## 5. API client

```dart
// lib/api/medical_stock_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'medical_stock.dart';

class MedicalStockApi {
  final http.Client _client;
  final String baseUrl; // https://be.beapp.in/api/medical-service
  final Future<String?> Function() tokenProvider;
  final Duration timeout;

  MedicalStockApi({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = await tokenProvider();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = res.body.isEmpty ? const {} : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StockException(res.statusCode, body['message']?.toString() ?? 'Request failed (${res.statusCode})');
    }
    return body;
  }

  Uri _uri(String path, [Map<String, dynamic>? q]) => Uri.parse('$baseUrl$path').replace(
        queryParameters: q?.map((k, v) => MapEntry(k, '$v'))..removeWhere((_, v) => v == 'null'),
      );

  Future<StockSummary> summary({String? pincode}) async {
    final res = await _client.get(_uri('/inventory/stock/summary', {'pincode': pincode}), headers: await _headers()).timeout(timeout);
    return StockSummary.fromJson(_decode(res));
  }

  Future<({int matched, int modified})> toggle(List<String> inventoryIds, bool outOfStock) async {
    final res = await _client
        .patch(_uri('/inventory/stock/toggle-out-of-stock'),
            headers: await _headers(),
            body: jsonEncode({'inventoryIds': inventoryIds, 'isOutOfStock': outOfStock}))
        .timeout(timeout);
    final b = _decode(res);
    return (matched: (b['matchedCount'] as num?)?.toInt() ?? 0, modified: (b['modifiedCount'] as num?)?.toInt() ?? 0);
  }

  Future<Paginated<StockItem>> _list(String path, Map<String, dynamic> q) async {
    final res = await _client.get(_uri(path, q), headers: await _headers()).timeout(timeout);
    final b = _decode(res);
    final items = (b['data'] as List? ?? []).map((e) => StockItem.fromJson(e as Map<String, dynamic>)).toList();
    final pg = (b['pagination'] as Map?) ?? const {};
    return Paginated(items, (pg['total'] as num?)?.toInt() ?? 0, (pg['page'] as num?)?.toInt() ?? 1,
        (pg['limit'] as num?)?.toInt() ?? 10, (pg['totalPages'] as num?)?.toInt() ?? 0);
  }

  Future<Paginated<StockItem>> outOfStock({String? pincode, String? categoryId, String? search, int page = 1, int limit = 10}) =>
      _list('/inventory/stock/out-of-stock', {'pincode': pincode, 'categoryId': categoryId, 'search': search, 'page': page, 'limit': limit});

  Future<Paginated<StockItem>> lowStock({String? pincode, String? categoryId, String? search, String sortBy = 'stock_low_to_high', int page = 1, int limit = 10}) =>
      _list('/inventory/stock/low-stock', {'pincode': pincode, 'categoryId': categoryId, 'search': search, 'sortBy': sortBy, 'page': page, 'limit': limit});

  Future<Paginated<StockItem>> expiringSoon({int days = 30, String? pincode, String? categoryId, String? search, int page = 1, int limit = 10}) =>
      _list('/inventory/stock/expiring-soon', {'days': days, 'pincode': pincode, 'categoryId': categoryId, 'search': search, 'page': page, 'limit': limit});

  void dispose() => _client.close();
}
```

Wire once:
```dart
final stockApi = MedicalStockApi(
  baseUrl: 'https://be.beapp.in/api/medical-service',
  tokenProvider: () async => await secureStorage.read(key: 'access_token'),
);
```

> **dio** user? Swap the http calls for `dio.get/patch`, read errors off
> `DioException.response?.data['message']`. Models unchanged.

---

## 6. Screen flow

```dart
// On dashboard load
final summary = await stockApi.summary();
// -> summary cards; each card taps into a list:

// Out of Stock tab
final page = await stockApi.outOfStock(page: 1, limit: 20, search: query);

// Toggle from a card / bulk select
final r = await stockApi.toggle([item.id], true);      // mark out
final r2 = await stockApi.toggle(selectedIds, false);  // bulk mark back in
// then refresh the list + summary
```

Suggested layout: summary cards row → `[Out of Stock] [Low Stock] [Expiring Soon]` tabs →
filters `[Pincode ▾] [Category ▾] [Search]` → paginated item cards with an inline toggle.

---

## 7. Helpers & gotchas

```dart
int daysUntilExpiry(DateTime d) => d.difference(DateTime.now()).inDays;
// <=7 red · <=14 orange · <=30 yellow
```

* **`businessId` is never sent** — it comes from the token. A non-BUSINESS token → 403.
* **Effectively-out check** uses BOTH `totalStock <= 0` and `isOutOfStock`.
* **`expiringBatches` is only the expiring subset**; `batches` still holds all batches.
* **Rx badge**: `product.is_prescription_required` is on every stock row — show the red **Rx**.
* **Refresh summary after a toggle** — counts move between buckets.
* **Errors** always carry `{ "message": "…" }`; 401 → your token-refresh interceptor.

---

## 8. cURL

```bash
# Summary
curl https://be.beapp.in/api/medical-service/inventory/stock/summary -H "Authorization: Bearer $TOKEN"

# Toggle out of stock
curl -X PATCH https://be.beapp.in/api/medical-service/inventory/stock/toggle-out-of-stock \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"inventoryIds":["664f1a2b3c4d5e6f7a8b9c0d"],"isOutOfStock":true}'

# Expiring within 7 days
curl "https://be.beapp.in/api/medical-service/inventory/stock/expiring-soon?days=7" -H "Authorization: Bearer $TOKEN"
```
