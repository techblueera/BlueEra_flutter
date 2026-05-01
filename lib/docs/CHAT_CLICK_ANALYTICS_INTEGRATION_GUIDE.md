# Chat-Click Analytics — Integration Guide

`GET /business/{businessId}/chat-clicks` is a single multi-format
analytics endpoint that powers every chart, KPI tile, leaderboard, and
heatmap on the merchant-facing dashboard. This guide walks through the
query surface, the response shapes, and end-to-end snippets for the
common chart types.

> Swagger reference (live): visit `/api-docs` on a running instance and
> open the **BusinessChatClicks** tag. The schemas there are the source
> of truth.

> Companion docs:
> - [`CHAT_CLICK_TRACKING_GUIDE.md`](./CHAT_CLICK_TRACKING_GUIDE.md) — how
>   the click events get *recorded* (the `POST` side).
> - This file — how clients *read* analytics.

---

## TL;DR

Fire one request, change the chart by swapping `format`:

```
GET /business/:businessId/chat-clicks?format=timeseries&range=last_7_days
GET /business/:businessId/chat-clicks?format=breakdown&breakdownBy=source&range=this_month
GET /business/:businessId/chat-clicks?format=heatmap&range=last_30_days
GET /business/:businessId/chat-clicks?format=top_users&range=last_90_days&limit=20
GET /business/:businessId/chat-clicks?format=full&range=last_30_days&compare=true
```

For backward compatibility, calling with **no query params** returns the
original lifetime aggregate:

```json
{
  "success": true,
  "data": {
    "unique_users": 142,
    "total_clicks": 389,
    "first_clicked_at": "2025-12-01T10:24:00.000Z",
    "last_clicked_at": "2026-04-30T18:11:09.000Z"
  }
}
```

---

## Endpoint

```
GET /business/:businessId/chat-clicks
```

- **Auth:** public for now (matches existing behaviour). Swap to
  `authenticateUser` middleware in `chatClick.route.js` if you want to
  gate it to merchant-dashboard JWTs.
- **Path param:** `businessId` — Mongo `_id` of the business.
- **Query params:** see the [reference table](#query-parameter-reference)
  below.

---

## Query parameter reference

### Date window

| Param          | Type    | Default          | Notes |
|----------------|---------|------------------|-------|
| `range`        | enum    | `last_7_days`    | Preset window. Full list below. |
| `from`         | ISO-8601 | —               | Custom range start (inclusive). Overrides `range`. |
| `to`           | ISO-8601 | —               | Custom range end (inclusive). Overrides `range`. |
| `tz`           | IANA TZ | `Asia/Kolkata`  | Boundary alignment + bucket trunc. |

**Allowed `range` presets:**

| Preset           | Window                                       |
|------------------|----------------------------------------------|
| `today`          | Midnight today → end of today (in `tz`)      |
| `yesterday`      | Full prior calendar day                      |
| `last_3_days`    | 3 days ending today (inclusive)              |
| `last_7_days`    | 7 days ending today                          |
| `last_14_days`   | 14 days ending today                         |
| `last_30_days`   | 30 days ending today                         |
| `last_60_days`   | 60 days ending today                         |
| `last_90_days`   | 90 days ending today                         |
| `last_180_days`  | 180 days ending today                        |
| `last_365_days`  | Trailing year                                |
| `this_week`      | ISO week containing today                    |
| `last_week`      | Prior ISO week                               |
| `this_month`     | Current calendar month                       |
| `last_month`     | Prior calendar month                         |
| `this_quarter`   | Current quarter                              |
| `last_quarter`   | Prior quarter                                |
| `this_year`      | Current calendar year                        |
| `last_year`      | Prior calendar year                          |
| `all_time`       | No date filter                               |

> Custom ranges always win when both `range` and `from`/`to` are given.

### Filters

| Param              | Type    | Notes |
|--------------------|---------|-------|
| `source`           | CSV     | Allow-list. Values: `map_card,map_list,store_detail,search_result,feed,deep_link,other`. |
| `excludeSource`    | CSV     | Deny-list of sources. |
| `platform`         | CSV     | Allow-list. Values: `ios,android,web,other`. |
| `excludePlatform`  | CSV     | Deny-list of platforms. |
| `userId`           | string  | Single user ObjectId. |
| `userIds`          | CSV     | Many user ObjectIds. |
| `metadataKey`      | string  | Metadata field path (alphanum/`_.-`, ≤64 chars). |
| `metadataValue`    | string  | Required value. Omit to filter for "key exists". |
| `minClicks`        | int     | `top_users` only — lower bound. |
| `maxClicks`        | int     | `top_users` only — upper bound. |

### Format / shape

| Param                | Type    | Default | Notes |
|----------------------|---------|---------|-------|
| `format`             | enum    | `summary` | `summary | timeseries | breakdown | heatmap | top_users | funnel | distribution | comparison | full`. |
| `granularity`        | enum    | `auto`  | `auto | hour | day | week | month | quarter | year`. |
| `breakdownBy`        | enum    | `source` | `source | platform | source_platform | user | day_of_week | hour_of_day | date`. |
| `distributionBuckets`| CSV ints | `1,2,5,10,25,50,100` | Histogram upper bounds. |

`granularity=auto` chooses based on the range span:
- ≤ 2 days → `hour`
- ≤ 90 days → `day`
- ≤ 730 days → `week`
- otherwise → `month`

### Sort / pagination

| Param      | Type    | Default | Notes |
|------------|---------|---------|-------|
| `sortBy`   | enum    | format-specific | `clicks | unique_users | first_clicked_at | last_clicked_at | bucket`. |
| `sortOrder`| enum    | `desc`  | `asc | desc`. |
| `limit`    | int     | `50`    | 1–1000. Caps `breakdown.groups[]` and `top_users.users[]`. |

### Comparison & misc

| Param            | Type    | Default | Notes |
|------------------|---------|---------|-------|
| `compare`        | bool    | `false` | When `true`, attach a `comparison` block with delta vs prior period. |
| `comparePeriod`  | enum    | `previous` | `previous` (same length immediately prior) or `year_over_year`. |
| `fillGaps`       | bool    | `true`  | Pad timeseries with zero buckets so x-axis is continuous. |
| `includeMeta`    | bool    | `true`  | Echo the resolved range/filters/sort under `meta`. |

---

## Response envelope

Every analytics call returns:

```jsonc
{
  "success": true,
  "meta": {                          // present when includeMeta != false
    "businessId": "6601b2c8f1a4a2001f9c0a11",
    "format": "timeseries",
    "granularity": "day",
    "range": {
      "preset": "last_7_days",
      "tz": "Asia/Kolkata",
      "from": "2026-04-24T18:30:00.000Z",
      "to":   "2026-05-01T18:29:59.999Z",
      "fromIso": "2026-04-24T18:30:00.000Z",
      "toIso":   "2026-05-01T18:29:59.999Z"
    },
    "filters": { "sources": ["map_card"], "platforms": null, ... },
    "sort":    { "sortBy": "clicks", "sortOrder": "desc" },
    "limit":   50,
    "generated_at": "2026-05-01T07:23:00.000Z"
  },
  "data": { /* shape depends on `format` */ }
}
```

> The `meta.range.from`/`to` is the canonical window the server filtered
> on. Prefer using these to label your chart axes — they already reflect
> tz alignment and any custom override.

---

## Format-by-format reference

### 1. `summary` — KPI tiles

```
GET /business/:id/chat-clicks?format=summary&range=last_30_days
```

Response `data`:

```json
{
  "total_clicks": 389,
  "unique_users": 142,
  "first_clicked_at": "2026-04-01T03:14:22.000Z",
  "last_clicked_at":  "2026-04-30T18:11:09.000Z",
  "average_clicks_per_user": 2.74
}
```

Use for the four KPI cards at the top of the dashboard.

### 2. `timeseries` — line/area/bar over time

```
GET /business/:id/chat-clicks?format=timeseries&range=last_7_days&granularity=day
```

```jsonc
{
  "granularity": "day",
  "series": [
    { "bucket": "2026-04-25T00:00:00.000Z", "bucket_start": "...", "bucket_end": "...", "clicks": 12, "unique_users": 9 },
    { "bucket": "2026-04-26T00:00:00.000Z", "bucket_start": "...", "bucket_end": "...", "clicks": 0,  "unique_users": 0 },
    ...
  ],
  "totals": { "clicks": 87, "unique_users": 51 }
}
```

- `fillGaps=true` (default) gives you zero-filled days/hours so charts
  don't jump.
- `totals.unique_users` is **deduped at the period level**, so it does
  not equal the sum of `series[].unique_users`.

### 3. `breakdown` — pie / donut / stacked bar

```
GET /business/:id/chat-clicks?format=breakdown&breakdownBy=source&range=last_30_days
```

```json
{
  "breakdownBy": "source",
  "groups": [
    { "key": "map_card",     "raw": { "source": "map_card" },     "clicks": 164, "unique_users": 88, "percentage": 42.16 },
    { "key": "store_detail", "raw": { "source": "store_detail" }, "clicks": 119, "unique_users": 73, "percentage": 30.59 },
    { "key": "search_result","raw": { "source": "search_result" },"clicks":  72, "unique_users": 47, "percentage": 18.51 },
    { "key": "deep_link",    "raw": { "source": "deep_link" },    "clicks":  21, "unique_users": 17, "percentage":  5.40 },
    { "key": "other",        "raw": { "source": "other" },        "clicks":  13, "unique_users":  9, "percentage":  3.34 }
  ],
  "totals": { "clicks": 389, "unique_users": 0 }
}
```

`breakdownBy` options:

| Value             | Use it for                                            |
|-------------------|-------------------------------------------------------|
| `source`          | Pie/donut of click sources                            |
| `platform`        | iOS vs Android vs Web split                           |
| `source_platform` | Stacked bar (source × platform) — keys are `src|plat` |
| `user`            | Per-user click counts (cap with `limit`)              |
| `day_of_week`     | "Best day" view (`sunday … saturday`)                 |
| `hour_of_day`     | "Best hour" view (0–23)                               |
| `date`            | Per-day aggregate (use `timeseries` for charts)       |

### 4. `heatmap` — 7×24 day-of-week × hour grid

```
GET /business/:id/chat-clicks?format=heatmap&range=last_30_days
```

```json
{
  "tz": "Asia/Kolkata",
  "days":  ["sunday","monday","tuesday","wednesday","thursday","friday","saturday"],
  "hours": [0,1,2,3,...,23],
  "grid":  [
    [0,0,0,0,0,1,2,4, 6,5,3,2,3,4,5,6, 7,8,7,5,3,2,1,0],
    [0,0,0,0,0,2,3,5, 8,9,6,4,5,7,9,11,13,15,12,7,5,3,2,1],
    ...
  ],
  "matrix": [
    { "day_of_week": 0, "hour":  5, "clicks": 1 },
    { "day_of_week": 0, "hour":  6, "clicks": 2 },
    ...
  ]
}
```

- `grid` is the easiest shape to drop into a heatmap component
  (`grid[dayIndex][hour]`).
- `matrix` is convenient for d3 / scatter-style libraries.

### 5. `top_users` — leaderboard

```
GET /business/:id/chat-clicks?format=top_users&range=last_90_days&limit=10&sortBy=clicks
```

```json
{
  "users": [
    {
      "userId": "65fa11d23ab9810022b30c44",
      "clicks": 17,
      "first_clicked_at": "2026-02-04T11:09:21.000Z",
      "last_clicked_at":  "2026-04-29T16:42:55.000Z",
      "sources":   ["map_card","store_detail"],
      "platforms": ["android","web"]
    },
    ...
  ]
}
```

`minClicks` / `maxClicks` filter the user list before sorting.

### 6. `funnel` — source contribution

```
GET /business/:id/chat-clicks?format=funnel&range=last_30_days
```

```json
{
  "stages": [
    { "rank": 1, "source": "map_card",     "clicks": 164, "unique_users": 88, "share": 0.4216 },
    { "rank": 2, "source": "store_detail", "clicks": 119, "unique_users": 73, "share": 0.3059 },
    ...
  ],
  "totals": { "clicks": 389 }
}
```

### 7. `distribution` — clicks-per-user histogram

```
GET /business/:id/chat-clicks?format=distribution&range=last_90_days&distributionBuckets=1,3,10,50
```

```json
{
  "buckets": [
    { "range": "1",    "lower": 1,  "upper": 1,    "users": 81 },
    { "range": "2-3",  "lower": 2,  "upper": 3,    "users": 34 },
    { "range": "4-10", "lower": 4,  "upper": 10,   "users": 19 },
    { "range": "11-50","lower": 11, "upper": 50,   "users": 7  },
    { "range": "51+",  "lower": 51, "upper": null, "users": 1  }
  ],
  "total_users": 142
}
```

### 8. `comparison` — period over period

```
GET /business/:id/chat-clicks?format=comparison&range=this_month&comparePeriod=previous
GET /business/:id/chat-clicks?format=comparison&range=this_month&comparePeriod=year_over_year
```

```json
{
  "current":  { "total_clicks": 389, "unique_users": 142, ... },
  "previous": { "total_clicks": 312, "unique_users": 121, ... },
  "range":          { "preset": "this_month", "from": "...", "to": "..." },
  "previous_range": { "from": "...", "to": "..." },
  "delta": {
    "clicks_abs": 77,
    "clicks_pct": 24.68,
    "unique_users_abs": 21,
    "unique_users_pct": 17.36
  }
}
```

Tip: pass `compare=true` on **any** other format and you'll also get a
`comparison` block attached to that response — handy for dashboard tiles
that want both a chart and a delta indicator.

### 9. `full` — one call, every shape

```
GET /business/:id/chat-clicks?format=full&range=last_30_days&compare=true
```

```jsonc
{
  "data": {
    "summary":               { ... },
    "timeseries":            { ... },
    "breakdown_by_source":   { ... },
    "breakdown_by_platform": { ... },
    "heatmap":               { ... },
    "top_users":             { ... },   // capped at min(limit, 25)
    "funnel":                { ... },
    "distribution":          { ... },
    "comparison":            { ... }    // null unless compare=true
  }
}
```

All eight aggregations run in parallel. Use this for the merchant
dashboard page-load so you don't fan out nine HTTP calls.

---

## Date window cookbook

| Use case                              | Query                                                   |
|---------------------------------------|---------------------------------------------------------|
| Today (in IST)                        | `range=today`                                           |
| Today (in PST)                        | `range=today&tz=America/Los_Angeles`                    |
| Last 7 days incl. today               | `range=last_7_days`                                     |
| Last 7 *full* days (excl. today)      | `from=2026-04-24T00:00:00+05:30&to=2026-04-30T23:59:59+05:30` |
| This calendar month                   | `range=this_month`                                      |
| April 2026                            | `from=2026-04-01T00:00:00+05:30&to=2026-04-30T23:59:59+05:30` |
| All time                              | `range=all_time`                                        |
| Same window, last year                | `range=this_month&compare=true&comparePeriod=year_over_year` |

---

## Frontend snippets

### React + axios

```js
import axios from "axios";

const api = axios.create({ baseURL: process.env.API_BASE });

export const fetchChatAnalytics = (businessId, params = {}) =>
  api
    .get(`/business/${businessId}/chat-clicks`, { params })
    .then((r) => r.data);

// KPI tiles
const kpi = await fetchChatAnalytics(id, { format: "summary", range: "last_30_days" });

// Time-series for a line chart
const ts = await fetchChatAnalytics(id, { format: "timeseries", range: "last_7_days" });
const points = ts.data.series.map((p) => ({ x: p.bucket, y: p.clicks }));

// Pie of sources
const pie = await fetchChatAnalytics(id, { format: "breakdown", breakdownBy: "source", range: "last_30_days" });

// Single-call dashboard
const dash = await fetchChatAnalytics(id, { format: "full", range: "last_30_days", compare: true });
```

### Recharts — line chart from `timeseries`

```jsx
import { LineChart, Line, XAxis, YAxis, Tooltip } from "recharts";

const series = ts.data.series.map((p) => ({
  date: new Date(p.bucket).toLocaleDateString(),
  clicks: p.clicks,
  uniqueUsers: p.unique_users,
}));

<LineChart width={600} height={300} data={series}>
  <XAxis dataKey="date" />
  <YAxis />
  <Tooltip />
  <Line type="monotone" dataKey="clicks" stroke="#3b82f6" />
  <Line type="monotone" dataKey="uniqueUsers" stroke="#10b981" />
</LineChart>;
```

### Recharts — pie from `breakdown`

```jsx
import { PieChart, Pie, Tooltip, Cell } from "recharts";

const COLORS = ["#3b82f6", "#10b981", "#f59e0b", "#ef4444", "#8b5cf6"];

<PieChart width={400} height={300}>
  <Pie data={pie.data.groups} dataKey="clicks" nameKey="key" outerRadius={100} label>
    {pie.data.groups.map((_, i) => (
      <Cell key={i} fill={COLORS[i % COLORS.length]} />
    ))}
  </Pie>
  <Tooltip />
</PieChart>;
```

### Heatmap (raw grid render)

```jsx
const { days, hours, grid } = heatmap.data;

<table>
  <thead>
    <tr>
      <th></th>
      {hours.map((h) => <th key={h}>{h}</th>)}
    </tr>
  </thead>
  <tbody>
    {grid.map((row, dIdx) => (
      <tr key={days[dIdx]}>
        <th>{days[dIdx]}</th>
        {row.map((c, h) => (
          <td key={h} style={{ background: `rgba(59,130,246,${Math.min(1, c / 20)})` }}>
            {c}
          </td>
        ))}
      </tr>
    ))}
  </tbody>
</table>;
```

### Flutter / Dart

```dart
final res = await Dio().get(
  '/business/$businessId/chat-clicks',
  queryParameters: {
    'format': 'full',
    'range': 'last_30_days',
    'compare': true,
  },
);

final data = res.data['data'];
final series = (data['timeseries']['series'] as List)
    .map((p) => FlSpot(
          DateTime.parse(p['bucket']).millisecondsSinceEpoch.toDouble(),
          (p['clicks'] as num).toDouble(),
        ))
    .toList();
```

### cURL quick checks

```bash
# KPI tiles for last 30 days
curl "$API/business/$BID/chat-clicks?format=summary&range=last_30_days"

# Hourly timeseries today
curl "$API/business/$BID/chat-clicks?format=timeseries&range=today&granularity=hour"

# Custom range pie
curl "$API/business/$BID/chat-clicks?format=breakdown&breakdownBy=source&from=2026-04-01T00:00:00%2B05:30&to=2026-04-30T23:59:59%2B05:30"

# Top 10 users with at least 3 clicks
curl "$API/business/$BID/chat-clicks?format=top_users&range=last_90_days&minClicks=3&limit=10"

# YoY comparison
curl "$API/business/$BID/chat-clicks?format=comparison&range=this_month&comparePeriod=year_over_year"

# Full dashboard payload (one call)
curl "$API/business/$BID/chat-clicks?format=full&range=last_30_days&compare=true"
```

---

## Field semantics & gotchas

- **Timezone-aware buckets.** `dateTrunc` uses the `tz` query value
  (default `Asia/Kolkata`) so a "day" bucket starts at local midnight,
  not UTC midnight. Set `tz=UTC` if your dashboard already displays UTC.
- **`unique_users` totals are deduped.** In `timeseries`, the per-bucket
  `unique_users` is local to that bucket. The period-level
  `totals.unique_users` is computed independently and may be smaller
  than `sum(series[].unique_users)` — that's correct.
- **Custom range overrides `range`.** If you pass both, `from`/`to` win.
  Use this to keep a preset selector and a date picker side-by-side.
- **`fillGaps=false`** returns only buckets that actually contain
  events. Useful for sparkline-style charts where you want the data to
  drive the x-axis.
- **`metadataKey`/`metadataValue` are tiny.** They filter on a single
  metadata path. For complex metadata queries, fetch the raw events via
  `/chat-clicks/events` and aggregate client-side.
- **`limit=1000` is the max** for `breakdown.groups[]` / `top_users`.
  Beyond that you should be paginating with `events`.

---

## Companion endpoints (unchanged)

```
POST  /business/:businessId/chat-click          — record a click (auth required)
GET   /business/:businessId/chat-clicks/events  — paginated raw event log (auth required)
```

The events endpoint accepts the same date-preset / filter / sort surface,
plus standard `page` / `limit` pagination. See
[`CHAT_CLICK_TRACKING_GUIDE.md`](./CHAT_CLICK_TRACKING_GUIDE.md) for the
write-side spec.

---

## Versioning & backwards compatibility

- Calling `GET /business/:id/chat-clicks` with **no query params** still
  returns the original `{ unique_users, total_clicks, last_clicked_at }`
  shape so existing clients don't need to migrate.
- Adding new `format` values is non-breaking. Always check `meta.format`
  on the response if you support multiple shapes in one client.
- Field additions inside `meta`, `data.summary`, etc. are non-breaking
  and may happen without a major-version bump. Do not assume the keys
  you see today are exhaustive.
