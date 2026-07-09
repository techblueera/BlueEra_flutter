# Laboratory Enquiry — UI Integration Guide

Customer → laboratory enquiry, mirroring the existing **hospital / hotel healthcare
enquiry** pattern. The resulting in-chat card is delivered by `be_chat_service`
(via Kafka) — this service only captures the enquiry and publishes the event.

- **Base path:** `/laboratory-enquiries`
- **Auth:** every endpoint requires `Authorization: Bearer <token>`
- **Chat card:** identical shape to hospital/hotel (`message_type: "healthcare_enquiry"`),
  only `category` differs (`"LABORATORY"`) — reuse the existing card UI, no new chat work.

---

## 1. Create an enquiry — `POST /laboratory-enquiries`

Entry point: an **"Enquire" / "Contact Lab"** CTA on a laboratory profile.

### application/json (no photos)
```json
{
  "laboratory_id": "665f0a2b8c1e4d0012a3b4c5",
  "tests": ["CBC", "Lipid Profile"],
  "purpose": ["Home sample collection"],
  "timeline": ["Within 2 days"],
  "note": "Need a morning slot"
}
```

### multipart/form-data (with up to 5 photos, e.g. a prescription)
- `payload` — a JSON **string** of the same object above
- `photos` — up to 5 image files (≤ 10 MB each)

### Rules
- `laboratory_id` is required and must be a valid id.
- At least one of `tests` / `purpose` / `timeline` **or** a non-empty `note` is required.
- `tests`, `purpose`, `timeline` are **free-form string arrays** — send whichever chips the customer selected.

### Responses
| Code | Meaning |
|---|---|
| `201` | `{ "success": true, "data": { "enquiryId": "…", "status": "pending" } }` |
| `400` | missing/invalid `laboratory_id`, empty enquiry, >5 photos, or enquiring on your own lab |
| `404` | laboratory not found |

---

## 2. Owner accepts / declines — `PUT /laboratory-enquiries/:enquiryId/status`

Only the **lab owner** on the enquiry, only while `status === "pending"`.

```json
{ "status": "accepted" }   // or "declined"
```

| Code | Meaning |
|---|---|
| `200` | `{ "data": { "enquiryId": "…", "status": "accepted" } }` |
| `400` | status must be `accepted` or `declined` |
| `403` | caller is not the owner |
| `409` | already accepted/declined |

---

## 3. Lists

Both are paginated and accept `?status=pending|accepted|declined`, `?page=`, `?limit=` (max 100).

- **Customer — enquiries I sent:** `GET /laboratory-enquiries/me`
- **Owner — enquiries on my labs (inbox):** `GET /laboratory-enquiries/owner/me`

```json
{
  "success": true,
  "data": [
    {
      "_id": "…",
      "laboratoryId": "…",
      "laboratoryName": "Diagnostic Laboratory",
      "laboratoryImage": "https://…",
      "location": "Lucknow, Mahesh Nagar",
      "tests": ["CBC"],
      "purpose": [],
      "timeline": ["Within 2 days"],
      "note": "Need a morning slot",
      "photos": ["https://…"],
      "status": "pending",
      "createdAt": "2026-07-08T…"
    }
  ],
  "pagination": { "totalCount": 1, "page": 1, "limit": 20, "totalPages": 1 }
}
```
The `laboratoryName` / `laboratoryImage` / `location` snapshot is denormalised on each
enquiry, so list rows render without any extra fetch.

---

## 4. Detail — `GET /laboratory-enquiries/:enquiryId`
Only the enquiry's customer or owner may view it (`403` otherwise).

---

## 5. The chat card (delivered by be_chat_service, not this service)

On a successful create, an in-chat **"healthcare_enquiry" card** appears in the
customer↔lab conversation. It is produced asynchronously by `be_chat_service` after
it consumes the Kafka event, so:

- The card may appear a moment after the `201` — don't block the UI on it.
- It is the **same card** already used for hospital/hotel enquiries; `category` is
  `"LABORATORY"`. No new chat-screen work is required.
- Owner accept/decline flips the same card for both parties.

---

## Quick reference

| Action | Method | Path | Role |
|---|---|---|---|
| Create enquiry | POST | `/laboratory-enquiries` | Customer |
| Accept / decline | PUT | `/laboratory-enquiries/:enquiryId/status` | Owner |
| My sent enquiries | GET | `/laboratory-enquiries/me` | Customer |
| Received inbox | GET | `/laboratory-enquiries/owner/me` | Owner |
| Enquiry detail | GET | `/laboratory-enquiries/:enquiryId` | Participant |
