# `POST /pathology-tests` — Create a test manually

Everything the create-test form needs: every field, where its value comes from,
and which API to fetch it from. Follow this and the request cannot fail.

**Full endpoint**

```
POST https://be.beapp.in/api/lab-service/pathology-tests
Authorization: Bearer <lab owner's token>
Content-Type: application/json
```

> Use this only when the test is **not in the master catalog**. If it is, use
> `POST /test-catalog/select` instead — that fills every field for you from the
> catalog's 602 tests and creates the category and parameters automatically. This
> endpoint is the manual fallback; the test it creates gets `source: "manual"`.

---

## 1. The 4 calls you must make first

Never hardcode these, and never guess an id.

```
1. GET /laboratory-profiles/user/{userId}        -> laboratoryId
2. GET /test-catalog/enums                       -> every dropdown's options
3. GET /test-categories/laboratory/{labId}       -> the Category dropdown
4. GET /test-parameters/laboratory/{labId}       -> the Parameters multi-select
```

Steps 3 and 4 **must** be the `/laboratory/{labId}` variants. See §4 — this is
where the real damage happens.

### 1.1 `GET /laboratory-profiles/user/{userId}`

```json
{ "success": true, "data": { "_id": "6a4caad7978c6634c0988871", "name": "My Laboratory" } }
```

`data._id` → your `laboratoryId`. Everything below hangs off it.

### 1.2 `GET /test-catalog/enums`

Public, no token, no DB hit. Returns exactly what the schema accepts:

```json
{
  "success": true,
  "data": {
    "groupCategory": ["Blood & Routine Tests", "..."],              // 6
    "packageType": ["Basic Blood Test", "Pathology", "..."],        // 26
    "specimen": ["Blood", "Urine", "Swab", "..."],                  // 40
    "specimenCollectionMethod": ["Hospital","Home","Laboratory","Other","All"],
    "gender": ["Male", "Female", "All"]
  }
}
```

Read straight from the constants both models validate against, so it can never
drift from what a POST accepts. Fetch once, cache for the session.

> **Not the same as `GET /test-catalog/filters`.** That returns values *present in
> the data* — right for filter chips, wrong for a create form. The catalog uses
> only 17 of the 26 packageTypes, but all 26 are legal on a new test. **Use
> `/enums` for this form.**

### 1.3 `GET /test-categories/laboratory/{labId}`

```json
{ "success": true, "data": [ { "_id": "6a4caad7978c6634c0988874", "name": "Hematology" } ] }
```

32 categories, pre-seeded for your lab. Send the `_id`.

### 1.4 `GET /test-parameters/laboratory/{labId}`

```json
{ "success": true, "data": [ { "_id": "6a4caada978c6634c09888e3", "name": "MCV", "unit": "fL" } ] }
```

Send an array of `_id`s.

---

## 2. Every field

### Required — a missing one is a 400

| Field | Type | Where it comes from |
|---|---|---|
| `testName` | String | User types it |
| `laboratoryId` | **ObjectId** | §1.1 → `data._id` |
| `testCategory` | **ObjectId** | §1.3 → the selected category's `_id`. **Not the name** |
| `groupCategory` | String enum | §1.2 → `data.groupCategory` (6) |
| `packageType` | String enum | §1.2 → `data.packageType` (26) |
| `specimen` | String enum | §1.2 → `data.specimen` (40) |
| `specimenCollectionMethod` | String enum | §1.2 → `data.specimenCollectionMethod` (5) |
| `estimatedReportHours` | Number | User. Whole hours — 4, 6, 12, 24, 48, 72 are the realistic set |
| `testFees` | Number | User. The **MRP / list price** |
| `customerPrice` | Number | User. What the customer **actually pays** — normally **lower** than `testFees` (66–80% of it across the catalog) |

### Optional

| Field | Type | Where it comes from |
|---|---|---|
| `testParameters` | **[ObjectId]** | §1.4 → array of `_id`s. `[]` is fine |
| `gender` | String enum | §1.2 → `data.gender`. Defaults to `All` |
| `organSystemTested` | String | User. e.g. `Liver` |
| `description` | String | User |
| `beforeTestGuidance` | String | User. e.g. `10-12 hours fasting required.` |
| `postTestGuidance` | String | User |
| `testMethod` | String | User. e.g. `ELISA`, `Photometry` |
| `applicableForChild` | Boolean | Defaults `false` |
| `prescriptionRequired` | Boolean | Defaults `false` |

### Never send these

| Field | Why |
|---|---|
| `userId` | Taken from your token. Sending it lets you stamp someone else's id on the test — don't |
| `source` | Set to `"manual"` automatically |
| `catalogTestId` | `null` for a manual test |
| `_id` | Generated |

---

## 3. The three category fields are different things

This is the most common error on this endpoint. They are **three separate
vocabularies with zero overlap**:

| Field | What it is | Values | Type |
|---|---|---|---|
| `groupCategory` | The UI's top-level **tab** | **6** — `Blood & Routine Tests` … | String |
| `packageType` | Which **package** it sells under | **26** — `Basic Blood Test`, `Pathology`, `Radiology` … | String |
| `testCategory` | The medical **department** | Your lab's 32 | **ObjectId** |

```jsonc
// WRONG — a groupCategory value in the packageType field
"groupCategory": "Blood & Routine Tests",
"packageType":   "Blood & Routine Tests"   // -> 400

// RIGHT
"groupCategory": "Blood & Routine Tests",
"packageType":   "Pathology"
```

`"Blood & Routine Tests"` is **never** a valid `packageType`. If one dropdown is
feeding both fields, every submit will fail. They need two dropdowns from two
different arrays — `data.groupCategory` and `data.packageType`.

---

## 4. ⚠️ Use the lab-scoped category/parameter endpoints

```
GET /test-categories        ← returns EVERY lab's categories (257 docs)
GET /test-parameters        ← same
```

There are **8 different "Hematology" categories** in the database — one per lab.
If the form fetches the unscoped list and picks the first row named
`"Hematology"`, it gets **another laboratory's id**.

```
6a4a835d73b65aef98f55de2   Hematology   lab 6a4a835d73b65aef98f55ddf   ← someone else's
6a4b8a6573b65aef98f55eec   Hematology   lab 6a4b8a6573b65aef98f55ee9   ← someone else's
6a4caad7978c6634c0988874   Hematology   lab 6a4caad7978c6634c0988871   ← yours
```

**This produces no error.** The backend does not currently verify that
`testCategory` and `testParameters` belong to your lab, so the test is created
successfully — pointing at another lab's records. It is silent corruption, and
it already exists in production data.

**Always use the scoped endpoints:**

```
GET /test-categories/laboratory/{labId}
GET /test-parameters/laboratory/{labId}
```

---

## 5. A complete working request

```http
POST https://be.beapp.in/api/lab-service/pathology-tests
Authorization: Bearer <token>
Content-Type: application/json
```

```json
{
  "testName": "Custom Hematology Panel",
  "laboratoryId": "6a4caad7978c6634c0988871",
  "testCategory": "6a4caad7978c6634c0988874",
  "testParameters": ["6a4caada978c6634c09888e3"],
  "groupCategory": "Blood & Routine Tests",
  "packageType": "Pathology",
  "specimen": "Swab",
  "specimenCollectionMethod": "Home",
  "estimatedReportHours": 12,
  "gender": "Male",
  "organSystemTested": "Blood",
  "description": "Comprehensive haematology screen.",
  "beforeTestGuidance": "No fasting required.",
  "postTestGuidance": "No special care needed.",
  "testMethod": "Automated Cell Counter",
  "applicableForChild": false,
  "prescriptionRequired": true,
  "testFees": 100,
  "customerPrice": 60
}
```

**Success — `201`:**

```json
{ "success": true, "data": { "_id": "...", "source": "manual", "catalogTestId": null } }
```

---

## 6. Every error, and what causes it

| Message | Cause | Fix |
|---|---|---|
| `packageType: 'Blood & Routine Tests' is not a valid enum value` | A `groupCategory` value in `packageType` | §3 — two separate dropdowns |
| `specimen: 'Plasma' is not a valid enum value` | Not one of the 40 | Use `data.specimen` from `/enums` |
| `Cast to ObjectId failed for value "Hematology"` | Sent the category **name** instead of its `_id` | Send `_id` |
| `Path 'testFees' is required` | Missing a required field | §2 |
| `laboratoryId does not belong to your laboratory` (**403**) | Someone else's `laboratoryId` | Use §1.1. Omit it entirely and it defaults to your lab |
| `Not authorized, no token provided` (**401**) | No `Authorization` header | Send the token |

All errors share one shape — show `message` directly, it names the field:

```json
{ "success": false, "message": "..." }
```

**No error, but wrong:** a `testCategory` or `testParameters` id from another lab
(§4). Nothing rejects it today.

---

## 7. Form build order

```js
// once, on mount
const labId  = (await get(`/laboratory-profiles/user/${userId}`)).data._id;
const enums  = (await get(`/test-catalog/enums`)).data;
const cats   = (await get(`/test-categories/laboratory/${labId}`)).data;
const params = (await get(`/test-parameters/laboratory/${labId}`)).data;

// dropdowns — note each has its OWN source
<Select options={enums.groupCategory}            value={form.groupCategory} />
<Select options={enums.packageType}              value={form.packageType} />   // NOT enums.groupCategory
<Select options={enums.specimen}                 value={form.specimen} />
<Select options={enums.specimenCollectionMethod} value={form.specimenCollectionMethod} />
<Select options={enums.gender}                   value={form.gender} />
<Select options={cats}   labelKey="name" valueKey="_id" value={form.testCategory} />   // send _id
<MultiSelect options={params} labelKey="name" valueKey="_id" value={form.testParameters} />

// submit
await post('/pathology-tests', { ...form, laboratoryId: labId });
// do NOT include userId — it comes from the token
```

Two rules that prevent every error above:

1. **Every dropdown reads its own array.** `packageType` never reads
   `enums.groupCategory`.
2. **Categories and parameters always come from the `/laboratory/{labId}`
   endpoints**, and you send the `_id`, never the name.

---

## 8. After it succeeds

The new test appears in:

- `GET /pathology-tests` — your own menu (token-scoped)
- `GET /pathology-tests/laboratory/{labId}` — the public listing customers see

It will **not** appear as `alreadyAdded` in `GET /test-catalog`, because a manual
test is not a catalog test. That is expected.

`POST /pathology-tests` is a plain insert, not an upsert — **submitting twice
creates two tests**. Disable the button while the request is in flight.
