# Property Enquiry — Frontend (Flutter) Integration Guide

Backend status: **IMPLEMENTED & DEPLOYABLE.** This is the definitive guide for the Flutter client to implement the property-enquiry flow against the **live** backend. It supersedes the "backend pending" contract note (`property-enquiry-flutter-integration.md`); the shapes here are what the deployed `booking-enquiry-service` actually returns and what `be_chat_service` actually emits.

The flow mirrors the live **Service Enquiry** flow (same socket pattern, same chat-card mechanism) but for property listings.

> The client was already wired against a success stub (`PropertyEnquiryController._useStub = true`). Use this guide to **verify each piece against the live shapes below**, then **flip `_useStub = false`**.

Base path: same `booking-enquiry-service/*` base URL and `Authorization: Bearer <token>` header used by every other property call.

---

## 0. TL;DR for the implementer

1. Build the create request (JSON or multipart) → `POST booking-enquiry-service/property-enquiries`.
2. Treat any **2xx (expect 201)** as success. Do **not** read a `conversationId` from the response.
3. On success, open the **owner's BUSINESS chat** by the owner's `userId` with `route = discover`. (The owner id is `property.userId` — the listing owner.)
4. The backend asynchronously creates the `property_enquiry` chat card and emits `newPropertyEnquiryReceived`. Render the card from `metadata.propertyEnquiry`; **dedupe by `message._id`**.
5. Owner taps Accept/Decline → `PUT …/property-enquiries/{enquiryId}/status` → both cards flip via `propertyEnquiryStatusUpdated`.

---

## 1. The flow at a glance

```
Customer taps the chat shortcut on a rental Discover property card
  → property-enquiry bottom sheet (purpose / intended use / requirements / timeline + note + photos)
  → POST booking-enquiry-service/property-enquiries        (JSON or multipart)
  → on HTTP 2xx (201): open the owner's BUSINESS chat (route = discover)
  → backend (async): creates the "property_enquiry" card message
    in that conversation + emits socket "newPropertyEnquiryReceived"
  → card renders for both parties (socket live, history on cold open)

Owner taps Accept / Decline on the card
  → PUT booking-enquiry-service/property-enquiries/{enquiryId}/status
  → backend emits socket "propertyEnquiryStatusUpdated" to BOTH parties
  → both cards flip
```

---

## 2. Endpoint constants

`lib/core/api/apiService/booking_enquiry_service_api.dart`

```dart
class BookingEnquiryServiceApi {
  // Reuse the existing booking-enquiry-service base URL.
  static const String _base = 'booking-enquiry-service';

  /// POST (create) — JSON or multipart.
  static const String propertyEnquiries = '$_base/property-enquiries';

  /// PUT (owner accept/decline). Append `/$enquiryId/status`.
  static String propertyEnquiryStatus(String enquiryId) =>
      '$_base/property-enquiries/$enquiryId/status';

  /// Optional inbox/outbox lists.
  static const String myPropertyEnquiries = '$_base/property-enquiries/me';
  static const String ownerPropertyEnquiries = '$_base/property-enquiries/owner/me';
  static String propertyEnquiryById(String enquiryId) =>
      '$_base/property-enquiries/$enquiryId';
}
```

---

## 3. API 1 — Create enquiry

### `POST booking-enquiry-service/property-enquiries`

Accepts **either** `application/json` **or** `multipart/form-data`.

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

Server-side rules the client should pre-gate to avoid round-trips:
- `property_id` required & a valid Mongo ObjectId — else **400**. (`propertyId` is also accepted as an alias.)
- At least **one non-empty selection array OR a non-empty `note`** — else **400**.
- Listing must exist and be live — else **404 `Property not found`** (covers deleted/inactive listings).
- You cannot enquire on your **own** listing — **400**.
- Absent arrays are treated as empty; the four groups are free-form (send whatever the user ticked).

**Multipart variant** (1–5 photos): `multipart/form-data` with exactly these part names:

| Part      | Type         | Notes                                                  |
|-----------|--------------|--------------------------------------------------------|
| `payload` | string part  | The JSON object above, encoded as a **string**.        |
| `photos`  | file part(s) | Repeated part, one per file. **Max 5, max 10 MB each.** |

Photos are uploaded to S3 server-side; their public URLs come back inside the chat card's `metadata.propertyEnquiry.photos`. Limit violations return **400** (not 500).

**Response — `201`:**

```json
{
  "success": true,
  "message": "Enquiry sent",
  "data": { "enquiryId": "66b0c9a4e1f2a3b4c5d6e7f8", "status": "pending" }
}
```

> The response carries **no `conversationId`**. After a 2xx, open the owner's business chat by `userId` with `route = discover`; the card is resolved asynchronously.

### Suggested selection catalog (open — backend never rejects unknown values)

- `purpose`: `Buy / Purchase`, `Rent / Lease`, `Investment`, `Site visit only`
- `intendedUse`: `Residential`, `Office / Commercial`, `Retail / Shop`, `Warehouse / Storage`, `Industrial / Manufacturing`, `Other`
- `requirements`: `Schedule a visit`, `Check availability`, `Negotiate the price`, `See more photos / video`, `Get the floor plan / layout`, `Documentation & legal help`, `Loan / finance assistance`
- `timeline`: `Immediately`, `Within 15 days`, `1–3 months`, `3+ months`, `Flexible`

### Repo methods

`lib/features/common/rental/repo/property_repo.dart`

```dart
/// Build the JSON payload once; reused for both variants.
Map<String, dynamic> _enquiryPayload({
  required String propertyId,
  List<String> purpose = const [],
  List<String> intendedUse = const [],
  List<String> requirements = const [],
  List<String> timeline = const [],
  String note = '',
}) => {
      'property_id': propertyId,
      'purpose': purpose,
      'intendedUse': intendedUse,
      'requirements': requirements,
      'timeline': timeline,
      'note': note,
    };

/// JSON variant (no photos).
Future<Response> sendPropertyEnquiry(Map<String, dynamic> payload) {
  return dio.post(
    BookingEnquiryServiceApi.propertyEnquiries,
    data: payload,
    options: Options(headers: {'Content-Type': 'application/json'}),
  );
}

/// Multipart variant (1–5 photos). `payload` is the SAME json, json-encoded.
Future<Response> sendPropertyEnquiryWithPhotos(
  Map<String, dynamic> payload,
  List<File> photos,
) async {
  assert(photos.length <= 5, 'Max 5 photos');
  final form = FormData.fromMap({
    'payload': jsonEncode(payload),
    'photos': [
      for (final f in photos)
        await MultipartFile.fromFile(f.path, filename: p.basename(f.path)),
    ],
  });
  return dio.post(BookingEnquiryServiceApi.propertyEnquiries, data: form);
}

/// Owner accept/decline.
Future<Response> updatePropertyEnquiryStatus(String enquiryId, String status) {
  return dio.put(
    BookingEnquiryServiceApi.propertyEnquiryStatus(enquiryId),
    data: {'status': status}, // "accepted" | "declined"
  );
}
```

### Controller (GetX) — submit + flip the stub

`lib/features/common/rental/controller/property_enquiry_controller.dart`

```dart
class PropertyEnquiryController extends GetxController {
  // 🔴 FLIP THIS to false now that the backend is live.
  static const bool _useStub = false;

  final isSubmitting = false.obs;

  Future<bool> submit({
    required String propertyId,
    required String ownerUserId, // = property.userId — used to open the chat
    List<String> purpose = const [],
    List<String> intendedUse = const [],
    List<String> requirements = const [],
    List<String> timeline = const [],
    String note = '',
    List<File> photos = const [],
  }) async {
    // Client-side submit gating (mirror the server rules).
    final hasSelection = [purpose, intendedUse, requirements, timeline]
        .any((g) => g.isNotEmpty);
    if (!hasSelection && note.trim().isEmpty) {
      showError('Pick at least one option or write a note.');
      return false;
    }

    isSubmitting.value = true;
    try {
      if (_useStub) {
        await Future.delayed(const Duration(milliseconds: 400));
        _openOwnerChat(ownerUserId);
        return true;
      }

      final payload = repo._enquiryPayload(
        propertyId: propertyId, purpose: purpose, intendedUse: intendedUse,
        requirements: requirements, timeline: timeline, note: note.trim(),
      );

      final res = photos.isEmpty
          ? await repo.sendPropertyEnquiry(payload)
          : await repo.sendPropertyEnquiryWithPhotos(payload, photos);

      final ok = res.statusCode != null &&
          res.statusCode! >= 200 && res.statusCode! < 300;
      if (ok) {
        // Do NOT wait for a conversationId — open the business chat directly.
        _openOwnerChat(ownerUserId);
        return true;
      }
      showError(res.data?['message'] ?? 'Could not send enquiry.');
      return false;
    } on DioException catch (e) {
      showError(e.response?.data?['message'] ?? 'Could not send enquiry.');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void _openOwnerChat(String ownerUserId) {
    // Open the owner's BUSINESS conversation. route=discover (same lane the
    // backend resolves the card into).
    openBusinessChatByUserId(ownerUserId, route: 'discover');
  }

  Future<void> respond(String enquiryId, String status) async {
    // status: "accepted" | "declined"
    try {
      await repo.updatePropertyEnquiryStatus(enquiryId, status);
      // The socket event will flip the card; no optimistic write required.
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Already decided elsewhere — the socket already flipped it. Ignore/refresh.
        return;
      }
      showError(e.response?.data?['message'] ?? 'Could not update enquiry.');
    }
  }
}
```

---

## 4. API 2 — Accept / decline (owner side)

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

Semantics:
- **400** — invalid enquiry id, or `status` not `accepted`/`declined`.
- **403** — caller isn't the owner on this enquiry.
- **404** — unknown enquiryId.
- **409** — the opposite decision was already made; refresh the card (or just rely on the socket event that already flipped it).
- **Idempotent**: re-sending the same status returns **200** and re-emits the socket event (safe to retry).

---

## 5. The chat card message

Created by the backend in the customer↔owner **business** conversation (the one your `route = discover` chat opens). Arrives via socket (live) and via the normal message-history endpoint (cold open). **No client-side message fabrication.**

```jsonc
{
  "_id": "66b0c9b1e1f2a3b4c5d6e801",
  "conversation_id": "6624aa01c2b9e4f1a0d33c90",   // snake_case (standard envelope)
  "senderId": "6624a0b1c2b9e4f1a0d33a10",          // the customer (string)
  "message_type": "property_enquiry",               // switch on this
  "sub_type": "property_enquiry",
  "message": "Property enquiry",                     // list-preview fallback
  "created_at": "2026-06-20T09:30:00.000Z",         // snake_case
  "metadata": {
    "propertyEnquiryId": "66b0c9a4e1f2a3b4c5d6e7f8",
    "propertyEnquiry": {
      "enquiryId": "66b0c9a4e1f2a3b4c5d6e7f8",
      "propertyId": "6624a1f0c2b9e4f1a0d33b21",
      "ownerId":    "6624a0b1c2b9e4f1a0d33a99",      // the listing owner (string)
      "customerId": "6624a0b1c2b9e4f1a0d33a10",      // the enquirer (string)

      // Property snapshot — embedded by the backend so the card header renders
      // without re-fetching the listing.
      "propertyName": "Industrial Shed, MIDC Phase 2",
      "propertyImage": "https://<bucket>.s3.ap-south-1.amazonaws.com/properties/….jpg",
      "priceText": "₹45,000/mo",                     // display string, ready to render
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

Naming: the **envelope** is snake_case (`conversation_id`, `created_at`, `sub_type`); fields **inside** `propertyEnquiry` are camelCase. All ids inside `propertyEnquiry` are **strings**. `message_type`, `metadata.propertyEnquiryId` and `metadata.propertyEnquiry` are exact and parsed by `MessageMetadata.fromJson`.

### Model

`lib/features/chat/auth/model/property_enquiry_model.dart`

```dart
class PropertyEnquiryModel {
  final String enquiryId;
  final String propertyId;
  final String ownerId;
  final String customerId;
  final String propertyName;
  final String propertyImage;
  final String priceText;
  final String location;
  final List<String> purpose;
  final List<String> intendedUse;
  final List<String> requirements;
  final List<String> timeline;
  final List<String> photos;
  final String note;
  final String status; // pending | accepted | declined

  const PropertyEnquiryModel({
    required this.enquiryId,
    required this.propertyId,
    required this.ownerId,
    required this.customerId,
    required this.propertyName,
    required this.propertyImage,
    required this.priceText,
    required this.location,
    required this.purpose,
    required this.intendedUse,
    required this.requirements,
    required this.timeline,
    required this.photos,
    required this.note,
    required this.status,
  });

  bool get isPending  => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';

  static List<String> _strList(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : const [];

  factory PropertyEnquiryModel.fromJson(Map<String, dynamic> j) {
    // Tolerate snake_case aliases too, but the backend sends camelCase.
    String pick(List<String> keys) {
      for (final k in keys) {
        final val = j[k];
        if (val != null) return val.toString();
      }
      return '';
    }
    return PropertyEnquiryModel(
      enquiryId:    pick(['enquiryId', 'enquiry_id']),
      propertyId:   pick(['propertyId', 'property_id']),
      ownerId:      pick(['ownerId', 'owner_id']),
      customerId:   pick(['customerId', 'customer_id']),
      propertyName: pick(['propertyName', 'property_name']),
      propertyImage:pick(['propertyImage', 'property_image']),
      priceText:    pick(['priceText', 'price_text']),
      location:     pick(['location']),
      purpose:      _strList(j['purpose']),
      intendedUse:  _strList(j['intendedUse'] ?? j['intended_use']),
      requirements: _strList(j['requirements']),
      timeline:     _strList(j['timeline']),
      photos:       _strList(j['photos']),
      note:         pick(['note']),
      status:       (j['status'] ?? 'pending').toString(),
    );
  }

  PropertyEnquiryModel copyWith({String? status}) => PropertyEnquiryModel(
        enquiryId: enquiryId, propertyId: propertyId, ownerId: ownerId,
        customerId: customerId, propertyName: propertyName,
        propertyImage: propertyImage, priceText: priceText, location: location,
        purpose: purpose, intendedUse: intendedUse, requirements: requirements,
        timeline: timeline, photos: photos, note: note,
        status: status ?? this.status,
      );
}
```

In `MessageMetadata.fromJson`, parse `metadata.propertyEnquiry` into this model (alongside `propertyEnquiryId`), exactly like `serviceEnquiry`.

### Card sides — `property_enquiry_msg_card.dart`

`lib/features/chat/view/widget/message_card.dart` → `case "property_enquiry": return PropertyEnquiryMsgCard(...)`.

| Viewer | While `status == "pending"` | After decision |
|---|---|---|
| **Owner** (`my_message == false`) | Show **Accept / Decline** buttons → call `controller.respond(enquiryId, status)` | Show Accepted/Declined state |
| **Customer** (sender, `my_message == true`) | Show "Waiting for response" | Show Accepted/Declined state |

Header renders straight from the snapshot: `propertyImage`, `propertyName`, `priceText`, `location` — no extra fetch. Render the four selection chip-groups (omit empty arrays), the note, and the photo thumbnails.

---

## 6. Socket events

Use the **same Socket.IO connection** the client already holds to the chat service. Register listeners in `ChatViewController`; add the event names to `ChatEmitEvents` (`app_constant.dart`).

### `newPropertyEnquiryReceived` (server → owner, echoed to the customer's sessions too)

```json
{ "message": { /* full property_enquiry card object from §5, plus message.conversation */ } }
```

Handling (same as service enquiry / pickup cards):
1. **Dedupe by `message._id`** — the sender receives an echo of their own card.
2. If `message.conversation_id` matches the open conversation → append to the thread.
3. Always refresh the chat list (last-message preview = "Property enquiry").

### `propertyEnquiryStatusUpdated` (server → both parties)

```json
{ "messageId": "66b0c9b1e1f2a3b4c5d6e801", "enquiryId": "66b0c9a4e1f2a3b4c5d6e7f8", "status": "accepted" }
```

Find the message by `messageId`, set `metadata.propertyEnquiry.status = status`, rebuild the card. Payload is **exactly** these three keys.

### Listener wiring

`lib/features/chat/auth/controller/chat_view_controller.dart`

```dart
void registerPropertyEnquiryListeners(Socket socket) {
  socket.on(ChatEmitEvents.newPropertyEnquiryReceived, (data) {
    final msg = (data is Map) ? data['message'] as Map<String, dynamic>? : null;
    if (msg == null) return;
    final id = msg['_id']?.toString();
    if (id == null || _seenMessageIds.contains(id)) return; // dedupe
    _seenMessageIds.add(id);

    final convId = msg['conversation_id']?.toString();
    if (convId == openConversationId) appendMessage(msg);
    refreshChatList();
  });

  socket.on(ChatEmitEvents.propertyEnquiryStatusUpdated, (data) {
    if (data is! Map) return;
    final messageId = data['messageId']?.toString();
    final status = data['status']?.toString();
    if (messageId == null || status == null) return;
    updateMessageInPlace(messageId, (m) {
      m['metadata']?['propertyEnquiry']?['status'] = status;
      return m;
    });
  });
}
```

```dart
// app_constant.dart
class ChatEmitEvents {
  static const newPropertyEnquiryReceived = 'newPropertyEnquiryReceived';
  static const propertyEnquiryStatusUpdated = 'propertyEnquiryStatusUpdated';
}
```

---

## 7. Push notifications (background)

Mirror the service-enquiry pipeline. The backend emits push with:
- operation `property_enquiry` (new enquiry → **owner**)
- operation `property_enquiry_status` (decision → **customer**)

Each carries `message_id`, `conversation_id`, `message_type: "property_enquiry"`, `conversation_type: "business"`. Route taps to the **business** conversation (the same one the in-app socket card lives in).

---

## 8. Optional REST lists (inbox/outbox outside chat)

All require the bearer token.

| Endpoint | Who | Returns |
|---|---|---|
| `GET booking-enquiry-service/property-enquiries/me?status=&page=&limit=` | customer | enquiries I sent |
| `GET booking-enquiry-service/property-enquiries/owner/me?status=&page=&limit=` | owner | enquiries on my listings |
| `GET booking-enquiry-service/property-enquiries/{enquiryId}` | either party | one enquiry (403 for outsiders) |

List response shape:

```json
{
  "success": true,
  "data": [ { /* enquiry doc */ } ],
  "pagination": { "totalCount": 42, "page": 1, "limit": 20, "totalPages": 3 }
}
```

`status` filter optional (`pending`|`accepted`|`declined`); newest first. Each enquiry doc has: `_id, customerId, ownerId, propertyId, purpose, intendedUse, requirements, timeline, note, photos, propertyName, propertyImage, priceText, location, status, createdAt, updatedAt`.

---

## 9. Error handling

All errors are shaped `{ "success": false, "message": "…" }`. Surface `message` to the user.

| Code | When | Client action |
|---|---|---|
| 400 | bad/missing `property_id`, no selection & no note, own listing, bad `payload` JSON, photo > 5 / > 10 MB | Show `message`; keep the sheet open to fix input |
| 401 | missing/expired/malformed token | Re-auth |
| 403 | (status) caller not the owner | Hide owner actions for non-owners |
| 404 | property not found / inactive (create); unknown enquiryId (status) | Show "Listing unavailable" / refresh |
| 409 | (status) already accepted/declined | Ignore — socket already flipped the card; optionally refresh |
| 500 | server | Generic retry |

---

## 10. Implementation checklist

1. ☐ `BookingEnquiryServiceApi` constants for create / status / lists (§2).
2. ☐ Repo: `sendPropertyEnquiry` (JSON) + `sendPropertyEnquiryWithPhotos` (multipart `payload`+`photos`, ≤5, ≤10 MB) + `updatePropertyEnquiryStatus` (§3–§4).
3. ☐ Controller: submit gating, treat **2xx** as success, open owner business chat `route=discover` by `ownerUserId` (= `property.userId`); **no `conversationId` read**.
4. ☐ `PropertyEnquiryModel.fromJson` parses `metadata.propertyEnquiry` (camelCase; ids are strings) (§5).
5. ☐ `message_card.dart` routes `case "property_enquiry"` → `PropertyEnquiryMsgCard`; owner sees Accept/Decline while pending, customer sees "Waiting for response".
6. ☐ Header renders from the embedded snapshot (`propertyName`/`propertyImage`/`priceText`/`location`) — no extra fetch.
7. ☐ Register socket listeners `newPropertyEnquiryReceived` (dedupe by `_id`, echo-safe) and `propertyEnquiryStatusUpdated` (`{messageId, enquiryId, status}`) (§6).
8. ☐ History cold-open: the card is already whitelisted server-side; confirm it renders when re-opening the chat.
9. ☐ Push routing for operations `property_enquiry` / `property_enquiry_status` → business conversation (§7).
10. ☐ **Flip `PropertyEnquiryController._useStub = false`.**

---

## 11. Flutter touch-points (already scaffolded against the stub)

| Concern | File |
|---|---|
| Enquiry bottom sheet | `lib/features/common/rental/widget/property_enquiry_sheet.dart` |
| Submit / status provider (GetX) | `lib/features/common/rental/controller/property_enquiry_controller.dart` |
| Repo (API calls) | `lib/features/common/rental/repo/property_repo.dart` |
| Endpoint constants | `lib/core/api/apiService/booking_enquiry_service_api.dart` |
| Card metadata model | `lib/features/chat/auth/model/property_enquiry_model.dart` + `MessageMetadata.propertyEnquiry` |
| In-chat card | `lib/features/chat/view/business_chat/widgets/property_enquiry_msg_card.dart` |
| Card routing | `lib/features/chat/view/widget/message_card.dart` → `case "property_enquiry"` |
| Socket listeners | `lib/features/chat/auth/controller/chat_view_controller.dart` |
| Entry point | `PropertyListingCard._openChat` → `PropertyEnquirySheet.open(...)` |
| Stub flag | `PropertyEnquiryController._useStub` → set **false** |
```
