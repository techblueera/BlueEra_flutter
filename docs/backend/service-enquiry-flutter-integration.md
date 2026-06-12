# Service Enquiry — Flutter Integration Guide

Backend status: **deployed code is live in `be_earn_with_blueera_service` + `be_chat_service`** (pending env/deploy). This guide maps the implemented backend to the Flutter client. Once the backend is deployed, flip `_useServiceEnquiryStub = false` in `DiscoverController`.

Base path: same `earn-service/*` base URL and `Authorization: Bearer <token>` header used by every other earn-service call.

---

## 1. The flow at a glance

```
Customer taps "Enquire" on a Self-Profession provider card
  → POST earn-service/service-enquiries            (JSON or multipart)
  → on HTTP 2xx: open the provider's BUSINESS chat (route = discover)
  → backend (async, via Kafka): creates the "service_enquiry" card message
    in that conversation + emits socket "newServiceEnquiryReceived"
  → card renders for both parties (socket now, history on cold open)

Provider taps Accept / Decline on the card
  → PUT earn-service/service-enquiries/{enquiryId}/status
  → backend emits socket "serviceEnquiryStatusUpdated" to BOTH parties
  → both cards flip
```

---

## 2. API 1 — Create enquiry

### `POST earn-service/service-enquiries`

**JSON variant** (no photos):

```json
{
  "provider_id": "6624a1f0c2b9e4f1a0d33b21",
  "serviceType": ["Residential"],
  "typesOfWork": ["Installation", "Repair"],
  "workCategories": ["Electrical"],
  "servicesOffered": ["AC Installation"],
  "requestType": ["Urgent / Same-day"],
  "note": "Split AC, 1.5 ton, need it done this weekend."
}
```

Rules enforced server-side (mirror your client-side submit gating):
- `provider_id` required, must be a valid Mongo ObjectId, and must belong to a **live** self-profession provider (active, not deleted) — otherwise `404 Self-profession provider not found`.
- At least one non-empty array **or** a non-empty `note`, else `400`.
- Sending only non-empty arrays is fine; absent arrays are treated as empty.
- You cannot enquire to yourself (`400`).

**Multipart variant** (1–5 photos): `multipart/form-data` with exactly these part names:

| Part      | Type        | Notes                                                |
|-----------|-------------|------------------------------------------------------|
| `payload` | string part | The JSON object above, encoded as a string.          |
| `photos`  | file part(s)| Repeated part, one per file. **Max 5, max 10 MB each.** |

Limit violations return `400 { success: false, message: "Photo upload error: …" }` — not a 500. Photos are uploaded to S3 server-side; their public URLs come back inside the chat card's `metadata.serviceEnquiry.photos`.

**Dio example:**

```dart
Future<String> createEnquiry({
  required String providerId,
  List<String> serviceType = const [],
  List<String> typesOfWork = const [],
  List<String> workCategories = const [],
  List<String> servicesOffered = const [],
  List<String> requestType = const [],
  String note = '',
  List<File> photos = const [],
}) async {
  final payload = {
    'provider_id': providerId,
    if (serviceType.isNotEmpty) 'serviceType': serviceType,
    if (typesOfWork.isNotEmpty) 'typesOfWork': typesOfWork,
    if (workCategories.isNotEmpty) 'workCategories': workCategories,
    if (servicesOffered.isNotEmpty) 'servicesOffered': servicesOffered,
    if (requestType.isNotEmpty) 'requestType': requestType,
    if (note.isNotEmpty) 'note': note,
  };

  final Response res;
  if (photos.isEmpty) {
    res = await dio.post('$earnBase/service-enquiries', data: payload);
  } else {
    final form = FormData();
    form.fields.add(MapEntry('payload', jsonEncode(payload)));
    for (final f in photos.take(5)) {
      form.files.add(MapEntry(
        'photos', // part name must be exactly "photos"
        await MultipartFile.fromFile(f.path),
      ));
    }
    res = await dio.post('$earnBase/service-enquiries', data: form);
  }

  // Backend returns 201 (not 200) — check the 2xx range / success flag,
  // never `statusCode == 200`.
  return res.data['data']['enquiryId'] as String;
}
```

**Response — `201`:**

```json
{
  "success": true,
  "message": "Enquiry sent",
  "data": { "enquiryId": "66b0c9a4e1f2a3b4c5d6e7f8", "status": "pending" }
}
```

> ⚠️ **Two deltas vs the original contract doc** (both contract-sanctioned, since the client only checks `success`/2xx):
> 1. Status code is **201**, not 200.
> 2. **`data.conversationId` is NOT returned.** The conversation is resolved asynchronously by the chat service. Open the chat the way you already planned: by the provider's userId with `route = discover` (business lane) — do not wait for or depend on a conversationId from this response.

**Errors:** `400` validation / bad `payload` JSON / photo limits, `404` provider not found, `401` auth, `500` server — all shaped `{ "success": false, "message": "…" }`.

---

## 3. API 2 — Accept / decline (provider side)

### `PUT earn-service/service-enquiries/{enquiryId}/status`

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

Semantics to handle in the UI:
- `403` — caller isn't the provider on this enquiry.
- `404` — unknown enquiryId.
- `409` — the **opposite** decision was already made (`"Enquiry has already been declined"`). Refresh the card state (see §6 GET endpoints, or rely on the socket event that already flipped it).
- **Retries are safe and encouraged**: re-sending the *same* status returns `200` and re-emits the socket event (this heals a transiently lost backend event). So on network failure, just retry the same PUT.

---

## 4. The chat card message

Created by the backend in the customer↔provider **business** conversation — the same conversation your `route = discover` chat opens. It arrives via socket (live) and via the normal message-history endpoint (cold open). No client-side message fabrication.

```jsonc
{
  "_id": "66b0c9b1e1f2a3b4c5d6e801",
  "conversation_id": "6624aa01c2b9e4f1a0d33c90",   // ← snake_case (standard message shape)
  "senderId": "6624a0b1c2b9e4f1a0d33a10",          // the customer
  "message_type": "service_enquiry",                // discriminator — switch on this
  "sub_type": "service_enquiry",
  "message": "Service enquiry",                     // list-preview fallback
  "created_at": "2026-06-12T09:30:00.000Z",         // ← snake_case
  "metadata": {
    "serviceEnquiryId": "66b0c9a4e1f2a3b4c5d6e7f8",
    "serviceEnquiry": {
      "enquiryId": "66b0c9a4e1f2a3b4c5d6e7f8",
      "providerId": "6624a1f0c2b9e4f1a0d33b21",
      "customerId": "6624a0b1c2b9e4f1a0d33a10",
      "serviceType": ["Residential"],
      "typesOfWork": ["Installation", "Repair"],
      "workCategories": ["Electrical"],
      "servicesOffered": ["AC Installation"],
      "requestType": ["Urgent / Same-day"],
      "photos": ["https://<bucket>.s3.ap-south-1.amazonaws.com/service-enquiries/….jpg"],
      "note": "Split AC, 1.5 ton, need it done this weekend.",
      "status": "pending"                            // pending | accepted | declined
    },
    "order_status": false,    // true once accepted (legacy flag, prefer serviceEnquiry.status)
    "is_cancelled": false
  }
}
```

> ⚠️ **Field naming:** the contract example showed `conversationId`/`createdAt` (camelCase), but the real message uses the chat service's standard shape — `conversation_id`, `created_at`, `sub_type` — exactly like the grocery/home-made-food pickup cards your parser already handles. `message_type`, `metadata.serviceEnquiryId`, and `metadata.serviceEnquiry` are exact. The dedicated `metadata.serviceEnquiry` object is always present (your `order`-key fallback parsing path will not be needed).

All five selection arrays are always present in `metadata.serviceEnquiry` (empty `[]` when not selected) — no null-checks needed, but keep them anyway for safety. `photos` is `[]` when none were attached, `note` is `""` when empty.

Card sides (as already designed):
- Provider (`my_message == false`): show **Accept / Decline** while `status == "pending"`.
- Customer (sender): show "Waiting for response" while pending.
- Both: render Accepted/Declined when status changes.

---

## 5. Socket events

Same Socket.IO connection you already hold to the chat service (`path: /socket`, JWT in `handshake.auth.token`). Register both listeners in `ChatViewController` / wherever `ChatEmitEvents` constants live.

### `newServiceEnquiryReceived` (server → provider, **echoed to the customer's sessions too**)

```json
{ "message": { /* full service_enquiry message object from §4, plus an embedded `conversation` object */ } }
```

Handling (same as the pickup-card events):
1. **Dedupe by `message._id`** — the customer who sent the enquiry also receives this echo.
2. If `message.conversation_id` matches the open conversation → append to the thread.
3. Always refresh the chat list.

```dart
socket.on('newServiceEnquiryReceived', (data) {
  final msg = ChatMessage.fromJson(data['message']);
  if (openConversationId == msg.conversationId && !thread.containsId(msg.id)) {
    thread.add(msg);
  }
  refreshChatList();
});
```

### `serviceEnquiryStatusUpdated` (server → both parties)

```json
{
  "messageId": "66b0c9b1e1f2a3b4c5d6e801",
  "enquiryId": "66b0c9a4e1f2a3b4c5d6e7f8",
  "status": "accepted"
}
```

Find the message by `messageId`, set `metadata.serviceEnquiry.status = status`, rebuild the card. Payload is exactly these three keys.

```dart
socket.on('serviceEnquiryStatusUpdated', (data) {
  final msg = thread.findById(data['messageId']);
  msg?.serviceEnquiry?.status = data['status'];
  // or fall back to lookup by enquiryId if the message isn't loaded yet
});
```

Note: the status event can theoretically arrive for a card not yet in the loaded thread (e.g. cold open mid-scroll) — the card from history will already carry the final status, so dropping an unmatched event is fine.

### Push notifications (background)

When the app is backgrounded, the same moments produce push notifications through the normal notification pipeline with operations `service_enquiry` (new enquiry → provider) and `service_enquiry_status` (decision → customer), carrying `message_id`, `conversation_id`, `message_type: "service_enquiry"`, `conversation_type: "business"`. Route taps to the business conversation like the pickup-order notifications.

---

## 6. Extra REST endpoints (optional, beyond the contract)

These exist if you want enquiry lists outside chat (e.g. a provider inbox screen). All require the bearer token.

| Endpoint | Who | Returns |
|---|---|---|
| `GET earn-service/service-enquiries/me?status=&page=&limit=` | customer | enquiries I sent |
| `GET earn-service/service-enquiries/provider/me?status=&page=&limit=` | provider | enquiries sent to me |
| `GET earn-service/service-enquiries/{enquiryId}` | either party | one enquiry (403 for outsiders) |

List responses: `{ success, data: [enquiry…], pagination: { totalCount, page, limit, totalPages } }`, sorted newest first, `status` filter optional (`pending`/`accepted`/`declined`), `limit` capped at 100.

---

## 7. Integration checklist

1. ☐ Keep `_useServiceEnquiryStub = true` until the backend deploy is confirmed, then flip to `false`.
2. ☐ Treat any 2xx (you'll get **201**) from API 1 as success; do not read `conversationId` from the response.
3. ☐ After API 1 success, open the provider's business chat via `route = discover` (existing behavior) — the card arrives via socket/history.
4. ☐ Multipart part names exactly `payload` (string) and `photos` (files, ≤5, ≤10 MB each).
5. ☐ Parser: switch on `message_type == "service_enquiry"`, read `metadata.serviceEnquiry` (snake_case standard fields on the envelope, camelCase inside `serviceEnquiry` — same convention as pickup cards).
6. ☐ Register `newServiceEnquiryReceived` (dedupe by `_id` — the sender gets an echo) and `serviceEnquiryStatusUpdated`.
7. ☐ Provider PUT: handle `409` by refreshing the card; retry the same decision freely on network errors (idempotent + re-emits the socket event).
8. ☐ Test cold open: the card must render from the normal message-history endpoint (backend whitelisted the new type there).
9. ☐ Test the 404 path: enquiring to a provider who deleted/deactivated their self-profession profile returns `404 Self-profession provider not found` — show a "provider no longer available" state and refresh the Discover list.
