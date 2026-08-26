# Order flow — the Flutter side, for the backend team

> **Who this is for:** the engineers on `be_product_service_v2`, `be_chat_service` and
> `be_rider_service` who need to know exactly what the app sends, calls, listens to, and
> does with each response.
>
> **Current as of** the v3 UI guide and the round of fixes from
> `ORDER_FLOW_CLIENT_CONTRACT_REVIEW.md`. That review found six statements in the previous
> edition of this document to be stale — **the code was right and the document was wrong**
> — and this edition is rewritten against the source rather than against the old text.
>
> **Companions:** `FLUTTER_ORDER_FLOW_UI_GUIDE.md` (v3, the spec) ·
> `ORDER_FLOW_V3_FRONTEND_DONE.md` (the v3 round) ·
> `ORDER_FLOW_CLIENT_CONTRACT_REVIEW.md` (the review this answers) ·
> `ORDER_FLOW_REVIEW_FIXES_DONE.md` (what that review changed here).
>
> **Status:** `flutter analyze lib` → 0 errors. `flutter test` → 263 passing.

---

## 1. The rule the app follows

```
backend  → computes the state machine → emits availableActions[]
Flutter  → renders availableActions[] → sends the action back
```

There is no client-side rule about order age, cancellability or readiness anywhere in the
app. Every countdown is driven from `deadlines.*`; a `null` deadline renders nothing and
means "no clock for this step", never "expired". An action string this build does not
recognise renders **nothing** — never a guess.

The consequence for you: **if you do not send it, the user cannot do it.** An empty
`availableActions` renders an empty bar, not a default one. That is why the review's
finding #1 — `cancellationReasons: []` in the one state where a shop can reject — stalled
a whole flow.

---

## 2. Three planes, three shapes

The single most important thing to know about this integration: order state reaches the
app three ways, and **they do not use the same key names**.

| | Plane A — the chat card | Plane B — `GET /actions` | Plane C — `/track` & action responses |
|---|---|---|---|
| Arrives as | `metadata.lifecycle`, pushed on `productOrderLifecycle` | on demand | on demand / as each verb's reply |
| The role | *(not present — one card serves both readers)* | **`actor`** | **`viewerRole`** on `/track`, `actor` on action responses |
| Buttons | `customerActions` + `ownerActions` | `availableActions`, caller-scoped | `availableActions`, caller-scoped |
| Status line | **`banner`** | *(none)* | *(none)* |
| Money | *(none)* | *(none)* | `paymentSummary` on `/track`, **`data.payment.*`** on action responses |
| `needsAttention` | — | a **bool** | an **object** — and on `/track` it has no `flagged` key |
| Deadlines | `deadlines` | `deadlines` | `deadlines` |

The app keeps a **union** of the three, keyed by order id, and each response overwrites
only what it actually spoke about. This is not defensive politeness — it is required:

- `/actions` carries **no `banner`**, so replacing wholesale on a refresh blanked the
  card's status line.
- `/track`'s `paymentSummary` carries **no refund fields**, so replacing wholesale erased
  the difference between *"the shop owes you ₹500"* and *"the shop says it sent ₹500"*.
- `/actions` never mentions `refundDue`, so a silent `false` must not close a refund.

All three are guarded by tests in `test/order_track_contract_test.dart`.

### 2.1 What the app reads, key by key

```dart
// role
json['actor'] ?? json['viewerRole']          // both accepted; actor wins

// buttons — caller-scoped list preferred, role split only as a Plane A fallback
json['availableActions']

// money
json['payment']         // action responses  ← preferred
  ?? json['paymentSummary']   // /track

// attention
json['needsAttention'] == true                       // Plane B
  || map['flagged'] == true                          // action responses
  || (map['flagged'] == null && map.isNotEmpty)       // /track: presence IS the flag

// success-with-a-caveat
raw['warning']          // ROOT — read before unwrapping `data`
```

**We do not read `needsAttention.reason`, anywhere.** `/track` sends it to every party
including the customer, but `PAYMENT_REVIEW` / `CUSTOMER_NO_SHOW` / `DISPUTED` /
`RIDER_LATE` is an internal ops taxonomy and half of it accuses somebody. The card shows
one neutral strip: *"We're looking into this order."*

---

## 3. What the app sends when an order is created

`POST <service>/api/orders`

```jsonc
{
  "items": [ { "inventory": "…", "productVariant": "…", "quantity": 2,
               "mrp": 500, "sellingPrice": 450 } ],
  "deliveryType": "self-pickup",          // or "rider"
  "discount": 0,

  "delivery": {                            // omitted entirely when empty
    "addressLine": "…", "landmark": "…", "city": "…", "pincode": "…",

    // ⚠ THE SHAPE THE GATE READS: GeoJSON, [lng, lat], LNG FIRST.
    "location": { "type": "Point", "coordinates": [77.59, 12.97] },
    // sent alongside for anything that displays them; NOT a substitute
    "latitude": 12.97, "longitude": 77.59,

    "contactName": "…", "contactNo": "…", "instructions": "…",
    // the quote the customer was actually shown — there is no endpoint to
    // attach it later, so it rides here or it is lost
    "distanceKm": 4.2, "feeEstimate": 84, "etaMinutes": 22
  },

  "paymentMethod": "cash",                 // or "upi" — always sent explicitly
  "idempotencyKey": "d3f1…-uuid-v4"        // always sent
}
```

**Idempotency, as confirmed in the review:** one UUID v4 per checkout *attempt*, generated
when the sheet opens, cleared once an order comes back. `201` = created, `200` = you
already created this one; **both are treated as success**. The multi-store carts hold one
key per store, because a response lost halfway through that loop was the real
duplicate-order hazard.

**Checkout gates on a coordinate.** `Continue` on the address step stays disabled until
latitude and longitude both exist, so `DELIVERY_LOCATION_REQUIRED` should be unreachable.
If it does arrive, the cart reopens checkout at the address step rather than toasting.

---

## 4. Lifecycle endpoints the app calls

Built as `<service>/api/orders/:orderId/<verb>` by one helper, so a prefix change is a
one-line fix. `product-service` today; `grocery-service` / `food-service` /
`medical-service` are wired and dormant.

| Method | Path | Body we send |
|---|---|---|
| `GET` | `/actions` | — |
| `GET` | `/track` | — |
| `POST` | `/accept` | `{ prepEtaMinutes? }` |
| `POST` | `/reject` | `{ reasonCode, comment? }` |
| `POST` | `/prep-eta` | `{ prepEtaMinutes }` |
| `PUT` | `/ready` | `{}` |
| `POST` | `/payment/submit` | `{ utrNo, amountPaid, screenshotUrl, paymentQrId? }` |
| `POST` | `/payment/verify` | `{ amountReceived?, note? }` |
| `POST` | `/payment/reject` | `{ reason }` |
| `GET` | `/pickup-code` | — |
| `POST` | `/handover` | `{ pickupCode, collectedCash? }` — cash orders only for the flag |
| `POST` | `/no-show` | `{ comment? }` |
| `POST` | `/cancel` | `{ reasonCode, comment? }` |
| `POST` | `/refund/sent` | `{ refundReference, note? }` |
| `POST` | `/refund/received` | `{}` |

Optional keys are omitted, never sent as `null` or `""`.

**Envelopes we handle:** `{success, data, warning?}`; a **bare order** with
`availableActions` and no wrapper (`PUT /ready`); and `{success, data:{pickupCode}}`.

**`cancellationReasons` is the only source of reasons** — nothing is hard-coded. Bare
strings are the normal shape and are humanised (`ITEM_UNAVAILABLE` → *Item unavailable*).
If the list is empty the sheet degrades to a required free-text note submitted as `OTHER`,
so the flow cannot dead-end; that is a safety net, not a substitute for the list.

---

## 5. Real-time

### 5.1 Order lifecycle — chat socket

```dart
socket.on('productOrderLifecycle', (d) { … });   // { messageId, orderId, action, lifecycle }
```

The app patches that message's `metadata.lifecycle` in place, mirrors the legacy
`order_status` / `is_cancelled` flags, and pushes the same lifecycle into its store.
Action lists **replace, never merge** — confirmed in the review as correct, since the
service recomputes and ships both lists whole on every event.

`lastEvent` ending `_REMINDER` updates the banner and moves nothing. Ending
`_NEEDS_ATTENTION` shows the neutral strip.

### 5.2 Payment — chat socket

`payment:received` (payee) · `payment:verified` / `payment:rejected` (payer). The app reads
the order id from `order_ref` / `order_id` / `orderId` and refreshes `/actions` for it, so
**Pay now** comes back on a rejection.

### 5.3 Rider broadcast — **the chat socket**, relayed via Kafka

Not the rider socket. `ride:broadcast:searching` (`{orderId, wave, totalWaves, radiusKm,
ridersNotified}`) · `ride:broadcast:accepted` · `ride:broadcast:exhausted`.

**`ride:broadcast:closed` is not customer-facing** — it goes to the losing riders to
dismiss their popups, and the app ignores it deliberately.

> One structural note: `ChatSocketService.listenEvent` *replaces* any existing handler for
> an event name. So the app holds exactly **one** subscription to each `ride:broadcast:*`
> event, in `DiscoverController`, which fans every payload out to the order cards. A second
> subscriber anywhere would silently kill the first.

### 5.4 Reconnect and foreground

On socket reconnect and on `AppLifecycleState.resumed` the app re-fetches `/actions` for
every order card on screen, including terminal ones — a cancelled order that owes a refund
is not finished business. **No polling on a timer**, with two exceptions: rider
live-location during an active delivery, and the 3 s broadcast status poll while a search
is running, which stops on accept or exhaust.

---

## 6. Delivery is decided at checkout — there is no "find a rider" button

This replaced the old manual flow entirely, and it changes what you should expect to see.

- **A doorstep order dispatches itself.** When the card turns `ready` with no ride
  attached, the customer's device calls `POST /fare/chat-dispatch/orders` with
  **`orderType: "broadcast"` and no `selectedRiders`**. No button, no second decision, and
  the drop point comes off the order — never re-asked.
- A `429` from the 3-minute duplicate guard is treated as success: a dispatch is already
  running.
- The live wave search renders **inside the card** — radius, round N of M, an appended
  timeline, a cumulative count of partners rung, and one 60 s countdown.
- **`FIND_RIDER` is now only the self-pickup change-of-mind path**, rendered as a text
  link, running in-card. It is the one remaining case where an address is asked for after
  checkout.
- `ride:broadcast:exhausted` produces *"No delivery partner found — your order is packed
  and waiting at the shop"* with **Try again** / **Collect it myself**. It is not a
  cancellation and the app never calls it one.

`GET /fare/chat-dispatch/quote` is called before the customer commits. `feasible:false` is
treated as the 200 it is; an **absent** `feasible` means feasible; a fee that exceeds the
order value warns and never blocks.

---

## 7. Errors — branched on `code`, never on message text

Read from `code`, `errorCode`, `error_code` or `error.code`.

| Codes | What the app does |
|---|---|
| `ACTION_NOT_AVAILABLE` · `CONCURRENT_MODIFICATION` · `PAYMENT_CONFLICT` · `INVALID_SELLER_TRANSITION` · `INVALID_PAYMENT_TRANSITION` | **Normal, not a failure.** Silent refresh + *"This order has changed."* |
| `ORDER_TERMINAL` | Silent refresh, no toast |
| `NOT_A_PARTY_TO_ORDER` · `NOT_ORDER_CUSTOMER` | *"You no longer have access to this order."* |
| `ORDER_NOT_FOUND` · `INVALID_ORDER_ID` | *"This order could not be found."* |
| `USE_LIFECYCLE_ENDPOINT` · `USE_HANDOVER_ENDPOINT` | *"Please update the app to continue."* |
| `TOO_MANY_PAYMENT_ATTEMPTS` | Sheet closes, *"Please contact the shop."* |
| `UTR_ALREADY_USED` · `UTR_REQUIRED` · `SCREENSHOT_REQUIRED` · `INVALID_AMOUNT` · `PICKUP_CODE_REQUIRED` · `PICKUP_CODE_MISMATCH` · `CASH_NOT_COLLECTED` · `REFUND_REFERENCE_REQUIRED` · `REASON_REQUIRED` · `INVALID_REASON` · `INVALID_PREP_ETA` | **Inline on the field. No toast** — it would cover the field. |
| `DELIVERY_LOCATION_REQUIRED` | Reopen checkout at the address step |
| `FARE_MISMATCH` | Confirm/Cancel at the new price, re-submit **once**, never silently |
| `OUTSIDE_DELIVERY_RADIUS` | Offer self-pickup |
| *(transport failure)* | Synthesised `NETWORK_ERROR` → Retry. Safe: every action is a server-side compare-and-set |

A `2xx` carrying `warning` is a **success with a caveat** and renders as an amber note.

---

## 8. Wording that constrains the API

`banner` is rendered **verbatim**, which means a server-authored string can override the
app's own wording rules. Three of them are load-bearing:

1. **A submitted payment is a claim, not money.** The shop's card says *"Customer says they
   paid"*, never "Paid". Please don't send a banner that calls a `submitted` payment paid.
2. **Refunds name who owes the money.** *"₹500 is to be returned by **the shop**"* → *"the
   shop says they've sent it"* → *"received"*. Never "we will refund you" — the platform
   never held the money. There are tests asserting those phrasings are absent.
3. **The shop's "I sent it" does not close the refund.** Only `CONFIRM_REFUND_RECEIVED`
   does, so please keep `MARK_REFUND_SENT` / `CONFIRM_REFUND_RECEIVED` in
   `availableActions` on **cancelled** orders.

---

## 9. Open items

Everything in the previous edition's §9 was answered in the review. What is left:

1. **Shop coordinates in the cart's business block.** The review confirms the data exists
   (`business.proto` `business_location`, `inventory.proto` `BusinessLocation`) — it is
   just not on the payload the cart reads. Until it is, the checkout sheet says *"This shop
   has not set a location yet"*, disables delivery and keeps pickup. **This is the one
   thing still gating the delivery half of checkout in practice.**
2. **Refund fields on `/track`'s `paymentSummary`** — optional now. The app merges
   field-wise, so a refund-less `/track` no longer erases refund state, and refunds are
   read from Plane A/C as the review suggested. Add them if it's cheap; nothing is broken
   without them.
3. **Smoke-test the shop-declines-a-new-order path** once the `cancellationReasons` fix
   deploys, and **a doorstep order end to end** — no doorstep order has ever been created
   successfully from the app, so the GeoJSON fix is verified by test rather than by a live
   `201`.
4. **The dispatch response's ride-order id.** The app reads `data.orderId` / `_id` / `id`.
   If it is named otherwise the socket still finds the search when one is in flight, but
   the 3 s safety poll has nothing to poll.

---

## 10. Where each part lives

| Concern | File |
|---|---|
| Endpoint paths | `core/api/apiService/order_service_api.dart` |
| HTTP calls | `chat/auth/repo/order_lifecycle_repo.dart` |
| State, merging, busy flags, error branching | `chat/auth/controller/order_lifecycle_controller.dart` |
| Parsing — all three planes | `chat/auth/model/order_lifecycle_model.dart` |
| Auto-dispatch + live search state | `chat/auth/controller/order_broadcast_controller.dart` |
| The card's six zones | `chat/view/business_chat/widgets/order_lifecycle_section.dart` |
| The single action renderer | `chat/view/business_chat/widgets/order_action_bar.dart` |
| Live wave search | `chat/view/business_chat/widgets/order_broadcast_search_section.dart` |
| Checkout | `me/product/view/customer/widget/order_checkout_stepper_sheet.dart` |
| Checkout payload + idempotency | `me/product/model/order_checkout_payload.dart` |
| Socket fan-out | `common/Discover/controller/discover_controller.dart` |
