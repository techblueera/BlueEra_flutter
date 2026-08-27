# Order UI — conditional flow round: what changed

> **Spec:** `ORDER_UI_CONDITIONAL_FLOW_GUIDE.md` (verified against live production
> `https://be.beapp.in/api` on 27 Aug 2026). Section numbers below are that guide's.
> **Supersedes on facts:** `ORDER_CHAT_AND_STEPS_UI_EDGE_CASES.md` §7 and
> `GROCERY_SELF_PICKUP_ORDER_UI_AUDIT_AND_GUIDE.md`, which are wrong on the four points in §12.
> **Does not supersede:** `ORDER_FLOW_V3_FRONTEND_DONE.md`. That round built the machinery; this
> round corrects six facts it was built on.
>
> **Verification:** `flutter analyze lib test` → **0 errors in any touched file** (234 issues, all
> pre-existing warnings/infos; the only 20 errors are in `test/rider_document_state_test.dart`,
> untouched here and already a known failure). `flutter test` → **368 passing**, and the 16 failures
> are the same pre-existing ones in `discover_folder_tile`, `doctor_card_layout`, `feed_card_render`,
> `search_result_card`, `vehicle_number` and `rider_document_state`. The order suite is **247
> passing, 0 failing**, up from 226.

---

## 0. What this round was, and was not

§14 of the guide lists thirteen items. **Ten were already built** by the v3 round and were verified
in place rather than rebuilt — the server-driven action bar with unknown-key→nothing, `actor` from
`/actions`, reason sheets from `cancellationReasons`, the whole payment track, the refund dialogs,
the pickup-code handshake, the `needsAttention` banner, deadline countdowns, `deliveryType`
branching, and the rider-search UI in its three places. The repo layer already sends the four body
keys the guide flags as differing from the route comments (`prepEtaMinutes`, `utrNo`, `reason`,
`comment`).

What was left was **six facts the app had wrong**, five of them inherited from an older document
that read production through a filter which hid the data.

---

## 1. The six

| # | Was | Is | Where |
|---|---|---|---|
| **1** | `riderLeg` coerced through `_map()`. It is a **String** on the wire, so the coercion returned null and the leg never reached the UI on any doorstep order | `fromAny` takes `dynamic` and normalises a bare status string into `{status: …}` | `order_track_model.dart` |
| **2** | The rider block drew name, vehicle and Call — no leg status at all | A status line per §18.5, with `cancelled` and `rejected` reading **differently**; an unknown leg draws nothing | `RiderLegStatus`, `order_steps_screen.dart` |
| **3** | *"Grocery emits no socket event"* → 2 of 4 subscribed, capability table said none | All four subscribed; `groceryOrderDispatched` / `groceryOrderCompleted` added as **re-read cues**, never state patches | `app_constant.dart`, `chat_view_controller.dart`, `order_vertical_capabilities.dart` |
| **4** | Push switched on `grocery_order` / `grocery_order_ready`, **which the backend never sends**. The labels it does send — `selfpickup_order`, `selfpickup_order_ready` — fell through to "open the conversation" | All of them, plus `grocery_order_dispatched`, route to the steps screen; the dead labels stay as aliases | `app_notification.dart`, `pending_deep_link.dart` |
| **5** | Grocery sends no `deadlines`, so a customer saw **no clock at all** on the vertical where **978 of 1,099 orders expire** | One derived clock: grocery, `placed` only, `createdAt + 1h` | `OrderVerticalCapabilities.derivedPlacedExpiry` |
| **6** | `ORDER_TERMINAL` on a refund action refreshed silently. `/actions` re-offers the same button, so it appeared to do **nothing, forever** | Refund actions get their own copy and the button stays; the failure is logged as an undeployed backend guard | `order_lifecycle_controller.dart` |

### Why #6 is not a workaround

A refund exists *because* the order is dead — the money conversation outlives it (§7). So
`availableActionsFor` offers `MARK_REFUND_SENT` on a terminal order deliberately, and a
`409 ORDER_TERMINAL` there means `guardAction` is still checking terminality **before** it checks
whether the action was allowed. The handoff prompt says that is fixed in `be_product_service_v2`
(`src/utils/orderStateMachine.js`); if the 409 still appears, **the fix has not been deployed** —
report it. Nothing in Flutter routes around it. `ORDER_TERMINAL` remains a stale-state code for
every other action; only the copy differs.

---

## 2. One test changed, and why

`order_chat_and_steps_edge_cases_test.dart` asserted *"grocery has no socket updates"* — the exact
claim §12 fact 2 corrects against production. It now asserts the opposite, with the correction
recorded inline. Nothing else in that file moved: focus-refresh survives as the fallback (§13), and
grocery still has no lifecycle and no `/actions`. Sockets and `/actions` are independent
capabilities, and gaining the first must not be read as gaining the second.

`test/order_conditional_flow_guide_test.dart` is new — 21 tests pinning all six facts, including the
ones that are easy to undo by accident: that an empty `riderLeg` string is **not** a rider, that no
vertical other than grocery derives a clock, and that a derived clock without `createdAt` draws
nothing rather than counting from now.

---

## 3. Deliberately not built

**A Track button on the rider block.** §6 says *"hide Track when `liveLocation` is null"*, which
presumes a Track control; the app has no order-rider tracking surface to send one to.
`goods_multi_call_tracking_screen.dart` is the Discover goods **call**-tracking flow, tied to
`DiscoverController` — pointing an order at it would be inventing a destination, which the rules of
engagement forbid. `OrderTrackRider.hasLocation` is in place for whoever builds the screen.

`§14 item 3` (rider-search coverage) and `§14 item 13` (grocery never publishing
`GROCERY_ORDER_COMPLETED`) are unchanged: the first was verified already-covered by the v3 round,
the second is backend work.
