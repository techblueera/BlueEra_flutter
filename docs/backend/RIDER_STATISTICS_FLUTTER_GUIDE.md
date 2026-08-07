# Rider Statistics — Flutter Integration Guide

> Client counterpart to `docs/backend/RIDER_STATISTICS_API_GUIDE.md`.
> Backend endpoint is **implemented and live**: `GET /riders/statistics`.
> This guide tells the Flutter team exactly what the backend returns, **which
> fields the backend does NOT have yet**, and how the app should adapt (hide the
> card, or show `0`).

---

## 1. Endpoint

```
GET /api/rider-service/riders/statistics?period=today
Authorization: Bearer <rider JWT>
```

- `period` (**required**): `today` | `week` | `month`. Anything else → `400`.
- Rider is taken from the **JWT only** — never send a `riderId`.
- Timezone: rider's profile tz (falls back to IST). Optional `?tz=Asia/Kolkata`.

Wire the constant that already exists:

```dart
// RiderServiceApi
static const String ridersStatistics = '/riders/statistics';
```

---

## 2. ⚠️ Backend reality — what is real vs what to change on the client

The backend returns the **full contract shape**, but some numbers cannot be
sourced by `be_rider_service` today. They come back as `0` / `null` and are also
listed in `data._meta.unavailable`. **The frontend must adapt to the backend, not
the other way around.**

| Field | Backend today | What the Flutter app should do |
|---|---|---|
| `earnings.total` | ✅ Real (= `tripFare`, no deductions) | Show as the hero number |
| `earnings.tripFare` | ✅ Real (sum of completed-ride fares) | Show |
| `earnings.incentives` | ❌ Always `0` (no incentive ledger) | **Hide the incentives line**, or show `₹0` |
| `earnings.tips` | ❌ Always `0` (not captured here) | **Hide the tips line**, or show `₹0` |
| `earnings.deductions` | ❌ Always `0` (no commission engine) | **Hide the deductions line**, or show `₹0` |
| `trips.completed` | ✅ Real | Show |
| `trips.cancelledByRider` | ✅ Real (needs `cancelledBy` set on cancel) | Show |
| `trips.cancelledByCustomer` | ✅ Real (needs `cancelledBy` set on cancel) | Show |
| `trips.distanceKm` | ⚠️ Straight-line pickup→drop estimate (not billed/road km) | Show, label as "approx" if you want |
| `trips.onlineMinutes` | ❌ Always `0` (no go-live session log) | **Hide the "hours online" card**, or show `0` |
| `performance.acceptanceRate` | ⚠️ Approx = accepted / (accepted + rejected) | Show |
| `performance.completionRate` | ✅ Real | Show |
| `performance.cancellationRate` | ✅ Real (rider-caused only) | Show |
| `performance.rating` / `ratingCount` | ✅ Real (lifetime) | Show; hide block if `ratingCount == 0` |
| `trend[]` | ✅ Real (completed rides/day, zero days filled) | Draw chart when ≥ 2 points |
| `payouts.*` | ❌ Always `0` / `null` (no settlement data) | **Hide the payouts card entirely** |

**Recommended rule:** drive card visibility off `data._meta.unavailable` so the UI
auto-hides placeholder blocks and re-enables them the moment the backend starts
sending real values — no client change needed later.

```dart
// A field is a placeholder zero if the backend flagged it unavailable.
bool isUnavailable(String path) => meta.unavailable.contains(path);

// Examples:
final showPayouts   = !isUnavailable('payouts.pending');       // false today → hide card
final showOnline    = !isUnavailable('trips.onlineMinutes');   // false today → hide card
final showTips       = !isUnavailable('earnings.tips');         // false today → hide line
```

---

## 3. Response shape (live)

```jsonc
{
  "success": true,
  "data": {
    "period": "week",
    "range": { "from": "2026-08-03T00:00:00+05:30", "to": "2026-08-04T19:42:11+05:30" },
    "earnings": {
      "currency": "INR",
      "total": 4290.00,     // == tripFare (no deductions available)
      "tripFare": 4290.00,
      "incentives": 0,      // unavailable
      "tips": 0,            // unavailable
      "deductions": 0       // unavailable
    },
    "trips": {
      "completed": 39,
      "cancelledByRider": 2,
      "cancelledByCustomer": 3,
      "distanceKm": 244.8,  // straight-line estimate
      "onlineMinutes": 0    // unavailable
    },
    "performance": {
      "acceptanceRate": 91.0,
      "completionRate": 95.0,
      "cancellationRate": 5.0,
      "rating": 4.7,
      "ratingCount": 132
    },
    "trend": [
      { "date": "2026-08-03", "earnings": 812.00, "trips": 7 },
      { "date": "2026-08-04", "earnings": 742.00, "trips": 6 }
    ],
    "payouts": { "pending": 0, "lastAmount": 0, "lastPaidAt": null },
    "_meta": {
      "unavailable": [
        "earnings.incentives", "earnings.tips", "earnings.deductions",
        "trips.onlineMinutes", "payouts.pending", "payouts.lastAmount", "payouts.lastPaidAt"
      ],
      "notes": [ "earnings.total == earnings.tripFare ...", "trips.distanceKm is straight-line ...", "..." ]
    }
  }
}
```

The client unwraps `data` (a bare object without `success` is also fine).

---

## 4. Dart model

Every field defaults so a missing/zero value never crashes the parser. Also parse
`_meta.unavailable` to drive card visibility.

```dart
class RiderStatistics {
  final String period;
  final Earnings earnings;
  final Trips trips;
  final Performance performance;
  final List<TrendPoint> trend;
  final Payouts payouts;
  final StatsMeta meta;

  RiderStatistics({
    required this.period,
    required this.earnings,
    required this.trips,
    required this.performance,
    required this.trend,
    required this.payouts,
    required this.meta,
  });

  factory RiderStatistics.fromJson(Map<String, dynamic> raw) {
    // Accept both { data: {...} } and a bare object.
    final j = (raw['data'] ?? raw) as Map<String, dynamic>;
    return RiderStatistics(
      period: j['period'] as String? ?? '',
      earnings: Earnings.fromJson(j['earnings'] as Map<String, dynamic>? ?? const {}),
      trips: Trips.fromJson(j['trips'] as Map<String, dynamic>? ?? const {}),
      performance: Performance.fromJson(j['performance'] as Map<String, dynamic>? ?? const {}),
      trend: ((j['trend'] as List?) ?? const [])
          .map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      payouts: Payouts.fromJson(j['payouts'] as Map<String, dynamic>? ?? const {}),
      meta: StatsMeta.fromJson(j['_meta'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

double _d(dynamic v) => (v is num) ? v.toDouble() : 0.0;
int _i(dynamic v) => (v is num) ? v.toInt() : 0;

class Earnings {
  final String currency;
  final double total, tripFare, incentives, tips, deductions;
  Earnings({required this.currency, required this.total, required this.tripFare,
    required this.incentives, required this.tips, required this.deductions});
  factory Earnings.fromJson(Map<String, dynamic> j) => Earnings(
    currency: j['currency'] as String? ?? 'INR',
    total: _d(j['total']), tripFare: _d(j['tripFare']),
    incentives: _d(j['incentives']), tips: _d(j['tips']), deductions: _d(j['deductions']),
  );
}

class Trips {
  final int completed, cancelledByRider, cancelledByCustomer, onlineMinutes;
  final double distanceKm;
  Trips({required this.completed, required this.cancelledByRider,
    required this.cancelledByCustomer, required this.distanceKm, required this.onlineMinutes});
  factory Trips.fromJson(Map<String, dynamic> j) => Trips(
    completed: _i(j['completed']),
    cancelledByRider: _i(j['cancelledByRider']),
    cancelledByCustomer: _i(j['cancelledByCustomer']),
    distanceKm: _d(j['distanceKm']),
    onlineMinutes: _i(j['onlineMinutes']),
  );
}

class Performance {
  final double acceptanceRate, completionRate, cancellationRate, rating;
  final int ratingCount;
  Performance({required this.acceptanceRate, required this.completionRate,
    required this.cancellationRate, required this.rating, required this.ratingCount});
  factory Performance.fromJson(Map<String, dynamic> j) => Performance(
    acceptanceRate: _d(j['acceptanceRate']), completionRate: _d(j['completionRate']),
    cancellationRate: _d(j['cancellationRate']), rating: _d(j['rating']),
    ratingCount: _i(j['ratingCount']),
  );
}

class TrendPoint {
  final String date; final double earnings; final int trips;
  TrendPoint({required this.date, required this.earnings, required this.trips});
  factory TrendPoint.fromJson(Map<String, dynamic> j) =>
    TrendPoint(date: j['date'] as String? ?? '', earnings: _d(j['earnings']), trips: _i(j['trips']));
}

class Payouts {
  final double pending, lastAmount; final String? lastPaidAt;
  Payouts({required this.pending, required this.lastAmount, required this.lastPaidAt});
  factory Payouts.fromJson(Map<String, dynamic> j) =>
    Payouts(pending: _d(j['pending']), lastAmount: _d(j['lastAmount']), lastPaidAt: j['lastPaidAt'] as String?);
}

class StatsMeta {
  final List<String> unavailable;
  StatsMeta({required this.unavailable});
  factory StatsMeta.fromJson(Map<String, dynamic> j) =>
    StatsMeta(unavailable: ((j['unavailable'] as List?) ?? const []).map((e) => e.toString()).toList());
  bool has(String path) => !unavailable.contains(path); // true = backend provides it
}
```

---

## 5. Service call

```dart
Future<RiderStatistics> fetchStatistics(String period) async {
  final res = await _dio.get(
    RiderServiceApi.ridersStatistics,
    queryParameters: {'period': period}, // today | week | month
  );
  return RiderStatistics.fromJson(res.data as Map<String, dynamic>);
}
```

---

## 6. Flip the sample-data flag

```dart
// RiderStatisticsController
static const bool useSampleData = false; // ← was true
```

That is the only switch. The model + view already exist; the sections below just
say which cards to gate.

---

## 7. View: gate the unavailable cards

Use `meta.has(...)` so the UI follows the backend automatically:

```dart
// Payouts card — hidden today, appears when the settlement service is wired.
if (stats.meta.has('payouts.pending')) PayoutsCard(stats.payouts),

// Hours-online card — hidden until a go-live session log exists.
if (stats.meta.has('trips.onlineMinutes')) OnlineHoursCard(stats.trips.onlineMinutes),

// Earnings breakdown — show only the lines the backend actually fills.
EarningsCard(
  total: stats.earnings.total,
  lines: [
    ('Trip fare', stats.earnings.tripFare),
    if (stats.meta.has('earnings.incentives')) ('Incentives', stats.earnings.incentives),
    if (stats.meta.has('earnings.tips'))       ('Tips', stats.earnings.tips),
    if (stats.meta.has('earnings.deductions')) ('Deductions', -stats.earnings.deductions),
  ],
),

// Rating block — hide for a brand-new rider (0 ratings).
if (stats.performance.ratingCount > 0) RatingBlock(stats.performance),

// Trend chart — only with ≥ 2 points (so `today` shows no chart).
if (stats.trend.length >= 2) TrendChart(stats.trend),
```

> If you prefer not to hide anything, just render the `0`s — they are safe and
> correct. Either way, **do not invent client-side values for the unavailable
> fields.**

---

## 8. Errors & empty state

| Status | App behaviour |
|---|---|
| `200` (incl. all zeros) | Render numbers; "No rides in this period" off the zeros |
| `400` | period missing / invalid → error card + Retry |
| `401` | auth interceptor |
| `403` | caller is not an onboarded rider → error card + Retry |
| `5xx` | error card + Retry |

Error body is `{ "message": "..." }` — surface `message`.

---

## 9. Test cases (green before shipping)

1. New rider, zero rides → `200`, all zeros, `trend` = one zero day (today).
2. Rides today only, `period=week` → week totals include today; earlier zero days present in `trend`.
3. `period=year` → `400`.
4. Rider with no ratings → `rating: 0, ratingCount: 0` → rating block hidden.
5. Payouts card is hidden (field is in `_meta.unavailable`).
6. Ride completed 00:04 counts in the new day (completion-time attribution).
7. Rider A's token never returns rider B's numbers (no `riderId` param exists).

---

## 10. When the backend catches up (no client change needed)

The day the payment/settlement service starts feeding real `incentives`, `tips`,
`deductions`, `payouts`, or a go-live session log feeds `onlineMinutes`, the
backend will drop those entries from `_meta.unavailable` and send real numbers.
Because the UI gates on `meta.has(...)`, the cards light up automatically — you do
not need to ship a new app version.
