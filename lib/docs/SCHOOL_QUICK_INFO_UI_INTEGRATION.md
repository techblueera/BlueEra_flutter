# Quick Info by Category — UI Integration Guide

How the frontend renders the **Quick Info** form for each education category
without hardcoding which fields belong to which category.

All six level-0 Siksha categories share one listing collection in
**be_education_service**, but each shows a different set of Quick Info fields.
The backend now owns that mapping and serves it over one endpoint, so adding a
field or a suggestion is a **backend change only** — no frontend release.

> Every list is a **suggestion for the input**, not validation. All Quick Info
> fields are free text, so an `"Other"` / custom value the user types still
> saves. The backend validates shape only (non-empty, length) and **never
> rejects a field for belonging to another category**.

---

## 1. Base URL & auth

- Service: **be_education_service**
- Routes mounted at root → base path is **`/schools`**
- `GET /schools/options` — **no auth**, public reference data.
- `GET /schools/:id/quick-info` — no auth.
- `PUT /schools/:id/quick-info` — **owner only**, send the bearer token.

---

## 2. The six categories and their fields

Category names match the business categories in be_user_service. Six categories
collapse into four field sets — school and coaching share one, professional and
skill training share another.

| Category | Fields (in render order) |
|---|---|
| **School Education** | `classRange`, `studentTeacherRatio`, `board`, `mediumOfInstruction`, `numberOfStudents` |
| **Coaching/Institute** | *same as School Education* |
| **College/University** | `classRange`, `studentTeacherRatio`, `coursesOffered`, `affiliatedUniversity`, `streams`, `numberOfStudents` |
| **Sports & Hobby** | `sportsOffered`, `sportsFacilities`, `achievements`, `numberOfStudents` |
| **Professional Learn** | `skillPrograms`, `industryPartnerships`, `certifications`, `numberOfStudents` |
| **Skill Training** | *same as Professional Learn* |

**Do not hardcode this table.** Fetch it — it is exactly what
`GET /schools/options?category=...` returns.

### Field types

| Field | Type | Notes |
|---|---|---|
| `classRange` | string | max 100, e.g. `"Class 1 - 12"` |
| `studentTeacherRatio` | string | must match `number:number`, e.g. `"1:20"` |
| `affiliatedUniversity` | string | max 200, **single value, not a list** |
| `numberOfStudents` | number | non-negative |
| everything else | string array | max 100 chars per entry; trimmed and deduped on save |

---

## 3. Endpoints

| Method | Path | Who | Purpose |
|---|---|---|---|
| `GET` | `/schools/options?category=<name>` | anyone | Fields + suggestions for one category |
| `GET` | `/schools/options` | anyone | All categories at once (+ legacy boards/mediums) |
| `GET` | `/schools/:id/quick-info` | anyone | A listing's saved values **and** its field set |
| `PUT` | `/schools/:id/quick-info` | owner | **Partial** save — recommended for the edit form |
| `POST` | `/schools` | authed | Create a listing; may include `quickInfo` inline |
| `PUT` | `/schools/:id` | owner | Update a listing; **replaces** `quickInfo` wholesale |

All four write paths apply the same validation and trim/dedupe normalization.
The difference is merge behaviour: `PUT /schools/:id/quick-info` merges onto
what is stored, while `PUT /schools/:id` replaces the whole `quickInfo` object —
so send every field you want to keep, or prefer the quick-info route.

---

## 4. Render the form — `GET /schools/options?category=`

### Request

```
GET /schools/options?category=Sports%20%26%20Hobby
```

The category is matched tolerantly: casing, spacing and punctuation are ignored,
and short aliases work (`College` → `College/University`, `Coaching` →
`Coaching/Institute`).

### Response — `200 OK`

```json
{
  "success": true,
  "data": {
    "category": "Sports & Hobby",
    "group": "sports",
    "fields": [
      {
        "key": "sportsOffered",
        "label": "Sports Offered",
        "type": "stringArray",
        "placeholder": "Add available sports",
        "suggestions": ["Cricket", "Football", "Basketball", "Volleyball"]
      },
      {
        "key": "sportsFacilities",
        "label": "Sports Facilities",
        "type": "stringArray",
        "placeholder": "Add available sports facilities",
        "suggestions": ["Playground", "Indoor Stadium", "Gym", "Swimming Pool"]
      },
      {
        "key": "achievements",
        "label": "Achievements",
        "type": "stringArray",
        "placeholder": "Add sports achievements",
        "suggestions": ["State Champion", "National Participation", "Inter-College Winners"]
      },
      {
        "key": "numberOfStudents",
        "label": "Student Strength",
        "type": "number",
        "placeholder": "Add the total number of students",
        "suggestions": []
      }
    ]
  }
}
```

### Reading a descriptor

- `key` — the `quickInfo` property to write. Send it back under this exact name.
- `label` — the input's heading.
- `type` — `stringArray` → chip/tag input; `string` → text input; `number` → numeric input.
- `placeholder` — the helper text under the heading.
- `suggestions` — chips/dropdown options. Empty means free text only. **Never a
  closed set** — always allow a custom value.
- `group` — `school` | `college` | `sports` | `professional`, or `null` when the
  category is unrecognised (in which case every field is returned so the form
  still works). Informational; render from `fields`.

Order is meaningful — render in the order received. The list can grow, so never
assume a fixed length.

---

## 5. All categories at once — `GET /schools/options`

Use when you want to cache everything on app start instead of per category.

```json
{
  "success": true,
  "data": {
    "boards": ["CBSE", "ICSE", "State Board", "IB", "IGCSE (Cambridge)", "NIOS"],
    "mediumsOfInstruction": ["English", "Hindi", "Punjabi", "..."],
    "categories": [
      "School Education",
      "College/University",
      "Coaching/Institute",
      "Sports & Hobby",
      "Professional Learn",
      "Skill Training"
    ],
    "fieldsByCategory": {
      "School Education": [ /* descriptors */ ],
      "College/University": [ /* descriptors */ ]
    }
  }
}
```

`boards` and `mediumsOfInstruction` are unchanged from the previous version of
this endpoint, so existing code keeps working. They are also available as the
`suggestions` of the `board` / `mediumOfInstruction` descriptors.

---

## 6. Load an existing listing — `GET /schools/:id/quick-info`

Returns the saved values **and** the field set for that listing's category, so
an edit form renders in one call.

```json
{
  "success": true,
  "data": {
    "coursesOffered": ["BCA", "BBA"],
    "affiliatedUniversity": "MAKAUT",
    "streams": ["CSE", "ECE"],
    "numberOfStudents": 2400
  },
  "category": "College/University",
  "fields": [ /* descriptors, same shape as above */ ]
}
```

`data` may be `{}` for a listing whose owner has not filled anything in.
`category` is `null` when the listing has no category set — `fields` then
contains every field.

---

## 7. Save

### On create — `POST /schools`

Send `quickInfo` inline with the rest of the listing:

```json
{
  "name": "St. Xavier's College",
  "category": "College/University",
  "ownerId": "<user id>",
  "quickInfo": {
    "coursesOffered": ["BCA", "BBA"],
    "affiliatedUniversity": "University of Calcutta",
    "streams": ["Science", "Commerce"]
  }
}
```

Set `category` on the listing at creation time — it is what decides the field
set every later screen renders.

### On edit — `PUT /schools/:id/quick-info`

Owner only. **Partial update**: send only what changed; omitted fields keep
their stored value.

```
PUT /schools/:id/quick-info
Authorization: Bearer <token>
Content-Type: application/json
```

```json
{
  "coursesOffered": ["BCA", "BBA", "B.Sc"],
  "affiliatedUniversity": "University of Calcutta",
  "streams": ["Science", "Commerce"],
  "numberOfStudents": 2400
}
```

Fields may also be wrapped in a `quickInfo` object — both are accepted.

### Rules

- List fields accept a **single string or an array**; both are stored as an array.
- Entries are **trimmed and deduped**; blanks are dropped.
- Send `[]` to **clear** a list field.
- Values outside the `suggestions` list are fine.
- A field from another category is accepted and saved — the backend does not
  enforce the category mapping. Use the `fields` array to decide what to *show*.

### Response — `200 OK`

```json
{
  "success": true,
  "message": "School quick info updated successfully",
  "data": { /* the full merged quickInfo */ }
}
```

### Errors

| Status | When |
|---|---|
| `400` | Shape violation — e.g. `{"streams": [""]}` or `studentTeacherRatio: "20"` |
| `401` | Missing/invalid token |
| `403` | Authenticated user does not own this listing |
| `404` | Listing not found |
| `500` | Server error |

`400` bodies carry a human-readable `message` naming the offending field, e.g.
`"streams must be a non-empty string or an array of non-empty strings (max 100 characters each)"`.

---

## 8. Recommended frontend usage

Options are static — fetch once on form mount and cache aggressively.

```js
// Field set for the category being created/edited
async function getQuickInfoFields(category) {
  const url = `${BASE_URL}/schools/options?category=${encodeURIComponent(category)}`;
  const res = await fetch(url);
  const json = await res.json();
  if (!json.success) throw new Error(json.message || 'Failed to load options');
  return json.data.fields;
}
```

```jsx
// Render straight from the descriptors — no per-category branching
{fields.map((field) => {
  if (field.type === 'stringArray') {
    return (
      <ChipInput
        key={field.key}
        label={field.label}
        placeholder={field.placeholder}
        suggestions={field.suggestions}
        value={values[field.key] || []}
        onChange={(next) => setValue(field.key, next)}
        allowCustom
      />
    );
  }

  return (
    <TextInput
      key={field.key}
      label={field.label}
      placeholder={field.placeholder}
      type={field.type === 'number' ? 'number' : 'text'}
      value={values[field.key] ?? ''}
      onChange={(next) => setValue(field.key, next)}
    />
  );
})}
```

Adding a category field later requires **no frontend change** — the new
descriptor simply appears in `fields`.

---

## 9. Migration from the previous version

1. Remove any hardcoded per-category field lists and suggestion arrays.
2. Drive the form from `GET /schools/options?category=` (or `fieldsByCategory`).
3. Existing `/schools/options` calls that read `boards` /
   `mediumsOfInstruction` keep working unchanged — no rush to migrate them.
4. Keep any "Other → free text" input; the backend still accepts custom values.

---

## 10. Quick test

```bash
curl -s "https://<host>/schools/options?category=College/University" | jq
curl -s "https://<host>/schools/options" | jq '.data.categories'
```

Swagger: documented under the **Schools** tag as `GET /schools/options`,
`GET /schools/{id}/quick-info` and `PUT /schools/{id}/quick-info`. The field
catalogue itself lives in `src/config/schoolQuickInfoFields.js`.
