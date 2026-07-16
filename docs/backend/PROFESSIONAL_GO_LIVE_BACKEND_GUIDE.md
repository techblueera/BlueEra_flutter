# Professional / Consultant Go-Live — Backend Guide

**To:** Backend team **From:** Flutter app team
**Applies to:** the **professionals / consultant** dashboard (`ProfessionalsMainScreen`).
**Related:** [`BUSINESS_GO_LIVE_BACKEND_GUIDE.md`](./BUSINESS_GO_LIVE_BACKEND_GUIDE.md)
(the business twin — same UX, different endpoints),
[`SELF_WORK_GO_LIVE_GUIDE.md`](./SELF_WORK_GO_LIVE_GUIDE.md)
(individual deposit gate), [`SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md`](./SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md)
(deposit purchase).

A professional's "Go Live" is **schedule-driven auto open/close** with a
**today-only override** — the same UX as business — but a professional is an
**INDIVIDUAL**. So it uses **new individual availability endpoints** (not the
business ones), and the **deposit gate lives on the personal profile**. This
guide is self-contained.

---

## 1. The model

- The provider sets a **weekly schedule once** (open/closed + open/close time per
  weekday). The shop then **opens and closes automatically within those hours**.
- A **today-only override** can force open/closed for the current day and
  **auto-reverts tomorrow**. No per-day time editing — times are only set in the
  weekly schedule.
- **First wall = the security deposit.** An unpaid professional is never shown
  live and cannot go live.

The old per-service "Working Hours" (professional service `timings`) has been
**removed from the app** — the weekly schedule below is the single source of a
professional's availability.

### Effective-open rule

```
effective_day = todayOverride (if dateKey == today, business tz) else weekly row
open_today    = effective_day.isOpen
isOpenNow     = open_today && effective_day.shopOpenTime <= now < effective_day.shopCloseTime
                (business timezone)
```

---

## 2. Individual availability endpoints (NEW)

Mirror the business availability endpoints **exactly** (request + response shape),
but scoped to the caller's own **INDIVIDUAL** account (bearer JWT — no
`businessId`). Auth: `Authorization: Bearer <JWT>`.

| Method | Path | Body | Purpose |
|--------|------|------|---------|
| PUT    | `/user-service/individual/availability/hours` | `{timezone, schedule[]}` | Set/replace weekly hours |
| GET    | `/user-service/individual/availability/hours` | — | Read schedule + `todayEffective` + `liveState` |
| PUT    | `/user-service/individual/availability/today` | `{isOpen, shopOpenTime?, shopCloseTime?}` | Override **today** only (auto-reverts) |
| DELETE | `/user-service/individual/availability/today` | — | Clear today's override now |

### `PUT /individual/availability/hours` request

```jsonc
{
  "timezone": "Asia/Kolkata",
  "schedule": [
    { "day": "Monday",  "isOpen": true,  "shopOpenTime": "09:00", "shopCloseTime": "17:00" },
    { "day": "Sunday",  "isOpen": false }
    // …full 7-day array; REPLACES the stored schedule…
  ]
}
```
Rules: `day` = full capitalized name. `isOpen:true` ⇒ `shopOpenTime` **and**
`shopCloseTime` required, `HH:MM` 24-h (else **400**). `isOpen:false` ⇒ times
ignored. Mirror open days into a `timeSlots` entry for backward-compat.

### `PUT /individual/availability/today`

Force-open today: `{ isOpen:true, shopOpenTime:"00:00", shopCloseTime:"23:59" }`.
Force-close: `{ isOpen:false }`. Keyed to today's date in the **business
timezone**; **auto-reverts at midnight**. `DELETE` reverts immediately.

### `GET /individual/availability/hours` response

```jsonc
{
  "status": true,
  "data": {
    "timezone": "Asia/Kolkata",
    "schedule": [ /* weekly hours */ ],
    "specialOverrides": [ { "dateKey": "2026-07-10", "isOpen": false } ],
    "liveState": {
      "isLive": true,          // ← COMPUTED isOpenNow (effective ∩ within hours, business tz)
      "liveDate": "2026-07-10"
    }
  },
  "todayEffective": { "date": "2026-07-10", "day": "Wednesday", "isOpen": true,
                      "shopOpenTime": "09:00", "shopCloseTime": "17:00", "source": "weekly" }
}
```
The app parses `data` into the same `AvailabilityData` model the business flow
uses, recomputes `isOpenNow` client-side on a 1-minute timer, and treats the
server as authoritative on every read.

---

## 3. Publish the live state to clients

Return the computed `liveState.isLive` (or `isOpenNow`) on the reads that show a
professional's public availability — **consultant detail / discovery / list /
map** — so customers see the correct Open/Closed badge without running the
merchant's client timer. Daily auto-revert: if `liveDate` / override `dateKey` ≠
today, recompute from the weekly schedule (never report a stale live state).

---

## 4. Deposit gate — on the INDIVIDUAL PROFILE

A professional is an **`INDIVIDUAL`** account whose deposit **`tag_id` is their
profession `category`**. The app reads `securityDeposit` from the **individual
profile** (the `PersonalProfileDetailsModel` read — top-level, next to `user`),
exactly like the self-employed gate.

```jsonc
// individual profile response
{
  "status": true,
  "user": { /* … */ },
  "securityDeposit": {
    "required": true,            // false ⇔ zero-deposit / exempt → never gate
    "paid": false,               // the gate: true → allow; false → block + CTA
    "paymentStatus": "created",
    "depositId": null,
    "refundEligibleAt": null
  }
}
```

- App rule: allowed when `securityDeposit == null || paid == true`; blocked only
  when `required && !paid`. **Fail-open** on outage / unresolved tag → `paid:true`.
- The professional pill shows `isOpenNow && paid` — an unpaid provider is never
  shown live even during scheduled hours.

### 402 backstop

Return **402 Payment Required** (with the `securityDeposit` body) when an unpaid
professional tries to open:
- `PUT /individual/availability/hours` opening **any** day, and
- `PUT /individual/availability/today` with `{isOpen:true}`.

```json
{
  "message": "Your payment is incomplete. Please complete the security deposit to go live and receive service enquiries.",
  "securityDeposit": { "required": true, "paid": false, "paymentStatus": "created", "depositId": null, "refundEligibleAt": null }
}
```

Purchase (be_subscribe_service): `POST /security-deposit/initiate {tag_id:
<category>, account_type:"INDIVIDUAL"}` → Razorpay → verify → `held`. After
payment, the next individual-profile read reports `paid:true`.

---

## 5. Timezone

All "today" and "now within hours" decisions use the **business timezone** the
app sends when saving hours (`"timezone":"Asia/Kolkata"`). Never use raw
server-UTC midnight.

---

## 6. App flow (context, no action needed)

```
Pill tap →
 1. PAYMENT CHECK FIRST — read securityDeposit from the INDIVIDUAL profile.
    paid == false → message + deposit screen; STOP.
 2. GET /individual/availability/hours (hydrate schedule + override)
 3. Shop-status sheet (always). No hours → "Set visiting hours" → PUT /hours.
    Hours exist → live status + weekly hours list + today override
      open today   → PUT    /individual/availability/today {isOpen:true,"00:00","23:59"}
      closed today → PUT    /individual/availability/today {isOpen:false}
      revert       → DELETE /individual/availability/today
    + "Edit weekly hours" → PUT /individual/availability/hours
```

The pill value = computed `isOpenNow` (from `GET /individual/availability/hours`,
recomputed client-side on a 1-min timer) **AND** the individual profile's
`securityDeposit.paid`.

---

## 7. Acceptance checklist

- [ ] `PUT/GET /user-service/individual/availability/hours` and
      `PUT/DELETE /user-service/individual/availability/today` exist and resolve
      the doc from the caller's own **INDIVIDUAL** account (bearer JWT, no
      `businessId`) — identical request/response shape to the business ones.
- [ ] `GET /individual/availability/hours` returns `schedule`,
      `specialOverrides`, `todayEffective`, and a **computed** `liveState.isLive`
      (`open_today && within hours`, business tz).
- [ ] A 09:00–17:00 professional reads `isLive:false` at 08:00, `true` at 10:00,
      `false` at 18:00 — no write in between. Closed weekday → false all day.
- [ ] `PUT /today {isOpen:false}` → false today, auto-reverts tomorrow;
      `PUT /today {isOpen:true,"00:00"–"23:59"}` → true today; `DELETE /today` →
      back to weekly.
- [ ] Consultant-detail / discovery / list / map reads carry the computed
      `liveState.isLive`.
- [ ] **Individual profile** read returns `securityDeposit` (top-level, next to
      `user`); fail-open when absent / on outage.
- [ ] **402** on `PUT /individual/availability/hours` (opening a day) and
      `PUT /individual/availability/today {isOpen:true}` for an unpaid
      professional, with the `message` + `securityDeposit` body.
- [ ] Deposit `tag_id = profession category`, `account_type = "INDIVIDUAL"`.
```
