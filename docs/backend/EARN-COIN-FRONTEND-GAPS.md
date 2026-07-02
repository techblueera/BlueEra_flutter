# Earn-Coin — Frontend/Backend Gaps

Fields the Coin Wallet dashboard UI (see `assets/Dash.png`, `Task.png`,
`History.png`, `Rank.png`, `Streak.png`) needs but that the current
`earn-service` endpoints (per `FLUTTER-MASTER-GUIDE.md`) do **not** return.
The app renders a sensible fallback for each so nothing breaks; backend should
add these so the numbers/artwork are real.

## 1. Dashboard "Days" stat — MISSING
- **Screen:** Dashboard tab, 4th stat cell ("50 / Days").
- **Endpoint:** `GET /earn/dashboard`.
- **Gap:** response has `balance.coins`, `balance.xp`, `streak.streak` but **no
  "days" value** (total active earning days).
- **Frontend fallback (temporary):** reads `data.streak.days`, else
  `data.activeDays`, else `data.streak.longestStreak`, else `0`
  (`EarnDashboard.activeDays`).
- **Requested:** add `data.activeDays` (int) — total number of days the user has
  earned/been active — to the dashboard payload (or `data.streak.days`).

## 2. Per-task illustration/icon — MISSING (cosmetic, worked around)
- **Screen:** Tasks tab — each card shows a 3D illustration (profile avatar,
  clipboard, …) on the right.
- **Endpoint:** `GET /earn/tasks` / `GET /earn/dashboard` (`tasks[]`).
- **Gap:** task objects have no `image`/`icon` field.
- **Frontend workaround (current):** the illustration is chosen by keyword —
  `event_name`/`title` containing `PROFILE` → profile art, otherwise the
  documents art.
- **Requested (optional):** add a stable `icon` key per task
  (`PROFILE` / `KYC` / `ORDER` / …) or an `image_url`, so mapping isn't
  keyword-based.

## 3. Fully covered by the API (no gap)
- **History** — `GET /earn/history` gives title, coins, xp, status, createdAt,
  type; the "Filter" (All/Credited/Debited) is done client-side on `type`.
- **Rank** — `GET /earn/leaderboard` gives `me` (rank/coins/xp) + `entries[]`
  (rank/name/avatar/coins/xp/isMe).
- **Streak** — `GET /earn/streak` gives streak/longestStreak/checkedInToday/
  lastEarnedAt.

## Design assets — PROVIDED ✅
Artwork supplied and wired in (`assets/images/`, `AppImageAssets`):
- `coin_header_bg.png` — coin-pattern blue header background.
- `task_profile.png`, `task_documents.png` — Tasks illustrations.
- `earn_trophy.png` — Rank "My Rank" trophy.
- `earn_flame.png`, `earn_calendar.png`, `earn_verified_badge.png` — Streak.

Still using `coin_icon.png` for the small coin glyph in the header/chips (a
dedicated 3D coin-stack could replace it if desired).
