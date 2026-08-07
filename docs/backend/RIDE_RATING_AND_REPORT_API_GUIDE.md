# Ride Rating & Report API — backend guide

The customer-side ride flow collects a **star rating** and, separately, a
**report**, at the end of every ride. Neither has anywhere to go: there is no
customer→captain feedback endpoint on the ride service. Both are currently
acknowledged locally with a snackbar and dropped.

This document is the complete contract for the two endpoints that close that
gap. It is written **from the UI that already exists**, so nothing here is
speculative about what the app can send — every field below is something the
customer is being asked for on screen today.

Where it is collected:

| Surface | File | Collects |
|---|---|---|
| Completed-ride chip on Discover | `lib/features/common/Discover/widget/ongoing_booking_chip.dart` (`_InlineRatingStars`) | stars only |
| End-of-ride summary | `lib/features/ride_booking/view/ride_completed_screen.dart` (`_submit`) | stars + tags + comment |
| Report sheet on that screen | same file (`_submitReport`) | one reason |

There is already a **rider→customer** rating in production
(`RiderServiceApi.rateCustomer`). This is its twin in the other direction, and
it should behave the same way wherever the two overlap — same once-per-order
rule, same duplicate response — so neither side needs its own mental model.

---

## 1. Why two endpoints and not one

A rating and a report answer different questions and must not share a record:

* A **rating** is about the ride. Every ride can have one, most are 4–5 stars,
  and the aggregate is a public-ish number that feeds the captain's dashboard.
* A **report** is an incident. It is rare, it needs a human, and it must be
  routable to someone whose job is to act on it. Filing it as a 1-star rating
  with a comment buries it in an average.

They are also reachable independently in the UI: a customer can report a ride
without rating it, and vice versa.

---

## 2. `POST` rate a completed ride

```
POST /api/rider-service/fare/orders/{orderId}/rate
Authorization: Bearer <customer JWT>
Content-Type: application/json

{
  "rating":  4,                                   // REQUIRED, integer 1–5
  "tags":    ["safe_driving", "polite"],          // optional, see §4
  "comment": "Waited for me without being asked"  // optional, free text
}
```

**Order-scoped, not rider-scoped.** The order already knows which captain drove
it, so the client cannot pass the wrong rider id — and it can't pass one at all
for a ride whose captain payload arrived incomplete. (The symmetric alternative,
`/riders/{riderId}/rate` with `orderId` in the body, mirrors `rateCustomer` more
literally; we prefer the order path for that reason, but either is fine as long
as the server derives the captain from the order rather than trusting the
client.)

`{orderId}` is the `ORD-…` id the whole ride flow uses, not a Mongo `_id`.

### Response `200`

```jsonc
{
  "success": true,
  "rating": 4,
  "alreadyRated": false,      // true when this call UPDATED an existing rating
  "riderRating": {            // the captain's aggregate AFTER this rating
    "average": 4.7,
    "count": 133
  }
}
```

Returning the fresh aggregate is not decoration — it lets the app show the
captain's updated score without a second call, and it is how we verify the
rating actually landed rather than trusting a 200.

### Rules

1. **Once per (order, customer) — as an UPSERT, not a rejection.** The app has
   two paths into this call and the customer may reach both: they can tap the
   stars on the Discover chip, then open the receipt and submit again with tags
   and a comment. The second call must **update** the first record and return
   `alreadyRated: true`, not `409`. A rejection there would silently throw away
   the more detailed feedback.
   *(This is the one place we deliberately differ from `rateCustomer`, which
   rejects duplicates. The rider side has a single entry point; this one has
   two.)*
2. **Only the customer on the order.** Any other caller → `403`.
3. **Only a completed ride.** Rating a cancelled or in-flight order → `409`.
   The app never offers it, so this is a safety net, not a flow.
4. **`rating` is an integer 1–5.** Reject `0`, reject decimals. The UI cannot
   produce either.
5. **A rating window.** After 30 days, `409`. Feedback about a ride nobody
   remembers helps no one, and an open-ended window is an abuse surface.

### Where the number goes

This is the source for `performance.rating` / `performance.ratingCount` in
`docs/backend/RIDER_STATISTICS_API_GUIDE.md` — that guide specifies them as the
**lifetime** mean of customer→rider ratings, which is exactly what this endpoint
accumulates. Today those fields are served from an empty set. Wiring this closes
that loop; no client change is needed for it.

---

## 3. `POST` report a problem with a ride

```
POST /api/rider-service/fare/orders/{orderId}/report
Authorization: Bearer <customer JWT>
Content-Type: application/json

{
  "reason":  "overcharged",             // REQUIRED, slug — see §4
  "comment": "Asked for ₹80 extra"      // optional, free text
}
```

### Response `201`

```jsonc
{
  "success": true,
  "reportId": "RPT-1786102072092",
  "status": "open"
}
```

Returning a `reportId` matters: right now the app tells the customer *"we've
logged your report and will look into it"* and has nothing to back that claim
with. With an id it can show a reference, and later a status.

### Rules

1. **Multiple reports per order are allowed.** Different problems, different
   reports — "I was overcharged" and "I left an item in the vehicle" are not the
   same incident and must not overwrite each other.
2. **Only the customer on the order.** Any other caller → `403`.
3. **Completed OR cancelled orders both count.** A ride that was cancelled badly
   is exactly the sort of thing worth reporting.
4. **`item_left` is time-critical.** If you route reports anywhere, route that
   one first — a phone left in a car is worth minutes, not days.

### Overlap with Customer Care — read this before building

There is already a customer-facing support path:
`POST chat-service/support/order-support`
(`docs/backend/ORDER_CUSTOMER_SUPPORT_FLUTTER_GUIDE.md`), which opens a **2-way
chat thread** with the ride team, keyed per order.

The difference is deliberate:

| | Customer Care sheet | Report sheet |
|---|---|---|
| Where | During or after a ride | End-of-ride summary only |
| Shape | Reason + note → **opens a conversation** | One tap on a reason → fire and forget |
| Customer expects | To talk to someone | To have flagged something |

**If you would rather have one system, say so and we will drop the report
endpoint** and route the report sheet into `order-support` instead — the app
change is small (it is the same reason list, and the sheet already knows the
order id). What must NOT happen is both existing and diverging: two places to
look for "what did customers complain about" is how complaints go unread. Pick
one and tell us which.

---

## 4. Slugs — the exact values the app will send

The app currently holds these as English display labels. It will map them to the
slugs below before sending, so copy can be reworded without breaking your
analytics. **These slugs are the contract; the labels are not.**

### `tags` — rating feedback chips

Which set the customer sees depends on the stars: **1–3 shows the negative set,
4–5 the positive set.** Never both, so a payload mixing them is a client bug
worth rejecting with `400`.

| Slug | Label shown | Set |
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

Unknown slugs → `400`, so a typo surfaces in QA rather than silently vanishing
into a column nobody reads.

### `reason` — report sheet

| Slug | Label shown |
|---|---|
| `driver_behaviour` | Driver behaved badly |
| `overcharged` | I was overcharged |
| `unsafe_driving` | Unsafe or rash driving |
| `vehicle_mismatch` | Vehicle did not match |
| `item_left` | I left an item in the vehicle |
| `other` | Something else |

`other` is the only one that really wants the free-text `comment`. Consider
making `comment` required when `reason == "other"` — a bare "Something else" is
unactionable, and the app can enforce it once you confirm.

---

## 5. Errors

| Status | When | App behaviour |
|---|---|---|
| `200` / `201` | Success | Thanks-you, row clears |
| `400` | Bad `rating`, unknown slug, missing `reason` | Generic retry message |
| `401` | Bad/expired token | Standard auth interceptor |
| `403` | Caller is not the order's customer | Generic retry message |
| `409` | Order not completed / outside the rating window | Generic retry message |
| `5xx` | — | Generic retry message |

Error body: `{ "message": "..." }` — the app surfaces `message` when it is a
sentence a customer can act on.

**Fail soft, always.** Feedback failing must never block the customer from
leaving the screen or clear-down of the finished ride. The app already treats it
this way (`ride_completed_screen.dart` releases the screen regardless of the
submit result) and that behaviour will not change.

---

## 6. Test cases we'd like green before integrating

1. Rate 5 with no tags and no comment → `200`, aggregate reflects it.
2. Rate 2 with negative tags → `200`; the same tags sent with a 5 → `400`.
3. Rate from the chip (stars only), then again from the receipt with tags +
   comment → **one** record, updated, `alreadyRated: true`.
4. Rating an in-flight order → `409`.
5. Rating someone else's order with a valid token → `403`.
6. Rating a 40-day-old ride → `409`.
7. `rating: 0`, `rating: 6`, `rating: 4.5` → `400` each.
8. Two different reports on one order → two `reportId`s, neither overwritten.
9. Report on a **cancelled** order → `201`.
10. Unknown tag slug / unknown reason slug → `400`.
11. A captain's `performance.rating` in `riders/statistics` matches the mean of
    the ratings this endpoint accepted.

---

## 7. Later (not needed for v1)

- **Tip on top of the rating.** The summary screen has room and it is a common
  ask; it needs a payment leg, so it is not v1.
- **Report status back to the customer** — `reportId` → `open / reviewing /
  resolved`, so "we'll look into it" can become something they can check.
- **Rider's view of their own ratings** — the tag histogram is more useful to a
  captain than the average is ("clean vehicle ×40" tells them what to keep
  doing).
- **Auto-flag on repeat slugs** — three `extra_fare` reports on one captain in a
  week is a signal that should not wait for someone to run a query.

---

## 8. Client wiring (for us, once the endpoints exist)

Nothing below needs backend input; recorded so the handoff is one step.

1. Add to `RiderServiceApi`:
   `String rateFareOrder(String orderId) => 'rider-service/fare/orders/$orderId/rate';`
   `String reportFareOrder(String orderId) => 'rider-service/fare/orders/$orderId/report';`
2. Add `rateRide` / `reportRide` to `RideBookingRepo` (both are `rider-service`
   routes, so this repo is the right home — unlike the customer-care call, which
   is chat-service and lives on `ChatViewRepo`).
3. Replace the three placeholders:
   - `ongoing_booking_chip.dart` → `_rateAndClear` (currently `debugPrint` + snackbar)
   - `ride_completed_screen.dart` → `_submit` (currently a 600 ms fake delay)
   - `ride_completed_screen.dart` → `_submitReport` (currently `log`)
4. Add the label→slug maps from §4 next to the existing label lists.
