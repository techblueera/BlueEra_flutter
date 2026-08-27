# Order flow — review of the client contract vs. both codebases

**Reviewing:** `FLUTTER_ORDER_FLOW_CLIENT_CONTRACT.md`
**Checked against:** `BlueEra_flutter` @ `main` (`e0186242c` "new order flow completed")
and `be_product_service_v2` / `be_rider_service` / `be_chat_service` @ `prod-staging`.
Read line by line, both sides.

**Headline: the app is in better shape than the contract document says it is.**
The document predates the v3 UI guide; the code has since absorbed it. Six of the
document's own statements are now stale — the code is right and the doc is wrong.

That said, the review turned up **four real defects**. One is a P0 that blocks a
core flow, and it is on our side; I have already fixed it. The other three are
small client-side misses.

| # | Finding | Side | Severity | Status |
|---|---|---|---|---|
| 1 | A shop **cannot reject a new order** — `cancellationReasons` came back empty in the only state where rejecting is possible | **backend** | **P0 — fixed** | ✅ fixed backend-side; the app's reason sheet already degraded to a required note submitted as `OTHER`, and that is now pinned by a widget test |
| 2 | `/track` sends `viewerRole`, the app only reads `actor` / `role` / `isOwner` | app | P1 | ✅ `viewerRole` accepted; `actor` still wins where both appear |
| 3 | `/track` sends `needsAttention` with **no `flagged` key**; the app tests for `flagged == true` and always gets false | app | P1 | ✅ on `/track` the object's presence is the flag; `reason` is still never parsed or rendered |
| 4 | `/track`'s `paymentSummary` omits every refund field, so a card refreshed only via `/track` cannot render the refund step | both | P2 | ✅ option 2 taken, and made safe: payment summaries and lifecycles now merge **field-wise**, so a refund-less `/track` cannot erase refund state |

> ## ✅ IMPLEMENTED (Flutter, this repo)
>
> All three client-side findings are fixed, plus **two more of the same family** that §4.2
> of this review exposed while implementing it:
>
> - **`/actions` carries no `banner`.** Replacing the lifecycle wholesale on a refresh
>   blanked the card's server-authored status line and fell back to the neutral "Order
>   update" placeholder. Lifecycles now merge field-wise.
> - **`/actions` never mentions `refundDue`.** A silent `false` from it was clearing a
>   `true` the socket had delivered, so the refund block vanished on the next app resume.
>   `refundDue` is now only taken from a payload that actually stated it.
>
> 17 new tests in `test/order_track_contract_test.dart`. `flutter analyze lib` → 0 errors;
> `flutter test` → 263 passing (was 246). **Full write-up:
> `ORDER_FLOW_REVIEW_FIXES_DONE.md` (same folder)**, summarised in
> `ORDER_FLOW_V3_FRONTEND_DONE.md` §9.

Your §9 open questions are all answered in §4 below. Short version: **#1 yes the
prefix is right, #2 here is the key-for-key answer, #5 already satisfied, #7 the
data exists.**

---

## 1. P0 — a shop could not reject a new order (fixed)

Your contract document called this exact failure mode:

> *"If you send an empty list the reason sheet has nothing to offer and the cancel
> flow stalls, so please always populate it on any state where `CANCEL_ORDER` /
> `REJECT_ORDER` is offered."*

It was happening. `GET /actions` built the list like this:

```js
cancellationReasons: actions.includes(ORDER_ACTION.CANCEL_ORDER) ? … : []
```

`REJECT_ORDER` was never checked. A shop looking at a brand-new order gets

```
availableActions: ["CONTACT_CUSTOMER", "ACCEPT_ORDER", "REJECT_ORDER"]
```

— no `CANCEL_ORDER`, because a shop that has not accepted yet has nothing to
cancel ([orderStateMachine.js:406-410](../../be_product_service_v2/src/utils/orderStateMachine.js)).
So `cancellationReasons` came back `[]` in the **one state where rejecting is the
entire point**, your reason sheet had nothing to render, and
`POST /reject` refuses a missing `reasonCode` with `400 INVALID_REASON`
([orderActions.controller.js:256-263](../../be_product_service_v2/src/controllers/orderActions.controller.js)).

**Fixed** — the condition now covers both actions. A pending order returns the
full `CANCELLATION_REASONS.OWNER` list:

```
ITEM_UNAVAILABLE · SHOP_CLOSED · TOO_BUSY · PRICE_CHANGED ·
CUSTOMER_NOT_RESPONDING · CUSTOMER_DID_NOT_ARRIVE · PAYMENT_NOT_RECEIVED ·
SUSPECTED_FRAUD · OUTSIDE_DELIVERY_AREA · OTHER
```

Uncommitted, in `be_product_service_v2`. **This is worth a smoke test the moment
it deploys** — "shop declines a new order" is not a rare path.

---

## 2. Three client-side misses

### 2.1 `/track` answers `viewerRole`, not `actor` — P1

`GET /:orderId/track` carries the same role information under a different key
([order.controller.js:2058](../../be_product_service_v2/src/controllers/order.controller.js)):

```jsonc
{ "data": { "viewerRole": "owner",     // ← "customer" | "owner" | "admin"
            "availableActions": [ … ], "paymentSummary": { … } } }
```

Your fallback chain reads `actor` → `role` → `isOwner`
([order_lifecycle_model.dart:826-833](../../BlueEra_flutter/lib/features/chat/auth/model/order_lifecycle_model.dart)),
so a model built from a track response has `actor == null` and `isOwner == null`.

It mostly survives, because `/track` also sends `availableActions` already scoped
to the caller and your code prefers the flat list. But anything downstream that
branches on `model.isOwner` falls back to the card heuristic. One key to add:

```dart
final actor = json['actor']?.toString()
    ?? json['viewerRole']?.toString()      // ← /track
    ?? …
```

**We will not rename `viewerRole` to `actor`** — the admin panel reads it — so
please accept both.

### 2.2 `/track`'s `needsAttention` has no `flagged` key — P1

The two planes disagree in shape, and the app only handles one of them.

```js
// GET /track  — order.controller.js:2079-2081
needsAttention: order.needsAttention?.flagged
  ? { reason: "PAYMENT_REVIEW", flaggedAt: "…" }   // ← NO `flagged` key
  : null,
```

```js
// action responses — the raw order sub-document
needsAttention: { flagged: true, reason: "…", flaggedAt: "…", note: "…" }
```

Your parser:

```dart
bool attention = json['needsAttention'] == true;
if (json['needsAttention'] is Map) {
  attention = Map<String,dynamic>.from(json['needsAttention'])['flagged'] == true;
}
```

On a `/track` response that `Map` has no `flagged`, so **`attention` is always
`false`** and the *"We're looking into this order."* strip never appears from a
track refresh. On `/track`, **the presence of the object is the flag**:

```dart
if (json['needsAttention'] is Map) {
  final m = Map<String, dynamic>.from(json['needsAttention']);
  attention = m['flagged'] == true || m.containsKey('reason');
}
```

⚠ **And do not render `needsAttention.reason`.** `/track` sends it to every party
including the customer, but the values are an internal ops taxonomy —
`PAYMENT_REVIEW`, `CUSTOMER_NO_SHOW`, `DISPUTED`, `RIDER_LATE` — and half of them
accuse somebody. The neutral strip only.

### 2.3 `/track`'s `paymentSummary` has no refund fields — P2

It carries `method`, `state`, `amountDue`, `amountPaid`, `utrNo`, `screenshotUrl`,
`submittedAt`, `verifiedAt`, `rejectionReason` — and **none** of
`refundOwedBy`, `refundRequestedAt`, `refundInitiatedAt`, `refundReference`,
`refundedAt`.

Your `OrderPaymentSummary.fromJson` reads all of them correctly, so this is not a
parsing bug — the data simply is not in that response. Consequence: a cancelled,
refund-pending order refreshed **only** through `/track` cannot tell
*"the shop owes you ₹500"* from *"the shop says it sent ₹500"*, because that
distinction is `refundInitiatedAt`.

Two ways out; **the second is free**:

1. we add the refund fields to `/track`'s `paymentSummary` (small, additive), or
2. the app reads refunds from **Plane A / Plane C** only — `metadata.lifecycle`
   carries `refundDue`, and every action response carries the full
   `data.payment.*`. Since the refund UI is only reachable from a card that has
   just been acted on or patched by socket, this is already the normal path.

Tell us if you want (1) and it ships with the next batch. Nothing is broken today
unless a refund card is rebuilt from a cold `/track` call.

---

## 3. Where your contract document is now stale

The code is correct in all six; only the document needs updating. Flagging them so
the next reader does not "fix" working code to match a stale spec.

| Doc says | Code actually does | Verdict |
|---|---|---|
| §2 `delivery` carries flat `"latitude": 12.97, "longitude": 77.59` | sends **`location: {type:"Point", coordinates:[lng, lat]}`** plus the flat pair ([order_checkout_payload.dart](../../BlueEra_flutter/lib/features/me/product/model/order_checkout_payload.dart)) | ✅ code right — and this is the fix that makes doorstep orders work at all; the flat pair alone is refused with `400 DELIVERY_LOCATION_REQUIRED` |
| §3.1 envelope has `isOwner` / `role` | reads **`actor`** first | ✅ code right |
| §3.1 `paymentSummary` is the money key | reads **`data.payment.*`** first, `paymentSummary` as fallback | ✅ code right — and the fallback is load-bearing, `/track` really does use `paymentSummary` |
| §3.1 `warning` sits inside the envelope | read from the **response root** before unwrapping `data` | ✅ code right |
| §5.3 "Rider broadcast (**rider socket**)" | they arrive on the **chat socket**, relayed via Kafka `EMIT_SOCKET_EVENT` ([consumer.js:385](../src/utils/consumer.js)) | ✅ code right, doc wrong |
| §5.3 lists `ride:broadcast:closed` as customer-facing | it goes to the **losing riders** to dismiss their popups; the app correctly ignores it | doc wrong |

Also worth correcting in the doc: **`FIND_RIDER` is no longer the delivery path.**
`order_broadcast_controller.dart` auto-dispatches on `ready` with
`orderType: "broadcast"` and no `selectedRiders` (`:265-268`), and renders the
live wave search in-card. The document still describes the old manual flow.

---

## 4. Your §9 open questions, answered

**1 — the gateway prefix is correct.** The service mounts `app.use("/api", apiRoutes)`
and the router mounts `router.use("/orders", orderRouter)`
([index.js:50](../../be_product_service_v2/src/index.js), [routes/index.js:20](../../be_product_service_v2/src/routes/index.js)),
so every verb really is at `/api/orders/:orderId/<verb>`. `product-service/api/orders/:id/actions`
is right, and it is the same prefix that already works for order creation. Keep
`_orderBase` as it is.

> The legacy `inventory-service/orders/:id/ready` constant points at a different
> service entirely. Leave it untouched; nothing new should use it.

**2 — `/actions` envelope, key for key.** Exactly this, nothing more:

```jsonc
{ "success": true,
  "data": {
    "orderId", "orderNumber",
    "actor",                    // "customer" | "owner" | "admin"
    "orderStatus", "sellerStatus", "paymentMethod", "paymentState",
    "deliveryType", "isTerminal",
    "needsAttention",           // BOOL here (an object on /track — §2.2)
    "deadlines": { … },
    "availableActions": [ … ],
    "cancellationReasons": [ "ITEM_UNAVAILABLE", … ]   // BARE STRINGS
  }}
```

There is **no** `lifecycle`, **no** `banner`, **no** `paymentSummary`, **no**
`cancellation`, **no** `pickupCode`, **no** `isOwner` on `/actions`. Those live on
other planes: `banner` + `lifecycle` on the card and the socket; `paymentSummary`
+ `cancellation` on `/track`; `payment` + `cancellation` on action responses;
`pickupCode` only from `GET /pickup-code` (`{success, data:{pickupCode}}`).

**3 — `availableActions` is already role-scoped**, on `/actions`, `/track` and
every action response. The role marker is `actor` on `/actions` and `viewerRole`
on `/track` (§2.1).

**4 — the complete list is sent on every socket event.** `customerActions` and
`ownerActions` are recomputed from scratch by the order service and shipped whole
on each event ([orderLifecycle.service.js:100-104](../../be_product_service_v2/src/services/orderLifecycle.service.js)).
Replacing rather than merging is correct.

**5 — already satisfied.** `messageId` is on every `productOrderLifecycle`
payload ([productOrderLifecycleHandler.js:354-358](../src/utils/productOrderLifecycleHandler.js)),
and `payment:verified` / `payment:rejected` both carry **`order_ref`**
([paymentQr.controller.js:415,496](../src/controllers/paymentQr.controller.js)) —
which your doc already lists as one of the keys you read. Nothing to add.

**6 — grocery / food / medical:** not ported. Only `be_product_service_v2` has the
lifecycle endpoints and emits `metadata.lifecycle`. We will tell you per vertical;
no app change needed, as you say.

**7 — shop coordinates exist**, they are just not on the payload the cart reads.
`business.proto` carries `Location business_location = 18` and `inventory.proto`
has an active `BusinessLocation { latitude, longitude } business_location = 5`.
So this is a matter of threading an existing field into the cart's business block,
not of capturing new data. Your honest degradation ("This shop has not set a
location yet", delivery disabled, self-pickup kept) is the right behaviour to keep
in the meantime — some shops genuinely have no location set.

**8 — timestamps.** Everything is a JS `Date` serialised by `res.json()`, i.e.
ISO-8601 UTC with a `Z`. `DateTime.tryParse(...).toLocal()` is correct.

---

## 5. Two things we confirm about idempotency (your §2.1 ask)

- **`200` returns the same order** for a repeated `idempotencyKey` from the same
  user. `201` on first create. Treating both as success is right.
- **A different key always creates a new order.** The uniqueness is
  `(userId, idempotencyKey)` with a `partialFilterExpression` so that orders with
  **no** key are not all indexed under `null` — that defect would have failed
  every customer's *second* order, and it is why the key mattered so much.

---

## 6. What we changed on our side in this round

| Service | File | Change |
|---|---|---|
| `be_product_service_v2` | `src/controllers/orderActions.controller.js` | `cancellationReasons` now populated when `REJECT_ORDER` is offered, not only `CANCEL_ORDER` (§1) |

Uncommitted. Nothing else on the order flow needed a server change — the rest of
this document is either already correct or a client-side fix.

---

## 7. Suggested order of work for the app

```
✅ P1  accept `viewerRole` in the actor chain              §2.1   done
✅ P1  treat a needsAttention OBJECT as flagged            §2.2   done
✅ P2  read refunds from Plane A/C — option 2              §2.3   done, field-wise merge
✅ —   refresh FLUTTER_ORDER_FLOW_CLIENT_CONTRACT.md       §3     rewritten
```

**On §2.3 — we do not need (1).** Option 2 is taken. But "read refunds from Plane A/C" was
only free once the merge stopped replacing wholesale: a cold `/track` landing on a card
that already knew `refundInitiatedAt` was erasing it, which is the same bug by a different
route. Field-wise merging fixes both, so **add the refund fields to `/track` only if it is
convenient for you** — nothing on our side is waiting for it.

**One thing back to you, from §4.2.** The key-for-key `/actions` answer is what surfaced
the two extra bugs above: `/actions` legitimately omits `banner` and `refundDue`, and our
merge was treating "not mentioned" as "now empty". No change needed on your side — but it
is worth knowing that any *further* trimming of a payload's keys is, for us, indistinguishable
from a field being cleared unless we know the plane's shape. That is why this document's
key-for-key answer was so useful.

None of these block a release. The one thing that did block a release was §1, and
that is ours and it is fixed.
