# Backend Guide — Opening Hours: One Record, Not Five

**Audience**: backend team (`be_user_service`, other-service, school-service, earn-service)
**Raised by**: Flutter team, from a live account
**App status**: shipped to the branch — the app no longer reads or writes ANY of the
per-vertical timings records. Every merchant-facing screen now reads the profile
`availability`.

---

## 1. The problem, from a real account

Business `6aa1076147e6a60f6d075b98` (`type_of_business: "Service"`, module `OTHERS`) had a
complete seven-day schedule:

```jsonc
// GET /business/6aa1076147e6a60f6d075b98
"availability": {
  "liveState": { "isLive": true, "liveDate": "2026-09-10" },
  "schedule": [
    { "day": "Monday", "isOpen": true, "shopOpenTime": "09:00", "shopCloseTime": "21:00", … },
    …all seven days…
  ]
}
```

Their own profile tab still said **"Set your Business Timings"**, and — because that banner
replaces the whole tab — hid management, gallery, banking, contact, website, share and QR
behind a demand they had already met.

Nothing was broken in either service. The app was reading a **different record**.

## 2. Five records for one fact

`availability` on the profile is the record that actually matters: it drives `liveState`,
the open/closed pill, the go-live scheduler and discovery. Alongside it, four verticals
each grew their own private timings store:

| Vertical | Second store | Written by | Shape |
|---|---|---|---|
| Other-service | `other-service …/full → timings` | `other-service/timings` (POST/PUT) | object per weekday, `openTime`/`closeTime` |
| Automotive-service | *(same record — the fork shared it)* | same | same |
| School | `schoolTimings` on the school payload | `PUT school/<id>/timings`, body `{ "schoolTimings": [...] }` | list, `day`/`isOpen`/`openTime`/`closeTime` |
| Professionals | `earn-service/professional/<id>/timings` | `PUT earn-service/professional/timings`, body `{ "schedule": [...] }` | list |

None of them wrote to `availability`, and `availability` did not write to them. So in every
vertical:

* hours set through **Go Live** left the vertical's own tab demanding timings;
* hours set through the **vertical's timings screen** never reached the open/closed pill,
  so a merchant could fill them in and still never appear open to a customer.

The second direction is the more damaging one, and it was silent.

## 3. The decision

**The profile `availability` record is the single source of opening hours** — the business
availability for BUSINESS accounts, the individual availability for INDIVIDUAL ones. All
four secondary stores are dropped.

## 4. What the app now does — already shipped

| Vertical | Reads | Edit button opens |
|---|---|---|
| Other-service, automotive-service, school, hotel, lab, doctor | `availability.schedule` on the business profile | the weekly-hours editor behind Go Live (`PUT /availability/hours`) |
| Professionals, self-employed | individual availability | the individual weekly-hours editor |

Deleted from the app, along with every call to them:

* `other-service/timings` — screen, controller, model, three repo methods, API key;
* `school/<id>/timings` — the availability form screen, both controller methods, both repo
  methods;
* `earn-service/professional/timings` — screen, controller, model, two repo methods.
  (The `earn-service/professional` prefix is still used for gallery endpoints — only the
  `/timings` paths are gone.)

A `grep` for a `/timings` endpoint anywhere in the app's API layer now returns nothing.

The app tolerates these fields continuing to appear in payloads. It ignores them.

## 5. What we are asking for

### 5.1 Migrate the merchants who only have a secondary store — please do this first

Any account whose vertical timings record has open days but whose `availability.schedule`
has none is, from today, an account the app shows as having **no hours** — and it will nudge
them to set hours they already set once.

Run this for **all four** stores:

```
for each account with a non-empty vertical timings record:
    if its profile availability.schedule has no open day:
        write availability.schedule from that record
        # openTime  → shopOpenTime
        # closeTime → shopCloseTime
        # isOpen    → isOpen
        # day name capitalised as availability already stores it ("Monday")
        # timezone: "Asia/Kolkata" unless the account has another
        # BUSINESS accounts → business availability
        # INDIVIDUAL (professionals) → individual availability
```

Please report the count per vertical — it tells us how many merchants were in the broken
half of each.

### 5.2 Stop writing the secondary stores

All four write endpoints should be retired, or kept only as redirects that write
`availability` instead. No client calls any of them after this release, so a `410` is
acceptable once §5.1 has run. If you prefer to keep them live for older installs, make them
write `availability` so the two can no longer diverge.

### 5.3 The customer-facing screens — mostly fixed app-side, one blocker left

If a payload keeps serving a stale secondary record, **a merchant edits their hours and
customers keep seeing the old ones** — the same bug, pointed at the people deciding whether
to visit.

**Fixed, shipped:** the shared visit hero (school, other-service, finance detail screens)
now prefers `availability.schedule` and falls back to the vertical timings only when the
payload has no `availability`. So the moment §5.1 runs, those three screens show live hours
with no further app change. Deriving or dropping the vertical fields is then cosmetic —
please still do it, so nothing is left serving a record nobody writes.

**Blocked on you — the professionals payload has no `availability` field at all:**

| Screen | Reads | Model |
|---|---|---|
| `discover_professionals_view_screen.dart:926` | `data.timings?.schedule` | `ProfessionalConsData` |
| `profession_consultant_discover_screen_v2.dart:1441` | `service.timings?.schedule` | `ProfessionalConsData` |

`ProfessionalConsData` carries `timings` and nothing else — there is no availability field to
read, so we cannot flip these the way we flipped the hero. A professional edits their hours
in the app today and **every customer-facing consultant screen keeps showing the old ones,
permanently.**

Please add the individual `availability` (same `schedule[]` shape as the business one) to
the professionals/consultant payloads. We will switch those two screens over as soon as it
lands. Until then this is a live wrong-data bug with no app-side fix.

By contrast `ServiceData` (the self-work/service payload) already carries `availability` —
that shape is the one to copy.

### 5.4 Please confirm `availability` is served for every module

The merchant screens now read `availability.schedule` for every business vertical. Confirm
`GET /business/<id>` returns `availability` for **every** `type_of_business` and module, and
that the individual profile endpoint returns its equivalent for every profession. If any
module omits it, those accounts will see the "set your hours" banner permanently.

## 6. What we are NOT asking for

* No change to the `availability` shape. The app reads `schedule[].day`, `.isOpen`,
  `.shopOpenTime`, `.shopCloseTime` and they are all fine.
* No change to `PUT /availability/hours`. It is now the only writer, and it already works.
* No new endpoint.

## 7. How to verify

1. Take a business with hours only in a vertical store → run §5.1 → open the app's profile
   tab. The Timings card shows the hours and the banner is gone.
2. Take a business with hours only in `availability` (the account in §1) → open the tab.
   Same result, with no migration needed. **This case is already fixed by the app change.**
3. Edit hours from any me-screen → confirm the write lands on `availability.schedule`, and
   that `liveState` starts respecting the new hours.
4. Open the same business in Discovery as a customer → the hours shown match what the
   merchant just saved. Works for school / other-service / finance as soon as §5.1 has run.
   **Consultants will still be wrong until the payload change in §5.3 lands** — that one
   cannot be verified until then.
5. Confirm no request to `other-service/timings`, `school/<id>/timings` or
   `earn-service/professional/timings` appears in the logs from an app client on this
   release or later.

## 8. Open question for you

Is `availability` per-ACCOUNT or per-module? The payload in §1 has it on the business
document, which is what the app assumes. If an account can hold more than one availability
record (one per module), say so — the app currently reads exactly one and would need to know
which.
