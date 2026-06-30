# Category API — Flutter Integration Guide

Focused on the progressive **level → subtree** drill-down flow for the
`/api/categories/nested` endpoint.

## Base setup

- **Base URL:** `https://<your-host>/product-service/api` (routes mount at `/api`,
  categories under `/categories`)
- **Auth:** only `/categories/with-inventory` needs a token. Send
  `Authorization: Bearer <jwt>`. The `nested` endpoints below are public.

### Endpoints used here

| Endpoint | Auth | Returns |
|---|---|---|
| `GET /categories/nested?level=0` | no | Flat level-0 categories, **no `children`** |
| `GET /categories/nested?categoryId=<id>` | no | That category **with full nested subtree** |
| `GET /categories/nested?categoryKey=<KEY>` | no | Same, by key |
| `GET /categories/nested` | no | Full root tree (all levels nested) |

A node looks like this (note: `imageOptions` is omitted from these responses):

```json
{
  "_id": "665f...",
  "name": "Beverages",
  "key": "BEVERAGES",
  "image": "https://...",
  "parentId": null,
  "level": 0,
  "isActive": true,
  "productCount": 1240,        // total in subtree (direct + descendants)
  "directProductCount": 0,     // products directly on this category (≈leaf only)
  "totalProductCount": 1240,   // alias of productCount
  "children": [ ... ]          // present ONLY when fetched via categoryId/categoryKey or full tree
}
```

## 1. Model

```dart
class Category {
  final String id;
  final String name;
  final String key;
  final String? image;
  final String? parentId;
  final int level;
  final int productCount;
  final int directProductCount;
  final List<Category> children;

  Category({
    required this.id,
    required this.name,
    required this.key,
    required this.level,
    required this.productCount,
    required this.directProductCount,
    this.image,
    this.parentId,
    this.children = const [],
  });

  bool get hasChildren => children.isNotEmpty;
  bool get isLeaf => level >= 3;

  factory Category.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] as List<dynamic>? ?? const [];
    return Category(
      id: json['_id'] as String,
      name: json['name'] as String,
      key: json['key'] as String? ?? '',
      image: json['image'] as String?,
      parentId: json['parentId'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 0,
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
      directProductCount: (json['directProductCount'] as num?)?.toInt() ?? 0,
      children: rawChildren
          .map((c) => Category.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
```

## 2. Service (Dio)

```dart
import 'package:dio/dio.dart';

class CategoryService {
  final Dio _dio;
  CategoryService(this._dio); // configure baseUrl = ".../product-service/api"

  /// Flat list of categories at a given level (no children). level 0 = root.
  Future<List<Category>> getCategoriesByLevel(int level) async {
    final res = await _dio.get('/categories/nested',
        queryParameters: {'level': level});
    return (res.data as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Single category WITH its full nested subtree.
  Future<Category> getSubtreeById(String categoryId) async {
    final res = await _dio.get('/categories/nested',
        queryParameters: {'categoryId': categoryId});
    return Category.fromJson(res.data as Map<String, dynamic>);
  }

  /// Same, by key (e.g. "BEVERAGES").
  Future<Category> getSubtreeByKey(String categoryKey) async {
    final res = await _dio.get('/categories/nested',
        queryParameters: {'categoryKey': categoryKey});
    return Category.fromJson(res.data as Map<String, dynamic>);
  }
}
```

## 3. Drill-down flow

The intended UX: **load level 0 cheaply, then fetch a subtree only when the user
taps a category.**

```dart
// Screen 1 — top-level grid/list
final roots = await service.getCategoriesByLevel(0); // fast, no subtree payload

// On tap of a root category:
final subtree = await service.getSubtreeById(tapped.id);
// subtree.children -> level-1 categories, each with their own .children down to leaves
```

You can keep drilling with the already-loaded subtree (no more calls needed), or
re-fetch per node if you prefer lazy loading:

```dart
void onCategoryTap(Category c) {
  if (c.isLeaf) {
    openProductList(categoryId: c.id);      // leaf → show products
  } else {
    Navigator.push(... CategoryChildrenScreen(parent: c));
    // parent.children already holds the next level
  }
}
```

## 4. Notes & gotchas

- **`level` returns flat nodes** — `children` will be empty. Don't expect a
  subtree there; that's by design. Use `categoryId` to expand.
- **Counts are subtree totals.** `productCount` includes all descendants, so a
  level-0 node shows the total across everything beneath it. `directProductCount`
  is usually non-zero only at leaves (level 3).
- **Short cache on the server (~60s).** Newly added categories / count changes can
  lag up to a minute. Don't build flows that require instant reflection of an
  admin edit.
- **`categoryId`/`categoryKey` override `level`** — if you send both, you get the
  subtree, not the flat list.
- **Invalid `level`** (non-integer) returns `400 { "message": "..." }`. Levels are
  `0..3`.
- **Empty level** returns `[]` (200), not an error.

## 5. Inventory-filtered variants (optional)

These return only categories that have products in stock, and the tree **starts at
level 1** (children of the roots) rather than level 0:

| Endpoint | Auth | Notes |
|---|---|---|
| `GET /categories/nested/with-inventory` | no | Supports `categoryId`, `categoryKey`, `businessId` query params |
| `GET /categories/with-inventory` | **yes** | Scoped to the authenticated business |

Same `Category` model applies; nodes carry nested `children` (no `productCount`
fields on these — they are inventory-pruned trees).
