# Order flow — the three UI boards, screen by screen, against the live contract

> **Source of truth for this document:** the three design boards in this folder —
> `Customer Order Self _ Cash _ UPI.pdf` (12 screens), `Business Side Order Self _ Cash _ UPI.pdf`
> (10 screens) and `Order By Rider.pdf` (22 screens: 10 customer · 4 rider · 8 business) — read
> against `ORDER_LIFECYCLE_FRONTEND_GUIDE.md` (the card contract) and the code as it stands today.
>
> **Companions:** `ORDER_FLOW_V3_FRONTEND_DONE.md` (the machinery), `ORDER_FLOW_REVIEW_FIXES_DONE.md`
> (the three-plane merge), `ORDER_UI_CONDITIONAL_FLOW_DONE.md` (the six corrected facts). Nothing
> here contradicts those; it extends them with what the boards ask for and the contract does not yet
> answer.
>
> **Who this is for:** §5 is the backend team's list — it is the whole reason this file exists. §4 is
> what the app already does after this round. §6 is the app work still outstanding.

---

## 1. The model does not change

The boards do not ask for a new architecture. Every screen in all three is still **one chat card,
re-rendered as `metadata.lifecycle` changes**, with server-authored copy and server-listed actions:

- the backend owns the state machine and emits `customerActions[]` / `ownerActions[]`;
- the app renders the card and calls the action the card offers;
- the app never derives a button, a deadline or a status string from its own clock.

What the boards do is **add states the machine does not have yet**, and **split two moments that the
machine currently fuses**. That is §5.

---

## 2. What the boards actually specify

### 2.1 The step strip is six different strips

Every screen carries a horizontal tracker under the order number. It is not one list — it depends on
who is looking, how the order is collected and how it is paid:

| Viewer | Receive | Pay | Steps, in order |
|---|---|---|---|
| customer | pickup | cash | Order Placed · Waiting for shop acceptance→Shop Accepted · Preparing order · Ready for pickup · Picked up · Completed |
| customer | pickup | UPI | …+ **UPI Payment Pending→Verification→Verified** after acceptance |
| customer | delivery | UPI | …+ **Waiting for Delivery→Delivery Completed** · **Rider Payment Pending→Completed** after Picked up |
| owner | pickup | cash | Order Received · Waiting for Acceptance→Order Accepted · Preparing→Prepared order · Ready for pickup · **Payment Confirmation** · Picked up · Completed |
| owner | pickup | UPI | Order Received · Order Accepted · **Share UPI QR Code→Payment Confirmation→Payment Confirmed** · Preparing Order · Ready for pickup · Picked up · Completed |
| owner | delivery | UPI | Order Received · Order Accepted · Payment Confirmed · **Finding Your Rider→Your Rider Found** · Preparing order · Ready for pickup · Picked up · Completed |

Three things fall out of that table, and each is a real behavioural claim rather than a label:

1. **`Picked up` and `Completed` are two nodes.** The goods moving and the order closing are
   different events, with the shop's *Complete Order* button (or the sweeper) in between.
2. **The owner's cash flow has a payment node of its own, *after* `Ready for pickup`.** Code first,
   money second, goods third. A shop that hands the bag over before collecting has no leverage left.
3. **The owner's delivery flow puts the rider hunt *before* preparing.** The rider rides to the shop
   while the shop packs, instead of afterwards.

Two screens in the boards disagree with each other on ordering (`Your Rider Found` appears both
before and after `Payment Confirmed`). The causal one is authoritative — payment verified → rider
dispatch — and that is what shipped.

### 2.2 Screen → state map

**Customer, self-pickup (cash):**

| Screen | Card state | Card carries |
|---|---|---|
| Review Your Order | pre-order | items · Self Pickup/Book Rider · Cash/UPI · bill (MRP, discount, grand total) · `Place Order ₹X` |
| Order placed | `placed` | strip · full item list · Total/Pickup/Payment rows · **Cancel Order** |
| Preparing | `accepted`/`in-progress` | "Estimated ready time · Ready in 15–20 min" · compact summary · `Cash at Shop · Not Paid Yet` · Cancel |
| Preparing (delayed) | same + overdue | "Updated ready time · 25 min" + amber *"taking longer than the original estimate"* · node reads **Preparing (Delayed)** |
| Ready for pickup | `ready` | shop card + map + distance · **"When you arrive at the shop" 1–5** · code panel locked: *"Pickup code will be available when you arrive"* + `Show Code` · `Pending at Shop` · Contact Shop · Get Direction |
| Pickup code | `ready`, revealed | 4 digits · order no · *"Only share this code with the shop when collecting"* |
| Picked up | `picked-up` | "Pickup Verification Done" · `Cash Payment · Payment Completed` · **Rate your experience** · View Details |
| Completed | `completed` | success block · View Details · Shop Again |
| Cancel sheet | any cancellable | stage-aware subtitle · mini summary · *"No payment has been collected yet."* · **optional** reason radio · Keep/Cancel |
| Cancelled | `cancelled` | red node in the strip · **Cancellation details** table (Cancelled by · Reason · Status · Payment method · Cash collected ₹0) · Continue Shopping |

**Customer, self-pickup (UPI)** adds: Payment Required + **QR with the amount on it** + `Or Pay To ID`
(copyable VPA) + Upload Screenshot → Screenshot Submitted (thumbnail + timestamp + Change Screenshot)
+ "Please wait" → **Payment Screenshot Not Verified** + Re-Upload + Need Help/Contact Shop → Payment
Verified success block.

**Customer, delivery (UPI)** adds, after pickup: Rider Has Arrived (at the shop) → Order Picked Up
(**Call Rider · Track Rider**) → **Delivery Verification** 4 digits shown to the rider → **Rider
Payment Pending** (rider's QR, ₹fee, pay-to-ID) → Completed.

**Owner, self-pickup:** new order (Cancel Order · **Accept**) → preparing (**Update Ready Time** ·
**Mark as Ready**) → **Verify Pickup Code** (4 boxes · Verify & Continue) → **Collect ₹X from
Customer** (*"After receiving the cash, then tap 'Payment Collected'"*) → Pickup Verified ✓ + Cash
Payment ✓ + **Complete Order** → Completed. UPI instead shows **Payment Screenshot Received** (full
screenshot, Reject/Confirm), a **required**-reason Reject sheet (Wrong payment amount · Invalid
screenshot · Payment not received · Screenshot unclear · Other), the rejected state with the reason,
and **Customer Re-shared Payment Screenshot** (Reject Order/Confirm).

**Owner, delivery:** … → Payment Confirmed → **Finding Your Nearest Rider** (waiting block) → **Your
Rider Is Ready** (rider block · Track Rider · **Continue**) → Preparing (rider block pinned) → Verify
Pickup Code *from the rider* → Picked up → Completed.

**Rider:** offer card (pickup/drop distance · travel distance · fare · Reject/**Accept**) → assigned
(**Pick-Up OTP shown** · Go to Pick Up · Drop Direction · customer Call · **Delivery OTP entry** ·
fare) → in progress (Waiting Time · Emergency Call · swipe to complete) → completion sheet (**the
rider's own QR** — *"Show this QR to <customer> to confirm your payment"* — plus a 5-star rating and
a short review).

---

## 3. What already exists, and is correct

Verified in code, not assumed. None of this needed rebuilding:

- server-driven action bar (unknown key → renders nothing), `actor`-based role split, per-button busy
  keys, 3-button cap with overflow;
- the whole UPI track: QR + VPA + amount, S3 upload → `payment/submit {utrNo, screenshotUrl,
  amountPaid}`, owner verify/reject with amount-vs-due comparison, re-upload, *"says they paid"*
  wording that never reads as "paid";
- reason sheets from `cancellationReasons`, degrading to a required free-text note submitted as
  `OTHER`;
- the pickup-code handshake (`GET /:id/pickup-code`, `POST /:id/handover {code}`) with the shake on a
  mismatch;
- deadline countdowns in bands off `deadlines.*`, one app-wide ticker;
- `needsAttention`, refund block surviving terminal, offline strip;
- checkout: address-first, quote on a real coordinate, `feasible:false` handled as the 200 it is,
  fee-exceeds-basket pre-selecting pickup, GeoJSON `[lng, lat]` on create;
- rider availability precheck (`GET /rider-service/fare/chat-dispatch/availability` on the **shop's**
  coordinates) gating the delivery choice, and the "no rider found" card that offers self-pickup
  without using the word "cancelled";
- the rider app's own order tab: offer, claim, per-shop pickup OTP, delivery OTP, fare, emergency
  call;
- `PendingOrderChip` on Discover, so a ready order is visible outside the conversation.

---

## 4. What this round changed in the app

| # | Change | Files |
|---|---|---|
| 1 | **The step strip**, all six variants, derived from the lifecycle the card already has (so it draws with no network call) and replaceable by a server `stages[]` list | `chat/auth/model/order_journey.dart` *(new)*, `chat/view/business_chat/widgets/order_journey_strip.dart` *(new)*, wired as zone ①b in `order_lifecycle_section.dart` |
| 2 | **Delivery is UPI-only.** Cash is absent (not greyed) on a doorstep order, a cash choice made before picking delivery is moved to UPI, and the invariant is enforced again where the order is created | `me/product/view/customer/widget/order_checkout_stepper_sheet.dart` |
| 3 | **Rider dispatch now fires on a verified payment**, not on `ready` — so the rider rides while the shop packs. Never on an unpaid order, never before acceptance, never twice, and cash/unknown-method orders keep the old `ready` trigger | `order_lifecycle_model.dart` (`needsRiderDispatch`) |
| 4 | New lifecycle fields parsed tolerantly and merged field-wise: `pickupVerifiedAt` · `cashCollectedAt` · `riderPaymentState` · `riderPaymentAmount` · `prepDelayed` | `order_lifecycle_model.dart` |
| 5 | New statuses in the vocabulary: `picked-up` · `delivered` | `order_lifecycle_model.dart` |
| 6 | New actions wired end to end (endpoint → repo → controller → button): `COLLECT_CASH` *Payment collected* · `COMPLETE_ORDER` *Complete order* · `START_PREPARING` *Start preparing*. `PAY_RIDER` and `RATE_ORDER` are named but deliberately **not** rendered yet — see §6 | `core/api/apiService/order_service_api.dart`, `chat/auth/repo/order_lifecycle_repo.dart`, `chat/auth/controller/order_lifecycle_controller.dart`, `chat/view/business_chat/widgets/order_action_bar.dart` |
| 7 | 24 step-label strings + English copy | `core/constants/app_strings.dart`, `assets/translations/en.json` |
| 8 | **"When you arrive at the shop"** — the numbered block, conditional on how the order is paid (no "pay in cash" line on a UPI order), plus the locked code panel. Customer side, self-pickup, `ready` only | `order_lifecycle_section.dart` |
| 9 | **The rider-fee block**: fee, a QR generated from the rider's VPA **with the amount written into the link**, and a long-press-to-copy VPA. Renders only when the server sent a VPA — never an empty frame. A `submitted` fee reads as a claim, never as settled | `order_lifecycle_section.dart`, `upi_qr_widget.dart` (`amount` on `upiQrPayload`) |
| 10 | **The cancellation details table** (cancelled by · reason · status · payment method · money). The money row is dropped when a refund is in play, because the refund block already owns that number — one money line per card | `order_lifecycle_section.dart` |
| 11 | `riderPayment.upiId` / `payeeName` parsed alongside state and amount | `order_lifecycle_model.dart` |
| 12 | 64 tests: the six variants, every live-node rule, delay, cancellation placement, unknown statuses, server-stage override, all eight dispatch-timing cases, and every claim the three new blocks make to a person | `test/order_journey_test.dart`, `test/order_card_blocks_test.dart` *(both new)* |

Every one of these is backward-safe: an order whose backend sends none of the new fields resolves to
exactly today's behaviour, and a status this build does not recognise draws **no** strip rather than
a wrong one.

---

## 5. Backend gaps — the list

Ordered by what blocks the most screens. Field names are proposals; what matters is that one name
exists and the app is told which.

### 5.1 `picked-up` as a status, and `COMPLETE_ORDER` — blocks 6 screens

`POST /:id/handover` currently goes straight to `completed`. The boards need the middle state:

```
ready ──handover(code)──▶ picked-up ──COMPLETE_ORDER | sweeper──▶ completed
```

- add `orderStatus: "picked-up"`;
- add `POST /:id/complete` (owner) → `completed`;
- **auto-complete**: a `picked-up` order closes itself after a grace window (proposal: 30 min) via
  the existing 60 s sweep. This is the *"otherwise backend some mints auto complete"* requirement —
  it must be server-side, because the shop's app may never be opened again.

### 5.2 Cash collection as its own step — blocks 3 screens

- add `POST /:id/payment/collect-cash` (owner, cash only, after the code matched) `{ amountCollected? }`;
- add `lifecycle.pickupVerifiedAt` and `lifecycle.cashCollectedAt` (or `paymentState: "collected"`);
- offer `COLLECT_CASH` in `ownerActions` between the code matching and the goods moving.

Today `POST /:id/handover {code, collectedCash}` fuses both moments, so the owner's card cannot show
*"Collect ₹600 from Customer"* as a step of its own — and the amber *"After receiving the cash, then
tap 'Payment Collected'"* has nowhere to live.

### 5.3 The rider-fee leg — blocks 3 screens, and it is the biggest one

The boards settle a question the current contract answers differently: **the shop's QR is charged the
product total only, and the delivery fee is settled with the rider at the door, against the rider's
own QR.** The rider's completion sheet shows that QR; the customer's card shows `Rider Payment
Pending` with the fee and a pay-to-ID.

Needed:

- `lifecycle.riderPayment = { state: "pending|submitted|paid", amount, upiId, qrUrl, payeeName }`;
- `orderStatus: "delivered"` — goods handed over, fee outstanding — between `dispatched` and
  `completed`;
- the rider confirming receipt (rider-service `confirm-payment` already exists for the goods flow —
  confirm whether it moves this leg) → `riderPayment.state: "paid"` → order `completed`;
- **the fee must be the checkout quote, re-verified server-side, never recomputed on the client.**
  The customer agreed to a number; a different number at the door is a dispute.
- the sweeper needs a rule for a delivered order whose fee is never settled (reminder → flag; it must
  **not** silently complete, and it must not reopen the delivery).

### 5.4 Dispatch before preparing — 4 screens

The app now dispatches on `paymentState: verified`. For the owner's card to say *"Finding Your
Rider"* and then *"Your Rider Is Ready"*, the service needs:

- `POST /:id/start-preparing` (owner) → `in-progress`, offered as `START_PREPARING` **only once a
  rider is assigned** on a doorstep order;
- `rideOrderId` (or a rider block) on the card as soon as the race is won — it is already stamped by
  `ConvertOrderToRider`; confirm it reaches `metadata.lifecycle`, not just `/track`;
- `deadlines.dispatchBy` measured from **payment verification**, not from `ready`.

### 5.5 Prep-time nudges keyed to the shop's *average* — the user's explicit ask

Today `deadlines.readyBy` is a fixed window and the sweeper escalates against it. The ask is that the
nudge fires when the shop crosses **its own average preparation time** for that vertical/category,
not a constant:

- keep a rolling per-shop average (accept → ready);
- fire a customer-facing revision and an owner nudge when the order crosses it;
- expose `lifecycle.prepDelayed: true` so the strip can read **Preparing (Delayed)** without the app
  inferring lateness from a lapsed `readyBy` (the app has that fallback, and it is a fallback);
- the same shape applies to the acceptance window (`acceptBy`) and to the owner sitting on a verified
  payment without preparing.

### 5.6 Walking-time tracking after `ready` — new, entirely server-side

*"backend track user home address or owner address then calculate average normal human walking time,
if cross time give notification, also show in card delayed pickup"*:

- on `ready`, compute the customer→shop travel time from the **saved address** on the order and the
  shop's coordinates (no live location, no new permission — a permission prompt at the moment
  someone is walking to a shop is worse than a slightly wrong estimate);
- set `deadlines.pickupBy = readyAt + travelTime + grace`;
- escalate in bands: reminder → *"delayed pickup"* banner → owner action → hard expiry. The card
  already renders whatever `banner` says and already counts `pickupBy` **up** past zero in amber, so
  **no app change is needed for this** beyond the copy the server sends;
- friendly, non-accusing copy at each band, and a cap on repeats per order. The user asked for
  *"push again and again"* — repetition has to be bounded or it becomes the reason notifications get
  turned off.

### 5.7 Ratings — 3 screens

- `POST /:id/rate` `{ shopRating, shopReview?, riderRating?, riderReview? }`, idempotent per party;
- offer `RATE_ORDER` in `customerActions` on `picked-up` and `completed`;
- on a delivery order the response must say **both** parties are ratable — the boards ask the
  customer to rate the shop *and* the rider, and the rider to rate the ride.

### 5.8 Smaller, but each one is a visible screen

| Gap | Why |
|---|---|
| `lifecycle.pickupCodeUnlockedAt` (or nothing at all) | The board's resting state is *"Pickup code will be available when you arrive"* with a `Show Code` link beside it. Treat it as **copy, not a geofence**: a customer with GPS off or permission denied must still be able to collect. If a real gate is ever wanted, it has to be server-evaluated and always overridable. |
| Cancellation detail block | The cancelled card is a table: cancelled by · reason · status · payment method · **cash collected ₹0**. `cancellation.{cancelledBy,reasonCode,comment}` exists; the money line needs `amountCollected: 0` stated rather than inferred. |
| Reject-payment reason list | The owner's reject sheet is a **required** pick list (5 options). The service does not scope payment-rejection reasons, so the app renders free text today. Either ship `paymentRejectionReasons[]` on `/actions` or confirm free text is final. |
| Cancel-reason optionality | The customer's cancel sheet marks the reason **optional**; the shop's reject sheet marks it **required**. `POST /:id/cancel` currently refuses a missing `reasonCode`. Confirm which side is right. |
| Shop `lat`/`lng` on the cart's business block | Still the single highest-value unblock: without it the checkout's delivery half is unreachable in practice, so flow ③ cannot be exercised at all. Open since the v3 round; the data exists in `business.proto` / `inventory.proto`. |
| Push labels | Each new state needs a label the app already routes: `selfpickup_order_picked_up`, `selfpickup_order_completed`, `order_cash_collected`, `order_rider_payment_pending`, `order_pickup_delayed`. Unknown labels fall through to "open the conversation", which is a working but silent fallback. |
| Socket | The existing `productOrderLifecycle` carries all of this — no new event is needed, provided the new fields ride on the same card. |

---

## 6. App work still outstanding

Stated plainly, because a board item silently skipped is worse than one openly deferred.

1. **The rating sheet** (5 stars + short review; shop **and** rider on a delivery order). Waiting on
   §5.7 for the endpoint — the entry point is `RATE_ORDER`, the action key is reserved, and it is
   deliberately **not** rendered until there is somewhere to send a rating. A star row that silently
   discards the tap is worse than no star row.
2. **Track Rider** from the order card. Noted as deliberately-not-built in the conditional-flow
   round because the app has no order-rider tracking surface to send it to; the boards now show it
   twice (customer after pickup, and the owner watching the rider come to the shop), so it needs a
   destination — `OrderTrackRider.hasLocation` is already in place for whoever builds it.
3. **`deliveryType` on the card context**, so a doorstep order draws the delivery strip on the very
   first frame. Today it resolves from the server's `deliveryType` and falls back to the pickup strip
   until `/actions` or `/track` has answered once.
4. **The rider's completion sheet showing its own QR** (board: rider side). The rider app's order tab
   is otherwise coverage-complete; this one tile needs the same `riderPayment.upiId` from §5.3, read
   from the rider's end.

The rider-fee block and the two self-pickup blocks that were listed here are done — see §4 rows 8–11.
They render only when the server sends the fields, so they are inert until §5.3 ships and correct the
moment it does.

---

## 7. How to verify a flow end to end

Per flow, on staging, with two accounts and (for ③) a rider:

**① Self-pickup · cash** — place → shop accepts → strip shows *Preparing* → let the ETA lapse and
confirm *Preparing (Delayed)* → Mark as Ready → customer taps Show Code → shop enters it → shop
collects cash → shop completes → both cards read Completed, and the strip has six green nodes.
Then repeat, cancelling at each of `placed` / `accepted` / `in-progress`, and confirm the red node
lands in a different place each time.

**② Self-pickup · UPI** — as above, plus: pay → submit screenshot → shop rejects with a reason →
customer re-uploads → shop confirms → *Payment Verified* → the rest of ①. Confirm the amount on the
QR is the product total and that a `submitted` payment never reads as "paid" on either card.

**③ Delivery · UPI** — cart → address → confirm **cash is not offered** → quote → place → shop
accepts → pay + verify → confirm the **rider hunt starts now, while the shop is still packing** →
rider accepts → owner sees the rider and taps Continue → Mark as Ready → rider's PIN into the shop's
keypad → out for delivery → customer's PIN into the rider's app → *Rider Payment Pending* at the
**checkout fee, to the penny** → rider confirms → Completed → both ratings offered.
Then the unhappy paths: no rider in the area (blocked at checkout), no rider accepts (self-pickup
fallback, and the word "cancelled" must not appear), rider cancels after accepting, and a rejected
payment on an order a rider was already hunting for.

**Always** — kill the app at every state and reopen: the card must come back identical, because it
renders from `metadata.lifecycle`. That single check catches more than the rest combined.
