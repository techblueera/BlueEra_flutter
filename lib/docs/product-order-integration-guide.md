# Product Order Integration Guide (Flutter Frontend)

> **Audience:** Flutter team
> **Scope:** New self-pickup product order flow in `be_inventory_service` + new chat message type `product_selfpickup` in `be_chat_service`.
> **Mirrors:** This is the third entry in the same family as grocery (`selfpickup`) and food (`food_selfpickup`). Reuse the existing pickup-order card; the only delta is the message type, the deep-link key, and the food/grocery/product copy / icon.

---

## 1. What's new

| Area | Change |
|---|---|
| `be_inventory_service` | New `Order` resource + REST API at `/orders/...`. The order lives in inventory service because that's where the seller listing (`InventorySchema`) lives. |
| `be_inventory_service` | Two delivery types: `self-pickup` (fully wired end-to-end) and `rider` (stub — order is persisted but no chat/dispatch yet, parity with grocery and food). |
| `be_inventory_service` | On self-pickup creation, publishes Kafka event `CREATE_PRODUCT_PICKUP_ORDER` to chat service. |
| `be_inventory_service` | On "mark ready" by the seller, publishes `PRODUCT_ORDER_READY`. |
| `be_inventory_service` | Polymorphic-owner resolution: `Inventory.owner` can be `User` or `Business`; the controller resolves `Business` → `business.user_id` via gRPC up-front so chat participants are always real users. `Channel` and `Admin` owners are rejected (`400`). |
| `be_chat_service` | New `message_type` and `sub_type` enum value: **`product_selfpickup`** |
| `be_chat_service` | New `metadata.productPickupOrderId` field on messages |
| `be_chat_service` | New socket events: `newProductPickupOrderReceived`, `productPickupOrderReady` |
| `be_chat_service` | The existing `"order"` conversation type is reused — no new chat-list filter value, `?type=order` already returns these chats alongside grocery and food. |

---

## 2. REST endpoints — `be_inventory_service`

> Base path: `{INVENTORY_SERVICE_URL}/orders` (note: no `/api` prefix in this service — the routes index mounts directly under `/`).
> All endpoints require `Authorization: Bearer <jwt>`. The auth middleware sets `req.rootUser` from the token.

### 2.1 Create order

`POST /orders`

**Request body**

```json
{
  "items": [
    {
      "inventory":  "<Inventory ObjectId>",
      "variantId":  "<variant._id from Inventory.variants[]>",
      "quantity":   1,
      "mrp":        500,
      "sellingPrice": 399
    }
  ],
  "deliveryType": "self-pickup",
  "discount": 0
}
```

| Field | Type | Notes |
|---|---|---|
| `items[]` | array | Required, ≥1 item |
| `items[].inventory` | string | `Inventory._id` (the per-seller listing) |
| `items[].variantId` | string | `_id` of a specific variant inside `Inventory.variants[]` |
| `items[].productId` | string | Optional — the upstream product id; the server stamps this from `Inventory.product_id` if you don't send it |
| `items[].quantity` | int | ≥1 |
| `items[].mrp` | number | Backend re-derives `totalMRP` from this |
| `items[].sellingPrice` | number | Backend re-derives `grandTotal` from this |
| `deliveryType` | string | `"self-pickup"` or `"rider"` |
| `discount` | number | Optional, subtracted from `grandTotal` |

**Response 201**

```json
{
  "_id": "65f...",
  "userId": "<customerId>",
  "businessId": "<resolved seller user_id>",
  "businessIds": ["<resolved seller user_id>"],
  "pickupStatus": { "<seller user_id>": "pending" },
  "items": [
    {
      "inventory": "...",
      "productId": "...",
      "variantId": "...",
      "quantity": 1,
      "mrp": 500,
      "sellingPrice": 399,
      "businessLocation": { "lat": 17.4, "lon": 78.4 }
    }
  ],
  "totalItems": 1,
  "totalMRP": 500,
  "discount": 0,
  "grandTotal": 399,
  "deliveryType": "self-pickup",
  "orderStatus": "placed",
  "contact_no": "9999999999",
  "createdAt": "...",
  "updatedAt": "..."
}
```

**Important:** `businessId` and `businessIds[]` in the response are **resolved owner user_ids**, NOT the raw `Inventory.owner.id`. This matters when the seller logs in and queries `/orders/business/me` — they must use their own `user_id`, not the `Business._id`.

**Validation rules**
- Variant must exist on the Inventory and be `varientIsActive: true` and `stock: true`.
- Inventory must be `isActive: true`.
- `Inventory.owner.type` must be `User` or `Business`. If it's `Channel` or `Admin`, you'll get `400 'Inventory owner type "Channel" cannot be ordered'`.
- For `Business` owners, the gRPC `getBusinessById({business_id: owner.id})` call must succeed and return a `business.user_id`. If not, you'll get `400 'Could not resolve business owner for inventory ...'`.

**Side effects**
- `self-pickup`: a `CREATE_PRODUCT_PICKUP_ORDER` Kafka event is published asynchronously. Within ~1s, the chat service creates an `"order"` conversation between customer and seller (or reuses an existing one) and posts a `product_selfpickup` message. The seller receives a real-time socket event (see §4) and a push.
- `rider`: order is persisted with `deliveryType: "rider"`, but no Kafka event and no chat conversation are created (parity with grocery / food).

---

### 2.2 Mark order ready (seller)

`PUT /orders/:orderId/ready`

Called by the seller (logged in with their `user_id`) once the order is prepared. Multi-seller orders track readiness per business; the order transitions to `in-progress` only when **all** sellers have marked their items ready.

**Auth:** caller's `req.rootUser` must be in `order.businessIds`.

**Response 200**: returns the updated `Order` document.

**Errors**
- `400` — order is `rider`, already ready, expired, or cancelled
- `403` — caller is not associated with this order
- `404` — order not found

**Side effects**
- Publishes `PRODUCT_ORDER_READY`. Chat service updates the existing `product_selfpickup` message metadata (`order_status: true`, `metadata.order.isReady: true`) and pushes a socket event + notification to the customer.

---

### 2.3 Update order

`PUT /orders/:id`

Body (any subset):
```json
{
  "orderStatus": "cancelled",
  "rider": "<riderId>"
}
```

- Customer can cancel only while status is `placed`.
- Either the order owner OR a seller `user_id` in `businessIds` can update.
- Returns the updated order.

### 2.4 List my orders (customer)

`GET /orders/me`

Query params: `page`, `limit`, `orderStatus` (comma-separated), `startDate`, `endDate`, `sortBy`, `sortOrder`.

Returns `{ success, data: { orders, pagination, filters } }` with `items.inventory` populated.

### 2.5 List business orders (seller)

`GET /orders/business/me`

Same shape as `/me`, filtered by `businessIds: <currentUserId>`.

### 2.6 Check ongoing order (customer)

`GET /orders/status/me`

Returns the customer's most recent order with status `placed` or `in-progress`, or `{ hasOngoingOrder: false }`.

### 2.7 Order lifecycle

```
placed ──(seller marks ready, all businesses)──▶ in-progress ──▶ completed
   │
   ├──(customer cancels within "placed")──▶ cancelled
   └──(no action within 1h, background job)──▶ expired
```

> Self-pickup orders that stay in `placed` for more than **1 hour** are auto-expired by the `orderExpiryJob` (every 15 minutes).

---

## 3. Chat service — new message type

### 3.1 Schema

```jsonc
{
  "_id": "...",
  "conversation_id": "...",
  "senderId": "<customerId>",
  "message_type": "product_selfpickup",   // NEW
  "sub_type": "product_selfpickup",        // NEW
  "message": "New self-pickup product order",
  "metadata": {
    "productPickupOrderId": "<orderId>",   // NEW — deep-link key into the product order
    "order_status": false,                 // becomes true when seller marks ready
    "is_cancelled": false,
    "order": {
      "orderId": "...",
      "businessId": "<resolved seller user_id>",
      "items": [
        {
          "inventoryId": "...",
          "productId": "...",
          "variantId": "...",
          "quantity": 1,
          "mrp": 500,
          "sellingPrice": 399
        }
      ],
      "totalItems": 1,
      "grandTotal": 399,
      "deliveryType": "self-pickup",
      "isReady": false                  // becomes true when seller marks ready
    }
  },
  "created_at": "...",
  "updated_at": "..."
}
```

> **Note:** the Kafka payload deliberately omits product names / variant attributes / images to keep the inventory service decoupled from the product catalog. If the chat card needs human-readable labels, the Flutter client should fetch product details on demand by `productId` from `be_product_service`.

### 3.2 Conversation

- `conversation.type === "order"` (existing — reused)
- One conversation per (customer, seller) pair, shared across all order messages (and shared with grocery + food order messages between the same two users)
- `last_message_type` will be `"product_selfpickup"` for the most recent product order

### 3.3 Chat list filter

**No new filter value.** Product order chats come back from the same query the grocery and food flows already use:

```
GET {CHAT_SERVICE_URL}/chat/latest-chat?type=order
```

Or via the socket `ChatList` / `ArchiveList` events with `type: "order"`. The Flutter "Orders" tab should pick these up automatically — verify visually.

### 3.4 UI parity with grocery and food

Render the `product_selfpickup` card identically to the existing `selfpickup` (grocery) and `food_selfpickup` cards. Reuse the same widget; switch on `message_type` to:

| Element | grocery `selfpickup` | food `food_selfpickup` | new `product_selfpickup` |
|---|---|---|---|
| Header label | "Grocery Order" | "Food Order" | "Product Order" |
| Item icon/placeholder | grocery placeholder | food placeholder | product placeholder |
| "Mark ready" CTA target | grocery service `PUT .../ready` | food service `PUT .../ready` | **inventory service** `PUT /orders/:orderId/ready` |
| Deep-link key | `metadata.selfpickupOrderId` | `metadata.foodPickupOrderId` | `metadata.productPickupOrderId` |
| Item list source | `metadata.order.items[]` | `metadata.order.items[]` | `metadata.order.items[]` (no productName / image — fetch from product service if needed) |
| Ready badge | toggled by `metadata.order_status` | same | same |

---

## 4. Real-time socket events

| Event name | Payload | When |
|---|---|---|
| `newProductPickupOrderReceived` | `{ message: <full Message object incl. conversation> }` | Customer creates a self-pickup product order — emitted to the seller |
| `productPickupOrderReady` | `{ messageId, orderId, businessId }` | Seller marks the order ready — emitted to both customer and seller |

**Action when received:**
1. `newProductPickupOrderReceived` — insert/refresh the conversation in the chat list, surface a toast/badge on the Orders tab, optimistically render the message.
2. `productPickupOrderReady` — find the existing message by `messageId` (or by `metadata.productPickupOrderId`) and flip `metadata.order_status` to `true`. If the customer is on the order details screen, update the "Ready for pickup" badge.

> **Chat list filter check (already done in this release):** `be_chat_service/src/controllers/message.controller.js:47` was updated to include `"product_selfpickup"` in the `getMessages` `sub_type` whitelist. Without it, opening the conversation would silently filter the message out — same bug we hit on the food rollout. This is already shipped.

---

## 5. Push notifications

Two FCM reasons fire via the existing `sendNotification()` flow:

| Reason key | Recipient | Body | When |
|---|---|---|---|
| `product_pickup_order` | Seller | "You have a new self-pickup product order! N item(s) - Total: ₹X" | Order created |
| `product_pickup_order_ready` | Customer | "Your product order is ready for pickup!" | Seller marked ready |

Both carry the standard payload:
```json
{
  "message_id": "...",
  "conversation_id": "...",
  "message_type": "product_selfpickup",
  "conversation_type": "order"
}
```

Tap action: open the conversation `conversation_id`, then scroll to / highlight `message_id`.

---

## 6. End-to-end flow (sequence)

```
Customer (Flutter)         be_inventory_service        Kafka         be_chat_service             Seller (Flutter)
       │                          │                      │                  │                          │
       │ POST /orders             │                      │                  │                          │
       │  (self-pickup)           │                      │                  │                          │
       ├─────────────────────────▶│                      │                  │                          │
       │                          │ validate inventory   │                  │                          │
       │                          │ + variant.stock      │                  │                          │
       │                          │ resolve owner→user_id│                  │                          │
       │                          │ create Order         │                  │                          │
       │                          │ commit txn           │                  │                          │
       │◀──── 201 + order ────────│                      │                  │                          │
       │                          │ publishEvent         │                  │                          │
       │                          │ CREATE_PRODUCT_PICKUP_ORDER ────────────▶│                          │
       │                          │                      │                  │ create/find "order"      │
       │                          │                      │                  │ conversation             │
       │                          │                      │                  │ create product_selfpickup│
       │                          │                      │                  │ message                  │
       │                          │                      │                  │ ──── socket ────────────▶│
       │                          │                      │                  │   newProductPickup       │
       │                          │                      │                  │   OrderReceived          │
       │                          │                      │                  │ ──── FCM ───────────────▶│
       │                          │                      │                  │                          │
       │                          │       (later)        │                  │                          │
       │                          │                      │                  │ PUT /orders/:id/ready    │
       │                          │◀────────────────────────────────────────────────────────────────────│
       │                          │ mark ready           │                  │                          │
       │                          │ publishEvent         │                  │                          │
       │                          │ PRODUCT_ORDER_READY ───────────────────▶│                          │
       │                          │                      │                  │ update msg metadata      │
       │◀──── socket ──────────────────────────────────────────────────────│ ──── socket ────────────▶│
       │  productPickupOrderReady                                              productPickupOrderReady│
       │◀──── FCM ─────────────────────────────────────────────────────────│                          │
```

---

## 7. Implementation checklist for Flutter

- [ ] Reuse the grocery / food self-pickup order card widget; gate on `message_type == 'product_selfpickup'` to show the "Product Order" copy and route the deep-link to the product order detail screen via `metadata.productPickupOrderId`.
- [ ] Wire `POST /orders` from the cart screen for inventory items with `deliveryType: 'self-pickup'`. Send `inventory` + `variantId` + `quantity` + `mrp` + `sellingPrice`.
- [ ] Add socket listeners for `newProductPickupOrderReceived` and `productPickupOrderReady` next to the existing food / grocery socket listeners — same handlers, product repository.
- [ ] Seller app: surface "Mark Ready" CTA on the order detail screen wired to `PUT /orders/:orderId/ready` against the inventory service.
- [ ] Wire `GET /orders/me` for the customer "My Orders" tab and `GET /orders/business/me` for the seller order list.
- [ ] Wire `GET /orders/status/me` for the "ongoing order" sticky banner.
- [ ] FCM handler: route reasons `product_pickup_order` and `product_pickup_order_ready` to open the conversation, same as food / grocery.
- [ ] If you need product names / images on the chat card, fetch them on demand from `be_product_service` by `productId` — they're not included in the Kafka payload to keep services decoupled.
- [ ] Verify the Orders tab shows grocery + food + product chats together.

---

## 8. Quick testing recipe

1. Start `be_chat_service`, `be_inventory_service`, MongoDB, Kafka.
2. Pick an `Inventory` doc whose `owner.type === 'Business'` AND whose `Business._id` resolves via `getBusinessById` to a real `user_id` (or an `owner.type === 'User'` row). The variant you target must have `stock: true`.
3. Hit `POST /orders` with `deliveryType: 'self-pickup'` as a customer JWT (use that variant's `_id`).
4. Tail `be_chat_service` logs — expect `[ProductPickup] Creating order message for order …`.
5. In Mongo: `db.messages.findOne({ message_type: "product_selfpickup" })` should return the new message; `db.conversations.findOne({ _id: <id> })` should be `type: "order"`, `last_message_type: "product_selfpickup"`.
6. Verify the chat appears in `GET /chat/latest-chat?type=order` and via the `ChatList` socket event.
7. Hit `PUT /orders/:orderId/ready` as the seller's `user_id` JWT — the same message should now have `metadata.order_status === true`.

---

## 9. Reference

- **Order controller** — `be_inventory_service/src/controllers/order.controller.js`
- **Order routes (Swagger)** — `be_inventory_service/src/routes/order.route.js`
- **Order model** — `be_inventory_service/src/model/Order.js`
- **Inventory model (polymorphic owner)** — `be_inventory_service/src/model/InventorySchema.js`
- **Chat handler** — `be_chat_service/src/utils/productPickupHandler.js`
- **Kafka consumer dispatch** — `be_chat_service/src/utils/consumer.js` (cases `CREATE_PRODUCT_PICKUP_ORDER`, `PRODUCT_ORDER_READY`)
- **Message schema** — `be_chat_service/src/models/schema/message.schema.js` (`product_selfpickup` enum value)
- **Sibling references** — `be_chat_service/docs/food-order-integration-guide.md`, `be_chat_service/src/utils/foodPickupHandler.js`, `be_chat_service/src/utils/groceryPickupHandler.js`
