# Rider Job-Type, Caller Screen, Notifications & OTP — Master Frontend Integration Guide

This is the consolidated guide for the rider work the backend just shipped:

1. **Job descriptor** — every order now tells the rider *what the job is*: a passenger **ride**, a **goods** pickup, or a **parcel** delivery.
2. **Caller screen** — the incoming fare-call screen shows the job type.
3. **Notifications** — order/route/call notifications carry the job descriptor.
4. **OTP integration** — `rider_otp` chat cards, single-shop (pickup + delivery) **and** multi-shop (one pickup OTP per shop).

Legend: ✅ already in the app · ▶ **TODO** (wire this).

---

## 0. Where things live (this repo)

| Concern | File |
|---|---|
| Push/FCM routing | `lib/core/services/app_notification.dart` (`showMsg` ~1385, handlers 296/323/1392) |
| Incoming fare-call screen | `lib/features/chat/view/call_screen/rider_call/incoming_rider_order_screen.dart` |
| Call controller | `lib/features/chat/auth/controller/call_controller.dart` (`fareCallRideDetails`) |
| Chat bubble switch | `lib/features/chat/view/widget/message_card.dart` (`switch (messageType)` ~280) |
| `rider_otp` card widget | `lib/features/chat/view/business_chat/widgets/rider_otp_msg_card.dart` (`RiderOtpMsgCard`) |
| Message + OTP models | `lib/features/chat/auth/model/GetListOfMessageData.dart` (`RiderOtpInfo` ~685, `MessageMetadata`) |
| Chat socket listeners | `lib/features/chat/auth/controller/chat_view_controller.dart` (`newRiderOtpReceived` 1048, `riderOtpUpdated` 1072) |
| Rider order model | `lib/features/chat/auth/model/rider_orders_details_model.dart` |
| Rider API endpoints | `lib/core/api/apiService/rider_service_api.dart` |

All endpoints are under the gateway slug `rider-service/...` (already the convention in `RiderServiceApi`).

---

## 1. Job descriptor (shared concept)

The backend derives a descriptor from `orderFor` and attaches it everywhere an order reaches a rider.

| `orderFor` | `jobType` | `jobLabel` | `riderTask` |
|---|---|---|---|
| `InCity` / `OutStation` / `HourlyRental` | `ride` | Passenger / Outstation / Hourly rental ride | Pick up and drop the passenger |
| `Parcel` | `parcel` | Parcel delivery | Collect the parcel and deliver it |
| `grocery` / `food` / `medical` / `product` | `goods` | Grocery / Food / Medicine / Goods pickup | Collect the order from the shop and deliver it |

Extra fields for the call screen: `callTitle` (e.g. "Incoming Pickup Request") and `callBody` (e.g. "Incoming grocery pickup request").

**Where it arrives:**
- `RIDE_ORDER_RECEIVED` notification `data`: `jobType`, `jobLabel`, `riderTask` (+ inside `metadata`).
- `ROUTE_ORDER_AVAILABLE` notification `data`: same three fields; `title`/`message` already job-aware.
- Route order list / claim responses: each order has a **`jobInfo`** object (all fields above).
- Fare-call payload `metadata.rideDetails`: `jobType`, `jobLabel`, `riderTask`, `callTitle`, `callBody`.

▶ **Add a model** (e.g. in `rider_orders_details_model.dart` or a small shared file):
```dart
class JobInfo {
  final String? jobType, orderFor, jobLabel, riderTask, callTitle, callBody;
  JobInfo({this.jobType, this.orderFor, this.jobLabel, this.riderTask, this.callTitle, this.callBody});
  factory JobInfo.fromJson(Map j) => JobInfo(
    jobType: j['jobType'], orderFor: j['orderFor'], jobLabel: j['jobLabel'],
    riderTask: j['riderTask'], callTitle: j['callTitle'], callBody: j['callBody']);
  bool get isRide => jobType == 'ride';
  bool get isGoods => jobType == 'goods';
  bool get isParcel => jobType == 'parcel';
}
```
Parse `RiderOrdersDetailsModel.jobInfo` from `json['jobInfo']`. Fallback: if absent (legacy), derive from `orderFor` client-side using the table above.

Display rule everywhere a rider sees an order: **header = `jobLabel`**, **sub-line = `riderTask`**.

---

## 2. Caller screen — incoming fare-call (job-aware)

✅ Already wired: FCM `fare_ride_incoming_call` → `_showRiderOrderScreen` (`app_notification.dart:1392`) → fills `CallController.fareCallRideDetails` → `IncomingRiderOrderScreen`. The screen already reads `metadata.rideDetails` (guide format) for pickup/drop/fare/`orderFor`.

▶ **TODO — show the job type on the call:** `incoming_rider_order_screen.dart` currently does `_rideType = ride?['orderFor']`. Use the friendly fields instead:
```dart
final ride = _callController.fareCallRideDetails.value;
final jobLabel = ride?['jobLabel'] ?? ride?['orderFor'] ?? 'Ride';
final callTitle = ride?['callTitle'] ?? 'Incoming Ride Request';
final riderTask = ride?['riderTask'] ?? '';
final jobType  = ride?['jobType'] ?? 'ride';   // ride | goods | parcel
```
- Title bar → `callTitle` ("Incoming Ride Request" / "Incoming Pickup Request" / "Incoming Parcel Pickup").
- Primary label → `jobLabel`; secondary → `riderTask`.
- Optional: icon/color by `jobType` (person / shopping-bag / parcel-box).

The full-screen Android call notification (`showIncomingCallLocalNotification`) heading is already driven by the server template (`callTitle`), so no change needed there beyond passing the data through (already does).

> The OTP is **never** in the call payload — riders read it later from the order/chat.

---

## 3. Notifications

✅ Operation routing already exists in `app_notification.dart` for every op below; button-id convention `<action>_<entity>_<id>` is already parsed.

| Operation | Channel | Handler (exists) | Buttons → action |
|---|---|---|---|
| `RIDE_ORDER_RECEIVED` | push+inapp | order-received flow | open order |
| `ROUTE_ORDER_AVAILABLE` | push+inapp | 296 / 1270 | `view_order_*` → detail · `claim_order_*` → claim API |
| `rider_otp` | push+inapp | 323 / 1299 | `open_chat_*` → open chat |
| `fare_ride_incoming_call` | VoIP push | 1392 | `view_fare_ride_*` / `decline_fare_ride_*` |

▶ **TODO — surface the job label:** these notifications now carry `data.jobType` / `data.jobLabel` / `data.riderTask`. When opening the order/route/claim UI from a tap, show `jobLabel` as the header so the rider immediately knows the job. Titles/bodies from the server are already job-specific.

Claim from `ROUTE_ORDER_AVAILABLE` (✅ endpoint exists — `claimRouteOrder(orderId)`):
- `200` → claimed (response includes `jobInfo`); open active order.
- `409` → already taken → toast + refresh list.
- `422` → off-route / preference mismatch → remove from list.
- `400` → no active route.

---

## 4. En-route route orders (the rider's route + claimable jobs)

✅ `claimRouteOrder(orderId)` already in `RiderServiceApi`.

▶ **TODO — add the route-management endpoints** (not in the app yet) to `RiderServiceApi`:
```dart
final String riderRoutes = 'rider-service/riders/routes';              // POST create/activate
final String riderActiveRoute = 'rider-service/riders/routes/active';  // GET
final String riderEndRoute = 'rider-service/riders/routes/active/end'; // PATCH
final String riderRouteOrders = 'rider-service/riders/routes/orders';  // GET list
final String riderRouteOrdersStream =
    'rider-service/riders/routes/orders/stream';                       // GET (SSE)
```
- **Create route** `POST /riders/routes` body: `{ pickup:{latitude,longitude,address}, drop:{...}, path?:[[lng,lat],...], radiusKm?:1, expiresInMinutes?:240 }`.
- **List** `GET /riders/routes/orders` → `{ routeId, count, orders:[ ...each with jobInfo ] }`.
- **Live** `GET /riders/routes/orders/stream` → SSE frames `{ routeId, orders:[...] }` (use the same EventSource/stream pattern as other SSE screens; keep-alive comments are sent).
- Each order has `jobInfo` → render `jobLabel` + `riderTask` per card, with a **Claim** button → `claimRouteOrder`.

---

## 5. OTP integration

### 5.1 The `rider_otp` chat card

✅ Exists: `RiderOtpMsgCard` widget, `RiderOtpInfo` model, socket listeners `newRiderOtpReceived` (append) + `riderOtpUpdated` (flip `status` → consumed). Server enforces `visible_to` (pickup card → shop only, delivery card → customer only) — **no client-side filtering needed**.

▶ **TODO — wire `rider_otp` into the bubble switch.** It is NOT in `message_card.dart` yet. Add a case next to `selfpickup` (~line 294):
```dart
case "rider_otp":
  messageWidget = RiderOtpMsgCard(message: widget.message, time: time);
```
(Card constructor is `RiderOtpMsgCard({required message, required time})`.)

Card data lives at `message.metadata.riderOtp` (`RiderOtpInfo`): `otp`, `kind` (`pickup`|`delivery`), `role` (`shop`|`customer`), `status` (`active`|`consumed`), `isPickup`, `isConsumed`. Render:
- pickup (shop): "Show this OTP to the rider at pickup"
- delivery (customer): "Give this OTP to the rider on delivery"
- consumed → strike-through / checked.

### 5.2 Single-shop (chat-dispatch) verification — ✅ endpoints exist
- Shop confirms pickup → `updateThePickupOtpUrl(orderId)` → `POST .../pickup` body `{ pickupOTP }`.
- Rider confirms delivery → `deliverOtpVerify(orderId)` → `POST .../deliver` body `{ deliveryOTP }`.
Both flip the matching card to consumed (socket `riderOtpUpdated`).

### 5.3 Multi-shop — **one pickup OTP per shop**

A 3-shop order issues **3 pickup OTPs** (one per shop) + 1 delivery OTP. Each shop gets its own private `rider_otp` pickup card in *that shop's* chat.

▶ **TODO — extend `RiderOtpInfo`** with the multi-shop fields the server now sends in `metadata.otp`:
```dart
final String? businessId;   // the shop this card belongs to
final String? shopName;
final int? sequence;        // 0 = first/furthest shop
final bool isMultiStop;
// in fromJson: businessId: json['businessId'], shopName: json['shopName'],
//   sequence: json['sequence'] is int ? json['sequence'] : null,
//   isMultiStop: json['isMultiStop'] == true,
```
Render multi-stop pickup cards labelled by `shopName` / `sequence` ("Shop 1 of 3"). Shopkeeper sees only their own card.

▶ **Rider per-stop flow** (endpoints ✅ already in `RiderServiceApi`):
1. Arrive at shop → `multiShopStopArrive(orderId, businessId)` → `PATCH .../stops/{businessId}/arrive` (no body).
2. Shopkeeper gives **that shop's** OTP → rider enters it →
   `multiShopStopPickup(orderId, businessId)` → `PATCH .../stops/{businessId}/pickup` **body `{ "pickupOTP": "4821" }`**.
   - `400` if missing/wrong OTP. On success that shop's card flips to consumed.
3. Repeat per shop in `sequence` order, then deliver to the customer with the single delivery OTP.

> Build the rider UI as a sequenced checklist (one row per `stops[]`), each row = Arrive → enter OTP → Picked-up.

---

## 6. API reference

| Action | `RiderServiceApi` member | Method | Status |
|---|---|---|---|
| Find riders (booking) | `getBookingRiders` | GET | ✅ |
| Create chat-dispatch order | `chatDispatchOrders` | POST | ✅ |
| Multi-shop riders | `multiShopRiders` | POST | ✅ |
| Multi-shop create | `multiShopOrders` | POST | ✅ |
| Multi-shop stop arrive | `multiShopStopArrive(id,biz)` | PATCH | ✅ |
| Multi-shop stop pickup (OTP) | `multiShopStopPickup(id,biz)` | PATCH `{pickupOTP}` | ✅ (send body) |
| Claim route order | `claimRouteOrder(id)` | POST | ✅ |
| Pickup OTP (single) | `updateThePickupOtpUrl(id)` | POST `{pickupOTP}` | ✅ |
| Deliver OTP | `deliverOtpVerify(id)` | POST `{deliveryOTP}` | ✅ |
| Accept/reject order | `updateRideOrParcelOrderStatus(id)` | PATCH `{action}` | ✅ |
| Create route | `riderRoutes` | POST | ▶ add |
| Active route | `riderActiveRoute` | GET | ▶ add |
| End route | `riderEndRoute` | PATCH | ▶ add |
| Route orders list | `riderRouteOrders` | GET | ▶ add |
| Route orders stream | `riderRouteOrdersStream` | GET (SSE) | ▶ add |

---

## 7. Socket events (already listened where noted)

| Event | Payload | Where |
|---|---|---|
| `newRiderOtpReceived` | `{ message }` | `chat_view_controller.dart:1048` ✅ |
| `riderOtpUpdated` | `{ messageId, rideOrderId, kind, status }` | `:1072` ✅ (for multi-shop also carries the consumed shop's card) |
| `ride:queue:calling` | fare-call progress to the customer | call flow ✅ |
| `ride:stop:update` | multi-stop per-shop status to rider/customer | ▶ optional live map update |

---

## 8. Pending-wiring checklist

- [ ] ▶ Add `case "rider_otp":` → `RiderOtpMsgCard` in `message_card.dart` (~line 294).
- [ ] ▶ Add `JobInfo` model; parse `jobInfo` on order/claim/route responses; fallback-derive from `orderFor`.
- [ ] ▶ Caller screen: read `jobLabel`/`callTitle`/`riderTask`/`jobType` from `rideDetails` (don't rely on raw `orderFor`).
- [ ] ▶ Show `jobLabel`/`riderTask` on every rider-facing order/route/claim card + on notification-open.
- [ ] ▶ Extend `RiderOtpInfo` with `businessId`/`shopName`/`sequence`/`isMultiStop`; label multi-shop pickup cards.
- [ ] ▶ Multi-shop pickup call must send body `{ pickupOTP }`; build the sequenced per-stop checklist UI.
- [ ] ▶ Add the 5 route-management endpoints + an en-route route-orders screen (list + SSE) with Claim.
- [ ] Verify: ride / goods / parcel each render distinct labels on the call screen, route cards, and notifications.

---

## 9. Backward compatibility
- All new fields are **additive** (`jobInfo`, `jobType`, `stops[].pickupOTP`, multi-shop OTP card fields). Old builds ignore them; existing flows are unchanged.
- The incoming-call op is unchanged (`fare_ride_incoming_call`) — VoIP path untouched; only the title/body/data became job-aware.
- Legacy multi-stop orders without per-stop OTPs fall back to the order-level `pickupOTP`.
