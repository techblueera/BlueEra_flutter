# Self-Work (Skilled Worker) Statistics API — backend guide

The self-employed dashboard's **Statics** tab (Me tab → self-employed home →
last tab) needs one endpoint. This document is the complete contract: request,
response, field semantics, how each number is defined, and the edge cases the
app already handles.

"Self-employed" here means a **skilled worker on a `selfWork` earn-service
profile** — electrician, plumber, carpenter, painter, AC technician, tutor,
gardener, tailor, and the rest of the trades. Not a shop, not a rider, not a
home-made-food seller.

Frontend is **built and merged** against this contract. It currently renders
sample data behind a flag; the day this endpoint returns 200, we flip
`SelfWorkStatisticsController.useSampleData` to `false` and nothing else
changes.

- Endpoint constant: `EarnServiceApi.selfWorkStatistics`
- Repo method: `EarnServiceRepo.getSelfWorkStatisticsRepo`
- Client model: `lib/features/personal/personal_profile/view/self_employed/model/self_work_statistics_model.dart`
- Client view: `lib/features/personal/personal_profile/view/self_employed/view/self_work_statistics_view.dart`

This replaces, for this profile type only, the generic
`GET /business/:userId/chat-clicks` + profile-visits pair that used to back the
tab. Those two numbers describe a *page*; a tradesperson runs a *business*.

---

## 1. Endpoint

```
GET /api/earn-service/self-work/statistics?period=week
Authorization: Bearer <user JWT>
```

| Param | Type | Required | Values | Notes |
|---|---|---|---|---|
| `period` | string | yes | `today` \| `week` \| `month` | Anything else → `400` |

**The worker is taken from the JWT, never from a query param.** There is no
`userId` in this request and there must not be one — a worker must not be able
to read a competitor's earnings by changing a URL.

### Period boundaries

Computed in the **worker's local timezone** (IST unless the profile says
otherwise), not UTC. A worker who finishes a job at 00:30 IST expects it in
*yesterday*, not today.

| `period` | From | To |
|---|---|---|
| `today` | 00:00:00 local today | now |
| `week` | 00:00:00 local **Monday** of the current week | now |
| `month` | 00:00:00 local 1st of the current month | now |

Rolling windows (last 7 / last 30 days) are **not** what we want — a worker
compares against "this week" as a calendar thing, and settles accounts monthly.

---

## 2. Response

`200 OK`

```jsonc
{
  "period": "week",
  "profession": "ELECTRICIAN",
  "range": {
    "from": "2026-08-03T00:00:00+05:30",
    "to":   "2026-08-07T19:42:11+05:30"
  },

  "earnings": {
    "currency":            "INR",
    "total":               18450.00,
    "collected":           14200.00,
    "pending":              4250.00,
    "averageJobValue":      1025.00,
    "highestJobValue":      4600.00,
    "previousPeriodTotal": 15900.00
  },

  "jobs": {
    "completed":            18,
    "inProgress":            2,
    "cancelledByWorker":     1,
    "cancelledByCustomer":   3,
    "repeatCustomers":       6,
    "workedMinutes":      1810
  },

  "funnel": {
    "received":                46,
    "responded":               39,
    "quoted":                  31,
    "converted":               18,
    "medianResponseMinutes":   22,
    "missed":                   7
  },

  "trend": [
    { "date": "2026-08-03", "earnings": 1900.00, "jobs": 2 },
    { "date": "2026-08-04", "earnings": 3200.00, "jobs": 4 }
  ],

  "topServices": [
    { "name": "House wiring",             "jobs": 6, "earnings": 7400.00, "sharePercent": 40.0 },
    { "name": "Fan & light installation", "jobs": 7, "earnings": 4300.00, "sharePercent": 23.0 }
  ],

  "reputation": {
    "rating":            4.6,
    "ratingCount":        87,
    "distribution":     [58, 19, 6, 3, 1],
    "onTimeRate":       92.0,
    "unansweredReviews":   4
  },

  "availability": {
    "liveMinutes":    2680,
    "daysLive":          6,
    "daysInPeriod":      7,
    "acceptanceRate": 84.0
  },

  "reach": {
    "profileViews":       312,
    "searchImpressions": 1840,
    "callTaps":            41,
    "chatTaps":            33,
    "directionTaps":       12
  },

  "benchmark": {
    "peerGroupLabel":            "Electricians near you",
    "peerCount":                  34,
    "earningsPercentile":       68.0,
    "ratingPercentile":         81.0,
    "responsePercentile":       42.0,
    "peerMedianEarnings":    15200.00,
    "peerMedianRating":          4.3,
    "peerMedianResponseMinutes":  17
  }
}
```

A `{ "data": { ... } }` envelope is also accepted — the client unwraps either.
Pick one and stay consistent.

### Response rules

1. **Never 404 for "no work".** A worker with zero activity gets `200` with
   zeros. The app shows a "Nothing to show yet" state off the zeros; a 404 would
   show a network error instead, which is a lie.
2. **Every field is optional to the parser** and defaults to `0` / `""` / `[]`.
   Ship sections incrementally if you need to — a missing `benchmark` block
   simply hides that card. Do not send `null` for a whole section *and* expect
   the app to show something.
3. **Numbers are numbers**, not strings. `"18450.00"` parses, but don't.
4. **Money is in major units** (rupees, `18450.00`), not paise. If your ledger
   is in paise, divide before responding — one conversion in one place beats
   every client doing it.
5. **Every rate is a percentage 0–100**, never a 0–1 fraction. A `0.84` here
   renders as "1%" and tells the worker they're failing.

---

## 3. Field definitions

These definitions are the whole point of the document. Two services computing
"conversion rate" differently is how a worker ends up with a number they can't
reconcile with what they remember.

### `profession`

The worker's trade slug, exactly as stored on the earn-service profile
(`ELECTRICIAN`, `PLUMBER`, …). The app uses it only for copy. Empty is fine.

### `earnings`

| Field | Definition |
|---|---|
| `total` | Billed across jobs **completed** in the window. The hero number. |
| `collected` | Of `total`, what the worker has actually been paid. |
| `pending` | Of `total`, what customers still owe. |
| `averageJobValue` | Mean value of the completed jobs in the window. |
| `highestJobValue` | Largest single completed job in the window. |
| `previousPeriodTotal` | `total` for the **immediately preceding window of the same length** (last week for `week`, yesterday for `today`, last calendar month for `month`). |

`total` is **authoritative** — the app displays it as sent and never recomputes
it. `collected` + `pending` are an explanation and may legitimately not sum to
`total` exactly (write-offs, adjustments, part payments). Do not fudge a
category to force reconciliation.

**Attribution rule:** a job counts in the window its **completion** timestamp
falls in, not when it was booked. A job booked Friday and finished Monday
belongs to the new week.

`previousPeriodTotal` drives the up/down chip on the hero number. Send `0` when
there is no prior window (the worker's first ever week) — the app then hides the
chip rather than showing a meaningless "+100%".

### `jobs`

| Field | Definition |
|---|---|
| `completed` | Jobs finished in the window. |
| `inProgress` | Accepted and not finished **as of now**. A live count, not windowed. |
| `cancelledByWorker` | Jobs the worker accepted then cancelled. |
| `cancelledByCustomer` | Jobs the customer cancelled *after* this worker accepted. |
| `repeatCustomers` | Of `completed`, how many were for a customer who had hired **this worker** before — at any time, not just in this window. |
| `workedMinutes` | Time spent on jobs. **Not** time online; that's `availability.liveMinutes`. |

`repeatCustomers` is the single strongest health signal for a trade, so be
precise: "had hired this worker before" means a prior *completed* job, not a
prior enquiry.

If you have no reliable job-duration signal yet, send `workedMinutes: 0` rather
than estimating from job value. A made-up duration is worse than a blank.

### `funnel`

The section a tradesperson actually acts on: it separates "nobody is calling me"
from "people call and I lose them". Each step is a **subset of the one above**,
so `received ≥ responded ≥ quoted ≥ converted` must hold. The app draws the bars
scaled against `received`, so a violation renders as a bar wider than its track.

| Field | Definition |
|---|---|
| `received` | Service enquiries that reached this worker in the window (the `service_enquiry` flow — see `docs/backend/service-enquiry-api.md`). Counted by enquiry **creation** time. |
| `responded` | Of `received`, how many got any reply from the worker — a chat message or a status change. |
| `quoted` | Of `responded`, how many got a price. |
| `converted` | Of `quoted`, how many became an accepted job. |
| `medianResponseMinutes` | **Median** minutes from enquiry creation to the worker's first reply, over the enquiries in `responded`. |
| `missed` | Of `received`, how many expired/closed with no reply at all. |

`medianResponseMinutes` is a **median, not a mean**, deliberately. One enquiry
forgotten over a weekend would wreck a mean and tell the worker nothing about
their normal behaviour. Compute over `responded` only — unanswered enquiries
have no response time and belong in `missed`.

Note `responded + missed` need not equal `received`: an enquiry raised 10
minutes ago is neither yet.

### `trend`

One entry per **day**, oldest first, for the selected period:

| `period` | Entries |
|---|---|
| `today` | 1 (today) |
| `week` | 1–7 (Monday → today) |
| `month` | 1–31 (1st → today) |

- `date` is `yyyy-MM-dd` **local**.
- **Include zero days.** A day with no work is `earnings: 0, jobs: 0`, not a
  gap — the chart's shape is the point, and a missing Wednesday silently shifts
  every point after it.
- Do not send future days.
- `earnings` here uses the same completion-time attribution as
  `earnings.total`, so the trend sums to the hero number.

The app draws the chart only when there are ≥ 2 points, so `today` correctly
shows no chart.

### `topServices`

Revenue split across the services the worker lists on their **Service tab**.

| Field | Definition |
|---|---|
| `name` | A string the worker recognises from their own profile — an entry from `serviceType[]` or `serviceOffered[]`. **Never an internal id.** |
| `jobs` | Completed jobs attributed to this service in the window. |
| `earnings` | Revenue attributed to this service in the window. |
| `sharePercent` | This service's share of the window's total revenue, 0–100. |

- Sort **descending by `earnings`** — the app renders in array order.
- Cap at **6 entries**; roll the rest into a final `{ "name": "Other", ... }`
  row if the tail matters. A phone can't read more than that.
- `sharePercent` is sent rather than derived client-side precisely because the
  list is truncated: shares must be of the *true* total, not of the shown rows.
- A job spanning two services should be attributed to one (the primary), not
  split — half-jobs make `jobs` unreadable. If you must split revenue, still
  count the job once, against the primary.

### `reputation`

| Field | Definition |
|---|---|
| `rating` | Mean of customer→worker ratings, **lifetime**, not windowed. A single bad week shouldn't appear to move a lifetime score. Round to 1 decimal. |
| `ratingCount` | Number of ratings behind `rating` (lifetime). |
| `distribution` | Counts for **5★, 4★, 3★, 2★, 1★ in that order**. Exactly 5 entries; lifetime, consistent with `rating`. |
| `onTimeRate` | Jobs finished within the promised/agreed window ÷ completed × 100, for the window. |
| `unansweredReviews` | Lifetime reviews with text that the worker has not replied to. A nudge, not a score. |

Send `rating: 0, ratingCount: 0` for a worker nobody has rated — the app hides
the whole card rather than showing "0.0 ★", which reads as a terrible worker
rather than a new one.

`distribution` must sum to `ratingCount`. The app scales the bars against the
largest bucket, so an inconsistent sum shows as bars that don't match the count.

If you have no "promised completion time" concept yet, send `onTimeRate: 0` and
tell us — we'll hide that metric rather than show a hard zero, which reads as
"you are never on time".

### `availability`

Driven by the same **go-live** the Service tab toggles
(`serviceProviderStatus` / the self-work go-live gate), so the worker can
connect "I was offline Tuesday" with "Tuesday earned nothing" on the trend chart
directly above.

| Field | Definition |
|---|---|
| `liveMinutes` | Minutes live/available in the window. Sum of go-live sessions, **clipped to the window boundaries**. |
| `daysLive` | Days in the window with at least one live minute. |
| `daysInPeriod` | Days in the window so far (`today` → 1; mid-week Thursday → 4; 7th of the month → 7). Not the length of the whole calendar month. |
| `acceptanceRate` | `accepted / offered × 100` — job offers shown to this worker in the window. |

`liveMinutes` must be **clipped, not counted whole**: a session from 22:00
Sunday to 01:00 Monday contributes 120 min to Sunday and 60 to Monday. An
unclipped session double-counts across week boundaries.

Exclude offers that expired because another worker took the broadcast first —
this worker never had a real chance at those, and counting them makes the
acceptance rate a lottery result.

### `benchmark` — the "industry level" section

The worker against their own trade in their own area. This is the section that
makes the tab worth opening for someone who already knows what they earned.

| Field | Definition |
|---|---|
| `peerGroupLabel` | Human, already-pluralised, already-localised label for the peer set, e.g. `Electricians near you`. **The app does not build this string.** |
| `peerCount` | How many peers the comparison draws on. |
| `earningsPercentile` | Share of peers this worker earned **more** than, 0–100. |
| `ratingPercentile` | Share of peers this worker is rated **above**, 0–100. |
| `responsePercentile` | Share of peers this worker replies **faster** than, 0–100. |
| `peerMedianEarnings` | Peer group median for the same window. |
| `peerMedianRating` | Peer group median lifetime rating. |
| `peerMedianResponseMinutes` | Peer group median response time. |

Three rules, all load-bearing:

1. **Higher is always better, on all three percentiles.** `responsePercentile`
   must therefore be **inverted server-side** — a worker who replies faster than
   80% of peers sends `80`, not `20`. The app renders all three with identical
   colour logic and cannot tell them apart.
2. **Peer group definition:** same profession slug, within a sensible radius of
   the worker's service location (we suggest the same radius Discover uses),
   active in the same window. Say what you picked in the response headers or
   here; the worker will ask.
3. **Suppress thin groups.** Below `peerCount: 5` the app hides the card
   (`SelfWorkBenchmark.minimumPeers`), and the backend should apply the same
   floor rather than relying on the client. A comparison against three other
   electricians is noise, and in a thin market it also de-anonymises them.

**Never send raw peer identities, peer maxima, or a leaderboard.** Percentiles
and medians only. Publishing "the top electrician near you made ₹94,000" leaks a
competitor's business and invites exactly the wrong comparison.

---

## 4. Errors

| Status | When | App behaviour |
|---|---|---|
| `200` | Always, including zero activity | Renders numbers / empty state |
| `400` | `period` missing or not one of the three | Error card + Retry |
| `401` | Bad/expired token | Standard auth interceptor |
| `403` | Caller has no `selfWork` earn-service profile | Error card + Retry |
| `5xx` | — | Error card + Retry |

Error body shape follows the existing convention: `{ "message": "..." }` — the
app surfaces `message` when present.

---

## 5. Performance

This tab is opened often and casually — treat it as a read-hot endpoint.

- **Pre-aggregate.** A per-worker per-day rollup
  (`user_id, local_date, billed, collected, jobs_completed, worked_minutes,
  live_minutes, enquiries_received, enquiries_responded, enquiries_quoted,
  enquiries_converted, offers, accepted`) makes all three periods a range-sum
  over ≤ 31 rows. Do not scan enquiries and orders per request.
- **The benchmark is the expensive part.** Do not compute percentiles live per
  request. Roll peer aggregates up nightly per (profession, area) and read them;
  a benchmark that is a day stale is fine and nobody will notice.
- **Target < 400 ms p95.** The app caches per period for the life of the screen,
  so realistic load is ~3 calls per tab visit.
- Server-side cache of ~5 min per (worker, period) is welcome. A worker does not
  need second-level freshness on a summary; they have the enquiry list for that.

---

## 6. Test cases we'd like green before integrating

1. Brand-new worker, no profile activity → `200`, all zeros, `trend` one zero
   day, `benchmark.peerCount: 0`.
2. Worker with jobs today only, asking `period=week` → week totals include
   today, `trend` has the earlier zero days **present**.
3. Go-live session spanning midnight → `liveMinutes` split across both days.
4. Job booked Friday, completed Monday → counted in the **new** week.
5. `funnel` monotonicity: `received ≥ responded ≥ quoted ≥ converted` on every
   fixture.
6. One enquiry answered after 3 days, nine answered in ~10 min →
   `medianResponseMinutes` ≈ 10, not ≈ 300.
7. Customer-cancelled job → increments `cancelledByCustomer`, does **not**
   affect `acceptanceRate`.
8. Broadcast offer taken by another worker first → does **not** lower this
   worker's `acceptanceRate`.
9. Worker with no ratings → `rating: 0, ratingCount: 0`, `distribution` all
   zeros.
10. `distribution` sums to `ratingCount` on every fixture.
11. Peer group of 4 → `benchmark` omitted or `peerCount: 4` (app hides it).
12. Worker replying faster than most peers → `responsePercentile` **high**.
13. `topServices` sorted descending by `earnings`, `sharePercent` sums to ≤ 100.
14. `period=year` → `400`.
15. Worker A's token cannot retrieve worker B's numbers under any parameter.

---

## 7. Later (not needed for v1)

Listed so the rollup table doesn't have to be redesigned when they come up:

- **Per-hour buckets** for a "best hours to be live" view — the trade equivalent
  of surge awareness.
- **Area breakdown** — which localities this worker's jobs come from, to guide
  travel radius.
- **Quote win/loss reasons** — why the 13 quoted jobs that didn't convert
  didn't, if we ever capture a reason.
- **Materials vs labour split** on `earnings`, which most trades track
  separately for tax.
- **Seasonality** — this month vs the same month last year.
- **CSV/statement export** for a month.
