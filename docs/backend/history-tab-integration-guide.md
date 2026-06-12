# History Tab — Frontend Integration Guide

This guide covers the new **History** tab: business conversations automatically
move out of the Business tab and into History **12 hours after they are created**.

- **New conversation type:** `history`
- **Trigger:** a background sweep (every 10 min) flips qualifying `business`
  conversations to `history` once they are older than 12h.
- **Frontend work:** add a History tab that fetches conversations with
  `type: "history"` — same payload shape as the Business tab.

---

## What moves to History

| Conversation | Moves to History? |
|---|---|
| Any 1:1 `business` conversation (orders, rider-association, stranger/b2b chats) | ✅ 12h after creation |
| The multi-party **"BlueEra Orders"** broadcast group (`orders_conversation: true`) | ❌ excluded |
| `personal`, `group`, `request` conversations | ❌ never |

> Only the conversation's `type` changes (`business` → `history`). Everything
> else — `is_order`, `business_owner_user_id`, all messages, `last_message`,
> `created_at` — is preserved. `updated_at` is intentionally **not** bumped, so a
> conversation keeps its position in the list ordering when it lands in History.

The clock is based on **creation time** (`created_at`), not last activity. A
conversation created at `T` moves to History at `T + 12h` regardless of how
recently it was messaged.

---

## Lifecycle (why History accumulates multiple convos per pair)

Business/order conversations are normally **reused** per user-pair. Once a
conversation ages into History, it is no longer matched by the
"find-or-create business conversation" logic, so the **next** order/business
interaction between the same two users creates a **fresh** business conversation.
That fresh one ages out 12h later too. Over time a pair accumulates several
History entries:

```
Day 1 10:00  A orders from B           → business convo #1 (Business tab)
Day 1 22:00  (12h later, sweep runs)   → convo #1 → History tab
Day 2 09:00  A orders from B again      → business convo #2 (Business tab)
Day 2 21:00  (12h later)               → convo #2 → History tab
            History tab for A now shows: [#2, #1]
```

---

## Fetching the tabs

### Socket — `ChatList` (primary)

Emit `ChatList` with the tab's `type`. Each call returns exactly one bucket.

```js
// History tab
socket.emit("ChatList", { type: "history" });

socket.on("ChatList", ({ success, type, chatList, archived }) => {
  // type echoes back "history"; chatList = history conversations
});
```

`type` values: `"personal"` (default), `"business"`, `"group"`, `"history"`.

### HTTP — `GET /chat/latest-chat` (only convos with unread)

```
GET /chat/latest-chat?type=history
Authorization: Bearer <token>
```

Same `type` values. `type=request` is rejected here (use `GET /chat/requests`).

### Payload shape

History items are identical in shape to Business items — the order/commerce
flags are preserved so the History tab can render and sub-bucket exactly like
the Business tab:

| Field | Meaning |
|---|---|
| `type` | `"history"` |
| `is_order` | true for order/commerce convos (preserved across the move) |
| `i_own_business` | `true` = someone ordered from MY business ("Me" section); `false` = I ordered |
| `is_friend` | other participant is in my contacts |
| `business_owner_user_id` | seller's user id (on socket update payloads) |
| `conversation_id`, `sender`, `last_message`, `unread_count`, `created_at`, … | as usual |

---

## Replying inside a History conversation

Opening a History conversation and sending a message works normally — pass the
existing `conversation_id` and the message lands in that History thread. It does
**not** bounce back to the Business tab, and it does **not** fork a new
conversation:

```
POST /chat/send-message
{ "conversation_id": "<history convo id>", "message": "…", "message_type": "text" }
```

Only the dedicated order/business **creation** flows (a new order, a Discover
send, etc.) create a fresh business conversation — they never resurface a
History one.

---

## Timing & configuration

- The sweep runs **every 10 minutes**, so a conversation lands in History within
  ~10 minutes of crossing the 12h mark (not instantly at 12h00m).
- On service boot the sweep runs **once immediately** to clear any backlog
  accumulated while the service was down.
- Threshold is configurable via env: `HISTORY_TAB_AGE_HOURS` (default `12`).

> **First-deploy behavior:** on the first run after this feature ships, **every
> existing business conversation older than 12h moves to History at once** (a
> single bulk update). After that, the Business tab shows only conversations
> created within the last 12h; everything older is in History. This is expected.

---

## FAQ / edge cases

- **Does the 12h reset if the convo gets a new message?** No — it is based on
  `created_at`, so the move happens 12h after creation regardless of activity.
- **What about the "BlueEra Orders" rider broadcast?** Excluded — it is a
  multi-party group flagged `orders_conversation: true` and stays put.
- **Will a History convo show up in the Business tab?** No — the `type` filter is
  exact, so `type:"business"` excludes History and vice-versa.
- **Do unread counts / archive still work?** Yes, unchanged — they key on
  `conversation_id`, not `type`.

---

## Backend internals (for maintainers)

| File | Change |
|---|---|
| `src/models/schema/conversation.schema.js` | Added `"history"` to the `type` enum + `{ type, created_at }` index |
| `src/utils/historyScheduler.js` | **New** — `sweepBusinessToHistory()` + `startHistoryScheduler()` (node-cron, every 10 min, runs once on boot) |
| `index.js` | Starts `startHistoryScheduler()` alongside the other schedulers |
| `src/utils/functions.js` | `deriveIsOrder()` now treats `history` like `business` |
| `src/controllers/message.controller.js` | `i_own_business` (chatList, latestChat, export) now treats `history` like `business` |
| `src/controllers/group.controller.js` | `findOneToOneConversation` default lookup excludes `history` (`$nin: ["group","history"]`) so archived convos aren't resurfaced |
| `src/swaggers/chat.swagger.js` | Documented `history` in the relevant `type` enums |

Sweep query (idempotent):
```js
Conversation.updateMany(
  { type: "business", orders_conversation: { $ne: true }, created_at: { $lte: now - 12h } },
  { $set: { type: "history" } },
  { timestamps: false }   // preserve updated_at ordering
)
```
