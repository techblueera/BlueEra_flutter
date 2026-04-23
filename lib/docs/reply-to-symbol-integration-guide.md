# `reply_to_symbol` — Frontend Integration Guide

## TL;DR

A new chat `message_type: "reply_to_symbol"` lets a user send a text reply that
references a **symbol** (from `be_symbols_service`) as its quoted context. The
reply lands in the 1:1 conversation between the replier and the symbol's author
— creating the conversation if it doesn't exist — and carries a full snapshot
of the symbol inside the message, so the frontend can render the quoted-reply
UX without a separate API call.

- **Endpoint:** `POST /chat/send-message` (same as every other message)
- **New message type:** `"reply_to_symbol"`
- **New required fields on the request body:** `symbol_id`, `symbol_snapshot`
- **On the wire (sockets and REST):** the stored symbol snapshot is available
  at `message.metadata.symbol` (plus `message.metadata.symbol_id`).
- **In the `ChatList` socket event:** when a conversation's last message is a
  symbol reply, the chat-list item exposes the snapshot at the top level as
  `replied_symbol` + `replied_symbol_id` so the preview can render without a
  history round-trip.

---

## Request payload

Send a symbol reply exactly like any other message — just flip the type and
include the two new fields. Either `conversation_id` or `other_user_id` is
accepted; if neither exists the chat service creates a 1:1 conversation with
the symbol author.

```jsonc
// POST /chat/send-message
{
  "message_type": "reply_to_symbol",
  "message": "Loved this 🔥",
  "other_user_id": "<symbol author user_id>",   // or conversation_id
  "symbol_id": "<symbol ObjectId as string>",
  "symbol_snapshot": {
    "_id": "<same as symbol_id>",
    "user_id": "<symbol author user_id>",
    "type": "photo",                            // photo | video | text | embeddedUrl
    "content": "https://…/photo.jpg",           // URL for media, raw text for text
    "caption": "Sunset from the balcony",
    "backgroundColor": null,                    // for text symbols only
    "fontFamily": null,
    "fontSize": null,
    "fontWeight": null,
    "visibility": "public",
    "expires_at": "2026-05-01T00:00:00.000Z",
    "created_at": "2026-04-23T10:00:00.000Z"
  }
}
```

### Validation rules

| Field                         | Rule                                                                                           |
|-------------------------------|------------------------------------------------------------------------------------------------|
| `message_type`                | Must be `"reply_to_symbol"` to trigger the new flow.                                           |
| `symbol_id`                   | Required, non-empty string. Returns `HTTP 400` if missing.                                     |
| `symbol_snapshot`             | Required object, must contain at least `_id`. Returns `HTTP 400` if missing/invalid.           |
| `reply_id` / `forward_id`     | Ignored — symbol replies are not message-to-message replies. Server forces both to `null`.     |
| `message`                     | The reply text. Can be empty, but you almost always want to send something.                    |

### Why `symbol_snapshot` is client-provided

The client is **already** displaying the symbol when the user taps "reply", so
it has the canonical snapshot in hand. Sending it along avoids a server-side
gRPC round-trip and lets the chat bubble render correctly even after the symbol
has expired and been purged from `be_symbols_service`. If you only have a
subset of fields, send what you have — the server stores whatever object you
pass, keyed under `metadata.symbol`.

---

## Where you'll see it

### 1. `newMessageReceived` socket event (sent in real-time)

Emitted to all receivers (and the sender, via chat-list refresh) the moment the
message is created. Identical flow to every other `newMessageReceived` payload,
with the snapshot embedded at `metadata.symbol`:

```jsonc
// socket: "newMessageReceived"
{
  "message": {
    "_id": "66f1a2…",
    "senderId": "<replier user_id>",
    "conversation_id": "66ef…",
    "message_type": "reply_to_symbol",
    "message": "Loved this 🔥",
    "sub_type": "message",
    "status": "sent",
    "metadata": {
      "symbol_id": "<symbol ObjectId as string>",
      "symbol": {
        "_id": "…", "user_id": "…", "type": "photo",
        "content": "https://…/photo.jpg",
        "caption": "Sunset from the balcony",
        "visibility": "public",
        "expires_at": "2026-05-01T00:00:00.000Z",
        "created_at": "2026-04-23T10:00:00.000Z"
      }
    },
    "sender": { "id": "…", "name": "…", "profile_image": "…" },
    "conversation": { /* full conversation doc */ },
    "my_message": false,
    "is_star_message": false,
    "parentMessage": null,
    "created_at": "2026-04-23T10:02:31.000Z"
  }
}
```

### 2. Chat history — `messageReceived` socket event / `getMessages` REST

Nothing new on your side: `reply_to_symbol` messages come back through the
existing chat history pipeline with `metadata.symbol` populated exactly the
same way as in the socket event above. No extra filter flag needed —
`sub_type: "message"` keeps them in the normal history list.

### 3. `ChatList` socket event

When a conversation's **last message** is a `reply_to_symbol`, the chat-list
item gets two extra top-level fields so the preview row can render without
reloading the message:

```jsonc
// socket: "ChatList"
{
  "success": true,
  "type": "personal",
  "chatList": [
    {
      "conversation_id": "66ef…",
      "type": "personal",
      "last_message": "Loved this 🔥",
      "last_message_type": "reply_to_symbol",
      "replied_symbol": {
        "_id": "…", "user_id": "…", "type": "photo",
        "content": "https://…/photo.jpg",
        "caption": "Sunset from the balcony",
        "visibility": "public",
        "expires_at": "2026-05-01T00:00:00.000Z",
        "created_at": "2026-04-23T10:00:00.000Z"
      },
      "replied_symbol_id": "<symbol ObjectId as string>",
      "unread_count": 1,
      "sender": { /* … */ },
      "symbolData": [ /* … */ ]
    },
    {
      "conversation_id": "66ee…",
      "last_message_type": "text"
      // no `replied_symbol` / `replied_symbol_id` keys here — not a symbol reply
    }
  ],
  "archived": [ /* same shape */ ]
}
```

The `replied_symbol` / `replied_symbol_id` fields are **only** present when
`last_message_type === "reply_to_symbol"` — they're omitted entirely for every
other conversation, so they don't bloat payloads.

The same two fields also appear on items returned by the `latestChat` endpoint
(used for partial chat-list refreshes after message/delete events), so cached
chat-list rows stay consistent.

---

## Frontend usage

### Rendering a reply-to-symbol bubble

```ts
if (message.message_type === "reply_to_symbol") {
  const sym = message.metadata?.symbol ?? null;
  if (!sym) {
    // Defensive fallback: old/partial payload — render as plain text
    return <Text>{message.message}</Text>;
  }
  return (
    <QuotedSymbolBubble
      creatorName={sym.user?.name ?? "Symbol author"}
      symbolType={sym.type}                   // photo | video | text | embeddedUrl
      content={sym.content}
      caption={sym.caption}
      backgroundColor={sym.backgroundColor}
      replyText={message.message}
    />
  );
}
```

### Rendering the chat list preview

```ts
if (chat.last_message_type === "reply_to_symbol") {
  const thumb = chat.replied_symbol?.type === "photo" || chat.replied_symbol?.type === "video"
    ? chat.replied_symbol.content
    : null;
  // Preview row: tiny thumb + "Symbol reply: <last_message text>"
  return <ChatListRow thumbnail={thumb} label={`Symbol reply: ${chat.last_message}`} />;
}
```

### Graceful degradation

- **Client-side:** a client that doesn't know `reply_to_symbol` will fall
  through the `buildBubbleContent` default branch and show the raw text in an
  `[reply_to_symbol] <message>` bubble. Still readable, just unstyled.
- **Server-side:** if `metadata.symbol` is somehow missing (e.g. a client
  posted without a snapshot and got past validation via `sendMessageLargeFile`
  / `syncOfflineMessages` edge cases), the bubble renderer should treat the
  message like plain text.

---

## Field reference

| Field                                       | Type      | Where                                | Meaning                                                         |
|---------------------------------------------|-----------|--------------------------------------|-----------------------------------------------------------------|
| `message_type`                              | string    | request body + message object        | `"reply_to_symbol"`                                             |
| `message`                                   | string    | request body + message object        | The user's reply text.                                          |
| `symbol_id` (request) / `metadata.symbol_id`| string    | request body / stored message        | The ObjectId of the referenced symbol (string form).            |
| `symbol_snapshot` (request) / `metadata.symbol` | object | request body / stored message        | Full symbol snapshot (author, type, content, visibility, etc.). |
| `replied_symbol`                            | object    | chat-list item                       | Mirror of `metadata.symbol` for the chat's last message.        |
| `replied_symbol_id`                         | string    | chat-list item                       | Mirror of `metadata.symbol_id` for the chat's last message.     |
| `last_message_type`                         | string    | chat-list item                       | `"reply_to_symbol"` when the last message is a symbol reply.    |

---

## Backwards compatibility

- The `message_type` enum was extended with one new value — no migration, no
  breaking change to existing records.
- Two new keys were added inside `metadata` (`symbol_id`, `symbol`). They're
  `null`/absent on every pre-existing message.
- `replied_symbol` / `replied_symbol_id` are only attached to chat-list items
  whose last message is a `reply_to_symbol`. Every other chat-list shape is
  unchanged.
- Clients that ignore the new fields will keep working — they just won't be
  able to render the quoted-symbol UX or the chat-list preview thumbnail.

---

## Quick test checklist

- [ ] Send a `reply_to_symbol` via `POST /chat/send-message` with valid
      `symbol_id` + `symbol_snapshot`. Confirm HTTP 200 and the response
      `data.metadata.symbol` matches what you sent.
- [ ] Confirm the recipient receives `newMessageReceived` with the full
      `metadata.symbol` payload.
- [ ] Refetch chat history. Confirm the message re-hydrates with
      `metadata.symbol` intact.
- [ ] Trigger a `ChatList` refresh. Confirm the sender's and recipient's
      conversation item has `last_message_type: "reply_to_symbol"`,
      `replied_symbol` (matching the snapshot), and `replied_symbol_id`.
- [ ] Send a plain `text` message in the same conversation. Refetch the chat
      list. Confirm `replied_symbol` / `replied_symbol_id` are **absent** on
      that conversation item.
- [ ] Send a request missing `symbol_id` → expect HTTP 400 with
      `"symbol_id is required for reply_to_symbol messages"`.
- [ ] Send a request with `symbol_snapshot` missing `_id` → expect HTTP 400
      with `"symbol_snapshot with at least { _id, type, user_id } is required"`.
- [ ] (Regression) Send a `live_location` in a separate chat and confirm
      `isEnded` is still computed correctly on the chat-list item.
