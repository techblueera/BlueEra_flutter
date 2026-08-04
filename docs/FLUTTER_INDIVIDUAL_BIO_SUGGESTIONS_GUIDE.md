# Flutter Integration Guide — Individual Bio Suggestions

**Audience**: Flutter mobile team (BlueEra_flutter)
**Date**: 2026-08-04
**Endpoint**: `GET /individual-professions/bio-suggestions`
**Backend**: `src/controllers/bioSuggestion.controller.js` · Swagger: `/api-docs/` → tag **Suggestions**
**Business counterpart**: `docs/FLUTTER_BUSINESS_DESCRIPTION_SUGGESTIONS_GUIDE.md`

---

## 1. What this API is for

When an individual user is filling in their profile bio, the app shows a list of ready-written bios they can pick and edit, instead of facing an empty text box.

The suggestions are **predefined content stored per profession, and per designation (subcategory) where the profession has them**. The app sends whatever identifier it already holds for the user's profession — an `_id`, a `tag_id`, or the display name — and gets back the matching bios.

The app does **not** need to know in advance whether a profession has subcategories. Send the profession alone and you get everything under it; add the subcategory when the user has picked one.

---

## 2. Endpoint

```
GET {API_BASE}/individual-professions/bio-suggestions
```

- **API_BASE (prod)**: `https://be.beapp.in/api/user-service`
- **API_BASE (local)**: `http://localhost:3000`
- **Auth**: none required (same as `GET /individual-professions`). Sending the `Authorization` header anyway is harmless.
- **Method**: GET, query params only. No body.

---

## 3. Every way to identify the profession

Pass **one** of these. The generic `profession` param accepts all three identifier kinds, so it is what you should normally use.

| Query param | Accepts | Example |
|---|---|---|
| `profession` | `_id` **or** `tag_id` **or** name | `PLUMBER` / `Plumber` / `6a085c7d740baa2c944756f1` |
| `profession_id` | `_id` only | `6a085c7d740baa2c944756f1` |
| `profession_tag_id` | `tag_id` only | `PLUMBER` |
| `profession_name` | name only | `Plumber` |

Resolution order inside `profession` is **_id → tag_id → name**, so there is no ambiguity. Name matching is case-insensitive and exact-word (`plumber` = `Plumber`).

**Which one should the app send?** Whatever it already has, in this order of preference:

1. `tag_id` — stable, short, already returned by `GET /individual-professions`. **Preferred.**
2. `_id` — equally exact; use it if that is what the profile object stores.
3. name — works, but is the most fragile if content is ever renamed.

---

## 4. Every way to identify the subcategory (designation)

Optional. Pass **one** of these alongside the profession.

| Query param | Accepts | Example |
|---|---|---|
| `subcategory` | `_id` **or** `tag_id` **or** name | `PIPELINE_REPAIR` / `Pipeline Repair` / `66f0…` |
| `subcategory_id` | subdocument `_id` | `66f0…` |
| `subcategory_tag_id` | `tag_id` only | `PIPELINE_REPAIR` |
| `subcategory_name` | name only | `Pipeline Repair` |
| `sub_category`, `sub_category_id`, `sub_category_tag_id`, `sub_category_name`, `designation` | same as above — accepted aliases | |

> Subcategories of a profession are **embedded inside the profession document** (`subcategories_filedName`), not a separate collection. "Subcategory `_id`" therefore means the id of that embedded entry — exactly the `_id` you get from `GET /individual-professions` / `GET /individual-professions/:tag_id/designation`.

### Extra param

| Query param | Meaning |
|---|---|
| `limit` | Cap how many suggestions come back (e.g. `limit=3`). Omit to get all of them (currently 5 per subcategory). |

---

## 5. The three call shapes

| User state | Send | You get back |
|---|---|---|
| Profession picked, **has no** designations | `profession=BIKE_RIDER` | That profession's own bios. `has_subcategories: false` |
| Profession picked, designations exist, **none chosen yet** | `profession=PLUMBER` | **All** bios of every designation under it, flat in `suggestions`, split in `groups` |
| Profession **and** designation picked | `profession=PLUMBER&subcategory=PIPELINE_REPAIR` | Only that designation's bios |

The app can use the same call for the first two cases — send the profession and read `has_subcategories` if you care about the distinction.

```
# by tag_id (preferred)
/individual-professions/bio-suggestions?profession=PLUMBER

# by _id
/individual-professions/bio-suggestions?profession=6a085c7d740baa2c944756f1

# by name  (note: must be URL-encoded — see §9)
/individual-professions/bio-suggestions?profession=Plumber

# profession + subcategory, both by tag_id
/individual-professions/bio-suggestions?profession=PLUMBER&subcategory=PIPELINE_REPAIR

# profession by _id + subcategory by name
/individual-professions/bio-suggestions?profession_id=6a085c…&subcategory_name=Pipeline%20Repair

# capped
/individual-professions/bio-suggestions?profession=PLUMBER&limit=3
```

---

## 6. Response

```jsonc
{
  "success": true,
  "message": "Bio suggestions fetched successfully",
  "data": {
    "profession": {
      "id": "6a085c7d740baa2c944756f1",
      "name": "Plumber",
      "tag_id": "PLUMBER",
      "profile_type": "Self Employed"
    },
    "subcategory": {                      // null when no subcategory was requested
      "id": "66f0a1…",
      "name": "Pipeline Repair",
      "tag_id": "PIPELINE_REPAIR"
    },
    "has_subcategories": true,
    "total": 5,
    "suggestions": [                      // flat list — render this
      {
        "lines": [
          "I work as a Plumber, handling pipeline repair across the city.",
          "I would rather take fewer jobs and do them properly."
        ],
        "text": "I work as a Plumber, handling pipeline repair across the city. I would rather take fewer jobs and do them properly."
      }
    ],
    "groups": [                           // same content, grouped per subcategory
      {
        "subcategory": { "id": "66f0a1…", "name": "Pipeline Repair", "tag_id": "PIPELINE_REPAIR" },
        "count": 5,
        "suggestions": [ /* … */ ]
      }
    ]
  }
}
```

### `suggestions` vs `groups`

- **`suggestions`** — one flat list, already in display order. **This is what a simple bio picker should render.**
- **`groups`** — the same suggestions split per designation, each with its own `subcategory` object and `count`. Use it only if you want section headers ("Pipeline Repair", "Bathroom Fitting") when the user hasn't picked a designation. `subcategory` is `null` inside a group when the profession has no designations.

Don't render both — pick one path and stick to it.

---

## 7. `lines` vs `text` — how to render a suggestion

Every suggestion carries the **same content twice**:

| Field | Type | What it is |
|---|---|---|
| `lines` | `List<String>` | The individual sentences, in order, exactly as authored |
| `text` | `String` | Those same sentences joined with a single space — one paragraph |

**Use `text`** when the bio is a single flowing paragraph — profile headers, preview cards, one-line summaries, and when writing into a `TextEditingController` where the user will edit it as one block.

**Use `lines`** when you want line breaks or per-sentence layout — a two-line bio card, bullet points, or animating sentences in one at a time. Join them yourself with whatever separator the design calls for:

```dart
final oneParagraph  = suggestion.text;                 // "Sentence one. Sentence two."
final lineBroken    = suggestion.lines.join('\n');     // sentence per line
final spacedParas   = suggestion.lines.join('\n\n');   // blank line between sentences
final bulleted      = suggestion.lines.map((l) => '• $l').join('\n');
```

> `text` is exactly `lines.join(' ')`. Never reconstruct one from the other with custom logic — just choose the field that matches the layout.

**What to save on the profile**: whatever the user ends up seeing. If the design shows line breaks, save `lines.join('\n')`; if it shows a paragraph, save `text`. The bio field on the user record is a plain string either way — the backend does not care which you send.

---

## 8. Dart models

```dart
class BioSuggestion {
  final List<String> lines;
  final String text;

  const BioSuggestion({required this.lines, required this.text});

  factory BioSuggestion.fromJson(Map<String, dynamic> json) => BioSuggestion(
        lines: (json['lines'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        text: json['text']?.toString() ?? '',
      );

  /// Ready-to-render variants.
  String get asParagraph => text;
  String get asLineBroken => lines.join('\n');
  String get asSpacedParagraphs => lines.join('\n\n');
}

class ProfessionRef {
  final String? id;
  final String name;
  final String? tagId;
  final String? profileType;

  const ProfessionRef({this.id, required this.name, this.tagId, this.profileType});

  factory ProfessionRef.fromJson(Map<String, dynamic> json) => ProfessionRef(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
        tagId: json['tag_id']?.toString(),
        profileType: json['profile_type']?.toString(),
      );
}

class SubcategoryRef {
  final String? id;
  final String name;
  final String? tagId;

  const SubcategoryRef({this.id, required this.name, this.tagId});

  factory SubcategoryRef.fromJson(Map<String, dynamic> json) => SubcategoryRef(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
        tagId: json['tag_id']?.toString(),
      );
}

class BioSuggestionGroup {
  final SubcategoryRef? subcategory; // null when the profession has no designations
  final int count;
  final List<BioSuggestion> suggestions;

  const BioSuggestionGroup({this.subcategory, required this.count, required this.suggestions});

  factory BioSuggestionGroup.fromJson(Map<String, dynamic> json) => BioSuggestionGroup(
        subcategory: json['subcategory'] == null
            ? null
            : SubcategoryRef.fromJson(json['subcategory'] as Map<String, dynamic>),
        count: (json['count'] as num?)?.toInt() ?? 0,
        suggestions: (json['suggestions'] as List? ?? const [])
            .map((e) => BioSuggestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class BioSuggestionResponse {
  final ProfessionRef profession;
  final SubcategoryRef? subcategory;
  final bool hasSubcategories;
  final int total;
  final List<BioSuggestion> suggestions;
  final List<BioSuggestionGroup> groups;

  const BioSuggestionResponse({
    required this.profession,
    this.subcategory,
    required this.hasSubcategories,
    required this.total,
    required this.suggestions,
    required this.groups,
  });

  factory BioSuggestionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return BioSuggestionResponse(
      profession: ProfessionRef.fromJson(data['profession'] as Map<String, dynamic>),
      subcategory: data['subcategory'] == null
          ? null
          : SubcategoryRef.fromJson(data['subcategory'] as Map<String, dynamic>),
      hasSubcategories: data['has_subcategories'] == true,
      total: (data['total'] as num?)?.toInt() ?? 0,
      suggestions: (data['suggestions'] as List? ?? const [])
          .map((e) => BioSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      groups: (data['groups'] as List? ?? const [])
          .map((e) => BioSuggestionGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Thrown for 400 / 404 / 5xx so the UI can react per case.
class BioSuggestionException implements Exception {
  final int statusCode;
  final String message;

  /// Present on a 404 for an unknown subcategory: what *is* available.
  final List<SubcategoryRef> availableSubcategories;

  const BioSuggestionException(
    this.statusCode,
    this.message, {
    this.availableSubcategories = const [],
  });

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'BioSuggestionException($statusCode): $message';
}
```

---

## 9. Service

Build the URL with `Uri.https` / `Uri.http` and a **query map**. Do not concatenate strings: profession names contain spaces, slashes and ampersands (`Auto / E-Rickshaw`, `Business & HR Consultant`, `Maid (Female)`), and a hand-built URL will silently truncate at the `&`.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class BioSuggestionService {
  BioSuggestionService({http.Client? client, this.host = 'be.beapp.in'})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String host;
  static const _basePath = '/api/user-service/individual-professions/bio-suggestions';

  /// [profession] accepts a profession _id, tag_id or name.
  /// [subcategory] accepts a subcategory _id, tag_id or name — omit it to get
  /// every suggestion under the profession.
  Future<BioSuggestionResponse> fetch({
    required String profession,
    String? subcategory,
    int? limit,
  }) async {
    final uri = Uri.https(host, _basePath, {
      'profession': profession,
      if (subcategory != null && subcategory.isNotEmpty) 'subcategory': subcategory,
      if (limit != null) 'limit': '$limit',
    });

    final res = await _client.get(uri, headers: const {'Accept': 'application/json'});
    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200 && body['success'] == true) {
      return BioSuggestionResponse.fromJson(body);
    }

    final data = body['data'] as Map<String, dynamic>?;
    throw BioSuggestionException(
      res.statusCode,
      body['message']?.toString() ?? 'Could not load bio suggestions',
      availableSubcategories: (data?['available_subcategories'] as List? ?? const [])
          .map((e) => SubcategoryRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ---- Explicit-param variants, if you prefer to be unambiguous ----

  Future<BioSuggestionResponse> byTagId(String professionTagId, {String? subcategoryTagId}) =>
      _fetchRaw({
        'profession_tag_id': professionTagId,
        if (subcategoryTagId != null) 'subcategory_tag_id': subcategoryTagId,
      });

  Future<BioSuggestionResponse> byId(String professionId, {String? subcategoryId}) =>
      _fetchRaw({
        'profession_id': professionId,
        if (subcategoryId != null) 'subcategory_id': subcategoryId,
      });

  Future<BioSuggestionResponse> byName(String professionName, {String? subcategoryName}) =>
      _fetchRaw({
        'profession_name': professionName,
        if (subcategoryName != null) 'subcategory_name': subcategoryName,
      });

  Future<BioSuggestionResponse> _fetchRaw(Map<String, String> query) async {
    final res = await _client.get(
      Uri.https(host, _basePath, query),
      headers: const {'Accept': 'application/json'},
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return BioSuggestionResponse.fromJson(body);
    }
    throw BioSuggestionException(
      res.statusCode,
      body['message']?.toString() ?? 'Could not load bio suggestions',
    );
  }

  void dispose() => _client.close();
}
```

### Calling it

```dart
final service = BioSuggestionService();

// 1. Profession only — by tag_id (preferred)
final all = await service.fetch(profession: 'PLUMBER');

// 2. Profession only — by _id
final byId = await service.fetch(profession: user.professionId!);

// 3. Profession only — by name (spaces/&/ are encoded for you by Uri.https)
final byName = await service.fetch(profession: 'Business & HR Consultant');

// 4. Profession + subcategory, both tag_ids
final narrowed = await service.fetch(
  profession: 'PLUMBER',
  subcategory: 'PIPELINE_REPAIR',
);

// 5. Profession _id + subcategory name (mixed identifier kinds are fine)
final mixed = await service.fetch(
  profession: user.professionId!,
  subcategory: 'Pipeline Repair',
);

// 6. Only the first 3
final capped = await service.fetch(profession: 'PLUMBER', limit: 3);
```

---

## 10. Suggested UI flow

1. User opens **Edit profile → Bio** and taps *"Get suggestions"*.
2. Call `fetch(profession: <tag_id the profile already stores>, subcategory: <designation tag_id, if the user has one>)`.
3. Show the suggestions in a bottom sheet — one card per suggestion.
4. Tapping a card writes it into the bio `TextEditingController` and closes the sheet. The user can edit it before saving.

```dart
Future<void> _openBioSuggestions() async {
  setState(() => _loading = true);
  try {
    final result = await service.fetch(
      profession: _profile.professionTagId,
      subcategory: _profile.designationTagId, // null-safe: omitted when null
    );
    if (!mounted) return;

    final picked = await showModalBottomSheet<BioSuggestion>(
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
                // lines.join('\n') → one sentence per line.
                // Swap for Text(s.text) if the design wants a paragraph.
                child: Text(s.asLineBroken, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          );
        },
      ),
    );

    if (picked != null) {
      _bioController.text = picked.asParagraph; // what gets saved
    }
  } on BioSuggestionException catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
```

### Sectioned variant (no designation chosen yet)

```dart
if (result.hasSubcategories && result.subcategory == null) {
  // Render result.groups with a header per designation.
  for (final group in result.groups) {
    // group.subcategory?.name → section title
    // group.suggestions       → cards under that title
  }
} else {
  // Flat list — result.suggestions
}
```

---

## 11. Errors

| Status | Body `message` | What it means | What the app should do |
|---|---|---|---|
| 400 | `profession is required — …` | No profession identifier was sent | Bug in the app — always send one |
| 404 | `No profession found for "X"` | The identifier doesn't match any profession | Hide the "Get suggestions" entry point |
| 404 | `No bio suggestions uploaded for profession "X"` | Profession exists, content not loaded yet | Show "No suggestions yet" empty state |
| 404 | `No bio suggestions found for subcategory "X" …` | Wrong designation for that profession | `data.available_subcategories` lists the valid ones — retry with one, or fall back to the profession-only call |
| 500 | `Internal server error` | Backend fault | Generic retry snackbar |

Failure here should never block the user — the bio field must stay editable by hand.

---

## 12. Gotchas

1. **Never hand-build the query string.** `Business & HR Consultant` contains `&`; `Auto / E-Rickshaw` contains `/`. `Uri.https(host, path, queryMap)` encodes both correctly.
2. **`profession` is mandatory, `subcategory` is not.** Sending a subcategory alone is a 400 — the backend needs the profession to scope it.
3. **`subcategory` `_id` is the embedded subdocument id**, from `GET /individual-professions/:tag_id/designation`. It is not an id from any other collection.
4. **`limit` caps per group as well as overall.** With `limit=2` on a profession with two designations you get 2 per group in `groups` and 2 in the flat `suggestions`. For a strict overall cap, use `limit` and read `suggestions` only.
5. **Suggestion order is stable** — the same call returns the same order, so an index is safe as a list key within one response, but don't persist it.
6. **Cache per (profession, subcategory) for the session.** The content is static; there's no reason to refetch every time the sheet opens.
7. **`profile_type`** (`Self Employed`, `GigWork`, `Professional`, `Social Profile`) comes back for free — useful for analytics, not needed for the request.
