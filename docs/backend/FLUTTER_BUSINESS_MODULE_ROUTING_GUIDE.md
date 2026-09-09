ka# Business Profile: Category Slug & Module Routing — Backend Response

**Responding to:** `BUSINESS_OWN_PROFILE_BACKEND_GAPS.txt` (2026-09-09, branch `Development-BlueEra`)
**Backend branch:** `SB/automotive-category-subcategory-tags` (be_user_service)
**Status:** implemented and tested, **not yet deployed** — see [Deployment status](#deployment-status)

---

## TL;DR

GAP 1 and GAP 7 are fixed. The profile response now carries a stable `slug` on
both category and sub-category, plus a `module` string that names the screen to
open. There is a new public endpoint publishing the whole type/category/module
vocabulary so the Dart enum can go away.

**You can delete the token-matching layer** (`BusinessCategoryTokens`,
`doctorToken`, `clinicToken`, `groceryToken`, `healthcareToken`,
`automotiveToken`) and the `.contains()` chain in `_buildBusinessScreen`.

Three of the other gaps are not what the document assumed — details in
[Gap-by-gap response](#gap-by-gap-response). Please read GAP 3, 4 and 6 before
raising them again; the evidence is included.

**One thing we need from you:** sign-off on the module names before you code
against them. Renaming later is a breaking change. See
[Module vocabulary](#module-vocabulary).

---

## What changed in the response

All three fields are **additive**. No existing key changed shape, name or type,
so the currently shipped app keeps working unchanged.

### `category_details` — gains `slug` and `type`

```jsonc
"category_details": {
  "_id":  "665f...",          // unchanged
  "name": "Doctors",          // unchanged — DISPLAY ONLY, an admin may rename it
  "slug": "DOCTORS",          // NEW — stable machine key (Category.tag_id)
  "type": "Healthcare"        // NEW — the Category.type, same vocabulary as type_of_business
}
```

`slug` is the `tag_id` you already have in your own onboarding catalogue
(`OnboardingCategoryModel.slugId`). It was always in the database; it simply was
not being returned on the profile. **Verified against production: all 68 live
categories have a non-null `tag_id`, so `slug` is never null for a real
category.**

### `sub_category_details` — gains `slug`

```jsonc
"sub_category_details": {
  "_id":  "69ac...",
  "name": "Punjabi Veg Restaurant",
  "slug": "PUNJABI_VEG_RESTAURANT"   // NEW — DERIVED, see note
}
```

**Note:** `SubCategory` has no key column in the database — only a display
`name`. The slug is therefore *derived* from the name (uppercase, `&` → `AND`,
non-alphanumerics → `_`). This is the same derivation the backend already
publishes to the catalogue services (Food, Grocery, Automotive) when tagging
products, so a slug you match on here matches what those services tagged with.

Because it is derived, **renaming a sub-category changes its slug.** Treat it as
a normalised form of the name, not as an id. If you need an identifier that
survives a rename, use `_id`.

### `module` — NEW, top-level on `data`

```jsonc
"module": "DOCTOR"
```

This is GAP 7. It names the module the merchant belongs to, resolved server-side
from the canonical category tag, falling back to `type_of_business`.

**`module` can be `null`, and this is a normal answer, not an error.** It means
the backend is not certain, and you must fall back to your generic screen —
exactly the behaviour you have today. This is deliberate: a category added
tomorrow must degrade to "generic dashboard", never to a *wrong* one. Likewise,
**if you receive a module string you do not recognise, fall back to the generic
screen** rather than crashing or guessing. That is what lets us route a new
business type without waiting for an app release.

### Where these appear

| Endpoint | `category_details.slug` | `sub_category_details.slug` | `module` |
|---|:--:|:--:|:--:|
| `GET /business/:id` | yes | yes | yes |
| `GET /business/filter` | yes | — | yes |
| `GET /business/search` | yes | — | yes |

On the list endpoints `category_details` keeps its existing keys and gains
`slug` alongside `tag_id` (they hold the same value; `slug` is the name the
contract uses). `module` is top-level on each list row, so a tap on a card can
route without re-fetching.

---

## Module vocabulary

**These strings are the contract. Please confirm them before coding against
them — renaming one later is a breaking change.**

Derived from your own dispatcher list in the gaps document
(`_buildBusinessScreen`, `bottom_navigation_bar_screen.dart:1139`):

| `module` | Screen it selects today |
|---|---|
| `FOOD` | `FoodMainScreen` |
| `GROCERY` | `GroceryScreen` |
| `EDUCATION` | `SchoolMain` |
| `DOCTOR` | `DoctorMain` |
| `HOSPITAL` | `HospitalMain` |
| `DIAGNOSTIC` | `LaboratoryMain` |
| `PHARMACY` | `MedicalScreen` |
| `HOTEL` | `HotelMain` |
| `PRODUCT` | `ProductScreen` |
| `AUTOMOTIVE_VEHICLE` | `VehicleScreenV3` |
| `AUTOMOTIVE_PARTS` | `AutomotivePartsScreen` |
| `AUTOMOTIVE_SERVICE` | `AutomotiveServiceMain` |
| `MANUFACTURING_GROCERY` | `GroceryScreen` |
| `MANUFACTURING_PHARMA` | `MedicalScreen` |
| `MANUFACTURING_AUTOMOTIVE` | `AutomotivePartsScreen` |
| `MANUFACTURING_PRODUCT` | `ManufacturerProductScreen` |
| `OTHERS` | `OthersMain` |
| `null` | your generic fallback screen |

The four `MANUFACTURING_*` modules are kept distinct even where two map to the
same screen today (`MANUFACTURING_GROCERY` → `GroceryScreen`), because a
manufacturer is not a retailer and you may want to split them later. Mapping two
modules to one screen on your side is fine.

**If any of these names is wrong for you, say so now** — changing them is one
line on our side today and a coordinated release later.

---

## New endpoint: the vocabulary

```
GET /business/module-vocabulary
```

Public, no auth, cacheable. Reference data — identical for every caller, exposes
nothing about any individual business. This is GAP 5.

**Query params**

| Param | Meaning |
|---|---|
| `type` | restrict to one `Category.type` (`Food`, `Healthcare`, …) |
| `unmapped=true` | return only categories with `module: null` (our work queue) |

**Response**

```jsonc
{
  "status": true,
  "data": {
    "modules": ["FOOD", "GROCERY", "EDUCATION", "..."],   // every value you may receive
    "types": [
      {
        "type": "Healthcare",
        "total": 6,
        "mapped": 5,
        "unmapped": 1,
        "categories": [
          { "_id": "…", "name": "Doctors",   "slug": "DOCTORS",   "module": "DOCTOR",   "active": true },
          { "_id": "…", "name": "Hospitals", "slug": "HOSPITALS", "module": "HOSPITAL", "active": true }
        ]
      }
    ],
    "summary": { "totalCategories": 68, "mapped": 67, "unmapped": 1 }
  }
}
```

This is what lets you drop the hardcoded `BusinessType` enum
(`app_enum.dart:50`). Read it at startup (or cache it), and a business type we
add later is routable without an app release.

### Live coverage, read from production on 2026-09-09

| Type | Categories | Mapped | Unmapped |
|---|--:|--:|--:|
| Automotive | 5 | 5 | 0 |
| Finance | 4 | 4 | 0 |
| Food | 10 | 10 | 0 |
| Grocery | 6 | 6 | 0 |
| Healthcare | 6 | 5 | **1** |
| Manufacturing | 4 | 4 | 0 |
| Motel | 5 | 5 | 0 |
| Product | 10 | 10 | 0 |
| Service | 8 | 8 | 0 |
| Siksha | 10 | 10 | 0 |
| **Total** | **68** | **67** | **1** |

The single unmapped category is `ALTERNATIVE_HEALTH` ("Alternative Health",
Healthcare). It is unmapped **on purpose** — the app has no screen for ayurveda
/ homeopathy, and forcing it into `DOCTOR` would be a worse outcome than the
generic screen. Tell us if you add a screen for it and we will map it.

Note also that Healthcare deliberately has **no type-level fallback**: an
unrecognised Healthcare category returns `null` rather than defaulting to, say,
`PHARMACY`. Showing a hospital the medical-store dashboard is worse than showing
it the generic one.

---

## Gap-by-gap response

### GAP 1 — category has no stable id — **FIXED**

`category_details.slug` and `sub_category_details.slug`, as above.

We also found and fixed the **root cause** of why `category_Of_Business` "carries
either the display name or the tag id". One write path,
`updateBusinessAccountUser` in `user.controller.js`, wrote the field straight
from the request body with no tag resolution, while every other write path
resolved it first. So whatever the client happened to send — a display name, an
ObjectId, or a tag_id — was stored verbatim.

That leak also had a second effect you would not have seen: Discover matches on
`tag_id`, so a business updated through that endpoint with a display name
silently disappeared from those listings.

New values written through that path are now normalised. **Existing rows are not
retro-fixed** — but this does not affect you, because `slug` comes from the
resolved Category document, not from the raw stored string.

### GAP 2 — two key spellings — **NOT WHAT IT LOOKS LIKE**

`category_Of_Business` (capital O) and `category_of_business` (lowercase) are
not two HTTP code paths. The lowercase form is the **gRPC proto field name** in
`src/grpc/services/buisnessService.js`, used for service-to-service calls
(map-service and similar). Proto convention is lower_snake_case.

Every HTTP endpoint sends `category_Of_Business`. Your
`json['category_Of_Business'] ?? json['category_of_business']` is harmless but
unnecessary on any HTTP response.

The related items in the same section are real, though minor, and we have not
changed them because the shipped app parses them:

- `_id` / `id` — both are emitted by different endpoints
- `referal_video` / `referral_video` — the typo and the correct spelling both
  exist in production

Tell us if you want either normalised and we will schedule it with a deprecation
window.

### GAP 3 — `"false"` as a string sentinel — **NOT A BACKEND WRITE**

We traced every write path for `Nature_of_Business`. All of them store either
`null` or the raw request body value; none of them produce the string `"false"`.

The literal `"false"` is arriving **from the client** and being stored verbatim.
Worth checking where the app sends `Nature_of_Business: false` (a bool, or a
bool stringified) during onboarding or profile edit.

We can add a normalisation on write (`"false"` → `null`) if you want the
existing rows cleaned. Say the word — we did not do it unprompted because it
changes a value the shipped app currently reads.

The `Capitalised_Like_This` key name is real and we agree it is inconsistent.
Renaming it is a breaking change; happy to do it behind a transition period if
you want it.

### GAP 4 — inconsistent scalar types — **ALREADY CORRECT**

Checked against the schemas:

| Field | Declared type |
|---|---|
| `referral_points` | `Number` (`user.schema.js:63`) |
| `business_location.lat` / `.lon` | `Number` (`business.schema.js:147-148`) |
| `total_ratings` | computed integer |

These are already JSON numbers on the HTTP profile response. Your `.toString()`
and `double.parse(...)` coercions are defensive rather than required.

The `lat`/`lon` string-parsing you cited at `viewBusinessProfileModel.dart:454`
is a **different, nested object** from `business_location` — worth confirming on
your side which payload that parser is actually reading.

### GAP 5 — no server-side contract for `type_of_business` — **FIXED**

`GET /business/module-vocabulary`, above. Option (a) from your document.

### GAP 6 — location routinely missing — **ROOT CAUSE FOUND, NOT FIXED**

This is not a data-quality accident. `business_location` is declared as:

```js
business_location: {
  lat: { type: Number, default: 0 },
  lon: { type: Number, default: 0 },
}
```

The schema **guarantees** `0, 0` for every business that never set a location.
That is why you see so many. Your four-way check (`null` object / `null` lat /
`null` lon / `0.0`) is compensating for the fact that neither side can currently
distinguish "never set" from "actually at 0,0".

The fix is to default these to `null` instead of `0`. **We have not done it** —
it changes a live response shape that the shipped app parses, so it needs to be
coordinated with a client release. Confirm you want it and we will schedule it.

### GAP 7 — nothing tells the client which module to use — **FIXED**

`module`, plus the vocabulary endpoint. Both the "Me" tab dispatcher
(`_buildBusinessScreen`) and the customer-facing `VisitProfileResolver` can
collapse to one flat lookup on `module`, removing the hand-maintained drift you
flagged.

---

## Why substring matching had to go — worked examples

These are your own examples from the document, now covered by regression tests
on our side:

| Input | Old `.contains()` behaviour | New `module` |
|---|---|---|
| Healthcare / `DOCTOR_REFERRAL_SERVICE` | `DOCTOR` — wrong dashboard | not `DOCTOR` |
| Manufacturing / `AUTOMOTIVE_INSURANCE` | `AutomotivePartsScreen` — wrong | not `AUTOMOTIVE_PARTS` |
| Service / `AUTOMOTIVE_SERVICES` (a real live category) | automotive module — wrong | `OTHERS` |
| Healthcare / `ALTERNATIVE_HEALTH` | unpredictable | `null` → generic screen |

The third row is worth noting: `AUTOMOTIVE_SERVICES` is a **live Service
category**, not an Automotive one. Under `.contains("AUTOMOTIVE")` those
merchants would open an automotive dashboard today.

---

## What we need from you

1. **Confirm the module names** in [Module vocabulary](#module-vocabulary)
   before coding against them.
2. **Confirm the fallback contract:** `module: null` *and* any unrecognised
   module string must fall back to your generic screen.
3. **GAP 6** — do you want `business_location` to default to `null` instead of
   `0,0`? It needs a coordinated release.
4. **GAP 3** — do you want us to normalise `"false"` → `null` on write, and/or
   rename `Nature_of_Business`? Also worth finding where the app sends it.
5. **GAP 2 (minor)** — do you want `_id`/`id` and
   `referal_video`/`referral_video` normalised?

---

## Deployment status

**Not deployed yet.** The work is committed on `SB/automotive-category-subcategory-tags`
in be_user_service and is awaiting review and merge to `prod-staging`.

Verified so far:

- 56 unit tests covering the resolver, all passing; full-suite failure count
  unchanged from before the change
- route registration and ordering confirmed (`/module-vocabulary` resolves
  before the `/:id` catch-all)
- resolver run read-only against the production `categories` collection —
  the coverage table above is real data, not a fixture

Not yet verified: an end-to-end HTTP response body from `GET /business/:id`
against a live business. We will confirm on staging before you integrate.

Please **do not ship client code against `module` until we confirm it is live on
staging** — the field will simply be absent until then, which your null-fallback
should already handle safely.

---

*Questions on any of this — especially the module names — please raise before
integrating rather than after.*
