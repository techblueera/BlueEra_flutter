# Order Flow — the client-contract review round, what was built

> **Implements:** `ORDER_FLOW_CLIENT_CONTRACT_REVIEW.md` (same folder) — the line-by-line
> review of both codebases that followed the v3 work.
> **Previous round:** `ORDER_FLOW_V3_FRONTEND_DONE.md` — the v3 UI guide, all of it.
> **Contract for the backend:** `FLUTTER_ORDER_FLOW_CLIENT_CONTRACT.md`, rewritten in this
> round against the source rather than against its own stale text.
>
> **Commit:** `fb1d9ede6 "order flow updated"`.
> **Verification:** `flutter analyze lib` → **0 errors**. `flutter test` → **263 passing**
> (was 246); the 16 failures are the same pre-existing ones in `discover_folder_tile`,
> `doctor_card_layout`, `feed_card_render`, `search_result_card`, `vehicle_number` and
> `rider_document_state`, none of which this work touches.
>
> **Scope:** one production file — `chat/auth/model/order_lifecycle_model.dart` — plus one
> new test file and three docs. Small diff, but it closed five real defects.

---

## 0. The one idea behind all five fixes

Order state reaches the app three ways, and **they do not answer with the same keys or the
same completeness**:

```
Plane A  metadata.lifecycle   pushed on productOrderLifecycle   banner, role-split actions
Plane B  GET /actions         on demand                          actor, caller-scoped actions
Plane C  /track + verb replies on demand / per action            viewerRole, money, address
```

The store keeps a **union** of the three, keyed by order id. The bug — five times over —
was that it treated *"this payload did not mention the key"* as *"the key is now empty"*.

That is fine when a payload is a complete picture. It is wrong for every one of these:

| Payload | Legitimately omits |
|---|---|
| `GET /actions` | `banner`, `refundDue`, all money, the delivery address |
| `GET /track` | every refund field on `paymentSummary` |
| `GET /pickup-code` | everything except the code |
| a bare `{success:true}` | everything |

So the merge is now **field-wise**: a key the newer payload did not mention keeps the value
we already had. With one deliberate exception — **action lists replace, never merge** —
because every payload that carries them carries the complete set, and merging would leave a
button the server had just withdrawn.

---

## 1. The five defects

### 1.1 `/track` answers `viewerRole`, not `actor` — P1, from the review §2.1

`GET /:orderId/track` carries the role under a different key from every other endpoint, and
**it is going to keep doing so** — the admin panel reads it.

```jsonc
{ "data": { "viewerRole": "owner", "availableActions": [ … ], "paymentSummary": { … } } }
```

The chain read `actor` → `role` → `isOwner`, so a model built from a track response had a
null role, and anything branching on it fell back to the card's own `myMessage` heuristic —
a guess that is right often enough to hide the problem and wrong often enough to matter.

```dart
final actor = json['actor']?.toString() ??
    json['viewerRole']?.toString() ??   // ← /track
    …
```

`actor` still wins where both could appear.

### 1.2 `/track`'s `needsAttention` has no `flagged` key — P1, review §2.2

Three shapes, and the parser only handled two:

```js
/actions          → true                                    // a bare bool
verb replies      → { flagged: true, reason, flaggedAt, note }
/track            → { reason, flaggedAt }   ← NO `flagged`, and null when not flagged
```

Testing `flagged == true` against the third shape is always `false`, so the neutral
*"We're looking into this order."* strip never appeared from a track refresh. **On `/track`
the presence of the object is the flag:**

```dart
bool attention = json['needsAttention'] == true;
if (json['needsAttention'] is Map) {
  final m = Map<String, dynamic>.from(json['needsAttention']);
  attention = m['flagged'] == true || (m['flagged'] == null && m.isNotEmpty);
}
```

An explicit `flagged: false` is still honoured as "no" — that is an answer, not a silence.

> **`needsAttention.reason` is still never parsed onto the model, from any plane.**
> `/track` sends it to every party including the customer, but `PAYMENT_REVIEW` /
> `CUSTOMER_NO_SHOW` / `DISPUTED` / `RIDER_LATE` is an internal ops taxonomy and half of it
> accuses somebody. There is a comment at the parse site saying so, because the next reader
> will be tempted to render it.

### 1.3 `/track`'s `paymentSummary` carries no refund fields — P2, review §2.3

It has `method`, `state`, `amountDue`, `amountPaid`, `utrNo`, `screenshotUrl`,
`submittedAt`, `verifiedAt`, `rejectionReason` — and **none** of `refundOwedBy`,
`refundRequestedAt`, `refundInitiatedAt`, `refundReference`, `refundedAt`.

The review offered two ways out and called the second free: read refunds from Plane A/C
only, since the refund UI is only reachable from a card that has just been acted on or
patched by socket. **It was not quite free.** A cold `/track` landing on a card that already
knew `refundInitiatedAt` was overwriting the whole summary and erasing it — dropping the
card from *"the shop says it sent ₹500"* back to *"the shop owes you ₹500"*. That
distinction **is** `refundInitiatedAt`.

`OrderPaymentSummary.mergedOver(base)` now merges field by field, so option 2 works as
described and no backend change is needed.

### 1.4 `/actions` carries no `banner` — found while implementing 1.3

Not in the review's findings list; it fell out of §4.2's key-for-key answer, which
enumerates exactly what `/actions` returns and confirms there is no `lifecycle` and no
`banner` on it.

The card's status line is **server-authored and rendered verbatim** — that is the whole
point of `banner`. Refreshing `/actions` replaced the lifecycle wholesale, so the banner
became null and the card fell back to its neutral "Order update" placeholder. And
`/actions` is called on socket reconnect and on every app resume, so this fired constantly.

`OrderLifecycle.mergedOver(base)` fixes it, with action lists still replacing.

### 1.5 `/actions` never mentions `refundDue` — same origin

`refundDue` is a `bool`, so "absent" and "false" were indistinguishable. A refresh set it to
`false` and the refund block vanished from a cancelled, refund-pending card on the next
resume.

`OrderLifecycle` now records whether the payload actually stated it:

```dart
final bool refundDueStated;              // json.containsKey('refundDue')
…
refundDue: refundDueStated ? refundDue : base.refundDue,
```

`applyFrom` — the in-place socket patch — respects the same flag.

### 1.6 The P0 was backend-side, and the app already survived it

A shop looking at a brand-new order gets `["CONTACT_CUSTOMER","ACCEPT_ORDER","REJECT_ORDER"]`
and **no** `CANCEL_ORDER`, because a shop that has not accepted has nothing to cancel. The
service only populated `cancellationReasons` when `CANCEL_ORDER` was offered, so the list
came back `[]` in the one state where rejecting is the entire point, and
`POST /reject` refuses a missing `reasonCode`.

Fixed in `be_product_service_v2`. Nothing needed changing here: `order_reason_sheet.dart`
already degrades an empty list to a **required** free-text note submitted as `OTHER`, which
is in the server's `OWNER` list. That behaviour is now pinned by a widget test rather than
left to luck — an empty list stays possible for other reasons, such as an `/actions` call
that failed.

---

## 2. What changed, file by file

| File | Change |
|---|---|
| `chat/auth/model/order_lifecycle_model.dart` | `viewerRole` in the actor chain · `needsAttention` presence-is-the-flag · `OrderPaymentSummary.mergedOver` · `OrderLifecycle.mergedOver` · `refundDueStated` · `applyFrom` respects it · `mergedWith` uses both field-wise merges and takes a non-empty action list from any payload that carries one |
| `test/order_track_contract_test.dart` | **new** — 17 tests, one group per finding |
| `FLUTTER_ORDER_FLOW_CLIENT_CONTRACT.md` | rewritten; the previous edition had been reduced to a 6-line stub and six of its statements were stale |
| `ORDER_FLOW_CLIENT_CONTRACT_REVIEW.md` | status column, an implemented banner, and a note back to the backend |
| `ORDER_FLOW_V3_FRONTEND_DONE.md` | §9, recording this round |

No widget, controller or repo file needed touching. Every fix was in the parse-and-merge
layer, which is where a three-plane contract belongs.

---

## 3. The merge rules, stated once

For the next person who has to reason about a fourth plane.

| Field | Rule | Why |
|---|---|---|
| `availableActions` | Take the fresh list whenever the payload carried one, **or** when it described the state — even if empty | "Nothing to do" is a real answer; a bare acknowledgement is not |
| `customerActions` / `ownerActions` | Replace when non-empty | Every payload carrying them carries the complete set |
| `banner`, `reasonCode`, `suggestion`, all timestamps, all ids | Keep ours when the newer payload says nothing | Only Plane A carries a banner at all |
| `refundDue` | Only from a payload that **stated** it | A bool cannot distinguish absent from false |
| `deadlines` | Replace when non-empty, keep when empty | A whole block, always sent together |
| `paymentSummary` | Field-wise | `/track` omits every refund key |
| `needsAttention` | From a payload that described the state | `/track`'s shape is the awkward one |
| `warning` | Always from the fresh payload, read from the **response root** | It describes *this* call, not the order |

---

## 4. Tests — 17 new, in `test/order_track_contract_test.dart`

```bash
flutter test test/order_track_contract_test.dart
```

Each group uses a realistic `/track` body with the service's own key names — `viewerRole`,
`paymentSummary`, a `needsAttention` object with no `flagged`.

| Group | Covers |
|---|---|
| `/track answers viewerRole, not actor` (4) | Owner and customer roles read · `actor` wins where both appear · an admin stays an admin |
| `needsAttention has no flagged key` (5) | The object alone raises the strip · `null` means not flagged · explicit `flagged` honoured both ways · `/actions`' bare bool · the reason code never reaches the model |
| `/track carries no refund fields` (3) | **Step 2 survives a cold `/track` refresh** · a newer value still overwrites an older one · `refundDue` from Plane A is not cleared by a payload that never mentions it |
| `/actions carries no banner` (3) | The status line survives a refresh · a newer banner does replace · an empty action list from a state-describing payload is honoured |
| `the shop can still decline` (2) | An empty reason list degrades to a note and submits `OTHER` · a bare-string reason is pickable and submits its code |

Suite: **263 passing**, up from 246.

---

## 5. Open items

Both cheap, neither blocking.

1. **Shop `lat` / `lng` on the cart's business block.** The review confirms the data exists
   — `business.proto` has `Location business_location = 18`, `inventory.proto` has an
   active `BusinessLocation business_location = 5` — it is simply not on the payload the
   cart reads. Until it is, checkout says *"This shop has not set a location yet"*, disables
   delivery and keeps pickup. **This is the one thing gating the delivery half of checkout
   in practice**, and it is a threading job, not new data capture.

2. **Two smoke tests once the backend fix deploys:** *shop declines a new order* (§1.6),
   and a **doorstep order end to end** — no doorstep order has ever been created
   successfully from the app, so the GeoJSON coordinate fix from the v3 round is verified by
   unit test rather than by a live `201`.

3. **Optional:** refund fields on `/track`'s `paymentSummary`. Nothing here is waiting for
   them any more; add them only if convenient.

---

## 6. One thing worth saying back to the backend

The key-for-key `/actions` answer in the review's §4.2 is what surfaced defects 1.4 and
1.5. Neither was in the findings list; both were found by comparing that enumeration
against what the app assumed.

From the client's side, **any trimming of a payload's keys is indistinguishable from a
field being cleared** unless we know that plane's shape. The merge rules in §3 are written
against the shapes as documented today. If a plane starts omitting something new, the
symptom will not be an error — it will be a card quietly losing a banner, a refund, or a
button.
