# Flutter Order Flow — UI Implementation Guide (v3)

> **Audience:** the Flutter developer building checkout and the order cards.
> **Replaces:** v1 (contract) and v2 (states). **v3 is the UI spec** — the look, the
> flow, the live states, and the design system that ties them together.
> **Companion:** `ORDER_SYSTEM_A_TO_Z_GUIDE.md` (the backend, the business, the why).
> **Verified:** every field, number, endpoint, event and error code below was read
> out of `be_product_service_v2`, `be_rider_service` and `be_chat_service` on
> `prod-staging`, and cross-checked against `BlueEra_flutter/lib` on `main`.

> ## ✅ STATUS: IMPLEMENTED (Flutter, this repo)
>
> Every P0, P1 and P2 item below is built. `flutter analyze lib` → **0 errors**;
> `flutter test` → **245 passing** (was 187), 57 of them new and specific to v3.
>
> **What shipped, what was deferred, and why, is recorded in
> `ORDER_FLOW_V3_FRONTEND_DONE.md` (same folder).** Read that for the current
> state — including the four items still open before release and the one part of
> §5.2 that was deliberately not built (the draggable map pin).
>
> The spec below is unchanged and remains the contract. Section headings now
> carry a status line where the implementation has something to declare.

**What changed in v3**

- **The manual "ride" button is gone.** Delivery is chosen at **checkout**, behind
  an address gate, and dispatch is automatic from then on. §5, §7.
- **The rider search is fully visible** — round timeline, expanding radius,
  partners called, countdown, live avatars. §7.3.
- **A design system** so the cards look like one modern product, not eleven
  screens. §3.
- Two new backend traps found and documented: §0 rows 6 and 7.

---

## 0. Why the app still looks static

Seven verified causes, worst first. **None of them need a backend change.**

| # | The app does | The backend actually sends | Symptom | § |
|---|---|---|---|---|
| **1** | reads `isOwner` / `role` from `/actions` ([order_lifecycle_model.dart:518-523](../../BlueEra_flutter/lib/features/chat/auth/model/order_lifecycle_model.dart)) | **`actor`**: `"customer"` \| `"owner"` \| `"admin"` ([orderActions.controller.js:1174](../../be_product_service_v2/src/controllers/orderActions.controller.js)) | `isOwner` is always `null` → the app guesses → **buyer and seller see the same buttons** | 2.2 |
| **2** | parses `paymentSummary` (`:546`) | **no such key.** Money is `data.payment.*`; `/actions` returns no money at all | blank amounts everywhere | 2.3 |
| **3** | `FIND_RIDER` pushes `GoodsMultiOrderBookingMain` + a drop-address sheet ([product_self_pickup_msg_card.dart:168-175](../../BlueEra_flutter/lib/features/chat/view/business_chat/widgets/product_self_pickup_msg_card.dart)) | delivery should be settled at **checkout**; dispatch is automatic | a manual button that leaves chat and re-asks for an address the order already has | 5, 7 |
| **4** | captures `wave` / `radiusKm` / `ridersNotified`, renders them only on `goods_multi_broadcast_searching_screen.dart` | `ride:broadcast:searching` every 20s with real numbers | a dead spinner while the server is doing something worth watching | 7.3 |
| **5** | unwraps `{data: …}` and returns the inner map | `warning` is a **sibling** of `data` ([orderActions.controller.js:82-93](../../be_product_service_v2/src/controllers/orderActions.controller.js)) | the amount-mismatch warning never shows | 2.3 |
| **6** | sends `delivery: { latitude, longitude }` (flat) | the rider-order gate reads **only** `delivery.location.coordinates` or `delivery.coordinates`, as **`[lng, lat]`** ([order.controller.js:184-198](../../be_product_service_v2/src/controllers/order.controller.js)) | **every doorstep order is rejected `400 DELIVERY_LOCATION_REQUIRED`** even with a full address | 5.4 |
| **7** | expects to attach the quote later | there is **no** `PATCH /:orderId/delivery-quote` — the comment at `order.controller.js:91` is stale | `distanceKm` / `feeEstimate` / `etaMinutes` must ride **inside `delivery` on create**, or they are lost forever | 5.4 |

Smaller, same family:

- `PUT /:orderId/ready` returns a **bare order** — no `success`, no `data` wrapper.
- `cancellationReasons` are **bare strings**, not `{code,label}` objects.

> **✅ All seven causes are closed**, and both smaller ones parse. Cause 6 is the
> one to smoke-test first: no doorstep order has ever been created successfully
> from the app, so the `[lng, lat]` fix is verified by unit test rather than by a
> live `201`.

### Order of work

```
✅ P0   §2.2  actor            reads `actor`; asks /actions on mount when unknown
✅ P0   §5.4  coordinates      delivery.location.coordinates = [lng, lat]
✅ P0   §2.3  payment.*        data.payment.*, hydrated from /track
✅ P0   §5    checkout stepper five gated steps; the manual ride button is gone
✅ P1   §7.3  live search      radar, rounds, cumulative count, one 60s timer
✅ P1   §3    design system    core/theme/order_design_tokens.dart
✅ P2   §9    edge-case UI     reminders, attention, decision prompt, no-rider
```

---

## 1. The one rule

```
backend  → computes the state machine → emits availableActions[]
Flutter  → renders availableActions[] → sends the action back
```

1. **Never render a button that is not in the list.** Unknown action → render
   nothing. Never guess.
2. **Never build a status string.** `lifecycle.banner` is server-authored and
   already worded. Render it verbatim.
3. **Never decide whose buttons to show from the message sender.** Ask the
   server: `actor`.

---

## 2. The three data planes

Three places order state reaches the app, carrying **different shapes**.
Conflating them is cause #2 above.

### 2.1 Plane A — the chat card (`metadata.lifecycle`), pushed

Written on every lifecycle event ([productOrderLifecycleHandler.js:303-319](../src/utils/productOrderLifecycleHandler.js)),
delivered live on socket `productOrderLifecycle`:

```jsonc
{ "messageId": "…", "orderId": "…", "action": "PRODUCT_ORDER_PAYMENT_VERIFIED",
  "lifecycle": {
    "orderStatus":   "ready",     // placed|accepted|in-progress|ready|dispatched|completed|cancelled|expired
    "sellerStatus":  "ready",     // pending|accepted|preparing|ready|handed_over|rejected|cancelled
    "paymentMethod": "upi",       // cash|upi|gateway
    "paymentState":  "verified",  // pending|submitted|under_review|verified|rejected|expired|refund_pending|refunded
    "customerActions": ["VIEW_PICKUP_CODE","CONTACT_SHOP","RAISE_ISSUE"],
    "ownerActions":    ["CONFIRM_HANDOVER","REPORT_NO_SHOW","CANCEL_ORDER","CONTACT_CUSTOMER"],
    "deadlines":   { "acceptBy": null, "payBy": null, "readyBy": null,
                     "pickupBy": "…", "dispatchBy": null, "deliverBy": null, "hardExpiryAt": "…" },
    "lastEvent": "PRODUCT_ORDER_PAYMENT_VERIFIED", "lastEventAt": "…",
    "banner": "Payment verified by the shop",
    "reasonCode": null, "refundDue": false,
    "seenEvents": ["…"]           // internal dedupe — never read, never render
  }}
```

**The card's primary source. Renders with zero network calls.** Carries **no
money amounts** and **no items** — those live in `metadata.order`, already on the card.

### 2.2 Plane B — `GET <svc>/api/orders/:orderId/actions`

The authoritative "what may I do right now"
([orderActions.controller.js:1169-1190](../../be_product_service_v2/src/controllers/orderActions.controller.js)):

```jsonc
{ "success": true,
  "data": {
    "orderId": "…", "orderNumber": "PROD260826…",
    "actor": "owner",              // ← "customer" | "owner" | "admin". THIS is the role.
    "orderStatus": "ready", "sellerStatus": "ready",
    "paymentMethod": "upi", "paymentState": "verified",
    "deliveryType": "self-pickup", // "self-pickup" | "rider"
    "isTerminal": false,
    "needsAttention": false,       // an admin is already looking at this order
    "deadlines": { … },
    "availableActions": ["CONFIRM_HANDOVER","REPORT_NO_SHOW","CANCEL_ORDER","CONTACT_CUSTOMER"],
    "cancellationReasons": ["ITEM_UNAVAILABLE","SHOP_CLOSED", …]   // bare strings, role-scoped
  }}
```

No `lifecycle`, no `banner`, no `paymentSummary`, no `cancellation`, no
`pickupCode`. Do not look for them.

```dart
final bool isOwner = json['actor'] == 'owner';   // 'admin' → §10.4
```

`availableActions` is **already scoped to the caller** — render it directly. The
`customerActions`/`ownerActions` split exists only on Plane A, where one stored
card serves both readers.

### 2.3 Plane C — the action response

Every verb returns the **whole order** plus the caller's fresh actions:

```jsonc
{ "success": true,
  "data": {
    "_id": "…", "orderNumber": "…", "orderStatus": "accepted",
    "deliveryType": "rider", "grandTotal": 500, "totalItems": 3, "items": [ … ],
    "businessIds": ["…"], "pickupStatus": { "<businessId>": "accepted" },
    "payment": {                       // ← ALL money lives here
      "method": "upi", "state": "submitted",
      "amountDue": 500, "amountPaid": 450,
      "utrNo": "…", "screenshotUrl": "https://…", "upiId": "…", "paymentQrId": "…",
      "submittedAt": "…", "verifiedAt": null, "rejectedAt": null,
      "rejectionReason": null, "submissionCount": 1, "dueBy": "…",
      "refundOwedBy": null, "refundRequestedAt": null,
      "refundInitiatedAt": null, "refundReference": null, "refundedAt": null },
    "delivery": { "addressLine": "…", "distanceKm": 4.2, "feeEstimate": 84, "etaMinutes": 22, … },
    "deadlines": { … },
    "cancellation": { "cancelledBy": "owner", "reasonCode": "…", "comment": "…", "at": "…" },
    "needsAttention": { "flagged": false, "reason": null },
    "availableActions": [ … ] },
  "warning": "The amount you entered (450) does not match the order total (500)."  // ← SIBLING of data
}
```

**Apply directly, never re-fetch.** Two envelope exceptions:

| Endpoint | Envelope |
|---|---|
| `PUT /:orderId/ready` | **bare order** + `availableActions`. No wrapper. |
| `GET /:orderId/pickup-code` | `{ success, data: { orderId, orderNumber, pickupCode } }` |

### 2.4 Which plane answers which question

| The UI needs | Read from |
|---|---|
| Buttons, status line, countdowns on a chat card | **A** `metadata.lifecycle` |
| Buttons after cold start / error / reconnect | **B** `/actions` |
| Amount due, paid, UTR, screenshot, refund ref | **C** `data.payment.*` |
| Items, shop name, order number | the card's `metadata.order` |
| Cancel reasons for the sheet | **B** `cancellationReasons` |
| The pickup code | `GET /pickup-code` only |

---

## 3. Design system — what "modern and professional" means here

Map these roles onto the app's existing theme. Do not introduce a second palette;
introduce **consistency**.

### 3.1 Tokens

| Token | Value | Used for |
|---|---|---|
| `space` | 4 · 8 · 12 · 16 · 24 (8pt grid) | everything. No 7s, no 13s. |
| `radius.card` | 16 | the order card |
| `radius.inner` | 12 | payment block, rider block, code box |
| `radius.pill` | 999 | chips, status dots, buttons |
| `border.hairline` | 1px `onSurface @ 10%` | card edge |
| `elevation` | **0** for cards | flat + hairline reads modern; shadows read 2016 |
| `elevation.sheet` | 8 | bottom sheets and dialogs only |

**Type scale** — four roles, nothing else:

| Role | Size / weight | Used for |
|---|---|---|
| `title` | 16 / w600 | ① order number line |
| `body` | 14 / w400 | ② banner, ④ detail |
| `label` | 12 / w500 | chips, countdowns, footnote |
| `mono` | 20–32 / w700, tabular | pickup code, UTR, ₹ amounts |

`FontFeature.tabularFigures()` on every number that ticks — a countdown that
jitters because `1` is narrower than `8` looks broken even when it is right.

### 3.2 Colour roles (semantic, never literal)

| Role | Meaning | Rule |
|---|---|---|
| `neutral` | waiting on the other party | muted text, no accent |
| `accent` | **waiting on you** | 3dp left border + filled primary button |
| `warning` | money claimed, not confirmed | **amber**, always paired with an icon **and** a word |
| `success` | verified / completed | green **tick inline**, never a full green card |
| `danger` | destructive action only | text button, never a filled red button on a card |
| `muted` | terminal | desaturated surface, reason still fully legible |

**The single most important colour rule:** `paymentState: "submitted"` is amber
and reads *"Customer says they paid"*. Green there is how a shop hands over goods
on a screenshot.

Never encode meaning in colour alone — amber always ships with `⚠` and a word, for
colour-blind users and for glare on a shop counter at noon.

### 3.3 Components to build once

| Component | Spec |
|---|---|
| `StatusDot` | 8dp dot + `body` label. The dot pulses **only** while waiting on the other party. |
| `DeadlineChip` | pill, `label` type, tabular. §8.1 for the rules. |
| `MoneyRow` | left label / right `mono` amount, `space.8`. Amber background when paid ≠ due. |
| `ActionBar` | `Wrap`, `space.8`, max 3 visible + `⋯`. Order: primary → secondary → destructive → icon. |
| `LiveBlock` | the only zone allowed to animate. §7.3. |
| `CardSkeleton` | shimmer of the six zones. Used on cold load — **never** a centred spinner in a chat list. |

### 3.4 Motion budget

| Change | Motion |
|---|---|
| banner text changes | 150ms cross-fade of ② only |
| a button appears / disappears | 200ms size + fade in ⑤ |
| a zone appears (e.g. ③) | 250ms expand |
| **reminder** (`lastEvent` ends `_REMINDER`) | **none.** Text swap only. No jump, no re-order. |
| terminal | 300ms desaturate |

Never animate ① or ④ height on a socket event — the user may be reading them.

### 3.5 Feedback

- Haptic `lightImpact` on a successful action; `heavyImpact` + shake on a
  rejected pickup code.
- Loading = spinner **inside the tapped button**; the rest of the card stays live
  so the other party's events keep landing.
- Minimum tap target 48dp. Buttons never narrower than 88dp.
- Dark mode: derive every role from the theme; no hard-coded `Color(0xFF…)`.

---

## 4. Card anatomy — one widget, six zones

Zones appear and disappear. **Nothing moves.** A card that reorders itself on
every event reads as a glitch.

```
┌─────────────────────────────────────────────┐
│ ① IDENTITY   Order #PROD2608…  ·  3 items   │  never changes
│              ₹500 · Doorstep delivery       │
├─────────────────────────────────────────────┤
│ ② STATUS     ● Payment verified by the shop │  = lifecycle.banner, verbatim
│              ⏱ Collect within 2h 14m        │  = DeadlineChip (§8.1)
├─────────────────────────────────────────────┤
│ ③ LIVE       [ rider search / countdown ]   │  only while something is
│                                             │  actually happening (§7.3)
├─────────────────────────────────────────────┤
│ ④ DETAIL     [role-specific body]           │  payment proof, pickup code,
│                                             │  rider info, refund status
├─────────────────────────────────────────────┤
│ ⑤ ACTIONS    [ Handed over ]  [Didn't come] │  = availableActions, verbatim
│              [Cancel]              📞       │
├─────────────────────────────────────────────┤
│ ⑥ FOOTNOTE   Shop confirmed at 4:32 PM      │  lastEventAt, muted, one line
└─────────────────────────────────────────────┘
```

② is one line of server text plus at most one chip — never two banners.
The card **never collapses because a state is terminal**: a cancelled order that
owes a refund still has buttons (§6.9).

---

## 5. Checkout — where delivery is decided

**This section removes the manual ride button.** The customer chooses pickup or
delivery *before the order exists*, because distance, feasibility, fee, ETA and
rider matching all depend on the address — and the backend **refuses** a doorstep
order without coordinates.

### 5.1 The stepper

One sheet, five steps, one visible at a time, with a progress rail at the top.
Each step is a **gate**: `Continue` is disabled until it is satisfied.

```
①───②───③───④───⑤
Method  Address  Quote  Payment  Review
```

```
┌──────────────────────────────────────────────┐
│  ●───○───○───○───○           Checkout    ✕   │
│                                              │
│  How should you get it?                      │
│                                              │
│  ┌────────────────────┐ ┌──────────────────┐ │
│  │  🏪  Pick it up    │ │  🛵  Deliver to  │ │
│  │  Free · ready in   │ │      me          │ │
│  │  ~20 min           │ │  from ₹40        │ │
│  └────────────────────┘ └──────────────────┘ │
│                                  [Continue]  │
└──────────────────────────────────────────────┘
```

Two large tap cards, not radio buttons. Show the *consequence* of each choice on
the card itself — free vs "from ₹40" — so the decision is informed before it is made.

### 5.2 Step ② — the address gate (delivery only)

**This is the condition you asked for.** Selecting delivery goes straight into the
address step. Nothing else is reachable until there is a real coordinate.

```
┌──────────────────────────────────────────────┐
│  ●───●───○───○───○           Checkout    ✕   │
│                                              │
│  Where should we deliver?                    │
│  ┌──────────────────────────────────────┐    │
│  │        [ map, pin draggable ]        │    │
│  └──────────────────────────────────────┘    │
│  ◉ Home · 12 MG Road, 560001                 │
│  ○ Work · 4 Residency Rd, 560025             │
│  ○ Use my current location        ⌖          │
│  ○ Add a new address              +          │
│                                              │
│  Receiver   Bhupinder      9876543210   ✎    │
│  Note to the rider (optional)                │
│                                  [Continue]  │
└──────────────────────────────────────────────┘
```

**Rules**

- If the user has **no saved address**, open the picker immediately. Never show
  an empty state with an "Add address" button — that is one dead tap.
- `Continue` stays disabled until **latitude and longitude both exist**. Text
  alone is not an address here; the backend and the rider search need the point.
- The pin is draggable and the address text updates from it. Reverse-geocoding is
  a convenience; **the pin is the truth.**
- Receiver name and phone default from the profile and are editable — "send it to
  my mother" is a real, common case, and it is a `delivery.contactName` /
  `contactNo` the shop and the rider both see.
- Going **back** to step ① and choosing pickup clears nothing — coming forward
  again must restore the address.

### 5.3 Step ③ — the quote, automatic

The moment a coordinate exists, fire the quote. Debounce 400ms; refire on any
pin move.

```
GET rider-service/fare/chat-dispatch/quote
    ?shopLat&shopLng&dropLat&dropLng&distance_in_km&orderValue
```

```jsonc
{ "feasible": true, "distanceKm": 4.2, "deliveryFee": 84, "riderPayout": 84,
  "etaMinutes": 22, "etaRange": { "min": 17, "max": 32 }, "peak": false,
  "breakdown": { "baseFee": …, "baseKm": …, "chargeableKm": …, "perKmFee": …,
                 "peakMultiplier": 1, "minimumFeeApplied": false, "maximumFeeApplied": false },
  "economics": { "orderValue": 10, "feeToOrderRatio": 8.4,
                 "feeExceedsOrderValue": true, "feeIsHighVsOrder": false, "suggestion": "…" } }
```

```
│  Delivery                                    │
│  ₹84 · 17–32 min · 4.2 km                    │
│  How is this calculated?                 ⌄   │   ← discloses `breakdown`
│                                              │
│  ⚠ Delivery costs more than your order.      │
│    Picking it up is cheaper.                 │
│    [ Pick it up instead ]                    │
```

- **`feasible: false` is a `200`**, with `reason: "OUTSIDE_DELIVERY_RADIUS"`,
  `message`, `maxDistanceKm`. Do not toast an error: disable delivery, show
  `message`, and slide back to step ① with pickup selected and explained.
- **A missing `feasible` means feasible.** Never disable delivery on an absent key.
- `economics.feeExceedsOrderValue` → amber note with `suggestion` + a
  **"Pick it up instead"** shortcut. **Never block.** A customer may pay ₹84 to
  have a ₹10 item delivered — they must only not be *surprised*.
- The `breakdown` disclosure kills the "why is delivery so expensive" support
  ticket before it is written.
- While the quote is in flight, **skeleton the fee row** — do not show ₹0 and
  correct it a moment later.

### 5.4 Step ⑤ — place the order, correctly

```dart
final body = {
  'items': items,
  'deliveryType': isPickup ? 'self-pickup' : 'rider',
  'discount': discount,
  'paymentMethod': method,                 // 'cash' | 'upi'
  'idempotencyKey': _checkoutAttemptId,    // one UUID per checkout ATTEMPT
  if (!isPickup) 'delivery': {
    'addressLine': a.line, 'landmark': a.landmark, 'city': a.city, 'pincode': a.pincode,

    // ⚠ REQUIRED SHAPE. The rider-order gate reads ONLY these two forms,
    // as [longitude, latitude] — LNG FIRST. Flat latitude/longitude alone
    // fails with 400 DELIVERY_LOCATION_REQUIRED. (order.controller.js:184-198)
    'location': { 'type': 'Point', 'coordinates': [a.lng, a.lat] },

    'contactName': a.name, 'contactNo': a.phone, 'instructions': notes,

    // ⚠ There is NO endpoint to attach the quote later. Send it here or lose it.
    'distanceKm':  quote?.distanceKm,
    'feeEstimate': quote?.deliveryFee,
    'etaMinutes':  quote?.etaMinutes,
  },
};
```

**Idempotency.** One UUID v4 generated when the sheet **opens**, not per tap;
cleared once an order comes back. **`201` = created, `200` = you already created
this one — treat both as success.** The multi-store carts place one order per
store and need **one key per store**; a response lost halfway through that loop is
the real duplicate-order hazard.

| Code | HTTP | UI |
|---|---|---|
| `DELIVERY_LOCATION_REQUIRED` | 400 | jump back to step ②, focus the map. Should be unreachable once the gate is right. |
| — | 400 `"Invalid deliveryType"` | ship-blocker; log it |
| — | 400 `"Order must contain at least one item."` | close, return to cart |

### 5.5 After checkout, delivery is automatic

For `deliveryType: "rider"` the customer has already decided, already paid the
delivery fee's price of admission, and already given the address. **There is no
further delivery button anywhere.** When the card reaches `ready` with no ride
attached, the app dispatches (§7.2) and ③ turns into the live search.

The only remaining `FIND_RIDER` case is a **self-pickup** order the customer
changes their mind about. The backend still offers it at `ready`
([orderStateMachine.js:393-395](../../be_product_service_v2/src/utils/orderStateMachine.js)). Render it as a
**low-emphasis text link** under the pickup code — *"Can't come? Get it
delivered"* — and run the exact same in-card flow (§7.2). Never a primary button,
never a navigation away from chat.

---

## 6. A to Z — every state, both roles

**C** = customer's device, **S** = shop's device. Button lists are what
`availableActionsFor()` really returns
([orderStateMachine.js:330-448](../../be_product_service_v2/src/utils/orderStateMachine.js)).

### 6.1 `placed` — waiting for the shop

```
C ┌────────────────────────────────────┐   S ┌────────────────────────────────────┐
  │ Order #PROD…  · 3 items · ₹500     │     │ NEW ORDER · 3 items · ₹500        │
  │ ● Waiting for the shop to confirm  │     │ ● Confirm within 18m              │
  │ ⏱ 18m 04s left                     │     │ ⏱ 18m 04s  ▓▓▓▓▓▓▓▓░░  (pulses)   │
  │                                    │     │ [item list, quantities]           │
  │ [Cancel order]              📞     │     │ [ Accept ]  [Can't take it]   📞  │
  └────────────────────────────────────┘     └────────────────────────────────────┘
```

- **C**: `CANCEL_ORDER`, `CONTACT_SHOP`, `RAISE_ISSUE`
- **S**: `ACCEPT_ORDER`, `REJECT_ORDER`, `CONTACT_CUSTOMER`
- Countdown from `deadlines.acceptBy` — **20 minutes**. Shop nudged at **5** and **10**.
- **No pay button here, ever**, even for UPI — the backend will not return
  `SUBMIT_PAYMENT` before `accepted`. Money is only requested after a shop commits.
- At zero: *"Confirming…"* + one `/actions` call. **Do not render cancelled
  yourself** — the sweeper ticks every 60s and sends the real card.

**Accept sheet (S):** ETA chips 10 / 15 / 20 / 30 / 45 + "Skip", defaulted from the
vertical (perishable 20, grocery 30, general 45). One tap must be enough.

### 6.2 `accepted`

```
C  ● Order accepted — ready in about 20 min       S  ● Preparing
   ⏱ Ready by 5:02 PM                                ⏱ Ready by 5:02 PM
   ── cash ──                                        [ Order packed ]
   [Cancel order]                 📞                 [Update time] [Cancel]  📞
   ── upi ──
   ₹500 due    [ Pay now ]  [Cancel order]  📞
```

- **C**: `CONTACT_SHOP`, `RAISE_ISSUE`, `CANCEL_ORDER`, +`SUBMIT_PAYMENT` if UPI
- **S**: `CONTACT_CUSTOMER`, `SET_PREP_ETA`, `MARK_READY`, `CANCEL_ORDER`
- `deadlines.payBy` (UPI) = **30 min**. `readyBy` = accept window + prep + 15m grace.
- `CANCEL_ORDER` **disappears for the customer** at `in-progress` — deliberate, the
  shop has started spending money. Show a "Call the shop" affordance, not a dead button.

### 6.3 The payment sub-flow (UPI) — five distinct screens

```
pending      C: [ Pay now ]                      S: (no payment block yet)
   │ POST /payment/submit
   ▼
submitted    C: amber, no buttons                S: AMBER card ↓ [Payment received] [Not received]
             "Waiting for the shop to
              confirm your payment"
   │                        ╲ reject
   ▼ verify                  ▼
verified     C: ✓ verified            rejected  C: "Payment not confirmed: <reason>" + [Pay now]
             S: [Order packed]                   S: back to waiting

expired      C: "Payment window closed" + [Pay now]     (expired → submitted is legal)
```

**The shop's verification card — the whole safety model in one block:**

```
┌──────────────────────────────────────────┐
│ ⚠ Customer says they paid                │
│ ┌────────┐  Paid    ₹450  ← amber if ≠   │
│ │ [shot] │  Due     ₹500                 │
│ │  tap   │  UTR  4429XXXX9921    [copy]  │
│ │  zoom  │  2 minutes ago                │
│ └────────┘                               │
│  Check your bank app before confirming.  │
│ [ Payment received ]   [ Not received ]  │
└──────────────────────────────────────────┘
```

Every field from `data.payment.*`. Amber when `amountPaid != amountDue` (backend
tolerates ±₹1).

**Customer's pay sheet:** QR + UPI id + the exact `amountDue`, then UTR (required)
· amount paid (pre-filled, editable) · screenshot (required).

| Code | HTTP | UI |
|---|---|---|
| `UTR_REQUIRED` / `SCREENSHOT_REQUIRED` / `INVALID_AMOUNT` | 400 | inline, sheet stays open |
| `UTR_ALREADY_USED` | 409 | red under the UTR field. Sheet stays open. |
| `TOO_MANY_PAYMENT_ATTEMPTS` | 429 | close, *"Please contact the shop."* + call. Cap is **5**. |
| `ACTION_NOT_AVAILABLE` | 409 | close, refresh, neutral toast |
| 200 **with `warning`** | — | close, amber note. Read `warning` from the **response root**. |

Shop nudged at **10** and **30** min; admin-flagged at **60** (§9.3). The
customer's card never says "escalated".

### 6.4 `in-progress`

As 6.2 minus the customer's cancel. Past `readyBy`, both sides get
`order_preparation_overdue`: the banner changes and the chip flips to **overdue**
styling — amber, counting **up** ("12m over"). Nobody is cancelled for being slow.

### 6.5 `ready` — self-pickup

```
C ┌────────────────────────────────────┐   S ┌────────────────────────────────────┐
  │ ● Your order is ready for pickup   │     │ ● Ready — waiting for the customer │
  │ ⏱ Collect within 2h 58m            │     │                                    │
  │ ┌──────────────────────────────┐   │     │ Ask the customer for their         │
  │ │      K 7 Q P 4 M             │   │     │ 6-character pickup code.           │
  │ │   show this at the counter   │   │     │                                    │
  │ └──────────────────────────────┘   │     │ [ Handed over ]                    │
  │ 12 MG Road · [Directions]          │     │ [Customer didn't come] [Cancel] 📞 │
  │ Can't come? Get it delivered   →   │     │                                    │
  └────────────────────────────────────┘     └────────────────────────────────────┘
```

- **C**: `VIEW_PICKUP_CODE`, `CONTACT_SHOP`, `RAISE_ISSUE`, +`FIND_RIDER` (text link, §5.5)
- **S**: `CONFIRM_HANDOVER` (**UPI: only when `paymentState == "verified"`**),
  `REPORT_NO_SHOW`, `CANCEL_ORDER`, `CONTACT_CUSTOMER`
- `deadlines.pickupBy` = **180 min**. Customer reminded at **30** and **90**. At
  180 the shop gets a decision prompt (§9.2). Hard expiry **24h**.

**Pickup code (C):** full screen, `mono` 32, max contrast, `Wakelock.enable()`.
`GET /pickup-code` → `data.pickupCode`. It 409s before ready and 403s for anyone
else — never cache it into the card.

**Handover dialog (S):** 6 chars, auto-uppercase, auto-submit at 6, monospace.

| Code | UI |
|---|---|
| `PICKUP_CODE_REQUIRED` 400 | inline |
| `PICKUP_CODE_MISMATCH` 403 | shake + heavy haptic, clear, stay open, unlimited retries |
| `CASH_NOT_COLLECTED` 409 | inline — only if you send `collectedCash: false` |
| `ACTION_NOT_AVAILABLE` 409 | close, *"Confirm the payment first."* |

**Cash:** a pre-checked *"I have collected ₹500 in cash"* in the same dialog, sent
as `collectedCash`. One tap records goods leaving **and** money arriving — a busy
shop will not do two.

### 6.6 `ready` — delivery → §7

### 6.7 `dispatched`

Customer only: *"Picked up — on the way to you"*, rider name/photo/vehicle, live
tracking entry, delivery OTP card. The shop's card collapses to a summary.
`deadlines.deliverBy` = **90 min**; past it both sides get a neutral attention
strip and an admin is notified.

### 6.8 `completed`

Green tick in ②, card collapses to a summary row both sides. Customer keeps
**Rate the shop** and `RAISE_ISSUE`. Everything else gone.

### 6.9 `cancelled` / `expired` — and the refund that outlives them

Grey card, **reason always visible** (`banner` already carries it in plain
language). If verified non-cash money was held, `paymentState` becomes
`refund_pending` and **the card keeps buttons**:

| `paymentState` | `payment.refundInitiatedAt` | C sees | S sees |
|---|---|---|---|
| `refund_pending` | null | *"₹500 is to be returned by **the shop**. We've asked them to send it."* + Report a problem | **[I sent the refund]** + 📞 |
| `refund_pending` | set | *"The shop says they've sent ₹500 (ref UTR…). Confirm when it reaches you."* + **[I received the refund]** | *"Waiting for the customer to confirm"* + 📞 |
| `refunded` | — | *"Refund received ✓"* | *"Refund settled ✓"* |

**Two wording rules, both tested for:**

1. Never *"we will refund you"* or *"refund processed"*. The customer paid the
   **shop's own VPA**; the platform never held the money and cannot move it.
   *"the shop will return it"* → *"the shop says they've sent it"* → *"received"*.
2. **The shop's "I sent it" does not close the refund.** It is a claim, exactly as
   the screenshot was. Only `CONFIRM_REFUND_RECEIVED` (or an admin close-out) ends
   it. **Do not grey the card at that step.**

Refund dialog (S): amount read-only from `payment.amountPaid`, return-transfer UTR
required (`REFUND_REFERENCE_REQUIRED` → inline).

---

## 7. The delivery leg — automatic, and visible

### 7.1 What the backend really does

`POST rider-service/fare/chat-dispatch/orders` with **`orderType: "broadcast"`**
starts a Rapido-style race ([broadcastDispatch.service.js](../../be_rider_service/src/services/broadcastDispatch.service.js)):

```
round 1   3 km   → up to 15 eligible partners rung at once   ─┐
          20s                                                 │
round 2   6 km   → any NEW eligible partners rung             │  60s total
          20s                                                 │
round 3  10 km   → any NEW eligible partners rung            ─┘
          20s
          ↓ nobody accepted
      ride:broadcast:exhausted
```

Filtered by: in radius · registered · vehicle type · preference · not busy · not
already asked · **economically viable** (a partner 8 km away for a 1 km job is
skipped, not underpaid). First accept wins by atomic compare-and-set; every other
popup is dismissed instantly.

**Send `orderType: "broadcast"` with no `selectedRiders`.** The default,
`"standard"`, *requires* a hand-picked list — that is the manual flow the card is
still using.

### 7.2 The trigger — no button

| Order | Trigger |
|---|---|
| `deliveryType: "rider"` | **automatic.** Card reaches `ready` and `rideOrderId` is empty → dispatch immediately. ③ appears. No button, no second decision. |
| `deliveryType: "self-pickup"` | only if the customer taps the *"Can't come? Get it delivered"* text link (§5.5) → quote sheet → dispatch. Still in-card. |

Both use the order's stored `delivery` coordinates. **Never re-ask for an address
the order already has.**

> **Why the app is the trigger, and that is correct.** Nothing server-side
> dispatches on `PRODUCT_ORDER_READY`: `markOrderReady` sets
> `deadlines.dispatchBy` (25 min) and lets the sweeper escalate if no rider ever
> collects ([order.controller.js:868-888](../../be_product_service_v2/src/controllers/order.controller.js)).
> So the app fires the dispatch the moment the card turns `ready`. It is one
> call, the 3-minute guard answers `429` on a duplicate, and the 25-minute
> sweeper is the safety net if the app never manages it. No backend change.

### 7.3 The live search — full visibility

This is the screen you asked for. Socket `ride:broadcast:searching` arrives on the
**chat socket** every ~20 s:

```jsonc
{ "orderId": "ORD-1756…", "wave": 2, "totalWaves": 3,
  "radiusKm": 6, "ridersNotified": 7 }
```

```
┌──────────────────────────────────────────────┐
│  ● Finding a delivery partner                │
│                                              │
│              (( ( ◉ ) ))                     │   radar, ring expands with
│               within 6 km                    │   radiusKm: 3 → 6 → 10
│                                              │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░  round 2 of 3       │
│                                              │
│  👤👤👤👤👤 +12    17 partners called         │
│                                              │
│  ✓ round 1 · 3 km  — 9 called                │   live timeline, one row
│  ◐ round 2 · 6 km  — 8 more called           │   per round, appended as
│  ○ round 3 · 10 km — up next                 │   each event lands
│                                              │
│  ⏱ 38s                    ₹84 · 17–32 min    │
│                        [ Cancel search ]     │
└──────────────────────────────────────────────┘
```

**Element by element — every value below is already on the wire**

| Element | Source | Behaviour |
|---|---|---|
| Radar ring | `radiusKm` | one ring, radius eased over 600ms on change. Two pulses per 20s round — a constant strobe is noise. |
| "within N km" | `radiusKm` | animate the number; never re-layout the row |
| Progress bar | `wave` / `totalWaves` | eases **within** a round over 20s, jumps at the boundary. **Never indeterminate** — you know exactly how long this takes. |
| "round 2 of 3" | `wave`, `totalWaves` | say "round", not "wave" — it is a customer-facing word |
| Avatar stack | count only | 5 max + `+N`. Faceless silhouettes are fine; this is progress, not a roster. Fade one in per notification. |
| **N partners called** | Σ `ridersNotified` across rounds | **cumulative — sum it.** A single round's value is not the total. |
| **The round timeline** | one row per `searching` event | ✓ done · ◐ current · ○ up next. Rows are **appended, never rewritten** — this is the detail that makes the block read as live rather than as a placeholder. |
| Countdown | 60 s total from dispatch | **one shared timer**, does not restart per round |
| Fee · ETA | the quote already shown | pinned — the number the customer agreed to |
| Cancel search | — | always available, always the lowest-emphasis control here |

**`ridersNotified: 0` is a real and common answer.** Never render "0 partners
called" three times. Render *"No partners nearby yet — widening the search"* and
keep the bar moving. Silence reads as a hang.

**Never show `ride:broadcast:closed` to the customer** — that goes to the *losing*
partners to dismiss their popups. Customer-facing terminals are
`ride:broadcast:accepted` and `ride:broadcast:exhausted` only.

Keep the existing 3 s status poll as the safety net. Socket first, poll to
converge; if the poll wins, the UI must land in the identical state.

### 7.4 The counting model — build it from what arrives

The backend is fixed. Everything the block needs comes from the four fields on
`ride:broadcast:searching`, plus your own dispatch timestamp. Hold one small
object per search and append to it:

```dart
class BroadcastSearch {
  final DateTime startedAt;            // when POST /chat-dispatch/orders returned 201
  final rounds = <RoundRow>[];         // one per `searching` event, APPEND ONLY
  int get calledTotal => rounds.fold(0, (n, r) => n + r.notified);
  int  currentRound = 0, totalRounds = 3;
  double radiusKm = 0;
  Duration get remaining =>
      const Duration(seconds: 60) - DateTime.now().difference(startedAt);
}
// on ride:broadcast:searching
rounds.add(RoundRow(index: d['wave'], radiusKm: d['radiusKm'], notified: d['ridersNotified']));
```

That yields, all real: round N of M · current radius · partners called per round ·
partners called in total · seconds left · the finished/current/upcoming timeline.

**Two honesty rules — the block must never overstate what it knows.**

1. **Do not invent a denominator.** "17 of 23" is not derivable, so do not print
   an "of N". `17 partners called` is a complete, true sentence. A fake total is
   worse than no total, because the customer counts down against it.
2. **`ridersNotified: 0` is a normal answer**, and it will happen. Never print
   "0 partners called". That round's row reads *"round 1 · 3 km — none nearby"*
   and the headline reads *"Widening the search…"*. Silence reads as a hang; an
   honest "none nearby yet, looking further" reads as work.

The round timeline is what makes this feel detailed. Three rows appearing one at
a time, each with a real radius and a real count, tells the customer more than any
percentage would — and every character of it is server truth.

### 7.5 Partner found

```
● Delivery partner assigned
[photo] Ramesh K. · KA-01-AB-1234 · ★4.8
        Arriving at the shop in ~6 min
[Track] [Call]        pickup OTP shown to the SHOP
```

Cards already exist: `rider_details_msg_card.dart`, `rider_otp_msg_card.dart`,
`rider_live_location_msg_card.dart`, `track_rider_live_location_page.dart`.
New OTP cards arrive on `newRiderOtpReceived`; status flips on `riderOtpUpdated`
([riderOtpHandler.js:92,179,284](../src/utils/riderOtpHandler.js)).

### 7.6 No partner found — the honest dead end

`ride:broadcast:exhausted`, and separately `PRODUCT_ORDER_NO_RIDER` from the order
service 25 minutes after packing:

```
┌─────────────────────────────────────────────┐
│ ● No delivery partner found                 │
│ Your order is packed and waiting at the     │
│ shop. You can collect it, or try again.     │
│ [ Try again ]  [ Collect it myself ]        │
│ [Cancel order]                       📞     │
└─────────────────────────────────────────────┘
```

**This is not a cancellation and must not look like one.** The goods exist. The
backend deliberately keeps the order alive and sends
`suggestion: "SELF_PICKUP_FALLBACK"` with `customerActions: ["CANCEL_ORDER","CONTACT_SHOP"]`.
The shop's card carries the same message plus *"Goods are packed and no rider
came. Call the customer."*

### 7.7 Dispatch errors

| Code | HTTP | UI |
|---|---|---|
| `FARE_MISMATCH` | 409 | carries `quotedFare` + a fresh `quote`. Dialog: *"The delivery charge is now ₹96."* **Confirm** / **Cancel**. Re-submit **once**, never silently. |
| `OUTSIDE_DELIVERY_RADIUS` | 422 | *"We can't deliver to this address."* → offer self-pickup |
| — | 429 | *"You already requested delivery for this order recently."* (3-minute guard) |

---

## 8. Making it feel alive

### 8.1 Countdown chips

One widget, fed **only** from `deadlines.*`. Never `createdAt + constant`.

| Condition | Render |
|---|---|
| `deadline == null` | **nothing.** Null means "no clock for this step" — not expired. |
| > 1h | `2h 14m`, muted |
| 10–60m | `18m`, normal |
| < 10m | `4m 12s`, accent, ticks every second, tabular figures |
| < 0 | *"12m over"*, amber. **Never flip the card to terminal yourself.** |
| hits 0 | *"Checking…"* + one `/actions`, then render what comes back |

One `Timer.periodic(1s)` per **screen**, not per card. Parse with
`DateTime.tryParse(...)?.toLocal()`.

### 8.2 Optimistic updates: don't

Every action can legitimately 409. Wait, then apply the returned
`availableActions`. An Accept button that vanishes and comes back is worse than a
spinner.

### 8.3 Reconnect and foreground

On socket reconnect **and** `AppLifecycleState.resumed`, refresh `/actions` for
every card on screen — **including terminal ones**, because a cancelled order that
owes a refund is not finished business.

**Do not poll on a timer.** Two justified exceptions: rider live-location during
an active delivery, and the 3 s broadcast poll while a search is running (it stops
on accept/exhaust).

---

## 9. Edge-case catalogue

All reachable with nobody touching a phone — the sweeper ticks every **60 s**.

### 9.1 Reminders

`lastEvent` ends `_REMINDER` → **not a state change.** Banner only. No motion, no
push-to-top, no badge, no ④ rebuild.

| Template | Audience | When |
|---|---|---|
| `order_awaiting_acceptance` | shop | 5, 10 min after placed |
| `payment_awaiting_verification` | shop | 10, 30 min after submit |
| `order_preparation_overdue` | both | past `readyBy` |
| `order_ready_reminder` | customer | 30, 90 min after ready |
| `order_pickup_owner_action_required` | shop | 180 min after ready |

Hard cap **6 reminders per order, ever**.

### 9.2 The decision prompt

At `pickup:owner-action` the shop's card changes **shape**, not just text:

```
┌─────────────────────────────────────────────┐
│ ● This order has been ready for 3 hours.    │
│   What happened?                            │
│ [ Handed over ] [ Customer didn't come ]    │
│ [ Cancel order ]                      📞    │
└─────────────────────────────────────────────┘
```

Three buttons, no default, no dismiss.

### 9.3 `needsAttention`

`/actions.needsAttention == true` or `lastEvent == "PRODUCT_ORDER_NEEDS_ATTENTION"`:

```
ℹ We're looking into this order.
```

Neutral, on **both** cards. **Never expose the reason code** (`PAYMENT_REVIEW`,
`CUSTOMER_NO_SHOW`, `NO_RIDER`, `DISPUTED`, …) — it is an ops taxonomy and half
the values accuse someone.

### 9.4 The full catalogue

| Situation | Backend does | UI must show |
|---|---|---|
| Shop never opens the app | nudge 5/10; auto-cancel at 20, `OWNER_DID_NOT_RESPOND` | C: cancelled card, plain reason, **[Order again]**. Never "your order failed". |
| UPI chosen, never paid | `paymentState → expired` at 30 min; **order stays alive** | C: *"Payment window closed"* + **[Pay now]**. S: banner + `[Cancel] [Call]`. Do not grey. |
| Shop sits on a payment | nudge 10/30, admin flag at 60 | C: *"Waiting for the shop to confirm your payment"* throughout, then §9.3. Never an hour-long spinner. |
| Both shop devices tap Accept | one wins, other gets `CONCURRENT_MODIFICATION` | loser: silent refresh, **no error toast**. The order *is* accepted. |
| Customer cancels while shop accepts | loser gets a typed 409 | *"This order has changed. Please check the updated details."* + refresh |
| Handover on unverified UPI | button absent; forced call 409s | *"Confirm the payment first."* |
| Wrong pickup code | `PICKUP_CODE_MISMATCH` | shake, stay open, unlimited retries |
| Prep runs late | reminder to both | chip flips to "12m over" amber. **No cancel button appears.** |
| Ready, nobody comes | 30/90 nudges, decision at 180, hard expiry 24h | §9.2, then: unpaid → cancelled with reason; **paid → §9.3, never auto-cancelled** |
| Packed for delivery, no partner in 25 min | `PRODUCT_ORDER_NO_RIDER`, attention flag, order alive | §7.6 — "collect it yourself", not a failure card |
| Partner takes it, goes dark 90 min | `DELIVERY_FAILED` flag | both: §9.3 + [Call partner] / [Call support] |
| Cancelled with verified UPI money | `refund_pending` + ops queue | §6.9 — buttons on a terminal card |
| Shop says it refunded | `refundInitiatedAt` set, still `refund_pending` | C: **[I received the refund]**. Card stays open. |
| One shop of two rejects | rolls up on the surviving shop | *"1 of 2 shops couldn't take their items"* — never a whole-order failure |
| Kill the app mid-payment | state is in Mongo | `/actions` on resume → identical screen, **no ghost spinner** |
| Response lost after Place order, retry | `idempotencyKey` → same order, `200` | **200 and 201 both success**; clear the key on either |
| Unknown action from a newer backend | — | render **nothing** for it |

---

## 10. Errors, loading, empty, offline

### 10.1 Branch on `code`, never on message text

```dart
switch (err.code) {
  case 'ACTION_NOT_AVAILABLE':
  case 'CONCURRENT_MODIFICATION':
  case 'PAYMENT_CONFLICT':
  case 'INVALID_SELLER_TRANSITION':
  case 'INVALID_PAYMENT_TRANSITION':
    await refreshActions(orderId);
    toast('This order has changed. Please check the updated details.');
    break;
  case 'ORDER_TERMINAL':        await refreshActions(orderId); break;   // silent
  case 'NOT_A_PARTY_TO_ORDER':
  case 'NOT_ORDER_CUSTOMER':    toast('You no longer have access to this order.'); break;
  case 'ORDER_NOT_FOUND':
  case 'INVALID_ORDER_ID':      toast('This order could not be found.'); break;
  case 'DELIVERY_LOCATION_REQUIRED': _jumpToAddressStep(); break;
  case 'USE_LIFECYCLE_ENDPOINT':
  case 'USE_HANDOVER_ENDPOINT':  toast('Please update the app to continue.'); break;
  // field-level: NO TOAST — the sheet renders them inline
  case 'UTR_REQUIRED': case 'SCREENSHOT_REQUIRED': case 'INVALID_AMOUNT':
  case 'PICKUP_CODE_REQUIRED': case 'PICKUP_CODE_MISMATCH':
  case 'REFUND_REFERENCE_REQUIRED': case 'REASON_REQUIRED':
  case 'INVALID_REASON': case 'INVALID_PREP_ETA': case 'CASH_NOT_COLLECTED':
    break;
  default: toast(err.message ?? 'Something went wrong. Please try again.');
}
```

`ACTION_NOT_AVAILABLE` is **normal** — the other party moved first. Refresh cue,
never a red banner. Read the code from `code`, `errorCode`, `error_code` or
`error.code`; this service always sends `code` at the top level.

### 10.2 Loading

Per-action `RxBool`; spinner inside the tapped button. Cold card load = the
skeleton (§3.3), never a centred spinner in a chat list.

### 10.3 Offline

Synthesise `NETWORK_ERROR` → **Retry** chip on the card, not a dialog. Retrying is
safe: every action is a server-side compare-and-set, so a retry after an unknown
outcome cannot double-apply. Cards render from `metadata.lifecycle`, which is
already local — **an offline user still sees the last known state**; disable the
buttons and show one "You're offline" strip.

### 10.4 `actor: "admin"`

Gets `["ADMIN_OVERRIDE","CONTACT_SHOP","CONTACT_CUSTOMER"]`. Consumer builds
render read-only + call buttons, never `ADMIN_OVERRIDE` UI.

---

## 11. Files to change — ✅ all done

Status of every row, with anything that landed somewhere other than the row
suggested called out. Full detail in `ORDER_FLOW_V3_FRONTEND_DONE.md` §1–§3.

| File | Change | Status |
|---|---|---|
| `chat/auth/model/order_lifecycle_model.dart` | **P0** parse `actor`; drop `paymentSummary` → `data.payment.*`; read `warning` from the root; accept the bare-order envelope from `PUT /ready` | ✅ rewritten |
| `me/product/model/order_checkout_payload.dart` | **P0** emit `delivery.location.coordinates = [lng, lat]`; keep `distanceKm`/`feeEstimate`/`etaMinutes` in the create body | ✅ + `hasCoordinates` is the checkout gate |
| `me/product/view/customer/…_cart_screen.dart` + the 6 sibling controllers | **P0** the five-step sheet (§5); address gate; auto-quote | ✅ new `order_checkout_stepper_sheet.dart`; siblings pass `allowDelivery:false` until their services take doorstep orders |
| `chat/view/business_chat/widgets/product_self_pickup_msg_card.dart` | **P0** delete `_findRiderFromCard`'s navigation; auto-dispatch on ready for `rider` orders; `FIND_RIDER` → in-card text link | ✅ auto-dispatch lives in `order_broadcast_controller.dart`, triggered from the section |
| `…/self_pickup_msg_card.dart`, `…/food_self_pickup_msg_card.dart` | same | ✅ |
| `…/order_broadcast_search_section.dart` | **new** — the live search block (§7.3) | ✅ |
| `…/order_lifecycle_section.dart` | the six zones; add ③ | ✅ rewritten |
| `…/order_deadline_countdown.dart` | null / overdue / hits-zero rules (§8.1) | ✅ + one app-wide `OrderClock` ticker |
| `…/order_action_bar.dart` | cap 3 + overflow; unknown → nothing (already correct) | ✅ + priority ranking; call icons exempt from the cap |
| `…/order_payment_submit_sheet.dart` | amount from `payment.amountDue`; inline error codes | ✅ + hydrates from `/track` |
| `…/payment_transaction_msg_card.dart` | paid-vs-due side by side, amber on mismatch | ✅ already correct |
| `chat/auth/controller/chat_view_controller.dart` | `productOrderLifecycle` → patch in place; action lists **replace, never merge** | ✅ already correct; verified by test |
| `common/Discover/controller/discover_controller.dart` | reuse the broadcast listeners for chat-dispatch order ids — today they only serve the multi-shop screen | ✅ fans out **before** the fare-call staleness filter |
| `core/api/apiService/rider_service_api.dart` | dispatch body carries `orderType: "broadcast"`, **no** `selectedRiders` | ✅ in both dispatch paths |
| `core/theme/…` | the tokens in §3.1–3.2 | ✅ `core/theme/order_design_tokens.dart` |

---

## 12. Acceptance checklist — visual, not just functional

> **How to read the boxes.** `[x]` = built **and** guarded by a unit or widget
> test. `[~]` = built, but it needs a device, a live server or two accounts to
> confirm — those are listed again in `ORDER_FLOW_V3_FRONTEND_DONE.md` §7.

**Checkout**

- [x] Choosing "Deliver to me" goes straight into the address step
- [x] `Continue` is disabled until a pin exists; a typed address alone will not pass
- [x] No saved address → the picker opens immediately, no empty state
- [x] The fee row skeletons while the quote is in flight; never shows ₹0 first
- [x] A 15 km address disables delivery **with a reason** and pre-selects pickup
- [x] A ₹10 order at 8 km shows the amber note and still lets the order through
- [~] A doorstep order actually gets created (not `DELIVERY_LOCATION_REQUIRED`)

**Role and dynamism**

- [~] Same order, two devices: customer `[Pay now] [Cancel]`, shop
      `[Order packed] [Update time] [Cancel]`. **Never the same set.**
- [~] Shop marks ready → the customer's card changes with no refresh
- [x] No button anywhere is built from an `if (status == …)` in Dart

**Live**

- [x] A doorstep order reaching ready starts the search **with no button tapped**
- [x] The search shows a moving bar, a radius that goes 3 → 6 → 10, and a count that grows
- [x] `ridersNotified: 0` reads "widening the search", not "0 partners"
- [x] The countdown is one 60 s timer, not three restarting ones
- [x] Countdown ticks every second under 10 minutes and says "12m over" past zero
- [x] A reminder changes the banner and moves nothing

**Money**

- [x] Pay sheet shows the real ₹ amount
- [x] Shop's verify card shows ₹450 vs ₹500 side by side, amber
- [x] A submitted payment is never labelled "Paid"
- [x] The amount-mismatch `warning` appears

**Edges**

- [~] Two devices tap Accept: one succeeds, the other refreshes silently
- [x] Wrong pickup code shakes and stays open
- [x] No partner found → "collect it yourself", **not** a cancelled card
- [x] Cancel a paid UPI order → the card says **the shop** returns the money
- [x] Shop taps "I sent the refund" → card stays open, customer gets a confirm button
- [x] A cancelled order still shows refund buttons
- [~] Kill mid-payment, reopen → same state, no ghost spinner
- [x] Airplane mode → last known card, buttons disabled, one offline strip

---

## 13. Reference

### Endpoints — base `product-service`, `Authorization: Bearer <jwt>`

| Method | Path | Role | Body |
|---|---|---|---|
| `POST` | `/api/orders` | customer | `items`, `deliveryType`, `discount`, `delivery`, `paymentMethod`, `idempotencyKey` |
| `GET` | `/api/orders/:orderId/actions` | any party | — |
| `POST` | `/api/orders/:orderId/accept` | BUSINESS | `{ prepEtaMinutes? }` |
| `POST` | `/api/orders/:orderId/reject` | BUSINESS | `{ reasonCode, comment? }` |
| `POST` | `/api/orders/:orderId/prep-eta` | BUSINESS | `{ prepEtaMinutes }` |
| `PUT` | `/api/orders/:orderId/ready` | BUSINESS | — · **bare-order response** |
| `POST` | `/api/orders/:orderId/payment/submit` | customer | `{ utrNo, amountPaid, screenshotUrl, paymentQrId?, upiId?, transactionRef? }` |
| `POST` | `/api/orders/:orderId/payment/verify` | BUSINESS/ADMIN | `{ amountReceived?, note? }` |
| `POST` | `/api/orders/:orderId/payment/reject` | BUSINESS/ADMIN | `{ reason }` |
| `GET` | `/api/orders/:orderId/pickup-code` | customer | — |
| `POST` | `/api/orders/:orderId/handover` | BUSINESS | `{ pickupCode, collectedCash? }` |
| `POST` | `/api/orders/:orderId/no-show` | BUSINESS | `{ comment? }` |
| `POST` | `/api/orders/:orderId/cancel` | any party | `{ reasonCode, comment? }` |
| `POST` | `/api/orders/:orderId/refund/sent` | BUSINESS | `{ refundReference, note? }` |
| `POST` | `/api/orders/:orderId/refund/received` | customer | — |
| `GET` | `/api/orders/:orderId/track` | any party | — |
| `GET` | `rider-service/fare/chat-dispatch/quote` | customer | query |
| `POST` | `rider-service/fare/chat-dispatch/orders` | customer | **`orderType:"broadcast"`**, `selfpickupOrderId`, `selfpickupType`, `businessId`, `shopLocation`, `dropLocation`, `orderFor`, `fare`, `distance_in_km?`, `orderValue?`, `vehicleType?` |

There is **no** `PATCH /:orderId/delivery-quote`. Send the quote on create.

### Sockets — all on the chat socket

| Event | Payload | For |
|---|---|---|
| `productOrderLifecycle` | `{ messageId, orderId, action, lifecycle }` | **subscribe to this one** |
| `productOrderAccepted`, `…PaymentVerified`, … | same payload | per-event aliases, legacy |
| `ride:broadcast:searching` | `{ orderId, wave, totalWaves, radiusKm, ridersNotified }` | customer |
| `ride:broadcast:accepted` | `{ orderId, riderId }` | customer |
| `ride:broadcast:exhausted` | `{ orderId }` | customer |
| `ride:broadcast:closed` | `{ orderId, reason }` | **losing partners only — not the customer** |
| `newRiderOtpReceived` / `riderOtpUpdated` | `{ message }` / status | handoff cards |
| `payment:received` / `payment:verified` / `payment:rejected` | chat payment channel | payee / payer |

### Clocks — so the UI can promise honestly

| Clock | Value | Env key |
|---|---|---|
| Shop must accept | 20 min (nudge 5, 10) | `ORDER_ACCEPT_TIMEOUT_MINUTES` |
| Customer must pay (UPI) | 30 min | `ORDER_PAYMENT_SUBMIT_WINDOW_MINUTES` |
| Shop must verify | nudge 10, 30 · admin 60 | `ORDER_PAYMENT_VERIFY_*` |
| Prep default | 20 / 30 / 45 min by profile, +15 grace | `ORDER_PREP_*` |
| Pickup | nudge 30, 90 · decide 180 · expire 1440 | `ORDER_PICKUP_*` |
| Delivery not started | 25 min | `ORDER_DELIVERY_NOT_STARTED_MINUTES` |
| Delivery stalled | 90 min | `ORDER_DELIVERY_STALLED_MINUTES` |
| Broadcast rounds | 3, 6, 10 km · 20 s each · 60 s total · ≤15 partners/round | `BROADCAST_*` |
| Sweeper tick | 60 s | `ORDER_LIFECYCLE_JOB_INTERVAL_MS` |

All env-tunable. **Never hard-code any of them in Dart** — render `deadlines.*`
and let the server own the clock.

---

## 14. Scope — this is entirely a client change

**The backend is done. Nothing in this guide asks for a backend change.**

Every number, every state, every button and every live value specified above is
already computed, already persisted and already on the wire today. The work is:
read the right keys (§2), send the right coordinate shape (§5.4), stop navigating
away for delivery (§5.5, §7.2), and render what already arrives (§7.3).

Two things that look like backend gaps but are not:

| Looks like | Actually |
|---|---|
| "the server should auto-dispatch a rider when the shop packs a doorstep order" | It deliberately does not — it sets `deadlines.dispatchBy` (25 min) and lets the sweeper escalate if nothing happens. **The app is the trigger**, by design, and a duplicate call inside 3 minutes answers `429`. One line, no server change. |
| "the search should tell me how many partners were skipped" | Not emitted, and not needed. §7.4 builds a richer, fully truthful block — round timeline, radius, cumulative called, countdown — out of what already arrives. |

---

## 15. Implementation notes back to the backend (added after the client work)

Nothing here is a request for a change. These are three things the client side
learned building §1–§14 that are worth knowing on the server side.

| What we found | Why it matters to you |
|---|---|
| **The dispatch response's ride-order id is what the socket keys on.** The client reads it from `data.orderId` / `_id` / `id`. If it is named something else, the live block still works — the socket payload is matched to the one search in flight — but the 3 s safety poll has nothing to poll, so a missed socket event goes unnoticed until the next app resume. | One field name, worth confirming. |
| **`/actions` carrying no money means the client fetches `/track` to show an amount.** The pay sheet, the shop's verification card and the auto-dispatch all need Plane C. That is one extra round trip per card that needs money or an address. | If `/actions` ever gains `payment` and `delivery`, the client already merges rather than replaces, so it would simply stop calling `/track`. |
| **`banner` is rendered verbatim, so it can override the app's wording rules.** The client is careful never to call a `submitted` payment "Paid" — but a server-authored banner that does say "Paid" would appear on the shop's card as-is, next to the amber "Customer says they paid" block. | The three load-bearing strings in §3.2 and §6.9 are only safe if both sides hold them. |

**Client-side status:** implemented, `0` analyzer errors, 245 tests passing.
See `ORDER_FLOW_V3_FRONTEND_DONE.md`.
