# Business Filter — `timing` key

`GET /business/filter` now returns each business's opening hours as a `timing`
object, built from the same availability data `PUT /business/availability/hours`
saves. This is additive — no existing field changed.

- **Service:** `be_user_service`
- **Endpoint:** `GET https://be.beapp.in/api/user-service/business/filter`

---

## Request (unchanged)

```
GET /business/filter?category=DIAGNOSTIC&page=1&limit=10
```

| Query | Notes |
|---|---|
| `category` | e.g. `DIAGNOSTIC` (maps to `category_Of_Business`) |
| `subCategory`, `typeOfBusiness` | optional |
| `page` / `limit` | default 1 / 10, max 50 |

---

## What was added

Each item in `data[]` now carries a **`timing`** object, alongside the existing
`liveState`. Both are computed from the business's Availability document (what
`PUT /business/availability/hours` writes), so they never disagree.

```jsonc
{
  "success": true,
  "data": [
    {
      "_id": "…",
      "businessName": "…",
      "liveState": { "isLive": true, "liveDate": "2026-07-24" },   // already existed
      "timing": {                                                   // NEW
        "timezone": "Asia/Kolkata",
        "today": {
          "day": "Friday",
          "date": "2026-07-24",
          "isOpen": true,
          "shopOpenTime": "09:00",
          "shopCloseTime": "21:00",
          "source": "weekly"          // "override" | "weekly" | "none"
        },
        "schedule": [
          { "day": "Monday",    "isOpen": true,  "shopOpenTime": "09:00", "shopCloseTime": "21:00" },
          { "day": "Sunday",    "isOpen": false }
          // … up to 7 days, as saved
        ]
      }
    }
  ],
  "pagination": { … }
}
```

### `timing` can be `null`

If a business has **never set its hours**, `timing` is `null`. Verified against
production: of 10 DIAGNOSTIC businesses on the first page, 3 had hours set and 7
returned `timing: null`. Render a "Timing not set" state — do **not** invent a
default.

---

## Field reference

| Path | Type | Meaning |
|---|---|---|
| `timing` | object \| **null** | `null` = hours never set |
| `timing.timezone` | string | e.g. `Asia/Kolkata` |
| `timing.today.day` | string | weekday for the caller's "now" in the business timezone |
| `timing.today.date` | string | `YYYY-MM-DD` |
| `timing.today.isOpen` | bool | is the business open **today** |
| `timing.today.shopOpenTime` | string \| undefined | `"HH:MM"`; absent when closed |
| `timing.today.shopCloseTime` | string \| undefined | `"HH:MM"`; absent when closed |
| `timing.today.source` | string | `override` (a special one-day override) · `weekly` (the normal weekly schedule) · `none` (no entry for today) |
| `timing.schedule[]` | array | the saved weekly hours (0–7 entries) |
| `timing.schedule[].day` | string | `Monday`…`Sunday` |
| `timing.schedule[].isOpen` | bool | open on that weekday |
| `timing.schedule[].shopOpenTime` / `shopCloseTime` | string \| undefined | `"HH:MM"` |

`today` already accounts for special one-day overrides — if the lab set a
different time for today, `today` reflects it and `source` is `"override"`.

---

## UI usage

**Card badge — today's status:**

```dart
final t = business.timing;                 // may be null
if (t == null) {
  return const Text('Timing not set');
}
if (t.today.isOpen) {
  return Text('Open · ${t.today.shopOpenTime}–${t.today.shopCloseTime}');
} else {
  return const Text('Closed today');
}
```

> For an accurate "Open now" vs just "Open today", combine with the existing
> `liveState.isLive` — `liveState` already checks the current clock time against
> today's window. `timing.today.isOpen` means "open *sometime* today"; use
> `liveState.isLive` for "open *right now*".

**Full weekly hours** (detail sheet): iterate `timing.schedule` — each entry is a
weekday with its open/close, or `isOpen:false` for a closed day.

---

## Notes

- **Additive & fail-soft.** The enrichment reuses the existing per-list
  Availability fetch and the same helpers as `liveState`; on any error the list
  still returns (without `timing`), never a failure.
- Encoding: none of the `category` values contain special characters, but keep
  using `Uri`/`URLSearchParams` for query building as standard.
- This change is in `be_user_service`
  (`utils/availabilityHours.js` → `buildTimingSummary`, wired into
  `business.controller.js` → `attachLiveStateToBusinesses`). Confirm it is
  **deployed** before the app relies on `timing`.
