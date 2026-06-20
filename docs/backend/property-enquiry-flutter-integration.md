# Property Enquiry — Flutter Integration Guide

Backend status: **NOT yet implemented.** This guide is the contract the Flutter client was built against; implement the backend to match it. It mirrors the live **Service Enquiry** flow (`service-enquiry-flutter-integration.md`) — same shapes, same socket pattern, same chat-card mechanism — but for rental **property listings** and the `booking-enquiry-service`.

While the backend is pending, the client keeps `PropertyEnquiryController._useStub = true`, which short-circuits the API calls to a success stub so the sheet → chat navigation can be exercised. **Flip it to `false` once the endpoints below are deployed.**

Base path: same `booking-enquiry-service/*` base URL and `Authorization: Bearer <token>` header used by every other property call (`booking-enquiry-service/properties`, etc.).

---

## 1. The flow at a glance

```
Customer taps the chat shortcut on a rental Discover property card
  → property-enquiry bottom sheet (purpose / intended use / requirements / timeline + note + photo)
  → POST booking-enquiry-service/property-enquiries        (JSON or multipart)
  → on HTTP 2xx: open the owner's BUSINESS chat (route = discover)
  → backend (async): creates the "property_enquiry" card message
    in that conversation + emits socket "newPropertyEnquiryReceived"
  → card renders for both parties (socket now, history on cold open)

Owner taps Accept / Decline on the card
  → PUT booking-enquiry-service/property-enquiries/{enquiryId}/status
  → backend emits socket "propertyEnquiryStatusUpdated" to BOTH parties
  → both cards flip
```

---

## 2. API 1 — Create enquiry

### `POST booking-enquiry-service/property-enquiries`

**JSON variant** (no photos):

```json
{
  "property_id": "6624a1f0c2b9e4f1a0d33b21",
  "purpose": ["Rent / Lease"],
  "intendedUse": ["Industrial / Manufacturing", "Warehouse / Storage"],
  "requirements": ["Schedule a visit", "Negotiate the price"],
  "timeline": ["Within 15 days"],
  "note": "Need ~5000 sq.ft with 3-phase power and truck access."
}
```

Rules to enforce server-side (mirror the client-side submit gating):
- `property_id` required, valid Mongo ObjectId, must belong to a **live** property listing (not deleted) — else `404 Property not found`.
- At least one non-empty array **or** a non-empty `note`, else `400`.
- Absent arrays are treated as empty.
- You cannot enquire on your **own** listing (`400`).

The four selection groups are free-form string arrays — the client sends whichever the customer ticked. Suggested known values (the client's current static catalog; treat as open, do not reject unknowns):
- `purpose`: `Buy / Purchase`, `Rent / Lease`, `Investment`, `Site visit only`
- `intendedUse`: `Residential`, `Office / Commercial`, `Retail / Shop`, `Warehouse / Storage`, `Industrial / Manufacturing`, `Other`
- `requirements`: `Schedule a visit`, `Check availability`, `Negotiate the price`, `See more photos / video`, `Get the floor plan / layout`, `Documentation & legal help`, `Loan / finance assistance`
- `timeline`: `Immediately`, `Within 15 days`, `1–3 months`, `3+ months`, `Flexible`

**Multipart variant** (1–5 photos): `multipart/form-data` with exactly these part names:

| Part      | Type         | Notes                                                  |
|-----------|--------------|--------------------------------------------------------|
| `payload` | string part  | The JSON object above, encoded as a string.            |
| `photos`  | file part(s) | Repeated part, one per file. **Max 5, max 10 MB each.** |

Photos are uploaded to S3 server-side; their public URLs come back inside the chat card's `metadata.propertyEnquiry.photos`. Limit violations return `400` (not 500).

**Response — `201`:**

```json
{
  "success": true,
  "message": "Enquiry sent",
  "data": { "enquiryId": "66b0c9a4e1f2a3b4c5d6e7f8", "status": "pending" }
}
```

> The client treats any 2xx (expect **201**) as success and does **not** read a `conversationId` from this response. The conversation is resolved asynchronously; the client opens the owner's business chat by `userId` with `route = discover`.

**Errors:** `400` validation / bad `payload` JSON / photo limits, `404` property not found, `401` auth, `500` server — all shaped `{ "success": false, "message": "…" }`.

---

## 3. API 2 — Accept / decline (owner side)

### `PUT booking-enquiry-service/property-enquiries/{enquiryId}/status`

```json
{ "status": "accepted" }   // or "declined"
```

**Response — `200`:**

```json
{
  "success": true,
  "message": "Enquiry accepted",
  "data": { "enquiryId": "66b0c9a4e1f2a3b4c5d6e7f8", "status": "accepted" }
}
```

Semantics (same as service enquiry):
- `403` — caller isn't the owner on this enquiry.
- `404` — unknown enquiryId.
- `409` — the opposite decision was already made; refresh the card (or rely on the socket event that already flipped it).
- **Retries are safe**: re-sending the same status returns `200` and re-emits the socket event.

---

## 4. The chat card message

Created by the backend in the customer↔owner **business** conversation — the same conversation the client's `route = discover` chat opens. Arrives via socket (live) and via the normal message-history endpoint (cold open). **No client-side message fabrication.**

```jsonc
{
  "_id": "66b0c9b1e1f2a3b4c5d6e801",
  "conversation_id": "6624aa01c2b9e4f1a0d33c90",   // snake_case (standard message shape)
  "senderId": "6624a0b1c2b9e4f1a0d33a10",          // the customer
  "message_type": "property_enquiry",               // discriminator — switch on this
  "sub_type": "property_enquiry",
  "message": "Property enquiry",                     // list-preview fallback
  "created_at": "2026-06-20T09:30:00.000Z",         // snake_case
  "metadata": {
    "propertyEnquiryId": "66b0c9a4e1f2a3b4c5d6e7f8",
    "propertyEnquiry": {
      "enquiryId": "66b0c9a4e1f2a3b4c5d6e7f8",
      "propertyId": "6624a1f0c2b9e4f1a0d33b21",
      "ownerId": "6624a1f0c2b9e4f1a0d33b21",
      "customerId": "6624a0b1c2b9e4f1a0d33a10",

      // Property snapshot — embed these so the card header renders without
      // re-fetching the listing. priceText is the display string (e.g. "₹45,000/mo").
      "propertyName": "Industrial Shed, MIDC Phase 2",
      "propertyImage": "https://<bucket>.s3.ap-south-1.amazonaws.com/properties/….jpg",
      "priceText": "₹45,000/mo",
      "location": "MIDC, Pune",

      // Grouped selections — always present, [] when not selected.
      "purpose": ["Rent / Lease"],
      "intendedUse": ["Industrial / Manufacturing", "Warehouse / Storage"],
      "requirements": ["Schedule a visit", "Negotiate the price"],
      "timeline": ["Within 15 days"],

      "photos": ["https://<bucket>.s3.ap-south-1.amazonaws.com/property-enquiries/….jpg"],
      "note": "Need ~5000 sq.ft with 3-phase power and truck access.",
      "status": "pending"                            // pending | accepted | declined
    },
    "order_status": false,
    "is_cancelled": false
  }
}
```

Field naming matches the chat service's standard shape — `conversation_id`, `created_at`, `sub_type` (snake_case on the envelope); the fields **inside** `propertyEnquiry` are camelCase, exactly like `serviceEnquiry`. `message_type`, `metadata.propertyEnquiryId`, and `metadata.propertyEnquiry` are exact and parsed by `MessageMetadata.fromJson`.

The client's `PropertyEnquiryModel` tolerates snake_case aliases too (`property_id`, `owner_id`, `customer_id`, `property_image`, `price_text`), but please send the camelCase keys above.

Card sides (already designed in `PropertyEnquiryMsgCard`):
- Owner (`my_message == false`): **Accept / Decline** while `status == "pending"`.
- Customer (sender): "Waiting for response" while pending.
- Both: render Accepted/Declined when status changes.

---

## 5. Socket events

Same Socket.IO connection the client already holds to the chat service. Constants live in `ChatEmitEvents` (`app_constant.dart`): `newPropertyEnquiryReceived`, `propertyEnquiryStatusUpdated`. Listeners are registered in `ChatViewController`.

### `newPropertyEnquiryReceived` (server → owner, **echoed to the customer's sessions too**)

```json
{ "message": { /* full property_enquiry message object from §4 */ } }
```

Handling (same as service enquiry / pickup cards):
1. **Dedupe by `message._id`** — the sender also receives an echo.
2. If `message.conversation_id` matches the open conversation → append to the thread.
3. Always refresh the chat list.

### `propertyEnquiryStatusUpdated` (server → both parties)

```json
{
  "messageId": "66b0c9b1e1f2a3b4c5d6e801",
  "enquiryId": "66b0c9a4e1f2a3b4c5d6e7f8",
  "status": "accepted"
}
```

Find the message by `messageId`, set `metadata.propertyEnquiry.status = status`, rebuild the card. Payload is exactly these three keys.

### Push notifications (background)

Mirror the service-enquiry pipeline with operations `property_enquiry` (new enquiry → owner) and `property_enquiry_status` (decision → customer), carrying `message_id`, `conversation_id`, `message_type: "property_enquiry"`, `conversation_type: "business"`. Route taps to the business conversation.

---

## 6. Extra REST endpoints (optional)

For enquiry lists outside chat (e.g. an owner inbox). All require the bearer token.

| Endpoint | Who | Returns |
|---|---|---|
| `GET booking-enquiry-service/property-enquiries/me?status=&page=&limit=` | customer | enquiries I sent |
| `GET booking-enquiry-service/property-enquiries/owner/me?status=&page=&limit=` | owner | enquiries on my listings |
| `GET booking-enquiry-service/property-enquiries/{enquiryId}` | either party | one enquiry (403 for outsiders) |

List responses: `{ success, data: [enquiry…], pagination: { totalCount, page, limit, totalPages } }`, newest first, `status` filter optional.

---

## 7. Integration checklist

1. ☐ Implement API 1 / API 2 + the chat-card creation and two socket emits to match §2–§5.
2. ☐ Embed the property snapshot (`propertyName` / `propertyImage` / `priceText` / `location`) in the card metadata so the header renders standalone.
3. ☐ Return **201** from API 1; do not return / require a `conversationId`.
4. ☐ Multipart part names exactly `payload` (string) and `photos` (files, ≤5, ≤10 MB each).
5. ☐ Card `message_type == "property_enquiry"`, metadata under `metadata.propertyEnquiry` (camelCase inside).
6. ☐ Emit `newPropertyEnquiryReceived` (echo to sender; client dedupes by `_id`) and `propertyEnquiryStatusUpdated` (`{ messageId, enquiryId, status }`).
7. ☐ Owner PUT: handle `409` by refreshing; the same decision is idempotent and re-emits the socket event.
8. ☐ Whitelist `property_enquiry` in the message-history endpoint so the card renders on cold open.
9. ☐ 404 path: enquiring on a deleted listing returns `404 Property not found`.
10. ☐ Once deployed, flip `PropertyEnquiryController._useStub = false` in the Flutter client.

---

## 8. Flutter touch-points (already implemented)

| Concern | File |
|---|---|
| Enquiry bottom sheet | `lib/features/common/rental/widget/property_enquiry_sheet.dart` |
| Submit / status provider (GetX) | `lib/features/common/rental/controller/property_enquiry_controller.dart` |
| Repo (API calls) | `lib/features/common/rental/repo/property_repo.dart` → `sendPropertyEnquiry`, `updatePropertyEnquiryStatus` |
| Endpoint constants | `lib/core/api/apiService/booking_enquiry_service_api.dart` → `propertyEnquiries`, `propertyEnquiryStatus` |
| Card metadata model | `lib/features/chat/auth/model/property_enquiry_model.dart` + `MessageMetadata.propertyEnquiry` |
| In-chat card | `lib/features/chat/view/business_chat/widgets/property_enquiry_msg_card.dart` |
| Card routing | `lib/features/chat/view/widget/message_card.dart` → `case "property_enquiry"` |
| Socket listeners | `lib/features/chat/auth/controller/chat_view_controller.dart` |
| Entry point | `PropertyListingCard._openChat` → `PropertyEnquirySheet.open(...)` |
