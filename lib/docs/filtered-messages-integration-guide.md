# Filtered Messages (Mentions / Assigned) — Frontend Integration Guide

> Status: shipped on `feature/filtered-messages-mentions-assigned` (backend). Frontends can start integrating immediately — old behaviour is fully preserved when the new flags are omitted.

## TL;DR

Two new optional filter flags — `mentioned` and `assigned` — narrow a conversation's message list down to only mention activity. Available on **both** transports the chat thread already uses:

| Transport | How to use | What changes |
|---|---|---|
| **Socket** `messageReceived` event | Add `mentioned: true` and/or `assigned: true` to the existing emit payload | Server emits back the same `messageReceived` shape, filtered |
| **REST** `GET /chat/conversation/:conversation_id/filtered-messages` | Pass `?mentioned=true&assigned=true` query params | Returns a JSON body with the same `messages` shape the socket emits |

Both transports work for every conversation type — **personal, group, business, order, request** — without special-casing. Group chat is the primary use case; the predicate is on `tagged_users` only and doesn't care about conversation type.

---

## Filter semantics — exactly what each flag returns

| `mentioned` | `assigned` | Returns |
|:-:|:-:|---|
| `false` (default) | `false` (default) | **No filter** — full message list (existing behaviour, byte-identical to before). |
| `true` | `false` | Only messages **I sent** that tagged at least one user (`senderId == me AND tagged_users.length > 0`). My **outgoing** mentions. |
| `false` | `true` | Only messages where **my user id is in `tagged_users`** (regardless of sender). My **incoming** mentions. |
| `true` | `true` | **Union (OR)** of the above two sets. Use this when you want "every message that's mention-related to me" in one panel. |

`mentioned` is from your point of view as a sender. `assigned` is from your point of view as a recipient. The two are orthogonal.

### Why these names?

- **`mentioned`** — "messages I have mentioned someone in." Mirrors how chat UIs surface a user's own mention activity.
- **`assigned`** — common product term for "messages where I've been tagged/assigned." Note: this is **not** a separate field on the schema — there is no task-assignment concept in the chat service. It's just a different read of the same `tagged_users` array.

---

## Transport 1 — Socket (`messageReceived` event)

The existing `messageReceived` event you already use to load a conversation's messages now accepts two extra optional flags. **Everything else about the event is unchanged** — same name, same response shape, same auto-mark-as-read side effect.

### Emit

```js
socket.emit("messageReceived", {
  conversation_id: "507f1f77bcf86cd799439011",  // required, unchanged
  page: 1,                                       // unchanged
  per_page_message: 50,                          // unchanged
  message_id: 0,                                 // unchanged (cursor)
  search: "",                                    // unchanged
  user_timezone: "Asia/Kolkata",                 // unchanged
  orders_conversation: false,                    // unchanged

  // ⭐ NEW — both optional, both default false
  mentioned: false,                              // outgoing mentions
  assigned:  true,                               // incoming mentions
});
```

### Response (`socket.on("messageReceived", ...)`)

Identical to the existing payload. Same `messages` array, same `totalPages`, same `currentPage`. Filtered down server-side per the flags.

```js
socket.on("messageReceived", ({ messages, totalPages, currentPage }) => {
  // messages: enriched per-message rows (sender, parentMessage, my_message, is_saved, is_liked, ...)
  // totalPages: pagination total (for the filtered set when flags are passed)
  // currentPage: 1-based page index
});
```

### React example (drop-in upgrade of an existing `useChatThread` hook)

```tsx
function useChatThread({ conversationId, mentioned, assigned, page }) {
  const [state, setState] = useState({ messages: [], totalPages: 0 });

  useEffect(() => {
    if (!conversationId) return;

    const handler = (payload) => setState(payload);
    socket.on("messageReceived", handler);

    socket.emit("messageReceived", {
      conversation_id: conversationId,
      page,
      per_page_message: 50,
      mentioned: !!mentioned,        // 👈 new
      assigned:  !!assigned,         // 👈 new
    });

    return () => socket.off("messageReceived", handler);
  }, [conversationId, mentioned, assigned, page]);

  return state;
}
```

```tsx
// "Show only @ mentions of me in this group" toggle
<MentionsPanel>
  {useChatThread({ conversationId, assigned: true }).messages.map(...)}
</MentionsPanel>
```

---

## Transport 2 — REST (`GET /chat/conversation/:conversation_id/filtered-messages`)

Use this when you don't want to keep a socket open (e.g., a side panel that's lazily opened, an admin dashboard, integration scripts).

### Request

```
GET /api/chat/conversation/:conversation_id/filtered-messages
    ?mentioned=true
    &assigned=true
    &page=1
    &per_page=50
    &search=<optional substring>
    &message_id=<optional cursor>
    &user_timezone=Asia/Kolkata
    &orders_conversation=false

Authorization: Bearer <jwt>
```

Path param `conversation_id` is required. All query params are optional. Booleans accept `"true"`/`"false"` (also `"1"` and `true`). `page` defaults to 1, `per_page` to 50.

### Response (200)

```jsonc
{
  "success": true,
  "messages": [
    {
      "_id": "60d...e1",
      "message": "Hey @alice can you look at this?",
      "senderId": "60d...u1",
      "conversation_id": "507f1f77bcf86cd799439011",
      "tagged_users": ["60d...u2"],
      "message_type": "text",
      "created_at": "2025-05-11T10:32:00.000Z",
      "updated_at": null,
      "sender": {
        "name": "Bob",
        "profile_image": "https://…/bob.jpg",
        // …other user fields populated via gRPC
      },
      "my_message": false,
      "is_saved": false,
      "is_liked": false,
      "parentMessage": null
      // …plus date-separator rows interleaved (`message_type: "date"`),
      //    same as the messageReceived socket payload
    }
  ],
  "totalPages": 3,
  "currentPage": 1,
  "filters": { "mentioned": false, "assigned": true }
}
```

The `filters` echo confirms which flags the server actually applied — useful for debugging boolean-coercion issues in the URL.

### Curl

```bash
# All mentions touching me (outgoing + incoming)
curl -H "Authorization: Bearer $TOKEN" \
  "https://chat.blueera.ai/api/chat/conversation/507f1f77bcf86cd799439011/filtered-messages?mentioned=true&assigned=true&page=1&per_page=50"

# Just "tagged me" in a group
curl -H "Authorization: Bearer $TOKEN" \
  "https://chat.blueera.ai/api/chat/conversation/507f1f77bcf86cd799439011/filtered-messages?assigned=true"
```

### TypeScript types (recommended)

```ts
export interface FilteredMessagesRequest {
  conversation_id: string;     // path param
  mentioned?: boolean;
  assigned?: boolean;
  page?: number;               // default 1
  per_page?: number;           // default 50
  message_id?: string;         // cursor
  search?: string;             // startsWith match
  user_timezone?: string;      // default "Asia/Kolkata"
  orders_conversation?: boolean;
}

export interface MessageRow {
  _id: string;
  message: string;
  senderId: string;
  conversation_id: string;
  tagged_users: string[];      // ObjectId strings
  message_type: string;        // "text" | "image" | … | "date" (separator)
  created_at: string;          // ISO 8601
  updated_at: string | null;
  sender: { name: string; profile_image: string; [k: string]: unknown };
  my_message: boolean;
  is_saved: boolean;
  is_liked: boolean;
  parentMessage: MessageRow | null;
  // …plus message-type-specific fields (url, latitude, metadata.symbol, etc.)
}

export interface FilteredMessagesResponse {
  success: true;
  messages: MessageRow[];
  totalPages: number;
  currentPage: number;
  filters: { mentioned: boolean; assigned: boolean };
}
```

---

## Group chat — first-class citizen

This was specifically designed for group chat workflows but it's not a group-only feature. Things to know:

1. **Conversation type doesn't matter.** Pass any `conversation_id` — personal, business, group, order, request. The predicate is on `tagged_users` only.
2. **A single message can tag multiple users.** The `assigned=true` filter still matches whether the array has 1 or 20 entries — Mongo's array element match handles cardinality.
3. **`@everyone` / `@here` is not implemented today.** Mentions are always an explicit list of user ObjectIds populated at send-time on `POST /chat/send-message` (field `tagged_users` accepts a comma-separated string or array). If your group UX adds `@everyone`, decide at send-time whether to expand it into all member IDs (in which case this filter keeps working untouched) or to store a sentinel — coordinate with backend.
4. **`mentioned=true` in a busy group surfaces your outgoing pings only.** Useful for "review what I've assigned" workflows.

---

## Important behaviours

### Auto-mark-as-read

Calling either the socket event or the REST endpoint marks the conversation's remaining unread messages as `read` and (on socket) emits `unreadCountCleared` — exactly like opening the conversation does today. This is intentional: a filter view is still a "view." If your UX needs a non-destructive "preview mentions" mode, surface a separate UI affordance for it and don't fire either call.

### Both flags simultaneously = OR (union)

When you pass `mentioned=true&assigned=true`, you get a **union** of both sets — every message that's mention-related to you in any direction. AND-intersection (`I tagged myself`) would be essentially empty in practice and was explicitly rejected as a design.

### Backward compatibility

Both flags default to `false`. Any existing client that doesn't pass them gets **byte-identical** responses to the prior implementation. This is true for both transports.

### Pagination

`totalPages` reflects the **filtered** count when flags are passed, not the conversation-wide count. Don't reuse a totalPages cached from an unfiltered request after toggling a filter — refetch.

### Search + filter compose

`search=<text>` is ANDed with the mention filter, not OR. So `assigned=true&search=urgent` returns "messages where I'm tagged AND text starts with 'urgent'." Use this for things like "unresolved tagged tasks."

---

## Performance note (backend)

A compound MongoDB index `{ conversation_id: 1, tagged_users: 1 }` was added to the `messages` collection as part of this work. It speeds up both the new filter and the existing `chatList` tagged-count aggregation.

If you observe slow responses on large conversations (>100k messages), confirm the index is present:

```js
db.messages.getIndexes()
// expect to see: { conversation_id: 1, tagged_users: 1 }
```

On a fresh deployment Mongoose autoIndex will create it on app start. On long-running clusters it builds in the background (non-blocking on MongoDB 4.2+).

---

## Edge cases & gotchas

| Situation | Behaviour |
|---|---|
| Conversation with zero mentions | Returns `{ messages: [date-separators only or nothing], totalPages: 0, currentPage: 1 }`. Render an empty state. |
| User passes `mentioned=true` but their messages have empty `tagged_users` arrays | Returns empty set. Not a bug — they haven't tagged anyone. |
| Cleared chat (`clearAllChat`) | Existing cleared-chat truncation rules apply *before* the mention filter. You'll never see messages older than the clear marker. |
| Deleted-for-me messages | Honored. Filtered out by `processMessageContent` after the mention predicate matches, same as the socket flow. |
| Request-type conversations (`type: "request"`) before consent | Same access rules as the existing `messageReceived` event — if you can read messages, you can filter them. |
| Self-tagging (`I'm in tagged_users on my own message`) | Matched by `assigned=true` (because you ARE in `tagged_users`). Rare in practice; if your UX wants to hide self-tags, filter client-side. |

---

## Migration checklist for a frontend rollout

- [ ] Add a "mentions" panel/tab in your group chat view that emits `messageReceived` with `assigned: true` (or hits the REST endpoint).
- [ ] Add a "my outgoing mentions" view if your product surfaces it — same event, `mentioned: true`.
- [ ] Wire the `filters` echo from the REST response into your devtools/logging so boolean-coercion bugs are obvious.
- [ ] If you cache `totalPages`, invalidate the cache when filter flags change.
- [ ] Document the auto-mark-as-read behaviour in product copy if a user might be confused by the badge clearing when they open the panel.

---

## Reference — what changed on the backend

For backend engineers reviewing the integration:

| File | Change |
|---|---|
| `src/models/schema/message.schema.js` | Added compound index `{ conversation_id: 1, tagged_users: 1 }` |
| `src/controllers/message.controller.js` — `getMessages()` | New 8th arg `filters = { mentioned, assigned }`; applies `$or` predicate on `tagged_users` when either flag is truthy |
| `src/controllers/message.controller.js` — `receiveMessage()` | Destructures the two flags from socket data and forwards to `getMessages` |
| `src/controllers/message.controller.js` — `filteredMessages()` | New REST controller mirroring the socket pipeline |
| `src/routes/chat.route.js` | Registered `GET /conversation/:conversation_id/filtered-messages` |
| `src/swaggers/chat.swagger.js` | Swagger docs for the new endpoint |
| `src/config/asyncapi.js` | Documented `mentioned` and `assigned` on `messageReceivedRequest` |
| `api_and_socket_context.md` | Updated socket events table and added REST endpoint section |

No breaking changes. No new dependencies.

---

## Questions / follow-ups

- Need a "read-only preview" variant that doesn't mark messages as read? File an issue — the design preserves that as an explicit future option.
- Need a global "mentions inbox" across all conversations? That's a different feature (would need a new event/endpoint that joins across conversations); not in this scope.
- Need `@everyone` / `@here`? Backend decision needed — see the group chat section above.
