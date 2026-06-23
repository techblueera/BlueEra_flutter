# New Notifications — Frontend Integration Guide (deeplinks + button actions)

Covers the two notifications added this cycle:

| Operation (emitted) | When | Who gets it | Channels |
|---|---|---|---|
| `ROUTE_ORDER_AVAILABLE` | A new order is created on a rider's active route | the route rider | push + in-app |
| `rider_otp` | Rider accepts a chat-dispatch order → OTP handoff cards | shop (pickup OTP) / customer (delivery OTP) | push + in-app |

> Backend note (already handled): the notification service lowercases the operation
> for **push** template lookup but uses the exact emitted case for **in-app**. Templates
> exist for both paths. Frontend keys off `data.type` / `type`, not the raw casing.

---

## How button actions are encoded

Both push `buttons[]` and in-app `action[]` use the same id convention:

```
<action>_<entity>_<id>
```
e.g. `view_order_ORD-123`, `claim_order_ORD-123`, `open_chat_6a3a1a99...`

Frontend parses the id: split off the trailing id, map the leading `action_entity` to a
route or an API call. This matches the existing order notifications (`view_order_*`,
`accept_order_*`), so reuse the same dispatcher.

---

## 1. `ROUTE_ORDER_AVAILABLE` — order on your route

### Push payload (FCM `data`)
```json
{
  "headings": "Order on your route",
  "contents": "A new order on your route is available to claim.",
  "data": { "orderId": "ORD-123", "type": "route_order_available" },
  "buttons": [
    { "id": "view_order_ORD-123",  "text": "View Order" },
    { "id": "claim_order_ORD-123", "text": "Claim Order" }
  ]
}
```

### In-app payload (from notification list API)
```json
{
  "type": "ROUTE_ORDER_AVAILABLE",
  "message": "Order on your route: A new order on your route is available to claim.",
  "metadata": { "orderId": "ORD-123", "title": "...", "message": "...", "metadata": { "orderFor": "grocery" } },
  "action": [
    { "id": "view_order_ORD-123",  "text": "View Order" },
    { "id": "claim_order_ORD-123", "text": "Claim Order" }
  ]
}
```

### Button → behaviour
| Button id prefix | Deeplink | API call |
|---|---|---|
| `view_order_<orderId>` | Open the order-detail / route-orders screen for `<orderId>` | (optional) `GET /riders/routes/orders` to refresh the list, or fetch the single order |
| `claim_order_<orderId>` | After success, open the active-ride screen | **`POST /riders/orders/<orderId>/claim`** (Bearer = rider) |

Claim responses to handle:
- `200` → claimed; navigate to the active order.
- `409` → "Just taken by another rider" → refresh list.
- `422` → no longer on route / preference mismatch → remove from list.
- `400` → rider has no active route.

> Tapping the notification body (not a button) should also deeplink to the order using
> `data.orderId`.

---

## 2. `rider_otp` — OTP handoff card alert

Sent when the rider accepts a chat-dispatch order. The **OTP itself is NOT in the
notification** (security) — it lives in the chat `rider_otp` message card. This push just
nudges the user to open the chat.

### Push payload
```json
{
  "headings": "Rider OTP",
  "contents": "Share the pickup OTP with the rider at handoff.",   // or delivery copy for the customer
  "data": { "conversationId": "6a3a1a99...", "messageId": "...", "type": "rider_otp" },
  "buttons": [ { "id": "open_chat_6a3a1a99...", "text": "Open Chat" } ]
}
```

### In-app payload
```json
{
  "type": "rider_otp",
  "message": "Share the pickup OTP with the rider at handoff.",
  "metadata": { "conversation_id": "6a3a1a99...", "message_id": "...", "message_type": "rider_otp" },
  "action": [ { "id": "open_chat_6a3a1a99...", "text": "Open Chat" } ]
}
```

### Button → behaviour
| Button id prefix | Deeplink | API call |
|---|---|---|
| `open_chat_<conversationId>` | Open the chat conversation `<conversationId>` and scroll to the `rider_otp` card | none (the OTP card is already in chat via socket `newRiderOtpReceived` / history) |

> The actual OTP card rendering is covered in
> `CHAT_DISPATCH_RIDER_FRONTEND_GUIDE.md` (message_type `rider_otp`, `metadata.otp`).

---

## Suggested client dispatcher (pseudocode)

```dart
void onNotificationButton(String id, Map data) {
  final parts = id.split('_');            // [action, entity, ...idParts]
  final action = '${parts[0]}_${parts[1]}'; // e.g. "view_order", "claim_order", "open_chat"
  final entityId = parts.sublist(2).join('_');

  switch (action) {
    case 'view_order':  navTo(OrderDetail(entityId)); break;
    case 'claim_order': claimOrder(entityId); break;          // POST /riders/orders/{id}/claim
    case 'open_chat':   navTo(ChatScreen(conversationId: entityId)); break;
  }
}
```

Tapping the body (no button): route by `data.type`:
- `route_order_available` → order detail via `data.orderId`
- `rider_otp` → chat via `data.conversationId`

---

## Checklist
- [ ] Register a notification-channel category `orders` (both new ops are categorized there).
- [ ] Handle `claim_order_*` → `POST /riders/orders/:id/claim` with the 200/409/422/400 cases.
- [ ] `view_order_*` and body-tap → order detail by `orderId`.
- [ ] `open_chat_*` and `rider_otp` body-tap → chat by `conversationId`.
- [ ] In-app list: render `action[]` the same way as push `buttons[]`.
