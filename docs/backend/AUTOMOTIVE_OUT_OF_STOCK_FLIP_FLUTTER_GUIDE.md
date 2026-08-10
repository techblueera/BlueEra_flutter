# Automotive Out-of-Stock Flip — Flutter Integration Guide

Flip an automotive inventory item's `isOutOfStock` flag to its opposite value.

If you already integrated this in grocery, food or product-v2, **automotive is the same
contract on a different host**. Skip to §2 — it's a one-line change.

---

## 1. The endpoint

| | |
|---|---|
| Service | `be_automotive_service` |
| Method + path | `PATCH /api/inventory/stock/flip-out-of-stock` |
| Auth | Bearer token, role `BUSINESS` |

```
Content-Type: application/json
Authorization: Bearer <token>
```

> ⚠️ **Grocery, product-v2 and automotive all expose this exact path.** Only the host
> differs. Swapping two base URLs in a `.env` marks the wrong catalogue's items sold out
> with no error at all — the request succeeds and returns a perfectly valid response.
> This is the single most likely way to get this wrong. See §6.

### Flip vs. the existing toggle

Automotive already had `PATCH /api/inventory/stock/toggle-out-of-stock`. Despite its name it
does **not** flip — it **sets** the explicit `isOutOfStock` you send, driving every listed
item to the same state.

| | You send | Two items `[false, true]` become |
|---|---|---|
| `toggle-out-of-stock` | `inventoryIds` + `isOutOfStock: true` | `[true, true]` |
| `flip-out-of-stock` | `inventoryIds` only | `[true, false]` |

Use **flip** for a per-row switch in a list, where the user taps one item and you don't want
to track its current value. Use **toggle** for a "mark all selected as out of stock" bulk
action. `toggle` is unchanged and still supported — nothing you already built breaks.

---

## 2. Already using the shared client? One line.

```dart
enum CatalogService { grocery, food, product, automotive }   // <-- added

extension FlipPath on CatalogService {
  String get flipPath => switch (this) {
        CatalogService.grocery => '/api/inventory/stock/flip-out-of-stock',
        CatalogService.product => '/api/inventory/stock/flip-out-of-stock',
        CatalogService.food => '/api/kitchen-inventory/stock/flip-out-of-stock',
        CatalogService.automotive => '/api/inventory/stock/flip-out-of-stock', // <-- added
      };
}
```

The request and response shapes are identical to grocery and product-v2, so the model
classes below need no changes if you already have them.

---

## 3. Request → Response

### Send

Either form works:

```json
{ "inventoryId": "664f1a2b3c4d5e6f7a8b9c0d" }
```

```json
{ "inventoryIds": ["664f1a2b3c4d5e6f7a8b9c0d", "664f1a2b3c4d5e6f7a8b9c0e"] }
```

* `inventoryIds` wins if both are sent.
* Duplicate ids are collapsed server-side — an id sent twice flips **once**, not twice back
  to where it started.
* Only inventory belonging to your business is touched. Ids that don't match come back in
  `notFound` instead of failing the whole request.

### Receive — `200`

```json
{
  "message": "Successfully flipped isOutOfStock for 2 inventory item(s).",
  "matchedCount": 2,
  "modifiedCount": 2,
  "notFound": [],
  "items": [
    { "inventoryId": "664f1a2b3c4d5e6f7a8b9c0d", "previous": false, "isOutOfStock": true },
    { "inventoryId": "664f1a2b3c4d5e6f7a8b9c0e", "previous": true,  "isOutOfStock": false }
  ]
}
```

| Field | Meaning |
|---|---|
| `items[].previous` | the value **before** the flip |
| `items[].isOutOfStock` | the value **after** — write this straight into your model |
| `matchedCount` / `modifiedCount` | how many rows matched / were written |
| `notFound` | ids that are not yours or don't exist. **Not an error** — check it |

> **Never guess the new value client-side.** Read `isOutOfStock` off the response row. If two
> devices flip the same item at once, `!currentValue` and the server's value diverge and your
> UI shows a lie until the next refresh.

---

## 4. Dart

```dart
class FlipResult {
  final String inventoryId;
  final bool previous;
  final bool isOutOfStock;

  const FlipResult({
    required this.inventoryId,
    required this.previous,
    required this.isOutOfStock,
  });

  factory FlipResult.fromJson(Map<String, dynamic> json) => FlipResult(
        inventoryId: json['inventoryId'] as String,
        previous: json['previous'] == true,
        isOutOfStock: json['isOutOfStock'] == true,
      );
}

class FlipResponse {
  final String message;
  final int matchedCount;
  final int modifiedCount;
  final List<String> notFound;
  final List<FlipResult> items;

  const FlipResponse({
    required this.message,
    required this.matchedCount,
    required this.modifiedCount,
    required this.notFound,
    required this.items,
  });

  factory FlipResponse.fromJson(Map<String, dynamic> json) => FlipResponse(
        message: json['message'] as String? ?? '',
        matchedCount: json['matchedCount'] as int? ?? 0,
        modifiedCount: json['modifiedCount'] as int? ?? 0,
        notFound: (json['notFound'] as List?)?.cast<String>() ?? const [],
        items: (json['items'] as List? ?? const [])
            .map((e) => FlipResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Lookup table for writing results back into a list without an O(n²) scan.
  Map<String, bool> get byId =>
      {for (final r in items) r.inventoryId: r.isOutOfStock};
}
```

```dart
class AutomotiveInventoryApi {
  final Dio _dio; // baseUrl = automotive service host
  AutomotiveInventoryApi(this._dio);

  Future<FlipResponse> flipOutOfStock({
    String? inventoryId,
    List<String>? inventoryIds,
  }) async {
    assert(inventoryId != null || (inventoryIds?.isNotEmpty ?? false),
        'Supply inventoryId or a non-empty inventoryIds');

    final res = await _dio.patch(
      '/api/inventory/stock/flip-out-of-stock',
      data: inventoryIds != null
          ? {'inventoryIds': inventoryIds}
          : {'inventoryId': inventoryId},
    );
    return FlipResponse.fromJson(res.data as Map<String, dynamic>);
  }
}
```

---

## 5. Optimistic UI, done correctly

Flip the switch immediately, then **reconcile with the server's value** — don't just leave
your guess in place.

```dart
Future<void> onSwitchTapped(InventoryRow row) async {
  final expectedPrevious = row.isOutOfStock;

  setState(() => row.isOutOfStock = !expectedPrevious); // optimistic

  try {
    final res = await api.flipOutOfStock(inventoryId: row.id);

    if (res.notFound.contains(row.id)) {
      // Deleted, or belongs to another business. Roll back and refresh.
      setState(() => row.isOutOfStock = expectedPrevious);
      await refreshInventory();
      return;
    }

    final actual = res.byId[row.id];
    if (actual != null) {
      setState(() => row.isOutOfStock = actual); // authoritative
    }
  } catch (_) {
    setState(() => row.isOutOfStock = expectedPrevious); // roll back
    showSnack('Could not update stock status');
  }
}
```

Bulk version:

```dart
final res = await api.flipOutOfStock(inventoryIds: selected.map((r) => r.id).toList());
setState(() {
  for (final row in rows) {
    final value = res.byId[row.id];
    if (value != null) row.isOutOfStock = value;
  }
});
if (res.notFound.isNotEmpty) {
  showSnack('${res.notFound.length} item(s) could not be updated');
}
```

---

## 6. Errors

| Status | When | Do |
|---|---|---|
| `400` | no ids sent, or a malformed ObjectId | Fix the call — this is a client bug |
| `401` | missing/expired token | Refresh the token, retry once |
| `404` | **none** of the ids matched your business | Roll back the UI and refresh the list |
| `500` | server error | Roll back, show a retry |

```json
{ "message": "inventoryIds must be a non-empty array." }
{ "message": "Invalid ObjectId(s): abc123, xyz" }
{ "message": "No matching inventory items found for this business." }
```

Note the difference: **some** ids unmatched → `200` with them listed in `notFound`;
**all** ids unmatched → `404`.

### Guarding the wrong-host mistake

Because grocery, product-v2 and automotive share this path, a misconfigured base URL fails
*silently*. Bind the host to the service in one place and never let a caller pass a raw path:

```dart
final automotiveApi = AutomotiveInventoryApi(
  Dio(BaseOptions(baseUrl: Env.automotiveBaseUrl)), // not Env.groceryBaseUrl
);
```

A cheap smoke test: flip a known automotive inventory id and assert it appears in
`items` rather than in `notFound`. Against the wrong host it lands in `notFound`.

---

## 7. Reading the flag back

`isOutOfStock` is already returned by the automotive read endpoints — nothing new to
integrate, listed here so you know where to read it from:

| Endpoint | Where the flag sits |
|---|---|
| `GET /api/inventory/my-products` | `variants[].inventory.isOutOfStock` |
| `POST /api/inventory/business-products` | on each inventory row |
| `POST /api/inventory/public/business-products` | on each inventory row |
| `GET /api/inventory/public/global-products` | `variants[].inventory.isOutOfStock` |
| `GET /api/inventory/stock/out-of-stock` | on each row |
| `GET /api/inventory/stock/low-stock` | on each row |
| `GET /api/inventory/stock/expiring-soon` | on each row |

Parse it defensively. The field was added after some inventory documents were written, so it
can be **absent**, and absent means `false`:

```dart
final isOut = json['isOutOfStock'] == true; // null-safe by construction
```

Never write `json['isOutOfStock'] as bool` — it throws on those older rows.

### An item is sold out if *either* is true

```dart
bool get soldOut => isOutOfStock || totalStock <= 0;
```

`isOutOfStock` is a **manual override**. It does not touch batches or quantities, and
flipping it back to `false` does not make a zero-quantity item sellable. Two different
states worth showing differently:

* `isOutOfStock == true` → "Marked out of stock" (owner's choice, reversible from the UI)
* `totalStock <= 0` → "No stock" (needs a restock, the switch won't help)

Where the `inStock=true` filter exists, it already excludes both.

---

## 8. Checklist

- [ ] Automotive base URL is bound to the automotive client, not grocery's or product's
- [ ] Reading `isOutOfStock` off the response, never inferring it from `!previous`
- [ ] `notFound` handled — it arrives with a `200`
- [ ] `json['isOutOfStock'] == true`, not a hard cast
- [ ] Sold-out badge checks `isOutOfStock || totalStock <= 0`
- [ ] Optimistic update rolls back on failure
