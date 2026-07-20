# Flutter Catalogue Module — Backend Integration Guide

Production integration guide for the Flutter team. The UI already exists — this
document does **not** redesign it. It maps the existing screens/fields to the
backend and defines every API call, payload, and flow.

Every backend fact is taken from the models, routes, controllers and validators
of `be_laboratory_service`. Flutter-side choices (widgets, state management,
folder layout) are engineering recommendations and are marked **RECOMMENDATION**;
anything not provable from the backend is marked **ASSUMPTION**.

- **Base URL (prod):** `https://be.beapp.in/api/lab-service`
- **Auth header:** `Authorization: Bearer <token>` on protected calls.
- **Envelope:** every response is `{ "success": bool, "data"?: ..., "message"?: ... }`.

---

## PART 1 — Understanding the Catalogue module (backend view)

The Catalogue manages **two independent entities**: **Tests** (`PathologyTest`)
and **Packages** (`Package`). They live in separate collections and separate
endpoints. A Package is a **bundle of existing Tests** (`tests: [testId]`,
minimum 1) — it depends on Tests but is otherwise unrelated.

| Screen | Backend behaviour |
|---|---|
| **Catalogue** | Two lists from two endpoints — Tests and Packages are never mixed in one response. |
| **Tests List** | `GET /pathology-tests` (token) → the caller's own tests. |
| **Packages List** | `GET /packages/me` (token) → the caller's own packages, `tests` populated. (NOT `GET /packages` — that is unscoped and returns every lab's.) |
| **Add Test** | Needs 3 dropdown sources first, then `POST /pathology-tests`. |
| **Add Package** | Needs the lab's Tests first, then `POST /packages`. |
| **Edit Test** | `PUT /pathology-tests/{id}` — ownership-scoped, ownership fields stripped. |
| **Edit Package** | `PUT /packages/{id}` — scoped by `{_id, userId}`. |
| **View Test** | `GET /pathology-tests/{id}` — populated refs. |
| **View Package** | `GET /packages/{id}` — `tests` populated (subset of fields). |
| **Delete Test/Package** | `DELETE /{entity}/{id}` — scoped; 404 if not the caller's; hard delete. |

Key consequence for the UI: **the same form cannot serve both.** The two POST
targets, payloads, validators, and dropdown sources are disjoint. Use the
existing UI's separate Add-Test and Add-Package screens; do not fold them.

---

## PART 2 — Screen-by-screen behaviour

### 1. Catalogue
- **Purpose:** entry to Tests and Packages.
- **Opens:** on tab/module entry.
- **API:** loads both lists (see 2 & 5 below). **ASSUMPTION:** the UI shows Tests
  and Packages as two tabs or two sections — load each with its own call.
- **Loader:** per-section shimmer/spinner while each list loads.
- **Success:** render each list.
- **Failure:** per-section error state + retry button.
- **After save/delete elsewhere:** re-fetch the affected list on return.
- **Next:** tapping an item → View; FAB/Add button → Add Test or Add Package.

### 2. Tests List
- **Purpose:** the lab's own tests.
- **API:** `GET /pathology-tests` (token). Optional filter `?groupCategory=...`.
- **Loader:** full-list spinner on first load; pull-to-refresh thereafter.
- **Data:** `data[]` — populated `testCategory`, `testParameters`, `catalogTestId`.
- **Success:** list rows (name, category name, `customerPrice`).
- **Failure:** 401 → re-auth; else error + retry.
- **No pagination** on this endpoint — the whole list returns at once.
- **Next:** row → View Test; Add → Add Test.

### 3. Add Test — see PART 4.
### 4. Edit Test — see PART 9.
### 5. View Test
- **API:** `GET /pathology-tests/{id}` (public). Populated.
- **Data:** all test fields; `testCategory.name`, `testParameters[].name`.
- **Next:** Edit or Delete.

### 6. Packages List
- **Purpose:** the caller's own packages.
- **API:** `GET /packages/me` (token). This is the package equivalent of
  `GET /pathology-tests` — token-scoped to the owner, so no `labId` needed.
- **Data:** `data[]` — `tests` are **populated** to a subset
  (`_id, testName, groupCategory, estimatedReportHours, customerPrice, testFees, specimenCollectionMethod`),
  so you can show `name`, `customerPrice`, and the bundled test names/count
  directly. No second call needed for the list.
- **Do NOT use `GET /packages`** (unscoped — returns every lab's packages) or
  `GET /packages/laboratory/{labId}` (needs a labId and returns raw, unpopulated
  test ids). `GET /packages/me` is the correct owner list.
- **Next:** row → View Package.

> **Dangling tests:** if a package references a test that was later deleted, that
> id simply drops out of the populated `tests` array (the package can show fewer
> tests than its `tests.length`). This is the orphaned-reference case flagged in
> PART 10 — render defensively.

### 7. Add Package — see PART 5.
### 8. Edit Package — see PART 9.
### 9. View Package
- **API:** `GET /packages/{id}` (public). `tests` **populated** to
  `{_id, testName, groupCategory, estimatedReportHours, customerPrice, testFees, specimenCollectionMethod}`.
- **Next:** Edit or Delete.

### 10. Delete Test / Delete Package — see PART 10.

**On success (create/update):** pop back to the list and re-fetch it.
**On delete:** pop/stay and remove the row (or re-fetch).
**On failure:** keep the screen, show the `message` from the response.

---

## PART 3 — Field-by-field guide

### 3A. Test fields

| Field | Widget | Backend field | Req? | Validation | Default | Options API | Payload key |
|---|---|---|---|---|---|---|---|
| Test Name | `TextFormField` | `testName` | ✅ | non-empty | — | — | `testName` |
| Category | `DropdownButtonFormField` | `testCategory` | ✅ | must select | — | `GET /test-categories/laboratory/{labId}` | `testCategory` = `_id` |
| Group Category | `DropdownButtonFormField` | `groupCategory` | ✅ | one of 6 | — | `GET /test-catalog/enums` → `groupCategory` | `groupCategory` |
| Package Type | `DropdownButtonFormField` | `packageType` | ✅ | one of 26 | — | `enums.packageType` | `packageType` |
| Specimen | `DropdownButtonFormField` | `specimen` | ✅ | one of 40 | — | `enums.specimen` | `specimen` |
| Collection Method | `DropdownButtonFormField` | `specimenCollectionMethod` | ✅ | one of 5 | — | `enums.specimenCollectionMethod` | `specimenCollectionMethod` |
| Report Hours | `TextFormField` (number) or `DropdownButtonFormField` | `estimatedReportHours` | ✅ | int > 0 (use 4,6,12,24,48,72) | — | — | `estimatedReportHours` (int) |
| Test Fees (MRP) | `TextFormField` (number) | `testFees` | ✅ | number ≥ 0 | — | — | `testFees` (num) |
| Customer Price | `TextFormField` (number) | `customerPrice` | ✅ | number ≥ 0, ≤ testFees (advisable) | — | — | `customerPrice` (num) |
| Parameters | Multi-select `BottomSheet` (checkbox list) | `testParameters` | ⚪ | each must be the lab's own | `[]` | `GET /test-parameters/laboratory/{labId}` | `testParameters` = `[_id]` |
| Gender | `DropdownButtonFormField` | `gender` | ⚪ | one of 3 | `All` | `enums.gender` | `gender` |
| Organ System | `TextFormField` | `organSystemTested` | ⚪ | — | — | — | `organSystemTested` |
| Description | `TextFormField` (multiline) | `description` | ⚪ | — | — | — | `description` |
| Before Guidance | `TextFormField` (multiline) | `beforeTestGuidance` | ⚪ | — | — | — | `beforeTestGuidance` |
| Post Guidance | `TextFormField` (multiline) | `postTestGuidance` | ⚪ | — | — | — | `postTestGuidance` |
| Test Method | `TextFormField` | `testMethod` | ⚪ | — | — | — | `testMethod` |
| Applicable For Child | `Switch` / `Checkbox` | `applicableForChild` | ⚪ | bool | `false` | — | `applicableForChild` |
| Prescription Required | `Switch` / `Checkbox` | `prescriptionRequired` | ⚪ | bool | `false` | — | `prescriptionRequired` |

**Never send from the Test form:** `userId`, `source`, `catalogTestId`, `_id`,
`laboratoryId` (send only if you have it; it defaults to the caller's lab).

> There is **no** `reportDelivery` and **no** `imageUrl` field on a Test.

### 3B. Package fields

| Field | Widget | Backend field | Req? | Validation | Default | Options API | Payload key |
|---|---|---|---|---|---|---|---|
| Package Name | `TextFormField` | `name` | ✅ | non-empty | — | — | `name` |
| Tests | Searchable multi-select `BottomSheet` | `tests` | ✅ | **≥ 1** selected | — | `GET /pathology-tests` (token) | `tests` = `[testId]` |
| Package MRP | `TextFormField` (number) | `packageMrp` | ✅ | number ≥ 0 | — | — | `packageMrp` |
| Customer Price | `TextFormField` (number) | `customerPrice` | ✅ | number ≥ 0, ≤ MRP (advisable) | — | — | `customerPrice` |
| Description | `TextFormField` (multiline) | `description` | ⚪ | — | — | — | `description` |
| Image | `ImagePicker` → upload → URL | `imageUrl` | ⚪ | valid URL | — | `GET /upload/init` + PUT to S3 | `imageUrl` (publicUrl) |
| Gender | `DropdownButtonFormField` | `gender` | ⚪ | one of 3 | `All` | `enums.gender` (reuse) | `gender` |
| Active | `Switch` | `isActive` | ⚪ | bool | `true` | — | `isActive` |

**Never send from the Package form:** `userId`, `laboratoryId` (both from token).
Also do not send any Test-only field (`groupCategory`, `packageType`, `specimen`,
`testCategory`, `estimatedReportHours`) — they are silently ignored.

---

## PART 4 — Add Test screen (sections)

```
Basic Information → Category → Parameters → Pricing → Guidance → Save
```

- **Basic Information:** `testName` (TextFormField), `description` (multiline),
  `organSystemTested`, `testMethod`.
- **Category:** three `DropdownButtonFormField`s from `GET /test-catalog/enums`
  (`groupCategory`, `packageType`, `specimen`), one for
  `specimenCollectionMethod`, one for `gender`, plus the lab-scoped
  `testCategory` dropdown from `GET /test-categories/laboratory/{labId}` (submit `_id`).
- **Parameters:** multi-select bottom sheet from
  `GET /test-parameters/laboratory/{labId}` → submit `[_id]`.
- **Pricing:** `estimatedReportHours` (int; recommend a dropdown of
  4/6/12/24/48/72), `testFees`, `customerPrice`.
- **Guidance:** `beforeTestGuidance`, `postTestGuidance`, and the two `Switch`
  toggles (`applicableForChild`, `prescriptionRequired`).
- **Save button:** validates locally, then `POST /pathology-tests`.

Dropdown-loading APIs (call before/while opening the screen): `/test-catalog/enums`,
`/test-categories/laboratory/{labId}`, `/test-parameters/laboratory/{labId}` — all
three can run in parallel.

---

## PART 5 — Add Package screen (sections)

```
Basic Information → Test Selection → Pricing → Image → Save
```

- **Basic Information:** `name`, `description`, `gender`.
- **Test Selection:** load `GET /pathology-tests` (token) → the lab's own tests.
- **Pricing:** `packageMrp`, `customerPrice`.
- **Image:** `ImagePicker` → `GET /upload/init?fileName=&fileType=` returns
  `{ uploadUrl, publicUrl, fileKey }` → `PUT` the bytes to `uploadUrl` → put
  `publicUrl` in `imageUrl`.
- **Save:** local validation (`tests` ≥ 1), then `POST /packages`.

### Which widget for Test Selection?

**RECOMMENDATION: a searchable multi-select BottomSheet (checkbox list with a
search field).** Reasons grounded in the backend:

- `tests` is an **array** with **min 1** and no maximum → needs multi-select, not
  a single `Dropdown`.
- `GET /pathology-tests` returns **all** of the lab's tests in one response with
  **no pagination** and **no server-side search** → a client-side search filter
  over the loaded list is the correct fit (no need for a dedicated search
  screen or server paging).
- Each row shows `testName` + `customerPrice`; the submit value is `_id`.

Not suitable: single `Dropdown` (can't multi-select), plain `Checkbox` list
without search (fine for a handful of tests, poor once the lab has many). A full
Search Screen is over-engineering because the dataset is already fully loaded.

---

## PART 6 — API integration per screen

| Screen | Method | Endpoint | Headers | Body | Success | Error |
|---|---|---|---|---|---|---|
| Tests List | GET | `/pathology-tests` | Bearer | — | `data[]` | 401→login; else retry |
| View Test | GET | `/pathology-tests/{id}` | — | — | `data` | 404→"not found" |
| Add Test | POST | `/pathology-tests` | Bearer, JSON | test payload | 201 `data` | 400/403 show `message` |
| Edit Test | PUT | `/pathology-tests/{id}` | Bearer, JSON | changed fields | 200 `data` | 404/400 |
| Delete Test | DELETE | `/pathology-tests/{id}` | Bearer | — | 200 | 404 |
| Enums | GET | `/test-catalog/enums` | — | — | 5 arrays | retry |
| Categories | GET | `/test-categories/laboratory/{labId}` | — | — | `data[]` | retry |
| Parameters | GET | `/test-parameters/laboratory/{labId}` | — | — | `data[]` | retry |
| Packages List | GET | `/packages/me` | Bearer | — | `data[]` (tests populated) | 401→login; else retry |
| View Package | GET | `/packages/{id}` | — | — | `data` (tests populated) | 404 |
| Add Package | POST | `/packages` | Bearer, JSON | package payload | 201 `data` | 400/401 |
| Edit Package | PUT | `/packages/{id}` | Bearer, JSON | changed fields | 200 `data` | 404/400 |
| Delete Package | DELETE | `/packages/{id}` | Bearer | — | 200 | 404 |
| Image init | GET | `/upload/init?fileName=&fileType=` | — | — | `{uploadUrl,publicUrl,fileKey}` | retry |

- **Loading state:** per-request boolean; disable Save while POST/PUT in flight.
- **Error state:** show the `message` string; it is written to be user-facing.
- **Retry:** GET calls are safe to retry. **POST is NOT idempotent — never
  auto-retry a create** (it makes a duplicate). Guard the button instead.
- **Refresh:** on returning from Add/Edit/Delete, re-fetch the affected list.
- **Navigation:** on 201/200 → pop to list + refresh; on 401 → auth flow.

---

## PART 7 — GET-API flow (when, why, how often, caching)

| API | When | How often | Cache |
|---|---|---|---|
| `GET /pathology-tests` | Tests List open; also before opening Add/Edit **Package** (the test picker) | on open + pull-to-refresh + after any test create/edit/delete | short-lived in memory; invalidate on any test mutation |
| `GET /packages/me` | Packages List open | on open + pull-to-refresh + after any package create/edit/delete | in memory; invalidate on package mutation |
| `GET /packages/laboratory/{labId}` | only a **public** view of some *other* lab's packages | rarely | — |
| `GET /packages/{id}` | View/Edit Package open | per open | none (always fresh — shows populated tests) |
| `GET /test-catalog/enums` | before Add/Edit **Test** | **once per session** | **cache aggressively** — static vocabulary, no DB hit |
| `GET /test-categories/laboratory/{labId}` | before Add/Edit Test | once per session (per lab) | cache per session; refresh if a category is added |
| `GET /test-parameters/laboratory/{labId}` | before Add/Edit Test | once per session (per lab) | cache per session |
| `GET /packages` | **never for a lab's own list** — it is unscoped | — | — |

**Caching strategy:** enums and the lab's categories/parameters change rarely →
load once, keep for the session. Lists (tests, packages) change on every mutation
→ cache in memory but invalidate and re-fetch after create/update/delete.

---

## PART 8 — Create flow

### Add Test

```
User taps "Add Test"
        ↓
Parallel GET:  /test-catalog/enums
               /test-categories/laboratory/{labId}
               /test-parameters/laboratory/{labId}
        ↓
Fill form (enum strings; category _id; parameter _ids)
        ↓
Local validation (required + enum + numbers)
        ↓
POST /pathology-tests   (Bearer)
        ↓
201  →  pop back
        ↓
Re-fetch GET /pathology-tests
        ↓
Show new test in Tests List
```

### Add Package

```
User taps "Add Package"
        ↓
GET /pathology-tests   (Bearer)  → the test picker
        ↓
(optional) pick image → GET /upload/init → PUT to S3 → publicUrl
        ↓
Fill form (name, select tests ≥1, packageMrp, customerPrice)
        ↓
Local validation (tests.length ≥ 1, numbers)
        ↓
POST /packages   (Bearer)
        ↓
201  →  pop back
        ↓
Re-fetch GET /packages/me
        ↓
Show new package in Packages List
```

---

## PART 9 — Edit flow

Same as create, with two differences:

1. **Prefill:** open with the existing document.
    - Test: use the row you already have, or `GET /pathology-tests/{id}`. The refs
      come populated — map `testCategory._id` and `testParameters[]._id` back into
      the dropdown/multi-select selections.
    - Package: `GET /packages/{id}` (tests populated) → preselect `tests[]._id`.
2. **Submit:** `PUT /{entity}/{id}` with **only changed fields** (or the full
   editable set — both work).
    - Test PUT strips `_id`/`userId`/`laboratoryId` server-side; if you change
      `testCategory`/`testParameters` they must belong to the lab (else 400).
    - Package PUT is scoped by `{_id, userId}` and re-runs validators (so `tests`
      must still be ≥ 1).
3. **Response:** 200 with updated `data`. **404** means the item isn't the
   caller's — treat as "not found / not yours".
4. After success → pop + refresh the list.

---

## PART 10 — Delete flow

```
User taps Delete
        ↓
Confirmation dialog (AlertDialog)   ← client-side; there is no soft-delete
        ↓
DELETE /pathology-tests/{id}   or   DELETE /packages/{id}   (Bearer)
        ↓
200  →  remove row from list (or re-fetch)
        ↓
404  →  "Not found or not yours" — the scope did not match
```

- Both deletes are **hard deletes**, scoped to the caller. A test that is part of
  a package can still be deleted — the package keeps the now-dangling id.
  **ASSUMPTION:** the backend does not block deleting a test referenced by a
  package; warn the user if you want to prevent orphaned package references.

---

## PART 11 — Catalogue screen (strictly per backend)

- **Two APIs, never one.** Tests and Packages come from different endpoints and
  different collections. No endpoint returns both, and there is **no `type`
  field** to distinguish them — the endpoint you call *is* the type.
- **Separate sections or tabs.** Load Tests via `GET /pathology-tests` and
  Packages via `GET /packages/me`, render as two lists.
- Do **not** attempt a merged list from a single call — it does not exist.

---

## PART 12 — Flutter project structure (RECOMMENDATION)

```
lib/features/catalogue/
├── models/
│   ├── pathology_test.dart        # PathologyTest + fromJson/toJson
│   ├── package.dart               # Package + fromJson/toJson
│   ├── test_enums.dart            # the 5 enum lists from /test-catalog/enums
│   ├── test_category.dart
│   └── test_parameter.dart
├── services/
│   └── catalogue_api.dart         # raw Dio calls, one method per endpoint
├── repository/
│   └── catalogue_repository.dart  # maps API JSON → models; owns caching
├── controllers/  (or providers/)
│   ├── tests_controller.dart      # list + create/edit/delete test state
│   ├── packages_controller.dart   # list + create/edit/delete package state
│   └── form_options_controller.dart # enums + categories + parameters (cached)
├── screens/
│   ├── catalogue_screen.dart
│   ├── add_edit_test_screen.dart
│   ├── add_edit_package_screen.dart
│   ├── view_test_screen.dart
│   └── view_package_screen.dart
├── widgets/
│   ├── test_list_tile.dart
│   ├── package_list_tile.dart
│   ├── enum_dropdown.dart
│   └── price_row.dart
├── bottom_sheets/
│   ├── parameter_multiselect_sheet.dart
│   └── test_multiselect_sheet.dart
├── dialogs/
│   └── confirm_delete_dialog.dart
└── utils/
    ├── validators.dart
    └── image_uploader.dart        # /upload/init + PUT to S3
```

**Responsibilities:** `services` = thin HTTP; `repository` = JSON↔model +
caching + which-endpoint decisions (e.g. never call `GET /packages`);
`controllers` = state (loading/error/data/selection); `screens` = existing UI;
`widgets`/`bottom_sheets`/`dialogs` = reusable pieces; `utils` = validation +
image upload.

---

## PART 13 — State management (RECOMMENDATION)

This module is CRUD-over-REST: a few lists, two forms, cached lookups. Any of
Riverpod / Bloc(Cubit) / GetX works; the backend does not dictate one.

**Recommended: Riverpod (or Cubit if the team prefers Bloc).** Why it fits this
module:
- Async lists map cleanly to `AsyncNotifier`/`FutureProvider` (loading/error/data
  for free).
- The cached lookups (enums, categories, parameters) are a natural
  keep-alive/`FutureProvider` — load once, reuse.
- Form selection state (selected category, selected parameter ids, selected test
  ids) is local `StateNotifier`/`Notifier` state.
- Invalidation after a mutation is one `ref.invalidate(testsProvider)` call — the
  refresh-after-save pattern the backend forces (no server push).

State to hold:
- **Loading / Error:** per async provider (`AsyncValue`).
- **Selected Test / Package:** the model being viewed/edited.
- **Selected Tests (package):** `Set<String>` of test `_id`s.
- **Refresh:** `ref.invalidate(...)` after create/edit/delete.
- **Pagination:** **not needed** — `GET /pathology-tests` and
  `/packages/me` return full lists with no paging. (Only the
  admin endpoint pages; not used here.)

---

## PART 14 — Frontend validation (mirror the backend)

**Test:**
- `testName` — required, non-empty.
- `testCategory` — required; must be a selected id from the lab's categories.
- `groupCategory`, `packageType`, `specimen`, `specimenCollectionMethod` —
  required; must equal a value from `/test-catalog/enums` (use the loaded list,
  never free text).
- `estimatedReportHours` — required; integer > 0.
- `testFees`, `customerPrice` — required; numbers ≥ 0. (Advisable:
  `customerPrice ≤ testFees`.)
- `testParameters` — optional; each must be an id from the lab's parameters.
- `gender` — one of `Male/Female/All`; default `All`.

**Package:**
- `name` — required, non-empty.
- `tests` — required; **at least 1** id.
- `packageMrp`, `customerPrice` — required; numbers ≥ 0. (Advisable:
  `customerPrice ≤ packageMrp`.)
- `gender` — one of `Male/Female/All`; default `All`.
- `imageUrl` — optional; if set, a valid URL from the upload step.

Client validation is a UX layer — the backend re-validates and returns `400`
with a `message` naming the field; always surface that too.

---

## PART 15 — Payload mapping

### Test

| Flutter widget | Backend field | Payload key | Required | Type |
|---|---|---|---|---|
| TextFormField | testName | `testName` | ✅ | String |
| Dropdown (categories) | testCategory | `testCategory` | ✅ | ObjectId (String) |
| Dropdown (enums) | groupCategory | `groupCategory` | ✅ | String enum |
| Dropdown (enums) | packageType | `packageType` | ✅ | String enum |
| Dropdown (enums) | specimen | `specimen` | ✅ | String enum |
| Dropdown (enums) | specimenCollectionMethod | `specimenCollectionMethod` | ✅ | String enum |
| Number field/Dropdown | estimatedReportHours | `estimatedReportHours` | ✅ | int |
| Number field | testFees | `testFees` | ✅ | num |
| Number field | customerPrice | `customerPrice` | ✅ | num |
| Multiselect sheet | testParameters | `testParameters` | ⚪ | [ObjectId] |
| Dropdown (enums) | gender | `gender` | ⚪ | String enum (def All) |
| TextFormField | organSystemTested | `organSystemTested` | ⚪ | String |
| TextFormField | description | `description` | ⚪ | String |
| TextFormField | beforeTestGuidance | `beforeTestGuidance` | ⚪ | String |
| TextFormField | postTestGuidance | `postTestGuidance` | ⚪ | String |
| TextFormField | testMethod | `testMethod` | ⚪ | String |
| Switch | applicableForChild | `applicableForChild` | ⚪ | bool (def false) |
| Switch | prescriptionRequired | `prescriptionRequired` | ⚪ | bool (def false) |

### Package

| Flutter widget | Backend field | Payload key | Required | Type |
|---|---|---|---|---|
| TextFormField | name | `name` | ✅ | String |
| Multiselect sheet | tests | `tests` | ✅ (≥1) | [ObjectId] |
| Number field | packageMrp | `packageMrp` | ✅ | num |
| Number field | customerPrice | `customerPrice` | ✅ | num |
| TextFormField | description | `description` | ⚪ | String |
| ImagePicker→upload | imageUrl | `imageUrl` | ⚪ | String (URL) |
| Dropdown (enums) | gender | `gender` | ⚪ | String enum (def All) |
| Switch | isActive | `isActive` | ⚪ | bool (def true) |

---

## PART 16 — Existing-UI behaviour (no redesign)

- **User taps Add Test:** open the existing Add-Test screen; fire the 3 dropdown
  GETs (enums, categories, parameters) while the screen animates in; disable Save
  until they resolve.
- **User taps Add Package:** open the existing Add-Package screen; fire
  `GET /pathology-tests` for the picker; disable Save until it resolves.
- **User edits Test:** open the same form prefilled from the test; map
  `testCategory._id` and `testParameters[]._id` into the selections; submit via
  `PUT`.
- **User edits Package:** open the same form prefilled from `GET /packages/{id}`;
  preselect `tests[]._id`; submit via `PUT`.
- **User selects Tests (package):** open the existing multi-select control; store
  the chosen `_id`s in a `Set<String>`; enforce ≥1 before enabling Save.
- **User saves:** run local validation → disable Save → POST/PUT → on 2xx pop +
  refresh the list; on 4xx keep the screen and show `message`.
- **User deletes:** existing confirm dialog → DELETE → remove row / refresh.
- **User refreshes:** pull-to-refresh re-calls the list endpoint; enums/categories
  /parameters can stay cached.

Nothing above changes the layout — it only wires existing controls to calls.

---

## PART 17 — Implementation order

1. **API service** (`catalogue_api.dart`) — one Dio method per endpoint in PART 6;
   attach the bearer token via an interceptor.
2. **Models** — `PathologyTest`, `Package`, `TestEnums`, `TestCategory`,
   `TestParameter` with `fromJson`/`toJson`. `toJson` must **omit** the
   never-send fields.
3. **Repository** — JSON↔model, caching for enums/categories/parameters, and the
   rule "owner packages list = `/packages/me`, never the unscoped `/packages`".
4. **Controllers/providers** — tests list, packages list, form-options,
   selection state.
5. **Tests List + View Test** wired to GET.
6. **Add/Edit Test** — dropdowns + parameters multiselect + POST/PUT.
7. **Packages List + View Package** wired to GET.
8. **Add/Edit Package** — test multiselect + image upload + POST/PUT.
9. **Validation** (PART 14) + **Delete** flows with confirm dialog.
10. **Integration + testing** — verify the payload keys exactly match PART 15;
    confirm refresh-after-mutation; verify 401/403/400/404 handling.

---

## PART 18 — Final summary (read in 2 minutes)

```
CATALOGUE
   ├── Tests  ← GET /pathology-tests            (token, full list, no paging)
   └── Packages ← GET /packages/me                 (NOT GET /packages)

ADD TEST
   tap → GET /test-catalog/enums
       + GET /test-categories/laboratory/{labId}
       + GET /test-parameters/laboratory/{labId}
   → fill (enum strings, category _id, parameter _ids)
   → validate → POST /pathology-tests
   → 201 → refresh GET /pathology-tests → back

ADD PACKAGE
   tap → GET /pathology-tests           (the test picker)
   → (optional) image: GET /upload/init → PUT S3 → publicUrl
   → fill (name, tests ≥1, packageMrp, customerPrice)
   → validate → POST /packages
   → 201 → refresh GET /packages/me → back

EDIT   = same screen, prefilled → PUT /{entity}/{id}   (404 = not yours)
DELETE = confirm → DELETE /{entity}/{id}               (hard delete, scoped)

NEVER send:  test → userId, source, catalogTestId, _id
             package → userId, laboratoryId
IDS:  testCategory=_id, testParameters=[_id], package tests=[testId]
RULE: Test and Package are separate entities — separate forms, separate lists.
```

### Golden rules
1. Test and Package never share a payload, endpoint, or form.
2. Category/parameter/test ids must be the **lab's own** (`/laboratory/{labId}` +
   `/pathology-tests`) — never the unscoped lists.
3. Enum dropdowns come from `/test-catalog/enums`, cached once.
4. Use `/packages/me` for the owner's packages — `/packages` is
   unscoped.
5. Nothing is an upsert — never auto-retry a POST; refresh the list after every
   mutation.
