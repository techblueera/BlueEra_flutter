# Business Go-Live — Backend Guide (single source of truth)

**To:** Backend team **From:** Flutter app team
**Service:** be_user / business service (deposit purchase itself lives in
be_subscribe_service — see [`SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md`](./SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md))

This is the **one** guide for the business "Go Live" flow. It replaces the
earlier split notes (auto-open-close request + live-state persistence request).
Applies to every business/service that shows the Go-Live pill: **grocery,
food/restaurant, product, manufacturer, automotive-parts, hotel, hospital, lab,
medical, school, vehicle, others.**

---

## 1. The model (what "live" means now)

Go-Live is **not** a manual daily action. The merchant sets a **weekly schedule
once** (open/closed + open/close time per weekday). The shop then **opens and
closes automatically within those hours**. On top of that, a merchant may
**override *today only*** (force open / closed for the current day), which
**auto-reverts to the weekly schedule tomorrow**.

There is **no per-day time editing** — times are only ever set in the weekly
schedule; the today override is a plain open/closed switch.

### The effective-open rule (single source of truth)

```
effective_day = todayOverride  (if its dateKey == today in the business timezone)
                else the weekly schedule row for today's weekday

open_today    = effective_day.isOpen
isOpenNow     = open_today
                && effective_day.shopOpenTime <= now < effective_day.shopCloseTime
                (evaluated in the business timezone)
```

The app sends a force-open override as `{ isOpen:true, shopOpenTime:"00:00",
shopCloseTime:"23:59" }` ("open the rest of today") and a force-close as
`{ isOpen:false }`.

---

## 2. Tap order on the app (so you know when each endpoint fires)

```
Pill tap →
 1. PAYMENT CHECK FIRST
    securityDeposit.paid == false → app shows a message + routes to the deposit
    screen and STOPS. (Server backstop = 402, see §3.)
 2. Load hours if not cached → GET /availability/hours
 3. Open the shop-status sheet (always). Two states:
    a. No weekly hours yet → "Set visiting hours" → PUT /availability/hours
    b. Hours exist         → live status + today override:
         open today   → PUT    /availability/today {isOpen:true,"00:00","23:59"}
         closed today → PUT    /availability/today {isOpen:false}
         revert       → DELETE /availability/today
       + "Edit weekly hours" → PUT /availability/hours
```

The pill value itself is the computed `isOpenNow`; the app recomputes it on a
1-minute client timer so it crosses open/close boundaries without a network call.

---

## 3. Payment gate (checked FIRST)

An unpaid business **cannot go live**. Every business account is a `BUSINESS`
account whose deposit **`tag_id` is its business `category`** (e.g. `Grocery`,
`Restaurant`, `Manufacturer`). The business service asks be_subscribe_service
*"has this user paid?"* and returns the answer as a **`securityDeposit`** object.

### 3.1 Return `securityDeposit` on the business profile (top-level on `data`)

```jsonc
"securityDeposit": {
  "required": true,            // false ⇔ zero-deposit / exempt category (never blocked)
  "paid": false,               // true ⇔ holds an active (held) deposit, OR exempt
  "paymentStatus": "created",  // raw UserSecurityDeposit.status | null
  "depositId": "66c1...",      // deposit id (null if none yet)
  "refundEligibleAt": null     // ISO date once held; else null
}
```

| Field | Type | App use |
|---|---|---|
| `required` | bool | `false` → never gate. |
| `paid` | bool | **The gate.** `true` → allow. `false` → block + deposit CTA. |
| `paymentStatus` | string? | Raw status (`created`/`held`/`refunded`/…). |
| `depositId` | string? | Deep-link into the deposit/refund screen. |
| `refundEligibleAt` | string? | ISO date the deposit becomes refundable. |

Return it on **`GET /user-service/business/:id`** (own) and
**`GET /user-service/business/:userId`** (by user). Discovery / list / map /
search reads intentionally omit it — the gate is about the merchant's own shop.

**Fail-open (required):** if the subscribe service is unreachable or the tag
can't be resolved, return `paid:true`. Exempt/zero-deposit categories return
`required:false, paid:true`. The app treats missing / `paid:true` as "allowed".
Rule: allowed when `securityDeposit == null || securityDeposit.paid == true`.

### 3.2 Enforce 402 as the backstop

Return **402 Payment Required** on the go-open endpoints when `paid:false`:
- `PUT /availability/hours` when it opens **any** day, and
- `PUT /availability/today` with `{isOpen:true}`.

```json
{
  "message": "Your payment is incomplete. Please complete the security deposit to go live and receive service enquiries.",
  "securityDeposit": { "required": true, "paid": false, "paymentStatus": "created", "depositId": null, "refundEligibleAt": null }
}
```

The app pre-checks `paid` before opening the sheet, so 402 only guards a stale
client. Purchase flow: `POST /security-deposit/initiate {tag_id:<category>,
account_type:"BUSINESS"}` → Razorpay → verify → deposit `held`; the next profile
read reports `paid:true`.

---

## 4. Endpoints

Base prefix `/user-service/business`. Auth: `Authorization: Bearer <JWT>`
(auto-injected by the app's Dio interceptor).

| Method | Path | Body | Purpose |
|--------|------|------|---------|
| PUT    | `/availability/hours` | `{timezone, schedule[]}` | Set/replace weekly hours |
| GET    | `/availability/hours` | — | Read schedule + `todayEffective` + liveState |
| PUT    | `/availability/today` | `{isOpen, shopOpenTime?, shopCloseTime?}` | Override **today** only (auto-reverts tomorrow) |
| DELETE | `/availability/today` | — | Clear today's override now (revert to weekly) |
| ~~POST~~ | ~~`/availability/go-live`~~ | — | **Deprecated** — no longer called (live is computed) |
| ~~POST~~ | ~~`/availability/end-live`~~ | — | **Deprecated** — no longer called |

### 4.1 `PUT /availability/hours` — weekly schedule

```jsonc
{
  "timezone": "Asia/Kolkata",     // defaults Asia/Kolkata
  "schedule": [
    { "day": "Monday",  "isOpen": true,  "shopOpenTime": "09:00", "shopCloseTime": "17:00" },
    { "day": "Saturday","isOpen": true,  "shopOpenTime": "10:00", "shopCloseTime": "18:00" },
    { "day": "Sunday",  "isOpen": false }
    // …full 7-day array; it REPLACES the stored schedule…
  ]
}
```
Rules: `day` = full capitalized name (`Sunday`..`Saturday`). `isOpen:true` ⇒
`shopOpenTime` **and** `shopCloseTime` required, `HH:MM` 24-h zero-padded (else
**400**). `isOpen:false` ⇒ times ignored. Omitted days stored closed. Invalid
`timezone`/empty body ⇒ **400**. Mirror open days into a `timeSlots` entry for
backward-compat with the existing availability widget.

### 4.2 `PUT /availability/today` — today override

Keyed to today's date in the business timezone; **stops applying at midnight**
(business tz) with no client call. `DELETE` reverts immediately. `isOpen:true`
⇒ `shopOpenTime`+`shopCloseTime` required (else **400**); `404` if weekly hours
not set yet. Keep returning `todayEffective {isOpen, shopOpenTime,
shopCloseTime, source}` and include the override in `specialOverrides` (with a
`dateKey`).

---

## 5. Compute & return the live state on reads (persistence)

The app hydrates the toggle from the business profile and keeps it live with the
client timer between fetches. **The server must be authoritative on every read**,
especially for customers/discovery (who never run the merchant's timer).

Return, under `availability`, the raw inputs **and** the computed flag:

```jsonc
"availability": {
  "timezone": "Asia/Kolkata",
  "schedule": [ /* full 7-day weekly hours */ ],
  "specialOverrides": [ { "dateKey": "2026-07-10", "isOpen": false } ], // today's, if any
  "liveState": {
    "isLive": true,            // ← COMPUTED isOpenNow (effective ∩ within hours, business tz)
    "liveDate": "2026-07-10"   // the date isLive was computed for
  }
}
```

- Keep populating `liveState.isLive` with the **computed** value — the app
  already parses it and uses it as the first-paint value.
- Also return `schedule` + `specialOverrides` so the client can recompute
  between fetches.
- **Where:** own profile (`GET /business/:id`), by-user (`GET /business/:userId`),
  `GET /availability/hours`, **and** discovery / list / map / search business
  reads (at minimum `liveState.isLive`, so customers see the correct Open/Closed
  badge).

Daily auto-revert: if `liveDate`/override `dateKey` is not today, it does not
apply — recompute from the weekly schedule.

---

## 6. Timezone

All "today" and "now within hours" decisions use the **business timezone** (the
app sends `"timezone":"Asia/Kolkata"` when saving hours). Never use raw
server-UTC midnight, or shops near midnight flip early/late.

---

## 7. Go-live reminder (optional)

If you keep the `business_go_live_reminder` push, target businesses with **no
schedule** (or a closed-for-today override) rather than "didn't tap today" —
there is no daily tap anymore. FCM payload the app already handles (body tap and
the `go_live` action button both deep-link to the business own-profile, which
auto-opens the shop-status control):

```jsonc
{
  "operation": "business_go_live_reminder",
  "data": {
    "title": "You're not live yet",
    "body": "Your shop was scheduled to open at 09:00. Tap to set your hours / go live.",
    "business_id": "<id>",
    "open_time": "09:00",
    "cta": "go_live"
  }
}
```

---

## 8. Acceptance checklist

- [ ] Profile reads (`:id`, `:userId`) return `securityDeposit` (top-level) and
      `availability` with `schedule`, `specialOverrides`, and a **computed**
      `liveState.isLive`.
- [ ] `isLive` = `open_today && within hours` in the business tz. A 09:00–17:00
      shop reads false at 08:00, true at 10:00, false at 18:00 — with no write
      in between. A closed weekday reads false all day.
- [ ] `PUT /today {isOpen:false}` → false today, auto-reverts tomorrow;
      `PUT /today {isOpen:true,"00:00"–"23:59"}` on a closed day → true today,
      auto-reverts; `DELETE /today` → back to weekly immediately.
- [ ] Discovery / list / map reads carry the same computed `isLive`.
- [ ] Gate: `securityDeposit.paid:false` blocks; fail-open on outage /
      exempt category returns `paid:true`.
- [ ] **402** on `PUT /hours` (opening a day) and `PUT /today {isOpen:true}` for
      an unpaid business, with the `message` + `securityDeposit` body.
- [ ] `PUT /hours` validates `HH:MM` and required open/close on open days (400).
