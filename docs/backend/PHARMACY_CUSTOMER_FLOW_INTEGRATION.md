# Pharmacy — customer flow backend guide

The whole customer-side pharmacy journey in one place: **browse stores → store
detail → cart → place order → order card in chat.**

**Client status: complete and merged.** Every ask below is app-side done and
waiting on the server. Nothing here needs an app release — add the keys / publish
the event and the UI lights up on your next deploy.

**Endpoints involved**

| # | Endpoint | Status |
|---|---|---|
| 1 | `GET user-service/business/filter?category=PHARMACY` | live — **needs 5 keys + a filter rule** |
| 2 | `GET medical-service/profile/home/{businessId}` | live — **2 fields to add, 1 to confirm** |
| 3 | `POST medical-service/orders` | live — no change |
| 4 | chat message `medical_selfpickup` | ❌ **missing — the main gap** |
| 5 | `PUT medical-service/orders/{orderId}/ready` | ❌ **missing** |

---

## The flow

```
Discover ▸ Pharmacy section (sub-category tiles)
      │
      ▼
PharmacyStoresScreen ─────────────────── ① business/filter?category=PHARMACY&subCategory=…
  banner + sub-category tabs + store cards
      │  tap a pharmacy
      ▼
MedicalPharmacyDetailScreen ──────────── ② medical-service/profile/home/{businessId}
  header · popular rail · category grid · live photos
      │  tap a category
      ▼
MedicalCategoryProductsScreen             (no API — served from ②'s tree)
  sub-category rail + tabs + product grid
      │  ADD  →  cart  →  Place Order
      ▼
POST medical-service/orders ───────────── ③  { items, deliveryType, discount }
      │
      ├─ deliveryType: "rider"        → MedicalConfirmScreen (no chat card)
      │
      └─ deliveryType: "self-pickup"  → app jumps to Chats ▸ Inquiry
                                             │
                                    ④ ⚠️ THE GAP: chat service must publish
                                       message_type "medical_selfpickup"
                                             ▼
                                       order card in the thread
                                             │  pharmacy taps "Mark as Ready"
                                             ▼
                                       ⑤ PUT medical-service/orders/{id}/ready
```

---

## ① Pharmacy stores list

`GET user-service/business/filter?category=PHARMACY&page=1&limit=10`
Optional: `&subCategory=<sub-category _id>`

### 1a. NEW RULE — hide empty pharmacies

**Exclude any pharmacy with 0 categories AND 0 products from this response.** A
store with no inventory is a dead end: the card advertises it, the user taps
through, and the detail screen has nothing to show. Filter it server-side —
the client cannot, because the list response carries no inventory counts (see
1b, which is exactly the data that would be needed).

### 1b. Add these 5 keys

The pharmacy card is the same design as the grocery store card. Grocery is fed
by `map-service/api/stores`, which returns all of these; `business/filter`
doesn't — so these slots currently render `0`.

| Key | Type | Card slot | Renders now |
|---|---|---|---|
| `total_category_count` | `int` | "N Category" stat box | `0` |
| `total_product_count` | `int` | "N Product" stat box | `0` |
| `views` | `string` ⚠️ | Footer: "N Total views on this store" | `0` |
| `chat_click_count` | `int` | Footer: "N orders" | `0` |
| `quirky_message` | `string`, optional | Footer tail, after the counts | omitted |

⚠️ `map-service/api/stores` returns `views` as a **string** (`"views": "120"`).
The pharmacy card accepts either, but please match the existing contract.

`quirky_message` is optional — absent/empty just omits that clause. The other
four should default to `0`, not `null`.

**Semantics** — mirror whatever `map-service/api/stores` already computes:
`total_category_count` / `total_product_count` = the pharmacy's live catalog;
`views` = lifetime profile views; `chat_click_count` = despite the name, the card
labels this **"orders"** (grocery does the same).

Note `total_product_count` / `total_category_count` also answer 1a — a store
where both are 0 is exactly the one to exclude.

### 1c. CONFIRM — how does `subCategory` match?

The Discover tiles and this screen's tabs send:

```
GET user-service/business/filter?category=PHARMACY&subCategory=6a088366c1424a5f4d8ec14f&page=1&limit=10
```

The value is the sub-category `_id` from the onboarding categories — the same id
that appears on the business record at `sub_category_details._id` (e.g.
`6a088366c1424a5f4d8ec14f` = "Medical Store").

**Please confirm it matches on that id.** No client passed this param before, so
it's unverified from the app side. If it matches on **name** instead, say so —
it's a one-line client change. This matters: the sub-category tiles are the only
way into the pharmacy list, so a no-op filter means every tile shows identical
results.

### 1d. Already correct

Consumed as-is: `_id`, `user_id`, `business_name`, `logo`, `address`,
`live_photos`, `avg_rating`, `business_location.lat/lon`, `business_description`,
`website_url`, `created_at`, `category_details.name`,
`sub_category_details.{_id,name}`.

Distance ("X Km Away") is computed client-side from `business_location` — no
`distance` key needed, and **this response is not location-scoped** (no lat/lng
is sent).

### 1e. Dead fields (FYI)

The client parses `openFrom` / `openTill`, but this endpoint has never returned
them, so they're always empty and nothing renders from them. Either add them or
treat them as retired.

---

## ② Pharmacy detail

`GET medical-service/profile/home/{businessId}`

This one payload drives the **entire** detail screen *and* the category browser
— header, popular rail, category grid, sub-category rail, tabs and product grid
all read from it. There is deliberately no second call: the response already
carries the full category tree with products at the leaves, so category browsing
is served from memory (no pagination anywhere in this flow).

Consumed: `businessProfile` (all of it), `inventorySummary.popularProducts`,
`inventorySummary.categoriesWithProducts` (recursive `children[]` + leaf
`products[]`), `gallery`.

### 2a. Add `product_form` + `is_prescription_required` to popular products

`inventorySummary.categoriesWithProducts[].products[]` carries both — good, so
the category grid shows the red **Rx** badge and the pack/form line correctly.

`inventorySummary.popularProducts[]` carries **neither**, so the popular rail
**cannot show the Rx badge** and the cart line for a popular item always reads
`isPrescriptionRequired: false`. For a pharmacy that's a real gap — the same
product shows Rx in one section and not the other.

Please add to each `popularProducts[]` entry (matching the names already used on
category products):

```jsonc
"product_form": "Tablet",
"is_prescription_required": true
```

### 2b. CONFIRM — where is variant inventory nested?

The client parses a variant's inventory from the **`product`** key:

```dart
inventory: json['product'] != null ? CategoryInventory.fromJson(json['product']) : null
```

If the payload doesn't nest inventory under `product`, then
`variant.inventory.inventoryId` is silently null — and **that id is what
`POST /orders` sends as `items[].inventory`**, so orders from the category
browser would fail or mis-resolve the store. Please confirm the actual key. If
it's `inventory`, this is a client fix and we'll take it.

Batch pricing (`variant.inventory.batches[0].mrp/sellingPrice`) is preferred over
catalog `variant.pricing[0]` — same rule as the grocery card. If batches are
absent the card silently falls back to list price.

---

## ③ Place order — no change

`POST medical-service/orders`

```jsonc
{
  "items": [
    { "inventory": "<inventoryId>", "productVariant": "<variantId>",
      "quantity": 2, "mrp": 120, "sellingPrice": 99 }
  ],
  "deliveryType": "self-pickup",   // or "rider"
  "discount": 42                    // rupee amount = totalMRP - totalSellingPrice
}
```

- **No `businessId` is sent** — the server resolves the pharmacy from the
  `inventory` ids, same contract as grocery.
- Response parses into `AddMedicalOrderResponseModel`; the client uses `_id` as
  `orderId` for the rider flow.
- The customer cart **only ever sends `self-pickup`**. Rider orders come from the
  separate `user_medical_controller` flow.

---

## ④ NEW — the order card in chat (the main gap)

Today `POST /orders` succeeds, the app jumps to Chats ▸ Inquiry, and **the thread
is empty** — nothing publishes a card. Grocery has done this for years via
`selfpickup`; pharmacy needs the same with its own id key.

Publish into the existing customer↔pharmacy **business** conversation (create it
if absent), sender = customer, **only for `deliveryType: "self-pickup"`** (the
rider branch routes to `MedicalConfirmScreen` and must NOT produce a card).

```jsonc
{
  "_id": "<messageId>",
  "conversation_id": "<conversationId>",
  "senderId": "<customerUserId>",
  "message_type": "medical_selfpickup",       // ← the discriminator
  "message": "New pharmacy order",
  "metadata": {
    "medicalPickupOrderId": "<orderId>",      // ← REQUIRED (see gotcha #1)
    "order_status": false,
    "is_cancelled": false,
    "order": {                                // ← REQUIRED
      "orderId": "<orderId>",
      "businessId": "<pharmacyBusinessId>",
      "totalItems": 2,
      "grandTotal": 198,
      "deliveryType": "self-pickup",
      "isReady": false,
      "items": [
        {
          "inventoryId": "<inventoryId>",
          "productVariantId": "<variantId>",
          "productId": "<productId>",
          "variantId": "<variantId>",
          "productName": "Dolo 650",
          "variantName": "Strip of 15 tablets",
          "quantityLabel": "15 tablets",
          "unit": "strip",
          "images": ["https://<presigned>"],
          "quantity": 2,
          "mrp": 120,
          "sellingPrice": 99
        }
      ]
    }
  }
}
```

### ⚠️ Gotcha #1 — both keys or the card renders empty

The client parses the order **only when `metadata.order` AND
`metadata.medicalPickupOrderId` are both present**:

```dart
medicalPickupOrder: (json['order'] != null && json['medicalPickupOrderId'] != null)
    ? SelfPickupOrderModel.fromJson(json['order'])
    : null,
```

Send `order` without `medicalPickupOrderId` and the card silently renders blank.
This has bitten every previous vertical.

### ⚠️ Gotcha #2 — enrich `items[]`

The raw order row has only ids + prices. The card shows a **thumbnail, product
name and variant name**, so the chat service must join product/variant/inventory
and inline them. Un-enriched items render as grey placeholders reading "Product
Item". `images[]` accepts `["url", …]` or `[{"url": "…"}, …]`; **presign** if the
bucket is private — the card has no auth on image loads.

### Field → UI mapping

| Field | Renders as |
|---|---|
| `order.totalItems` (falls back to `items.length`) | header "N items" |
| `order.grandTotal` | "Grand Total ₹X" |
| `items[].images[0]` | 48×48 thumbnail |
| `items[].productName` → `variantName` | item title / subtitle |
| `items[].sellingPrice` / `mrp` / `quantity` | price, struck-through MRP, qty |
| `order.isReady` ?? `metadata.order_status` | Ready badge + action gating |
| `metadata.is_cancelled` | cancelled state |
| `order.orderId` ?? `metadata.medicalPickupOrderId` | Mark-as-Ready, payment QR, PDF |
| `order.businessId` | rider handoff |

Card shows max 3 items + "+N more". `message.createdAt` drives a 24h action lock.

### Socket events

| Event | Direction | Payload |
|---|---|---|
| `newMedicalPickupOrderReceived` | → pharmacy | `{ "message": { …the full envelope above… } }` |
| `medicalPickupOrderReady` | → customer | `{ "messageId": "<messageId>" }` |

The first carries the **whole message**; the second carries **only `messageId`**
(the client flips `order_status` / `isReady` locally). Both are best-effort — the
message must also come back from `getMessages` history, which is the source of
truth on reload.

### Push notification operations

Add so the app plays the order sound instead of the normal chat tone (already
allow-listed client-side):

- `medical_pickup_order` → to the pharmacy, on order placed
- `medical_pickup_order_ready` → to the customer, on mark-as-ready

---

## ⑤ NEW — `PUT medical-service/orders/{orderId}/ready`

The pharmacy taps **Mark as Ready** on the chat card. Mirrors
`grocery-service/api/orders/{orderId}/ready`. Any 2xx is success (body ignored);
the client optimistically flips the badge. On success, set `isReady` /
`order_status` on the stored message and emit `medicalPickupOrderReady` so the
customer's open thread updates live.

---

## Reference — the five existing verticals

Copy the grocery implementation and swap the id key; nothing in ④/⑤ is novel.

| Vertical | `message_type` | metadata id key | ready endpoint |
|---|---|---|---|
| Grocery | `selfpickup` | `selfpickupOrderId` | `grocery-service/api/orders/{id}/ready` |
| Food | `food_selfpickup` | `foodPickupOrderId` | food service |
| Home-made food | `homemade_food_selfpickup` | `homeMadeFoodPickupOrderId` | `earn/homeFoodOrders/{id}/ready` |
| Tiffin | `tiffin_selfpickup` | `tiffinPickupOrderId` | `earn/tiffinOrders/{id}/ready` |
| Product | `product_selfpickup` | `productPickupOrderId` | inventory service |
| **Pharmacy (this doc)** | **`medical_selfpickup`** | **`medicalPickupOrderId`** | **`medical-service/orders/{id}/ready`** |

---

## Client changes already merged

| File | Change |
|---|---|
| `GetListOfMessageData.dart` | `medicalPickupOrderId` + `medicalPickupOrder` metadata (parse gated on both keys) |
| `message_card.dart` | `case "medical_selfpickup"` → `ProductSelfPickupMsgCard(isMedical: true)` |
| `product_self_pickup_msg_card.dart` | `isMedical` flag — medical metadata + medical mark-ready (reused, not cloned, like `FoodSelfPickupMsgCard` does for home-made/tiffin) |
| `medical_service_api.dart` | `medicalOrderReady(orderId)` |
| `medical_repo.dart` | `markMedicalOrderReadyRepo` |
| `app_constant.dart` | `newMedicalPickupOrderReceived`, `medicalPickupOrderReady` |
| `chat_view_controller.dart` | listeners for both events |
| `app_notification.dart` | `medical_pickup_order`, `medical_pickup_order_ready` |
| `nearest_pharmacies_controller.dart` | reads the ① keys defensively; 5-min TTL on the list |
| `medical_product_card_adapter.dart` | maps ② products onto the product card |

No new models: the pharmacy order reuses `SelfPickupOrderModel` / `SelfPickupItem`
unchanged, like every other vertical.

---

## Test checklist

1. A pharmacy with 0 categories and 0 products **does not appear** in the stores
   list (①-1a).
2. Store cards show real Category / Product / views / orders counts, not `0` (①-1b).
3. Tapping "Surgical Store" shows only surgical pharmacies, not everything (①-1c).
4. A popular-rail product that needs a prescription shows the red **Rx** badge —
   same as the same product in the category grid (②-2a).
5. Add to cart from the **category browser** → place order → the order succeeds
   (proves `items[].inventory` resolved; ②-2b).
6. Place a self-pickup order → **both** threads show the card with thumbnails,
   names, qty and grand total — not "Product Item" placeholders (④).
7. Omit `medicalPickupOrderId` → card renders empty. Confirms the gate; then put
   it back (④, gotcha #1).
8. Pharmacy taps Mark as Ready → `PUT …/ready` 2xx → badge flips → the customer's
   open thread updates live (⑤).
9. Kill and reopen the app → the card still renders from `getMessages` history.
10. Place a **rider** order → **no** chat card; lands on `MedicalConfirmScreen`.
