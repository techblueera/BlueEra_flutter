# Frontend Integration — Vehicle Booking ("Place Order")

Backend: `be_vehicle_service` (PR #19) + `chat.service` (Kafka consumer).
All endpoints require a `Bearer <JWT>` auth header. Base path: `/vehicles/bookings`.

The booking model is **connect-style, not cart-style**: one request = one vehicle
listing. No items array, no quantity, no payment. Lifecycle:

```
pending ──(seller)──► accepted
        ──(seller)──► declined
        ──(buyer)───► cancelled      (only while still pending)
```

---

## Endpoints

| Action | Method & path | Who |
|---|---|---|
| Place order | `POST /vehicles/bookings` | Buyer |
| My sent requests | `GET /vehicles/bookings/me` | Buyer |
| Requests received | `GET /vehicles/bookings/seller/me` | Seller |
| View one booking | `GET /vehicles/bookings/:id` | Buyer or seller only |
| Accept / decline | `PUT /vehicles/bookings/:id/status` | Seller |
| Cancel | `PUT /vehicles/bookings/:id/cancel` | Buyer |

---

## 1. Place order — `POST /vehicles/bookings`

**Request body**
```json
{
  "inventoryId": "665f0a...",        // REQUIRED — the VehicleInventory id (NOT the catalog/variant id)
  "intent": "BUY",                    // REQUIRED — one of: BUY | TEST_DRIVE | EXCHANGE | INFO
  "offerPrice": 199000,               // optional, number ≥ 0, max 100_000_000_000
  "note": "Is it still available?",   // optional, string, max 2000 chars
  "photos": ["https://.../a.jpg"]     // optional, max 10 items, each must be an http(s) URL
}
```

> ⚠️ `inventoryId` is the **listing** id (`VehicleInventory`), not the catalog
> variant id. Use the id you got from the listing/detail screen.

**Success — `201`**
```json
{
  "status": true,
  "booking": { /* full booking object, see shape below */ }
}
```

---

## 2 & 3. Lists — `GET /me` and `GET /seller/me`

**Query params** (both endpoints)
- `status` — optional filter: `pending | accepted | declined | cancelled`
- `page` — default `1`
- `limit` — default `20`, max `100`

`/seller/me` accepts `status` (page/limit also work). Results sorted newest-first.

**Success — `200`**
```json
{
  "status": true,
  "page": 1,
  "limit": 20,
  "total": 37,
  "bookings": [ /* array of booking objects */ ]
}
```

---

## 4. Get one — `GET /vehicles/bookings/:id`

`200` → `{ "status": true, "booking": { ... } }`
Only the buyer or seller on that booking may read it (else `403`).

---

## 5. Accept / decline — `PUT /vehicles/bookings/:id/status`

**Request body**
```json
{ "status": "accepted" }   // "accepted" or "declined" only
```
`200` → `{ "status": true, "booking": { ...updated } }`

---

## 6. Cancel — `PUT /vehicles/bookings/:id/cancel`

No body. `200` → `{ "status": true, "booking": { ...cancelled } }`

---

## Booking object shape

Every endpoint that returns a single booking (`booking`) or a list (`bookings[]`)
uses this shape:

```json
{
  "_id": "6700...",
  "buyerId": "665a...",
  "sellerId": "665b...",
  "sellerType": "User",                 // "User" | "Business"
  "inventoryId": "665f...",
  "variantId": "6601...",
  "intent": "BUY",                      // BUY | TEST_DRIVE | EXCHANGE | INFO
  "offerPrice": 199000,                 // or null
  "note": "Is it still available?",
  "photos": ["https://.../a.jpg"],
  "snapshot": {                         // denormalized listing card — render directly, no re-fetch
    "title": "Maruti Swift VXi 2021",
    "image": "https://.../cover.jpg",
    "priceText": "₹1,99,000",           // pre-formatted Indian-grouped rupees
    "condition": "USED",
    "location": "Pune"
  },
  "status": "pending",                  // pending | accepted | declined | cancelled
  "created_at": "2026-06-22T10:00:00.000Z",
  "updated_at": "2026-06-22T10:00:00.000Z"
}
```

The `snapshot` is a self-contained card — use it to render the listing in the
booking list / chat without calling the listing API again.

---

## Error responses (handle these explicitly)

All errors return `{ "status": false, "message": "<human-readable>" }`.

| Code | When | Suggested UI |
|---|---|---|
| `400` | Bad/missing `intent`, invalid `offerPrice`/`note`/`photos`, invalid `inventoryId`, or **booking your own listing** ("You cannot book your own listing") | Inline validation / toast with `message` |
| `403` | Not a party to the booking (read), not the seller (status), not the buyer (cancel) | Hide the action; toast if hit |
| `404` | Listing not found / not available, or booking not found | "No longer available" |
| `409` | **Duplicate** — you already have a *pending* request for this listing; or status change on a non-pending booking ("Booking is already accepted/declined/cancelled") | Show existing request / refresh state |
| `422` | Listing can't be booked (un-migrated/legacy owner) | "This listing can't be booked right now." |

Notes:
- Only **one pending** request per buyer+listing is allowed (the `409` duplicate).
  After a decline/cancel the buyer **can** re-request — accepted/declined/cancelled
  rows don't block a new one.
- Accept/decline/cancel only work while `pending`; any other state → `409`. Refresh
  the booking after a `409` to show its real status.

---

## Chat side (separate)

Creating a booking and changing its status publish Kafka events to `chat.service`:
- `CREATE_VEHICLE_BOOKING` (on place order)
- `VEHICLE_BOOKING_STATUS_UPDATED` (on accept/decline/cancel)

Whatever chat.service produces from these (conversation / system message /
notification) surfaces through the **existing chat & notifications channels** — confirm
with the chat-service owner what gets emitted and that the app already renders it. No
extra polling of the vehicle service is needed for the chat card; the `snapshot` above
is included in the event payload.

---

## Contracts / testing aids already in the repo
- Swagger annotations: `src/routes/vehicleBooking.route.js`
- Postman smoke collection: `scripts/smoke/vehicle-booking.postman_collection.json`
- Smoke walkthrough: `scripts/smoke-vehicle-booking.md`
