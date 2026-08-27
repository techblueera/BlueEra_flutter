# Order Chat UI + Order Steps UI — Every Edge Case

**Companion to** [`GROCERY_SELF_PICKUP_ORDER_UI_AUDIT_AND_GUIDE.md`](GROCERY_SELF_PICKUP_ORDER_UI_AUDIT_AND_GUIDE.md).
That document covers the order API. **This one covers the two screens**: the **order card inside chat** and the
**order steps / status tracker**.

Everything is verified against the **live production backend** (27 Aug 2026) with Seller A (Singh Store,
grocery) and Customer B. Documentation only — no app code is changed by this file.


> **Where this lives vs what it covers.** This document sits in `be_chat_service/docs/` next to the other
> order docs, but the findings span several services. Fixes belong to:
> **`be_grocery_service`** (order create/pricing/state machine, `/track`, missing lifecycle routes) ·
> **`be_rider_service`** (the seller order list that excludes self-pickup) ·
> **`be_chat_service`** (the order card: `grocery-order/send-message`, the dead `chat/order-status` route,
> the missing grocery socket event) · **`BlueEra_flutter`** (rendering).
> Each item in the bug table names its owner.

---

## 0. Read this first — the chat order UI cannot render today

Nine real orders were placed against Singh Store during this audit. Then:

```
GET chat-service/chat/latest-chat   as SELLER A   → 1 thread   (system welcome), is_order: false
GET chat-service/chat/latest-chat   as CUSTOMER B → 1 thread   (system welcome), is_order: false
```

**Zero order threads. Zero order cards.** Placing a grocery order creates no conversation, no message and no
card. The chat order UI has nothing to draw.

Three things are missing at once:

| Layer | State | Evidence |
|---|---|---|
| **Thread** | Never created | `latest-chat` shows only the welcome thread, `is_order: false` |
| **Card** | `chat-service/grocery-order/send-message` produces `conversation_id: null` + `metadata.order` = bare id string, and **is never called by the app** | §2.3 |
| **Card state updates** | `chat-service/chat/order-status` → **404, route missing** | §2.4 |
| **Socket** | No grocery event exists (`newSelfPickupOrderReceived`, `newFood…`, `newProduct…`, `newHomeMadeFood…`, `newTiffin…`, `newMedical…` — **no grocery**) | `BlueEra_flutter/lib/core/constants/app_constant.dart:1206-1219` |
| **Model** | No grocery slot (`selfPickupOrder`, `foodPickupOrder`, `productPickupOrder`, `homeMadeFoodPickupOrder`, `tiffinPickupOrder`, `medicalPickupOrder` — **no grocery**) | `BlueEra_flutter/lib/features/chat/auth/model/GetListOfMessageData.dart:463-482` |

So §3–§6 below describe **the contract to render against once the backend produces it** (and how the ported
`product-service` vertical already behaves), and §7 describes **what to draw today, given nothing arrives**.

---

## Table of contents

1. [The two rendering paths](#1-the-two-rendering-paths)
2. [Chat order card — the payload](#2-chat-order-card--the-payload)
3. [Chat UI edge cases — the card itself](#3-chat-ui-edge-cases--the-card-itself)
4. [Chat UI edge cases — buttons and actions](#4-chat-ui-edge-cases--buttons-and-actions)
5. [Chat UI edge cases — thread, delivery, realtime](#5-chat-ui-edge-cases--thread-delivery-realtime)
6. [Order steps UI — every state](#6-order-steps-ui--every-state)
7. [What to render TODAY for grocery](#7-what-to-render-today-for-grocery)
8. [Copy table](#8-copy-table)
9. [QA checklist](#9-qa-checklist)

---

## 1. The two rendering paths

A chat order card can be driven by one of two payloads, and **which one you get depends on the vertical**:

```
┌─ MODERN (product-service only, deployed) ──────────────────────────────┐
│  metadata.lifecycle = {                                                │
│     orderStatus, sellerStatus, paymentMethod, paymentState,            │
│     customerActions[], ownerActions[], deadlines{}, banner,            │
│     lastEvent, reasonCode, refundDue, suggestion, refundOwedBy, …      │
│  }                                                                     │
│  → the card draws its buttons, banner and countdowns with NO API call  │
└────────────────────────────────────────────────────────────────────────┘

┌─ LEGACY (everything else, and any pre-rollout order) ──────────────────┐
│  metadata.lifecycle == null                                            │
│  metadata.order_status  ('placed' | 'ready' | 'cancelled' | null)      │
│  metadata.is_cancelled  (bool)                                         │
│  metadata.<vertical>PickupOrder = { … order snapshot … }               │
│  → fall back to status-only rendering; NO action buttons               │
└────────────────────────────────────────────────────────────────────────┘
```

**Rule:** `lifecycle == null` is not an error. It is the documented fallback
(`BlueEra_flutter/lib/features/chat/auth/model/GetListOfMessageData.dart` — *"Null on orders created before the lifecycle rollout, and on verticals whose
service is not yet ported"*). Grocery is one of those verticals, **today and for every order**.

---

## 2. Chat order card — the payload

### 2.1 Message envelope (real capture)

```json
{
  "_id": "6a8fdaa3ef2f11e94d346ed7",
  "message": "New grocery order",
  "message_type": "grocery_order",
  "sub_type": "grocery_order",
  "conversation_id": null,
  "senderId": "6a841f79acdd3589d5d21067",
  "status": "sent",
  "encryption_type": "plain",
  "is_payment": false,
  "payment_status": "pending",
  "message_read": 0,
  "who_seen_the_message": ["6a841f79acdd3589d5d21067"],
  "delete_from_everyone": false,
  "created_at": "2026-08-27T06:35:15.852Z",
  "sender": { "id": "…", "name": "Bhupinder", "contact": "1111123232", "profile_image": "…" },
  "my_message": true,
  "metadata": { … see 2.2 … }
}
```

### 2.2 `metadata` — the full field list (real capture)

```json
{
  "order": null,             // ← order snapshot, or (today) a bare id STRING
  "order_status": null,      // ← 'placed' | 'ready' | 'cancelled' | null
  "is_cancelled": false,
  "user": null,              // customer block
  "receiverUser": null,      // seller block
  "rider": null,
  "otp": null,
  "missed_call": false, "call_accept": false, "call_decline": false, "call_status": null,
  "serviceEnquiry": null, "artistEnquiry": null, "propertyEnquiry": null,
  "businessEnquiry": null, "educationEnquiry": null, "healthcareEnquiry": null,
  "hotelEnquiry": null, "homeStayEnquiry": null,
  "booking": null, "healthcareBooking": null,
  "riderAssociation": null, "symbol": null,
  "is_announcement": false
}
```

⚠️ **`lifecycle` is not even a key in the grocery response.** Absent ≠ empty — treat missing and `null`
identically.

### 2.3 `grocery-order/send-message` — why the card is orphaned

| Body sent | Result |
|---|---|
| `{}` | **`200`** — message created with everything null |
| `{"orderId": "<id>"}` | ignored; `metadata.order` stays `null` |
| `{"order": "<id>"}` | `metadata.order` = **`"6a8fda1d…"`** (bare string, not an object) |
| `{"conversation_id": "<id>"}` | sets `conversation_id` |
| `receiverId` / `businessId` / `order_status` / `user` / `receiverUser` | **silently ignored** |

It is a pass-through of raw message fields with no order lookup and no validation. A card built from it has no
items, no totals, no parties, and no thread.

### 2.4 `chat/order-status` — dead route

```
POST chat-service/chat/order-status  → 404  "Cannot POST /chat/order-status"   (all body shapes)
```

There is no way to update an order card's state from the client.

---

## 3. Chat UI edge cases — the card itself

| # | Case | What arrives | Exact UI |
|---|---|---|---|
| C1 | **No order message at all** (today's grocery reality) | thread has only text messages | Render the plain text bubble. **Do not** fabricate a card from the text |
| C2 | `metadata.order == null` | orphan card | **Do not render an order card.** Fall back to a plain text bubble showing `message` ("New grocery order"). A card with no data is worse than no card |
| C3 | `metadata.order` is a **String** id | today's `send-message` output | Treat as "id only": either fetch `/track` with it and render the full card, or render the text bubble. **Never** `order['grandTotal']` on a String — that throws |
| C4 | `metadata.order` is an **object** | modern path | Render §3.1 |
| C5 | `lifecycle == null` or key absent | grocery, food, medical, legacy orders | Legacy rendering: status chip from `order_status`, **no buttons** |
| C6 | `lifecycle` present but `customerActions` / `ownerActions` empty | terminal or waiting-on-other-party | Card + status, **no buttons**. Empty is a valid, common state |
| C7 | `conversation_id == null` | orphan | Message will never appear in a thread. Nothing to do client-side |
| C8 | `message_type` unknown to this build | new vertical shipped server-side | Render the plain text bubble. **Never** crash or show a blank row |
| C9 | `metadata.user` / `receiverUser` null | today, always | Fall back to the envelope `sender{}` block for the name/photo; hide the other party's row |
| C10 | `is_cancelled: true` with `order_status: null` | cancelled legacy card | Grey card + strikethrough title + "Cancelled". `is_cancelled` **wins** over `order_status` |
| C11 | `delete_from_everyone: true` | deleted | "This message was deleted" — never the card |
| C12 | Same order card appears twice | duplicate order (BUG-2) or replayed socket | De-duplicate by `metadata.order` id, keep the newest `created_at` |
| C13 | Card older than its order (stale) | socket missed | On thread open, re-fetch `/track` for every visible order id and prefer that |
| C14 | `my_message: true` for the seller | seller placed it themselves (self-order is allowed) | Render as an outgoing card; hide the seller action buttons |
| C15 | Product image missing | `productVariant.images: []` | Fall back to `productVariant.product.images[0].url`, then to a placeholder tile — **never an empty box** |

### 3.1 Card anatomy (when data is complete)

```
┌─ CHAT ORDER CARD ────────────────────────────────────────┐
│ 🧾 New order            GRO260827120009UXCQHL   12:00 PM │  ← message / orderNumber / created_at
│ ● Placed                                                 │  ← status chip (§6.1)
├──────────────────────────────────────────────────────────┤
│ ┌────┐ Act II Popcorn · 70 g              × 2            │
│ │IMG │ ₹̶2̶6̶ ₹24                             ₹48           │
│ └────┘                                                   │
│ + 2 more items                                           │  ← collapse beyond 2 lines
├──────────────────────────────────────────────────────────┤
│ Total                                       ₹48          │  ← grandTotal
│ 💵 Pay at the counter on pickup                          │  ← payment note VERBATIM
├──────────────────────────────────────────────────────────┤
│ [ View order ]              [ Mark Ready ]               │  ← §4
└──────────────────────────────────────────────────────────┘
```

- **Never headline a total you computed.** Use `grandTotal` from the payload.
- Collapse the item list at 2 rows + "+N more"; the full list belongs on the order detail screen.
- The status chip is the only colour on the card — keep the rest neutral.

---

## 4. Chat UI edge cases — buttons and actions

Buttons come **only** from `lifecycle.customerActions` / `lifecycle.ownerActions`. Never hard-code them per
status.

### 4.1 Action keys → labels → role

| Key | Label | Role |
|---|---|---|
| `SUBMIT_PAYMENT` | Submit payment | customer |
| `VIEW_PICKUP_CODE` | View pickup code | customer |
| `FIND_RIDER` | Find a rider | customer |
| `CONTACT_SHOP` | Call shop | customer |
| `RAISE_ISSUE` | Raise an issue | customer |
| `CONFIRM_REFUND_RECEIVED` | I received the refund | customer |
| `ACCEPT_ORDER` | Accept | owner |
| `REJECT_ORDER` | Reject | owner |
| `SET_PREP_ETA` | Set prep time | owner |
| `MARK_READY` | Mark ready | owner |
| `VERIFY_PAYMENT` | Verify payment | owner |
| `REJECT_PAYMENT` | Reject payment | owner |
| `CONFIRM_HANDOVER` | Confirm handover | owner |
| `REPORT_NO_SHOW` | Report no-show | owner |
| `MARK_REFUND_SENT` | Mark refund sent | owner |
| `CONTACT_CUSTOMER` | Call customer | owner |
| `CANCEL_ORDER` | Cancel order | both |
| `ADMIN_OVERRIDE` | Admin override | admin |

### 4.2 Button edge cases

| # | Case | Exact UI |
|---|---|---|
| B1 | **Action key this build doesn't know** | **Skip it silently.** Never render a button with a raw key like `MARK_REFUND_SENT` as its label, and never crash. This is how new server actions roll out safely |
| B2 | Both lists empty | No button row at all — don't reserve empty space |
| B3 | Action arrives for the wrong role | Render `customerActions` only when the viewer is the customer, `ownerActions` only when owner. **Verify against the viewer's own id**, not the card |
| B4 | Tap → `409 ACTION_NOT_AVAILABLE` | The other party moved first. **This is normal, not an error.** Silently re-fetch and re-render; no red toast |
| B5 | Tap → `409 CONCURRENT_MODIFICATION` | Same as B4 |
| B6 | Tap → `ORDER_TERMINAL` | "This order is already closed." + refresh |
| B7 | Tap → `NOT_A_PARTY_TO_ORDER` / `NOT_ORDER_CUSTOMER` | "You can't act on this order." + hide buttons |
| B8 | Tap → `404` **HTML** (`Cannot POST`) | Route not deployed for this vertical. Generic error + **hide that button permanently for this vertical** |
| B9 | Double-tap | Disable the button on first tap until the response lands; the server does not dedupe |
| B10 | Offline | Disable the row + "No connection" — never optimistically advance the card |
| B11 | Action succeeds | Re-fetch `/track` (or apply the socket `lifecycle`), never advance the card locally |
| B12 | `deadlines.acceptBy` in the past | Grey out `ACCEPT_ORDER`, show "Expired", let the server confirm on refresh |
| B13 | `refundDue: true` but payload never mentioned refunds | Use `refundDueStated` — a plain `false` from `/actions` must **not** clear a `true` the socket delivered |

### 4.3 Deadline countdowns

`lifecycle.deadlines`: `acceptBy · payBy · readyBy · pickupBy · dispatchBy · deliverBy · hardExpiryAt`.

| # | Case | Exact UI |
|---|---|---|
| D1 | All null | No countdown. Grocery: always null today |
| D2 | Deadline in the future | `mm:ss` when < 1 h, else `Hh Mm`; amber < 5 min |
| D3 | Deadline passes with the screen open | Stop the timer, show "Time's up", **re-fetch** — do not decide expiry client-side |
| D4 | Device clock wrong | Anchor to `lastEventAt` / server time, then tick with a monotonic clock |
| D5 | Screen backgrounded and resumed | Recompute from the server value on resume, never from the paused tick |
| D6 | Timer leak | Cancel every timer in `dispose()` — an order list can hold dozens |

---

## 5. Chat UI edge cases — thread, delivery, realtime

| # | Case | Exact UI |
|---|---|---|
| T1 | **No order thread exists** (today) | Nothing to show. The customer's post-order message goes into the ordinary personal thread |
| T2 | `is_order: true` on a chat-list row | Badge the row as an order conversation; show the order status as the subtitle |
| T3 | `is_order: false` but the thread contains order cards | Treat the thread as normal chat; the flag is a hint, not the source of truth |
| T4 | Socket `productOrderLifecycle` `{messageId, orderId, action, lifecycle}` | Find the card by `messageId` (fallback `orderId`), replace its `lifecycle`, re-render just that card |
| T5 | Socket arrives for an order not in the list | Ignore it, or insert the card if the thread is open. Never crash on an unknown id |
| T6 | Legacy socket (`selfPickupOrderReady` etc.) **and** `productOrderLifecycle` both fire | The generic channel is a superset — prefer it, de-dupe by `messageId` |
| T7 | **No grocery socket event exists** | Grocery cards will never update live. Refresh on screen focus and pull-to-refresh |
| T8 | Socket disconnected / app resumed | Re-fetch the thread + `/track` for visible orders. Never trust a stale card after resume |
| T9 | Card updates while the user is scrolled up | Update in place; do **not** auto-scroll or steal focus |
| T10 | Order completes while the thread is open | Card flips to Completed, all buttons disappear, no dialog |
| T11 | Push notification tapped → order thread | Deep-link to the thread; if the card isn't loaded yet, show a skeleton, then hydrate from `/track` |
| T12 | Two devices, same account | Both get the socket; the card is server-driven so they converge. Never keep local-only state |

---

## 6. Order steps UI — every state

Driven by `stages[]` from `/track` (§5.3 of the companion guide). Grocery has exactly **three** steps.

### 6.1 Status chip

| `orderStatus` | Chip | Colour |
|---|---|---|
| `placed` | Placed | amber |
| `accepted` | Accepted | blue |
| `in-progress` | In progress / Ready for pickup | blue |
| `ready` | Ready for pickup | green |
| `dispatched` | On the way | blue |
| `completed` | Completed | green |
| `cancelled` | Cancelled | grey |
| `expired` | Expired | grey |

> Grocery only ever emits `placed` · `in-progress` · `completed` (and `cancelled` via direct write).
> Handle all eight anyway — the enum is shared.

### 6.2 The stepper

```
✓───────────●───────────○
Order      Ready for   Completed
placed     pickup
27 Aug     27 Aug        —
12:00 PM   12:01 PM
```

- `done: true` → filled tick + `at` formatted (`27 Aug, 12:01 PM`)
- current step (first `done: false`) → filled ring, pulsing
- future → hollow circle + `—`
- **Labels come from `stages[].label`** — server copy, render verbatim, never hard-code "Ready for pickup"

### 6.3 Steps edge cases

| # | Case | Exact UI |
|---|---|---|
| S1 | `stages: []` | Fall back to a single chip from `orderStatus`; no stepper |
| S2 | An unknown `key` appears | Render it using its `label` — never filter to a hard-coded whitelist. This is how a 4th step ships without an app release |
| S3 | Stage `done: true` but `at: null` | Show the tick, hide the timestamp row |
| S4 | Stages out of order / a later one done first | Trust the array order for layout and `done` for state. Do not re-sort |
| S5 | **`orderStatus` and `currentStage` disagree** (real: `placed` + `ready_for_pickup`, BUG-6) | **`currentStage` wins** for the stepper; `orderStatus` drives the chip. Never assert they match |
| S6 | `isTerminal: true` then the order reopens (BUG-6) | Never cache `isTerminal`. Re-read it on every fetch |
| S7 | `stages[].businesses[]` present | Multi-shop: render a sub-row per business with its own `status` (`pending` / `ready`) |
| S8 | `pickup.businesses[].status` stays `ready` after completion (BUG-10) | Drive the final step from `stages[]`, **not** from `pickupStatus` |
| S9 | Cancelled mid-flow | Stop the stepper at the last `done` step, append a grey "Cancelled" node. Don't grey out completed history |
| S10 | `riderLeg` / `rider` / `rideOrder` null | Hide the rider tracker entirely — no empty map, no "waiting for rider" |
| S11 | `deliveryType: 'rider'` | Extra steps arrive in `stages[]`; render the rider block from `rider` |
| S12 | Timestamps in the future (clock skew) | Clamp to "just now" |
| S13 | Screen open while the seller marks ready | Poll `/track` on focus + pull-to-refresh (no grocery socket, T7) |
| S14 | `/track` 404 mid-view (order deleted) | "This order no longer exists." + pop, and drop it from the local list |

### 6.4 Payment row

| # | `payment.customer` | Exact UI |
|---|---|---|
| P1 | `applicable: false` + note (**grocery, always**) | Print `note` verbatim: *"Paid at the store counter on pickup."* **No pay button** |
| P2 | `applicable: true` | Render the amount + the action from `lifecycle.customerActions` (`SUBMIT_PAYMENT`) |
| P3 | `payment` key absent | Hide the whole row |
| P4 | `paymentState: 'submitted' / 'under_review'` | "Payment submitted — waiting for the shop to verify". No retry button |
| P5 | `paymentState: 'rejected'` | Red banner + reason + allow re-submit if the action is offered |
| P6 | `paymentState: 'refund_pending'` | "Refund pending from the shop" — **never** "we will refund you"; use `refundOwedBy` (always `"shop"`) |
| P7 | `isPaid: false` on a completed order (**grocery, always**) | Do **not** show "Unpaid" — cash was taken at the counter. Ignore `isPaid` for self-pickup |

---

## 7. What to render TODAY for grocery

Given nothing arrives from chat, this is the honest UI. No backend change required.

| Surface | Today | Render |
|---|---|---|
| Chat thread | plain text only | Normal text bubble. **No order card** |
| Order card | never created | — |
| Card buttons | no `lifecycle` | **None** |
| Live updates | no socket | Refresh on focus + pull-to-refresh |
| Steps UI | `/track` **works** ✅ | **Full 3-step stepper — this is the one surface you can build now** |
| Seller action | `PUT /ready` **works** ✅ | Single `Mark Ready` button at stage `placed` |
| Complete | `PUT :id {completed}` works | `Mark Collected` at stage `ready_for_pickup`, behind a confirm |
| Everything else | 404 | **Hide** — accept, reject, cancel, prep-ETA, handover, no-show, pickup code, all payment controls |

**The order detail screen, fed by `/track`, is the entire usable order UI today.** Reach it from a locally
persisted order id (see §9 of the companion guide) — there is no server list for either role.

**Vertical gate to apply everywhere:**

```
lifecycle available  → product-service only
/actions available   → product-service only
/track available     → product-service, grocery-service, food-service   (grocery/food = legacy shape)
chat order card      → nowhere for grocery
socket updates       → nowhere for grocery
```

---

## 8. Copy table

Use these strings; keep them in `AppStrings` with `.tr`.

| Situation | Copy |
|---|---|
| Order placed, waiting | "Waiting for the shop to confirm" |
| Ready for pickup (customer) | "Ready! Collect it from the shop" |
| Ready (seller) | "Waiting for the customer to collect" |
| Completed | "Order completed" |
| Cancelled | "Order cancelled" |
| Payment, self-pickup | *(print `payment.customer.note` verbatim)* |
| Stale action (409) | *(no message — refresh silently)* |
| Order terminal | "This order is already closed." |
| Not a party | "You can't act on this order." |
| Order gone (404) | "This order no longer exists." |
| Route missing / HTML error | "Something went wrong. Please try again." |
| Offline | "No connection. Pull to refresh." |
| Unknown action key | *(render nothing)* |

**Never** show: raw `error` text, Mongoose validation strings, "Invalid order ID", `ACTION_NOT_AVAILABLE`, or
an action key as a button label.

---

## 9. QA checklist

**Chat card**
- [ ] Order placed → thread behaviour matches reality (today: text bubble only, no card)
- [ ] `metadata.order == null` → text bubble, **no** empty card
- [ ] `metadata.order` as a String → no crash (never property-access a String)
- [ ] `lifecycle == null` → card renders, **zero** buttons, no error state
- [ ] Unknown `message_type` → text bubble, no crash
- [ ] `is_cancelled: true` → cancelled styling, overrides `order_status`
- [ ] Deleted message → "This message was deleted"
- [ ] Duplicate cards de-duplicated by order id
- [ ] Missing variant image → falls back to product image → placeholder
- [ ] Long item list collapses to 2 + "+N more"

**Buttons**
- [ ] Buttons come only from `customerActions` / `ownerActions`
- [ ] Unknown action key → skipped silently
- [ ] Role check against the viewer's own id
- [ ] 409 stale → silent refresh, no red toast
- [ ] 404 HTML → generic error, button hidden for that vertical
- [ ] Double-tap → one request
- [ ] Offline → disabled, never optimistic
- [ ] Success → re-fetch, never local advance

**Deadlines**
- [ ] All-null → no countdown (grocery)
- [ ] Expiry with screen open → stop + re-fetch
- [ ] Wrong device clock → still sane
- [ ] Background/resume → recomputed from server
- [ ] No timer leaks (open/close 20×)

**Steps**
- [ ] 3 steps render with server labels and timestamps
- [ ] Current step highlighted; future steps hollow
- [ ] Unknown stage key still renders via its label
- [ ] `orderStatus` vs `currentStage` mismatch → `currentStage` drives the stepper
- [ ] `isTerminal` never cached
- [ ] Multi-shop sub-rows render per business
- [ ] Rider block hidden when null
- [ ] Cancelled → history kept, grey terminal node
- [ ] Seller marks ready → customer sees it after refresh
- [ ] `/track` 404 mid-view → friendly message + pop

**Payment**
- [ ] `applicable: false` → note verbatim, no pay button
- [ ] `isPaid: false` on a completed self-pickup order → **no** "Unpaid" badge
- [ ] Refund copy says the **shop** returns the money, never "we"
