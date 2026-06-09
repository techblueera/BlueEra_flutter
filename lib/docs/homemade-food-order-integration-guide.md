# Home-Made Food Order Integration Guide (Flutter Frontend)

> **Audience:** Flutter team
> **Scope:** New self-pickup home-made food order flow in `be_earn_with_blueera_service` + new chat message type `homemade_food_selfpickup` in `be_chat_service`.
> **Mirrors:** This feature is the earn-service equivalent of the existing grocery / food / product self-pickup flows. Wherever you already render `selfpickup` / `food_selfpickup` order cards, render `homemade_food_selfpickup` the same way (same layout, same actions, home-made-food copy/assets).

---

## 0. Key difference vs. grocery/food — read this first

Home-made food has **no business and no inventory**. A `HomeMadeFood` document is *both* the product and the stock, and it carries the cook on its own `userId`. So everywhere grocery/food uses `businessId` + `inventory` + `productVariant`, the home-made flow uses **`sellerId`** (the cook's userId) and references the **`homeMadeFood`** document directly. There is no stock decrement.

| Grocery / Food concept | Home-made-food equivalent |
|---|---|
| `businessId` / `businessIds` | `sellerId` / `sellerIds` (cook's userId) |
| `items[].inventory` + `items[].productVariant` | `items[].homeMadeFood` |
| `metadata.selfpickupOrderId` / `foodPickupOrderId` | `metadata.homeMadeFoodPickupOrderId` |
| `message_type: "selfpickup"` / `"food_selfpickup"` | `message_type: "homemade_food_selfpickup"` |
| business location fetched via gRPC | `sellerLocation` taken straight off the `HomeMadeFood` doc and included in the chat payload |

---

## 1. What's new

| Area | Change |
|---|---|
| `be_earn_with_blueera_service` | New `HomeMadeFoodOrder` resource with full REST API (`/homeFoodOrders/...`) |
| `be_earn_with_blueera_service` | Two delivery types: `self-pickup` (fully wired end-to-end) and `rider` (order persisted, no chat/dispatch yet — parity with grocery) |
| `be_earn_with_blueera_service` | On self-pickup order creation, publishes Kafka event `CREATE_HOMEMADE_FOOD_PICKUP_ORDER` to chat service — **one event per seller** |
| `be_earn_with_blueera_service` | On "mark ready" by the cook, publishes Kafka event `HOMEMADE_FOOD_ORDER_READY` |
| `be_chat_service` | New `message_type` and `sub_type` enum value: **`homemade_food_selfpickup`** |
| `be_chat_service` | New `metadata.homeMadeFoodPickupOrderId` field on messages |
| `be_chat_service` | New socket events: `newHomeMadeFoodPickupOrderReceived`, `homeMadeFoodPickupOrderReady` |
| `be_chat_service` | Existing `"business"` conversation is reused — no new chat-list filter value |

---

## 2. REST endpoints — `be_earn_with_blueera_service`

> Base path: `{EARN_SERVICE_URL}/homeFoodOrders`
> All endpoints require `Authorization: Bearer <jwt>`.

### 2.1 Create order

`POST /homeFoodOrders`

**Request body**

```json
{
  "items": [
    {
      "homeMadeFood": "<HomeMadeFood ObjectId>",
      "quantity": 2
    }
  ],
  "deliveryType": "self-pickup",
  "discount": 0
}
```

| Field | Type | Notes |
|---|---|---|
| `items[]` | array | Required, ≥1 item |
| `items[].homeMadeFood` | string | `HomeMadeFood._id` — the dish being ordered (product **and** stock) |
| `items[].quantity` | int | ≥1 |
| `deliveryType` | string | `"self-pickup"` or `"rider"` |
| `discount` | number | Optional, subtracted from `grandTotal` |

> **Note:** the client sends only `homeMadeFood` + `quantity`. The backend reads `mrp`, `sellingPrice`, the seller (`userId`), and the pickup `location` straight off the `HomeMadeFood` document — **do not** trust client-supplied prices. Multiple dishes from different cooks in one cart produce a multi-seller order (`sellerIds` has >1 entry, and one Kafka/chat message is created per seller).

**Response 201**

```json
{
  "_id": "65f...",
  "userId": "<customerId>",
  "sellerId": "<primary sellerId>",
  "sellerIds": ["<sellerId>"],
  "pickupStatus": { "<sellerId>": "pending" },
  "items": [
    {
      "homeMadeFood": "...",
      "quantity": 2,
      "mrp": 250,
      "sellingPrice": 199,
      "centerName": "Anita's Kitchen",                          // self-pickup only
      "sellerLocation": { "type": "Point", "coordinates": [78.4, 17.4] }  // [long, lat], self-pickup only
    }
  ],
  "totalItems": 2,
  "totalMRP": 500,
  "discount": 0,
  "grandTotal": 398,
  "deliveryType": "self-pickup",
  "orderStatus": "placed",
  "contact_no": "9999999999",   // populated from user-service via gRPC (best-effort)
  "createdAt": "...",
  "updatedAt": "..."
}
```

**Side effects**
- For `self-pickup`: a Kafka event `CREATE_HOMEMADE_FOOD_PICKUP_ORDER` is published asynchronously **per seller**. Within ~1s, the chat service creates/reuses a `"business"` conversation between customer and cook and posts a `homemade_food_selfpickup` message. The cook receives a real-time socket event + FCM push (see §4–5).
- For `rider`: the order is persisted with `deliveryType: "rider"` but **no chat event is published** (parity with grocery — rider dispatch not implemented yet).

**Errors**
- `400` — empty `items`, invalid `homeMadeFood` ID, invalid quantity, dish not available (`isActive: false`)
- `401` — missing/invalid token
- `404` — `HomeMadeFood` not found
- `500` — unexpected failure

---

### 2.2 Mark order ready (cook/seller)

`PUT /homeFoodOrders/:orderId/ready`

Called by the cook once the food is prepared. Multi-seller orders track readiness per seller in `pickupStatus`; the order transitions to `in-progress` only when **all** sellers have marked their items ready.

**Auth:** caller's userId must be in `order.sellerIds`.

**Response 200**: returns the updated `HomeMadeFoodOrder` document.

**Errors**
- `400` — order is `rider` (only self-pickup can be marked ready), already ready, expired, or cancelled
- `403` — caller is not a seller on this order
- `404` — order not found

**Side effects**
- Publishes Kafka event `HOMEMADE_FOOD_ORDER_READY`. Chat service updates the existing `homemade_food_selfpickup` message metadata (`order_status: true`, `metadata.order.isReady: true`) and pushes a socket event + notification to the customer.

---

### 2.3 Update order

`PUT /homeFoodOrders/:id`

Body (any subset):

```json
{
  "orderStatus": "cancelled",
  "rider": "<riderId>"
}
```

- Customer can cancel only while status is `placed`.
- Either the order owner OR a seller in `sellerIds` can update.
- Returns the updated order.

---

### 2.4 List my orders (customer)

`GET /homeFoodOrders/me`

Query params: `page`, `limit`, `orderStatus` (comma-separated), `startDate`, `endDate`, `sortBy`, `sortOrder`.

Returns paginated orders with `items.homeMadeFood` populated, plus pagination metadata.

### 2.5 List seller orders (cook)

`GET /homeFoodOrders/seller/me`

Same shape as `/me`, filtered by `sellerIds: <currentUserId>`.

### 2.6 Check ongoing order (customer)

`GET /homeFoodOrders/status/me`

Returns whether the customer has an order with status `placed` or `in-progress`, plus the most recent ongoing order if any.

### 2.7 Find alternative sellers

`GET /homeFoodOrders/:orderId/alternatives`

Query: `filter` = `suggested` | `cheapest` | `nearest`. Returns other active cooks offering the same `foodKey` dishes, grouped by seller and enriched with seller name + profile picture. Use this for the "find another cook" upsell (mirrors grocery's order-alternatives screen).

### 2.8 Order lifecycle

```
placed ──(all sellers mark ready)──▶ in-progress ──▶ completed
   │
   ├──(customer cancels within "placed")──▶ cancelled
   └──(no action within 1h, background job)──▶ expired
```

> Self-pickup orders that stay in `placed` for more than **1 hour** are auto-expired by `homeMadeFoodOrderExpiryJob` (runs every 15 minutes).

---

## 3. Chat service — new message type

### 3.1 Schema

```jsonc
{
  "_id": "...",
  "conversation_id": "...",
  "senderId": "<customerId>",
  "message_type": "homemade_food_selfpickup",   // NEW
  "sub_type": "homemade_food_selfpickup",         // NEW
  "message": "New self-pickup home-made food order",
  "metadata": {
    "homeMadeFoodPickupOrderId": "<orderId>",     // NEW — use this to deep-link into the order
    "order_status": false,                        // becomes true when the cook marks ready
    "is_cancelled": false,
    "order": {
      "orderId": "...",
      "sellerId": "...",
      "items": [
        {
          "homeMadeFoodId": "...",
          "foodName": "Anita's Veg Biryani",
          "foodKey": "veg_biryani",
          "images": ["https://..."],
          "quantity": 2,
          "mrp": 250,
          "sellingPrice": 199
        }
      ],
      "totalItems": 2,
      "grandTotal": 398,
      "deliveryType": "self-pickup",
      "sellerLocation": { "type": "Point", "coordinates": [78.4, 17.4], "centerName": "Anita's Kitchen" },
      "isReady": false                            // becomes true when the cook marks ready
    }
  },
  "created_at": "...",
  "updated_at": "..."
}
```

> The `order.items[]` shape here is **different from grocery/food** — each item is `{ homeMadeFoodId, foodName, foodKey, images[], quantity, mrp, sellingPrice }`. There is no `inventoryId` / `productVariantId`. `sellerLocation` is home-made-food-only and is a GeoJSON Point (`coordinates` is `[long, lat]`) — use it to show the pickup pin on a map.

### 3.2 Conversation

- `conversation.type === "business"` (existing — reused; the customer↔cook pair shares one conversation)
- One conversation per (customer, seller) pair, shared across all order messages
- `last_message_type` will be `"homemade_food_selfpickup"` for the most recent home-made order

### 3.3 Chat list filter

**No new filter value.** Home-made order chats come back through the same conversation queries you already use for business conversations. The Flutter chat list should already pick these up — verify visually.

### 3.4 UI parity

The `homemade_food_selfpickup` card should look and behave **identically** to the existing `selfpickup` (grocery) / `food_selfpickup` card. Reuse the same widget; switch only on the `message_type` value to:

| Element | grocery `selfpickup` | new `homemade_food_selfpickup` |
|---|---|---|
| Header label | "Grocery Order" | "Home-Made Food Order" |
| Item icon/placeholder | grocery placeholder | home-made-food placeholder |
| "Mark ready" button (seller side) | calls grocery service | calls **earn service** `PUT /homeFoodOrders/:orderId/ready` |
| Deep-link tap target | `metadata.selfpickupOrderId` → grocery order screen | `metadata.homeMadeFoodPickupOrderId` → **home-made order screen** |
| Item list source | `metadata.order.items[]` (inventory/variant fields) | `metadata.order.items[]` (`homeMadeFoodId`/`foodName`/`foodKey`/`images`) |
| Pickup map pin | from business location | `metadata.order.sellerLocation` (GeoJSON Point) |
| Ready badge | toggled by `metadata.order_status` | same |

---

## 4. Real-time socket events

Listen on the same socket the user is already connected to for chat. Events are **emitted to the recipient's socket(s)** — i.e. the cook for `newHomeMadeFoodPickupOrderReceived`, both parties for `homeMadeFoodPickupOrderReady`.

| Event name | Payload | When |
|---|---|---|
| `newHomeMadeFoodPickupOrderReceived` | `{ message: <full Message object incl. conversation> }` | Customer creates a self-pickup home-made order — emitted to the cook |
| `homeMadeFoodPickupOrderReady` | `{ messageId, orderId, sellerId }` | Cook marks the order ready — emitted to both customer and cook |

**Action when received:**
1. `newHomeMadeFoodPickupOrderReceived` — insert/refresh the conversation in the chat list, surface a toast/badge, optimistically render the message.
2. `homeMadeFoodPickupOrderReady` — find the existing message by `messageId` (or by `metadata.homeMadeFoodPickupOrderId`) and flip `metadata.order_status` to `true`. If the customer is on the order details screen, update the "Ready for pickup" badge.

> **Chat-list filter check (already fixed in this release):** the chat service had a `sub_type` whitelist in `getMessages` and a `SELFPICKUP_MESSAGE_TYPES` list that previously excluded `homemade_food_selfpickup`, so home-made messages would not render in a thread and `lastMessageSenderId` was wrong. Both now include `homemade_food_selfpickup`. No frontend change needed — just be aware if you test against an older deploy.

---

## 5. Push notifications

The chat service triggers two FCM notifications via the existing `sendNotification()` flow. The Flutter notification handler should treat these like the grocery equivalents.

| Reason key | Recipient | Body | When |
|---|---|---|---|
| `homemade_food_pickup_order` | Cook/seller | "You have a new self-pickup home-made food order! N item(s) - Total: X" | Order created |
| `homemade_food_pickup_order_ready` | Customer | "Your home-made food order is ready for pickup!" | Cook marked ready |

Both carry the standard payload:
```json
{
  "message_id": "...",
  "conversation_id": "...",
  "message_type": "homemade_food_selfpickup",
  "conversation_type": "business"
}
```

Tap action: open the conversation `conversation_id`, then scroll to / highlight `message_id`.

---

## 6. End-to-end flow (sequence)

```
Customer (Flutter)     be_earn_with_blueera        Kafka          be_chat_service          Cook (Flutter)
       │                       │                     │                  │                          │
       │ POST /homeFoodOrders  │                     │                  │                          │
       │  (self-pickup)        │                     │                  │                          │
       ├──────────────────────▶│                     │                  │                          │
       │                       │ validate dishes     │                  │                          │
       │                       │ read price/seller/  │                  │                          │
       │                       │ location from doc   │                  │                          │
       │                       │ create Order        │                  │                          │
       │◀─── 201 + order ──────│                     │                  │                          │
       │                       │ publishEvent (per seller)              │                          │
       │                       │ CREATE_HOMEMADE_FOOD_PICKUP_ORDER ─────▶│                          │
       │                       │                     │                  │ create/find "business"   │
       │                       │                     │                  │ conversation             │
       │                       │                     │                  │ create homemade_food_    │
       │                       │                     │                  │ selfpickup message       │
       │                       │                     │                  │ ─ socket: newHomeMade ──▶│
       │                       │                     │                  │   FoodPickupOrderReceived │
       │                       │                     │                  │ ─ FCM push ─────────────▶│
       │                       │                     │                  │                          │
       │                       │       (later)       │                  │                          │
       │                       │                     │                  │ PUT .../:orderId/ready    │
       │                       │◀───────────────────────────────────────────────────────────────────│
       │                       │ mark ready          │                  │                          │
       │                       │ publishEvent        │                  │                          │
       │                       │ HOMEMADE_FOOD_ORDER_READY ─────────────▶│                          │
       │                       │                     │                  │ update message metadata  │
       │◀── socket: homeMadeFoodPickupOrderReady ──────────────────────│ ─ socket: same event ───▶│
       │◀── FCM push ──────────────────────────────────────────────────│                          │
```

---

## 7. Implementation checklist for Flutter

- [ ] Add / reuse a `DeliveryType` enum: `selfPickup`, `rider`.
- [ ] Wire `POST /homeFoodOrders` from the cart screen with `deliveryType: 'self-pickup'`; send only `homeMadeFood` + `quantity` per item.
- [ ] Reuse the grocery/food self-pickup order card widget; gate on `message_type == 'homemade_food_selfpickup'` to show home-made copy/icons, map the `homeMadeFoodId`/`foodName`/`images` item fields, and route the deep-link to the home-made order detail screen via `metadata.homeMadeFoodPickupOrderId`.
- [ ] Render the pickup pin from `metadata.order.sellerLocation` (GeoJSON `[long, lat]`).
- [ ] Add socket listeners for `newHomeMadeFoodPickupOrderReceived` and `homeMadeFoodPickupOrderReady` next to the existing grocery/food listeners — same handlers, home-made repository.
- [ ] Cook app: surface "Mark Ready" CTA on the order detail screen wired to `PUT /homeFoodOrders/:orderId/ready`.
- [ ] Wire `GET /homeFoodOrders/me` for the customer "My Orders" tab and `GET /homeFoodOrders/seller/me` for the cook order list.
- [ ] Wire `GET /homeFoodOrders/status/me` for the "ongoing order" sticky banner (mirror grocery).
- [ ] (Optional) Wire `GET /homeFoodOrders/:orderId/alternatives` for the "find another cook" screen.
- [ ] FCM handler: route reasons `homemade_food_pickup_order` and `homemade_food_pickup_order_ready` to open the conversation, same as grocery.

---

## 8. Quick testing recipe

1. Start `be_chat_service`, `be_earn_with_blueera_service`, MongoDB, and Kafka locally (set `KAFKA_BROKERS` in the earn service secrets, else publish fails gracefully and no chat message is created).
2. Seed at least one `HomeMadeFood` doc with `isActive: true`, a `userId` (the cook), and a `location` GeoJSON Point.
3. Hit `POST /homeFoodOrders` with `deliveryType: 'self-pickup'` as a customer JWT.
4. Tail `be_chat_service` logs — you should see `[HomeMadeFoodPickup] Creating order message for order …`.
5. In Mongo: `db.messages.findOne({ message_type: "homemade_food_selfpickup" })` should return the new message with `metadata.homeMadeFoodPickupOrderId` set.
6. Hit `PUT /homeFoodOrders/:orderId/ready` as the cook JWT — the same message should now have `metadata.order_status === true`.
7. Open the conversation in the app and confirm the home-made order card renders (this is what the `getMessages` `sub_type` fix enables).

---

## 9. Reference

- **Order controller** — `be_earn_with_blueera_service/src/controllers/homeMadeFoodOrder.controller.js`
- **Order routes** — `be_earn_with_blueera_service/src/routes/homeMadeFoodOrder.routes.js` (mounted at `/homeFoodOrders`)
- **Order model** — `be_earn_with_blueera_service/src/models/homeMadeFoodOrder.model.js`
- **Expiry job** — `be_earn_with_blueera_service/src/jobs/homeMadeFoodOrderExpiryJob.js`
- **Kafka publisher** — `be_earn_with_blueera_service/src/kafka/publisher.js` (events `CREATE_HOMEMADE_FOOD_PICKUP_ORDER`, `HOMEMADE_FOOD_ORDER_READY`)
- **Chat handler** — `be_chat_service/src/utils/homeMadeFoodPickupHandler.js`
- **Kafka consumer dispatch** — `be_chat_service/src/utils/consumer.js` (cases `CREATE_HOMEMADE_FOOD_PICKUP_ORDER`, `HOMEMADE_FOOD_ORDER_READY`)
- **Message schema** — `be_chat_service/src/models/schema/message.schema.js` (`homemade_food_selfpickup` enum value)
- **Chat-list filter fix** — `be_chat_service/src/controllers/message.controller.js` (`SELFPICKUP_MESSAGE_TYPES`, `getMessages` `sub_type` whitelist)
- **Grocery reference (mirror this for visual parity)** — `be_chat_service/src/utils/groceryPickupHandler.js`
- **Food reference (same pattern)** — `be_chat_service/docs/food-order-integration-guide.md`
