# Order Flow — What Was Built

> **⚠ SUPERSEDED.** This records the v1/v2 round of the order work. The v3 guide
> then changed the contract in several places — `actor` instead of `isOwner`,
> `data.payment.*` instead of `paymentSummary`, GeoJSON coordinates at checkout,
> automatic dispatch instead of a manual ride button. **Current state:
> `ORDER_FLOW_V3_FRONTEND_DONE.md` (same folder).**

> **Companion:** `FLUTTER_ORDER_FLOW_UI_GUIDE.md` (same folder) — the contract this
> implements. Section numbers below refer to it.
> **Scope built:** the full client side of the server-driven order lifecycle, plus
> checkout, payment, refund, delivery-quote and real-time wiring.
> **Verification:** `flutter analyze lib/` → **0 errors**; 66 new tests, all green.

---

## 0. The rule this change enforces

**Flutter no longer decides what a user can do.**

```
backend  → computes the state machine → emits availableActions[]
Flutter  → renders availableActions[] → sends the action back
```

The 24-hour client-side expiry is gone from all three order cards. It used to
disagree with the server's one-hour clock for twenty-three hours at a stretch —
the shop saw a live order, the customer saw a dead one, and neither device was
lying about what it had been told. Order age is now the server's business alone.

An action string this build doesn't recognise renders **nothing**. Never a guess:
a button the server did not offer comes back as a typed `409`.

---

## 1. New files

| File | What it is |
|---|---|
| `chat/auth/model/order_lifecycle_model.dart` | `OrderLifecycle`, `OrderActionsModel`, `OrderDeadlines`, `OrderPaymentSummary`, `OrderCancellationReason`, `DeliveryQuote` + the `OrderAction` / `OrderErrorCode` / `PaymentStateValue` vocabularies |
| `chat/auth/repo/order_lifecycle_repo.dart` | One method per endpoint — all 15 of §9, plus the delivery quote |
| `chat/auth/controller/order_lifecycle_controller.dart` | State per order id, busy flag per *(order, action)*, code-based error branching, refresh sweep |
| `chat/view/business_chat/widgets/order_action_bar.dart` | **The single action renderer** — one switch, no per-card copies |
| `chat/view/business_chat/widgets/order_lifecycle_section.dart` | Banner + countdown + payment sub-state + refund wording + attention strip + action bar |
| `chat/view/business_chat/widgets/order_deadline_countdown.dart` | Countdown driven by `deadlines.*`, never by `createdAt + constant` |
| `chat/view/business_chat/widgets/order_payment_submit_sheet.dart` | QR → UTR + amount + screenshot → `POST /payment/submit` |
| `chat/view/business_chat/widgets/pickup_handover_dialog.dart` | 6-char code, auto-submit, cash checkbox, shake on mismatch |
| `chat/view/business_chat/widgets/pickup_code_screen.dart` | Full-screen mono code, screen kept awake |
| `chat/view/business_chat/widgets/order_reason_sheet.dart` | Reason picker fed from `/actions` — never hard-coded |
| `chat/view/business_chat/widgets/order_prep_eta_sheet.dart` | Prep-time picker for `ACCEPT_ORDER` / `SET_PREP_ETA` |
| `chat/view/business_chat/widgets/order_refund_dialog.dart` | The shop's "I sent the refund" claim + UTR |
| `me/product/model/order_checkout_payload.dart` | `CheckoutAttempt` (idempotency key), `OrderDeliveryDetails`, method/type constants |
| `me/product/view/customer/widget/order_checkout_options_sheet.dart` | The §4.2 checkout sheet: pickup/delivery, cash/UPI, live quote, totals |

## 2. Changed files

| File | Change |
|---|---|
| `core/api/apiService/order_service_api.dart` | 15 lifecycle endpoints as `<service>/api/orders/:id/…` functions; `service` defaults to `product-service`, so grocery/food/medical need only pass a different prefix |
| `core/api/apiService/rider_service_api.dart` | `chatDispatchQuote` |
| `core/api/apiService/chat_service_api.dart` | transaction `pending` / `verify` / `reject` |
| `core/constants/app_constant.dart` | `productOrderLifecycle`, `payment:verified`, `payment:rejected` |
| `chat/auth/model/GetListOfMessageData.dart` | `metadata.lifecycle`; payment-transaction `status`, `order_ref`, `order_service`, `expected_amount`, `amount_mismatch` |
| `chat/auth/controller/chat_view_controller.dart` | `productOrderLifecycle` listener → `patchMessageLifecycle()`; payer-side payment events; `refreshVisibleOrderActions()` on socket reconnect |
| `chat/auth/controller/payment_qr_controller.dart` | `handlePaymentResolved()`; `uploadImageToS3()` exposed for reuse |
| `chat/view/business_chat/business_chat_screen_updated.dart` | `/actions` sweep on `AppLifecycleState.resumed` |
| `product_self_pickup_msg_card.dart` · `self_pickup_msg_card.dart` · `food_self_pickup_msg_card.dart` | 24 h rule deleted; `OrderLifecycleSection` drops in; status badge reads `lifecycle.orderStatus` |
| `payment_transaction_msg_card.dart` | Status-aware wording, paid-vs-due side by side, payee verify/reject |
| `product_selfpickup_controller.dart` | `delivery` + `paymentMethod` + `idempotencyKey`; `refreshDeliveryQuote()` |
| `hmp_cart_controller.dart` · `hmf_cart_controller.dart` | **One idempotency key per store** — the multi-store loop was the duplicate-order hazard |
| `manufacturer` · `automotive` · `grocery` · `food` selfpickup controllers | `paymentMethod` + `idempotencyKey` |
| `product_self_pickup_cart_screen.dart` | Opens the checkout sheet before placing; starts the attempt in `initState` |
| `discover_controller.dart` | `FARE_MISMATCH` / `OUTSIDE_DELIVERY_RADIUS` / 429 handling; `fetchChatDispatchQuote()` |
| `product_order_booking_rider_main.dart` | Confirm/Cancel dialog on a re-priced fare — **never a silent re-submit** |
| `goods_multi_broadcast_searching_screen.dart` | Exhausted race → "No delivery partner available right now" + **Try again** / **Pick it up instead** |

---

## 3. The decisions worth knowing

**Endpoint prefix.** §9b.4 flagged `inventory-service/orders/…` vs
`<svc>/api/orders/…` as *must confirm before writing any Dart*. The new routes use
`product-service/api/orders/:id/…`, because the app **already reaches
`product-service/api/orders` successfully** for order creation — the new routes are
its direct siblings and resolve through the same gateway rewrite. The legacy
`inventory-service/orders/:id/ready` constant is untouched, so nothing that works
today stopped working. **Still worth a staging smoke test before release** (§6).

**Cards render offline-first, then verify.** A card paints its buttons from
`metadata.lifecycle` with no network call; `//actions` is fetched only when a flow
needs authoritative data (cancellation reasons, amount due) or after an error.

**No optimistic updates, anywhere.** Every action waits for the response and
applies the returned `availableActions`. An optimistically-hidden Accept button
that comes back is worse than a spinner.

**Per-button loading.** Busy state is keyed `"<orderId>:<ACTION>"`, so only the
tapped button spins — the other party's updates keep landing on the same card.

**A double-tap is a no-op, not a second request.** `_run()` refuses to start an
action already in flight for that order.

**Errors branch on `code`, never on message text.** `ACTION_NOT_AVAILABLE` is
treated as normal — it means the other party moved first, so it is a refresh cue.

**Legacy flags stay in step.** Each card's `onChanged` mirrors the server status
onto `order_status` / `is_cancelled` so untouched code paths keep behaving.

**One real bug was caught by a test and fixed:** `OrderActionBar`'s `Obx` read no
observable when the action list held only actions that don't consult the busy set
(the call icon, or an unknown string from a newer backend). GetX throws
"improper use of a GetX" rather than rendering — which would have taken the whole
card down over a button we had deliberately chosen not to draw. The builder now
touches `busyKeys` unconditionally.

---

## 4. Wording that is load-bearing

Three strings decide whether this system works socially, not just technically.

**A submitted payment is a claim, not money.** The owner's card says
**"Customer says they paid"**, never "Paid". That single choice is what stops a
shop handing over goods on a screenshot.

**Refunds name who owes the money.** With direct UPI the customer paid the shop's
own VPA — the platform never held a paisa, has no balance to reverse and no
gateway to call. So the copy runs *"₹500 is to be returned by **the shop**"* →
*"the shop says they've sent it"* → *"received"*. It never says "we will refund
you" or "refund processed", which would manufacture a complaint against us for
someone else's inaction. There are tests asserting those two phrasings are absent.

**The shop's "I sent it" does not close the refund.** It is a claim, exactly like
the customer's original screenshot — the same trust model applied symmetrically.
Only `CONFIRM_REFUND_RECEIVED` ends it, and the card does not grey out at step 2.

---

## 5. Tests — 66 new, all passing

```bash
flutter test test/order_lifecycle_model_test.dart \
             test/order_action_bar_test.dart \
             test/order_lifecycle_controller_test.dart \
             test/order_lifecycle_section_test.dart \
             test/order_client_side_rules_test.dart
```

| File | Covers |
|---|---|
| `order_lifecycle_model_test.dart` (19) | Parses the documented block verbatim; role lists never cross; null deadline ≠ expired; unknown status doesn't throw; `{data:…}` and flattened envelopes; reason lists in both shapes; amount mismatch incl. float noise; `feasible:false` is a UI state; absent `feasible` means feasible |
| `order_action_bar_test.dart` (10) | Every action in §2 maps to its documented label; **an unknown action renders nothing**; mixed known/unknown renders only the known; only the tapped button disables; a busy button shows a spinner; terminal orders keep their bar |
| `order_lifecycle_controller_test.dart` (17) | Seeds from a card with no network; won't clobber authoritative state unless forced; remembers the vertical; socket patch replaces (not merges) action lists; busy keys scoped per action; stale-state codes; `CheckoutAttempt` key reuse then rotation; delivery block omits empty keys |
| `order_lifecycle_section_test.dart` (16) | Banner rendered verbatim and no status-derived copy leaks; countdown only when a deadline exists; submitted payment is a claim; paid-vs-due + mismatch on the owner card; rejection reason; cash shows no payment block; all three refund steps incl. the forbidden phrasings; `NEEDS_ATTENTION` hides the internal reason code |
| `order_client_side_rules_test.dart` (4) | **Regression guard:** the three order cards contain no `isMessageOlderThan24Hours` and no `'Order Closed'`, while the rider cards **keep** theirs; all three are wired to `OrderLifecycleSection`; countdown formatting incl. clamping a negative remainder |

Suite-wide: **121 → 187 passing.** The 16 remaining failures and the errors in
`test/rider_document_state_test.dart` are pre-existing and untouched by this work
(verified against a clean tree). `flutter analyze lib/` went from 235 issues to
215; zero are errors.

### Checklist items that need a device or two accounts

The §10 checklist rows below are covered by unit/widget tests
(double-tap, unknown action, stale-state refresh, UTR reuse, amount mismatch,
refund wording, terminal-order buttons, quote warnings). These need real runs:

- Two devices on the same shop account both tapping Accept
- Kill the network mid-action and retry against a live server
- Background for an hour, resume, confirm every open order refreshes
- Force-quit mid-payment, reopen

---

## 6. Open items — read before release

1. **Smoke-test the gateway prefix in staging.** `product-service/api/orders/:id/actions`
   is inferred from the working `POST product-service/api/orders`, not observed. If
   the gateway rewrites differently for the sub-paths, change the one `_orderBase`
   helper in `order_service_api.dart` — every route follows it.

2. **`/actions` response shape is parsed defensively, not from a fixture.** The
   guide gives the `metadata.lifecycle` block exactly (§1.2) but not the `/actions`
   envelope. The parser accepts `{data:…}` or flat, `availableActions` or role
   lists, `cancellationReasons` as objects or bare strings. Once a real response is
   available, confirm `paymentSummary`, `cancellation` and `pickupCode` land where
   expected — a key we guessed wrong fails silently as a missing amount, not as an
   error.

3. **Grocery / food / medical are wired but not enabled.** Their cards pass
   `groceryOrderService` / `foodOrderService` / `medicalOrderService`, and their
   lifecycle section activates the moment the backend starts sending
   `metadata.lifecycle` on those message types. Until then they fall through to
   their legacy rendering, unchanged.

4. **Shop coordinates at checkout.** The delivery quote needs the shop's lat/lng,
   which `cartBusinessInfo` doesn't carry today. The sheet degrades honestly —
   "This shop has not set a location yet", delivery disabled, self-pickup kept —
   rather than showing a broken quote. Add `lat` / `lng` to `cartBusinessInfo` when
   products are added to the cart and delivery lights up with no other change.

5. **`FIND_RIDER` reuses the existing dispatch screen.** The action opens the same
   drop-address sheet → `GoodsMultiOrderBookingMain` flow the old button used. The
   rider leg is unchanged by design (§7); the quote-before-dispatch and
   `FARE_MISMATCH` handling live in `DiscoverController` and are used by the
   chat-dispatch path.

6. **Legacy shortcut row is hidden once the server drives a card.** The old
   Payment / Find Rider icon row still renders on cards with no `lifecycle`. When
   every vertical is ported that row and each card's `_buildActionSection` become
   dead code and can be deleted.
