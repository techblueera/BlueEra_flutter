# Business ("Other") Enquiry — UI Integration Guide

Enquiry flow for **"other" businesses** (the other / support / finance vertical:
banking, insurance, loans, capital-market, data, etc.) owned by
**be_other_service**.

**Flow:** customer fills an enquiry form on a business listing → backend persists
it → an **in-chat card** appears in the customer↔owner *business* conversation →
the owner accepts/declines → the card flips for both parties (realtime + push).

> ⚠️ **Not the same as `/business-enquiries`.** `be_user_service` owns
> `/business-enquiries` for **non-hospital healthcare** (doctors / labs /
> pharmacy / surgical), which renders a `healthcare_enquiry` card. This guide is
> the **separate** `/other-enquiries` endpoint for the *other/support/finance*
> vertical, which renders a distinct `business_enquiry` card. Same overall
> mechanics and request shape, different base path + card type.

| Vertical | REST base | Owning service | Chat card |
|---|---|---|---|
| Other / support / finance businesses | `/other-enquiries` | be_other_service | `business_enquiry` |

All endpoints require `Authorization: Bearer <token>`.

---

## 1. (Optional) Upload photos first

Photos are sent as **already-uploaded public URLs**, so upload them before
creating the enquiry using the presign flow:

`GET /upload/init?fileName=<name>&fileType=<mimeType>`

```json
{
  "uploadUrl": "https://<bucket>.s3.<region>.amazonaws.com/...&X-Amz-Signature=...",
  "publicUrl": "https://<bucket>.s3.<region>.amazonaws.com/<key>",
  "fileKey": "<key>"
}
```

Steps: call `/upload/init` → `PUT` the raw image bytes to `uploadUrl` (valid ~30
min) → keep the returned `publicUrl`. Pass those `publicUrl`s in `photos[]` below.
Max **5** photos.

---

## 2. Create an enquiry (customer) — `POST /other-enquiries`

`application/json` only.


```json
{
  "business_id": "<BusinessProfile._id>",
  "selections": {
    "Services": ["Home Loan", "Personal Loan"],
    "Purpose": ["Compare rates"]
  },
  "note": "optional free text",
  "photos": ["https://.../a.jpg", "https://.../b.jpg"]
}
```

- `selections` is an **open group→values map**. The app decides the group labels
  and options per business type, e.g. Finance → `Services`, `Purpose`; Insurance →
  `Policy Type`, `Purpose`. The backend stores the map as-is and the chat card
  renders it generically (each key = a section, its array = chips).
- **Rules:** at least **one selection group or a note** is required (else `400`);
  max **5 photos** (else `400`); enquiring on your **own** listing is blocked
  (`400`); business not found → `404`.

### Success response
```json
{ "success": true, "message": "Enquiry sent",
  "data": { "enquiryId": "<id>", "status": "pending" } }
```

---

## 3. Owner accepts / declines — `PUT /other-enquiries/:enquiryId/status`

```json
{ "status": "accepted" }   // or "declined"
```

- Only the listing **owner** may call this (`403` otherwise).
- Only valid while `pending`; re-sending the same decision is idempotent;
  a different decision after it's settled → `409`.

---

## 4. List & detail

| Endpoint | Who | Returns |
|---|---|---|
| `GET /other-enquiries/me` | customer | enquiries I sent |
| `GET /other-enquiries/owner/me` | owner | enquiries on my listings |
| `GET /other-enquiries/:enquiryId` | participant only | one enquiry |

Query params on the list endpoints:
`?status=pending|accepted|declined&page=1&limit=20` (limit max 100).

Response shape:
```json
{ "success": true, "data": [ /* enquiry docs */ ],
  "pagination": { "totalCount": 0, "page": 1, "limit": 20, "totalPages": 0 } }
```

An enquiry doc:
```json
{
  "_id": "<enquiryId>",
  "customerId": "<userId>",
  "ownerId": "<userId>",
  "businessId": "<BusinessProfile._id>",
  "category": "LOANS_SECTOR",
  "selections": { "Services": ["Home Loan"], "Purpose": ["Compare rates"] },
  "note": "…",
  "photos": ["https://.../a.jpg"],
  "listingName": "Acme Finance",
  "listingImage": "https://.../cover.jpg",
  "location": "MG Road, Bengaluru",
  "status": "pending",
  "createdAt": "…", "updatedAt": "…"
}
```

---

## 5. The in-chat card

A message in the **business** conversation with `message_type: "business_enquiry"`:

```json
{
  "message_type": "business_enquiry",
  "metadata": {
    "businessEnquiryId": "<enquiryId>",
    "businessEnquiry": {
      "enquiryId": "<enquiryId>",
      "listingId": "<BusinessProfile._id>",
      "ownerId": "<userId>",
      "customerId": "<userId>",
      "category": "LOANS_SECTOR",
      "listingName": "Acme Finance",
      "listingImage": "https://.../cover.jpg",
      "location": "MG Road, Bengaluru",
      "selections": { "Services": ["Home Loan"], "Purpose": ["Compare rates"] },
      "photos": ["https://.../a.jpg"],
      "note": "…",
      "status": "pending"
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
- The card does not need to resolve `listingId` — snapshot fields are denormalised.

---

## 6. Realtime (Socket.IO)

| Event | Payload | Meaning |
|---|---|---|
| `newBusinessEnquiryReceived` | `{ message }` (full message obj incl. `conversation`) | New card. Emitted to the owner; echoed to the customer's other sessions — **dedupe by `message._id`**. |
| `businessEnquiryStatusUpdated` | `{ messageId, enquiryId, status }` | Owner accepted/declined; both parties flip the card. |

---

## 7. Push notifications

- **New enquiry → owner:** "You have a new business enquiry!"
- **Status change → customer:** "Your business enquiry was accepted/declined"

Both carry `message_type: "business_enquiry"` and `conversation_type: "business"`.

---

## 8. End-to-end sequence

1. (Optional) Upload photos via `GET /upload/init` → `PUT` to S3 → collect `publicUrl`s.
2. Customer submits the form → `POST /other-enquiries`.
3. Backend persists, returns `enquiryId` (`201`), then asynchronously creates the
   chat card.
4. Owner receives `newBusinessEnquiryReceived` + push; card shows `pending`.
5. Owner taps Accept/Decline → `PUT /other-enquiries/:enquiryId/status`.
6. Both parties receive `businessEnquiryStatusUpdated`; card flips; customer gets a push.
