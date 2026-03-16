# Self-Conversation Support

This document describes how self-conversations (sending messages to yourself) work in the chat service.

## Overview

A self-conversation occurs when `sender_id == receiver_id` (i.e., `other_user_id` is the user's own ID). The system creates a one-to-one conversation with a single participant record and delivers messages back to the sender via socket in real-time.

## How It Works

### Conversation Creation & Lookup

When `other_user_id` matches the sender's own user ID:

1. **`createConversation`** deduplicates the `user_ids` array before calling `insertMany`, so only **one** `conversationsUser` record is created (not two duplicates).

2. **`findOneToOneConversation`** detects `uid1 === uid2` and switches the aggregation's second `$match` stage:
   - Normal: `{ count: 2, participants: { $all: [uid1, uid2], $size: 2 } }`
   - Self: `{ count: 1, participants: { $size: 1 } }`

   This ensures subsequent self-messages reuse the existing conversation instead of creating duplicates.

### Message Sending

In `sendMessage`, after fetching `conversationUsers` for the conversation:

```
receiverUserIds  = conversationUsers filtered to exclude senderId → [] (empty)
isSelfConversation = conversationUsers.length === 1 && only participant is sender
```

| Behavior | Self-Conversation | Normal 1-on-1 |
|----------|-------------------|---------------|
| **Socket targets** | `[senderId]` | `receiverUserIds` |
| **Message status** | `"read"` (hardcoded) | Result of `getRoomStatus()` |
| **`my_message` flag** | `true` | `false` |
| **Push notification** | Skipped | Sent if status != read |

**Why notifications are skipped:** `receiverUserIds` is empty (sender filtered out), so `regularReceiverIds.length > 0` is false and `sendNotification` is never called. No special-casing needed.

### Chat List

In `getChatList`, when resolving the "other user" for a 1-on-1 conversation, the standard lookup finds no participant whose `user_id !== current_user_id`. A self-conversation fallback runs:

```
if participants.length === 1 AND participants[0].user_id === current_user_id:
    use current user's own profile as the sender/display info
```

This ensures the self-conversation appears in the chat list with the user's own name and avatar.

## Data Model

No schema changes. A self-conversation in the database looks like:

```
conversations:
  { _id: "conv_abc", type: "single", last_message: "...", ... }

conversations_users:
  { user_id: "user_123", conversation_id: "conv_abc" }   ← single record
```

Compare with a normal 1-on-1 which has **two** `conversations_users` records.

## API Usage

Send a message to yourself using the standard `sendMessage` endpoint:

```json
POST /api/message/send
{
  "other_user_id": "<your_own_user_id>",
  "message": "Note to self",
  "message_type": "text"
}
```

Response is identical to a normal message, with `status: "read"` and `my_message: true`.

## Socket Events

The sender receives the message back on the same socket events as normal:

- **`newMessageReceived`** — for regular messages
- **`commentReceived`** — for replies to forwarded media

No changes to socket infrastructure were needed; `getReceiverSocketIds` works with any user ID including the sender's own.

## Verification Checklist

| # | Check | Expected |
|---|-------|----------|
| 1 | Send message with `other_user_id` = own ID | Conversation created with 1 `conversationsUser` record |
| 2 | Send second self-message | Reuses existing conversation (no duplicate) |
| 3 | Real-time delivery | `newMessageReceived` socket event fires on sender's client |
| 4 | Message fields | `status: "read"`, `my_message: true` |
| 5 | Chat list | Self-conversation visible with own name/avatar |
| 6 | Push notification | None triggered |
| 7 | Regression | Normal 1-on-1 conversations unaffected |

## Files Modified

| File | Changes |
|------|---------|
| `src/controllers/group.controller.js` | `findOneToOneConversation` conditional match + `createConversation` dedup |
| `src/controllers/sendMessage.controller.js` | Self-conversation flag, socket targets, status override, `my_message` flag |
| `src/controllers/message.controller.js` | Chat list self-conversation fallback |
