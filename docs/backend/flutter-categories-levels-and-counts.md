# Flutter Integration — Category Levels & Product Counts

Backend: `be_automotive_service`, endpoint `GET /api/categories/nested`.
Base URL behind the gateway: `https://<host>/product-service/api`. Public — no token.

This covers the **level drill-down** and **product count** capabilities of
`/categories/nested`. It supersedes §1–4 of `flutter-categories-integration.md`,
which documented these before they were implemented; the older guide's Dart model
parsed count fields the API did not yet return, so they always rendered `0`.

---

## 1. Three response modes, one endpoint

`/categories/nested` answers in three different **shapes** depending on the query.
Getting this wrong is the main integration hazard — a `List` vs a single object.

| Query | Returns | `children` |
|---|---|---|
| `?level=<n>` | **JSON array** of that level's categories | **absent** |
| `?categoryId=<id>` / `?categoryKey=<KEY>` | **single object** — that node + full subtree | present, nested to leaves |
| _(no params)_ | **JSON array** of root nodes, each with a full subtree | present, nested to leaves |

`categoryId`/`categoryKey` **take precedence over `level`** — send both and you get
the subtree, not the flat list.

Every node in every mode carries counts:

```json
{
  "_id": "665f...",
  "name": "Oil Filters",
  "key": "OIL_FILTERS",
  "image": "https://...",
  "parentId": "664a...",
  "level": 2,
  "isActive": true,
  "directProductCount": 42,     // products sitting ON this node
  "productCount": 42,           // subtree total: self + all descendants
  "totalProductCount": 42,      // alias of productCount
  "children": [ ... ]           // omitted entirely when ?level= is used
}
```

> `productCount` counts **active products only** (`isActive: true`). A category can
> legitimately show `0` while holding inactive rows — don't treat `0` as "category
> is broken".

> `directProductCount` is non-zero mainly at leaves. On a level-0 node it is
> usually `0` while `productCount` is large — that is the intended shape, and it is
> why you should badge with `productCount`, never `directProductCount`.

---

## 2. Model

```dart
class Category {
  final String id;
  final String name;
  final String key;
  final String? image;
  final String? parentId;
  final int level;
  final bool isActive;
  final int productCount;
  final int directProductCount;
  final List<Category> children;

  const Category({
    required this.id,
    required this.name,
    required this.key,
    required this.level,
    required this.isActive,
    required this.productCount,
    required this.directProductCount,
    this.image,
    this.parentId,
    this.children = const [],
  });

  /// True once a subtree has been loaded. Meaningless on a `?level=` row, where
  /// `children` is never sent — use [hasStock] to decide if a tap is worthwhile.
  bool get hasChildren => children.isNotEmpty;

  /// Anything to show behind this node.
  bool get hasStock => productCount > 0;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['_id'] as String,
        name: json['name'] as String? ?? '',
        key: json['key'] as String? ?? '',
        image: json['image'] as String?,
        parentId: json['parentId'] as String?,
        level: (json['level'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        productCount: (json['productCount'] as num?)?.toInt() ?? 0,
        directProductCount: (json['directProductCount'] as num?)?.toInt() ?? 0,
        children: (json['children'] as List<dynamic>? ?? const [])
            .map((c) => Category.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}
```

`parentId` is `null` on roots — keep it nullable. `key` is uppercase and globally
unique, so it is a safe cache key and a safe deep-link segment.

---

## 3. Service

```dart
import 'package:dio/dio.dart';

class CategoryService {
  CategoryService(this._dio);   // baseUrl = ".../product-service/api"
  final Dio _dio;

  /// Flat list for one level — no subtree payload. Sorted by name server-side.
  Future<List<Category>> byLevel(int level) async {
    final res = await _dio.get('/categories/nested', queryParameters: {'level': level});
    return (res.data as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// One node WITH its full nested subtree.
  Future<Category> subtreeById(String categoryId) async {
    final res = await _dio.get('/categories/nested', queryParameters: {'categoryId': categoryId});
    return Category.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Category> subtreeByKey(String categoryKey) async {
    final res = await _dio.get('/categories/nested', queryParameters: {'categoryKey': categoryKey});
    return Category.fromJson(res.data as Map<String, dynamic>);
  }

  /// Every root with its full tree. One big payload — prefer [byLevel] on a
  /// home screen and expand on tap.
  Future<List<Category>> fullTree() async {
    final res = await _dio.get('/categories/nested');
    return (res.data as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

---

## 4. The drill-down flow

Load one level cheaply, then fetch a subtree **once** and walk it locally.

```dart
// Screen 1 — top level. Small payload, no subtree.
final roots = await service.byLevel(0);

// Screen 2 — on tap, fetch that node's whole subtree in a single call.
final subtree = await service.subtreeById(tapped.id);
// subtree.children => level 1, each with .children => level 2, … down to leaves.

void onTap(Category c) {
  if (c.hasChildren) {
    push(CategoryScreen(parent: c));   // already in memory — no network call
  } else {
    push(ProductListScreen(categoryId: c.id));
  }
}
```

After that one `subtreeById` call, **every deeper level is already in memory**.
Don't re-fetch per level — that was the old pattern and it costs a round trip per tap.

### Hiding dead ends

`/categories/nested` returns the full catalog including categories with nothing for
sale, and including `isActive: false` rows. Filter client-side:

```dart
List<Category> sellable(List<Category> cs) =>
    cs.where((c) => c.isActive && c.hasStock).toList();
```

If you want the server to do it, use the inventory-pruned variant instead —
`GET /categories/nested/with-inventory`, which drops branches with no stock anywhere
beneath them. Note it returns **no count fields**: it is a different handler and was
not part of this change.

### Count badges

```dart
Widget badge(Category c) => c.hasStock
    ? Chip(label: Text('${c.productCount}'))
    : const SizedBox.shrink();
```

Badge with `productCount`, not `directProductCount` — see §1.

---

## 5. Caching — the 60s window

The server memoises the assembled tree **and its counts for 60 seconds**. Two
consequences for the client:

1. **An admin edit takes up to a minute to appear.** Don't build a flow that
   creates a category and immediately expects it in a category list, and don't show
   a "saved!" state that depends on a re-fetch confirming it.
2. **Retrying immediately gets you the same bytes.** A pull-to-refresh inside the
   window is a no-op — either debounce it to ≥60s, or accept it as a UX placebo.

The counts are a *snapshot*, not live stock. If a screen needs an exact number
(a checkout, an admin audit), query the product endpoint instead of trusting a badge.

Client-side, cache `byLevel(0)` for the session — it changes rarely, and the server
is already caching behind you.

---

## 6. Errors

| Status | When | Body | Handle |
|---|---|---|---|
| `400` | `level` is not a non-negative integer | `{ "message": "level must be a non-negative integer." }` | A bug in your call — `level` must be an `int`, never a string like `"all"` |
| `404` | `categoryId`/`categoryKey` not found | `{ "message": "Category not found" }` | Stale deep link — fall back to level 0 |
| `500` | server | `{ "message": "...", "error": "..." }` | Retry once, then show a generic failure |

```dart
Future<List<Category>> safeByLevel(CategoryService s, int level) async {
  try {
    return await s.byLevel(level);
  } on DioException catch (e) {
    if (e.response?.statusCode == 400) {
      throw ArgumentError('level must be a non-negative integer, got: $level');
    }
    rethrow;
  }
}
```

Any non-negative integer is accepted. There is no schema ceiling on `level` — the
usable range is however deep your category data actually goes, so discover it from
the data rather than hardcoding `0..3`.

Two non-error edge cases worth knowing:

- **A level that holds no categories** (say `level=9`) returns `[]` with `200`.
  Render an empty state, don't treat it as a failure.
- **`?level=` with an empty value** is treated as *not supplied* — you get the full
  root tree, not `[]` and not a `400`. If your UI can produce an empty level string,
  omit the parameter instead, or you will silently download the whole catalog.

---

## 7. Migration from the old behaviour

If your app already calls `/categories/nested`:

| You were doing | Now |
|---|---|
| Sending `?level=0` and receiving the **whole tree** (the param was ignored) | You get a flat array. If you relied on `children` being present, switch to `subtreeById` |
| Reading `productCount` and always getting `0` | Real values — badges will start appearing |
| Fetching the full tree on the home screen to get roots | Use `byLevel(0)` — far smaller |
| Expecting instant reflection of admin edits | Up to 60s stale |

The response shape for `categoryId`, `categoryKey`, and the no-param call is
**unchanged** apart from the added count fields, so those call sites keep working
without edits.
