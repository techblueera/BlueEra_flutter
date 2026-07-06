# Healthcare Doctor Appointment — UI Integration Guide

The **booking step after the hospital enquiry**: the customer requests an
appointment with a specific doctor (an OPD record); the owner accepts or
declines; the customer can cancel. Same in-chat card pattern as the enquiry —
no payment, no slot inventory (`fees` is display-only).

Owned by **be_hospital_service**. All endpoints require
`Authorization: Bearer <token>`.

**Enquiry-first flow:** after `healthcareEnquiryStatusUpdated` flips the
enquiry card to `accepted`, show a **Book Appointment** button that opens the
appointment sheet and passes the enquiry's id as `enquiry_id`. Direct booking
from the hospital's OPD/doctor list also works — `enquiry_id` is optional.

**Statuses:** `pending` → `accepted` | `declined` | `cancelled`

---

## 1. Create — `POST /hospital-appointments`

**Role:** customer (not the listing owner). JSON, or multipart with a
`payload` JSON-string part plus up to 5 `photos` files (reports/prescriptions).

| Field | Type | Required | Notes |
|---|---|---|---|
| `hospital_id` (or `hospitalId`) | string (ObjectId) | ✅ | The user-service Business._id the listing was discovered with — same id the enquiry uses. |
| `opd_id` (or `opdId`) | string (ObjectId) | ✅ | The doctor: an OPD._id from `GET /opd/department/:departmentId`. Must belong to this hospital. |
| `appointmentDate` (or `appointment_date`) | date string | ✅ | Today or later (calendar-day comparison). |
| `preferredTime` | string | ⬦ | Free text, e.g. `"10:00 – 11:00 AM"` (OPD timings are free text — render the doctor's `timing` and let the customer pick/type). |
| `patientName` | string | ⬦ | Who the appointment is for. |
| `enquiry_id` (or `enquiryId`) | string (ObjectId) | ⬦ | The customer's own enquiry on this hospital (enquiry-first flow). |
| `note` | string | ⬦ | Free text. |
| `photos` | file[] | ⬦ | Multipart only, max 5. |

The doctor's `name` / `department` / `fees` / `image` are snapshotted
**server-side** from the OPD record — do not send them.

**Success — `201`**
```json
{ "success": true, "message": "Appointment request sent", "data": { "appointmentId": "...", "status": "pending" } }
```

**Errors**

| Status | When | `message` |
|---|---|---|
| 400 | bad/missing `hospital_id` | `A valid hospital_id is required` |
| 400 | bad/missing `opd_id` | `A valid opd_id (doctor) is required` |
| 400 | bad/missing date | `A valid appointmentDate is required` |
| 400 | past date | `appointmentDate cannot be in the past` |
| 400 | malformed `enquiry_id` | `enquiry_id must be a valid id` |
| 400 | `enquiry_id` not the caller's / different hospital | `enquiry_id does not match one of your enquiries on this hospital` |
| 400 | booking own listing | `You cannot book an appointment on your own listing` |
| 400 | >5 photos | `A maximum of 5 photos is allowed` |
| 404 | hospital not found / inactive | `Hospital not found` |
| 404 | doctor not this hospital's | `Doctor not found for this hospital` |

---

## 2. Status — `PUT /hospital-appointments/:appointmentId/status`

Body `{ "status": "accepted" | "declined" | "cancelled" }`.

| status | Who may set it |
|---|---|
| `accepted` / `declined` | **owner only**, while `pending` |
| `cancelled` | **customer only**, while `pending` **or** `accepted` |

`declined` / `cancelled` are terminal → `409`. Re-sending the current status →
`200` (idempotent). Errors: `400` / `403` / `404` / `409` — same conventions
as the enquiry.

---

## 3. Lists & detail

| Endpoint | Role | Returns |
|---|---|---|
| `GET /hospital-appointments/me` | customer | Requests I sent |
| `GET /hospital-appointments/owner/me` | owner | Requests on my hospital |
| `GET /hospital-appointments/:appointmentId` | participant | One appointment |

`?status=&page=&limit=` (limit ≤ 100) with the standard `pagination` envelope.

**Document shape**
```jsonc
{
  "_id": "…",
  "customerId": "…",
  "ownerId": "…",
  "hospitalId": "…",
  "category": "HOSPITAL",
  "opdId": "…",
  "doctorName": "Dr. A. Sharma",
  "department": "Cardiology",
  "fees": 600,                    // display only — nothing is charged
  "doctorImage": "https://…",
  "appointmentDate": "2026-07-20T00:00:00.000Z",
  "preferredTime": "10:00 – 11:00 AM",
  "patientName": "R. Verma",
  "enquiryId": null,              // set in the enquiry-first flow
  "note": "…",
  "photos": ["https://…"],
  "hospitalName": "City Care Hospital",
  "hospitalImage": "https://…",
  "location": "12 MG Road, Dehradun",
  "status": "pending",
  "createdAt": "…", "updatedAt": "…"
}
```

---

## 4. The in-chat card (chat-screen team)

be_hospital_service publishes to Kafka topic `chat.service`; be_chat_service
creates/flips the card and emits the sockets.

| | |
|---|---|
| Create action | `CREATE_HEALTHCARE_BOOKING` |
| Status action | `HEALTHCARE_BOOKING_STATUS_UPDATED` |
| Chat card `message_type` | `healthcare_booking` |
| Card data path | `metadata.healthcareBooking` (id at `metadata.healthcareBookingId`) |
| Sockets | new: `newHealthcareBookingReceived` `{message}` · flip: `healthcareBookingStatusUpdated` `{messageId, bookingId, status}` |

Card `data` includes the listing snapshot (`listingName` / `listingImage` /
`location`), a `doctor` object (`opdId`, `name`, `department`, `fees`,
`image`), `appointmentDate` (ISO), `preferredTime`, `patientName`,
`enquiryId`, `note`, `photos`, `status`. Render Accept / Decline for the
owner and Cancel for the customer (while pending/accepted), exactly like the
hotel-booking card.
