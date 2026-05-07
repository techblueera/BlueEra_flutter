# Symbol-Reply Requests — Frontend Integration Guide

> **Audience:** Web/Flutter/iOS/Android engineers integrating the new
> consent-gated `request` conversation type for symbol-reply messages.
>
> **Service:** `be_chat_service`
> **Status:** v1.1
> **Last reviewed:** 2026-05-07
>
> **v1.1 changes (2026-05-07):**
> - `GET /chat/requests` now supports `?role=sent` so the initiator can
>   list their own pending outgoing requests (the symmetric inbox).
> - `GET /chat/requests/:id` is now readable by either party
>   (initiator OR recipient) and returns both `initiator`, `recipient`,
>   and a `viewer_role` field.

---

## 1. Overview

When user **A** sends a `reply_to_symbol` message to user **B** for the first
time, the chat service now asks: *does A have a relationship with B?* The
answer drives one of three conversation types:

| Sender state vs. recipient | Existing 1:1 conversation? | Resulting type |
|---|---|---|
| Sender has saved recipient as a contact | — | `personal` (existing behaviour) |
| Sender has NOT saved recipient as a contact | Yes (any type) | reuses existing conversation (existing behaviour) |
| Sender has NOT saved recipient as a contact | No | **`request` (new)** — gated on recipient consent |

A `request` conversation behaves like a normal conversation in almost every
respect — messages are persisted, sockets fire, push notifications go out —
but it lives in a separate "Requests" inbox until the recipient explicitly
**accepts** (in-place promotion to `personal`) or **declines** (full deletion).

```
A  ─────reply_to_symbol─────►  B
                  │
                  └─ first message? ──► creates conv (type=request)
                                          │
                            ┌─────────────┴─────────────┐
                            │                           │
                  B taps Accept              B taps Decline
                  → type flips to            → conversation
                    "personal"                  + messages deleted
                  → both users see           → A is notified
                    requestAccepted          → optional block
```

### What does NOT change

- All other `message_type` values (text, image, video, …) continue to
  behave exactly as before. Only `reply_to_symbol` from a stranger is gated.
- If A and B already share a 1:1 conversation of any type, symbol-replies
  land in that existing conversation (no `request` flow).
- Group conversations are untouched. `request` is exclusively 1:1.

---

## 2. API contract

All endpoints require `Authorization: Bearer <token>`. Base URL is the same
as the rest of `be_chat_service` (e.g. `https://chat.<env>.example.com`).

### 2.1 `POST /chat/send-message` (existing — extended)

The existing send-message contract is unchanged for clients that ignore the
new fields. New behaviour:

#### Request additions

```jsonc
{
  "message_type": "reply_to_symbol",
  "message": "Loved this 🔥",
  "symbol_id": "67f9aa0bc2d4e5f6a7b8c9d0",
  "symbol_snapshot": {
    "_id": "67f9aa0bc2d4e5f6a7b8c9d0",
    "user_id": "<symbol owner>",
    "type": "photo",
    "content": "https://cdn.example.com/symbols/abc.jpg",
    "caption": "Sunset run",
    "expires_at": "2026-05-04T12:00:00Z"
  },
  "other_user_id": "<symbol_owner_user_id>",
  "conversation_type": "personal"   // hint only — server overrides for stranger symbol-replies
}
```

#### Response additions

When the message lands in a `request`-type conversation that is still
pending, the response gains a `request` block:

```jsonc
{
  "status": true,
  "message": "Message created successfully",
  "data": {
    "_id": "...",
    "conversation_id": "...",
    "message": "Loved this 🔥",
    "message_type": "reply_to_symbol",
    "my_message": true,
    "request": {
      "is_request_conversation": true,
      "status": "pending",
      "initiator_user_id": "<A>",
      "recipient_user_id": "<B>",
      "origin_symbol_id": "67f9aa0bc2d4e5f6a7b8c9d0",
      "requested_at": "2026-04-29T10:23:00.000Z"
    }
  }
}
```

When the conversation is `personal` / `business` / a previously promoted
request, the `request` block is omitted (treat its absence as "regular
conversation").

#### New 409 response

While a request is still pending, the **initiator** can only send additional
`reply_to_symbol` messages into it. Any other `message_type` returns:

```jsonc
HTTP/1.1 409 Conflict
{
  "status": false,
  "code": "REQUEST_PENDING",
  "message": "Request is pending — only reply_to_symbol messages are allowed until the recipient accepts",
  "conversation_id": "..."
}
```

### 2.2 `GET /chat/requests`

Lists the authenticated user's pending requests, newest first.

By default returns **incoming** requests (where the caller is the recipient).
Pass `role=sent` to instead return **outgoing** requests the caller raised
that are still waiting on the recipient — the symmetric inbox the initiator
needs to surface a "Sent Requests" view.

**Query parameters**

| Param | Type | Default | Description |
|---|---|---|---|
| `role` | `"incoming"` \| `"sent"` | `"incoming"` | `incoming` = caller is recipient; `sent` = caller is initiator. |
| `limit` | int | `20` | Max items (1–100). |
| `before` | ISO timestamp | — | Cursor: returns items with `requested_at < before`. |

**curl — incoming (default, back-compat)**

```sh
curl -H "Authorization: Bearer $TOKEN" \
     "$BASE/chat/requests?limit=20"
```

**curl — outgoing (initiator's view)**

```sh
curl -H "Authorization: Bearer $TOKEN" \
     "$BASE/chat/requests?role=sent&limit=20"
```

**Response 200 — `role=incoming`**

```jsonc
{
  "success": true,
  "message": "Requests fetched successfully",
  "data": [
    {
      "conversation_id": "67f9...",
      "status": "pending",
      "origin_symbol_id": "67f9aa0bc2d4e5f6a7b8c9d0",
      "requested_at": "2026-04-29T10:23:00.000Z",
      "last_message": "Loved this 🔥",
      "last_message_type": "reply_to_symbol",
      "last_message_id": { "_id": "…", "metadata": { "symbol": { ... } } },
      "initiator": {
        "id": "...",
        "name": "Alex Carter",
        "contact": "919...",
        "profile_image": "https://..."
      }
    }
  ],
  "pagination": { "limit": 20, "next_cursor": "2026-04-29T10:00:00.000Z", "has_more": false, "role": "incoming" }
}
```

**Response 200 — `role=sent`**

Same shape, except each card carries `recipient` (the user the initiator
is waiting on) instead of `initiator`. `pagination.role` is `"sent"`.

```jsonc
{
  "success": true,
  "message": "Requests fetched successfully",
  "data": [
    {
      "conversation_id": "67f9...",
      "status": "pending",
      "origin_symbol_id": "67f9aa0bc2d4e5f6a7b8c9d0",
      "requested_at": "2026-04-29T10:23:00.000Z",
      "last_message": "Loved this 🔥",
      "last_message_type": "reply_to_symbol",
      "last_message_id": { "_id": "…", "metadata": { "symbol": { ... } } },
      "recipient": {
        "id": "...",
        "name": "Sam Patel",
        "contact": "919...",
        "profile_image": "https://..."
      }
    }
  ],
  "pagination": { "limit": 20, "next_cursor": null, "has_more": false, "role": "sent" }
}
```

> **Why the role split is needed.** Request conversations are deliberately
> filtered out of `GET /chat/latest-chat` (the chat-list endpoint) to keep
> the consent gate effective. Without `role=sent` the initiator has no
> server-backed way to retrieve their own pending requests after a page
> reload or device switch — only the recipient does. Use this view to
> render a "Sent" tab (or a sub-toggle inside the Requests tab) so the
> initiator can see what they're still waiting on and cancel if they want.

### 2.3 `GET /chat/requests/{conversation_id}`

Fetches a single request including its message history. Either party of
the request — initiator OR recipient — can read it while the request is
still pending.

The response carries a `viewer_role` field (`"initiator"` | `"recipient"`)
so clients can branch UI affordances (Cancel for the initiator,
Accept/Decline for the recipient) without comparing user IDs themselves,
and resolves **both** `initiator` and `recipient` so each side has the
counterparty's profile.

| Status | Meaning |
|---|---|
| `200` | Returns `{ data: { conversation_id, status, origin_symbol_id, requested_at, viewer_role, initiator, recipient, messages[] } }` |
| `400` | Invalid `conversation_id` |
| `403` | Authenticated user is not a participant (neither initiator nor recipient) |
| `404` | Request not found |
| `410` | Already accepted or declined |

### 2.4 `POST /chat/requests/respond`

Recipient-only. **Accept** or **decline** a pending request.

```sh
curl -X POST -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"conversation_id":"67f9...","action":"accept"}' \
     "$BASE/chat/requests/respond"
```

**Body**

| Field | Type | Required | Description |
|---|---|---|---|
| `conversation_id` | string | yes | Request conversation id. |
| `action` | `"accept"` \| `"decline"` | yes | What to do. |
| `block_initiator` | bool | no | When `action="decline"`, also adds a user-scoped block (silently drops future requests from the same sender). |

**Status codes**

| Status | Meaning |
|---|---|
| `200` | Resolved. On accept, conversation type flips to `personal` and history is preserved. On decline, conversation + messages are deleted. |
| `400` | Missing or invalid params. |
| `403` | Not the recipient. |
| `404` | Conversation not found. |
| `409` | Not a `request` conversation, or already accepted/declined. |
| `500` | `request_meta` missing (data corruption — escalate). |

### 2.5 `POST /chat/requests/cancel`

Initiator-only. Withdraw a still-pending request before the recipient acts.

```sh
curl -X POST -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"conversation_id":"67f9..."}' \
     "$BASE/chat/requests/cancel"
```

Same status codes as `respond`; on success deletes the conversation and emits
`requestDeclined` to the recipient with `reason: "cancelled_by_initiator"`.

---

## 3. Detecting a request from `send-message`

After every `POST /chat/send-message` with `message_type: "reply_to_symbol"`,
inspect `data.request`:

```ts
type SendMessageResponse = {
  status: boolean;
  message: string;
  data: {
    _id: string;
    conversation_id: string;
    message_type: string;
    request?: {
      is_request_conversation: true;
      status: "pending";
      initiator_user_id: string;
      recipient_user_id: string;
      origin_symbol_id: string;
      requested_at: string;
    };
  };
};

const res = await api.post<SendMessageResponse>("/chat/send-message", payload);
if (res.data.data.request?.is_request_conversation) {
  // Show "Request sent — waiting for {recipient} to accept" banner.
  // Disable any non-symbol-reply send affordances for this conversation.
  setRequestPending(res.data.data.conversation_id, res.data.data.request);
}
```

`request` is **absent** when the conversation is already `personal` /
`business` / a previously promoted request. In that case treat it as a
regular conversation.

---

## 4. Socket events

Three new events flow over the existing chat socket connection
(`/socket`, auth handshake unchanged). Subscribe immediately after `connect`:

### `requestReceived` — recipient only, on first symbol-reply

```jsonc
{
  "conversation_id": "67f9...",
  "status": "pending",
  "origin_symbol_id": "67f9aa0bc2d4e5f6a7b8c9d0",
  "requested_at": "2026-04-29T10:23:00.000Z",
  "last_message": "Loved this 🔥",
  "last_message_type": "reply_to_symbol",
  "last_message_id": "...",
  "initiator": { "id": "...", "name": "Alex Carter", "contact": "...", "profile_image": "..." }
}
```

Recommended UX: prepend to the Requests inbox + bump the badge counter.
Also fires a regular `newMessageReceived` for the same message — clients
watching the Requests tab don't need to render the message body in the main
chat list (filter conversations by `type !== "request"`).

### `requestAccepted` — both users (initiator + recipient)

```jsonc
{
  "conversation_id": "67f9...",
  "accepted_by": "<userId>",
  "accepted_at": "2026-04-29T10:25:00.000Z",
  "reason": "explicit_accept" | "implicit_accept",
  "initiator_user_id": "<A>",
  "recipient_user_id": "<B>"
}
```

Recommended UX:
- Recipient: drop card from Requests inbox, decrement badge, refetch chat list.
- Initiator: clear "request pending" banner, surface a success toast, re-enable text input.
- Both: the conversation now shows up in `latestChat` with `type: "personal"`.

### `requestDeclined` — initiator only

```jsonc
{
  "conversation_id": "67f9...",
  "reason": "declined" | "cancelled_by_initiator",
  "blocked": false   // true only when recipient chose "Decline + Block"
}
```

Recommended UX: hide the request card from the initiator's UI, clear
banner. **Do not surface "you were blocked"** to the initiator — the
`blocked` field is for telemetry only. The push notification is suppressed
when `blocked === true` to avoid leaking the block.

### Reconnection

The socket-bridge does not replay missed events. After a reconnect, call
`GET /chat/requests` (and, for the initiator's view, `GET /chat/requests?role=sent`)
to resync the inbox. The badge counter should be recomputed from these
fetches.

---

## 5. Recommended Inbox UI

```
┌─ Personal ─┬─ Business ─┬─ Order ─┬─ Group ─┬─ Requests (3) ─┐
│                                                                │
│  Tabs scroll horizontally on narrow screens.                   │
│  The "Requests" tab shows a count badge sourced from           │
│  `requestsCache.size`. Badge updates from socket events.       │
└────────────────────────────────────────────────────────────────┘

Inside the Requests tab, expose a sub-toggle so the initiator can see
their own outgoing requests (which are deliberately hidden from the
regular chat list):

  ┌───────────┬──────────┐
  │ Incoming  │   Sent   │
  └───────────┴──────────┘
  Incoming → GET /chat/requests           (role defaults to "incoming")
  Sent     → GET /chat/requests?role=sent

When "Incoming" is active (recipient's view):
- Render each request as a card with:
  • Initiator avatar + name (or contact_no fallback if name absent)
  • The originating symbol thumbnail (from `metadata.symbol`)
  • last_message preview (typically the symbol-reply text)
  • Timestamp (`requested_at`)
  • Three primary buttons: Accept · Decline · Decline + Block
  • Optional secondary: "View thread" (calls GET /chat/requests/:id)

Tapping Accept/Decline:
  • POST /chat/requests/respond
  • Optimistically remove the card from the UI on 2xx
  • Re-render badge; if the badge hits 0, navigate back to Personal

When "Sent" is active (initiator's view):
- Each card uses `recipient` instead of `initiator` for the avatar/name.
- Replace Accept/Decline/Block with a single primary button: **Cancel**
  (calls POST /chat/requests/cancel — initiator-only, deletes the request).
- Optional secondary: "View thread" (GET /chat/requests/:id — initiator
  is now permitted to read their own pending request).
- Sent cards SHOULD NOT count toward the inbox badge — the badge is for
  inbound requests awaiting your action.
```

A reference implementation is in `public/index.html` (search for
`fetchAndRenderRequests`, `renderRequests`, `respondToRequest`,
`cancelOutgoingRequest`).

---

## 6. Implicit accept

When the recipient sends ANY message into the request conversation through
`POST /chat/send-message`, the server auto-promotes the conversation to
`personal` before persisting the message and emits `requestAccepted` with
`reason: "implicit_accept"`. **Clients should NOT pre-emptively call
`respond {accept}`** before sending a reply — let the server handle it.

If the client is unsure of the conversation type, always send normally and
react to the `requestAccepted` event when it arrives.

---

## 7. Block + decline UX

The `block_initiator` flag inserts a Block row scoped to the user (no
conversation_id), so any future direct message from the initiator to the
responder is silent-dropped (sender sees a fake-success). Existing
conversation-scoped Blocks (the `/block` endpoint) remain unchanged.

Recommended copy:

| Action | Suggested label | Confirm dialog |
|---|---|---|
| Decline | `Decline` | None |
| Decline + Block | `Decline & block sender` | "This will permanently silence future requests from this user. Continue?" |

The push notification for "request_declined" is suppressed when
`block_initiator === true` so the sender isn't told about the block.

---

## 8. Edge cases the FE must handle

| Case | What to expect | What to do |
|---|---|---|
| Initiator deleted account between request and accept | `initiator: null` in `GET /chat/requests` (incoming) response | Render "Unknown user" + still allow Decline (clean up) |
| Recipient deleted account before accepting | `recipient: null` in `GET /chat/requests?role=sent` response | Render "Unknown user" + allow Cancel (clean up) |
| Symbol expired between send and accept | Snapshot in `metadata.symbol` survives | Render the symbol from snapshot — do NOT re-fetch from `be_symbols_service` |
| Concurrent: initiator sends 2nd reply while recipient accepts | Final state: 1 conversation, `personal`, 2 messages | Just render normally — server dedupes |
| Two clients of the same user (e.g. mobile + web) | Both receive `requestAccepted` | Idempotent UI updates; safe to call again |
| Initiator's other device doesn't know about a just-sent request | No `requestSent` socket event is emitted | On reconnect/cold-load, refetch `GET /chat/requests?role=sent` to populate the Sent view |
| Forwarding a message FROM a pending request | `409 REQUEST_PENDING` from `POST /chat/forward-messages` | Surface "Cannot forward from a pending request" toast |
| Pinning / starring inside a pending request | `409 REQUEST_PENDING` | Disable pin/star UI when current conversation type is `request` |
| Old client opens chat list with `type=request` | Returns empty array (request type is filtered from `latestChat`) | None — ignore |
| Old client calls `GET /chat/requests` without `role` | Returns incoming requests (default), same shape as before | None — back-compat preserved |

---

## 9. Error code reference

| Status | Code | Surface to user as |
|---|---|---|
| `400` | (no code) | "Invalid input — please try again" |
| `401` | (auth) | Re-authenticate flow |
| `403` | (no code) | "You don't have permission to do that" |
| `404` | (no code) | "Request no longer exists" |
| `409` | `REQUEST_PENDING` | "Request is pending — only symbol replies allowed until accepted" |
| `409` | (no code) | "Already accepted or declined" |
| `410` | (no code) | "This request has already been handled" |
| `500` | (no code) | "Something went wrong — please retry" |

---

## 10. Backwards compatibility

Old clients that don't know about `request` conversations:
- They will NOT see request conversations in `GET /latest-chat` /
  `socket('ChatList')` — those endpoints filter `type !== "request"`.
- They will receive `requestReceived` socket events and ignore them
  (unknown event handlers are silently dropped by socket.io clients).
- A symbol-reply they send to a non-contact stranger will succeed with a
  200 response. They simply won't render the new `data.request` block, so
  the user won't see a "pending" banner — no functional regression.
- If the user receives a request-conversation-bound `newMessageReceived`
  for a conversation they can't see in their chat list, the message will
  appear "orphaned" until they update the client. Mitigation: the
  `newMessageReceived` payload still includes `conversation.type`, so old
  clients can defensively filter.

Clients that know about `role=incoming` only (i.e. predate the `role=sent`
addition):
- `GET /chat/requests` without `role` continues to return incoming
  requests with the original shape (`initiator` field, no `pagination.role`
  meaningful difference). No regression.
- `GET /chat/requests/:id` is now readable by the initiator as well.
  Old recipient-only clients will simply never call it as the initiator,
  so this is purely additive.
- Initiators on old clients still rely on the in-memory `data.request`
  block from `send-message` (lost on reload). They should adopt
  `role=sent` to surface the durable Sent view.

When all clients are upgraded, the chat list filter remains intact —
request conversations are *intentionally* invisible to the regular list to
keep the consent gate effective. The Sent view is the only durable
server-backed surface for the initiator's pending requests.

---

## 11. Trust note on `symbol_snapshot`

The chat service does **not** validate `symbol_snapshot` against
`be_symbols_service` on send. The snapshot is stored verbatim under
`metadata.symbol` and rendered as-is. Implications:

- Resilient to symbol expiry / deletion (snapshot survives).
- Trusts the client to send accurate snapshots. Mobile / web clients should
  always use the snapshot returned by `be_symbols_service` directly — never
  let users hand-edit it.
- If you observe spoofed symbol metadata in the field, raise it as a
  product / security concern; the fix is a server-side `GetSymbolById` gRPC
  validation that we have left out of v1 to keep the path fast.
