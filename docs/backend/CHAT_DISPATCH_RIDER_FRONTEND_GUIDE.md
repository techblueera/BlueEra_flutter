# Chat Self-Pickup → Rider Dispatch + Two-OTP Handoff — Frontend Integration Guide

## What this feature does

Adds a **"Find Rider"** action on a self-pickup order card in the customer's chat.
The customer taps it, sees riders **near the shop**, picks one, and a delivery ride is
dispatched: **shop = pickup, customer = drop**. Two OTPs gate the handoff and appear as
dedicated chat cards:

- **pickupOTP** — appears in the **shopkeeper's** chat. Shop confirms it when handing goods to the rider.
- **deliveryOTP** — appears in the **customer's** chat. Customer gives it to the rider at delivery.

Each OTP card is private: the customer never sees the pickup card, the shop never sees the
delivery card (enforced server-side via `visible_to`).

Applies to self-pickup card types: `selfpickup`, `food_selfpickup`, `product_selfpickup`,
`homemade_food_selfpickup`.

---

## End-to-end flow

```
1. Customer chat shows a self-pickup order card (existing).
2. Customer taps [Find Rider]  ── customer side only; hide for the business viewer.
3. App resolves SHOP coords (business profile) + CUSTOMER coords (current/delivery location).
4. GET /fare/riders   pickup = shop, drop = customer, orderFor = goods type
       → riders grouped by vehicleType (only goods-capable riders; preference-filtered server-side).
5. Customer selects rider(s) from the existing rider-selection sheet.
6. POST /fare/chat-dispatch/orders  → creates the delivery ride, notifies riders.
7. Rider accepts (rider app, existing accept action).
       → pickupOTP card appears in shopkeeper chat; deliveryOTP card appears in customer chat.
8. Rider reaches shop → shop confirms pickup with pickupOTP  → pickup card flips to "consumed".
9. Rider reaches customer → customer gives deliveryOTP → rider enters it → delivery card "consumed", order completed.
```

---

## Step 4 — Find riders (REUSES existing endpoint, no new call shape)

`GET /fare/riders` (existing). Send the **shop** as pickup and the **customer** as drop.

Query params:
```
orderFor        = grocery | food | product | medical   (goods category of the order)
pickupLatitude  = SHOP latitude
pickupLongitude = SHOP longitude
dropLatitude    = CUSTOMER latitude
dropLongitude   = CUSTOMER longitude
range_in_km     = 5 (optional)
distance_in_km  = optional road distance shop→customer
```

Response (unchanged shape — grouped by vehicleType):
```json
{
  "twoWheelerRider": { "users": [ { "riderId": "...", "name": "...", "distance": "1.2 km", ... } ], "fare": 45 }
}
```
> The rider-preference filter runs server-side: only riders who opted into goods
> delivery are returned. An empty `{}` is valid → show "no riders available".

---

## Step 6 — Create the dispatch order (NEW endpoint)

`POST /fare/chat-dispatch/orders`  (Bearer auth = the customer)

Request body:
```json
{
  "selfpickupOrderId": "GROCERY_ORDER_ID",          // from the chat card metadata (selfpickupOrderId)
  "selfpickupType": "selfpickup",                    // selfpickup | food_selfpickup | product_selfpickup | homemade_food_selfpickup
  "businessId": "SHOP_BUSINESS_OWNER_USER_ID",       // from the card metadata.order.businessId
  "shopLocation": { "latitude": 0, "longitude": 0, "address": "Shop name/addr" },
  "dropLocation":  { "latitude": 0, "longitude": 0, "address": "Customer address" },
  "orderFor": "grocery",                             // grocery | food | product | medical
  "selectedRiders": ["riderUserId1"],                // from the rider sheet
  "modeOfPayment": "prepaid",                         // prepaid | postpaid (optional, default prepaid)
  "fare": 45                                          // optional, the quoted fare
}
```

Success `201` → returns the created `RideOrder` (includes `pickupOTP`, `deliveryOTP`,
`orderSource: "chat-dispatch"`). Other codes: `400` invalid fields, `429` created too
recently (3-min guard), `500` server error.

> Field mapping from the chat card: `selfpickupOrderId` = `metadata.selfpickupOrderId`,
> `businessId` = `metadata.order.businessId`, `selfpickupType` = the card's `message_type`.

---

## Step 7+ — Render the OTP cards (NEW chat message type)

New message type/sub_type: **`rider_otp`**. Add it to your message-model parsing and the
chat bubble switch. Cards arrive via Kafka→socket and on history fetch.

Message shape (relevant fields):
```json
{
  "message_type": "rider_otp",
  "sub_type": "rider_otp",
  "visible_to": "<recipientUserId>",
  "message": "Rider OTP for pickup",
  "metadata": {
    "rideOrderId": "...",
    "selfpickupOrderId": "...",
    "otp": {
      "otp": "4821",
      "kind": "pickup",          // "pickup" (shop) | "delivery" (customer)
      "role": "shop",            // "shop" | "customer"
      "status": "active",        // "active" | "consumed"
      "riderName": "Ramesh",
      "rideOrderId": "...",
      "selfpickupOrderId": "..."
    }
  }
}
```

Rendering:
- `kind == "pickup"` (shop side): label e.g. **"Show this OTP to the rider at pickup"**.
- `kind == "delivery"` (customer side): label e.g. **"Give this OTP to the rider on delivery"**.
- `status == "consumed"` → render greyed/checked ("Picked up" / "Delivered").

> You do NOT need to filter by `visible_to` yourself — the server only returns the pickup
> card to the shop and the delivery card to the customer. But you may still read
> `metadata.otp.role`/`kind` to choose the label.

### Socket events (real-time)
- `newRiderOtpReceived` → `{ message }` : a new OTP card (handle like other new-message events).
- `riderOtpUpdated` → `{ messageId, rideOrderId, kind, status }` : flip an existing card to `consumed`.

---

## Step 8/9 — OTP verification (REUSES existing rider endpoints)

No change to these calls; they already exist:

- **Shop confirms pickup** — `POST /orders/:rideOrderId/pickup` body `{ "pickupOTP": "4821" }`.
  Auth = the shop (receiver). On success status → `picked-up`, pickup card flips consumed.
- **Rider confirms delivery** — `POST /orders/:rideOrderId/deliver` body `{ "deliveryOTP": "7390" }`.
  Auth = the assigned rider. On success status → `completed`, delivery card flips consumed.

> `:rideOrderId` is the Mongo `_id` returned by the create call.

---

## UI gating rules
- Show **[Find Rider]** only to the **customer** (the card sender / non-business viewer).
  Hide it when the logged-in user is the business owner.
- Optionally hide/disable [Find Rider] once a chat-dispatch ride already exists for that
  `selfpickupOrderId` (avoid duplicates; backend also enforces a 3-min guard).
- Pickup card is shop-only; delivery card is customer-only — server guarantees this, so no
  client-side leak handling needed.

## Backward compatibility
- New `rider_otp` message type: old app builds that don't recognise it simply won't render
  the card (unknown type). New builds required to use the feature.
- The new endpoint is additive; existing order/ride flows unchanged.
- Existing single-OTP plain-text messages still fire for non-chat-dispatch (parcel) orders.

## Quick reference
| Step | Call | New? |
|------|------|------|
| Find riders near shop | `GET /fare/riders` (shop=pickup, customer=drop) | reused |
| Create dispatch | `POST /fare/chat-dispatch/orders` | **new** |
| Pickup OTP verify | `POST /orders/:id/pickup` (shop) | reused |
| Delivery OTP verify | `POST /orders/:id/deliver` (rider) | reused |
| OTP card type | `message_type: "rider_otp"` | **new** |
| Socket: new card | `newRiderOtpReceived` | **new** |
| Socket: card consumed | `riderOtpUpdated` | **new** |
