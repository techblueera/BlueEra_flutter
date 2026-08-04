# Flutter Integration Guide — Business Description Suggestions

**Audience**: Flutter mobile team (BlueEra_flutter)
**Date**: 2026-08-04
**Endpoint**: `GET /business/description-suggestions`
**Backend**: `src/controllers/businessDescription.controller.js` · Swagger: `/api-docs/` → tag **Suggestions**
**Individual counterpart**: `docs/FLUTTER_INDIVIDUAL_BIO_SUGGESTIONS_GUIDE.md`

---

## 1. What this API is for

When a business owner is filling in their business description, the app offers ready-written descriptions to pick and edit instead of an empty text box.

The content is predefined **per category, and per subcategory where the category has them**. Every description contains the placeholder token `{business_name}`, which is replaced with the actual business name — either by the backend (pass `business_name` in the request) or by the app (see §8). So `{business_name} has grown into a dependable accessories shop.` comes back as `Sharma Motors has grown into a dependable accessories shop.`

---

## 2. Endpoint

```
GET {API_BASE}/business/description-suggestions
```

- **API_BASE (prod)**: `https://be.beapp.in/api/user-service`
- **API_BASE (local)**: `http://localhost:3000`
- **Auth**: none required (same as `GET /business/getAllcategories`). Sending the `Authorization` header anyway is harmless.
- **Method**: GET, query params only. No body.

---

## 3. Every way to identify the category

Pass **one** of these. The generic `category` param accepts all three identifier kinds, so it is what you should normally use.

| Query param | Accepts | Example |
|---|---|---|
| `category` | `_id` **or** `tag_id` **or** name | `AUTO_PARTS` / `Auto Parts` / `6a087f8cacefcd8ca15f9234` |
| `category_id` | `_id` only | `6a087f8cacefcd8ca15f9234` |
| `category_tag_id` | `tag_id` only | `AUTO_PARTS` |
| `category_name` | name only | `Auto Parts` |

Resolution order inside `category` is **_id → tag_id → name**. Name matching is case-insensitive and exact-word.

**Preference**: `tag_id` → `_id` → name. `tag_id` is what `GET /business/getAllcategories` and `GET /business/by-type/:type` already return, and it is what the business record stores in `category_Of_Business`.

---

## 4. Every way to identify the subcategory

Optional. **Subcategories have no `tag_id`** — there is no such field on the SubCategory model — so only `_id` and name are accepted.

| Query param | Accepts | Example |
|---|---|---|
| `sub_category` | `_id` **or** name | `6a087f8dacefcd8ca15f9239` / `Accessories Shop` |
| `sub_category_id` | `_id` only | `6a087f8dacefcd8ca15f9239` |
| `sub_category_name` | name only | `Accessories Shop` |
| `subcategory`, `subcategory_id`, `subcategory_name` | same as above — accepted aliases | |

Subcategory `_id`s come from `GET /business/by-tag/{category_tag_id}/subcategories`.

### Extra params

| Query param | Meaning |
|---|---|
| `business_name` | Replaces `{business_name}` in the returned text. Optional — see §7 and §8. Alias: `businessName` |
| `limit` | Cap how many suggestions come back (e.g. `limit=3`). Omit for all (currently 5 or 10 per subcategory) |

---

## 5. The four call shapes

| User state | Send | You get back |
|---|---|---|
| Category picked, **has no** subcategories | `category=AUTO_BIKE_ACCESSORIES` | That category's own descriptions. `has_sub_categories: false` |
| Category picked, subcategories exist, **none chosen yet** | `category=AUTO_PARTS` | **All** descriptions of every subcategory under it, flat in `suggestions`, split in `groups` |
| Category **and** subcategory picked | `category=AUTO_PARTS&sub_category=Accessories Shop` | Only that subcategory's descriptions |
| **Subcategory `_id` only** | `sub_category=6a087f8dacefcd8ca15f9239` | Same as above — the category is derived from the subcategory. `data.category` still comes back filled in |

> Use an **`_id`** for the subcategory-alone shape. A bare subcategory *name* without a category is ambiguous — the same name exists under several categories, and the backend takes the first match — so always pair a name with its category.

```
# category by tag_id (preferred)
/business/description-suggestions?category=AUTO_PARTS&business_name=Sharma%20Motors

# category by _id
/business/description-suggestions?category=6a087f8cacefcd8ca15f9234&business_name=Sharma%20Motors

# category by name
/business/description-suggestions?category=Auto%20Parts&business_name=Sharma%20Motors

# category + subcategory (combined)
/business/description-suggestions?category=AUTO_PARTS&sub_category=Accessories%20Shop&business_name=Sharma%20Motors

# category by _id + subcategory by _id
/business/description-suggestions?category_id=6a087f8c…&sub_category_id=6a087f8d…&business_name=Sharma%20Motors

# subcategory alone, by _id — category derived
/business/description-suggestions?sub_category=6a087f8dacefcd8ca15f9239&business_name=Sharma%20Motors

# no business name — placeholder comes back intact, replace it client-side
/business/description-suggestions?category=AUTO_PARTS
```

---

## 6. Response

```jsonc
{
  "success": true,
  "message": "Description suggestions fetched successfully",
  "data": {
    "category": {
      "id": "6a087f8cacefcd8ca15f9234",
      "name": "Auto Parts",
      "tag_id": "AUTO_PARTS",
      "type": "Automotive"
    },
    "sub_category": {                     // null when no subcategory was requested
      "id": "6a087f8dacefcd8ca15f9239",
      "name": "Accessories Shop"          // no tag_id — the model has none
    },
    "has_sub_categories": true,
    "business_name": "Sharma Motors",     // null when not sent
    "placeholder": "{business_name}",     // the exact token in the stored text
    "placeholder_replaced": true,         // false when business_name was not sent
    "total": 5,
    "suggestions": [                      // flat list — render this
      {
        "lines": [
          "Sharma Motors has grown into a dependable accessories shop, serving walk-in customers and bulk buyers with the same care.",
          "At the centre of what we do is car and bike accessories, styling kits, audio upgrades and on-the-spot fitment.",
          "Customers stay with us because they see vehicles that look sharper and stay better protected.",
          "Discover why so many customers make Sharma Motors their first and only stop."
        ],
        "text": "Sharma Motors has grown into a dependable accessories shop, … their first and only stop."
      }
    ],
    "groups": [                           // same content, grouped per subcategory
      {
        "sub_category": { "id": "6a087f8d…", "name": "Accessories Shop" },
        "count": 5,
        "suggestions": [ /* … */ ]
      }
    ]
  }
}
```

### `suggestions` vs `groups`

- **`suggestions`** — one flat list, in display order. **This is what a simple description picker should render.**
- **`groups`** — the same content split per subcategory, each with its own `sub_category` and `count`. Use it only for section headers when the user hasn't picked a subcategory. `sub_category` is `null` inside a group when the category has none.

---

## 7. `business_name` — the two ways to fill it in

### Option A — backend fills it (default, simplest)

Send `business_name` with the request. Every occurrence of `{business_name}` in `lines` **and** `text` comes back already replaced, and `placeholder_replaced` is `true`.

```dart
await service.fetch(category: 'AUTO_PARTS', businessName: 'Sharma Motors');
```

Use this when the business name is already known — editing an existing business, or an onboarding step that comes after the name field.

### Option B — app fills it (live typing / name not known yet)

Omit `business_name`. The response keeps the literal `{business_name}` token, `placeholder_replaced` is `false`, and `placeholder` tells you the exact token to substitute. Fetch **once**, then re-render locally on every keystroke — no refetch, no network chatter.

```dart
String applyBusinessName(String source, String businessName, {String placeholder = '{business_name}'}) {
  final clean = businessName.trim();
  if (clean.isEmpty) return source;              // keep the token rather than leaving a hole
  return source.replaceAll(placeholder, clean);
}

// on every TextField change:
final preview = applyBusinessName(suggestion.text, _nameController.text);
```

> If the name is empty, **leave the placeholder in place**. Substituting an empty string produces sentences that start with a space or a stray comma.

### Which to use

| Situation | Option |
|---|---|
| Business already created / name saved | **A** — backend fills it |
| Name typed on the same screen, live preview | **B** — fetch once, replace locally |
| Name typed on a previous onboarding step | **A** |
| Offline-cached suggestions reused across businesses | **B** — cache the raw template, fill per business |

Both options can coexist: pass `business_name` **and** still run `applyBusinessName` on the result. The second call is a no-op once the token is gone, so it is safe as a belt-and-braces default.

---

## 8. `lines` vs `text` — how to render a suggestion

Every suggestion carries the **same content twice**:

| Field | Type | What it is |
|---|---|---|
| `lines` | `List<String>` | The individual sentences, in order (4 per description in the current content) |
| `text` | `String` | Those same sentences joined with a single space — one paragraph |

**Use `text`** for a single flowing paragraph — the business profile description block, preview cards, and when writing into a `TextEditingController` the user will edit as one block.

**Use `lines`** when the design wants line breaks or per-sentence structure. The four lines follow a consistent rhythm — *what the business is → what it offers → why customers stay → the call to action* — which makes them a natural fit for spaced paragraphs:

```dart
final oneParagraph  = suggestion.text;                 // "Sentence one. Sentence two. …"
final lineBroken    = suggestion.lines.join('\n');     // sentence per line
final spacedParas   = suggestion.lines.join('\n\n');   // blank line between sentences  ← recommended here
final bulleted      = suggestion.lines.map((l) => '• $l').join('\n');
final headline      = suggestion.lines.first;          // opening sentence only, for a card preview
final callToAction  = suggestion.lines.last;           // "Visit Sharma Motors …"
```

> `text` is exactly `lines.join(' ')`. Pick the field that matches the layout instead of rebuilding one from the other.

**What to save on the business record**: whatever the user saw. Line-broken layout → save `lines.join('\n')`; paragraph layout → save `text`. `updateBusinessDescription` takes a plain string either way.

---

## 9. Dart models

```dart
class DescriptionSuggestion {
  final List<String> lines;
  final String text;

  const DescriptionSuggestion({required this.lines, required this.text});

  factory DescriptionSuggestion.fromJson(Map<String, dynamic> json) => DescriptionSuggestion(
        lines: (json['lines'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        text: json['text']?.toString() ?? '',
      );

  String get asParagraph => text;
  String get asLineBroken => lines.join('\n');
  String get asSpacedParagraphs => lines.join('\n\n');

  /// Client-side placeholder fill (Option B in §7).
  DescriptionSuggestion withBusinessName(String businessName, {String placeholder = '{business_name}'}) {
    final clean = businessName.trim();
    if (clean.isEmpty) return this;
    return DescriptionSuggestion(
      lines: lines.map((l) => l.replaceAll(placeholder, clean)).toList(),
      text: text.replaceAll(placeholder, clean),
    );
  }
}

class CategoryRef {
  final String? id;
  final String name;
  final String? tagId;
  final String? type;

  const CategoryRef({this.id, required this.name, this.tagId, this.type});

  factory CategoryRef.fromJson(Map<String, dynamic> json) => CategoryRef(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
        tagId: json['tag_id']?.toString(),
        type: json['type']?.toString(),
      );
}

class SubCategoryRef {
  final String? id;
  final String name; // no tag_id — the SubCategory model has none

  const SubCategoryRef({this.id, required this.name});

  factory SubCategoryRef.fromJson(Map<String, dynamic> json) => SubCategoryRef(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
      );
}

class DescriptionGroup {
  final SubCategoryRef? subCategory; // null when the category has no subcategories
  final int count;
  final List<DescriptionSuggestion> suggestions;

  const DescriptionGroup({this.subCategory, required this.count, required this.suggestions});

  factory DescriptionGroup.fromJson(Map<String, dynamic> json) => DescriptionGroup(
        subCategory: json['sub_category'] == null
            ? null
            : SubCategoryRef.fromJson(json['sub_category'] as Map<String, dynamic>),
        count: (json['count'] as num?)?.toInt() ?? 0,
        suggestions: (json['suggestions'] as List? ?? const [])
            .map((e) => DescriptionSuggestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DescriptionSuggestionResponse {
  final CategoryRef category;
  final SubCategoryRef? subCategory;
  final bool hasSubCategories;
  final String? businessName;
  final String placeholder;
  final bool placeholderReplaced;
  final int total;
  final List<DescriptionSuggestion> suggestions;
  final List<DescriptionGroup> groups;

  const DescriptionSuggestionResponse({
    required this.category,
    this.subCategory,
    required this.hasSubCategories,
    this.businessName,
    required this.placeholder,
    required this.placeholderReplaced,
    required this.total,
    required this.suggestions,
    required this.groups,
  });

  factory DescriptionSuggestionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return DescriptionSuggestionResponse(
      category: CategoryRef.fromJson(data['category'] as Map<String, dynamic>),
      subCategory: data['sub_category'] == null
          ? null
          : SubCategoryRef.fromJson(data['sub_category'] as Map<String, dynamic>),
      hasSubCategories: data['has_sub_categories'] == true,
      businessName: data['business_name']?.toString(),
      placeholder: data['placeholder']?.toString() ?? '{business_name}',
      placeholderReplaced: data['placeholder_replaced'] == true,
      total: (data['total'] as num?)?.toInt() ?? 0,
      suggestions: (data['suggestions'] as List? ?? const [])
          .map((e) => DescriptionSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      groups: (data['groups'] as List? ?? const [])
          .map((e) => DescriptionGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Fill the placeholder locally (Option B in §7). No-op if already replaced.
  DescriptionSuggestionResponse filledWith(String businessName) {
    if (placeholderReplaced || businessName.trim().isEmpty) return this;
    return DescriptionSuggestionResponse(
      category: category,
      subCategory: subCategory,
      hasSubCategories: hasSubCategories,
      businessName: businessName.trim(),
      placeholder: placeholder,
      placeholderReplaced: true,
      total: total,
      suggestions: suggestions
          .map((s) => s.withBusinessName(businessName, placeholder: placeholder))
          .toList(),
      groups: groups
          .map((g) => DescriptionGroup(
                subCategory: g.subCategory,
                count: g.count,
                suggestions: g.suggestions
                    .map((s) => s.withBusinessName(businessName, placeholder: placeholder))
                    .toList(),
              ))
          .toList(),
    );
  }
}

class DescriptionSuggestionException implements Exception {
  final int statusCode;
  final String message;

  /// Present on a 404 for an unknown subcategory: what *is* available.
  final List<SubCategoryRef> availableSubCategories;

  const DescriptionSuggestionException(
    this.statusCode,
    this.message, {
    this.availableSubCategories = const [],
  });

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'DescriptionSuggestionException($statusCode): $message';
}
```

---

## 10. Service

Build the URL with `Uri.https` and a **query map** — never string concatenation. Category names contain spaces and ampersands (`Auto & Bike Accessories`, `Food & Beverages`), and business names contain spaces and punctuation; a hand-built URL truncates at the `&`.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class BusinessDescriptionService {
  BusinessDescriptionService({http.Client? client, this.host = 'be.beapp.in'})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String host;
  static const _basePath = '/api/user-service/business/description-suggestions';

  /// [category]     — category _id, tag_id or name. Optional **only** when
  ///                  [subCategory] is a subcategory _id.
  /// [subCategory]  — subcategory _id or name. Omit for all descriptions of the category.
  /// [businessName] — fills {business_name} server-side. Omit to fill it client-side.
  Future<DescriptionSuggestionResponse> fetch({
    String? category,
    String? subCategory,
    String? businessName,
    int? limit,
  }) async {
    assert(
      (category != null && category.isNotEmpty) || (subCategory != null && subCategory.isNotEmpty),
      'Pass a category, or a subcategory _id',
    );

    final uri = Uri.https(host, _basePath, {
      if (category != null && category.isNotEmpty) 'category': category,
      if (subCategory != null && subCategory.isNotEmpty) 'sub_category': subCategory,
      if (businessName != null && businessName.trim().isNotEmpty)
        'business_name': businessName.trim(),
      if (limit != null) 'limit': '$limit',
    });

    final res = await _client.get(uri, headers: const {'Accept': 'application/json'});
    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200 && body['success'] == true) {
      return DescriptionSuggestionResponse.fromJson(body);
    }

    final data = body['data'] as Map<String, dynamic>?;
    throw DescriptionSuggestionException(
      res.statusCode,
      body['message']?.toString() ?? 'Could not load description suggestions',
      availableSubCategories: (data?['available_sub_categories'] as List? ?? const [])
          .map((e) => SubCategoryRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ---- Explicit-param variants ----

  Future<DescriptionSuggestionResponse> byCategoryTagId(
    String categoryTagId, {
    String? subCategoryName,
    String? businessName,
  }) =>
      _fetchRaw({
        'category_tag_id': categoryTagId,
        if (subCategoryName != null) 'sub_category_name': subCategoryName,
        if (businessName != null) 'business_name': businessName,
      });

  Future<DescriptionSuggestionResponse> byIds({
    String? categoryId,
    String? subCategoryId,
    String? businessName,
  }) =>
      _fetchRaw({
        if (categoryId != null) 'category_id': categoryId,
        if (subCategoryId != null) 'sub_category_id': subCategoryId,
        if (businessName != null) 'business_name': businessName,
      });

  /// Subcategory _id alone — the backend derives the category.
  Future<DescriptionSuggestionResponse> bySubCategoryId(
    String subCategoryId, {
    String? businessName,
  }) =>
      _fetchRaw({
        'sub_category_id': subCategoryId,
        if (businessName != null) 'business_name': businessName,
      });

  Future<DescriptionSuggestionResponse> _fetchRaw(Map<String, String> query) async {
    final res = await _client.get(
      Uri.https(host, _basePath, query),
      headers: const {'Accept': 'application/json'},
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return DescriptionSuggestionResponse.fromJson(body);
    }
    throw DescriptionSuggestionException(
      res.statusCode,
      body['message']?.toString() ?? 'Could not load description suggestions',
    );
  }

  void dispose() => _client.close();
}
```

### Calling it

```dart
final service = BusinessDescriptionService();

// 1. Category only, by tag_id — name filled by backend
final all = await service.fetch(category: 'AUTO_PARTS', businessName: 'Sharma Motors');

// 2. Category only, by _id
final byId = await service.fetch(category: business.categoryId!, businessName: business.name);

// 3. Category only, by name
final byName = await service.fetch(category: 'Auto & Bike Accessories', businessName: 'Verma Industries');

// 4. Category + subcategory (combined) — mixed identifier kinds are fine
final combined = await service.fetch(
  category: 'AUTO_PARTS',
  subCategory: 'Accessories Shop',
  businessName: 'Sharma Motors',
);

// 5. Category _id + subcategory _id
final byBothIds = await service.byIds(
  categoryId: '6a087f8cacefcd8ca15f9234',
  subCategoryId: '6a087f8dacefcd8ca15f9239',
  businessName: 'Sharma Motors',
);

// 6. Subcategory alone (must be an _id) — category derived from it
final subOnly = await service.bySubCategoryId(
  '6a087f8dacefcd8ca15f9239',
  businessName: 'Sharma Motors',
);

// 7. No business name — placeholder intact, fill locally as the user types
final template = await service.fetch(category: 'AUTO_PARTS');
final live = template.filledWith(_nameController.text);

// 8. First 3 only
final capped = await service.fetch(category: 'AUTO_PARTS', businessName: 'Sharma Motors', limit: 3);
```

---

## 11. Suggested UI flow

1. User opens **Edit business → Description** and taps *"Get suggestions"*.
2. Call `fetch(category: <category tag_id on the business>, subCategory: <subcategory name or id, if set>, businessName: <business name>)`.
3. Show the suggestions in a bottom sheet — one card per description, rendered with `asSpacedParagraphs`.
4. Tapping a card writes it into the description controller and closes the sheet.

```dart
Future<void> _openDescriptionSuggestions() async {
  setState(() => _loading = true);
  try {
    var result = await service.fetch(
      category: _business.categoryTagId,     // tag_id preferred
      subCategory: _business.subCategoryId,  // null-safe: omitted when null
      businessName: _nameController.text,    // Option A — backend fills it
    );

    // Belt-and-braces: no-op when the backend already replaced it.
    result = result.filledWith(_nameController.text);
    if (!mounted) return;

    final picked = await showModalBottomSheet<DescriptionSuggestion>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: result.suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final s = result.suggestions[i];
          return InkWell(
            onTap: () => Navigator.pop(context, s),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                // Four sentences with a blank line between them.
                // Swap for Text(s.text) if the design wants one block.
                child: Text(s.asSpacedParagraphs, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          );
        },
      ),
    );

    if (picked != null) {
      _descriptionController.text = picked.asSpacedParagraphs; // what gets saved
    }
  } on DescriptionSuggestionException catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
```

### Live-preview variant (name typed on the same screen)

```dart
// Fetch once, without business_name.
_template ??= await service.fetch(category: _business.categoryTagId);

// Rebuild on every keystroke — no network call.
ValueListenableBuilder<TextEditingValue>(
  valueListenable: _nameController,
  builder: (_, value, __) {
    final filled = _template!.filledWith(value.text);
    return Text(filled.suggestions[_selectedIndex].asSpacedParagraphs);
  },
);
```

### Sectioned variant (no subcategory chosen yet)

```dart
if (result.hasSubCategories && result.subCategory == null) {
  for (final group in result.groups) {
    // group.subCategory?.name → section title
    // group.suggestions       → cards under that title
  }
} else {
  // Flat list — result.suggestions
}
```

---

## 12. Errors

| Status | Body `message` | What it means | What the app should do |
|---|---|---|---|
| 400 | `category is required — …` | Neither a category nor a subcategory `_id` was sent | Bug in the app |
| 404 | `No category found for "X"` | The identifier doesn't match any category | Hide the "Get suggestions" entry point |
| 404 | `No description suggestions uploaded for category "X"` | Category exists, content not loaded yet | Show "No suggestions yet" empty state |
| 404 | `No description suggestions found for subcategory "X" …` | Wrong subcategory for that category | `data.available_sub_categories` lists the valid ones — retry with one, or fall back to the category-only call |
| 500 | `Internal server error` | Backend fault | Generic retry snackbar |

Failure here should never block the user — the description field must stay editable by hand.

---

## 13. Gotchas

1. **Never hand-build the query string.** `Auto & Bike Accessories` contains `&`, and business names contain spaces and punctuation. `Uri.https(host, path, queryMap)` encodes both correctly. A concatenated `?category=Auto & Bike Accessories&business_name=…` silently loses everything after the first `&`.
2. **Subcategories have no `tag_id`.** Only `_id` and name. Sending `sub_category_tag_id` does nothing.
3. **A bare subcategory *name* needs its category.** A name sent without a category resolves to the *first* subcategory with that name across all categories — and names like "Accessories Shop" repeat across categories, so you can silently get the wrong one. Only a subcategory **`_id`** is safe on its own.
4. **Empty `business_name` keeps the placeholder** rather than blanking it — check `placeholder_replaced` before showing text to the user, or run `filledWith()` yourself.
5. **Read `placeholder` from the response** instead of hardcoding `{business_name}` — the model stores the token per document, so this stays correct if it ever changes.
6. **`limit` caps per group as well as overall.** With `limit=2` on a category with three subcategories you get 2 per group in `groups` and 2 in the flat `suggestions`.
7. **Cache the un-filled template per (category, subcategory) for the session.** The content is static; fetch once, fill locally per business name.
8. **`category.type`** (`Product`, `Food`, `Service`, `Automotive`, …) comes back for free — useful for analytics, not needed for the request.
