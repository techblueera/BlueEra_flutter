# Order UI — State-Driven Implementation Guide

**For the Flutter developer.** The backend is done and deployed. This document says exactly what to
draw for every state, every role, and every edge case — and what to **hide**.

**Verified 27 Aug 2026** against live production (`https://be.beapp.in/api`) with two real accounts,
plus the source of `be_product_service_v2` (the deployed order engine), `be_grocery_service`,
`be_chat_service` and the production databases. Every payload here is real.

---

## 0. The one rule that replaces all others

> **`GET /actions` tells you which buttons to draw. Flutter never decides.**

The backend owns legality. From `orderStateMachine.js`:

> *"Flutter's job shrinks to: render `availableActions`. It never decides."*

So **delete every local rule** of the form "show Cancel if status == placed". If a state you have
never heard of arrives, you render **no buttons** — never a button the backend will reject.

```dart
// The ONLY correct shape.
final res = await api.getActions(orderId, service: service);
for (final key in res.availableActions) {
  final spec = kActionSpecs[key];   // §3 table
  if (spec == null) continue;       // unknown key → render NOTHING
  buttons.add(spec.build(ctx));
}
```

This is what makes the UI conditional instead of one fixed card. The user's own example —
*"cash order, so don't show a pay button or a ride button"* — needs no client logic at all: on a cash
order the server simply never returns `SUBMIT_PAYMENT`.

---

## 1. Three independent state domains

Forcing everything into one status is what produces meaningless states. The backend keeps three, and
**your UI must read all three**:

| Field | Values | Drives |
|---|---|---|
| `orderStatus` | `placed` · `accepted` · `in-progress` · `ready` · `dispatched` · `completed` · `cancelled` · `expired` | the headline chip and the stepper |
| `sellerStatus` *(owner only)* | `pending` · `accepted` · `preparing` · `ready` · `handed_over` · `rejected` · `cancelled` | **the shop's own** buttons in a multi-shop cart |
| `paymentState` | `pending` · `submitted` · `under_review` · `verified` · `rejected` · `expired` · `refund_pending` · `refunded` | the money row — **on its own clock** |

**A cancelled order can still have `paymentState: refund_pending`.** That is the whole point of
keeping them apart: the order is dead, the money conversation is not. Never hide the money row just
because `isTerminal == true`.

Plus `paymentMethod`: `cash` · `upi` · `gateway` (reserved).

---

## 2. The contract — `GET /api/orders/:orderId/actions`

Call it on screen open, on focus, and after every successful action. This one response is enough to
render the entire screen's controls.

```json
{ "success": true, "data": {
  "orderId": "…", "orderNumber": "ORD…",
  "actor": "owner",                       // ← the server tells you who you are. Never guess.
  "orderStatus": "ready",
  "sellerStatus": "ready",                // null when actor is customer
  "paymentMethod": "upi",
  "paymentState": "submitted",
  "deliveryType": "self-pickup",
  "isTerminal": false,
  "needsAttention": false,
  "deadlines": { "acceptBy": "…", "payBy": "…", "readyBy": "…",
                 "pickupBy": "…", "dispatchBy": "…", "deliverBy": "…", "hardExpiryAt": "…" },
  "availableActions": ["CONTACT_CUSTOMER","CONFIRM_HANDOVER","REPORT_NO_SHOW",
                       "CANCEL_ORDER","VERIFY_PAYMENT","REJECT_PAYMENT"],
  "cancellationReasons": ["ITEM_UNAVAILABLE","SHOP_CLOSED", "…"]
} }
```

Three fields people miss:

- **`actor`** — `customer` \| `owner` \| `admin`. Stop threading an `isOwner` guess through
  constructors; read it here.
- **`cancellationReasons`** — the reason list is **server-owned**, populated for both `CANCEL_ORDER`
  *and* `REJECT_ORDER`. Never hardcode reasons in the app; they will drift.
- **`needsAttention`** — the order is stuck and flagged for a human. Show a banner (§8).

Errors are typed: `{ success:false, code, message }`. **Branch on `code`, show your own copy.**

---

## 3. The 16 actions — label, API, gating

`ctx` = the order. Every path is `{service}/api/orders/{orderId}/…`.

> **Body keys below are the ones the live API actually accepts** — each was confirmed by a real call
> on 27 Aug 2026. Several differ from what the route comments suggest; sending the wrong key returns
> a typed 400, not a silent ignore.

| `availableActions` key | Button | Method + path | Body | Confirm? |
|---|---|---|---|---|
| `ACCEPT_ORDER` | **Accept order** | `POST /accept` | — | no |
| `REJECT_ORDER` | **Decline** | `POST /reject` | `{reasonCode, comment?}` | reason sheet |
| `SET_PREP_ETA` | **Set ready time** | `POST /prep-eta` | `{prepEtaMinutes}` ⚠️ *not `minutes`* | picker sheet |
| `MARK_READY` | **Mark ready** | `PUT /ready` | — | no |
| `CONFIRM_HANDOVER` | **Hand over** | `POST /handover` | `{pickupCode}` | code entry |
| `REPORT_NO_SHOW` | **Customer didn't arrive** | `POST /no-show` | `{note?}` | **yes** |
| `VERIFY_PAYMENT` | **Verify payment** | `POST /payment/verify` | `{amountReceived}` | after viewing proof |
| `REJECT_PAYMENT` | **Reject payment** | `POST /payment/reject` | `{reason}` ⚠️ *free text, not a code* | **yes** |
| `SUBMIT_PAYMENT` | **Pay now** | `POST /payment/submit` | `{utrNo, amountPaid, screenshotUrl}` ⚠️ *`utrNo`, not `utr`* | upload sheet |
| `VIEW_PICKUP_CODE` | **Show pickup code** | `GET /pickup-code` | — | no |
| `CANCEL_ORDER` | **Cancel order** | `POST /cancel` | `{reasonCode, comment?}` | reason sheet |
| `FIND_RIDER` | **Get it delivered** | *(rider dispatch)* | — | fee confirm |
| `MARK_REFUND_SENT` | **I've sent the refund** | `POST /refund/sent` | `{refundReference?}` | **yes** |
| `CONFIRM_REFUND_RECEIVED` | **I got my refund** | `POST /refund/received` | — | **yes** |
| `CONTACT_SHOP` / `CONTACT_CUSTOMER` | **Call** | *(dialer)* | — | no |
| `RAISE_ISSUE` | **Report a problem** | *(support)* | — | no |
| `ADMIN_OVERRIDE` | admin console only | `POST /admin/override` | `{action, reasonCode?, note?}` | **yes** |

> `REPORT_NO_SHOW` is **self-pickup only** — the server enforces it. On a delivery order the
> customer was never coming; a rider was. Never render it on a delivery order.

---

## 4. Flow A — Self-pickup + **CASH**

`paymentMethod: "cash"`, so **`SUBMIT_PAYMENT` is never returned**. No pay button, no UPI QR, no
fare, no rider control — anywhere, at any point. Money moves hand-to-hand at the counter and the
owner confirms it at handover.

| `orderStatus` | Customer sees | Customer buttons | Shop sees | Shop buttons |
|---|---|---|---|---|
| `placed` | "Waiting for the shop to accept" + **countdown to `acceptBy`** | Cancel · Contact · Issue | "New order" + countdown | **Accept** · **Decline** · Contact |
| `accepted` | "Shop accepted — preparing" + ETA if set | Cancel · Contact · Issue | preparing | Set ready time · **Mark ready** · Cancel · Contact |
| `in-progress` | "Being packed" + ETA, **late badge past `readyBy`** | Contact · Issue *(no Cancel)* | packing | Set ready time · Mark ready · Cancel |
| `ready` | **"Ready — collect it"** + address, Directions, **pickup code** + countdown to `pickupBy` | **Show pickup code** · Contact · Issue · *(Get it delivered)* | "Waiting for customer" | **Hand over** · **Customer didn't arrive** · Cancel · Contact |
| `completed` | "Collected" ✓ | Issue | ✓ | — |
| `cancelled` / `expired` | reason, verbatim | Issue | — | — |

**Why Cancel disappears at `in-progress`:** the shop has started spending money. The server drops
`CANCEL_ORDER` from the customer's list — so the button vanishes on its own. Do not re-add it.

### The handover handshake

`ready` → customer taps **Show pickup code** → shows a code → shop types it into **Hand over**.
A wrong code returns a typed error; show *"That code doesn't match this order."* This is what stops
the wrong order going to the wrong person — never let the shop complete without it.

---

## 5. Flow B — Self-pickup + **UPI**

Identical to A, **plus** a payment track that runs in parallel. `SUBMIT_PAYMENT` appears only once
`orderStatus ∈ {accepted, in-progress, ready}` — *"taking money before acceptance is how you end up
refunding orders the shop never wanted."*

| `paymentState` | Customer money row | Customer button | Shop money row | Shop buttons |
|---|---|---|---|---|
| `pending` | "Pay ₹X to the shop" + **countdown to `payBy`** | **Pay now** | "Waiting for payment" | — |
| `submitted` | "Payment sent — waiting for the shop to confirm" ⏳ | *(none — do not offer Pay again)* | **"Payment proof received"** + UTR + screenshot | **Verify** · **Reject** |
| `under_review` | same as submitted | — | "You're reviewing this" | Verify · Reject |
| `verified` | **"Payment confirmed"** ✓ green | — | ✓ | — |
| `rejected` | **"The shop couldn't confirm this payment"** + reason | **Pay again** (server re-offers `SUBMIT_PAYMENT`) | ✗ | — |
| `expired` | "Payment window closed" | **Pay now** (still allowed) | — | — |
| `refund_pending` | see §7 | — | see §7 | **I've sent the refund** |
| `refunded` | "Refunded" ✓ | — | ✓ | — |

**A screenshot is not a payment.** `submitted` means *the customer claims to have paid*. Never draw a
green tick, never say "Paid", never unlock anything until `verified`.

**Handover is gated on money for UPI:** `CONFIRM_HANDOVER` is withheld until `paymentState ==
verified`. The shop sees no Hand over button — that is correct, not a bug. Show
*"Verify the payment before handing over."*

### The payment sheet

```
┌──────────────────────────────────────────┐
│  Pay ₹480 to Singh Store                 │
│  ┌────────────────┐                      │
│  │   UPI QR       │  singhstore@upi  [⧉] │
│  └────────────────┘                      │
│  Pay in any UPI app, then come back.     │
│  ──────────────────────────────────────  │
│  UTR / reference *   [____________]      │  ← required
│  Screenshot *        [ Upload ]          │  ← required
│              [ Submit payment ]          │
└──────────────────────────────────────────┘
```

Both fields required client-side. On upload failure keep the sheet open with the UTR intact — never
lose typed input. On success the sheet closes and the row becomes "waiting for the shop".

---

## 6. Flow C — Delivery (rider)

### C0 · The waiting window — *"user must visibly understand they are waiting"*

Between placing and a rider accepting, the customer currently sees a hollow circle. **This is the
biggest visible gap.** The data is already in the rider card payload:

```json
"broadcast": { "waveIndex": 0, "waveStartedAt": "…", "expiresAt": "…",
               "notifiedRiders": ["…"], "vehicleType": "two-wheeler" },
"potentialRiders": [...], "rejectedRiders": [...], "status": "payment-pending"
```

Required card:

```
┌──────────────────────────────────────────────┐
│   ((( ● )))   Finding a delivery partner     │  ← pulsing, INDETERMINATE
│                                              │
│   Contacting riders nearby · round 1         │  ← broadcast.waveIndex + 1
│   ▓▓▓▓▓▓▓░░░░░░░  0:38                       │  ← counts to broadcast.expiresAt
│   3 riders notified                          │  ← notifiedRiders.length
│   Delivery fee ₹35 (estimated)               │
│                        [ Cancel order ]      │
└──────────────────────────────────────────────┘
```

Rules:
- Render only when `deliveryType == 'rider'` **and** no rider is assigned **and** not terminal.
- **Indeterminate** — never a percentage of a search that can restart.
- On `expiresAt` lapsing, roll to the next wave: *"Still looking — trying more riders."* **Not**
  a failure.
- The instant a rider is assigned this block is **replaced** by C2. Never both.
- If it ends with no rider, the order is flagged `NO_RIDER` (§8) — show the attention banner, **do
  not** silently cancel.

### C1–C5 · The rest

| Stage | Customer | Shop |
|---|---|---|
| `placed` | searching card (C0) | Accept / Decline |
| rider assigned | **rider block** (below) | "Rider on the way to you" |
| `dispatched` | "Picked up — on the way" + Track | ✓ handed to rider |
| `completed` | "Delivered" ✓ | ✓ |

**Rider block — the "real number":**

```
┌──────────────────────────────────────────────┐
│  ⬤  Ramesh Kumar              ★ 4.6 (23)     │
│     PB11AB1234 · two-wheeler                 │
│     [ 📞 Call rider ]   [ 🧭 Track ]         │
└──────────────────────────────────────────────┘
```

- Hide **Call** when `contactNo` is empty — never a dead dial button.
- Hide **Track** when `liveLocation` is null. The backend already suppresses `{0,0}`, so a present
  location is always real.

**Delivery fee must be shown before a rider is committed.** *"Do NOT assign a rider first and then
tell the user the cost."* If the final fee differs materially from the estimate, confirm before
charging — never surprise after acceptance.

---

## 7. Refund reconciliation — the flow that outlives the order

With direct UPI the customer paid the **shop's** VPA. The platform never held the money, so only the
shop can send it back and only the customer can confirm it landed. **Both need buttons on an order
that is already `cancelled`.**

```
order cancelled, paymentState = refund_pending
        │
        ├─ SHOP    → [ I've sent the refund ]      POST /refund/sent
        │                    ↓ refundInitiatedAt set
        └─ CUSTOMER→ [ I got my refund ]           POST /refund/received
                             ↓
                     paymentState = refunded ✓
```

| Who | Before shop sends | After shop sends |
|---|---|---|
| Shop | **I've sent the refund** · Contact | Contact only + *"Waiting for the customer to confirm"* |
| Customer | Report a problem · Contact *(nothing to confirm yet)* | **I got my refund** · Report a problem · Contact |

**A terminal order is not an empty screen.** If `paymentState ∈ {refund_pending}`, the money block
and its buttons stay. This is the single most-missed case in the app today.

### ⛔ Blocked on a backend bug — do not build this yet

Live-tested 27 Aug 2026: cancelling a **paid** order correctly produces
`orderStatus: cancelled · paymentState: refund_pending · needsAttention: true`, and `/actions`
correctly offers the shop `MARK_REFUND_SENT`. But calling it fails:

```
POST /refund/sent      → 409 {"code":"ORDER_TERMINAL","message":"This order is already cancelled."}
POST /refund/received  → 409 {"code":"ORDER_TERMINAL"}
```

`guardAction` checks *terminal* before it checks *is this action allowed*, while
`availableActionsFor` deliberately returns the refund actions **before** its own liveness gate. The
two disagree, so **both refund endpoints are unreachable for non-admins and verified money can never
be marked returned** — the order sits flagged for a human forever.

Build the UI to this spec, but expect the buttons to 409 until the guard is reordered. Treat
`ORDER_TERMINAL` on a refund action as "backend not fixed yet", not as user error.

---

## 8. Deadlines, timeouts and `needsAttention`

### 8.1 Countdowns — draw them, this is the "visible waiting"

`deadlines` gives seven absolute timestamps. Show the one that matches the current state:

| Field | Shown when | Copy |
|---|---|---|
| `acceptBy` | `placed` | "Shop must accept within 12:04" |
| `payBy` | UPI, unpaid | "Pay within 24:11" |
| `readyBy` | `accepted`/`in-progress` | "Ready by 6:40 pm" → past it: **Running late** badge |
| `pickupBy` | `ready`, self-pickup | "Collect by 8:15 pm" |
| `dispatchBy` | `ready`, delivery | shop-side: "Rider should collect by …" |
| `deliverBy` | `dispatched` | "Arriving by 7:05 pm" |
| `hardExpiryAt` | any | last-resort expiry |

Two hard rules:

1. **A countdown hitting zero never changes state locally.** Keep polling; the server decides. The
   sweeper runs on its own clock and a client that "expires" an order creates two systems that
   disagree — the exact bug the backend rewrite removed.
2. **A null deadline draws nothing.** No "—", no empty row.

### 8.2 Stuck orders

`needsAttention: true` → a human is required. Show a calm banner, never a red error:

> ⚠️ **We're looking into this order.** Support has been notified.

Reasons (internal, admin console): `PAYMENT_REVIEW` · `OWNER_ACTION_REQUIRED` · `NO_RIDER` ·
`RIDER_LATE` · `OWNER_PREPARATION_LATE` · `CUSTOMER_NO_SHOW` · `REFUND_REQUIRED` ·
`REFUND_AWAITING_CONFIRMATION` · `DELIVERY_FAILED` · `DISPUTED`.

**Never show a stuck order as "everything is fine".** The customer keeps Contact + Report a problem.

---

## 9. Cancellation & rejection sheets

Reasons come from `cancellationReasons` in the `/actions` response — **already scoped to the caller's
role**. Render them as a list; `OTHER` reveals a free-text note. `reasonCode` is required; the API
returns `INVALID_REASON` without it.

| Role | Reasons the server will offer |
|---|---|
| Customer | Changed mind · Ordered by mistake · Too slow · Found elsewhere · Delivery too expensive · Wrong items · Other |
| Shop | Item unavailable · Shop closed · Too busy · Price changed · Customer not responding · Customer didn't arrive · Payment not received · Suspected fraud · Outside delivery area · Other |
| System *(display only)* | Owner didn't respond · Payment window expired · Pickup window expired · No rider available · Order expired |

**Never render a raw code.** Map to sentence case. When an order is cancelled by the system, the
cancellation card must say **why** — *"Cancelled: no rider was available"*, never a bare "Cancelled".

---

## 10. Error codes → exact copy

| `code` | HTTP | Show |
|---|---|---|
| `ORDER_NOT_FOUND` | 404 | "This order no longer exists." + drop from list |
| `NOT_A_PARTY_TO_ORDER` | 403 | "You don't have access to this order." + hide all controls |
| `ORDER_TERMINAL` | 409 | "This order is already {status}." + refresh |
| `ACTION_NOT_AVAILABLE` | 409 | **Say nothing.** Silently re-fetch — the other party moved first. The refreshed screen explains itself |
| `INVALID_REASON` | 400 | Developer error — never ship |
| `INTERNAL_ERROR` | 500 | Generic copy |

`ACTION_NOT_AVAILABLE` is the common one and a red toast for it is a lie. Its `detail` carries the
fresh `available` list — use it to re-render immediately.

**Never** surface a raw `error` field, and never branch on message text.

---

## 11. Chat cards vs the order screen

| | Chat card | Order screen |
|---|---|---|
| Source | message `metadata` — a **snapshot**, frozen at send | `/actions` + `/track` — **live** |
| Actions | **exactly one**: open the order | all of them |
| Never | lifecycle buttons, pay controls, fare, rider dispatch | — |

The card is a snapshot that can be hours stale. Put write actions on the screen, not the card. The
chat sequence the product wants — order card → accept → payment card → proof → verified → packed →
finding rider → rider card → delivered — is produced by the **backend** posting cards; your job is to
render whichever arrives and keep one action on each.

Card parse keys (verified against 1,752 real production cards):

| `message_type` | id key | prod | parses |
|---|---|---:|---|
| `selfpickup` (grocery) | `selfpickupOrderId` | 977 | ✅ |
| `food_selfpickup` | `foodPickupOrderId` | 262 | ✅ |
| `tiffin_selfpickup` | `tiffinPickupOrderId` | 314 | ✅ |
| `product_selfpickup` | `productPickupOrderId` | 119 | ✅ |
| `homemade_food_selfpickup` | `homeMadeFoodPickupOrderId` | 61 | ✅ |
| `medical_selfpickup` | `medicalPickupOrderId` | **0** | ⚠️ never exercised |
| `rider` / `rider_map` / `rider_otp` | — | 182 / 182 / 55 | ✅ (`rider_map` suppressed) |
| `grocery_order` *(legacy)* | — | 19 | `metadata.order` is a bare string → hydrate via `/track` |

---

## 12. The legacy verticals — do not assume parity

`be_product_service_v2` is deployed and has everything above. **Grocery, food and medical are not on
it.** Grocery has three stages (`placed → ready_for_pickup → completed`), one seller action, no
`/actions`, no `actor`, no `availableActions`, payment always "cash at counter".

So keep the capability gate — but fix its facts. Verified live, the old docs are **wrong** on four
points and the app's table inherited all four:

1. *"No grocery chat card is ever created."* — **False.** 977 exist. The audit called `latest-chat`
   without `?type=business`; that endpoint defaults to `personal` and only returns threads with
   unread messages from someone else.
2. *"No grocery socket event exists."* — **False.** Four fire: `newSelfPickupOrderReceived`,
   `selfPickupOrderReady`, `groceryOrderDispatched`, `groceryOrderCompleted`.
3. *"No grocery order list."* — **False.** `GET /api/orders/business/me` and `/me` both work.
4. *"`chat/order-status` is dead."* — **False.** It is `PUT`, not `POST`.

For grocery specifically: **self-pickup orders auto-expire after 1 hour** at `placed`
(swept every 15 min) — **978 of 1,099 production orders are `expired`**. Grocery sends no
`deadlines`, so derive the countdown from `createdAt + 1h` and still let the server decide the state.

---

## 13. Realtime

Treat every event as *"something changed, go re-read"* — **never patch state from the event body**.

| Event | Then |
|---|---|
| `newSelfPickupOrderReceived` | insert card, badge thread |
| `selfPickupOrderReady` | re-fetch |
| `groceryOrderDispatched` / `groceryOrderCompleted` | re-fetch |
| product-service order events | re-fetch `/actions` |

Keep focus-refresh as the fallback. Push operations that must open the order screen:
`selfpickup_order` (→ shop), `selfpickup_order_ready` (→ customer), `grocery_order_dispatched`.
**The app currently switches on `grocery_order` / `grocery_order_ready`, which the backend never
sends** — that deep link is dead today.

---

## 14. Build order

| # | Gap | Sev | Work |
|---|---|---|---|
| 1 | Read `actor` from `/actions` instead of guessing `isOwner` | 🔴 | small |
| 2 | Fix push case labels (`selfpickup_order`, not `grocery_order`) | 🔴 | one line |
| 3 | Rider-search card — **already built** in three places (§17.4). Verify it covers every entry point rather than rebuilding it | 🟡 | verify |
| 4 | **Refund reconciliation UI** on terminal orders (§7) | 🔴 | medium |
| 5 | **Payment track**: submit sheet, waiting, verify/reject, rejected-retry (§5) | 🔴 | large |
| 6 | Deadline countdowns from `deadlines` (§8.1); grocery derived | 🔴 | medium |
| 7 | Branch cards on `deliveryType` — a delivery order renders the self-pickup card today | 🔴 | small |
| 8 | `needsAttention` banner (§8.2) | 🟠 | small |
| 9 | Reason sheets from `cancellationReasons`, never hardcoded (§9) | 🟠 | small |
| 10 | Pickup-code handshake (§4) | 🟠 | medium |
| 11 | Subscribe to the four grocery socket events | 🟡 | small |
| 12 | `riderLeg` is a **String**; the model does `_map()` on it → always null | 🟡 | one line |
| 13 | Chat card never reaches Completed — **backend**: grocery never publishes `GROCERY_ORDER_COMPLETED` | 🔴 | backend |

---

## 15. QA checklist

**Cash self-pickup**
- [ ] No pay button, no QR, no fare, no rider control at any state
- [ ] `placed`: customer has Cancel; shop has Accept + Decline only
- [ ] Cancel **disappears** for the customer at `in-progress`
- [ ] `ready`: pickup code shown; shop cannot hand over without it
- [ ] Decline opens the reason sheet; no reason → no request sent

**UPI self-pickup**
- [ ] Pay only after the shop accepts
- [ ] `submitted` shows waiting — **never** a green tick
- [ ] Shop's Hand over stays hidden until `verified`
- [ ] Rejected payment → customer can pay again, with a reason shown
- [ ] Upload failure keeps the UTR typed

**Delivery**
- [ ] Searching card while no rider; disappears the instant one is assigned
- [ ] Wave rollover shows "still looking", not failure
- [ ] Fee shown before a rider is committed
- [ ] Call hidden with no number; Track hidden with no location
- [ ] `REPORT_NO_SHOW` never appears

**Terminal & refunds**
- [ ] `cancelled` + `refund_pending` still shows the money block and its buttons
- [ ] Shop's button flips to "waiting for customer" after sending
- [ ] System cancellation states the reason, never a bare "Cancelled"

**Cross-cutting**
- [ ] Unknown action key renders nothing
- [ ] `ACTION_NOT_AVAILABLE` → silent refresh, no toast
- [ ] Countdown reaching zero never changes state locally
- [ ] `needsAttention` banner is calm, not an error
- [ ] Double-tap creates one order; buttons dead until the response lands
- [ ] Airplane mode: cached view + retry, no crash
- [ ] Raw `error` never rendered

---

## 16. Verified against

| | Shop A | Customer B |
|---|---|---|
| Name | Singh Store | Bhupinder |
| userId | `6a8e73a5f1331440ed37bdd9` | `6a841f79acdd3589d5d21067` |

Full grocery lifecycle replayed live on `6a8ff78b4679a69f9620ae3e`: place → `403` on customer ready →
Mark Ready → double-tap `400` → card flips (async) → Mark Collected → `isTerminal` → repeat writes
are no-ops.

### v2 lifecycle, replayed live

For product-service the roles flip: Singh Store has no product-service catalogue, Bhupinder does — so
Singh Store buys and Bhupinder's shop sells. Three real orders were created.

| Step | Result |
|---|---|
| Cash order placed | `201` · deadlines set: `acceptBy` +20 min, `readyBy` +1 h, `hardExpiryAt` +24 h |
| `/actions` at `placed` | customer `[CONTACT_SHOP, RAISE_ISSUE, CANCEL_ORDER]` · shop `[CONTACT_CUSTOMER, ACCEPT_ORDER, REJECT_ORDER]` — **exactly as specified** |
| Customer tries `ACCEPT` | `409 ACTION_NOT_AVAILABLE` ✅ |
| Shop accepts | `200` · shop gains `SET_PREP_ETA, MARK_READY, CANCEL_ORDER` |
| Prep ETA | `{minutes}` → `400 INVALID_PREP_ETA`; `{prepEtaMinutes}` → `200`, `readyBy` moves |
| Mark ready | `200` · `pickupBy` set +2.5 h · customer gains `VIEW_PICKUP_CODE`, `FIND_RIDER`, **loses `CANCEL_ORDER`** |
| Pickup code | customer `200 {"pickupCode":"Z5UTQ9"}` · shop `403 NOT_ORDER_CUSTOMER` ✅ |
| Handover, wrong code | `403 PICKUP_CODE_MISMATCH` ✅ |
| Handover, right code | `200` → `completed`, and **cash auto-moves to `paymentState: verified`** |
| Repeat handover | `409 ORDER_TERMINAL` ✅ |
| UPI: pay before acceptance | `409 ACTION_NOT_AVAILABLE` ✅ |
| UPI: after acceptance | customer gains `SUBMIT_PAYMENT` · `payBy` deadline appears |
| Submit proof | `{utr}` → `400 UTR_REQUIRED`; `{utrNo, amountPaid, screenshotUrl}` → `200` |
| After submit | customer **loses** `SUBMIT_PAYMENT` · shop gains `VERIFY_PAYMENT`, `REJECT_PAYMENT` ✅ |
| Ready while unpaid | shop has **no `CONFIRM_HANDOVER`** — the money gate works ✅ |
| Reject payment | `{reasonCode}` → `400 REASON_REQUIRED`; `{reason}` → `200` · customer regains `SUBMIT_PAYMENT` ✅ |
| Verify | `200` → `verified` · **`CONFIRM_HANDOVER` appears** ✅ |
| Cancel a paid order | `200` → `cancelled` + `refund_pending` + `needsAttention: true` |
| Refund endpoints | **`409 ORDER_TERMINAL` — the P0 bug in §7** ❌ |
| Same `idempotencyKey` twice | **one order** ✅ (grocery does not dedupe; v2 does) |
| Decline with `reasonCode` | `200` → `cancelled`, nothing owed, no attention flag |

**Context worth knowing:** before this run, v2 held 150 orders — 144 `expired`, 6 `cancelled`,
**zero completed, zero UPI, zero rider, zero attention flags**. The rich lifecycle is deployed but had
never been exercised end-to-end in production. Every deadline field read `null` across all 150,
because they all predate the lifecycle work — deadlines do populate correctly on new orders.

---

## 17. Checkout — before the order exists

Everything above starts once an order exists. This section covers the screen before it.

### 17.1 The quote — `GET rider-service/fare/chat-dispatch/quote`

**Call it on every address change.** It touches no database and searches for no rider, so it is
cheap and safe to call repeatedly.

```
?shopLat=30.140261&shopLng=74.2946258&dropLat=30.155&dropLng=74.305
&distance_in_km=<client road distance, optional but preferred>
&orderValue=<basket total, optional>
```

Real response (captured live):

```json
{ "feasible": true,
  "distanceKm": 2, "distanceSource": "haversine",
  "deliveryFee": 40, "riderPayout": 40, "platformMargin": 0,
  "etaMinutes": 15, "etaRange": { "min": 10, "max": 25 },
  "peak": false,
  "breakdown": { "baseFee": 20, "baseKm": 1, "chargeableKm": 1, "perKmFee": 20,
                 "distanceComponent": 20, "peakMultiplier": 1,
                 "minimumFeeApplied": false, "maximumFeeApplied": false },
  "economics": { "orderValue": 48, "feeToOrderRatio": 0.83,
                 "feeExceedsOrderValue": false, "feeIsHighVsOrder": true,
                 "suggestion": "Delivery costs a lot compared to this order — collecting it from the shop may be cheaper." },
  "quotedAt": "2026-08-27T09:36:10.612Z" }
```

**Why the quote comes first:** quoting *after* dispatch makes a rider wait while the customer
decides, and a decline burns their time for nothing. The fee here is authoritative —
`POST /fare/chat-dispatch/orders` recomputes it and refuses a materially lower client `fare` with
`409 FARE_MISMATCH`. Never send a fee the user did not see.

### 17.2 Every quote outcome → exact UI

| Case | Response | UI |
|---|---|---|
| Normal | `feasible: true` | "Delivery ₹40 · 10–25 min". Show `etaRange`, not the single `etaMinutes` — a range is honest |
| **Fee high vs basket** | `economics.feeIsHighVsOrder: true` | Show `economics.suggestion` **verbatim** and put **Self-pickup** beside it as an equal choice. Do not bury it |
| **Fee exceeds basket** | `feeExceedsOrderValue: true` (live: ₹10 order, ₹127 fee, ratio 12.7) | Same, but make self-pickup the **default** selection. Never let this be a silent surprise |
| **Out of range** | `200` · `feasible:false` · `reason: OUTSIDE_DELIVERY_RADIUS` · `"Delivery is only available within 12 km of the shop."` · `maxDistanceKm: 12` | **This is a 200, not an error.** Disable the delivery option, show the message, keep self-pickup selectable |
| Peak pricing | `peak: true`, `breakdown.peakMultiplier > 1` | Say so — "Busy right now, fares are higher" |
| Fee floor / ceiling hit | `minimumFeeApplied` / `maximumFeeApplied` | Optional detail in an expandable breakdown |
| Bad coords | `400 "shopLat, shopLng, dropLat and dropLng are all required and must be numbers."` | Developer error — never ship |

`breakdown` exists so the fee is explainable. Put it behind a "How is this calculated?" disclosure —
an unexplained delivery fee is the most common cause of checkout abandonment.

### 17.3 Checkout order of operations

```
1. Cart               → basket total
2. Address / location → lat+lng REQUIRED before the delivery option can be priced
3. Quote              → fee, ETA, feasibility          ← re-quote on every address change
4. Choose fulfilment  → Self-pickup  |  Delivery (fee shown)
5. Choose payment     → Cash | UPI
6. Place order        → POST /api/orders
```

- **Address before order creation, always.** Distance, feasibility, fee and ETA all depend on it, and
  a rider order with no drop point is an order nobody can fulfil.
- Self-pickup may omit `delivery`; **rider requires it**.
- `paymentMethod` defaults to `cash` when omitted — send it explicitly.
- Send `idempotencyKey` (a UUID per checkout attempt). v2 honours it: the same key returns the **same
  order**, verified live. Still disable the button on first tap.

### 17.4 What already exists in the app — verify before rebuilding

This part is **more built than the older docs suggest**. Before writing anything new, read:

| File | What it already does |
|---|---|
| `order_find_rider_sheet.dart` | Address → quote → confirm → dispatch, in one sheet |
| `goods_multi_broadcast_searching_screen.dart` | Renders live wave, radius and riders-notified |
| `order_broadcast_controller.dart` | Owns the four `ride:broadcast:*` events |
| `discover_controller.dart` (~line 1862) | The single socket subscription; fans out to the above |

The correct task is **coverage**, not construction: confirm every entry point that can dispatch a
rider reaches a searching UI — the Discover goods flow, the product-service lifecycle card, and the
chat `FIND_RIDER` conversion on a self-pickup order.

> ⚠️ `ChatSocketService.listenEvent` **replaces** any existing handler for an event name. Registering
> a second `ride:broadcast:searching` listener anywhere silently kills the existing one. Route
> everything through `OrderBroadcastController`; never add a competing listener.

---

## 18. The rider — third role in the same app

One app, three roles. The rider's order lives in **rider-service**, not the order services, and has
its own status vocabulary.

### 18.1 Rider order status

```
pending → accepted → payment-pending → confirmed → in-progress → picked-up → completed
                  ↘ rejected        ↘ cancelled  (cancelledBy: rider | customer | system)
```

This is `riderLeg` / `rider.status` in the customer's `/track`. It is a **String** — the app's model
currently calls `_map()` on it, so it is always null (build item 12).

### 18.2 The search, from the rider's side

The server discovers riders in **expanding waves** around the pickup point:

| | |
|---|---|
| Radii | **3 km → 6 km → 10 km** (`BROADCAST_WAVE_RADII_KM`) |
| Window | **20 s per wave** (`BROADCAST_WAVE_WINDOW_MS`) |
| Cap | 15 riders per wave |
| Total life | **60 s**, then the broadcast is exhausted |

Socket events — all four are **already owned** by `OrderBroadcastController`:

| Event | To | Payload | Meaning |
|---|---|---|---|
| `ride:broadcast:incoming` | riders in range | the offer | Show the offer card + countdown |
| `ride:broadcast:searching` | the customer | `{orderId, wave, totalWaves, radiusKm, ridersNotified}` | **The waiting UI's data source** |
| `ride:broadcast:accepted` | the customer | `{riderId, …}` | A partner won — swap to the rider card |
| `ride:broadcast:closed` | **losing** riders | — | Dismiss their offer card. Not a rejection |
| `ride:broadcast:exhausted` | the customer | — | Every round ran, nobody accepted |

**Customer waiting UI**: drive it from `searching` — *"Contacting riders nearby · round 2 of 3 · within 6 km · 7 notified"*. Indeterminate progress only. On `exhausted`, do **not** show failure and do
**not** cancel: offer *Try again* and *Collect it yourself* — the order is still fulfillable.

**Rider offer UI**: an offer is a race. On `closed`, dismiss silently — a partner who lost must never
see "rejected". Never show two live offers at once.

### 18.3 Rider actions

Base `rider-service/riders`.

| Action | Endpoint | Body | Notes |
|---|---|---|---|
| Go online / auto | `GET`·`PUT /auto-golive` | — | Availability gate — offers only reach online riders |
| Incoming offers | `GET /orders/requested`<br>`GET /orders/requested/stream` (SSE) | — | Carries `distanceToPickup`, `distancePickupToDrop` — show both, they decide acceptance |
| Accept / reject | `PATCH /orders/:orderId/status` | `{action: "accept"｜"reject"}` | |
| Claim an open run | `POST /orders/:orderId/claim` | — | **First claim wins** — expect to lose; handle the race, don't crash |
| Grocery accept | `POST /orders/grocery/:rideOrderId/accept` | `{groceryOrderDetails: {businesses: [{businessId, items[]}]}}` | Multi-shop manifest |
| Grocery reject | `POST /orders/grocery/:rideOrderId/reject` | — | |
| **Per-item pickup** | `PATCH /orders/grocery/:rideOrderId/businesses/:businessId/items/:itemId/pickup` | — | Tick items **one at a time** at each counter |
| Pickup (verify) | `POST /orders/:orderId/pickup` | `{pickupOTP}` | 4-digit, **per shop** on multi-stop |
| Deliver (verify) | `POST /orders/:orderId/deliver` | `{deliveryOTP}` | |
| Payment pending | `GET /orders/payment-pending` | — | Prepaid runs awaiting confirmation |
| Confirm payment | `PATCH /orders/:orderId/confirm-payment` | — | → `confirmed` |
| Rate the customer | `POST /customers/:userId/rate` | — | After completion |

Medical mirrors grocery with `/orders/medical/...`.

### 18.4 Rider UI, stage by stage

| Rider state | Screen | Actions |
|---|---|---|
| Offline | Go-live prompt | **Go online** |
| Online, idle | Waiting | Availability toggle · earnings |
| **Offer in** (`incoming`) | Offer card: pickup, drop, **both distances**, fare, **countdown** | **Accept** · **Reject**. Auto-dismiss on `closed` |
| `accepted` | Navigate to shop | Call shop · Navigate · Cancel (with reason) |
| At shop, multi-stop | **Per-shop checklist** | Tick each item, then that shop's OTP |
| `picked-up` | Navigate to customer | Call customer · Navigate |
| At customer | **Delivery OTP** entry | Confirm delivery |
| `payment-pending` | Amount to collect | **Confirm payment received** |
| `completed` | Summary + earnings | Rate the customer |

Hard rules:

- **A stop is not picked up until its OTP verifies.** No "mark all collected" shortcut — that is
  precisely how the wrong package leaves the wrong counter.
- **Multi-stop OTPs are per shop.** Show which shop each code belongs to; never one code for the run.
- `400` on OTP means wrong code **or** wrong state — say *"That code doesn't match"*, then refresh.
- `403` means this rider is not assigned. Leave the screen; do not retry.
- **Never let a client-side button finalise a delivery.** The OTP is the proof.

### 18.5 What the customer sees while the rider works

Purely from `/track` — never from the rider's own state:

| `riderLeg` | Customer sees |
|---|---|
| `not-started` | Searching card (§C0) |
| `accepted` | Rider block: name, **real number**, vehicle, rating |
| `payment-pending` | Rider block + payment row if prepaid |
| `in-progress` / `picked-up` | "On the way" + Track |
| `completed` | Delivered ✓ |
| `cancelled` / `rejected` | **Different copy each**: *"No rider accepted this order"* ≠ *"Order cancelled"* |

### 18.6 One app, three roles

Role is **per order**, not per user — `/actions` returns `actor` for that order, and the same person
is a shop on one order and a customer on another (verified live: Singh Store sells groceries and buys
from Bhupinder's product shop). So:

- **Never cache a global "I am a seller" flag** and use it to pick order UI.
- Rider is the exception: it is a *mode*, gated by go-live, with its own screens and its own service.
- The chat thread is shared. A rider card, an order card and a payment card can all sit in one
  conversation — render each by its `message_type`, never by who you think the viewer is.
