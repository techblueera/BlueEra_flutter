# Order Flow v3 — what the frontend now does

> **Companion:** `FLUTTER_ORDER_FLOW_UI_GUIDE.md` (v3) — the spec this implements.
> Section numbers below are that guide's.
> **Supersedes:** `ORDER_FLOW_IMPLEMENTATION_COMPLETE.md` and
> `FLUTTER_ORDER_FLOW_CLIENT_CONTRACT.md`, which record the v1/v2 round. Where they
> disagree with this file, this file is current.
>
> **Verification:** `flutter analyze lib` → **0 errors** (213 pre-existing warnings /
> infos, unchanged). `flutter test` → **245 passing**, up from 187; the 16 failures
> are the same pre-existing ones in `discover_folder_tile`, `doctor_card_layout`,
> `feed_card_render`, `search_result_card`, `vehicle_number` and
> `rider_document_state`, none of which this work touches.

---

## 0. The seven causes, and what each one is now

The guide opened with seven verified reasons the app looked static while the backend
was already sending everything it needed. All seven are closed.

| # | The app used to | It now | Where |
|---|---|---|---|
| **1** | look for `isOwner` / `role`, which the service never sends → always null → **both parties saw the same buttons** | reads **`actor`** (`customer`\|`owner`\|`admin`), and asks `/actions` on mount when a card has never been told | `order_lifecycle_model.dart`, `order_lifecycle_section.dart` |
| **2** | parse `paymentSummary`, a key that does not exist → **blank amounts everywhere** | reads **`data.payment.*`**, and hydrates it from `/track` because `/actions` carries no money at all | `order_lifecycle_model.dart`, `order_lifecycle_controller.dart` |
| **3** | push a full-screen rider-booking flow from a card button, re-asking for an address the order already had | **decides delivery at checkout** and dispatches automatically at `ready`; the only remaining `FIND_RIDER` is an in-card text link for a self-pickup change of mind | `order_checkout_stepper_sheet.dart`, `order_broadcast_controller.dart`, `order_find_rider_sheet.dart` |
| **4** | capture `wave` / `radiusKm` / `ridersNotified` and render them on one unrelated screen | renders the **live search inside the card** — radar, rounds, cumulative count, one 60 s countdown | `order_broadcast_search_section.dart` |
| **5** | unwrap `{data: …}` and return the inner map, losing `warning` | reads `warning` from the **response root, before unwrapping** | `OrderActionsModel.fromJson` |
| **6** | send `delivery: { latitude, longitude }` flat → **every doorstep order 400'd** | sends `delivery.location.coordinates = [lng, lat]`, GeoJSON, lng first | `order_checkout_payload.dart` |
| **7** | expect to attach the quote after creation, via an endpoint that does not exist | sends `distanceKm` / `feeEstimate` / `etaMinutes` **inside `delivery` on create** | same |

Smaller ones from the same section: `PUT /ready`'s **bare-order** envelope parses, and
`cancellationReasons` as **bare strings** humanise to `Item unavailable`.

---

## 1. New files

| File | What it is |
|---|---|
| `core/theme/order_design_tokens.dart` | The design system (§3): `OrderSpace` · `OrderRadius` · `OrderType` · `OrderTone` · `OrderMotion`, plus `OrderStatusDot`, `OrderMoneyRow`, `OrderCardSkeleton`, `OrderZoneDivider` |
| `chat/auth/controller/order_broadcast_controller.dart` | Automatic dispatch + the live-search state model (`BroadcastSearch`, `BroadcastRound`) + the 3 s safety poll |
| `chat/view/business_chat/widgets/order_broadcast_search_section.dart` | **Zone ③** — the visible rider search, and the honest dead end when nobody accepts |
| `chat/view/business_chat/widgets/order_find_rider_sheet.dart` | The self-pickup "Can't come? Get it delivered" flow — address → quote → dispatch, **in-card** |
| `me/product/view/customer/widget/order_checkout_stepper_sheet.dart` | The five-step checkout (§5), replacing `order_checkout_options_sheet.dart` (deleted) |
| `test/order_v3_contract_test.dart` | 47 tests: the contract, plane by plane |
| `test/order_broadcast_section_test.dart` | 10 tests: the live block's two honesty rules |

## 2. Rewritten

| File | What changed |
|---|---|
| `chat/auth/model/order_lifecycle_model.dart` | `actor`; `data.payment.*`; root `warning`; bare-order envelope; `deliveryType`, `delivery` (GeoJSON read-back), `rideOrderId`, `needsAttention` as bool **or** `{flagged}`, `isTerminal`, `orderNumber`, `grandTotal`; `dispatchBy` / `deliverBy`; `suggestion` (`SELF_PICKUP_FALLBACK`); the full error-code vocabulary with `isStaleState` / `isFieldLevel`; `DeliveryQuote` gains `reason`, `maxDistanceKm`, `breakdown`, `riderPayout`, `peak` |
| `chat/view/business_chat/widgets/order_lifecycle_section.dart` | The six zones (§4): identity tail · status · live · detail · actions · footnote |
| `chat/view/business_chat/widgets/order_deadline_countdown.dart` | The §8.1 bands, and **one `OrderClock` ticker for the whole app** instead of one timer per card |

## 3. Changed

| File | Change |
|---|---|
| `chat/auth/controller/order_lifecycle_controller.dart` | State **merges** rather than replaces; `refreshTrack` / `ensurePayment` for Plane C money; `actorIsOwner`; the §10.1 error switch |
| `chat/view/business_chat/widgets/order_action_bar.dart` | Priority ordering + a 3-button cap with a `⋯` overflow; `FIND_RIDER` demoted to a text link; context carries `businessId` / `selfpickupType` / `orderFor`; success haptic; `warning` surfaced |
| `product_self_pickup_msg_card` · `self_pickup_msg_card` · `food_self_pickup_msg_card` | `_findRiderFromCard` no longer navigates anywhere; dispatch inputs added to the card context |
| `common/Discover/controller/discover_controller.dart` | The three `ride:broadcast:*` handlers fan out to the cards; chat-dispatch now sends `orderType: "broadcast"` with **no** `selectedRiders` |
| `me/product/model/order_checkout_payload.dart` | GeoJSON `location`; `hasCoordinates` as the checkout gate; `copyWithQuote` |
| `me/product/controller/product_selfpickup_controller.dart` | `placeProductOrderApi` returns the server's error **code** so the cart can act on `DELIVERY_LOCATION_REQUIRED` |
| `product_self_pickup_cart_screen.dart` | Opens the stepper; reopens it on `DELIVERY_LOCATION_REQUIRED` |
| manufacturer · automotive · food · grocery · hmp · hmf carts | `paymentMethod` is now a real choice rather than a hard-coded `cash`; each opens the stepper with `allowDelivery: false` |
| `order_payment_submit_sheet.dart` | Hydrates the amount due from `/track`; the amount shown is never a guess |
| `pickup_handover_dialog.dart` | Heavy haptic with the shake on a wrong code |

---

## 4. How each part behaves now

### 4.1 Role (§1 rule 3, §2.2)

`actor` is the only answer to "whose buttons are these". A card seeded from
`metadata.lifecycle` has not been told yet, so on mount — and only for an order the
server is actually driving — it asks `/actions` once. Until that lands it falls back to
`myMessage`, which is a guess and is labelled as one in the code. A legacy card with no
lifecycle **never** asks: its id may not be a lifecycle order at all, so the call could
only 404.

`actor: "admin"` gets `ADMIN_OVERRIDE`, which has no case in the action bar's switch and
therefore renders nothing — the consumer build stays read-only plus call buttons (§10.4).

### 4.2 Money (§2.3, §2.4)

All money is `data.payment.*` on an action response or `/track`. `/actions` has none.
That asymmetry is why the controller **merges** instead of replacing: a plain refresh
would otherwise erase the payment block an action response had just delivered. A
response that describes no state at all — the bare `{pickupCode}`, a
`{success:true}` — cannot blank a live card either.

`warning` is read from the response root before the `data` unwrap, so the amount-mismatch
note actually appears, as an amber note on a **success**.

### 4.3 Checkout (§5)

Five steps, each a gate: Method → Address → Quote → Payment → Review. The gate that
matters is the address one — `Continue` stays disabled until latitude **and** longitude
both exist, because a typed address is useless to both the order gate and the rider
search. No saved address opens the picker immediately rather than showing an empty state
with one dead tap. The quote fires 400 ms after a coordinate exists and refires on
change; while it is in flight the fee row is a skeleton, never ₹0 corrected a moment
later.

`feasible: false` is treated as the 200 it is: delivery disabled, the server's `message`
shown, pickup offered. An **absent** `feasible` means feasible. A fee that exceeds the
order value warns and offers "Pick it up instead" — and never blocks.

A vertical whose service cannot take a doorstep order (or a shop with no location) skips
the delivery steps entirely rather than showing a greyed-out choice.

### 4.4 Delivery, automatic and visible (§7)

A doorstep order dispatches **itself** the moment the card turns `ready` with no ride
attached. No button. The drop point comes off the order — hydrated from `/track` if the
card has only ever seen `metadata.lifecycle` — and the shop's point is resolved from its
business profile the same way the old manual flow did. Only the customer's device
dispatches; two devices racing would serve nothing.

`POST /fare/chat-dispatch/orders` now sends **`orderType: "broadcast"` with no
`selectedRiders`**. A `429` from the 3-minute duplicate guard is treated as success —
a dispatch is already running.

The live block builds everything from the four fields on `ride:broadcast:searching` plus
our own dispatch timestamp: radar radius, round N of M, an appended timeline, a
cumulative count, and **one** 60 s countdown that does not restart per round. It obeys
both honesty rules — no invented denominator ("9 partners called", never "9 of 23"), and
`ridersNotified: 0` reads *"Widening the search…"* with a round row saying *"none
nearby"*, never "0 partners called".

`ride:broadcast:exhausted` produces the §7.6 card: *"No delivery partner found — your
order is packed and waiting at the shop"* with **Try again** and **Collect it myself**.
It is not a cancellation and does not use the word.

> **Why the listeners live in `DiscoverController`.** `ChatSocketService.listenEvent`
> *removes* any existing handler for an event name before registering. A card
> subscribing to `ride:broadcast:searching` would therefore have silently killed the
> multi-shop screen's subscription. So the three existing handlers stay where they are
> and fan every payload into `OrderBroadcastController` **before** their own
> fare-call staleness filter — which only knows about that one screen's order.

### 4.5 The card (§3, §4, §8, §9, §10)

Six zones that appear and disappear without moving. The banner is server text rendered
verbatim, cross-faded on change. Exactly one deadline chip per state, in the §8.1 bands,
counting **up** in amber past zero and never flipping the card to terminal. Reminders
change the banner and nothing else. `needsAttention` is a neutral strip on both cards
with the reason code never exposed. Offline dims the actions, keeps the last known state
on screen — it came from local metadata — and offers one Retry.

Actions are ranked primary → secondary → destructive → icon, capped at three with a `⋯`
overflow; call buttons never count against the cap, because a call button folded into a
menu is a call that does not get made. An unknown action renders nothing, in the bar and
in the menu.

---

## 5. Decisions worth knowing

**Merging, not replacing.** Three planes carry different subsets of the truth. The
controller keeps a union and lets each response overwrite only what it actually spoke
about. Two bugs fell out of getting this wrong in testing, both fixed here.

**One ticker, app-wide.** `OrderClock` runs a single `Timer.periodic(1s)` that starts
with its first listener and stops with its last. A chat screen with a dozen order cards
gets one timer, and every countdown ticks on the same frame.

**A pulsing dot that never pulses builds no ticker.** `OrderStatusDot` holds a nullable
controller. The obvious `late final` version constructs an `AnimationController` inside
`dispose()` for every resting dot — which throws while the element tree is being torn
down. A widget test caught it; it would have crashed real cards.

**No optimistic updates, still.** Every action waits for the response and applies the
returned `availableActions`. `ACTION_NOT_AVAILABLE` is a refresh cue, not a failure.

**Per-button loading, per-order guards.** Busy state is keyed `"<orderId>:<ACTION>"`, so
a double tap is a no-op rather than a second request, and only the tapped button spins.

---

## 6. What I did **not** build

Stated plainly, because a guide item silently skipped is worse than one openly deferred.

1. **No draggable map pin at the address step.** §5.2's mockup shows a map with a pin
   that is "the truth". The step reuses the existing address sheet — saved addresses,
   current location, Google suggestions — which does produce a real coordinate, and the
   gate enforces one. What is missing is the map view and the drag-to-adjust. Everything
   downstream of the coordinate is complete.

2. **Delivery is offered only where the app knows the shop's coordinates.** The cart's
   `cartBusinessInfo` still carries no `lat`/`lng`, so the product cart shows *"This shop
   has not set a location yet"* and keeps pickup rather than showing a broken quote. Add
   those two keys when products enter the cart and delivery lights up with no other
   change. **This is the single highest-value unblock left.**

3. **Grocery, food and medical checkouts pass `allowDelivery: false`** by design: their
   services do not take doorstep orders yet. Their **cards** are fully wired and will
   render the live search the moment their service emits `metadata.lifecycle` and
   accepts a rider order.

4. **The manual rider-selection screen still exists** (`ProductOrderBookingRiderMain`,
   `GoodsMultiOrderBookingMain`). No order card reaches it any more; the legacy shortcut
   row on cards with **no** `lifecycle` still does, deliberately, since those orders have
   no server-driven path at all. Both become dead code once every vertical is ported.

5. **The rider leg past assignment is untouched** (§7.5) — `rider_details_msg_card`,
   `rider_otp_msg_card`, `rider_live_location_msg_card`, the tracking page. They already
   work and the guide does not ask for changes.

---

## 7. Tests

```bash
flutter test test/order_v3_contract_test.dart \
             test/order_broadcast_section_test.dart \
             test/order_lifecycle_model_test.dart \
             test/order_action_bar_test.dart \
             test/order_lifecycle_controller_test.dart \
             test/order_lifecycle_section_test.dart \
             test/order_client_side_rules_test.dart
# 125 passing
```

| File | Covers |
|---|---|
| `order_v3_contract_test.dart` (47) | `actor` for all three roles and its absence · `data.payment.*` incl. the ±₹1 tolerance · root `warning` · the bare-order and pickup-code envelopes · bare-string reasons · **GeoJSON `[lng, lat]`** and the quote riding inside `delivery` · the auto-dispatch trigger's four cases · the counting model (cumulative, append-only, zero-is-an-answer, one 60 s window) · `feasible:false` vs absent · breakdown rows · `dispatchBy`/`deliverBy` · sweeper states · error-code families · merge safety |
| `order_broadcast_section_test.dart` (10) | The block renders only while something happens · cumulative count · **no invented denominator** · `0` reads "widening the search" · the appended timeline · pinned fee/ETA · exhausted is not a cancellation and does not say "cancelled" or "failed" · assignment collapses the zone |
| `order_lifecycle_section_test.dart` (16) | Banner verbatim, no status-derived copy · countdown only when a deadline exists · a submitted payment is a claim · paid-vs-due · refund wording, all three steps, with the forbidden phrasings asserted absent · terminal orders keep their buttons |
| `order_action_bar_test.dart` (12) | Every documented label · unknown action renders nothing · the 3-cap and what the `⋯` menu carries · per-button busy state |
| `order_lifecycle_controller_test.dart` (17) | Seeding, socket patching, busy keys, stale-state codes, checkout-attempt key lifecycle |
| `order_lifecycle_model_test.dart` (19) | The v1/v2 parsing contract, still green — the tolerant parsers did not regress |
| `order_client_side_rules_test.dart` (6) | **Regression guard:** no `isMessageOlderThan24Hours` in the three order cards, while the rider cards keep theirs · countdown bands · overdue counts up |

### Needs a device or two accounts

- Two devices on one shop account both tapping **Accept**
- Customer cancels while the shop accepts
- A doorstep order reaching `ready` and dispatching with no tap
- The radius actually walking 3 → 6 → 10 against a live broadcast
- Kill the network mid-action, retry
- Background an hour, resume, confirm every open order refreshes
- Force-quit mid-payment, reopen

---

## 8. Before release

1. **Ship a doorstep order end to end on staging.** Cause 6 means no doorstep order has
   ever been created successfully from the app; the GeoJSON fix is verified by test, not
   by a live `201`.
2. **Add `lat` / `lng` to `cartBusinessInfo`** (§6 item 2) — without it the delivery
   option stays hidden in the product cart, and the whole checkout stepper's delivery
   half is unreachable in practice.
3. **Confirm the dispatch response names the ride order id.** The controller reads
   `data.orderId` / `_id` / `id`; if the field is called something else, the socket still
   finds the search when exactly one is running, but the 3 s poll stays idle.
4. **Watch the `/actions`-on-mount call.** One request per server-driven card on screen.
   Deduped per order and skipped once `actor` is known, but a chat with many open orders
   will fan out on first open.

---

## 9. Round two — the client-contract review

`ORDER_FLOW_CLIENT_CONTRACT_REVIEW.md` read both codebases line by line after this work
landed. It found one P0 (backend, fixed there) and three client-side misses. All three are
done, and implementing them surfaced two more bugs of the same family.

**The family:** `/track` and `/actions` each answer a *subset* of what an action response
answers, under partly different names. The store keeps a union of the three planes, and it
was treating "this payload did not mention the key" as "the key is now empty".

| What was wrong | Now |
|---|---|
| `/track` answers **`viewerRole`**, not `actor` — so a model built from a track response had no role and everything downstream fell back to the card's `myMessage` guess | both keys accepted; `actor` wins where both appear |
| `/track`'s `needsAttention` object has **no `flagged` key** (it is `null` when not flagged), so the test for `flagged == true` was always false and the *"We're looking into this order."* strip never appeared from a track refresh | on `/track` the object's **presence** is the flag; an explicit `flagged: false` is still honoured as "no" |
| `/track`'s `paymentSummary` carries **no refund fields**, so a cold refresh dropped a card from *"the shop says it sent ₹500"* back to *"the shop owes you ₹500"* — that distinction is `refundInitiatedAt` | payment summaries merge **field-wise**; a key the newer payload did not mention keeps the value we had |
| **`/actions` carries no `banner`** — a refresh blanked the card's server-authored status line and fell back to the "Order update" placeholder | lifecycles merge field-wise too; action lists still **replace**, since every payload that carries them carries the complete set |
| **`/actions` never mentions `refundDue`** — its silent `false` cleared a `true` the socket had delivered, so the refund block vanished on the next app resume | `refundDue` is only taken from a payload that actually stated it (`refundDueStated`) |

The P0 was backend-side — `cancellationReasons` came back `[]` for a shop looking at a
brand-new order, the one state where `REJECT_ORDER` is the entire point. The app already
degraded correctly (an empty list becomes a required free-text note submitted as `OTHER`,
which is in the server's `OWNER` list), so nothing needed changing here — but that
behaviour is now pinned by a widget test rather than left to luck.

**Tests:** `test/order_track_contract_test.dart`, 17 of them, one per finding plus the
merge cases. Suite: **263 passing**, up from 246; `flutter analyze lib` → 0 errors.

**Still open, and both are cheap:** shop `lat`/`lng` on the cart's business block — the
review confirms the data already exists in `business.proto` / `inventory.proto` and just
needs threading through, and it is the one thing gating the delivery half of checkout in
practice; and a smoke test of *shop declines a new order* once the backend fix deploys.
