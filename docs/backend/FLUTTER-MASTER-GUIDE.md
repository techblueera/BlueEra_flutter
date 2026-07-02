# Earn-Coin — Flutter Master Integration Guide (Wallet → Coin Wallet → View Details)

End-to-end guide for the coin screens: the **Coin chip + Coin Wallet card** on the Wallet
page, and the **View Details** screen with its 5 tabs (Dashboard, Tasks, History, Rank, Streak).
Every endpoint below is verified against the live backend controllers.

- **Base URL:** `https://be.beapp.in/api/earn-service`
- **Service-internal route prefix:** `/earn` → so a call is
  `GET https://be.beapp.in/api/earn-service/earn/balance`
- **Auth (all endpoints here):** header `Authorization: Bearer <JWT>` (same token as the rest of the app).
- **Response envelope (every endpoint):** `{ "success": true, "data": {...}, "message"?, "pagination"? }`.
  On error: `{ "success": false, "message": "...", "code"? }` with HTTP 400/401/404/409/500.
- **Coins vs money:** coins are a gamification currency owned by this service. **Redemption = 100 coins → ₹1, minimum 5000 coins.** Rupees live in the separate **wallet** service.

> ⚠️ **Not this service:** the "**Your Reward ₹400 Bonus — 2 of 9 Completed**" card on the Wallet
> page is the **Joining-Bounce** feature (a refundable ₹ bonus), served by the **subscribe**
> service — NOT earn-coin. Keep it separate from the Coin Wallet card. This guide is only the
> coin system.

---

## 1. Screen flow

```
Wallet page
 ├─ top-right "🪙 5000" chip ............ GET /earn/balance → data.coins
 ├─ "Your Reward ₹400 Bonus" card ....... (Joining-Bounce API — subscribe service, NOT here)
 └─ "Coin Wallet" card (Current/Lifetime/Redeemed/XP)
        └─ [View Details] ─────────────► Earn screen (5 tabs)
             ├─ Dashboard  ... GET /earn/dashboard
             ├─ Tasks      ... GET /earn/tasks
             ├─ History    ... GET /earn/history?cursor=&limit=
             ├─ Rank       ... GET /earn/leaderboard?limit=
             └─ Streak     ... GET /earn/streak
        (Redeem coins → ₹) .. POST /earn/redeem
```

Earning is **automatic** (backend). The app only **reads** these screens and can **redeem**.
Every read endpoint also silently records the user's daily-login streak server-side — no check-in call needed.

---

## 2. Endpoint reference (with exact UI key mapping)

### 2.1 `GET /earn/balance` — coin chip + Coin Wallet card
Headers: `Authorization: Bearer <JWT>`. No query/body.

Response:
```json
{
  "success": true,
  "data": {
    "userId": "6a4...318a",
    "coins": 200,
    "xp": 60,
    "lifetimeCoins": 150,
    "redeemedCoins": 0,
    "badges": ["Verified", "Starter"],
    "level": 0,
    "currency": "COIN",
    "coins_per_rupee": 100,
    "min_redeem_coins": 5000
  }
}
```

| UI element | Key |
|---|---|
| Wallet "🪙 5000" chip | `data.coins` |
| Coin Wallet → **Current Coins** | `data.coins` |
| Coin Wallet → **Lifetime Coins** | `data.lifetimeCoins` |
| Coin Wallet → **Redeemed Coins** | `data.redeemedCoins` |
| Coin Wallet → **XP** | `data.xp` |
| Redeem screen: rate & minimum | `data.coins_per_rupee` (100), `data.min_redeem_coins` (5000) |
| ₹ equivalent (if you show one) | `data.coins / data.coins_per_rupee` |

> The donut "Total" in the card is your choice — show total `coins`, or the ₹ equivalent
> (`coins / 100`). The 4 legend numbers map to the four keys above.

---

### 2.2 `GET /earn/dashboard` — Dashboard tab (one call powers the whole tab)
Headers: `Authorization: Bearer <JWT>`. No query/body.

Response:
```json
{
  "success": true,
  "data": {
    "balance": { "coins": 5000, "xp": 60, "lifetimeCoins": 150, "badges": ["Verified"], "currency": "COIN" },
    "streak": { "streak": 10, "checkedInToday": true },
    "taskSummary": { "total": 9, "completed": 2, "pending": 7 },
    "pendingTasks": 7,
    "tasks": [
      { "id": "665...", "title": "Complete Your Profile", "event_name": "PROFILE_COMPLETED",
        "coin": 50, "xp": 20, "badge": "Verified", "completed": false, "progress": 40,
        "repeatable": false, "cta": "Complete Profile", "task_order": 1, "visibility": true }
    ],
    "recent": [
      { "id": "778...", "event_name": "DAILY_LOGIN", "title": "Daily Login",
        "coins": 50, "xp": 20, "status": "CREDITED", "createdAt": "2026-06-30T09:03:30.801Z" }
    ],
    "redemption": { "coins_per_rupee": 100, "min_redeem_coins": 5000 }
  }
}
```

| UI element | Key |
|---|---|
| Header "Total Coins Balance 5000" | `data.balance.coins` |
| Stat card **Coins** | `data.balance.coins` |
| Stat card **Streak** | `data.streak.streak` |
| Stat card **Days** (optional) | `data.streak.streak` / longest via Streak tab |
| **Recent Earning** rows: left title | `data.recent[].title` (e.g. "Daily Login") |
| Recent row: "50 Coins \| 20 XP" | `data.recent[].coins`, `data.recent[].xp` |
| Recent row: "Credited" | `data.recent[].status` |
| Recent row: date "30 Jun, 2026" | `data.recent[].createdAt` (format client-side) |
| "View All" → | open **History** tab |

---

### 2.3 `GET /earn/tasks` — Tasks tab
Headers: `Authorization: Bearer <JWT>`. Optional query: `tag_id` (normally omit — resolved from the token).

Response:
```json
{
  "success": true,
  "data": {
    "summary": { "total": 9, "completed": 2, "pending": 7, "percent": 22 },
    "tasks": [
      { "id": "665...", "title": "Complete Your Profile", "event_name": "PROFILE_COMPLETED",
        "coin": 50, "xp": 20, "badge": "Verified", "completed": false, "progress": 40,
        "repeatable": false, "cta": "Complete Profile", "task_order": 1, "visibility": true },
      { "id": "666...", "title": "Verify Documents", "event_name": "KYC_APPROVED",
        "coin": 100, "xp": 30, "badge": "Trusted", "completed": false, "progress": 70,
        "repeatable": false, "cta": "Verify Now", "task_order": 2, "visibility": true }
    ]
  }
}
```

| UI element | Key |
|---|---|
| "**2 of 9 Completed**" / progress ring | `data.summary.completed` of `data.summary.total`, `data.summary.percent` |
| Task card title | `data.tasks[].title` |
| "Badge: Verified" | `data.tasks[].badge` |
| "50 Coins  20 XP" | `data.tasks[].coin`, `data.tasks[].xp` |
| Task progress bar "40%" | `data.tasks[].progress` (0–100) |
| CTA button ("Complete profile"/"Verify Now") | `data.tasks[].cta` |
| Completed state (tick) | `data.tasks[].completed === true` |
| Sort order (1,2,3…) | `data.tasks[].task_order` (already sorted) — use array index for "Task N" |

> "Task 1 of 5 / first task complete": use the array position (1-based) for the number, and
> `summary.completed`/`summary.total` for the "X of Y" line.

---

### 2.4 `GET /earn/history` — History tab (paginated, cursor-based)
Headers: `Authorization: Bearer <JWT>`. Query: `limit` (default 20, max 100), `cursor` (from previous page's `nextCursor`; omit for first page).

`GET /earn/history?limit=20`
```json
{
  "success": true,
  "data": [
    { "id": "778...", "event_name": "DAILY_LOGIN", "title": "Daily Login",
      "coins": 50, "xp": 20, "badge": "", "type": "CREDIT", "status": "CREDITED",
      "sourceService": "be_earn_with_blueera_service", "sourceId": "", "createdAt": "2026-06-30T09:03:30.801Z" },
    { "id": "779...", "event_name": "REDEMPTION", "title": "Coin Redemption",
      "coins": -5000, "xp": 0, "type": "DEBIT", "status": "DEBITED", "createdAt": "2026-06-29T18:00:00.000Z" }
  ],
  "pagination": { "limit": 20, "nextCursor": "779...", "hasMore": true }
}
```

| UI element | Key |
|---|---|
| Row title ("Daily Login") | `data[].title` |
| "50 Coins \| 20 XP" | `data[].coins`, `data[].xp` (negative coins = a debit/redeem) |
| "Credited"/"Debited" chip | `data[].status` |
| Date "30 Jun, 2026" | `data[].createdAt` |
| Infinite scroll / next page | send `?cursor=<pagination.nextCursor>`; stop when `hasMore=false` |
| Filter (optional) | filter client-side by `type` (CREDIT/DEBIT) or `event_name` |

---

### 2.5 `GET /earn/leaderboard` — Rank tab
Headers: `Authorization: Bearer <JWT>`. Query: `limit` (default 50, max 100).

Response:
```json
{
  "success": true,
  "data": {
    "entries": [
      { "rank": 1, "userId": "6a1...", "name": "Ritesh", "avatar": "https://...", "coins": 10000, "xp": 10, "isMe": false },
      { "rank": 2, "userId": "6a2...", "name": "You",    "avatar": "",           "coins": 980,   "xp": 9,  "isMe": true }
    ],
    "me": { "rank": 1, "coins": 10000, "xp": 20 }
  }
}
```

| UI element | Key |
|---|---|
| "My Rank #1" | `data.me.rank` |
| My coins / XP (under My Rank) | `data.me.coins`, `data.me.xp` |
| Table row: Rank | `data.entries[].rank` |
| Table row: User (name) | `data.entries[].name` (avatar: `data.entries[].avatar`) |
| Table row: Coins / XP | `data.entries[].coins`, `data.entries[].xp` |
| Highlight "You" row | `data.entries[].isMe === true` |

> Names/avatars are best-effort (resolved from the user service). If empty, fall back to a
> masked id or placeholder. Ranks are refreshed by a backend snapshot every ~15 min.

---

### 2.6 `GET /earn/streak` — Streak tab
Headers: `Authorization: Bearer <JWT>`. No query/body.

Response:
```json
{
  "success": true,
  "data": { "streak": 2, "longestStreak": 2, "checkedInToday": true, "lastEarnedAt": "2026-06-30T09:03:30.801Z" }
}
```

| UI element | Key |
|---|---|
| "Current Streak 2 Days" | `data.streak` |
| "Longest Streak" | `data.longestStreak` |
| "Checked In Today — Yes/No" | `data.checkedInToday` |
| "Last Earned 30 Jun 2026" | `data.lastEarnedAt` |

---

### 2.7 `POST /earn/redeem` — convert coins → ₹ (credited to the money Wallet)
Headers: `Authorization: Bearer <JWT>`, `Content-Type: application/json`.
Body:
```json
{ "coins": 5000, "request_id": "optional-client-uuid-for-idempotency" }
```
Rules: `coins` must be **≥ 5000** and a **multiple of 100**. `request_id` is optional but
recommended (pass a stable UUID so a retry can't double-redeem).

Success `200`:
```json
{
  "success": true,
  "data": {
    "reference_id": "665abc...",
    "status": "COMPLETED",
    "coins": 5000,
    "rupees": 50,
    "wallet_transaction_id": "77af...",
    "created_at": "2026-07-01T10:00:00.000Z",
    "idempotent_replay": false
  }
}
```
Errors: `400 BELOW_MINIMUM` / `400 NON_DIVISIBLE` / `400 INSUFFICIENT_COINS` /
`409 IN_PROGRESS` / `502 WALLET_CREDIT_FAILED` (coins auto-refunded). Body carries `code` + `message`.

**After a successful redeem:** refresh `GET /earn/balance` (coins ↓, redeemedCoins ↑) and the
credited ₹ will appear in the **money Wallet history** automatically. The Wallet page's
"**Withdraw**" button is the rupee-wallet withdrawal (separate service) — do not confuse it with coin redeem.

---

## 3. Dart models (null-safe)

```dart
class CoinBalance {
  final int coins, xp, lifetimeCoins, redeemedCoins, level, coinsPerRupee, minRedeemCoins;
  final List<String> badges;
  CoinBalance({required this.coins, required this.xp, required this.lifetimeCoins,
    required this.redeemedCoins, required this.level, required this.badges,
    required this.coinsPerRupee, required this.minRedeemCoins});
  factory CoinBalance.fromJson(Map<String, dynamic> j) => CoinBalance(
    coins: j['coins'] ?? 0, xp: j['xp'] ?? 0,
    lifetimeCoins: j['lifetimeCoins'] ?? 0, redeemedCoins: j['redeemedCoins'] ?? 0,
    level: j['level'] ?? 0, badges: List<String>.from(j['badges'] ?? const []),
    coinsPerRupee: j['coins_per_rupee'] ?? 100, minRedeemCoins: j['min_redeem_coins'] ?? 5000);
  double get rupeeEquivalent => coinsPerRupee == 0 ? 0 : coins / coinsPerRupee;
}

class EarnTask {
  final String id, title, eventName, badge, cta;
  final int coin, xp, progress, taskOrder;
  final bool completed, repeatable;
  EarnTask.fromJson(Map<String, dynamic> j)
    : id = j['id'] ?? '', title = j['title'] ?? j['event_name'] ?? '',
      eventName = j['event_name'] ?? '', badge = j['badge'] ?? '', cta = j['cta'] ?? '',
      coin = j['coin'] ?? 0, xp = j['xp'] ?? 0, progress = j['progress'] ?? 0,
      taskOrder = j['task_order'] ?? 0, completed = j['completed'] ?? false,
      repeatable = j['repeatable'] ?? false;
}

class EarnHistoryItem {
  final String id, title, eventName, status, type;
  final int coins, xp;
  final DateTime? createdAt;
  EarnHistoryItem.fromJson(Map<String, dynamic> j)
    : id = j['id'] ?? '', title = j['title'] ?? j['event_name'] ?? '',
      eventName = j['event_name'] ?? '', status = j['status'] ?? '', type = j['type'] ?? '',
      coins = j['coins'] ?? 0, xp = j['xp'] ?? 0,
      createdAt = j['createdAt'] != null ? DateTime.tryParse(j['createdAt']) : null;
}

class LeaderboardEntry {
  final int rank, coins, xp; final String userId, name, avatar; final bool isMe;
  LeaderboardEntry.fromJson(Map<String, dynamic> j)
    : rank = j['rank'] ?? 0, coins = j['coins'] ?? 0, xp = j['xp'] ?? 0,
      userId = j['userId'] ?? '', name = j['name'] ?? '', avatar = j['avatar'] ?? '',
      isMe = j['isMe'] ?? false;
}

class Streak {
  final int streak, longestStreak; final bool checkedInToday; final DateTime? lastEarnedAt;
  Streak.fromJson(Map<String, dynamic> j)
    : streak = j['streak'] ?? 0, longestStreak = j['longestStreak'] ?? 0,
      checkedInToday = j['checkedInToday'] ?? false,
      lastEarnedAt = j['lastEarnedAt'] != null ? DateTime.tryParse(j['lastEarnedAt']) : null;
}
```

## 4. Repository (Dio)

```dart
class EarnApi {
  final Dio dio; // baseUrl: https://be.beapp.in/api/earn-service
  EarnApi(this.dio);

  Map<String, dynamic> _unwrap(Response r) {
    final b = r.data as Map<String, dynamic>;
    if (b['success'] != true) throw Exception(b['message'] ?? 'Earn API error');
    return b;
  }

  Future<CoinBalance> balance() async =>
    CoinBalance.fromJson(_unwrap(await dio.get('/earn/balance'))['data']);

  Future<Map<String, dynamic>> dashboard() async =>
    _unwrap(await dio.get('/earn/dashboard'))['data'];

  Future<Map<String, dynamic>> tasks() async =>
    _unwrap(await dio.get('/earn/tasks'))['data']; // { summary, tasks }

  Future<(List<EarnHistoryItem>, String?)> history({String? cursor, int limit = 20}) async {
    final b = _unwrap(await dio.get('/earn/history',
        queryParameters: {'limit': limit, if (cursor != null) 'cursor': cursor}));
    final items = (b['data'] as List).map((e) => EarnHistoryItem.fromJson(e)).toList();
    return (items, b['pagination']?['nextCursor'] as String?);
  }

  Future<Map<String, dynamic>> leaderboard({int limit = 50}) async =>
    _unwrap(await dio.get('/earn/leaderboard', queryParameters: {'limit': limit}))['data'];

  Future<Streak> streak() async =>
    Streak.fromJson(_unwrap(await dio.get('/earn/streak'))['data']);

  Future<Map<String, dynamic>> redeem(int coins, {String? requestId}) async =>
    _unwrap(await dio.post('/earn/redeem',
        data: {'coins': coins, if (requestId != null) 'request_id': requestId}))['data'];
}
```
Attach the JWT via a Dio interceptor: `options.headers['Authorization'] = 'Bearer $token'`.

## 5. Screen → endpoint cheat-sheet

| Screen / widget | Call | Refresh when |
|---|---|---|
| Wallet coin chip + Coin Wallet card | `GET /earn/balance` | wallet page open, after redeem |
| Tap **View Details** → Dashboard tab | `GET /earn/dashboard` | tab open / pull-to-refresh |
| Tasks tab | `GET /earn/tasks` | tab open; after user finishes a task action |
| History tab (+ "View All") | `GET /earn/history` | tab open; paginate on scroll |
| Rank tab | `GET /earn/leaderboard` | tab open |
| Streak tab | `GET /earn/streak` | tab open |
| Redeem action | `POST /earn/redeem` | on user confirm; then re-fetch balance |

## 6. Behavior notes
- **No "earn coin" button.** Coins accrue automatically server-side; screens are read-only except redeem.
- **Streak auto-updates** whenever the user opens any earn screen (server-side, idempotent per day) — no check-in call.
- **Amounts:** coins & XP are integers. Negative `coins` in history = a debit (redeem/refund).
- **Empty states:** new user → `coins:0`, `tasks` all `completed:false`, empty `history`, `streak:0`.
- **Auth failure:** 401 → refresh token / re-login (same flow as other services).
- **Redeem min:** enforce `coins >= 5000` and multiple of 100 client-side too, for instant feedback.
```
