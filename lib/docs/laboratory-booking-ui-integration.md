# Laboratory Test Booking — UI Integration Guide

The **booking step for a laboratory**: the customer books a **specific test**
(a `PathologyTest` offered by the lab) — the lab analog of the hotel room-booking
and hospital doctor-appointment flows. Same in-chat card pattern as the enquiry —
no payment, no slot inventory (`price` is display-only).

Owned by **be_laboratory_service**. All endpoints require
`Authorization: Bearer <token>`.

**Enquiry-first flow:** after the customer's laboratory *enquiry* is accepted,
show a **Book Test** button that opens the booking sheet and passes the enquiry's
id as `enquiry_id`. Direct booking from the lab's test list also works —
`enquiry_id` is optional.

**Statuses:** `pending` → `accepted` | `declined` (owner decides) | `cancelled`
(customer cancels).

| Vertical | REST base | Owning service | Chat card |
|---|---|---|---|
| Laboratory test booking | `/laboratory-bookings` | be_laboratory_service | `healthcare_booking` (category `LABORATORY`) |

> ⚠️ **Chat card dependency:** the booking publishes `CREATE_HEALTHCARE_BOOKING`
> to the chat service, but the in-chat *booking* card renders only once
> `be_chat_service` adds a `CREATE_HEALTHCARE_BOOKING` consumer (not shipped
> yet — same pending dependency as hospital doctor appointments). The REST flow
> below works regardless.

---

## 0. (Optional) Upload photos first

Photos are sent as already-uploaded public URLs. Upload them before creating the
booking via the presign flow (`GET /upload/init?fileName=<name>&fileType=<mime>`),
then pass the returned `publicUrl`s in `photos[]`. Max **5**. Multipart (below)
is also supported.

---

## 1. Create — `POST /laboratory-bookings`

**Role:** customer (not the listing owner). `application/json`, or
`multipart/form-data` with a `payload` JSON-string part plus up to 5 `photos`
files (e.g. prescriptions).

| Field | Type | Required | Notes |
|---|---|---|---|
| `laboratory_id` (or `laboratoryId`) | string (ObjectId) | ✅ | The `LaboratoryProfile._id` the listing was discovered with — same id the enquiry uses. |
| `test_id` (or `testId`) | string (ObjectId) | ✅ | The `PathologyTest._id` being booked. **Must belong to this lab.** |
| `collectionMode` | string | ⬦ | `HOME` or `AT_LAB`. Defaults to `AT_LAB`. |
| `address` | string | ⬦ | **Required when `collectionMode` = `HOME`** (home sample collection). |
| `appointmentDate` (or `appointment_date`) | date string | ✅ | Today or later (calendar-day comparison). |
| `preferredTime` | string | ⬦ | **24-hour `HH:mm`** (e.g. `"09:30"`, `"14:00"`). AM/PM or `"9:30"`/`"1400"` are rejected. |
| `patientName` | string | ⬦ | Who the test is for. |
| `enquiry_id` (or `enquiryId`) | string (ObjectId) | ⬦ | The customer's accepted enquiry on this lab (enquiry-first flow). |
| `note` | string | ⬦ | Free text. |
| `photos` | file[] | ⬦ | Multipart only, max 5. |

The test's `name` / `price` / `reportHours` and the lab's `name` / `image` /
`location` are snapshotted **server-side** — do not send them.

**Example body**
```json
{
  "laboratory_id": "6a4caad7978c6634c0988871",
  "test_id": "6a4e249a60dbb66122b5789b",
  "collectionMode": "HOME",
  "address": "H.No 12, Sector 26, Chandigarh",
  "appointmentDate": "2026-07-15",
  "preferredTime": "09:30",
  "patientName": "Ravi Kumar",
  "note": "Fasting done"
}
```

**Success — `201`**
```json
{ "success": true, "message": "Booking request sent", "data": { "bookingId": "...", "status": "pending" } }
```

**Errors**

| Status | When | `message` |
|---|---|---|
| 400 | bad/missing `laboratory_id` | `A valid laboratory_id is required` |
| 400 | bad/missing `test_id` | `A valid test_id is required` |
| 400 | test not this lab's | `Test does not belong to this laboratory` |
| 400 | bad `collectionMode` | `collectionMode must be 'HOME' or 'AT_LAB'` |
| 400 | HOME without address | `address is required for HOME collection` |
| 400 | bad/missing date | `A valid appointmentDate is required` |
| 400 | past date | `appointmentDate cannot be in the past` |
| 400 | bad `preferredTime` | `preferredTime must be 24-hour HH:mm` |
| 400 | malformed `enquiry_id` | `enquiry_id must be a valid id` |
| 400 | booking own listing | `You cannot book your own listing` |
| 400 | >5 photos | `A maximum of 5 photos is allowed` |
| 404 | lab not found | `Laboratory not found` |
| 404 | test not found | `Test not found` |

---

## 2. Status — `PUT /laboratory-bookings/:bookingId/status`

Body `{ "status": "accepted" | "declined" }`. **Owner only**, while the booking
is `pending`. Re-sending the current status → `200` (idempotent). A booking that
is already `accepted`/`declined` → `409`.

| Status | `message` |
|---|---|
| 400 | `status must be 'accepted' or 'declined'` |
| 403 | not the owner |
| 404 | booking not found |
| 409 | already accepted/declined |

---

## 2b. Cancel — `PUT /laboratory-bookings/:bookingId/cancel`

No body. **Customer only** (the one who raised it), while the booking is
`pending` **or** `accepted`. Sets status to `cancelled`. Re-sending on an
already-cancelled booking → `200` (idempotent). Already `declined`/`cancelled`
by another path → `409`.

| Status | `message` |
|---|---|
| 403 | `Only the customer who raised this booking can cancel it` |
| 404 | `Booking not found` |
| 409 | already declined/cancelled |

---

## 3. Lists & detail

| Endpoint | Role | Returns |
|---|---|---|
| `GET /laboratory-bookings/me` | customer | Bookings I sent (outbox) |
| `GET /laboratory-bookings/owner/me` | owner | Bookings received on my labs (inbox) |
| `GET /laboratory-bookings/:bookingId` | customer **or** owner | A single booking (participant-only; `403` otherwise) |

The two list endpoints accept `?status=`, `?page=`, `?limit=` (default 20, max
100) and return:
```json
{ "success": true, "data": [ /* bookings, newest first */ ],
  "pagination": { "totalCount": 0, "page": 1, "limit": 20, "totalPages": 0 } }
```

Each booking document carries the denormalized snapshot for standalone rendering:
`testName`, `price`, `estimatedReportHours`, `collectionMode`, `address`,
`appointmentDate`, `preferredTime`, `patientName`, `laboratoryName`,
`laboratoryImage`, `location`, `status`, `createdAt`.

---

## 4. Client notes

- **Time is 24-hour `HH:mm`.** Use a 24-hour time picker; do not send AM/PM. The
  server rejects anything not matching `^([01]\d|2[0-3]):[0-5]\d$`.
- **`collectionMode = HOME`** → make `address` required in the sheet; `AT_LAB` →
  hide the address field.
- **Test list:** populate `test_id` from the lab's own tests
  (`GET /pathology-tests/laboratory/:laboratoryId`); show `testName` + `price`
  (`customerPrice`) on the card — the same values the server snapshots.
- **One booking = one test.** For multiple tests, create multiple bookings.
