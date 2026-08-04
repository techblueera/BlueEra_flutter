# Rider Statistics API — backend guide

The rider app's **Statistics** tab (rider dashboard → last tab) needs one
endpoint. This document is the complete contract: request, response, field
semantics, how each number is defined, and the edge cases the app already
handles.

Frontend is **built and merged** against this contract. It currently renders
sample data behind a flag; the day this endpoint returns 200, we flip
`RiderStatisticsController.useSampleData` to `false` and nothing else changes.

- Endpoint constant: `RiderServiceApi.ridersStatistics`
- Client model: `lib/features/common/delivery_partner/model/rider_statistics_model.dart`
- Client view: `lib/features/common/delivery_partner/view/rider_statistics_view.dart`

---

## 1. Endpoint

```
GET /api/rider-service/riders/statistics?period=today
Authorization: Bearer <rider JWT>
```

| Param | Type | Required | Values | Notes |
|---|---|---|---|---|
| `period` | string | yes | `today` \| `week` \| `month` | Anything else → `400` |

**The rider is taken from the JWT, never from a query param.** There is no
`riderId` in this request and there must not be one — a rider must not be able
to read another rider's earnings by changing a URL.

### Period boundaries

Computed in the **rider's local timezone** (IST unless the profile says
otherwise), not UTC. A rider who finishes at 00:30 IST expects that ride in
*yesterday*, not today.

| `period` | From | To |
|---|---|---|
| `today` | 00:00:00 local today | now |
| `week` | 00:00:00 local **Monday** of the current week | now |
| `month` | 00:00:00 local 1st of the current month | now |

Rolling windows (last 7 days / last 30 days) are **not** what we want — riders
compare against "this week" as a calendar thing, and an incentive week resets on
a fixed day.

---

## 2. Response

`200 OK`

```jsonc
{
  "period": "week",
  "range": {
    "from": "2026-08-03T00:00:00+05:30",
    "to":   "2026-08-04T19:42:11+05:30"
  },
  "earnings": {
    "currency":   "INR",
    "total":      4685.00,
    "tripFare":   4290.00,
    "incentives":  300.00,
    "tips":        210.00,
    "deductions":  115.00
  },
  "trips": {
    "completed":            39,
    "cancelledByRider":      2,
    "cancelledByCustomer":   3,
    "distanceKm":        244.8,
    "onlineMinutes":      1985
  },
  "performance": {
    "acceptanceRate":   91.0,
    "cancellationRate":  5.0,
    "completionRate":   95.0,
    "rating":            4.7,
    "ratingCount":       132
  },
  "trend": [
    { "date": "2026-08-03", "earnings": 812.00, "trips": 7 },
    { "date": "2026-08-04", "earnings": 742.00, "trips": 6 }
  ],
  "payouts": {
    "pending":     1565.00,
    "lastAmount":  3120.00,
    "lastPaidAt":  "2026-08-01T18:40:00+05:30"
  }
}
```

A `{ "data": { ... } }` envelope is also accepted — the client unwraps either.
Pick one and stay consistent.

### Response rules

1. **Never 404 for "no rides".** A rider with zero activity gets `200` with
   zeros. The app shows a "No rides in this period" state off the zeros; a 404
   would show a network error instead, which is a lie.
2. **Every field is optional to the parser** and defaults to `0` / `""`. Ship
   sections incrementally if you need to — a missing `payouts` block simply
   hides that card. Do not send `null` for a whole section *and* expect the app
   to show something.
3. **Numbers are numbers**, not strings. `"4685.00"` parses, but don't.
4. **Money is in major units** (rupees, `4685.00`), not paise. If your ledger is
   in paise, divide before responding — one conversion in one place beats every
   client doing it.

---

## 3. Field definitions

These definitions are the whole point of the document. Two services computing
"acceptance rate" differently is how a rider ends up with a number they can't
reconcile with what they remember.

### `earnings`

| Field | Definition |
|---|---|
| `total` | What the rider actually earned in the window, **after** `deductions`. This is the hero number on the tab. |
| `tripFare` | Sum of fares for rides completed in the window, before deductions. |
| `incentives` | Bonuses, surge top-ups, streak/quest payouts credited in the window. |
| `tips` | Customer tips credited in the window. |
| `deductions` | Platform commission + any adjustments already taken out of `total`. Positive number. |

`total` is **authoritative** — the app displays it as sent and never recomputes
it from the parts. The parts are an explanation, so they may legitimately not
sum exactly (rounding, an adjustment that belongs to no category). Do not force
them to reconcile by fudging a category.

Attribution rule: a ride counts in the window its **completion** timestamp falls
in, not its acceptance. A ride accepted 23:58 and finished 00:04 belongs to the
new day.

### `trips`

| Field | Definition |
|---|---|
| `completed` | Rides finished by the rider in the window. |
| `cancelledByRider` | Rides the rider accepted then cancelled. |
| `cancelledByCustomer` | Rides the customer cancelled *after* this rider accepted. |
| `distanceKm` | Driven distance for completed rides. Pickup→drop as billed, **not** including the drive to the pickup, unless you also pay for that leg — say which you chose. |
| `onlineMinutes` | Minutes the rider was live/available in the window. Sum of go-live sessions, clipped to the window boundaries. |

`onlineMinutes` must be **clipped, not counted whole**: a session that starts
22:00 Sunday and ends 01:00 Monday contributes 120 min to Sunday and 60 to
Monday. An unclipped session double-counts in both week buckets.

### `performance`

All three rates are **percentages 0–100**, not 0–1 fractions. A `0.91` here
renders as "1%" and makes the rider think they're about to be deactivated.

| Field | Formula |
|---|---|
| `acceptanceRate` | `accepted / offered × 100` — offers shown to this rider in the window. Exclude offers that expired because another rider claimed the broadcast first; the rider never had a real chance at those. |
| `completionRate` | `completed / accepted × 100`. |
| `cancellationRate` | `cancelledByRider / accepted × 100`. Rider-caused only — a customer cancelling must never count against the rider. |
| `rating` | Mean of customer→rider ratings, **lifetime**, not windowed. A single bad week shouldn't appear to move a lifetime score. Round to 1 decimal. |
| `ratingCount` | Number of ratings behind `rating` (lifetime). |

Send `rating: 0, ratingCount: 0` for a rider nobody has rated — the app hides
the block rather than showing "0.0 ★", which reads as a terrible rider rather
than a new one.

The app's thresholds (client-side, tell us if the policy differs):
acceptance ≥ 80 good / ≥ 60 watch, completion ≥ 90 good / ≥ 75 watch,
cancellation ≤ 5 good / ≤ 15 watch.

### `trend`

One entry per **day**, oldest first, for the selected period:

| `period` | Entries |
|---|---|
| `today` | 1 (today) |
| `week` | 1–7 (Monday → today) |
| `month` | 1–31 (1st → today) |

- `date` is `yyyy-MM-dd` **local**.
- **Include zero days.** A day the rider didn't work is `earnings: 0, trips: 0`,
  not a gap — the chart's shape is the point, and a missing Wednesday silently
  shifts every bar after it.
- Do not send future days.

The app draws the chart only when there are ≥ 2 points, so `today` correctly
shows no chart.

### `payouts`

| Field | Definition |
|---|---|
| `pending` | Earned but not yet transferred, **lifetime** balance — not windowed. This is "what am I owed", which doesn't reset on Monday. |
| `lastAmount` | Amount of the most recent completed payout. |
| `lastPaidAt` | ISO-8601 timestamp of that payout, with offset. |

Omit the whole block (or send zeros) if payouts aren't implemented yet — the
card hides itself.

---

## 4. Errors

| Status | When | App behaviour |
|---|---|---|
| `200` | Always, including zero activity | Renders numbers / empty state |
| `400` | `period` missing or not one of the three | Error card + Retry |
| `401` | Bad/expired token | Standard auth interceptor |
| `403` | Caller is not an onboarded rider | Error card + Retry |
| `5xx` | — | Error card + Retry |

Error body shape follows the existing convention:
`{ "message": "..." }` — the app surfaces `message` when present.

---

## 5. Performance

This tab is opened often and casually — treat it as a read-hot endpoint.

- **Pre-aggregate.** A per-rider per-day rollup table (`rider_id, local_date,
  earnings, trips, distance_km, online_minutes, accepted, offered, cancelled`)
  makes all three periods a range-sum over ≤ 31 rows. Do not scan the orders
  collection per request.
- **Target < 300 ms p95.** The app caches per period for the life of the screen,
  so the realistic load is ~3 calls per tab visit, but riders check between
  rides on bad connections.
- Cache server-side for ~60 s per (rider, period) if it helps. Riders do not
  need second-level freshness on a summary; they have the order list for that.

---

## 6. Test cases we'd like green before integrating

1. Brand-new rider, zero rides → `200`, all zeros, `trend` = one zero day.
2. Rider with rides today only, asking `period=week` → week totals include
   today, `trend` has the earlier zero days present.
3. Session spanning midnight → `onlineMinutes` split across both days.
4. Ride accepted 23:58, completed 00:04 → counted in the **new** day.
5. Customer-cancelled ride → increments `cancelledByCustomer`, leaves
   `cancellationRate` unchanged.
6. Broadcast offer claimed by another rider first → does **not** lower this
   rider's `acceptanceRate`.
7. Rider with no ratings → `rating: 0, ratingCount: 0`.
8. `period=year` → `400`.
9. Rider A's token cannot retrieve rider B's numbers under any parameter.

---

## 7. Later (not needed for v1)

Listed so the rollup table doesn't have to be redesigned when they come up:

- **Per-hour buckets** for a "best hours to be online" view.
- **Zone/area breakdown** — where this rider's rides start.
- **Incentive progress** — `{ target, achieved, reward, expiresAt }` to show a
  "3 more rides for ₹150" bar.
- **Comparison** — this week vs last week as a delta on the hero number.
- **CSV/statement export** for a month.
