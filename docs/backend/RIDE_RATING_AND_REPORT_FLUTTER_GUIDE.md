# Ride Rating & Report — Flutter Integration Guide

> Client counterpart to `docs/backend/RIDE_RATING_AND_REPORT_API_GUIDE.md`.
> Both endpoints are **implemented and live** on `be_rider_service`.
> This guide gives the full URLs, request/response bodies, slug maps, Dart model
> + repo code, and exactly which 3 placeholders to replace.

---

## 1. Endpoints at a glance

| Action | Method + URL | Success |
|---|---|---|
| Rate a completed ride | `POST /api/rider-service/fare/orders/{orderId}/rate` | `200` |
| Report a problem | `POST /api/rider-service/fare/orders/{orderId}/report` | `201` |

- `{orderId}` is the **`ORD-…`** id the ride flow already uses (not a Mongo `_id`).
- Header: `Authorization: Bearer <customer JWT>` + `Content-Type: application/json`.
- The captain is derived from the order server-side — **never send a riderId.**

---

## 2. Rate a ride

### Request

```
POST /api/rider-service/fare/orders/ORD-1786100000000/rate
Authorization: Bearer <customer JWT>
Content-Type: application/json
```
```jsonc
{
  "rating": 4,                                   // REQUIRED, integer 1–5
  "tags": ["safe_driving", "polite"],            // optional, must match star set (§4)
  "comment": "Waited for me without being asked" // optional, free text
}
```

### Response `200`

```jsonc
{
  "success": true,
  "rating": 4,
  "alreadyRated": false,        // true when this call UPDATED a prior rating
  "riderRating": { "average": 4.7, "count": 133 }  // captain's aggregate AFTER this rating
}
```

### Behaviour that matters to the UI

- **Upsert, not reject.** The customer can tap stars on the Discover chip, then
  open the receipt and submit again with tags + comment — the second call
  **updates** the same record and returns `alreadyRated: true`. No `409` for a
  re-submit.
- `riderRating` is the captain's fresh aggregate — show it without a second call.

---

## 3. Report a ride

### Request

```
POST /api/rider-service/fare/orders/ORD-1786100000000/report
Authorization: Bearer <customer JWT>
Content-Type: application/json
```
```jsonc
{
  "reason": "overcharged",          // REQUIRED, slug (§4)
  "comment": "Asked for ₹80 extra"  // optional, free text
}
```

### Response `201`

```jsonc
{ "success": true, "reportId": "RPT-1786102072092", "status": "open" }
```

- **Multiple reports per order are allowed** — distinct incidents don't overwrite.
- Allowed on **completed OR cancelled** orders.
- Show the `reportId` as the reference behind "we've logged your report".

---

## 4. Slugs — exact values to send (labels are UI-only)

Map your English labels → these slugs **before** sending.

### `tags` (rating chips) — which set depends on the stars

**1–3 stars → negative set only. 4–5 stars → positive set only.** Mixing → `400`.

| Slug | Label | Set |
|---|---|---|
| `safe_driving` | Safe driving | positive |
| `polite` | Polite | positive |
| `clean_vehicle` | Clean vehicle | positive |
| `on_time` | On time | positive |
| `knows_the_route` | Knows the route | positive |
| `rash_driving` | Rash driving | negative |
| `rude_behaviour` | Rude behaviour | negative |
| `longer_route` | Took a longer route | negative |
| `kept_waiting` | Kept me waiting | negative |
| `extra_fare` | Asked for extra fare | negative |

### `reason` (report sheet)

| Slug | Label |
|---|---|
| `driver_behaviour` | Driver behaved badly |
| `overcharged` | I was overcharged |
| `unsafe_driving` | Unsafe or rash driving |
| `vehicle_mismatch` | Vehicle did not match |
| `item_left` | I left an item in the vehicle |
| `other` | Something else |

Unknown slug → `400` (surfaces typos in QA).

---

## 5. Errors

| Status | When | App behaviour |
|---|---|---|
| `200` / `201` | Success | Thank-you, clear the row |
| `400` | Bad `rating`, unknown slug, tag/star mismatch, missing `reason` | Generic retry message |
| `401` | Bad/expired token | Auth interceptor |
| `403` | Caller is not the order's customer | Generic retry message |
| `404` | Order not found | Generic retry message |
| `409` | Ride not completed / no captain / outside 30-day window (rate); order not completed-or-cancelled (report) | Generic retry message |
| `5xx` | — | Generic retry message |

Error body: `{ "message": "..." }` — surface `message`.

**Fail soft, always.** A failed submit must never block leaving the screen or the
clear-down of the finished ride. `ride_completed_screen.dart` already releases the
screen regardless of the result — keep that.

---

## 6. Client wiring

### 6.1 `RiderServiceApi`

```dart
String rateFareOrder(String orderId)   => 'rider-service/fare/orders/$orderId/rate';
String reportFareOrder(String orderId) => 'rider-service/fare/orders/$orderId/report';
```

### 6.2 Label → slug maps (put next to the existing label lists)

```dart
const kPositiveTagSlugs = <String, String>{
  'Safe driving': 'safe_driving',
  'Polite': 'polite',
  'Clean vehicle': 'clean_vehicle',
  'On time': 'on_time',
  'Knows the route': 'knows_the_route',
};
const kNegativeTagSlugs = <String, String>{
  'Rash driving': 'rash_driving',
  'Rude behaviour': 'rude_behaviour',
  'Took a longer route': 'longer_route',
  'Kept me waiting': 'kept_waiting',
  'Asked for extra fare': 'extra_fare',
};
const kReportReasonSlugs = <String, String>{
  'Driver behaved badly': 'driver_behaviour',
  'I was overcharged': 'overcharged',
  'Unsafe or rash driving': 'unsafe_driving',
  'Vehicle did not match': 'vehicle_mismatch',
  'I left an item in the vehicle': 'item_left',
  'Something else': 'other',
};
```

### 6.3 Response models

```dart
class RideRatingResult {
  final bool success;
  final int rating;
  final bool alreadyRated;
  final double riderAverage;
  final int riderCount;

  RideRatingResult({
    required this.success,
    required this.rating,
    required this.alreadyRated,
    required this.riderAverage,
    required this.riderCount,
  });

  factory RideRatingResult.fromJson(Map<String, dynamic> j) {
    final rr = (j['riderRating'] as Map<String, dynamic>?) ?? const {};
    return RideRatingResult(
      success: j['success'] == true,
      rating: (j['rating'] as num?)?.toInt() ?? 0,
      alreadyRated: j['alreadyRated'] == true,
      riderAverage: (rr['average'] as num?)?.toDouble() ?? 0.0,
      riderCount: (rr['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class RideReportResult {
  final bool success;
  final String reportId;
  final String status;
  RideReportResult({required this.success, required this.reportId, required this.status});
  factory RideReportResult.fromJson(Map<String, dynamic> j) => RideReportResult(
        success: j['success'] == true,
        reportId: j['reportId'] as String? ?? '',
        status: j['status'] as String? ?? 'open',
      );
}
```

### 6.4 `RideBookingRepo` (both are `rider-service` routes → this repo, not ChatViewRepo)

```dart
Future<RideRatingResult> rateRide({
  required String orderId,
  required int rating,
  List<String> tags = const [],
  String? comment,
}) async {
  final res = await _dio.post(
    _api.rateFareOrder(orderId),
    data: {
      'rating': rating,
      if (tags.isNotEmpty) 'tags': tags,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    },
  );
  return RideRatingResult.fromJson(res.data as Map<String, dynamic>);
}

Future<RideReportResult> reportRide({
  required String orderId,
  required String reason,
  String? comment,
}) async {
  final res = await _dio.post(
    _api.reportFareOrder(orderId),
    data: {
      'reason': reason,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    },
  );
  return RideReportResult.fromJson(res.data as Map<String, dynamic>);
}
```

### 6.5 Replace the three placeholders

| File | Method | Was | Now |
|---|---|---|---|
| `ongoing_booking_chip.dart` | `_rateAndClear` | `debugPrint` + snackbar | `repo.rateRide(orderId, rating: stars)` (stars only) |
| `ride_completed_screen.dart` | `_submit` | 600 ms fake delay | `repo.rateRide(orderId, rating: stars, tags: slugs, comment: text)` |
| `ride_completed_screen.dart` | `_submitReport` | `log(...)` | `repo.reportRide(orderId, reason: slug, comment: text)` |

Client-side guard before sending tags (mirrors the server so a mistake surfaces
locally): pick the slug map by star value.

```dart
final tagMap = stars <= 3 ? kNegativeTagSlugs : kPositiveTagSlugs;
final tagSlugs = selectedLabels.map((l) => tagMap[l]).whereType<String>().toList();
```

Wrap both calls so a failure never blocks screen clear-down:

```dart
try {
  final r = await repo.rateRide(orderId: orderId, rating: stars);
  // optionally show r.riderAverage; r.alreadyRated tells you it was an update
} catch (_) {
  // fail soft — show a light snackbar, still release the screen
}
```

---

## 7. Test cases (green before shipping)

1. Rate 5, no tags/comment → `200`, `riderRating` reflects it.
2. Rate 2 with negative tags → `200`; the same tags with a 5 → `400`.
3. Rate from chip (stars only), then from receipt with tags + comment → **one**
   record, `alreadyRated: true`.
4. Rate an in-flight order → `409`.
5. Rate someone else's order → `403`.
6. Rate a 40-day-old ride → `409`.
7. `rating: 0` / `6` / `4.5` → `400` each.
8. Two different reports on one order → two `reportId`s.
9. Report a **cancelled** order → `201`.
10. Unknown tag / reason slug → `400`.
11. Captain's `performance.rating` in `/riders/statistics` matches the mean of
    accepted ratings (the rate endpoint recomputes `Rider.ratings` on every write).

---

## 8. Notes

- The rating loop closes `performance.rating` / `ratingCount` in the Statistics
  tab (`RIDER_STATISTICS_FLUTTER_GUIDE.md`) — no extra client change needed there.
- `comment` is currently optional for every reason, including `other`. If you want
  it enforced for `other`, do it client-side; the server can be tightened to
  require it on request.
