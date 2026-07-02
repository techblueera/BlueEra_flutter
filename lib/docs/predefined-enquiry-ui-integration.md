# Predefined Enquiry Options — UI Integration Guide

Server-driven chip catalogs for the **"other" business enquiry sheet**
(banking / loans / insurance / financial-services listings), owned by
**be_other_service**.

This is the options-source counterpart of the existing enquiry flow: the sheet
fetches its chip groups from the backend (like the consultant sheet does from
`earn-service/predefined-professional`), then submits through the already-live
`POST /other-enquiries` (see `other-enquiry-ui-integration.md`).

**Flow:** listing screen loads → prefetch options for the listing's category →
customer taps Enquire → sheet renders the fetched groups → submit selections →
existing `business_enquiry` chat-card flow takes over (unchanged).

All endpoints require `Authorization: Bearer <token>`.

---

## 1. Fetch the option catalog

### `GET /predefined-enquiry/{category}`

`{category}` is the listing's category tag — the user-service
`Category.tag_id` that also arrives on the `business_enquiry` chat card as
`category`. **Case-insensitive** (the backend uppercases it), so
`loans_sector` works too.

Currently seeded categories:

| Category | Sheet |
|---|---|
| `LOANS_SECTOR` | Services / Loan Amount / Purpose |
| `BANKING_SECTOR` | Services / Account For / Purpose |
| `INSURANCE_SECTOR` | Services / Coverage · Investment / Purpose |
| `FINANCIAL_SERVICES` | Services / For Whom / Purpose |

**Response — `200`:**

```json
{
  "success": true,
  "data": {
    "category": "LOANS_SECTOR",
    "groups": [
      {
        "title": "Services",
        "options": ["Home Loan", "Personal Loan", "Business Loan", "Vehicle Loan",
                    "Education Loan", "Gold Loan", "Loan Against Property"],
        "multiSelect": true
      },
      {
        "title": "Loan Amount",
        "options": ["Under ₹1 L", "₹1 L – ₹5 L", "₹5 L – ₹25 L", "₹25 L – ₹1 Cr", "Above ₹1 Cr"],
        "multiSelect": false
      },
      {
        "title": "Purpose",
        "options": ["Compare rates", "Check eligibility", "Apply now",
                    "Documentation help", "Balance transfer", "EMI / repayment query"],
        "multiSelect": true
      }
    ]
  }
}
```

**Errors:**

| Status | Meaning | Client behavior |
|---|---|---|
| `400` | Blank category | Treat like 404 |
| `404` | Unknown or deactivated category | Fall back to the generic sheet: note + photo only (the create rule in §3 still holds) |
| `401` | Missing/expired token | Standard auth refresh |

Do **not** hardcode the group titles or options anywhere — new categories and
option edits ship from the backend with no app release.

---

## 2. Rendering rules

- Render `data.groups` **in array order**, top to bottom.
- Each group: `title` = section header, `options` = chips in the given order.
- `multiSelect: true` → toggle chips (0..n selectable).
- `multiSelect: false` → radio behavior (at most 1 selected — e.g. Loan
  Amount ranges). Selecting a chip deselects the group's previous one.
- Every group is optional; the submit button enables once **any chip is
  selected or a note is typed** (same rule the backend enforces).
- Note + photos sit alongside the groups exactly as today (photos: max 5,
  presign-upload first via `GET /upload/init` — see the main enquiry guide §1).

### Prefetch + cache

Fetch when the listing/detail screen loads (or the Discover tab, one fetch per
category) and cache per category for the session, so the sheet opens
instantly:

```dart
final _cache = <String, List<EnquiryGroup>>{};

Future<List<EnquiryGroup>> optionsFor(String category) async {
  final slug = category.toUpperCase();
  if (_cache.containsKey(slug)) return _cache[slug]!;
  try {
    final res = await dio.get('$otherBase/predefined-enquiry/$slug');
    final groups = (res.data['data']['groups'] as List)
        .map((g) => EnquiryGroup(
              title: g['title'] as String,
              options: List<String>.from(g['options'] ?? const []),
              multiSelect: g['multiSelect'] != false,
            ))
        .toList();
    return _cache[slug] = groups;
  } on DioException {
    return _cache[slug] = const []; // sheet falls back to note + photo only
  }
}
```

---

## 3. Submit — unchanged `POST /other-enquiries`

Build the `selections` map **keyed by each group's `title` exactly as
received** (do not translate/normalise the keys — the chat card renders them
as section headers on both sides):

```json
{
  "business_id": "<BusinessProfile._id>",
  "selections": {
    "Services": ["Home Loan", "Personal Loan"],
    "Loan Amount": ["Under ₹1 L"],
    "Purpose": ["Compare rates"]
  },
  "note": "optional free text",
  "photos": ["https://.../a.jpg"]
}
```

- Omit groups with nothing selected (empty arrays are dropped server-side
  anyway).
- Single-select groups still send an **array** with one value.
- Validation, responses, the in-chat `business_enquiry` card, accept/decline,
  sockets (`newBusinessEnquiryReceived`, `businessEnquiryStatusUpdated`) and
  push are all exactly as documented in `other-enquiry-ui-integration.md`
  §2–§7 — nothing changed there.

---

## 4. End-to-end sequence

1. Listing screen loads → `optionsFor(listing.category)` (cached per category).
2. Customer taps **Enquire** → sheet renders fetched groups (or note-only
   fallback on 404/error).
3. Customer ticks chips / types note / adds photos → **Send Enquiry** →
   `POST /other-enquiries` with the `selections` map keyed by group titles.
4. Existing card flow: owner gets the `business_enquiry` chat card + push,
   accepts/declines, both cards flip via socket.

---

## 5. Integration checklist

1. ☐ Prefetch + cache `GET /predefined-enquiry/{category}` per category; never
   hardcode the chip lists in the app.
2. ☐ Render groups in order; honor `multiSelect` (radio vs toggle).
3. ☐ `404`/error → note-only sheet; submit still requires ≥1 selection or a
   note.
4. ☐ Submit `selections` keyed by the received group `title`s through the
   existing `POST /other-enquiries` call.
5. ☐ No changes to the chat card, sockets, status flow, or lists — already
   integrated.
