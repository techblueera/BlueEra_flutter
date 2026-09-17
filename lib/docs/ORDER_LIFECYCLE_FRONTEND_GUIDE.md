# Order Lifecycle — Frontend / App Integration Guide (full life cycle)

> **Chat-card based, server-driven.** An order is a **dynamic chat card**. The backend owns
> the state machine; the app **renders whatever the card says** and calls the action the card
> offers. You never hard-code status logic or which buttons to show — the card carries them.
>
> Covers all three flows: **① Self Pickup › Cash · ② Self Pickup › UPI · ③ Delivery › UPI**
> (no payment gateway — cash or direct-UPI screenshot). Reference engine:
> `be_product_service_v2` (order actions) + `productOrderLifecycleHandler.js` (card) +
> `be_rider_service` (delivery). Once a vertical (grocery/food) runs on this engine, this
> guide applies unchanged.

---

## 0. The mental model

```
 App (customer / owner)                Backend
 ─────────────────────                 ─────────
   render card  ◀──── socket "productOrderLifecycle" ───  order state changes
       │  (buttons = card.ownerActions / card.customerActions, verbatim)
       ▼
   tap a button ──── POST /orders/:id/<action> ───▶  state machine guards + transitions
                                                       └─ emits next card update (socket + push)
```

- **Card lives in chat** (a `messages` doc). Load history via the normal chat messages API;
  live updates via socket. You DON'T poll the order service for status.
- **Actions go to the order service** (`be_product_service_v2`). Each returns the updated
  order; the card update arrives over the socket a moment later.
- **Buttons are server-driven.** Render `metadata.lifecycle.customerActions[]` (if you're the
  customer) or `ownerActions[]` (if you're the shop). Never invent buttons.

---

## 1. The card contract — `message.metadata.lifecycle`

Every order card is a chat message with `message_type` `product_selfpickup` (or grocery/food
equivalent) and a `metadata.lifecycle` object that is **replaced on every transition**:

```jsonc
metadata.lifecycle = {
  "orderStatus":  "placed|accepted|in-progress|ready|dispatched|completed|cancelled|expired",
  "sellerStatus": "pending|accepted|preparing|ready|handed_over|rejected|cancelled",
  "paymentMethod":"cash|upi",
  "paymentState": "pending|submitted|under_review|verified|rejected|expired|refund_pending|refunded",
  "banner":       "Preparing your order · Ready in ~15–20 min",   // human status line to show
  "customerActions": ["cancel", "pay_now", "show_pickup_code"],   // buttons for the customer
  "ownerActions":    ["accept", "reject", "set_prep_eta"],        // buttons for the shop
  "deadlines":    { "acceptBy":"…","payBy":"…","readyBy":"…","pickupBy":"…" },  // ISO — for countdowns
  "reasonCode":   null,          // set on reject/cancel — map to human text
  "refundDue":    false,
  "lastEvent":    "PRODUCT_ORDER_ACCEPTED",
  "lastEventAt":  "2026-09-15T09:30:00Z"
}
```
Also present on the card: `metadata.order` (items, totals, deliveryType), `metadata.selfpickupOrderId`
(the order id you call actions with), `metadata.is_cancelled`.

> **Render rule:** show `banner` as the status line, draw a stepper from `orderStatus`, and
> render one button per entry in your-side actions array (map the action key → label + the
> endpoint in §3). Grey out nothing yourself — if an action isn't allowed, it isn't in the array.

---

## 2. Live updates (Socket.IO)

Connect your normal chat socket. Order cards update via:
```js
socket.on("productOrderLifecycle", ({ message }) => {
  // message.metadata.lifecycle is the NEW state — replace the card in place.
  // message.selfpickupOrderId / conversation_id identify which card.
});
// New order card (owner side): "newProductSelfPickupOrderReceived" (grocery/food have twins).
// Rider handoff cards: "riderOtpUpdated" (see §7).
```
- Each transition also sends a **push notification** to the affected party (accept, payment
  requested/verified, ready, dispatched, completed, cancelled, reminders…). Tapping it opens
  the card.
- On cold start / reopen, load chat history — the card's `metadata.lifecycle` now persists
  (the schema fix), so the last state renders correctly.

---

## 2a. Which service / base URL per vertical (SAME endpoints, different base)

The full lifecycle now runs identically across all pickup verticals — **the endpoints,
card contract, socket events and flows in this guide are the same everywhere**; only the
base URL changes with the shop's vertical. Pick the base from the card's type / the shop
category:

| Vertical | Card `message_type` | Order-service base (via gateway) |
|---|---|---|
| Grocery | `selfpickup` | `{API}/grocery-service/api/orders` |
| Food | `food_selfpickup` | `{API}/food-service/api/orders` |
| Medical | `medical_selfpickup` | `{API}/medical-service/api/orders` |
| Product | `product_selfpickup` | `{API}/product-service-v2/orders` |
| Homemade / Tiffin | `homemade_food_selfpickup` / `tiffin` | *(coming — same shape)* |

> Confirm each base path against your gateway routing; the **route suffixes** (`/:id/accept`,
> `/:id/payment/submit`, …) are byte-for-byte identical across services. Cards + sockets come
> from the **chat service** regardless of vertical.

## 3. Action endpoints (order service)

Base = the vertical's base from §2a. `:id` = `metadata.selfpickupOrderId` (or `metadata.order.orderId`).

| Action key (from card) | Method + path | Who | Effect |
|---|---|---|---|
| `accept` | `POST /:id/accept` | owner | → accepted; UPI → emits payment request |
| `reject` | `POST /:id/reject` `{reasonCode}` | owner | seller rejected; last seller → cancel |
| `set_prep_eta` | `POST /:id/prep-eta` `{minutes}` | owner | revise ready ETA (delayed banner) |
| `mark_ready` | `PUT /:id/ready` | owner | → ready (pickup code becomes revealable) |
| `handover` | `POST /:id/handover` `{code}` | owner | verify pickup code → picked-up/completed, settle cash |
| `no_show` | `POST /:id/no-show` | owner | customer didn't arrive |
| `cancel` | `POST /:id/cancel` `{reasonCode}` | customer/owner | cancel (refund_pending if money held) |
| `pay_now` / submit | `POST /:id/payment/submit` `{utrNo, screenshotUrl, amountPaid}` | customer | UPI proof submitted |
| `verify_payment` | `POST /:id/payment/verify` | owner | screenshot approved → verified |
| `reject_payment` | `POST /:id/payment/reject` `{reason}` | owner | rejected → customer re-uploads |
| `show_pickup_code` | `GET /:id/pickup-code` | customer | reveal code (only when `ready`) |
| — | `GET /:id/actions` | any | server-computed allowed actions + cancel reasons (source of truth) |

> If you ever doubt which buttons to show, call `GET /:id/actions` — it returns
> `availableActions` for the caller + the allowed `cancellationReasons`.

---

## 4. Flow ① Self Pickup › Cash

```
placed ──accept──▶ accepted ──(prep)──▶ ready ──handover(code)──▶ completed
   │                                                     ▲
   └── cancel (customer/owner, reason) ──▶ cancelled     └─ auto-cancel if never collected (24h)
```
| Card state (`orderStatus` / `banner`) | Customer sees | Owner sees |
|---|---|---|
| `placed` / "Waiting for shop acceptance" | Cancel (reason sheet) | **Accept · Reject** |
| `accepted`+`in-progress` / "Preparing · Ready in 15–20 min" | "Not paid yet · pay ₹X at pickup" | Set prep ETA · Mark ready |
| `accepted` (delayed) / "Taking longer · Ready in ~25 min" | updated ETA | — |
| `ready` / "Ready for pickup" | **Show Code** · Contact Shop · Get Direction | Enter code (handover) |
| customer taps Show Code | 4-digit code (e.g. `2222`) — show to shop | — |
| owner enters code → verify | — | Handover → **Completed**, cash settled |
| `completed` | "Paid at shop · Rate experience" | done |
| `cancelled` | cancelled-by + reason + ₹0 collected | — |

Cancel reasons (from `GET /:id/actions`): Changed my mind / Ordered by mistake / No longer
need / Taking too long / Other. Cancel is allowed only while `placed`/`accepted` (the state
machine enforces; the card simply won't offer `cancel` later).

---

## 5. Flow ② Self Pickup › UPI (adds a payment stage before preparing)

```
placed ─accept─▶ accepted+payment:pending ─submit─▶ submitted ─verify─▶ verified ─▶ preparing … (same as ①)
                                                        └─ reject ─▶ rejected ─(re-upload)─▶ submitted
```
| `paymentState` | Customer card | Owner card |
|---|---|---|
| `pending` (after accept) | **Payment Pending** — owner QR + UPI id + amount → Scan/Pay → **Upload Screenshot** | waiting |
| `submitted` | "Payment Verification — screenshot submitted · please wait" · Change Screenshot | **Verify · Reject** |
| `verified` | "Payment Verified → preparing your order" | preparing |
| `rejected` | "Not verified — upload a valid screenshot" · **Re-Upload** · Contact Shop | — |

Upload: put the screenshot on S3 first, then `POST /:id/payment/submit {utrNo, screenshotUrl,
amountPaid}` (dup-UTR blocked, max 5 tries). Owner QR + UPI id come from the card
(`paymentQrId`/`upiId`). Payment must be `verified` before the order goes to preparing.

---

## 6. Flow ③ Delivery › UPI (critical)

```
CART → address → CHECKOUT ──[precheck]──▶ initiate ─accept─▶ pay(UPI, product amount) ─verify─▶
   preparing + RIDER DISPATCH (owner-area, first-accept-wins) ─▶ rider picks up (PIN) ─▶
   out for delivery ─▶ rider delivers (customer PIN) ─▶ completed ─▶ rate owner + rider
```

**Checkout precheck (before initiate) — call these and gate the Next button:**
1. **Delivery address present?** if not → "Add a delivery address."
2. **Rider available in the shop's area?** — the moment the customer picks **Delivery**,
   BEFORE initiating checkout, call:
   ```
   GET {API}/rider-service/fare/chat-dispatch/availability?lat=<SHOP lat>&lng=<SHOP lng>[&vehicleType=]
   → { success:true, available:true|false, count, message }
   ```
   If **`available:false`** → **block checkout** and show
   *"Rider service is not available in this area right now — please use Self Pickup."*
   (Do NOT initiate the delivery order.) `available:true` → proceed. Pass the **shop's**
   coordinates (the pickup point), not the customer's. Whether a rider actually accepts
   later is separate — this only gates that the area HAS riders at all. (Self-pickup never
   calls this — it has no rider leg.)

**Payment before dispatch:** the order is accepted → customer pays UPI (product amount ONLY,
no ride fee on this QR) → owner verifies. **Rider dispatch happens AFTER payment is verified**,
not before. Once `paymentState:verified` (and the order is packed/ready), trigger dispatch:
```
POST {API}/rider-service/fare/chat-dispatch/orders
{ selfpickupOrderId, selfpickupType, businessId, orderFor,
  shopLocation:{latitude,longitude}, dropLocation:{latitude,longitude},
  fare,                       // the quoted delivery fee from §6 quote (server re-verifies)
  orderType:"broadcast",      // Rapido-style race (recommended); or "standard" + selectedRiders
  vehicleType }               // optional
```
The rider service then runs the **first-accept-wins race**; on assignment it calls the order
service's `ConvertOrderToRider` (stamps `rideOrderId` + flips the order to dispatched) and pushes
the **rider details card** to the chat. The owner's card shows "Finding a rider…" until then.

**Rider dispatch (automatic, race):** backend broadcasts to owner-area riders in expanding
waves; **first accept wins** (atomic). Owner card gets the **rider details** (name, number,
vehicle). Customer card shows "Preparing / Rider assigned". Delivery fee shown to the customer
is the **same server-authoritative fee from checkout** — it never changes.

**Handoff PINs (two separate 4-digit codes):**
- **Pickup PIN** — shown on the **rider's** card; the **owner enters** it (`POST
  /riders/orders/:id/pickup {otp}`) → status `picked-up`, order → out for delivery.
- **Delivery PIN** — shown on the **customer's** card; the **rider enters** it (`POST
  /riders/orders/:id/deliver {otp}`) → status `completed`.
- These are the goods pair (`pickupOrder`/`deliverOrder`) — not the passenger `startRide` flow.

After completion: prompt **rate the shop + rate the rider**.

---

## 6a. UI screens (wireframes) — each screen = a card state

Every screen below is the SAME chat card re-rendered as `metadata.lifecycle` changes. The
label under each box shows what drives it. (Visual reference: the product PDF.)

```
① REVIEW / CHECKOUT                       ② PLACED — waiting acceptance
┌──────────────────────────────┐         ┌──────────────────────────────┐
│ Fresh Mart · 0.8km           │         │ ✅ Order placed  #GRO-1247    │
│ ── Items ──                  │         │ Waiting for shop acceptance  │
│ 3 items            ₹600      │         │ ●Placed ─○Accepted ─○Prep     │
│ Receive:  (•)Self Pickup     │         │        ─○Ready ─○Picked ─○Done│
│           ( )Book Rider      │         │ Total ₹600 · Cash at shop    │
│ Payment:  (•)Cash  ( )UPI    │         │            [ Cancel Order ]   │
│ ── Bill ──  Discount ₹450    │         └──────────────────────────────┘
│ Grand total          ₹600    │          orderStatus=placed
│      [ Place Order  ₹600 ]   │          customerActions=[cancel]
└──────────────────────────────┘
 POST {base}/  (deliveryType,paymentMethod)

③ CANCEL reason sheet                    ④ PREPARING + ETA (delayed variant)
┌──────────────────────────────┐         ┌──────────────────────────────┐
│ Cancel this order?           │         │ 👨‍🍳 Preparing your order      │
│ ( )Changed my mind           │         │ Ready in ~15–20 min          │
│ ( )Ordered by mistake        │         │ (delayed → "~25 min, taking  │
│ ( )No longer need            │         │  longer than expected")      │
│ ( )Taking too long  ( )Other │         │ Not paid yet · pay ₹600 at   │
│ [ Keep Order ] [ Cancel ]    │         │ pickup                        │
└──────────────────────────────┘         └──────────────────────────────┘
 POST /:id/cancel {reasonCode}            banner from lifecycle; setPrepEta revises

⑤ PAYMENT PENDING (UPI)                  ⑥ PAYMENT VERIFICATION
┌──────────────────────────────┐         ┌──────────────────────────────┐
│ 💳 Pay ₹600 · UPI            │         │ ⏳ Payment under review       │
│ [ QR CODE ]  freshmart@okhdfc│         │ Screenshot submitted 10:00am │
│ 1. Pay via any UPI app       │         │ Please wait — shop verifying │
│ 2. Upload screenshot         │         │ [ Change Screenshot ]        │
│ [ ⬆ Upload Screenshot ]      │         │ (rejected → "Upload a valid  │
│                              │         │  screenshot" [Re-Upload])    │
└──────────────────────────────┘         └──────────────────────────────┘
 paymentState=pending → submit           paymentState=submitted → verify/reject

⑦ READY FOR PICKUP                       ⑧ PICKUP CODE (customer shows)
┌──────────────────────────────┐         ┌──────────────────────────────┐
│ 🛍️ Ready for pickup           │        │ Show this code at the shop   │
│ When you arrive:             │         │        ┌───────────────┐     │
│ 1.Counter 2.Tell order       │         │        │   2 2 2 2     │     │
│ 3.Show code 4.Pay 5.Collect  │         │        └───────────────┘     │
│ [ Show Code ] [ Contact ]    │         │ Share only when collecting   │
│ [ Get Direction ]            │         │ [ Contact ] [ Direction ]    │
└──────────────────────────────┘         └──────────────────────────────┘
 orderStatus=ready                        GET /:id/pickup-code (owner → POST /handover)

⑨ COMPLETED                              ⑩ DELIVERY — rider assigned
┌──────────────────────────────┐         ┌──────────────────────────────┐
│ ✅ Order Completed!           │         │ 🛵 Rider: Amit · 97xxxx      │
│ Paid at shop · ₹600          │         │ Splendor · HR20AB1234        │
│ ●───●───●───●───●───●        │         │ Out for delivery · ₹40 fee   │
│ [ Rate experience ]          │         │ Your delivery PIN: 4321      │
│ [ Shop Again ]               │         │ (rider verifies at doorstep) │
└──────────────────────────────┘         └──────────────────────────────┘
 orderStatus=completed                    rider_otp delivery card (§7)
```

**Screen ↔ state cheat-sheet:** ①→create · ②`placed` · ③cancel · ④`accepted/in-progress` +
`banner` · ⑤`paymentState:pending` · ⑥`submitted`/`rejected` · ⑦`ready` · ⑧`pickup-code` ·
⑨`completed` · ⑩rider `rider_otp` cards. Delivery adds the checkout precheck (§6) before ①.

---

## 7. Rider handoff OTP cards (`message_type: "rider_otp"`)

Delivered as chat cards; `metadata.otp = { kind:"pickup|delivery", otp, mode:"show|enter", … }`,
plus `visible_to` (single user id).
- **Pickup card:** `mode:"enter"`, digits hidden — the **owner** types the rider's PIN.
- **Delivery card:** `mode:"show"` — the **customer** shows their PIN to the rider.
- When verified (in the rider service), the card flips to `metadata.otp.status:"consumed"` via
  socket `riderOtpUpdated` — grey it out / show a tick.

---

## 8. Edge-case UX (all backend-driven — you just render)

The backend runs a 60s sweep and pushes these; render the banner + a friendly line:
- **No accept in time** → nudge, then auto-cancel (owner didn't respond).
- **Payment window** elapses (UPI) → payment expired banner.
- **Owner slow to verify** → nudge; escalates internally.
- **Prep overdue / delayed** → "Taking longer than expected" + revised ETA.
- **Ready but not collected** → reminders, then owner action, then hard-expiry.
- **No rider found** → offer Self Pickup fallback on the card.

You do **not** implement these timers — just show `banner` and whatever actions the card lists,
and keep listening on the socket. Friendly/Hinglish copy can be driven from `reasonCode` +
`banner` if you localise.

---

## 9. Rendering checklist (do this, skip the rest)
1. Card = a chat message; subscribe to `productOrderLifecycle` (+ `riderOtpUpdated`).
2. Status line = `metadata.lifecycle.banner`; stepper = `orderStatus`.
3. Buttons = your-role actions array → map key→label→endpoint (§3). Nothing else.
4. Payment stage = `paymentState`; show QR/upload/verify per §5.
5. Codes: Self-pickup `GET /:id/pickup-code` (when `ready`); delivery PINs via the `rider_otp`
   cards (§7).
6. Countdowns (optional) from `deadlines`.
7. On any action → call its endpoint → the socket delivers the next card state. Don't optimistically
   flip status yourself.

### One-line summary
The order is a **server-driven chat card**: render `metadata.lifecycle.banner` + the role's
action buttons, call the mapped order-service endpoint on tap, and let the `productOrderLifecycle`
socket push the next state. Cash/UPI/Delivery all differ only by which `paymentState`/actions the
card carries; PINs (self-pickup code, rider pickup/delivery OTP) are separate cards. No polling,
no client-side status logic.
