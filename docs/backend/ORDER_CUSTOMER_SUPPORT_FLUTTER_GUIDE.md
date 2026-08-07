# Order Customer Support — Flutter Integration Guide

> **Wire the ride "Customer Care" sheet to a real backend.** Today
> `ride_customer_care_sheet.dart` → `_submit()` just shows `"Coming soon...."`.
> This guide replaces that placeholder with one API call that opens a **real,
> 2-way support chat** with the BlueEra ride/order team, then drops the customer
> into the normal chat screen. Self-contained — no backend follow-up needed.

---

## 0. What you're building

The customer taps **Customer Care** on an ongoing/completed ride, picks a reason
(*Rash driving / Rude behaviour / Asked for extra fare / …*), optionally types a
note, and taps **Send to chat**. That:

1. `POST /support/order-support` → opens (or reuses) a **per-order** support thread
   between the customer and the **ride/order team account**, posts the reason as
   the first message.
2. Navigates the customer into the **normal chat screen** on the returned
   `conversation_id` — where they chat normally (text, media, live socket) and the
   team replies.

Key facts:

| Thing | Value |
|---|---|
| One thread **per order** | A second complaint about the SAME ride appends to the same thread; a different ride opens a new one. |
| **2-way** | Customer sends, team replies from the admin panel, customer sees replies live (same socket as every chat). |
| Chat top label | **"Order Customer Support"** — comes back as `display_name`; show it INSTEAD of the team account's real name. |
| First message | The selected reason (+ note on a second line), sent **from the customer**. |
| After opening | Use the **normal chat APIs** on `conversation_id` — nothing special. |

> The other one-sided team feed ("Order Track") is **internal only** — the customer
> never sees it. This guide is only the customer-facing 2-way care chat.

---

## 1. The API

> ### ⚠️ Base URL — this is the #1 mistake
> This endpoint lives in the **CHAT service**, NOT the rider service. The full URL is:
> ```
> https://be.beapp.in/api/chat-service/support/order-support
> ```
> If you POST to `…/api/rider-service/support/order-support` you get an HTML
> **`Cannot POST /support/order-support`** (404) — the ride service has no such route.
> Do **not** reuse the `dioClient` that your ride/fare calls use (its base is
> `…/api/rider-service`). Use your **chat-service** client / base, or a full URL.

### Request
```
POST https://be.beapp.in/api/chat-service/support/order-support
Authorization: Bearer <customer JWT>          // same auth as every app call
Content-Type: application/json

{
  "orderId":     "ORD-10231",                  // REQUIRED — the ride/order id
  "reason":      "Rude behaviour",             // REQUIRED — the picked reason label
  "note":        "Driver was shouting",        // optional — the free-text note
  "vehicleType": "twoWheelerRider",            // optional — helps the team filter
  "ride": {                                    // optional but RECOMMENDED — the team
    "from":        "Sector 12, Hisar",         //   sees this as a card so they can
    "to":          "MG Road, Hisar",           //   act/contact without lookups.
    "fare":        120,
    "userName":    "Rama Shyama",              //   pass what you already have on the
    "userNumber":  "9876543201",               //   ride booking object — all optional.
    "riderName":   "Amit Kumar",
    "riderNumber": "9711122233",
    "vehicle":     "Splendor · HR20AB1234"
  }
}
```

> **Send the whole `ride` object.** You already have every field on the ride-booking
> object powering this screen. The team opens these chats in the admin panel and sees
> a **Customer & Ride card** built from it — the more you pass, the less they have to
> look up before calling the customer/rider. `orderId` + `reason` are the only
> required fields; everything in `ride` is optional context.

### Response `201`
```json
{
  "success": true,
  "conversation_id": "6c1a9f...",
  "message_id": "6c1aa0...",
  "display_name": "Order Customer Support"
}
```
Errors: `400` (missing `orderId`/`reason`), `401` (no token), `500`
(`RIDE_TRACK_TEAM_USER_ID not configured` → backend env not set yet).

---

## 2. Flutter — repo method

Put this in your **chat repo** (or anywhere that uses the **chat-service** HTTP
client). ⚠️ It must NOT go through the ride/fare `dioClient` — see the base-URL
warning above. Use whatever client your existing **chat** calls use (the ones that
hit `…/api/chat-service/...`), or hard-code the full URL.

```dart
/// Opens (or continues) the per-order customer-care support chat and returns
/// the conversation id + the label to show at the chat top.
Future<({String conversationId, String displayName})> openOrderSupport({
  required String orderId,
  required String reason,
  String? note,
  String? vehicleType,
  Map<String, dynamic>? ride,
}) async {
  // chatDioClient base = https://be.beapp.in/api/chat-service
  // (NOT the rider/fare client — that base is …/api/rider-service and 404s here)
  final res = await chatDioClient.post(
    '/support/order-support',
    data: {
      'orderId': orderId,
      'reason': reason,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (ride != null) 'ride': ride,
    },
  );
  final d = res.data as Map<String, dynamic>;
  if (d['success'] != true) {
    throw Exception(d['message'] ?? 'Failed to open support chat');
  }
  return (
    conversationId: d['conversation_id'] as String,
    displayName: (d['display_name'] as String?) ?? 'Order Customer Support',
  );
}
```

---

## 3. Wire `ride_customer_care_sheet.dart`

Replace the placeholder `_submit()`
(`lib/features/ride_booking/widget/ride_customer_care_sheet.dart:70`).

**a)** The sheet needs the **`orderId`** — the same `ORD-…` id the rest of the ride
flow uses (e.g. `ORD-1786102072092`), NOT a Mongo `_id`. The sheet already receives
`rideId`; pass the real order id in when you show the sheet. If it's blank/wrong the
API returns `400 orderId is required` (or opens a thread against the wrong key), so
make sure `widget.rideId` holds the `ORD-…` value before shipping.

**b)** Replace the body of `_submit()`:

```dart
Future<void> _submit() async {
  final reason = _kComplaintReasons[_selected!].label;

  // Optional: close the sheet only after the call succeeds so failures can be
  // retried. Simplest is to close first, then navigate on success.
  Get.back();

  try {
    commonSnackBar(message: 'Opening support chat…');
    final r = await chatRepo.openOrderSupport(   // chat-service client (see §2)
      orderId: widget.rideId ?? '',          // the ORD-… order id
      reason: reason,
      note: _note.text,
      vehicleType: booking.vehicleType,      // if you have it handy
      // Pass everything you already have on the ride-booking object — the team
      // sees it as a card and contacts the customer/rider from it.
      ride: {
        'from': booking.pickupAddress,
        'to': booking.dropAddress,
        'fare': booking.fare,
        'userName': booking.customerName,
        'userNumber': booking.customerNumber,
        'riderName': widget.riderName,
        'riderNumber': booking.riderNumber,
        'vehicle': booking.vehicleName,
      },
    );

    // Navigate into the normal chat screen on the returned conversation.
    Get.to(() => ChatScreen(
      conversationId: r.conversationId,
      // IMPORTANT: show the backend label at the top, NOT the team's real name.
      title: r.displayName,                   // "Order Customer Support"
      conversationType: 'personal',
    ));
  } catch (e) {
    commonSnackBar(message: 'Could not open support chat. Please try again.');
  }
}
```

> Adapt `ChatScreen(...)` / `Get.to(...)` to however your app opens a 1:1 chat
> today (the ride cards already open the captain's inquiry chat via
> `openRiderInquiryChat` — reuse that exact navigation, just with this
> `conversationId` and the `title` override).

---

## 4. Show "Order Customer Support" at the chat top (name replace)

These support threads use a **team account** whose real name is *"BlueEra Ride
Order Track"*. You must show the friendly label instead. Two places:

**a) Chat header (when you open from the sheet):** pass `title: r.displayName`
into the chat screen (done in step 3). Done.

**b) Chat list (when the customer re-opens later):** every chat item now carries a
`support_meta` object. This is true for BOTH list sources — the REST list
`GET /chat/latest-chat` (each item in `chatList[]`) and the socket `"ChatList"`
payload. In your chat-list item builder, override the name:

```dart
// chatItem is one entry from chatList[] (latest-chat) or the socket "ChatList".
final displayName = chatItem['support_meta']?['display_name'];
final title = (displayName is String && displayName.isNotEmpty)
    ? displayName                 // "Order Customer Support" / "Order Track"
    : chatItem['user_name'];      // normal chats keep the other user's name
```

> Field note: on `latest-chat` the other user's name is under `sender` (e.g.
> `chatItem['sender']?['user_name']`), on the socket list it's `chatItem['user_name']`.
> Use whichever your list already reads — only the `support_meta?.display_name`
> override is new.

And in the chat screen header, do the same: prefer
`conversation.support_meta?.display_name` when present, else the other user's name.
`support_meta` is `null` for every normal chat, so nothing else changes.

---

## 5. After opening — it's just a normal chat

Once you're on `conversation_id`, **use your existing chat plumbing unchanged**:
send text/media with your normal send-message API, connect the normal socket, and
receive the team's replies via `newMessageReceived` like any other chat. No
special polling, no special socket — the team's reply is a normal message in this
conversation.

---

## 6. UX notes

- **Reason is required** — the sheet already disables "Send to chat" until a reason
  is picked; keep that (the backend also 400s without `reason`).
- **Note is optional** — sent as a second line of the first message.
- **Re-entry** — if the customer opens Customer Care again for the SAME ride and
  sends another reason, it lands in the SAME thread (backend reuses per order).
- **"Coming soon" gate** — remove it only once `RIDE_TRACK_TEAM_USER_ID` is live on
  the chat service (ask backend). Until then the API returns `500` with
  `RIDE_TRACK_TEAM_USER_ID not configured`; you can keep the graceful catch above.

---

## 7. One-line summary

`POST /chat-service/support/order-support { orderId, reason, note? }` → returns
`conversation_id` + `display_name:"Order Customer Support"`. Navigate to the normal
chat screen with that id and show `display_name` at the top. Per-order, 2-way, team
replies from the admin panel. Everything after opening is a normal chat.
