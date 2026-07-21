# School Options (Boards & Mediums) — UI Integration Guide

How the frontend populates the **Board** and **Medium of Instruction** dropdowns
from the backend instead of a hardcoded client-side list.

Previously the frontend shipped these two lists statically. Now the education
service owns the canonical lists and exposes them over one lightweight endpoint,
so adding/renaming a board or medium is a **backend change only** — no frontend
release needed.

> These lists are **suggestions for the dropdowns**, not strict validation. The
> `board` and `mediumOfInstruction` fields on a school are still free-text arrays,
> so an `"Other"` / custom value the user types will still save fine.

---

## 1. Base URL & auth

- Service: **be_education_service**
- Routes mounted at root → base path is **`/schools`**
- **No auth required** — this is public reference data. Send it without a token.

---

## 2. Endpoint

| Method | Path | Who | Purpose |
|---|---|---|---|
| `GET` | `/schools/options` | anyone | Get dropdown lists for boards & mediums |

---

## 3. Get options — `GET /schools/options`

### Request

```
GET /schools/options
```

No query params, no body, no headers required.

### Response — `200 OK`

```json
{
  "success": true,
  "data": {
    "boards": [
      "CBSE",
      "ICSE",
      "State Board",
      "IB",
      "IGCSE (Cambridge)",
      "NIOS"
    ],
    "mediumsOfInstruction": [
      "English",
      "Hindi",
      "Punjabi",
      "Urdu",
      "Sanskrit",
      "Bengali",
      "Tamil",
      "Telugu",
      "Marathi",
      "Gujarati",
      "Kannada",
      "Malayalam",
      "Odia",
      "Assamese",
      "Other"
    ]
  }
}
```

### Error — `500`

```json
{
  "success": false,
  "message": "Error fetching school options",
  "error": "<detail>"
}
```

### Notes on the shape

- `data.boards` and `data.mediumsOfInstruction` are **arrays of plain strings**.
- The **string value is exactly what you store** back on the school — for a `<select>`,
  use the same string for both the option label and its value. No id/label mapping.
- Order is meaningful — render options in the order received.
- Lists can grow over time; **never assume a fixed length or fixed set**. Always
  render whatever the endpoint returns.

---

## 4. How the values connect to a school

Both fields live under `school.quickInfo` and are **arrays** (a school can have
more than one board / medium):

```json
{
  "quickInfo": {
    "board": ["CBSE"],
    "mediumOfInstruction": ["English", "Hindi"]
  }
}
```

- Use a **multi-select** (or "add more") control for each — the schema accepts an array.
- You may submit values not present in `/schools/options` (e.g. a custom `"Other"`
  entry the user typed); the backend accepts any non-empty string up to 100 chars.

Where these get saved:

| Field | Saved via |
|---|---|
| `quickInfo.board` | `POST /schools` (create) or `PUT /schools/:id/quick-info` |
| `quickInfo.mediumOfInstruction` | `POST /schools` (create) or `PUT /schools/:id/quick-info` |

---

## 5. Recommended frontend usage

Fetch once (e.g. when the school create/edit form mounts) and cache. The data is
static and safe to cache aggressively.

```js
// fetch options
async function getSchoolOptions() {
  const res = await fetch(`${BASE_URL}/schools/options`);
  const json = await res.json();
  if (!json.success) throw new Error(json.message || 'Failed to load options');
  return json.data; // { boards, mediumsOfInstruction }
}
```

```jsx
// render (React example, single-select shown; use multi-select for arrays)
const { boards, mediumsOfInstruction } = options;

<select value={board} onChange={e => setBoard(e.target.value)}>
  <option value="" disabled>Select board</option>
  {boards.map(b => (
    <option key={b} value={b}>{b}</option>
  ))}
</select>

<select value={medium} onChange={e => setMedium(e.target.value)}>
  <option value="" disabled>Select medium of instruction</option>
  {mediumsOfInstruction.map(m => (
    <option key={m} value={m}>{m}</option>
  ))}
</select>
```

---

## 6. Migration from the old static list

1. Delete the hardcoded `boards` / `mediums` arrays in the frontend.
2. Replace them with a single `GET /schools/options` call on form load.
3. Keep any "Other → free text" input you already have — it still works, since the
   backend does not restrict `board` / `mediumOfInstruction` to this list.

---

## 7. Quick test

```bash
curl -s https://<host>/schools/options | jq
```

Swagger: the endpoint is documented under the **Schools** tag as `GET /schools/options`.
