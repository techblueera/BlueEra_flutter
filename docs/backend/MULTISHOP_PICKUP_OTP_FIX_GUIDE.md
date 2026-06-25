# Fix: Shop "Confirm Pickup" OTP for multi-shop orders (404 → correct)

## The bug (observed)
The shop ("surat doodh") tapped **Confirm pickup** and the app called:
```
POST https://be.beapp.in/api/rider-service/riders/orders/6a3ce851dea6dd25609fa1b5/pickup
body: { "pickupOTP": "1334" }
→ 404 { "message": "Order not found." }
```
Two things are wrong:
1. **Wrong endpoint** — `POST /riders/orders/:id/pickup` is the **single-shop** pickup. The order is **multi-shop** (`isMultiStop: true`), which has a **different per-shop** endpoint.
2. **Wrong order id** — `6a3ce851…` does not exist. The real order is `orderId: ORD-1782376677880` (`_id: 6a3ce8e5a4d9cbfd4484c952`).

> The OTP `1334` was correct (it is the stop's `pickupOTP`). Only the call was wrong.

---

## Correct call (multi-shop, shop confirms a stop)
```
PATCH /api/rider-service/fare/multi-shop/orders/{orderId}/stops/{businessId}/pickup
body: { "pickupOTP": "<that shop's OTP>" }
Auth: Bearer = the SHOP (business account)
```
For this order:
```
PATCH .../fare/multi-shop/orders/ORD-1782376677880/stops/6a3bd5bc3cda417240c3edcd/pickup
body: { "pickupOTP": "1334" }
```

Already wired in the app — **use these, not the single-shop one**:
- `RiderServiceApi.multiShopStopPickup(orderId, businessId)` → builds the PATCH path.
- `MakeOrderRepo.multiShopStopPickupApi({ orderId, businessId, pickupOTP })` (`make_order_repo.dart:54`).

The single-shop ones to STOP using for multi-shop orders:
- `RiderServiceApi.updateThePickupOtpUrl(orderId)` (`POST .../pickup`)
- `MakeOrderRepo.uploadThePickupOtp(...)` (`make_order_repo.dart:15`) — currently called by `order_controllar.dart:195`.

---

## What to change

### 1. Branch on `isMultiStop` in the shop's confirm-pickup action
In the controller that handles the shop pressing "Confirm pickup" (`order_controllar.dart:195` `uploadThePickupOtp`):
```dart
Future<void> confirmShopPickup({
  required String orderId,      // the RideOrder orderId (ORD-...) or _id
  required String businessId,   // THIS shop's businessId (the stop's businessId)
  required String pickupOTP,    // the per-stop OTP the rider read out
  required bool isMultiStop,
}) async {
  final res = isMultiStop
    ? await MakeOrderRepo().multiShopStopPickupApi(
        orderId: orderId, businessId: businessId, pickupOTP: pickupOTP)
    : await MakeOrderRepo().uploadThePickupOtp({ 'pickupOTP': pickupOTP }, orderId);

  if (res.isSuccess) {
    // stop marked picked-up; that shop's OTP card flips to consumed
  } else {
    // res.statusCode handling below
  }
}
```

### 2. Pass the CORRECT ids
- **`orderId`** — use the order's real id from the order object: `order.orderId` (e.g. `ORD-1782376677880`) **or** its Mongo `_id`. Both work (backend accepts either). The current bug passed a non-existent id — make sure you read it from the actual order model, not a stop id / grocery id / stale value.
- **`businessId`** — the **stop's** `businessId`, which for a shop equals **the logged-in shop's own `business_id`** (here `6a3bd5bc3cda417240c3edcd`). Take it from the shop's profile / the order's `stops[]` entry, not the user `_id`.
- **`pickupOTP`** — the **per-stop** OTP (`stops[].pickupOTP`, here `1334`), NOT the order-level `pickupOTP`. The rider reads this out; the shop types it.

### 3. The rider app must show the per-stop OTP
On the rider side, for a multi-shop order show **`stops[].pickupOTP`** for the shop the rider is at (here `1334`), not the order-level `pickupOTP`. The rider reads that to the shopkeeper. (`rider_orders_details_model.dart` currently parses only the order-level `pickupOTP` — add per-stop OTP from `stops[]`.)

---

## Response handling
| Code | Meaning | Action |
|---|---|---|
| `200` | stop picked-up | mark done; that shop's OTP card → consumed (socket `riderOtpUpdated`) |
| `400` `pickupOTP is required` | body missing OTP | send `{ pickupOTP }` |
| `400` `Invalid pickup OTP for this shop` | wrong OTP — likely sent order-level OTP instead of the stop's | use `stops[].pickupOTP` |
| `403` `Only this shop can confirm its own pickup` | caller isn't this shop | call as the shop account; `businessId` must be the shop's own |
| `404` `Order not found` | wrong/old `orderId`, or single-shop endpoint used for a multi-shop order | use the multi-shop endpoint + the real `orderId` |
| `400` `This order is not a multi-stop order` | used multi-shop endpoint for a single-shop order | branch on `isMultiStop` |

---

## Backend note (already fixed, pending redeploy of `be_rider_service`)
The multi-shop pickup auth now accepts the shop by **either** its `business_id` or user `_id`, and the JWT's `business_id` is exposed on the server. So once `be_rider_service` is redeployed, the correct call above (shop account, stop `businessId`, stop OTP) will succeed with `200`.

---

## TL;DR
- Multi-shop order → **`PATCH /fare/multi-shop/orders/{orderId}/stops/{businessId}/pickup`** with `{ pickupOTP }`, called by the **shop**.
- Use the **real `orderId`**, the **stop's `businessId`**, and the **per-stop OTP** (`stops[].pickupOTP`).
- Single-shop order → keep `POST /riders/orders/{orderId}/pickup`.
- Branch on `order.isMultiStop`.
