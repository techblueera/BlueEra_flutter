# Joining Bounce (Joining Bonus) — Frontend Integration Guide (Flutter)

A complete guide for integrating the **Joining Bounce** flow. All field names,
status values, and response keys below match the backend **exactly** — use them
verbatim when parsing JSON.

> Source of truth: [`joiningBounce.controller.js`](../src/controllers/joiningBounce.controller.js),
> [`joiningBounce.route.js`](../src/routes/joiningBounce.route.js),
> [`JoiningBouncePlan.js`](../src/model/JoiningBouncePlan.js),
> [`UserJoiningBounce.js`](../src/model/UserJoiningBounce.js),
> [`joiningBounceProgress.js`](../src/utils/joiningBounceProgress.js).

---

## 1. What this feature is

**Joining Bounce is the _inverse_ of the Security Deposit.** Instead of the user
paying the platform, the **platform pays the user** a one-time joining bonus once
they prove genuine onboarding.

Every business / profession is identified by a **`tag_id`** (e.g. `GENERAL_STORE`)
and an **`account_type`** (`BUSINESS` or `INDIVIDUAL`). The frontend sends those
exactly as it already does for Security Deposit:

```
Individuals  → professions  → account_type = "INDIVIDUAL"   (e.g. ELECTRICIAN, PLUMBER)
Businesses   → categories    → account_type = "BUSINESS"      (e.g. GENERAL_STORE, PHARMACY)
```

For each combination there is a **Joining Bounce Plan** describing the bonus and
the requirements to earn it:

| Field | Meaning |
|---|---|
| `bonus_amount` | Bonus in **paise** (e.g. `426000` = ₹4260) |
| `bonus_inr` | Same bonus in whole rupees, for display |
| `min_days` | Minimum number of **active days** |
| `min_hours` | Minimum total **active hours** |
| `min_tasks` | Minimum **tasks** completed |
| `required_streak` | Required **longest consecutive-active-day streak** |
| `required_milestones` | Named onboarding milestones to complete |

The user side is a **`UserJoiningBounce`** record that moves through a lifecycle:

```
in_progress  →  eligible  →  credited
            ↘  cancelled / expired
```

- **`in_progress`** — enrolled, accruing progress.
- **`eligible`** — every threshold met; the bonus can be claimed.
- **`credited`** — bonus paid into the user's platform **wallet** (via the wallet
  gRPC service, idempotent on the record id).

> 💡 There is **no Razorpay / no payment** anywhere in this flow. It is a payout,
> not a charge.

---

## 2. Base setup

| Item | Value |
|---|---|
| Base URL (local) | `http://localhost:3000` |
| Route prefix | `/joining-bounce` |
| Auth | `Authorization: Bearer <JWT>` on **every** endpoint |
| Content-Type | `application/json` for POST bodies |
| Money unit | **paise** (₹1 = 100). `bonus_amount: 426000` → ₹4260 |

**Standard response envelope** (all endpoints):

```json
{ "success": true, "message": "Human readable", "data": { } }
```

On error: `{ "success": false, "message": "…", "error": "…" }`.

---

## 3. The typical app flow

```
1. Show catalog        GET  /joining-bounce/plans?account_type=BUSINESS
2. User picks category POST /joining-bounce/enroll   { tag_id, account_type }
3. As the user works   POST /joining-bounce/activity { tag_id, hours, tasks, milestone }
   (or milestones)     POST /joining-bounce/milestone{ tag_id, milestone }
4. Poll progress       GET  /joining-bounce/current
5. When eligible       POST /joining-bounce/claim    { joiningBounceId }
   → bonus lands in the user's wallet
```

You usually only call `enroll` **once per category**, then drive progress with
`activity` / `milestone`, and finally `claim`.

---

## 4. Endpoints

### 4.1 List plans
`GET /joining-bounce/plans?tag_id=&account_type=`

Both query params are optional. Send `account_type=INDIVIDUAL` for the professions
tab and `account_type=BUSINESS` for the categories tab.

```json
{
  "success": true,
  "message": "Fetched successfully",
  "data": [
    {
      "_id": "…",
      "ui_tab": "Business",
      "ui_category_group": "Grocery & Stationary Stores",
      "name": "General Store",
      "tag_id": "GENERAL_STORE",
      "account_type": "BUSINESS",
      "bonus_amount": 426000,
      "bonus_inr": 4260,
      "min_days": 140,
      "min_hours": 880,
      "min_tasks": 50,
      "required_streak": 40,
      "required_milestones": [
        "business_profile_verified", "inventory_added",
        "store_marked_open", "order_ready_marked", "order_completed"
      ],
      "terms_and_conditions": ["…"],
      "why": ["…"],
      "currency": "INR",
      "active": true
    }
  ]
}
```

### 4.2 Get one plan by tag
`GET /joining-bounce/plan/:tagId?account_type=BUSINESS`

`:tagId` is tolerant of display names & casing (`/plan/General%20Store` works).

### 4.3 Enroll
`POST /joining-bounce/enroll`

```json
{ "tag_id": "GENERAL_STORE", "account_type": "BUSINESS" }
```
*or* `{ "joiningBouncePlanId": "<plan _id>" }`.

Returns the **progress object** (see §5). Calling it again for the same tag is
safe — it returns the existing record instead of creating a duplicate
(`message: "You are already enrolled …"`).

### 4.4 Record activity
`POST /joining-bounce/activity`

```json
{
  "tag_id": "GENERAL_STORE",   // or "joiningBounceId": "<id>"
  "hours": 2,                   // optional, added to total_hours
  "tasks": 1,                   // optional, added to total_tasks
  "milestone": "inventory_added", // optional, marks a required milestone
  "date": "2026-06-26T10:00:00Z"  // optional, defaults to now
}
```

Rules the backend enforces (so the UI doesn't have to):
- **Days & streak are counted once per calendar day (UTC).** Multiple reports on
  the same day add hours/tasks but do **not** double-count a day or the streak.
- A consecutive next-day report **increments** the streak; a gap of 2+ days
  **resets** `current_streak` to 1. `longest_streak` keeps your best run, and
  eligibility is judged against `longest_streak`.
- A `milestone` is only accepted if it's in the plan's `required_milestones`.

Response `message` becomes *"…you have met all requirements! You can now claim…"*
and `data.status` flips to `eligible` the moment everything is satisfied.

### 4.5 Complete a milestone
`POST /joining-bounce/milestone`

```json
{ "tag_id": "GENERAL_STORE", "milestone": "store_marked_open" }
```

Thin wrapper over `activity` for a pure milestone toggle. Returns `400` if the
milestone isn't part of the program (with `data.required_milestones`).

### 4.6 Current active bonus
`GET /joining-bounce/current` → the user's `in_progress` or `eligible` record
(progress object), or `404` if none.

### 4.7 History
`GET /joining-bounce/my-bounces?status=credited` → array of progress objects.
`status` is optional (`in_progress` | `eligible` | `credited` | `cancelled` | `expired`).

### 4.8 Detailed progress
`GET /joining-bounce/:joiningBounceId/progress` → progress object plus the
populated `plan`.

### 4.9 Claim the bonus
`POST /joining-bounce/claim`

```json
{ "joiningBounceId": "<id>" }   // optional; resolves your eligible record if omitted
```

Success:
```json
{
  "success": true,
  "message": "Joining bonus credited to your wallet successfully.",
  "data": {
    "joining_bounce_id": "…",
    "status": "credited",
    "credited_amount": 426000,
    "bonus_inr": 4260,
    "currency": "INR",
    "wallet_txn_id": "…"
  }
}
```

Failure modes to handle:
| HTTP | Meaning | UI action |
|---|---|---|
| `404` | No eligible record | Keep showing progress |
| `400` | Requirements not actually met | Refresh progress |
| `409` | Already claimed | Show "already credited" |
| `502` | Wallet credit failed | Show retry; the record stays `eligible` so re-tapping Claim is safe |

### 4.10 Cancel
`POST /joining-bounce/cancel` `{ "joiningBounceId": "<id>" }` — cancels an
`in_progress`/`eligible` record (cannot cancel a `credited` one).

---

## 5. The progress object (parse this everywhere)

`enroll`, `activity`, `milestone`, `current`, `my-bounces`, `:id/progress` all
return this shape inside `data`:

```json
{
  "joining_bounce_id": "…",
  "tag_id": "GENERAL_STORE",
  "account_type": "BUSINESS",
  "status": "in_progress",
  "is_active": true,
  "bonus_amount": 426000,
  "bonus_inr": 4260,
  "currency": "INR",
  "progress_percent": 47,
  "eligible": false,
  "requirements": {
    "days":   { "required": 140, "current": 12,  "met": false },
    "hours":  { "required": 880, "current": 96,  "met": false },
    "tasks":  { "required": 50,  "current": 8,   "met": false },
    "streak": { "required": 40,  "current": 12,  "met": false },
    "milestones": {
      "required": ["business_profile_verified","inventory_added","store_marked_open","order_ready_marked","order_completed"],
      "completed": ["business_profile_verified","inventory_added"],
      "missing": ["store_marked_open","order_ready_marked","order_completed"],
      "met": false
    }
  },
  "days_active": 12,
  "total_hours": 96,
  "total_tasks": 8,
  "current_streak": 12,
  "longest_streak": 12,
  "last_active_date": "2026-06-26T10:00:00.000Z",
  "completed_milestones": ["business_profile_verified","inventory_added"],
  "enrolled_at": "…",
  "eligible_at": null,
  "credited_at": null,
  "credited_amount": 0
}
```

- Drive the **progress bar** from `progress_percent` (0–100).
- Drive **per-requirement checkmarks** from `requirements.*.met`.
- Enable the **Claim button** only when `eligible === true` (or `status === "eligible"`).

---

## 6. Minimal Dart client

```dart
class JoiningBounceApi {
  JoiningBounceApi(this.baseUrl, this.token);
  final String baseUrl;
  final String token;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<List<dynamic>> plans({String? accountType, String? tagId}) async {
    final qp = {
      if (accountType != null) 'account_type': accountType,
      if (tagId != null) 'tag_id': tagId,
    };
    final uri = Uri.parse('$baseUrl/joining-bounce/plans').replace(queryParameters: qp);
    final res = await http.get(uri, headers: _headers);
    return jsonDecode(res.body)['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> enroll(String tagId, String accountType) async {
    final res = await http.post(
      Uri.parse('$baseUrl/joining-bounce/enroll'),
      headers: _headers,
      body: jsonEncode({'tag_id': tagId, 'account_type': accountType}),
    );
    return jsonDecode(res.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> recordActivity(String tagId,
      {num? hours, int? tasks, String? milestone}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/joining-bounce/activity'),
      headers: _headers,
      body: jsonEncode({
        'tag_id': tagId,
        if (hours != null) 'hours': hours,
        if (tasks != null) 'tasks': tasks,
        if (milestone != null) 'milestone': milestone,
      }),
    );
    return jsonDecode(res.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> current() async {
    final res = await http.get(
      Uri.parse('$baseUrl/joining-bounce/current'), headers: _headers);
    return jsonDecode(res.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> claim(String joiningBounceId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/joining-bounce/claim'),
      headers: _headers,
      body: jsonEncode({'joiningBounceId': joiningBounceId}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>; // read success/message/data
  }
}
```

---

## 7. Who calls `activity`?

Two valid sources, both supported:

1. **The app itself** — call `POST /joining-bounce/activity` when the user does
   something meaningful (logs a session, completes a task, finishes a milestone).
2. **Other backend services (recommended for real counters)** — order-service /
   task-service can report genuine activity server-to-server via the gRPC
   `JoiningBounceService.RecordActivity` RPC (see
   [`joiningBounce.proto`](../src/grpc/protos/joiningBounce.proto)). This keeps
   hours/tasks honest and tamper-proof. The app then just reads `current` /
   `progress` and shows the Claim button.

Pick per metric: milestones are naturally app-driven; hours/tasks/days are best
driven from the authoritative backend events.

---

## 8. Seeding the catalog (backend ops)

```bash
# Dry run (parse + print, no DB writes)
JOINING_BOUNCE_SEED_DRY_RUN=true \
  node src/scripts/seedJoiningBouncePlans.js \
  "public/blueEra_joining_bounce - BlueEra_Onboarding_Full_Schema.csv"

# Real upsert (idempotent on tag_id + account_type + mode)
JOINING_BOUNCE_SEED_MODE=live \
  node src/scripts/seedJoiningBouncePlans.js \
  "public/blueEra_joining_bounce - BlueEra_Onboarding_Full_Schema.csv"
```

The CSV's `JB_Current_Streak`, `JB_Last_Active_Date`, `JB_Completed_Milestones`
columns are **per-user progress** and are intentionally ignored by the seeder —
they live on `UserJoiningBounce`, not on the plan.
