# Handoff prompt — paste this into Claude Code, in the BlueEra_flutter repo

---

You are working in the **BlueEra_flutter** repo. The backend order system is already built and
deployed. Your job is **only the Flutter UI**. Do not change any backend service.

## Read this first

**The complete spec:** https://claude.ai/code/artifact/384d62f4-ff56-4cf9-98da-94603b0db662

A copy also lives in the Flutter repo at `lib/docs/ORDER_UI_CONDITIONAL_FLOW_GUIDE.md`. Read the
whole thing before writing any code — section numbers below refer to it.

Every payload, error code and body key in it was verified against the live production API on
27 Aug 2026 with two real accounts. **Trust it over any older doc in `lib/docs/`** — in particular
`ORDER_CHAT_AND_STEPS_UI_EDGE_CASES.md` and `GROCERY_SELF_PICKUP_ORDER_UI_AUDIT_AND_GUIDE.md` are
wrong on four points, listed in §12 of the guide. The app's `OrderVerticalCapabilities` table
inherited those errors and needs correcting.

## The one rule you must not break

> **`GET /actions` decides which buttons exist. Flutter never decides.**

Delete every local rule shaped like `if (status == 'placed') showCancel()`. Render buttons by
looping over `availableActions` and mapping each key through a lookup table. **An action key the
build does not recognise renders nothing** — never a fallback button, never a label built from the
raw key string.

This is what makes the UI conditional. Example: on a cash order the server simply never returns
`SUBMIT_PAYMENT`, so no pay button appears — with zero client logic. Do not re-implement that
decision locally.

Corollaries:
- Read `actor` from the response. Do not thread an `isOwner` guess through constructors.
- Read `cancellationReasons` from the response. Never hardcode reason lists.
- A countdown reaching zero **never** changes state locally. Keep polling; the server decides.
- After every successful action, **re-fetch** — never advance the card locally.

## What to build, in this order

Work through §14 of the guide. Ordered by visible impact:

1. Read `actor` from `/actions` instead of guessing `isOwner`
2. Fix the push case labels — the backend sends `selfpickup_order` / `selfpickup_order_ready`, the
   app switches on `grocery_order` / `grocery_order_ready`, so that deep link is dead today
3. **Rider-search coverage** — the "finding a delivery partner" UI **already exists** in three places
   (§17): `order_find_rider_sheet.dart`, `goods_multi_broadcast_searching_screen.dart` and
   `OrderBroadcastSearchSection`. Do **not** rebuild it. Verify every dispatch entry point reaches
   one, and that `ride:broadcast:exhausted` offers *Try again* + *Collect it yourself* rather than
   showing failure
4. **Refund reconciliation UI** on terminal orders (§07) — a cancelled order with money owed is not
   an empty screen; the money block and its buttons stay
5. **Payment track** (§05) — submit sheet, waiting state, verify/reject, rejected-retry
6. **Deadline countdowns** from `deadlines`; for grocery derive from `createdAt + 1h`
7. Branch cards on `deliveryType` — a delivery order currently renders the self-pickup card
8. `needsAttention` banner
9. Reason sheets driven by `cancellationReasons`
10. Pickup-code handshake
11. Subscribe to the four grocery socket events
12. `riderLeg` is a **String**; the model calls `_map()` on it, so it is always null

## One backend note

`POST /refund/sent` and `POST /refund/received` used to return `409 ORDER_TERMINAL` even though
`/actions` correctly offered `MARK_REFUND_SENT` — the guard checked *terminal* before *action
allowed*. **That is fixed** in `be_product_service_v2` (`src/utils/orderStateMachine.js`,
`guardAction`). If you still see `409 ORDER_TERMINAL` on a refund action, the fix has not been
deployed yet — report it, do not work around it in Flutter.

## This is one app with three roles

The same person is a shop on one order and a customer on another. **Role is per order, not per user**
— `/actions` returns `actor` for that order. Never cache a global "I am a seller" flag and use it to
pick order UI.

Rider is the exception: a *mode*, gated by go-live, with its own screens and its own service
(`rider-service`). §18 covers the full rider lifecycle — offer race, per-shop pickup OTPs, delivery
OTP, payment confirmation. §17 covers checkout: the quote endpoint, the "delivery costs more than the
basket" case, and out-of-range handling.

**Before building anything in §17 or §18, check what already exists.** Both areas are more built than
the older docs suggest, and the correct task there is coverage, not construction.

## Two order contracts exist — do not assume parity

- **product-service** runs `be_product_service_v2`: full state machine, `/actions`,
  `availableActions`, 8 order states, 8 payment states, cash + UPI, deadlines, attention flags.
- **grocery / food / medical** are still on the old contract: three stages, one seller action, no
  `/actions`, no `actor`, payment always "cash at counter".

Keep the capability gate that already exists — but correct its facts per §12. Do not delete it, and
do not assume grocery will behave like product.

## Verify your work against the real API

Test accounts (both belong to the product owner, use freely):

| | Singh Store | Bhupinder |
|---|---|---|
| userId | `6a8e73a5f1331440ed37bdd9` | `6a841f79acdd3589d5d21067` |

Note the roles **flip between verticals**: for grocery, Singh Store is the shop. For product-service,
Singh Store has no catalogue and Bhupinder is the shop — so Singh Store buys.

Base URL `https://be.beapp.in/api`. §16 of the guide has a full replay of the v2 lifecycle with the
exact request bodies and responses, including the four body keys that differ from what the route
comments suggest (`prepEtaMinutes`, `utrNo`, `reason`, `comment`).

## Rules of engagement

- **Do not** change any backend service, or any file outside `BlueEra_flutter`.
- **Do not** rewrite the app's architecture, navigation, state management or design system. Match
  what is already there.
- **Do not** invent buttons, states, copy or endpoints that are not in the guide.
- **Do not** add a control "just in case" — if `availableActions` does not contain it, it does not
  render.
- Reuse the existing widgets and theme tokens. This is a behaviour change, not a redesign.
- If the guide and the code disagree, **say so and stop** rather than guessing. Report the mismatch.

## Definition of done

- Every state in §04–§07 renders correctly for both roles, driven only by the server response
- The QA checklist in §15 passes
- No hardcoded action list, reason list, or role guess remains anywhere in the order code
- The widget tests in `test/` pass (`order_chat_and_steps_edge_cases_test.dart`,
  `order_stepper_render_test.dart` — these have **never been run**; no Dart SDK was available on the
  machine that wrote the guide, so expect to fix some)

Start by reading the guide end to end, then show me your plan before writing code.
