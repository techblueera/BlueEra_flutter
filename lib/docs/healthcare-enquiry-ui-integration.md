# Healthcare Enquiry — UI Integration Guide

A single enquiry flow for **all** healthcare categories (hospitals, doctors, labs,
pharmacy, surgical, and any future one).

**Flow:** customer fills an enquiry form on a listing → backend persists it → an
**in-chat card** appears in the customer↔owner *business* conversation → the
owner accepts/declines → the card flips for both parties (realtime + push).

There are two REST producers but **one identical chat card and realtime/notification
contract**, so the app builds the card UI only once.

| Category | REST base | Owning service |
|---|---|---|
| Hospitals | `/hospital-enquiries` | be_hospital_service |
| Doctors, Labs, Pharmacy, Surgical (any non-hospital) | `/business-enquiries` | be_user_service |

All endpoints require `Authorization: Bearer <token>`.

---

## 1. Create an enquiry (customer)

### Hospitals — `POST /hospital-enquiries`
Accepts `application/json`, **or** `multipart/form-data` with a `payload` part
(JSON string of the same fields) plus up to 5 `photos` files (≤10 MB each).

```json
{
  "hospital_id": "<Hospital._id>",
  "departments": ["Cardiology"],
  "purpose": ["Consultation"],
  "timeline": ["This week"],
  "note": "optional free text"
}
```

### Non-hospital — `POST /business-enquiries`
`application/json`. Photos are passed as **already-uploaded public URLs** (upload
them first via the presign flow at `GET /upload/init`).

```json
{
  "business_id": "<Business._id>",
  "selections": {
    "Test Types": ["Blood Test", "X-Ray"],
    "Purpose": ["Home collection"]
  },
  "note": "optional free text",
  "photos": ["https://.../a.jpg", "https://.../b.jpg"]
}
```

### Rules (both)
- At least **one selection or a note** is required, else `400`.
- Max **5 photos**, else `400`.
- Enquiring on your **own** listing is blocked (`400`).
- Listing not found → `404`.

### Selection groups are app-defined
Group labels are free-form strings the backend stores as-is. The app decides the
groups per category, e.g.:
- Hospitals → `Departments`, `Purpose`, `Timeline`
- Labs → `Test Types`, `Purpose`
- Pharmacy → `Product Type`, `Purpose`
- Doctors → `Specialization`, `Purpose`, `Timeline`

> Note: the hospital endpoint takes `departments`/`purpose`/`timeline` as named
> arrays for backward reasons; the business endpoint takes the generic
> `selections` map. **The chat card always receives the generic `selections`
> map** (see §4), so card rendering is uniform.

### Success response
```json
{ "success": true, "message": "Enquiry sent",
  "data": { "enquiryId": "<id>", "status": "pending" } }
```

---

## 2. Owner accepts / declines

`PUT /hospital-enquiries/:enquiryId/status`
`PUT /business-enquiries/:enquiryId/status`

```json
{ "status": "accepted" }   // or "declined"
```

- Only the listing **owner** may call this (`403` otherwise).
- Only valid while `pending`; re-sending the same decision is idempotent;
  a different decision after it's settled → `409`.

---

## 3. List & detail

| Endpoint | Who | Returns |
|---|---|---|
| `GET .../me` | customer | enquiries I sent |
| `GET .../owner/me` | owner | enquiries on my listings |
| `GET .../:enquiryId` | participant only | one enquiry |

Query params on the list endpoints:
`?status=pending|accepted|declined&page=1&limit=20` (limit max 100).

Response shape:
```json
{ "success": true, "data": [ /* enquiry docs */ ],
  "pagination": { "totalCount": 0, "page": 1, "limit": 20, "totalPages": 0 } }
```

---

## 4. The in-chat card

A message in the **business** conversation with `message_type: "healthcare_enquiry"`:

```json
{
  "message_type": "healthcare_enquiry",
  "metadata": {
    "healthcareEnquiryId": "<enquiryId>",
    "healthcareEnquiry": {
      "enquiryId": "<enquiryId>",
      "category": "HOSPITAL",            // or the business's category_Of_Business
      "listingId": "<Hospital._id or businessId>",
      "ownerId": "<userId>",
      "customerId": "<userId>",
      "listingName": "City Care Hospital",
      "listingImage": "https://.../cover.jpg",
      "location": "Sector 12, Noida",
      "selections": { "Departments": ["Cardiology"], "Purpose": ["Consultation"] },
      "photos": ["https://.../a.jpg"],
      "note": "…",
      "status": "pending"                // pending | accepted | declined
    }
  }
}
```

**Rendering:**
- Header from `listingName` / `listingImage` / `location`.
- Iterate `selections`: each key = a section title, its array = chips.
- Show `note` and `photos` if present.
- `status` drives the card state; show accept/decline actions to the **owner**
  only while `pending`.
- Use `category` for any category-specific styling or deep-link target. The card
  does not need to resolve `listingId` — the snapshot fields are denormalised.

---

## 5. Realtime (Socket.IO)

| Event | Payload | Meaning |
|---|---|---|
| `newHealthcareEnquiryReceived` | `{ message }` (full message obj incl. `conversation`) | New card. Emitted to the owner; echoed to the customer's other sessions — **dedupe by `message._id`**. |
| `healthcareEnquiryStatusUpdated` | `{ messageId, enquiryId, status }` | Owner accepted/declined; both parties flip the card. |

---

## 6. Push notifications

- **New enquiry → owner:** "You have a new healthcare enquiry!"
- **Status change → customer:** "Your healthcare enquiry was accepted/declined"

Both carry `message_type: "healthcare_enquiry"` and `conversation_type: "business"`.

---

## 7. End-to-end sequence

1. Customer submits the form → `POST .../{hospital|business}-enquiries`.
2. Backend persists, returns `enquiryId` (`201`), then asynchronously creates the
   chat card.
3. Owner receives `newHealthcareEnquiryReceived` + push; card shows `pending`.
4. Owner taps Accept/Decline → `PUT .../:enquiryId/status`.
5. Both parties receive `healthcareEnquiryStatusUpdated`; card flips; customer
   gets a push.
