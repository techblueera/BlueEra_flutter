# Joining Bounce — Flutter Integration Guide

> **Joining Bounce** is a one-time **joining bonus**: the platform pays the user
> after they prove genuine onboarding (active days, hours, tasks, streak, and
> milestones). The user does **not** pay anything.

## The most important thing to know

**The app only DISPLAYS progress and CLAIMS the bonus.**

- ✅ The backend **auto-enrolls** the user the moment they become BUSINESS/INDIVIDUAL.
- ✅ The backend **auto-tracks** every milestone, task, hour, active-day and streak
  from the other microservices (profile verified, KYC approved, order completed,
  product published, channel created, provider online hours, etc.).
- ❌ The app must **NOT** send enroll / activity / milestone events. Those are
  backend-only now (see [Do NOT call](#-endpoints-you-must-not-call)).

So the entire app flow is just **4 endpoints**:

| # | Method | Endpoint | Purpose |
|---|--------|----------|---------|
| 1 | GET  | `/joining-bounce/current` | The user's active bonus + live progress (home/banner) |
| 2 | GET  | `/joining-bounce/my-bounces` | All bonuses (history: in-progress / eligible / credited) |
| 3 | GET  | `/joining-bounce/{joiningBounceId}/progress` | Full detail + plan terms for one bonus |
| 4 | POST | `/joining-bounce/claim` | Claim the bonus once `eligible` |

(Optional) `POST /joining-bounce/cancel` — let the user abandon an in-progress bonus.

---

## ⭐ Home scratch card — read it from the profile response (no polling)

You do **not** need to call any joining-bounce API to show the home scratch
card. The two profile APIs the app already calls on launch now return a
**`joining_bounce`** object that auto-creates the bonus on first load and tells
you everything the card needs:

- `GET /user-service/user/get?contact_no=<mobile>` → `data.joining_bounce` *(individual or business user)*
- `GET /user-service/business/<businessId>` → `joining_bounce` *(only when the requester is the business owner)*

```json
"joining_bounce": {
  "show_card": true,            // ← show the scratch card?
  "is_claimed": false,          // true once claimed (card hidden)
  "enrolled": true,
  "status": "in_progress",      // none | in_progress | eligible | credited
  "eligible": false,            // true ⇒ enable Claim
  "progress_percent": 60,
  "bonus_inr": 1000,            // display amount (₹)
  "tag_id": "GENERAL_STORE",
  "account_type": "BUSINESS",
  "joining_bounce_id": "665f0c2a…"
}
```

**Home flow (one decision, zero extra calls):**

```
On app open you ALREADY fetch user/get (or business/:id).
        │
        ├─ joining_bounce.show_card == false  → don't show the card. Done.
        │     (status "none" = no applicable bonus, or "credited" = already claimed)
        │
        └─ joining_bounce.show_card == true   → show the scratch card
                 │      (display bonus_inr + progress_percent)
                 ▼
          user taps the card
                 │
                 ├─ eligible == true  → POST /joining-bounce/claim  { joiningBounceId }
                 │
                 └─ eligible == false → open detail screen (optional):
                        GET /joining-bounce/{joining_bounce_id}/progress
```

So the **only** joining-bounce endpoint the home flow calls is `POST /claim`,
and only when the user taps an eligible card. Everything else rides on the
profile response you already load. The card is created **once** (first load) and
then just reflects status; after claim, `show_card` becomes `false`.

> The detailed `/current`, `/my-bounces`, `/progress` endpoints below are still
> available if you want a dedicated Joining Bounce screen — but they are
> **optional**. The home card alone needs none of them.

---

## Base setup

- **Base URL:** `https://<your-subscribe-service-host>` (routes are mounted at root, e.g. `https://api.blueera.com`)
- **Auth:** every request needs the user JWT:
  ```
  Authorization: Bearer <token>
  ```
- **Response envelope:** every endpoint returns
  ```json
  { "success": true, "message": "…", "data": <payload> }
  ```
- **Amounts:** `bonus_amount` and `credited_amount` are in **paise**. `bonus_inr`
  is the same value in **rupees** (use this for display). `1 rupee = 100 paise`.

---

## The full user flow

```
  User becomes BUSINESS / INDIVIDUAL
            │  (backend auto-enrolls — no app call)
            ▼
  ┌──────────────────────────────┐
  │ GET /joining-bounce/current  │  ← poll on screen open / pull-to-refresh
  │  status = in_progress        │
  │  progress_percent = 0..100   │  ← drive the progress UI from `requirements`
  └──────────────────────────────┘
            │  (user keeps using the app; backend services auto-report progress)
            ▼
  status = eligible   (eligible == true)
            │
            ▼
  ┌──────────────────────────────┐
  │ POST /joining-bounce/claim   │  ← enable the "Claim" button only when eligible
  └──────────────────────────────┘
            │
            ▼
  status = credited   → bonus_inr credited to wallet (wallet_txn_id returned)
```

**There is no "enroll" screen and no "mark complete" button.** When the user opens
the Joining Bounce screen, call `GET /current`. If it returns `404`, the user has
no active bonus yet — show an empty/info state. Otherwise render the progress.

---

## 1) GET `/joining-bounce/current`

The user's single active bonus (`in_progress` or `eligible`). Use this for the
main screen / home banner.

### ⭐ First-visit auto-create (important)

A brand-new user (or anyone who isn't enrolled yet) has **no** bonus, so a bare
`GET /current` returns `404`. To auto-create it the moment the user opens the
Joining Bounce screen, **pass the user's category/profession tag** as a query
param. The backend then auto-enrolls into the matching plan and returns it:

```
GET /joining-bounce/current?tag_id=<user's category or profession>
Authorization: Bearer <token>
```

- `account_type` is read from the JWT automatically — you don't need to send it
  (you *may* pass `&account_type=BUSINESS|INDIVIDUAL` to be explicit).
- `tag_id` = the user's **business category** (BUSINESS) or **profession**
  (INDIVIDUAL). Send the value you already display on the profile — the backend
  matches tolerantly by tag **or** name (e.g. `GENERAL_STORE` or `General Store`).
- If a matching plan exists → it auto-enrolls and returns `200` with the new
  bonus (`status: "in_progress"`, `progress_percent: 0`).
- If no plan matches that tag → still `404` (the user simply has no applicable
  bonus). Show the empty state.
- Already enrolled → returns the existing bonus (idempotent; never duplicates).

> Always call `/current` **with** `tag_id` on the Joining Bounce screen. It is
> safe to call every time — it creates once, then just reads.

**Request**
```
GET /joining-bounce/current?tag_id=GENERAL_STORE
Authorization: Bearer <token>
```

**200 Response**
```json
{
  "success": true,
  "message": "Current joining bonus fetched successfully",
  "data": {
    "joining_bounce_id": "665f0c2a…",
    "tag_id": "GENERAL_STORE",
    "account_type": "BUSINESS",
    "status": "in_progress",
    "is_active": true,
    "bonus_amount": 100000,
    "bonus_inr": 1000,
    "currency": "INR",
    "progress_percent": 60,
    "eligible": false,
    "requirements": {
      "days":   { "required": 5,  "current": 3,  "met": false },
      "hours":  { "required": 10, "current": 8,  "met": false },
      "tasks":  { "required": 5,  "current": 5,  "met": true  },
      "streak": { "required": 3,  "current": 3,  "met": true  },
      "milestones": {
        "required":  ["business_profile_verified", "inventory_added", "order_completed"],
        "completed": ["business_profile_verified", "inventory_added"],
        "missing":   ["order_completed"],
        "met": false
      }
    },
    "days_active": 3,
    "total_hours": 8,
    "total_tasks": 5,
    "current_streak": 3,
    "longest_streak": 3,
    "last_active_date": "2026-06-28T00:00:00.000Z",
    "completed_milestones": ["business_profile_verified", "inventory_added"],
    "enrolled_at": "2026-06-24T10:00:00.000Z",
    "eligible_at": null,
    "credited_at": null,
    "credited_amount": 0
  }
}
```

**404 Response** — user has no active bonus (show empty state, this is normal):
```json
{ "success": false, "message": "No active joining bonus found for this user." }
```

> **UI tip:** drive the checklist directly from `requirements`. Each of
> `days/hours/tasks/streak` has `{ required, current, met }`; `milestones` has
> `required / completed / missing / met`. Show `progress_percent` on the bar and
> enable **Claim** only when `eligible == true` (i.e. `status == "eligible"`).

---

## 2) GET `/joining-bounce/my-bounces`

All of the user's bonuses (history). Optional `?status=` filter
(`in_progress` | `eligible` | `credited` | `cancelled` | `expired`).

**Request**
```
GET /joining-bounce/my-bounces
GET /joining-bounce/my-bounces?status=credited
Authorization: Bearer <token>
```

**200 Response** — `data` is an **array** of the same payload as `/current`:
```json
{
  "success": true,
  "message": "User joining bonuses fetched successfully",
  "data": [ { "joining_bounce_id": "…", "status": "credited", "...": "…" } ]
}
```

---

## 3) GET `/joining-bounce/{joiningBounceId}/progress`

Full detail for one bonus, **including the plan** (with `terms_and_conditions`).
Use it on a details screen ("How it works" / T&C).

**Request**
```
GET /joining-bounce/665f0c2a…/progress
Authorization: Bearer <token>
```

**200 Response** — same payload as `/current`, plus a `plan` object:
```json
{
  "success": true,
  "message": "Joining bonus progress fetched successfully",
  "data": {
    "joining_bounce_id": "665f0c2a…",
    "status": "in_progress",
    "progress_percent": 60,
    "requirements": { "…": "…" },
    "plan": {
      "name": "General Store",
      "bonus_inr": 1000,
      "min_days": 5, "min_hours": 10, "min_tasks": 5, "required_streak": 3,
      "required_milestones": ["business_profile_verified", "inventory_added", "order_completed"],
      "terms_and_conditions": [
        "The joining bonus is credited only after all onboarding requirements are completed.",
        "Days, hours, tasks and streak are tracked from the day you enroll.",
        "Missing a day resets your active-day streak.",
        "The bonus is credited to your platform wallet once and cannot be claimed again for the same category."
      ]
    }
  }
}
```

---

## 4) POST `/joining-bounce/claim`

Claim an **eligible** bonus. Credits `bonus_inr` to the user's wallet (idempotent).

**Request**
```
POST /joining-bounce/claim
Authorization: Bearer <token>
Content-Type: application/json
```
```json
{ "joiningBounceId": "665f0c2a…" }
```
> `joiningBounceId` is **optional** — if omitted, the backend claims the user's
> current eligible bonus. Sending it explicitly is recommended.

**200 Response**
```json
{
  "success": true,
  "message": "Joining bonus credited to your wallet successfully.",
  "data": {
    "joining_bounce_id": "665f0c2a…",
    "status": "credited",
    "credited_amount": 100000,
    "bonus_inr": 1000,
    "currency": "INR",
    "wallet_txn_id": "wtxn_abc123"
  }
}
```

**Error responses** — handle each:

| HTTP | Meaning | Suggested app behaviour |
|------|---------|-------------------------|
| `404` | No claimable (eligible) bonus found | Requirements not met yet — keep showing progress |
| `400` | Requirements not fully met | Re-render progress from `data` (returned) |
| `409` | Already claimed | Refresh; show "Already credited" |
| `502` | Wallet credit failed (transient) | Show retry; user can claim again shortly |
| `500` | Server error | Generic error + retry |

---

## (Optional) POST `/joining-bounce/cancel`

Let the user abandon an `in_progress` / `eligible` bonus.

```
POST /joining-bounce/cancel
Authorization: Bearer <token>
```
```json
{ "joiningBounceId": "665f0c2a…" }   // required here
```
**200:** `{ "success": true, "message": "Joining bonus cancelled successfully." }`

---

## Status lifecycle (for the UI)

```
in_progress ──(all requirements met)──▶ eligible ──(claim)──▶ credited
     │                                     │
     └──────────── cancel ─────────────────┘ ──▶ cancelled
```

| status | UI |
|--------|----|
| `in_progress` | Show progress bar + checklist; Claim **disabled** |
| `eligible` | Show "🎉 You can claim!"; Claim **enabled** |
| `credited` | Show credited amount + `wallet_txn_id`; no Claim |
| `cancelled` / `expired` | Inactive; hide from main screen |

---

## Response field reference (the "progress payload")

| Field | Type | Notes |
|-------|------|-------|
| `joining_bounce_id` | string | Use for `/progress` and `/claim` |
| `tag_id` | string | Category/profession tag (e.g. `GENERAL_STORE`) |
| `account_type` | string | `BUSINESS` \| `INDIVIDUAL` |
| `status` | string | `in_progress`/`eligible`/`credited`/`cancelled`/`expired` |
| `bonus_amount` | int | **paise** |
| `bonus_inr` | int | **rupees** — display this |
| `currency` | string | `INR` |
| `progress_percent` | int | 0–100 (progress bar) |
| `eligible` | bool | `true` ⇒ enable Claim |
| `requirements` | object | `days/hours/tasks/streak` → `{required,current,met}`; `milestones` → `{required,completed,missing,met}` |
| `days_active`,`total_hours`,`total_tasks` | number | Raw counters |
| `current_streak`,`longest_streak` | int | Streaks |
| `completed_milestones` | string[] | Done milestone keys |
| `enrolled_at`,`eligible_at`,`credited_at` | ISO date / null | Timeline |
| `credited_amount` | int | paise actually credited |

---

## Dart example

```dart
class JoiningBounceApi {
  final Dio dio; // baseUrl = subscribe-service host
  JoiningBounceApi(this.dio);

  Options _auth(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  /// Current active bonus, or null if the user has none (404).
  /// Pass [tagId] = the user's business category / profession so the backend
  /// auto-creates the bonus on first visit. account_type comes from the token.
  Future<Map<String, dynamic>?> getCurrent(String token, {String? tagId}) async {
    try {
      final res = await dio.get('/joining-bounce/current',
          queryParameters: tagId != null ? {'tag_id': tagId} : null,
          options: _auth(token));
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // no applicable bonus
      rethrow;
    }
  }

  Future<List<dynamic>> getMyBounces(String token, {String? status}) async {
    final res = await dio.get('/joining-bounce/my-bounces',
        queryParameters: status != null ? {'status': status} : null,
        options: _auth(token));
    return res.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getProgress(String token, String id) async {
    final res = await dio.get('/joining-bounce/$id/progress', options: _auth(token));
    return res.data['data'] as Map<String, dynamic>;
  }

  /// Claim an eligible bonus. Throws on 400/404/409/502 — handle per the table.
  Future<Map<String, dynamic>> claim(String token, String id) async {
    final res = await dio.post('/joining-bounce/claim',
        data: {'joiningBounceId': id}, options: _auth(token));
    return res.data['data'] as Map<String, dynamic>;
  }
}
```

```dart
// Reading requirements for the checklist:
final req = data['requirements'] as Map<String, dynamic>;
final daysMet   = req['days']['met']   as bool;
final hoursMet  = req['hours']['met']  as bool;
final tasksMet  = req['tasks']['met']  as bool;
final streakMet = req['streak']['met'] as bool;
final missingMilestones =
    List<String>.from(req['milestones']['missing'] as List);

final canClaim = data['eligible'] == true; // enable Claim button
final progress = (data['progress_percent'] as num).toDouble() / 100.0;
```

---

## ⛔ Endpoints you must NOT call

These are now **backend-only** (auto-tracked). They still exist for backward
compatibility but are **deprecated for the app** — do not integrate them:

| ~~Method~~ | ~~Endpoint~~ | Replaced by |
|--------|----------|-------------|
| ~~POST~~ | ~~`/joining-bounce/enroll`~~ | Automatic enrollment when user becomes BUSINESS/INDIVIDUAL |
| ~~POST~~ | ~~`/joining-bounce/activity`~~ | Automatic activity tracking from microservices |
| ~~POST~~ | ~~`/joining-bounce/milestone`~~ | Automatic milestone hooks (profile/KYC/order/product/channel/hours…) |
| ~~GET/POST/DELETE~~ | ~~`/joining-bounce/plans`, `/create-plan`, `/plan/:tag`, `/plan/:id`~~ | Admin/catalog only — not for the user app |

**Rule of thumb:** if it changes progress, the app does not send it. The app only
**reads** (`current`, `my-bounces`, `progress`) and **claims**.
