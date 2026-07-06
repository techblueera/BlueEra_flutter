# UI Integration Guide — Hotel Enquiry & Booking

Frontend integration reference for the **Hotel Enquiry** and **Hotel Booking** features
added in PR #9 (`SB/feat: hotel enquiry + booking → chat service`).

Both features follow the same pattern: a customer raises an enquiry/booking from a hotel
listing, it is persisted and returned over REST **and** rendered as an in-chat card in
`be_chat_service`. The owner accepts/declines (and, for bookings, the customer can cancel)
either from the inbox screens documented here or directly from the chat card.

- **Base URL**: `/api`
- **Auth**: every endpoint requires a Bearer token — `Authorization: Bearer <jwt>`.
  The caller's user id is taken from the token; never send `customerId`/`ownerId` in the body.
- **Response envelope**: success `{ success: true, ... }`; error `{ success: false, message, error? }`.
- **The `businessId === userId` rule**: a hotel's owner id is the owner's user `_id`. The UI
  never computes this — it sends `hotel_id` and the server resolves the owner.

---

## Part 1 — Hotel Enquiry

A lightweight "I'm interested" message: the customer ticks any of four free-form selection
groups (room type / purpose / amenities / timeline) and/or writes a note, optionally attaching
photos. The owner accepts or declines.

**Statuses:** `pending` → `accepted` | `declined`

### 1.1 Create enquiry — `POST /api/hotel-enquiries`

**Role:** customer (any logged-in user who is not the listing owner).

Accepts **either** `application/json` **or** `multipart/form-data`:

- **JSON** — send fields directly in the body.
- **Multipart** — send a single `payload` field containing the JSON string of the body, plus up
  to **5** `photos` file parts (field name `photos`). Use multipart only when attaching photos.

**Body fields**

| Field | Type | Required | Notes |
|---|---|---|---|
| `hotel_id` (or `hotelId`) | string (ObjectId) | ✅ | The `HotelProfile._id`. Must be a valid ObjectId. |
| `roomType` | string[] | ⬦ | Free-form. Whatever the customer ticked. |
| `purpose` | string[] | ⬦ | Free-form. |
| `amenities` | string[] | ⬦ | Free-form. |
| `timeline` | string[] | ⬦ | Free-form. |
| `note` | string | ⬦ | Free text. |
| `photos` | file[] | ⬦ | Multipart only, **max 5**. |

⬦ = optional individually, but the request must contain **at least one** non-empty selection
array **or** a non-empty `note`, otherwise `400`.

**Success — `201`**
```json
{ "success": true, "message": "Enquiry sent", "data": { "enquiryId": "...", "status": "pending" } }
```

**Errors**

| Status | When | `message` |
|---|---|---|
| 400 | bad/missing `hotel_id` | `A valid hotel_id is required` |
| 400 | no selection and no note | `At least one selection (roomType / purpose / amenities / timeline) or a note is required` |
| 400 | enquiring on own listing | `You cannot enquire on your own listing` |
| 400 | >5 photos | `A maximum of 5 photos is allowed` |
| 400 | malformed multipart `payload` | `Invalid JSON in payload field` |
| 404 | hotel does not exist | `Hotel not found` |

> Note: the `201` is returned **before** the chat card is created (the chat event is
> fire-and-forget). Treat `201` as success even if the card takes a moment to appear, and never
> block the UI on the card.

**Example (JSON)**
```http
POST /api/hotel-enquiries
Authorization: Bearer <jwt>
Content-Type: application/json

{ "hotel_id": "665f...", "roomType": ["Deluxe"], "purpose": ["Family trip"], "note": "3 nights in July" }
```

**Example (multipart with photos)** — `payload` is the JSON string, `photos` are files:
```
payload = {"hotel_id":"665f...","amenities":["Pool","Breakfast"]}
photos  = <file1.jpg>, <file2.jpg>
```

### 1.2 Update enquiry status — `PUT /api/hotel-enquiries/:enquiryId/status`

**Role:** **owner only** (the listing owner on the enquiry).

**Body:** `{ "status": "accepted" | "declined" }`

**Success — `200`**
```json
{ "success": true, "message": "Enquiry accepted", "data": { "enquiryId": "...", "status": "accepted" } }
```

**Errors**

| Status | When |
|---|---|
| 400 | invalid id, or status not `accepted`/`declined` |
| 403 | caller is not the owner (`Only the owner on this enquiry can update its status`) |
| 404 | enquiry not found |
| 409 | already resolved (`Enquiry has already been accepted/declined`) |

Re-sending the **same** status the enquiry already has returns `200` (idempotent), not `409`.
The UI should disable accept/decline once the enquiry leaves `pending`.

### 1.3 Lists & detail

| Endpoint | Role | Returns |
|---|---|---|
| `GET /api/hotel-enquiries/me` | customer | Enquiries **I sent** (outbox) |
| `GET /api/hotel-enquiries/owner/me` | owner | Enquiries **on my listings** (inbox) |
| `GET /api/hotel-enquiries/:enquiryId` | customer **or** owner | A single enquiry |

**Query params** (both list endpoints):

| Param | Default | Notes |
|---|---|---|
| `status` | — | Optional filter: `pending` / `accepted` / `declined`. Invalid → 400. |
| `page` | `1` | 1-based. |
| `limit` | `20` | Clamped to `1..100`. |

**List response — `200`**
```json
{
  "success": true,
  "data": [ /* enquiry documents, newest first */ ],
  "pagination": { "totalCount": 42, "page": 1, "limit": 20, "totalPages": 3 }
}
```

`GET /:enquiryId` returns `{ "success": true, "data": { /* enquiry */ } }`, or `403`
(`You are not a participant of this enquiry`) if the caller is neither the customer nor the owner.

**Enquiry document shape**
```jsonc
{
  "_id": "…",
  "customerId": "…",        // user id of the sender
  "ownerId": "…",           // user id of the listing owner
  "hotelId": "…",
  "roomType": ["Deluxe"],
  "purpose": ["Family trip"],
  "amenities": [],
  "timeline": [],
  "note": "3 nights in July",
  "photos": ["https://…", "…"],   // public S3 URLs
  "hotelName": "Sea View Resort",  // denormalised snapshot
  "hotelImage": "https://…",       // coverUrl, falls back to logoUrl
  "priceText": "₹4,500/night",     // cheapest active room; "" if none
  "location": "Goa, India",        // "" if unknown
  "status": "pending",
  "createdAt": "2026-06-29T…Z",
  "updatedAt": "2026-06-29T…Z"
}
```

---

## Part 2 — Hotel Booking

A booking *request* the owner accepts or declines and the customer can cancel. Two levels:

- **Type-level** (legacy, unchanged): customer proposes free-text `roomType` + optional dates.
- **Room-level** (new): customer books a **specific room** (`room_id` from the hotel's rooms
  list). The server derives `roomName`/`roomType` and a **price snapshot** from the Room doc and
  **enforces availability** against `Room.totalRooms` for the date range. Nothing is charged —
  amounts are display-only.

**Enquiry-first flow:** after the owner accepts a hotel enquiry, open the booking sheet and pass
the enquiry's id as `enquiry_id` so the booking is linked back to it. Direct booking (no
enquiry) also works — the field is optional.

**Statuses:** `pending` → `accepted` | `declined` | `cancelled`

### 2.1 Create booking — `POST /api/hotel-bookings`

**Role:** customer (not the listing owner). Same JSON-or-multipart convention as enquiry
(`payload` + up to 5 `photos`).

**Body fields**

| Field | Type | Required | Notes |
|---|---|---|---|
| `hotel_id` (or `hotelId`) | string (ObjectId) | ✅ | Valid ObjectId. |
| `room_id` (or `roomId`) | string (ObjectId) | ⬦ | A Room of this hotel. Sending it makes the booking **room-level**: dates become required, `roomName`/`roomType`/price come from the Room, availability is enforced. |
| `enquiry_id` (or `enquiryId`) | string (ObjectId) | ⬦ | The customer's own hotel enquiry on this hotel (enquiry-first flow). |
| `roomType` | string | ⬦ | Single string. Ignored when `room_id` is sent (server uses the Room's type). |
| `checkIn` (or `check_in`) | date string | ⬦ (✅ with `room_id`) | Any `Date`-parseable value (ISO recommended). |
| `checkOut` (or `check_out`) | date string | ⬦ (✅ with `room_id`) | Must be **after** `checkIn`. |
| `guests` | integer | ⬦ | Coerced to `>= 1`; defaults to `1`. |
| `note` | string | ⬦ | Free text. |
| `photos` | file[] | ⬦ | Multipart only, max 5. |

There is **no "at least one field" rule** for bookings — only `hotel_id` is strictly required.

**Success — `201`**
```json
{ "success": true, "message": "Booking request sent", "data": { "bookingId": "...", "status": "pending" } }
```

**Errors**

| Status | When | `message` |
|---|---|---|
| 400 | bad/missing `hotel_id` | `A valid hotel_id is required` |
| 400 | malformed `room_id` | `room_id must be a valid id` |
| 400 | `room_id` without both dates | `checkIn and checkOut are required when booking a room` |
| 400 | malformed `enquiry_id` | `enquiry_id must be a valid id` |
| 400 | `enquiry_id` not the caller's / different hotel | `enquiry_id does not match one of your enquiries on this hotel` |
| 400 | `checkOut <= checkIn` | `checkOut must be after checkIn` |
| 400 | booking own listing | `You cannot book your own listing` |
| 400 | >5 photos | `A maximum of 5 photos is allowed` |
| 400 | malformed multipart `payload` | `Invalid JSON in payload field` |
| 404 | hotel does not exist | `Hotel not found` |
| 404 | room not this hotel's / inactive | `Room not found for this hotel` |
| 409 | all rooms of that type accepted for overlapping dates | `Room is not available for the selected dates` (`code: "ROOM_NOT_AVAILABLE"`) |

**Availability rule (room-level only):** only **accepted** bookings consume inventory. Creation
is rejected with `409` when the count of accepted, date-overlapping bookings for that room
already reaches `totalRooms`; the same check runs again when the owner accepts (see 2.2). The
interval is half-open — checkout day frees the room.

### 2.2 Update booking status — `PUT /api/hotel-bookings/:bookingId/status`

**Body:** `{ "status": "accepted" | "declined" | "cancelled" }`

**Role rules** — enforced server-side; mirror them in the UI:

| status | Who may set it |
|---|---|
| `accepted` | **owner only** |
| `declined` | **owner only** |
| `cancelled` | **customer only** (the one who raised it) |

**Transition rules**
- Owner may accept/decline only while `pending`.
- Customer may cancel while **`pending` or `accepted`** (not after it's terminal).
- `declined` and `cancelled` are **terminal** → `409` on further changes.
- Re-sending the current status → `200` (idempotent).
- **Room-level bookings:** accepting re-checks availability; if the room's inventory is already
  fully accepted for overlapping dates the accept fails with `409`
  (`code: "ROOM_NOT_AVAILABLE"`, message `All rooms of this type are already booked for these
  dates — accepting would overbook`). Surface this to the owner as "room full for these dates".

**Success — `200`**
```json
{ "success": true, "message": "Booking accepted", "data": { "bookingId": "...", "status": "accepted" } }
```

**Errors:** `400` (invalid id / invalid status value), `403` (wrong role — message differs for
cancel vs accept/decline), `404` (not found), `409` (terminal/already resolved).

### 2.3 Lists & detail

| Endpoint | Role | Returns |
|---|---|---|
| `GET /api/hotel-bookings/me` | customer | Bookings **I sent** |
| `GET /api/hotel-bookings/owner/me` | owner | Bookings **on my hotels** |
| `GET /api/hotel-bookings/:bookingId` | customer **or** owner | A single booking |

Same `status` / `page` / `limit` query params and same `pagination` envelope as enquiries
(`status` filter allows `pending` / `accepted` / `declined` / `cancelled`).

**Booking document shape**
```jsonc
{
  "_id": "…",
  "customerId": "…",
  "businessId": "…",        // owner user id (note: "businessId", not "ownerId")
  "hotelId": "…",
  "roomType": "Deluxe",     // single string
  "checkIn": "2026-07-10T00:00:00.000Z",   // may be null
  "checkOut": "2026-07-13T00:00:00.000Z",  // may be null
  "guests": 2,
  "roomId": "…",            // null on type-level bookings
  "roomName": "Deluxe Sea View",           // "" on type-level bookings
  "pricePerNight": 4500,    // Room.pricePerDay snapshot; 0 on type-level
  "nights": 3,
  "totalAmount": 13500,     // pricePerNight × nights — display only, never charged
  "enquiryId": "…",         // null unless enquiry-first flow
  "note": "…",
  "photos": ["https://…"],
  "hotelName": "Sea View Resort",
  "hotelImage": "https://…",
  "priceText": "₹4,500/night",
  "location": "Goa, India",
  "status": "pending",
  "createdAt": "2026-06-29T…Z",
  "updatedAt": "2026-06-29T…Z"
}
```

> ⚠️ **Field-name difference:** the enquiry owner field is **`ownerId`**; the booking owner field
> is **`businessId`**. Both hold the same thing (the owner's user id) — don't assume one name.

---

## Part 3 — The in-chat card (chat-screen team)

After a successful create/status-update, `be_hotel_service` publishes a Kafka event on topic
`chat.service` and `be_chat_service` turns it into / updates a card in the customer↔owner
business conversation. This is **fire-and-forget** — if `KAFKA_BROKERS` is unset or the broker
is down, the REST call still succeeds and only the chat card is skipped.

**Chat messages**

| Feature | `message_type` | metadata id field |
|---|---|---|
| Enquiry | `hotel_enquiry` | `metadata.hotelEnquiryId` |
| Booking | `hotel_booking` | `metadata.hotelBookingId` |

**Realtime socket events emitted by the chat service** (consume on the chat screen):
`newHotelEnquiryReceived`, `hotelEnquiryStatusUpdated`, `newHotelBookingReceived`,
`hotelBookingStatusUpdated`.

The card carries the denormalised snapshot (`hotelName`, `hotelImage`, `priceText`, `location`)
so it renders without re-fetching the hotel. The **exact card payload and consumer contract live
in `be_chat_service`** (`BOOKING_ENQUIRY_CONSUMERS.md`) — confirm field names there before
building the card component. The status-update event flips the existing card in place.

---

## Part 4 — UI checklist

- [ ] Send `Authorization: Bearer <jwt>` on every call; never send `customerId`/`ownerId`.
- [ ] **Create**: use multipart (`payload` + `photos`) only when attaching photos; otherwise JSON.
- [ ] Enquiry create requires **≥1 selection or a note**; surface the 400 message inline.
- [ ] Hide/disable "enquire"/"book" on the user's **own** listings (server returns 400 anyway).
- [ ] Booking: validate `checkOut > checkIn` client-side; default `guests` to 1.
- [ ] **Role-gate action buttons**: owner sees accept/decline; customer sees cancel (booking only).
      Still handle `403` defensively.
- [ ] Disable status actions once an item is non-`pending` (booking: customer may still cancel an
      `accepted` one); handle `409` gracefully.
- [ ] Two tabs per feature: "Sent" (`/me`) and "Received" (`/owner/me`), both paginated
      (`page`/`limit`, `limit` max 100) with an optional `status` filter.
- [ ] Render the snapshot fields directly from the list/detail payload — no extra hotel fetch.
- [ ] `priceText`/`location` can be empty strings — render a sensible fallback.
- [ ] On the chat screen, render the `hotel_enquiry`/`hotel_booking` cards and listen for the four
      socket events; reconcile card status with the REST detail when needed.

> Live request/response schemas are also in Swagger at `/api-docs`. Backend internals and the full
> Kafka event contracts are in `BOOKING_ENQUIRY_IMPLEMENTATION.md`; a ready-to-run request sequence
> is in `requests/hotel-enquiry-booking.http`.
