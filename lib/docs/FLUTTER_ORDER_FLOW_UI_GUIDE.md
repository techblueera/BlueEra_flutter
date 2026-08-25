# Flutter Order Flow — UI Implementation Guide

> **Audience:** the Flutter developer implementing the new order lifecycle.
> **Companion doc:** `ORDER_SYSTEM_A_TO_Z_GUIDE.md` (same folder — the why, the backend,
> the business).
> **File paths below** are relative to each service's own repo root, e.g.
> `be_product_service_v2/src/...`, `BlueEra_flutter/lib/...`.
> **Scope:** `be_product_service_v2` orders (product / pharmacy cards). Grocery, food,
> medical and home-made follow once their services are ported — the card contract is
> identical, only the `message_type` differs.

---

## 0. The one rule that changes everything

**Flutter no longer decides what a user can do.**

Today `product_self_pickup_msg_card.dart` decides for itself:

```dart
// lib/features/chat/view/business_chat/widgets/product_self_pickup_msg_card.dart:952
final isExpired = isMessageOlderThan24Hours(widget.message.createdAt);
if (isExpired && !_isReady) { /* hide the actions */ }
```

The server used **one hour**, the app uses **twenty-four**. For twenty-three hours the two
disagreed about whether the same order was alive — the shop saw a live order, the customer
saw a dead one, and neither was wrong about what their own device told them.

From now on:

```
backend  → computes the state machine → emits availableActions[]
Flutter  → renders availableActions[] → sends the action back
```

If a state is unknown to the app, it renders **no buttons** — never a guessed one. A button
the server did not offer will be refused with a typed `409`, so guessing is not just wrong,
it is visibly wrong.

**Delete every client-side rule about order age, cancellability or readiness.**

---

## 1. What arrives, and where

### 1.1 The two sources of truth for the UI

| Source | Use it for | Freshness |
|---|---|---|
| **`GET /api/orders/:orderId/actions`** | Buttons, states, deadlines, cancel reasons | On demand — authoritative |
| **Chat card `metadata.lifecycle`** | Rendering the card inline in chat without a call | Pushed by socket |

`metadata.lifecycle` is written by the chat service from the order service's events, and
carries the *same* action lists. So:

- **Rendering a chat card** → read `metadata.lifecycle` (no network).
- **Opening the order sheet / after any error** → call `/actions` (authoritative).
- **After a successful action** → the action response already returns fresh
  `availableActions`; use it directly, do not re-fetch.

### 1.2 The lifecycle block on every order card

```jsonc
"metadata": {
  "order": { /* unchanged — items, totals, orderId */ },
  "productPickupOrderId": "68f…",
  "order_status": false,     // legacy flag, still maintained
  "is_cancelled": false,     // legacy flag, still maintained
  "lifecycle": {
    "orderStatus":   "ready",           // placed|accepted|in-progress|ready|dispatched|completed|cancelled|expired
    "sellerStatus":  "ready",           // this shop's square (owner view)
    "paymentMethod": "upi",             // cash|upi|gateway
    "paymentState":  "verified",        // pending|submitted|under_review|verified|rejected|expired|refund_pending|refunded
    "customerActions": ["VIEW_PICKUP_CODE","CONTACT_SHOP","RAISE_ISSUE"],
    "ownerActions":    ["CONFIRM_HANDOVER","REPORT_NO_SHOW","CANCEL_ORDER","CONTACT_CUSTOMER"],
    "deadlines": { "acceptBy": null, "payBy": null, "readyBy": null,
                   "pickupBy": "2026-08-21T14:30:00Z", "hardExpiryAt": "2026-08-22T09:00:00Z" },
    "lastEvent":   "PRODUCT_ORDER_PAYMENT_VERIFIED",
    "lastEventAt": "2026-08-21T11:32:10Z",
    "banner":      "Payment verified by the shop",
    "reasonCode":  null,
    "refundDue":   false
  }
}
```

`banner` is server-authored, human-readable, and already localised in tone. **Render it
verbatim as the card's status line.** Do not build your own string from `orderStatus` — that
is how the app and the server drift apart again.

---

## 2. The action vocabulary

Every string that can appear in `customerActions` / `ownerActions`, the widget it becomes,
and the call it makes. **This table is the complete contract.**

### Customer

| Action | Button | Call |
|---|---|---|
| `SUBMIT_PAYMENT` | **Pay now** (primary) | opens `payment_qr_bottom_sheet.dart` → `POST /api/orders/:id/payment/submit` |
| `VIEW_PICKUP_CODE` | **Show pickup code** (primary) | `GET /api/orders/:id/pickup-code` |
| `CANCEL_ORDER` | **Cancel order** (destructive, text) | reason sheet → `POST /api/orders/:id/cancel` |
| `FIND_RIDER` | **Get it delivered** | quote sheet → `GET /fare/chat-dispatch/quote` → `POST /fare/chat-dispatch/orders` |
| `CONTACT_SHOP` | phone icon | existing `call_customer_controller.dart` |
| `RAISE_ISSUE` | **Report a problem** (text) | existing support flow |
| `CONFIRM_REFUND_RECEIVED` | **I received the refund** (primary) | `POST /api/orders/:id/refund/received` |

### Owner

| Action | Button | Call |
|---|---|---|
| `ACCEPT_ORDER` | **Accept** (primary green) | ETA sheet → `POST /api/orders/:id/accept` |
| `REJECT_ORDER` | **Can't take it** (destructive) | reason sheet → `POST /api/orders/:id/reject` |
| `SET_PREP_ETA` | **Update time** (text) | ETA sheet → `POST /api/orders/:id/prep-eta` |
| `MARK_READY` | **Order packed** (primary) | `PUT /api/orders/:id/ready` |
| `VERIFY_PAYMENT` | **Payment received** (primary green) | `POST /api/orders/:id/payment/verify` |
| `REJECT_PAYMENT` | **Not received** (destructive) | reason sheet → `POST /api/orders/:id/payment/reject` |
| `CONFIRM_HANDOVER` | **Handed over** (primary) | code dialog → `POST /api/orders/:id/handover` |
| `REPORT_NO_SHOW` | **Customer didn't come** (text) | `POST /api/orders/:id/no-show` |
| `CANCEL_ORDER` | **Cancel order** (destructive, text) | reason sheet → `POST /api/orders/:id/cancel` |
| `MARK_REFUND_SENT` | **I sent the refund** (primary) | UTR dialog → `POST /api/orders/:id/refund/sent` |
| `CONTACT_CUSTOMER` | phone icon | existing |

### Renderer

Put this in one place — e.g. `lib/features/chat/view/business_chat/widgets/order_action_bar.dart`
— and use it from every order card. One switch, one source of truth, no per-card copies.

```dart
Widget buildActionBar(List<String> actions, OrderCardContext ctx) {
  final widgets = <Widget>[];
  for (final a in actions) {
    switch (a) {
      case 'ACCEPT_ORDER':      widgets.add(_primary('Accept', () => _acceptFlow(ctx)));       break;
      case 'REJECT_ORDER':      widgets.add(_destructive("Can't take it", () => _rejectFlow(ctx))); break;
      case 'MARK_READY':        widgets.add(_primary('Order packed', () => _markReady(ctx)));  break;
      case 'VERIFY_PAYMENT':    widgets.add(_primary('Payment received', () => _verify(ctx))); break;
      case 'REJECT_PAYMENT':    widgets.add(_destructive('Not received', () => _rejectPay(ctx))); break;
      case 'CONFIRM_HANDOVER':  widgets.add(_primary('Handed over', () => _handover(ctx)));    break;
      case 'REPORT_NO_SHOW':    widgets.add(_text("Customer didn't come", () => _noShow(ctx))); break;
      case 'SUBMIT_PAYMENT':    widgets.add(_primary('Pay now', () => _payFlow(ctx)));         break;
      case 'VIEW_PICKUP_CODE':  widgets.add(_primary('Show pickup code', () => _showCode(ctx))); break;
      case 'FIND_RIDER':        widgets.add(_secondary('Get it delivered', () => _findRider(ctx))); break;
      case 'CANCEL_ORDER':      widgets.add(_text('Cancel order', () => _cancelFlow(ctx)));    break;
      case 'SET_PREP_ETA':      widgets.add(_text('Update time', () => _etaSheet(ctx)));       break;
      case 'CONTACT_SHOP':
      case 'CONTACT_CUSTOMER':  widgets.add(_iconCall(ctx));                                   break;
      case 'RAISE_ISSUE':       widgets.add(_text('Report a problem', () => _support(ctx)));   break;
      // Unknown action from a newer backend → render nothing. Never guess.
      default: break;
    }
  }
  return Wrap(spacing: 8, runSpacing: 8, children: widgets);
}
```

---

## 3. State-by-state UI

Each row: what the customer sees, what the shop sees. `orderStatus` × `paymentState`.

### 3.1 `placed` — waiting for the shop

| | Customer | Owner |
|---|---|---|
| Banner | "Waiting for the shop to confirm" | "New order — confirm within *N* min" |
| Extra | countdown to `deadlines.acceptBy` | countdown to `deadlines.acceptBy`, pulsing |
| Buttons | Cancel order · Call shop | **Accept** · **Can't take it** · Call |
| Payment | **Nothing.** No pay button, no QR. | — |

> **Why there is no pay button here.** Money is only requested after acceptance. If the shop
> turns out to be closed, nobody has to be refunded. Do not "helpfully" show the QR early.

**Countdown widget:** drive it from `deadlines.acceptBy`, not from `createdAt + constant`.
When it hits zero, show *"Confirming…"* and re-fetch `/actions` once — the sweeper cancels
within a minute and will send the real card. Do **not** flip the card to expired yourself.

### 3.2 `accepted` — confirmed, money time (UPI only)

| | Customer | Owner |
|---|---|---|
| Banner | "Order accepted — ready in about 20 min" | "Preparing" |
| Extra | ready-by time from `deadlines.readyBy` | ready-by time |
| Buttons (cash) | Cancel order · Call | **Order packed** · Update time · Cancel · Call |
| Buttons (UPI) | **Pay now** · Cancel · Call | same as cash, plus payment card once submitted |

### 3.3 Payment sub-states (UPI)

This is the sequence that must never look like a single step.

```
pending      customer: [Pay now]              owner: (nothing yet)
   ↓ POST /payment/submit
submitted    customer: "Waiting for the shop to confirm your payment"  ← spinner-ish, no buttons
             owner:    [Payment received] [Not received] + screenshot + UTR + amount
   ↓ owner verifies                       ↓ owner rejects
verified     customer: "Payment verified ✓"   owner: [Order packed] / [Handed over]
rejected     customer: "Payment not confirmed: <reason>" + [Pay now] again
expired      customer: "Payment window closed" + [Pay now] again
```

**Payment sheet (`payment_qr_bottom_sheet.dart` — extend, don't replace):**

1. Fetch the shop's QR (existing `payment_qr_controller.dart`).
2. Show QR + UPI id + **the exact amount due** (`paymentSummary.amountDue`).
3. "I have paid" → form: **UTR number** (required) · **amount paid** (pre-filled with
   amountDue, editable) · **screenshot** (required, via existing S3 pre-signed upload).
4. `POST /api/orders/:id/payment/submit`.

**Errors this sheet must handle by code, not by message text:**

| Code | HTTP | UI |
|---|---|---|
| `UTR_ALREADY_USED` | 409 | Red inline on the UTR field: *"This reference number has already been used. Check your bank app and enter the correct one."* Keep the sheet open. |
| `TOO_MANY_PAYMENT_ATTEMPTS` | 429 | Close sheet, show *"Please contact the shop."* + Call button. |
| `ACTION_NOT_AVAILABLE` | 409 | The order moved on. Close, refresh from `/actions`, toast *"This order has changed — please check again."* |
| `UTR_REQUIRED` / `SCREENSHOT_REQUIRED` / `INVALID_AMOUNT` | 400 | Inline field errors. |

**Amount mismatch:** a successful response may carry `warning`. Show it as an amber note on
the card — *"You entered ₹450 but the order is ₹500."* — not as an error. The submission
succeeded; the shop will now see the same mismatch.

**Owner's verification card** must show, together: the screenshot (tap to zoom), the UTR
(long-press to copy), **amount paid vs amount due side by side**, and an amber highlight when
they differ. Then the two buttons. The whole point is that the shop checks their own bank app
before tapping — the UI should make that comparison effortless.

> Never label a `submitted` payment as "Paid". The word for `submitted` is **"says they
> paid"**. This single wording choice is what stops a shop handing over goods on a
> screenshot.

### 3.4 `ready` — packed and waiting

| | Customer | Owner |
|---|---|---|
| Banner | "Your order is ready for pickup" | "Ready — waiting for the customer" |
| Extra | **big pickup code**, shop address, directions | "Ask the customer for their pickup code" |
| Buttons | **Show pickup code** · Get it delivered · Cancel? (only if offered) · Call | **Handed over** · Customer didn't come · Cancel · Call |

**Pickup code screen (customer):** full-width, large mono type, high contrast, keeps the
screen awake. It is read aloud or shown across a counter.

**Handover dialog (owner):** 6-character uppercase input, auto-uppercase, auto-submit at 6.

| Code | HTTP | UI |
|---|---|---|
| `PICKUP_CODE_MISMATCH` | 403 | Shake the field, *"That code doesn't match this order."* Do not close. |
| `ACTION_NOT_AVAILABLE` | 409 | Usually an unverified UPI payment. Close and show *"Confirm the payment first."* |
| `CASH_NOT_COLLECTED` | 409 | Only if you sent `collectedCash:false`. |

For **cash** orders, put a checkbox in the dialog: *"I have collected ₹500 in cash"*, checked
by default, sent as `collectedCash`. One tap records both the goods leaving and the money
arriving — so a busy shop cannot forget half of it.

### 3.5 `completed`

Both sides: green tick, "Order completed", collapse the card to a summary row. Customer gets
a **Rate the shop** entry point. No further action buttons except `RAISE_ISSUE`.

### 3.6 `cancelled` / `expired`

Grey card. **Always show the reason** — `lifecycle.banner` already contains it in plain
language ("Order cancelled by shop — item not available").

### 3.6.1 Refunds — say who owes the money

**This is the wording that matters most in the whole app.**

With direct UPI the customer paid the **shop's own VPA**. The platform never held
a paisa of it, has no balance to reverse and no gateway to call. Telling a customer
*"your refund is being processed"* implies we are sending it — we are not, and we
cannot — which manufactures a complaint against us for someone else's inaction.

The event carries `refundOwedBy` (`"shop"` today, always). Render accordingly:

| `paymentState` | `refundInitiatedAt` | Customer sees | Owner sees |
|---|---|---|---|
| `refund_pending` | null | *"₹500 is to be returned by **the shop**. We've asked them to send it."* + Report a problem | **I sent the refund** + Call customer |
| `refund_pending` | set | *"The shop says they've sent ₹500 (ref UTR…). Confirm when it reaches you."* + **I received the refund** | *"Waiting for the customer to confirm"* + Call |
| `refunded` | — | *"Refund received ✓"* | *"Refund settled ✓"* |

**Two rules:**
1. Never say *"we will refund you"* or *"refund processed"*. Say **"the shop will
   return it"**, then **"the shop says they've sent it"**, then **"received"**.
2. **The owner's "I sent it" does NOT close the refund.** It is a claim, exactly
   like the customer's original screenshot was a claim — same trust model,
   applied symmetrically. Only `CONFIRM_REFUND_RECEIVED` (or an admin
   close-out) ends it. Do not grey the card out at step 2.

**Owner's refund dialog:** amount (read-only, from `paymentSummary.amountPaid`),
**UTR of the return transfer** (required), and the customer's UPI id if known.
`REFUND_REFERENCE_REQUIRED` (400) → inline field error.

These actions appear on an order that is **already cancelled** — a cancelled
order that owes money is not finished business. Do not hide action bars on
terminal orders; render whatever `availableActions` contains.

### 3.7 Reminders and escalations

`lastEvent == "PRODUCT_ORDER_REMINDER"` is **not** a state change. Update the banner, do not
re-animate the card, do not move it in the list beyond the normal `updated_at` reorder.

`lastEvent == "PRODUCT_ORDER_NEEDS_ATTENTION"` → show a neutral info strip:
*"We're looking into this order."* Do not expose the internal reason code to either party.

---

## 4. Checkout — what has to change

**File:** `lib/features/me/product/view/customer/product_self_pickup_cart_screen.dart`
(and the automotive / manufacturer / food twins).

`POST /api/orders` now accepts three new fields. All are backwards compatible — an old build
keeps working — but the app should send all three.

```dart
final body = {
  'items': items,
  'deliveryType': isSelfPickup ? 'self-pickup' : 'rider',
  'discount': discount,

  // NEW — required when deliveryType == 'rider', recommended always
  'delivery': {
    'addressLine': address.line,
    'landmark':    address.landmark,
    'city':        address.city,
    'pincode':     address.pincode,
    'latitude':    address.lat,      // flat lat/lng is accepted
    'longitude':   address.lng,
    'contactName': address.name,
    'contactNo':   address.phone,
    'instructions': notes,
    // from GET /fare/chat-dispatch/quote — records what the customer was shown
    'distanceKm':  quote?.distanceKm,
    'feeEstimate': quote?.deliveryFee,
    'etaMinutes':  quote?.etaMinutes,
  },

  // NEW — 'cash' (default) or 'upi'
  'paymentMethod': selectedPaymentMethod,

  // NEW — one UUID per checkout ATTEMPT, regenerated only when the user
  // returns to the cart. This is what makes a double-tap or a retry safe.
  'idempotencyKey': _checkoutAttemptId,
};
```

### 4.1 The idempotency key — get this right

```dart
class ProductSelfPickupController extends GetxController {
  String? _checkoutAttemptId;

  /// Call when the checkout sheet OPENS. Not on every tap.
  void beginCheckoutAttempt() => _checkoutAttemptId = const Uuid().v4();

  Future<void> placeOrder() async {
    _checkoutAttemptId ??= const Uuid().v4();
    final res = await api.createOrder(body);
    // 201 = created, 200 = you already created this one. Both are success.
    if (res.statusCode == 201 || res.statusCode == 200) {
      _checkoutAttemptId = null;   // done — a NEW order needs a NEW key
      _onOrderPlaced(res.data);
    }
  }
}
```

The retry-after-timeout case is the one that matters: the request succeeded, the response was
lost, the user taps again. With the key, they get the same order back with `200`. Without it,
they get two orders and one very confused shop.

### 4.2 The checkout sheet

```
┌───────────────────────────────────────┐
│ How do you want it?                   │
│  ( ) Pick up from the shop            │
│  (•) Deliver to my address            │
├───────────────────────────────────────┤
│ [delivery selected]                   │
│  Deliver to: 12 MG Road, 560001  [>]  │
│  Delivery: ₹44 · 15–30 min            │
│  ⚠ Delivery costs more than your      │
│    order. Picking it up is cheaper.   │
├───────────────────────────────────────┤
│ How will you pay?                     │
│  (•) Cash        ( ) UPI              │
├───────────────────────────────────────┤
│ Items       ₹500                      │
│ Delivery     ₹44                      │
│ Total       ₹544                      │
│         [ Place order ]               │
└───────────────────────────────────────┘
```

**Delivery quote — call it before the customer commits, not after:**

```
GET {rider}/fare/chat-dispatch/quote
    ?shopLat=&shopLng=&dropLat=&dropLng=&distance_in_km=&orderValue=
```

Debounce ~400 ms on address change. Response:

```jsonc
{ "feasible": true, "distanceKm": 4.2, "deliveryFee": 84,
  "etaMinutes": 22, "etaRange": { "min": 17, "max": 32 },
  "breakdown": { … },
  "economics": { "feeExceedsOrderValue": true, "feeToOrderRatio": 8.4,
                 "suggestion": "Delivery costs a lot compared to this order — collecting it from the shop may be cheaper." } }
```

- `feasible: false` → **200, not an error.** Disable the delivery radio, show
  `message` ("Delivery is only available within 12 km of the shop"), auto-select self-pickup.
- `economics.feeExceedsOrderValue` or `feeIsHighVsOrder` → amber note with `suggestion` and a
  **"Pick it up instead"** shortcut. **Do not block.** A customer who wants their ₹10 item
  delivered is allowed to pay ₹84 for it — they just must not be surprised by it.

### 4.3 Dispatching the rider

`POST /fare/chat-dispatch/orders` now **recomputes the fare server-side**. Send back the
`deliveryFee` you displayed, in `fare`, as a confirmation.

| Code | HTTP | UI |
|---|---|---|
| `FARE_MISMATCH` | 409 | Response carries `quotedFare` and a fresh `quote`. Show *"The delivery charge is now ₹96."* with **Confirm** / **Cancel**. Never silently re-submit at the higher price. |
| `OUTSIDE_DELIVERY_RADIUS` | 422 | *"We can't deliver to this address."* → offer self-pickup. |
| — | 429 | *"You already requested delivery for this order recently."* |

---

## 5. Real-time

### 5.1 Sockets

One new generic channel plus per-event channels. **Subscribe to the generic one** and switch
on `action`; the specific names exist for legacy compatibility only.

```dart
socket.on('productOrderLifecycle', (data) {
  // { messageId, orderId, action, lifecycle: { … } }
  chatController.patchMessageLifecycle(data['messageId'], data['lifecycle']);
});
```

Payment (chat service, existing channel family):

| Event | Who receives | UI |
|---|---|---|
| `payment:received` | payee (shop) | new payment awaiting verification; now carries `status`, `order_ref`, `amount_mismatch` |
| `payment:verified` | payer (customer) | *"Payment verified ✓"* |
| `payment:rejected` | payer (customer) | *"Payment not confirmed: <reason>"* + re-enable Pay |

### 5.2 The reconnect rule

Sockets drop. On reconnect, and on app foreground, **re-fetch `/actions` for every visible
open order**. A missed socket event is the difference between a shop staring at a stale
"Accept" button and a shop that knows the order was auto-cancelled ten minutes ago.

```dart
void onAppResumed() {
  for (final id in visibleOpenOrderIds) {
    orderController.refreshActions(id); // GET /api/orders/:id/actions
  }
}
```

**Do not poll on a timer.** Sockets + foreground refresh + post-action responses cover it.
The only justified poll is rider live-location during an active delivery, which
`rider_location_poll_controller.dart` already does.

---

## 6. Loading, error, empty, timeout

Apply uniformly across every action.

**Loading.** Disable the *tapped* button and show an inline spinner **inside it**. Do not
block the whole card — the other party's updates must keep landing. Every action handler
needs its own `RxBool`; `_isMarkingReady` is the pattern already in
`product_self_pickup_msg_card.dart`, generalise it.

**Optimistic updates: don't.** Every one of these actions can legitimately fail with `409`.
Wait for the response, then apply the returned `availableActions`. An optimistically-hidden
Accept button that comes back is worse than a spinner.

**Errors.** Branch on `code`, never on `message`:

```dart
switch (err.code) {
  case 'ACTION_NOT_AVAILABLE':
  case 'CONCURRENT_MODIFICATION':
  case 'PAYMENT_CONFLICT':
    await refreshActions(orderId);
    toast('This order has changed. Please check the updated details.');
    break;
  case 'ORDER_TERMINAL':
    await refreshActions(orderId);
    break;
  case 'NOT_A_PARTY_TO_ORDER':
    toast('You no longer have access to this order.');
    break;
  case 'USE_LIFECYCLE_ENDPOINT':
  case 'USE_HANDOVER_ENDPOINT':
    // A build calling a retired path. Ship a fix; meanwhile:
    toast('Please update the app to continue.');
    break;
  default:
    toast(err.message ?? 'Something went wrong. Please try again.');
}
```

`ACTION_NOT_AVAILABLE` is **normal**, not exceptional: it means the other party moved first.
Treat it as a refresh cue, never as a crash.

**Network failure.** Show a **Retry** on the card. Retrying is always safe: every action is
idempotent server-side, so a retry after an unknown outcome cannot double-apply.

**Empty.** No orders → keep the existing empty-state widget.

**Timeout / countdown.** Render from `deadlines.*`. When one elapses, show a neutral
*"Checking…"* and refresh once. Never render a terminal state the server has not sent.

---

## 7. Rider leg (unchanged, listed for completeness)

The existing rider cards keep working exactly as they do today:

| File | Shows |
|---|---|
| `rider_request_msg_card.dart` | searching / rider offers |
| `rider_details_msg_card.dart` | assigned rider, vehicle, contact |
| `rider_otp_msg_card.dart` | pickup OTP (shop) / delivery OTP (customer) |
| `rider_live_location_msg_card.dart` | live tracking |
| `track_rider_live_location_page.dart` | full-screen map |

Broadcast search sockets already emitted by the rider service:
`ride:broadcast:searching` (wave N of M, radius, riders notified) ·
`ride:broadcast:accepted` · `ride:broadcast:exhausted` (no rider found) ·
`ride:broadcast:closed` (rider-side dismissal).

Wire `ride:broadcast:searching` into the searching card so the customer sees
*"Looking within 3 km… 6 km… 10 km"* instead of an unexplained spinner, and
`ride:broadcast:exhausted` into a clear *"No delivery partner available right now"* with
**Try again** / **Pick it up instead**.

---

## 8. Files to change

| File | Change |
|---|---|
| `chat/view/business_chat/widgets/product_self_pickup_msg_card.dart` | **Remove** the 24h client-side expiry (`:952`). Render `metadata.lifecycle.banner`. Replace the hand-built action row with `buildActionBar`. |
| `chat/view/business_chat/widgets/self_pickup_msg_card.dart` | same, once grocery is ported |
| `chat/view/business_chat/widgets/food_self_pickup_msg_card.dart` | same, once food is ported |
| `chat/view/business_chat/widgets/order_action_bar.dart` | **new** — the single action renderer |
| `chat/view/business_chat/widgets/payment_qr_bottom_sheet.dart` | add UTR + amount + screenshot form; post to the order endpoint |
| `chat/view/business_chat/widgets/payment_transaction_msg_card.dart` | show status, amount-vs-due, verify/reject buttons for the payee |
| `chat/view/business_chat/widgets/pickup_handover_dialog.dart` | **new** — 6-char code entry + cash checkbox |
| `chat/view/business_chat/widgets/pickup_code_screen.dart` | **new** — customer's large-type code |
| `chat/auth/model/self_pickup_order_model.dart` | add `OrderLifecycle` model |
| `chat/auth/controller/order_controllar.dart` | add the action calls + `refreshActions` |
| `core/api/apiService/order_service_api.dart` | add the nine new endpoints |
| `me/product/view/customer/product_self_pickup_cart_screen.dart` | delivery/payment/idempotency in checkout |
| `common/Discover/view/book_your_transport/product_order_booking_rider_main.dart` | call the quote endpoint before dispatch; handle `FARE_MISMATCH` |

---

## 9. Endpoint reference

Base: product service. Auth: `Authorization: Bearer <jwt>` on all.

| Method | Path | Role | Body |
|---|---|---|---|
| `GET` | `/api/orders/:orderId/actions` | any party | — |
| `POST` | `/api/orders/:orderId/accept` | business | `{ prepEtaMinutes? }` |
| `POST` | `/api/orders/:orderId/reject` | business | `{ reasonCode, comment? }` |
| `POST` | `/api/orders/:orderId/prep-eta` | business | `{ prepEtaMinutes }` |
| `PUT` | `/api/orders/:orderId/ready` | business | — |
| `POST` | `/api/orders/:orderId/payment/submit` | customer | `{ utrNo, amountPaid, screenshotUrl, paymentQrId?, upiId?, transactionRef? }` |
| `POST` | `/api/orders/:orderId/payment/verify` | business/admin | `{ amountReceived?, note? }` |
| `POST` | `/api/orders/:orderId/payment/reject` | business/admin | `{ reason }` |
| `GET` | `/api/orders/:orderId/pickup-code` | customer | — |
| `POST` | `/api/orders/:orderId/handover` | business | `{ pickupCode, collectedCash? }` |
| `POST` | `/api/orders/:orderId/no-show` | business | `{ comment? }` |
| `POST` | `/api/orders/:orderId/cancel` | any party | `{ reasonCode, comment? }` |
| `POST` | `/api/orders/:orderId/refund/sent` | business | `{ refundReference, note? }` |
| `POST` | `/api/orders/:orderId/refund/received` | customer | — |
| `GET` | `/api/orders/:orderId/track` | any party | — (now also returns `availableActions`, `paymentSummary`, `cancellation`, `deadlines`) |
| `GET` | `/fare/chat-dispatch/quote` | customer | query params |
| `POST` | `/fare/chat-dispatch/orders` | customer | existing + `distance_in_km`, `orderValue` |

Chat service (payments):

| Method | Path |
|---|---|
| `POST` | `/payment-qr/transactions` (now accepts `order_service`, `order_id`, `expected_amount`) |
| `GET` | `/payment-qr/transactions/pending` |
| `POST` | `/payment-qr/transactions/:id/verify` |
| `POST` | `/payment-qr/transactions/:id/reject` |

**Cancellation reasons come from `/actions`**, in `cancellationReasons[]`, already scoped to
the caller's role. Do not hard-code them — a customer must not be able to pick
`ITEM_UNAVAILABLE`, and the server will reject it anyway with `INVALID_REASON`.

---

## 9b. FRONTEND IMPLEMENTATION AUDIT (contract audit against real Dart source)

> **STATUS: IMPLEMENTED.** This audit was originally written before any Dart file
> was touched — every "After" row then read *REQUIRED — NOT IMPLEMENTED*. Those
> rows have since been built. The "Before" column is kept as the historical record
> of what the source looked like; the line numbers in it refer to the **pre-change**
> files and no longer resolve.
>
> **What shipped, and what did not, is recorded in
> `ORDER_FLOW_IMPLEMENTATION_COMPLETE.md` (same folder).** Read that for the
> current state — including the two items that are still open.

### 9b.1 Before vs After

| File | Before (verified in source) | After | Why it must change |
|---|---|---|---|
| `chat/.../product_self_pickup_msg_card.dart:951-953` | `isExpired = isMessageOlderThan24Hours(message.createdAt)` — **client-side 24 h expiry** | **DONE** — reads `lifecycle.deadlines` via `OrderLifecycleSection` | Server expires on its own configurable clocks. Client and server disagreed for 23 h. |
| `chat/.../food_self_pickup_msg_card.dart:985-987` | **same 24 h rule** | **DONE** | The guide previously named only the product card. **The rule exists in 3 order cards, not 1.** |
| `chat/.../self_pickup_msg_card.dart:966-968` | **same 24 h rule** (grocery) | **DONE** | ditto |
| `chat/.../rider_details_msg_card.dart:61,223` · `rider_live_location_msg_card.dart:37` | 24 h rule used to grey out **tracking/call** buttons | **LEAVE AS-IS** | This is display hygiene on a rider card, not order state. Do **not** delete it — it is not an order business rule. |
| `me/product/controller/product_selfpickup_controller.dart:254-258` | `{items, deliveryType:"self-pickup", discount}` — `deliveryType` **hard-coded** | **DONE** — sends `delivery`, `paymentMethod`, `idempotencyKey` | No delivery option exists at checkout; no address is ever sent. |
| `common/Discover/controller/hmp_cart_controller.dart:227-240` | same 3-field payload, `deliveryType` hard-coded | **DONE** | ditto |
| `common/Discover/controller/hmp_cart_controller.dart:304-313` | **loop** placing one order per store, **no idempotency key**, counts successes | **DONE** — one key per store | A lost response mid-loop duplicates orders on retry. |
| `chat/auth/repo/make_order_repo.dart:68-74` | `verifyPayment()` → `order-service/api/orders/verify-payment` — **DEAD CODE, zero callers** | **DONE** — `OrderLifecycleRepo.verifyPayment` now posts to `POST /api/orders/:id/payment/verify`; the dead constant is kept only so an old import compiles. | There was no payment-verification UI. Must be repointed at `POST /api/orders/:id/payment/verify`. |
| `chat/auth/controller/chat_view_controller.dart:1866,1891` | listens to `newProductPickupOrderReceived`, `productPickupOrderReady` only | **DONE** — `productOrderLifecycle` listener added | 13 new lifecycle events are emitted; none are consumed. |
| `chat/auth/controller/payment_qr_controller.dart:277` | handles `payment:received` | **DONE** — `payment:verified` / `payment:rejected` handled | Payer is never told the outcome. |
| all order cards | action rows built from **hard-coded `if` conditions** on `_isReady` / `_isCancelled` | **DONE** — renders `availableActions` via `order_action_bar.dart` | Client can show actions the backend will reject. |

### 9b.2 What the backend does about all this today

**Every backend change is backwards compatible, and that is verified, not assumed.**
`delivery`, `paymentMethod` and `idempotencyKey` are all optional; the exact 3-field
payload above still creates an order. Consequences of the app *not* changing:

- `deliveryType` is always `"self-pickup"` → **the rider/delivery path is unreachable from the app.**
- `paymentMethod` is absent → defaults to `cash` → **the whole UPI verification flow is unreachable.**
- `idempotencyKey` is absent → **every order carries `idempotencyKey: null`.**

> ⚠️ That last point is why the index defect found in verification was catastrophic
> rather than theoretical. The original `{ unique: true, sparse: true }` compound
> index indexed **every** order under `idempotencyKey: null`, so a customer's
> **second order would fail forever** — and because Flutter never sends a key,
> that would have hit **100 % of production orders**, not an edge case. Fixed with
> `partialFilterExpression`; regression-tested.

### 9b.3 Client-side business rules found (exhaustive search)

Searched for `createdAt + duration`, `24 hours`, `1 hour`, `isExpired`, local timers
and local state transitions across `features/chat`, `features/me`, `features/common`:

| Finding | Verdict |
|---|---|
| 24 h expiry in the **3 order cards** | **REMOVE** — replace with `lifecycle.deadlines` |
| 24 h greying in **rider cards** | **KEEP** — display hygiene, not order state |
| `track_live_location.dart:41,66,76` `_isExpired` | **KEEP** — live-tracking session TTL, unrelated |
| `order_chat_screen.dart:130` `Duration(hours: 24)` | **already commented out** — no action |
| `product_selfpickup_controller.dart:246` `isPlacingOrder` guard | **KEEP, INSUFFICIENT** — guards a double-tap in one session; does not survive a lost response. Still needs `idempotencyKey`. |
| Local order status transitions | **none found** — cards mutate `metadata` optimistically after a successful call only (e.g. `product_self_pickup_msg_card.dart:787-788`) |

### 9b.4 API contract audit

| Flutter call | Backend endpoint | Verdict |
|---|---|---|
| `POST product-service/api/orders` (3 fields) | `POST /api/orders` | ✅ **compatible** — new fields optional |
| `PUT inventory-service/orders/{id}/ready` (`inventory_service_api.dart:8`) | `PUT /api/orders/:orderId/ready` | ⚠️ **PREFIX MISMATCH — MUST CONFIRM.** Flutter uses `inventory-service/orders/...` with **no `/api/`**, while every other vertical uses `<svc>/api/orders/...`. The existing call works, so the gateway rewrites it. **The 13 new routes must use the same rewrite** or they will 404. Verify in staging before writing any Dart. |
| `POST order-service/api/orders/verify-payment` | *(does not exist in product v2)* | ❌ **dead constant** — no caller, no matching backend route |
| — | 13 new endpoints (accept/reject/payment/handover/cancel/refund/actions) | ❌ **not called by any Dart file** |

### 9b.5 Handoff order for the Flutter developer

1. **Confirm the gateway prefix first** (9b.4 row 2). Everything else is blocked on it.
2. Add `idempotencyKey` to both checkout payloads — highest value, smallest change.
3. Add `productOrderLifecycle` socket listener + render `lifecycle.banner`.
4. Build `order_action_bar.dart` (§2) and delete the 24 h rule from the **3 order cards only**.
5. Then payment, delivery, refund UI.

---

## 10. Test checklist

- [ ] Double-tap every button → one effect, no error toast
- [ ] Kill the network mid-action, retry → no duplicate
- [ ] Two devices on the same shop account: both tap Accept → one succeeds, the other refreshes cleanly
- [ ] Customer cancels while the shop taps Accept → whichever loses shows a refresh, not a crash
- [ ] Submit a UTR already used on another order → inline field error, sheet stays open
- [ ] Submit an amount lower than the total → succeeds with an amber warning; the shop sees the mismatch
- [ ] Shop tries Handover on an unverified UPI payment → button is absent, and the call 409s if forced
- [ ] Enter a wrong pickup code → shake, retry allowed
- [ ] Leave an order unaccepted past `acceptBy` → card becomes cancelled with a reason, no client-side guessing
- [ ] Background the app for an hour, resume → every open order refreshes
- [ ] Force-quit mid-payment, reopen → correct state, no ghost spinner
- [ ] Quote a 15 km address → delivery disabled with a reason, self-pickup offered
- [ ] Quote a ₹10 order at 8 km → amber warning + "Pick it up instead"
- [ ] Old app build against the new backend → still renders (legacy `order_status` / `is_cancelled` flags maintained)
- [ ] Cancel a paid UPI order → card says **the shop** returns the money, never "we will refund you"
- [ ] Shop taps "I sent the refund" → card does **not** close; customer gets a confirm button
- [ ] Customer confirms → both cards settle
- [ ] A cancelled order still shows refund actions (terminal ≠ no buttons)
- [ ] Delivery order packed, no rider found → card shows the escalation + "pick it up instead", **not** a cancellation
