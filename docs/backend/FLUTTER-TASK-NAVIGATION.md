# Earn Coin — Flutter Task Navigation Guide

A practical guide for Flutter developers: how to read the `/earn/tasks` response,
what every task type means, and **exactly where to navigate** when the user taps a
task card.

> One rule to remember: **navigate by `event_name`.** It is the stable task type.
> `icon` is the asset key, `cta` is the button label. Never parse `title` for logic.

---

## 1. Endpoint

```
GET {{base_url}}/earn/tasks
Authorization: Bearer <token>
```

Optional: `?tag_id=<category-or-profession>` to override the user's category.

---

## 2. Response shape

```jsonc
{
  "success": true,
  "data": {
    "summary": { "total": 6, "completed": 4, "pending": 2, "percent": 67 },
    "tasks": [
      {
        "id": "6a4246715fa976d6d8a1bacd",
        "title": "Complete Your Profile",
        "event_name": "PROFILE_COMPLETED",   // ← navigate by THIS
        "coin": 50,
        "xp": 20,
        "badge": "Verified",
        "completed": false,
        "progress": 0,                        // 0..100
        "repeatable": false,
        "cta": "Complete Profile",            // button label
        "icon": "PROFILE",                    // asset key
        "image_url": "",
        "task_order": 1,
        "visibility": true,
        "completed_source": null,             // "event" | "state" | null
        "pending": [                          // what's still left (empty if done)
          { "key": "bio", "label": "Bio" },
          { "key": "profession", "label": "Profession" }
        ]
      }
    ]
  }
}
```

### Field cheat-sheet

| Field | Type | Use it for |
|---|---|---|
| `event_name` | string | **Navigation** — `switch` on this |
| `icon` | string | Which illustration/asset to show |
| `cta` | string | Button text (may be empty → hide button) |
| `title` | string | Card heading (display only) |
| `coin` / `xp` | int | Reward chips |
| `badge` | string | Badge label (empty → none) |
| `completed` | bool | Show ✓ / grey-out the card |
| `progress` | int (0–100) | Progress bar |
| `repeatable` | bool | Show "repeatable" hint; task can be done again |
| `completed_source` | `event` \| `state` \| `null` | Why it's complete (see §5) |
| `pending` | array | Exact remaining steps for this task (see §4) |
| `task_order` | int | Sort ascending for display order |
| `visibility` | bool | Always `true` in this list (hidden ones are pre-filtered) |

Render order: sort by `task_order` ascending (the API already does, but be safe).

---

## 3. Task types → where to navigate

Switch on `event_name`. Tasks are grouped as **Universal** (any user) and
**Category/Profession-specific** (only sent when relevant to the user).

### 3a. Universal tasks (every account type)

| `event_name` | `icon` | Meaning | Navigate to (on tap) |
|---|---|---|---|
| `PROFILE_COMPLETED` | `PROFILE` | Fill profile to threshold | **Profile edit screen** |
| `KYC_APPROVED` | `KYC` | Verify identity/documents | **KYC / document verification** |
| `FIRST_LOGIN` | `LOGIN` | Welcome bonus | No nav (auto-completes) |
| `DAILY_LOGIN` | `LOGIN` | Daily check-in | **Home / streak** (call `/earn/streak`) |
| `REFERRAL_SUCCESS` | `REFERRAL` | Invite a friend | **Referral / invite screen** |
| `BANNER_UPLOADED` | `BANNER` | Add cover banner | **Profile → edit cover/banner** |

> `SUBSCRIPTION_PURCHASED` (`SUBSCRIPTION`) is **paused** and no longer sent.
> If you ever receive it again, route to the **Subscription plans** screen.

### 3b. Business — by category

| `event_name` | `icon` | Sent to (category) | Navigate to |
|---|---|---|---|
| `HOTEL_VERIFIED` | `HOTEL` | Hospitality & Stay only | **Hotel/property verification** |
| `LAB_VERIFIED` | `LAB` | Diagnostic only | **Lab verification** |
| `FIRST_ORDER` | `ORDER` | Order-based businesses | **Orders** |
| `ORDER_COMPLETED` | `ORDER` | Order-based businesses | **Orders** |
| `INVENTORY_ADDED` | `INVENTORY` | Retail / food | **Add inventory / menu** |
| `PRODUCT_UPLOADED` | `PRODUCT` | Sellers | **Add product** |
| `FIRST_SELL` | `SELL` | Sellers | **Catalog / storefront** |
| `REVIEW_RECEIVED` | `REVIEW` | Service/lead businesses | **Reviews** |
| `ACCOUNT_VERIFIED` | `VERIFIED` | Verifiable accounts | **Account verification** |

### 3c. Individual — by profession / creator type

| `event_name` | `icon` | Sent to | Navigate to |
|---|---|---|---|
| `RIDE_COMPLETED` | `RIDE` | Riders / drivers | **Go online / rides** |
| `VIDEO_UPLOADED` | `VIDEO` | Creators | **Upload video** |
| `POST_CREATED` | `POST` | Social users | **Create post** |
| `CHANNEL_CREATED` | `CHANNEL` | Creators | **Create channel** |
| `CHANNEL_VERIFIED` | `CHANNEL` | Creators | **Channel verification** |
| `FOLLOWER_MILESTONE` | `FOLLOWERS` | Creators | **Channel / followers** |
| `JOB_POSTED` | `JOB` | Employers | **Post a job** |
| `JOB_HIRED` | `JOB` | Employers | **Applicants / hiring** |

> **Unknown `event_name`?** `icon` falls back to `TASK`. Show a generic card and,
> if `cta` is non-empty, a button that deep-links to your home/dashboard. Never crash
> on an unknown type — new task types can be added server-side any time.

The authoritative list of every `event_name` + `icon` lives in the backend at
`src/constants/earnEvents.js` (`EARN_EVENTS`, `EVENT_ICONS`).

---

## 4. `pending[]` — show the user exactly what's left

When `completed == false`, `pending` lists the precise remaining steps. Render it as
a checklist under the card.

- **Profile** → the actual missing fields, e.g.
  `[{ "key": "bio", "label": "Bio" }, { "key": "profession", "label": "Profession" }]`
  → deep-link each row into that profile field if you can.
- **KYC** → the steps, e.g.
  `[{ "key": "kyc_documents", "label": "Upload a valid government ID" },
    { "key": "kyc_approval", "label": "Wait for verification approval" }]`
- **Other tasks** → a single step describing the action.

When `completed == true`, `pending` is `[]`.

---

## 5. `completed_source` — how it got completed

| Value | Meaning | UI hint |
|---|---|---|
| `"event"` | Completed via a real reward event (coins credited) | Normal ✓ + reward chip |
| `"state"` | Reconciled from real data (user already did it before the reward system existed) | Show ✓; coins may not have been credited retroactively |
| `null` | Not completed yet | Show `pending[]` |

You don't need to branch on this for navigation — it's informational. Optionally show a
subtle "already done" state for `"state"`.

---

## 6. Navigation flow (pseudocode)

```dart
void onTaskTap(Task task) {
  if (task.completed) {
    // Optional: show a "completed" toast; still allow re-entry for repeatable tasks.
    if (!task.repeatable) return;
  }

  switch (task.eventName) {
    // ---- Universal ----
    case 'PROFILE_COMPLETED':   goToProfileEdit(); break;
    case 'KYC_APPROVED':        goToKyc(); break;
    case 'DAILY_LOGIN':         goToHomeStreak(); break;
    case 'REFERRAL_SUCCESS':    goToReferral(); break;
    case 'BANNER_UPLOADED':     goToProfileBanner(); break;
    case 'FIRST_LOGIN':         /* no-op, auto */ break;

    // ---- Business by category ----
    case 'HOTEL_VERIFIED':      goToHotelVerification(); break;
    case 'LAB_VERIFIED':        goToLabVerification(); break;
    case 'FIRST_ORDER':
    case 'ORDER_COMPLETED':     goToOrders(); break;
    case 'INVENTORY_ADDED':     goToInventory(); break;
    case 'PRODUCT_UPLOADED':
    case 'FIRST_SELL':          goToCatalog(); break;
    case 'REVIEW_RECEIVED':     goToReviews(); break;
    case 'ACCOUNT_VERIFIED':    goToAccountVerify(); break;

    // ---- Individual / creator ----
    case 'RIDE_COMPLETED':      goToRides(); break;
    case 'VIDEO_UPLOADED':      goToVideoUpload(); break;
    case 'POST_CREATED':        goToCreatePost(); break;
    case 'CHANNEL_CREATED':
    case 'CHANNEL_VERIFIED':
    case 'FOLLOWER_MILESTONE':  goToChannel(); break;
    case 'JOB_POSTED':
    case 'JOB_HIRED':           goToJobs(); break;

    // ---- Fallback ----
    default:                    goToHome(); // unknown/new type → safe default
  }
}
```

---

## 7. Rendering rules (quick reference)

1. **Sort** tasks by `task_order` ascending.
2. **Card**: `icon` → asset, `title`, `coin`/`xp` chips, `badge` if non-empty.
3. **State**: `completed` → ✓ + grey; else show `progress` bar + `pending[]` checklist.
4. **Button**: show only if `cta` is non-empty; label = `cta`; tap → §6 switch.
5. **Summary header**: use `data.summary` → `"{completed} of {total} completed"` +
   `percent` for the ring/bar.
6. **Unknown `event_name`** → generic card, default nav, never crash.

---

## 8. Related endpoints

| Screen | Endpoint |
|---|---|
| Coin/XP balance, badges | `GET /earn/balance` |
| Daily streak | `GET /earn/streak` |
| Coin history (paginated) | `GET /earn/history?limit=&cursor=` |
| Leaderboard | `GET /earn/leaderboard?limit=` |
| Earn home aggregate | `GET /earn/dashboard` |

Full API docs: Swagger (`src/swaggers/earn.swagger.js`) or the Postman collection at
`docs/earn-coin/coin-earn-user.postman_collection.json`.
