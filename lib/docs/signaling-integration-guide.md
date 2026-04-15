# Signaling Integration Guide

Complete frontend integration guide for real-time signaling: **message status ticks**, **online/offline presence**, **typing indicators**, and **unread badges**.

> **Architecture**: Frontend connects ONLY to `be_chat_service` via Socket.IO. All signaling logic runs in `be_signaling_service` behind the scenes via Redis Pub/Sub bridge. Frontend never talks to the signaling service directly.

---

## Table of Contents

1. [Socket Connection](#1-socket-connection)
2. [Message Status Ticks (Sent / Delivered / Read)](#2-message-status-ticks)
3. [Online / Offline Presence](#3-online--offline-presence)
4. [Typing Indicators](#4-typing-indicators)
5. [Unread Badges](#5-unread-badges)
6. [Screen Room (Active Conversation)](#6-screen-room)
7. [Edge Cases & Gotchas](#7-edge-cases--gotchas)
8. [Event Reference Table](#8-event-reference-table)

---

## 1. Socket Connection

```
URL:  wss://chat.blueera.ai
Path: /socket
Auth: { token: "<JWT>" }
```

```javascript
const socket = io("https://chat.blueera.ai", {
  path: "/socket",
  auth: { token: jwtToken },
});
```

### Connection Events

| Event | Direction | Payload | Description |
|-------|-----------|---------|-------------|
| `connect` | Server -> Client | - | Socket connected successfully |
| `disconnect` | Server -> Client | `reason: string` | Socket disconnected |
| `connect_error` | Server -> Client | `Error` | Auth failed or server unreachable |
| `protocol:resolved` | Server -> Client | `{ version: "plain" \| "e2e" }` | Encryption protocol for this session |

---

## 2. Message Status Ticks

Messages progress through three statuses:

```
sent (single grey tick)  ->  delivered (double grey tick)  ->  read (double blue tick)
       ✓                          ✓✓                             ✓✓ (blue)
```

### 2.1 How Status is Determined at Send Time

When a message is created, the server checks the receiver's current state via Redis:

| Receiver State | Initial Status | Explanation |
|---------------|---------------|-------------|
| Offline (no socket, no room) | `sent` | Receiver is not connected |
| Online but viewing a different conversation | `delivered` | Receiver is connected but not in this conversation |
| Viewing THIS conversation (`screenRoom` matches) | `read` | Receiver is actively looking at the conversation |
| Self-conversation | `read` | Always read immediately |

**Server logic** (`socketManager.js`):
```javascript
// Redis key: userRoom:{userId} = "online" | "{conversation_id}"
getRoomStatus(receiverId, conversationId):
  if no userId      -> "sent"
  if room == convId -> "read"      // viewing this conversation
  if room == "online" -> "delivered" // online but elsewhere
  else              -> "sent"       // offline
```

### 2.2 Status Transitions After Send

#### Sent -> Delivered (User Comes Online)

When the receiver connects:
1. Chat service calls `markMessageAsDelivered(userId)` locally
2. DB update: all `sent` messages where `senderId != userId` -> `delivered`
3. Server emits `messageStatusUpdate` to each message sender

```
Receiver connects -> Server updates DB -> Sender gets event
```

#### Delivered -> Read (User Opens Conversation)

When the receiver opens a conversation:
1. Client emits `markConversationRead`
2. Signaling service receives it via Redis bridge
3. gRPC call to chat service updates DB: all `sent` + `delivered` messages -> `read`
4. Server emits `messageStatusUpdate` to conversation partners
5. Server emits `unreadCountCleared` to the reader

```
Receiver opens conversation -> Client emits markConversationRead
                            -> Server updates DB -> Sender gets event
```

### 2.3 Client Implementation

#### Emit: Mark Conversation as Read

Emit this when the user opens/views a conversation:

```javascript
socket.emit("markConversationRead", {
  conversation_id: "conv_abc123"
});
```

**When to emit:**
- When user taps/opens a conversation from the chat list
- When a new message arrives in the CURRENTLY ACTIVE conversation (auto-mark as read)
- When user navigates back to a conversation they had open

**When NOT to emit:**
- When a message arrives in a conversation the user is NOT viewing
- On app background/minimize

#### Listen: Message Status Updates

```javascript
socket.on("messageStatusUpdate", (data) => {
  // data = { status: "delivered" | "read", conversation_id: "conv_abc123" }
  
  // Update ALL outgoing message ticks in this conversation
  // NOTE: No message_id is provided — this is a bulk update for the conversation
  updateAllOutgoingTicks(data.conversation_id, data.status);
});
```

**IMPORTANT Edge Cases:**

1. **No `message_id` field** -- The server sends `{ status, conversation_id }`, NOT individual message IDs. Update ALL outgoing messages in that conversation to the new status.

2. **Status only goes forward** -- Never downgrade: if a tick shows `read`, don't change it to `delivered`. Apply updates only if the new status is "higher":
   ```javascript
   const STATUS_ORDER = { sent: 0, delivered: 1, read: 2 };
   
   function shouldUpdate(currentStatus, newStatus) {
     return STATUS_ORDER[newStatus] > STATUS_ORDER[currentStatus];
   }
   ```

3. **Sender only** -- Only outgoing messages (messages YOU sent) show ticks. Incoming messages don't have status ticks.

4. **Bulk update on conversation open** -- When the receiver opens a conversation, ALL unread messages in that conversation jump to `read`. The sender receives one `messageStatusUpdate` event for the entire conversation, not per-message.

### 2.4 Rendering Ticks

```
sent:      ✓     (grey)
delivered: ✓✓    (grey)
read:      ✓✓    (blue/accent color)
```

```dart
// Flutter example
Widget statusTick(String status) {
  switch (status) {
    case 'read':
      return Row(children: [
        Icon(Icons.done_all, size: 14, color: Colors.blue),
      ]);
    case 'delivered':
      return Row(children: [
        Icon(Icons.done_all, size: 14, color: Colors.grey),
      ]);
    case 'sent':
      return Row(children: [
        Icon(Icons.done, size: 14, color: Colors.grey),
      ]);
    default:
      return SizedBox.shrink();
  }
}
```

### 2.5 Full Tick Lifecycle Example

```
Timeline:
─────────────────────────────────────────────────────
  User A sends "Hello" to User B (who is offline)
  -> Message created with status: "sent"
  -> User A sees: ✓ (single grey tick)
  
  User B comes online (opens app)
  -> Server marks message as "delivered"
  -> User A receives: messageStatusUpdate { status: "delivered", conversation_id: "..." }
  -> User A sees: ✓✓ (double grey tick)
  
  User B opens the conversation with User A
  -> Client emits: markConversationRead { conversation_id: "..." }
  -> Server marks message as "read"
  -> User A receives: messageStatusUpdate { status: "read", conversation_id: "..." }
  -> User A sees: ✓✓ (double blue tick)
─────────────────────────────────────────────────────
```

### 2.6 Edge Case: Sent Directly to Read (Skip Delivered)

If User B is **already viewing the conversation** when User A sends a message:
- `getRoomStatus` returns `"read"` at creation time
- Message is created with `status: "read"` in DB
- The message object returned to User A already has `status: "read"`
- No separate `messageStatusUpdate` event is needed
- User A should render blue double-tick immediately

If User B is **online but NOT viewing this conversation**:
- Message is created with `status: "delivered"`
- User A sees double grey tick immediately
- When User B later opens the conversation, it transitions to `read`

---

## 3. Online / Offline Presence

### 3.1 How It Works

```
User B connects    -> Signaling service broadcasts isOnLine { is_online: true }
                   -> Signaling service sends isOnlineFromChatList to User B 
                      with all already-online partners
                   -> Signaling service sends isOnlineFromChatList to User B's 
                      partners telling them User B is online

User B disconnects -> Signaling service broadcasts isOnLine { is_online: false }
                   -> Signaling service sends isOnlineFromChatList to partners
```

### 3.2 Client Implementation

#### Listen: Online Status Events

```javascript
// Global broadcast — a user's status changed
socket.on("isOnLine", ({ user_id, is_online }) => {
  updateOnlineDot(user_id, is_online);
});

// Targeted list — batch update for chat list
socket.on("isOnlineFromChatList", (statusArray) => {
  // statusArray = [{ user_id: "abc", is_online: true }, ...]
  statusArray.forEach(({ user_id, is_online }) => {
    updateOnlineDot(user_id, is_online);
  });
});
```

### 3.3 Edge Cases

1. **Cache online state locally** -- The chat list may re-render (new message, tab switch, etc.) and wipe online dots. Keep a local `Set` of online user IDs and re-apply after every re-render:
   ```javascript
   const onlineUsers = new Set();
   
   function updateOnlineDot(userId, isOnline) {
     if (isOnline) onlineUsers.add(userId);
     else onlineUsers.delete(userId);
     renderDot(userId, isOnline);
   }
   
   // Call after every chat list re-render
   function reapplyOnlineDots() {
     onlineUsers.forEach(uid => renderDot(uid, true));
   }
   ```

2. **Initial load** -- When your socket connects, the server sends `isOnlineFromChatList` with all currently-online partners. This arrives AFTER the chat list renders, so dots will update automatically if you listen to the event. No need to make a separate API call.

3. **Multi-device** -- A user is "online" if ANY of their devices has an active socket. They go "offline" only when ALL devices disconnect.

4. **Last Seen** -- When a user goes offline, their `online:{userId}` Redis key is set to a timestamp. Use the `userLastSeenList` event for "Last seen X minutes ago" display:
   ```javascript
   socket.on("userLastSeenList", (data) => {
     // data = [{ conversation_id: "...", last_seen: "2026-04-10T13:00:00Z" }, ...]
     data.forEach(({ conversation_id, last_seen }) => {
       updateLastSeen(conversation_id, last_seen);
     });
   });
   ```

---

## 4. Typing Indicators

### 4.1 How It Works

```
User A types -> Client emits isTyping -> Chat service forwards via Redis
            -> Signaling service gets conversation members via gRPC
            -> Emits isTyping ONLY to members of that conversation (not broadcast)
```

### 4.2 Client Implementation

#### Emit: User is Typing

```javascript
let lastTypingEmit = 0;
const TYPING_DEBOUNCE_MS = 1000;

messageInput.addEventListener("input", () => {
  if (!socket?.connected || !currentConversationId) return;
  const now = Date.now();
  if (now - lastTypingEmit > TYPING_DEBOUNCE_MS) {
    lastTypingEmit = now;
    socket.emit("isTyping", { conversation_id: currentConversationId });
  }
});
```

**IMPORTANT**: Debounce to max 1 emit per second. Without debouncing, rapid typing floods the server.

#### Listen: Someone is Typing

```javascript
let typingTimer;

socket.on("isTyping", (data) => {
  // data = { conversation_id: "...", user_id: "...", user: { name: "..." } }
  
  // Only show if it's the currently active conversation and not self
  if (data.conversation_id !== currentConversationId) return;
  if (data.user_id === myUserId) return;
  
  showTypingIndicator(data.user?.name || "Someone");
  
  // Auto-clear after 3 seconds (no explicit "stop typing" event exists)
  clearTimeout(typingTimer);
  typingTimer = setTimeout(() => hideTypingIndicator(), 3000);
});
```

### 4.3 Edge Cases

1. **No "stop typing" event** -- The server does not send a "stopped typing" event. The client must auto-clear the indicator after a timeout (3 seconds recommended).

2. **Conversation switch** -- Clear the typing indicator when the user switches conversations:
   ```javascript
   function onConversationSwitch() {
     clearTimeout(typingTimer);
     hideTypingIndicator();
   }
   ```

3. **Only active conversation** -- Only show typing indicator for the currently-viewed conversation. Ignore `isTyping` events for other conversations (or optionally show a subtle indicator in the chat list).

4. **Targeted delivery** -- The server only sends `isTyping` to members of the conversation, NOT to all connected users. This is handled server-side; no client filtering needed beyond conversation matching.

---

## 5. Unread Badges

### 5.1 How It Works

Unread count comes from the chat list API response (`unread_count` field per conversation). It is cleared when the user opens a conversation and `markConversationRead` is processed.

### 5.2 Client Implementation

#### Listen: Badge Cleared

```javascript
socket.on("unreadCountCleared", (data) => {
  // data = { conversation_id: "conv_abc123" }
  clearBadge(data.conversation_id);
  refreshChatList(); // Re-fetch to get updated counts
});
```

#### When to Show Badges

```javascript
socket.on("newMessageReceived", (data) => {
  const msg = data.message;
  
  if (msg.conversation_id === currentConversationId) {
    // User is viewing this conversation — render message and mark as read
    renderMessage(msg);
    if (!msg.my_message) {
      socket.emit("markConversationRead", { conversation_id: msg.conversation_id });
    }
  } else {
    // Message in a different conversation — increment badge
    incrementBadge(msg.conversation_id);
  }
  
  // Always refresh chat list to update last message preview
  refreshChatList();
});
```

### 5.3 Edge Cases

1. **Re-render persistence** -- Same as online dots: if your chat list re-renders, badges come from the server response `unread_count` field, so they're automatically correct after a refresh. No local caching needed for badges (unlike online dots).

2. **Multiple messages** -- If 5 messages arrive while the user is in a different conversation, the badge should show `5`. The server tracks this; just re-fetch the chat list.

3. **Self-messages** -- Messages sent by the current user (`my_message: true`) should never increment badges.

---

## 6. Screen Room

The `screenRoom` event tells the server which conversation the user is currently viewing. This is used for:
- Determining initial message status (`read` if receiver is viewing the conversation)
- Online presence tracking

### 6.1 Client Implementation

```javascript
// Emit when user opens a conversation
socket.emit("screenRoom", { conversation_id: "conv_abc123" });

// Emit when user goes back to chat list (no specific conversation)
socket.emit("screenRoom", { conversation_id: "online" });
```

**When to emit:**
- Opening a conversation: `screenRoom` with the `conversation_id`
- Leaving a conversation (back to list): `screenRoom` with `"online"`
- App going to background: `screenRoom` with `"online"`
- App coming to foreground in a conversation: `screenRoom` with the `conversation_id`

### 6.2 Paired with markConversationRead

Always emit both when opening a conversation:
```javascript
function openConversation(conversationId) {
  socket.emit("screenRoom", { conversation_id: conversationId });
  socket.emit("markConversationRead", { conversation_id: conversationId });
}
```

`screenRoom` sets the room for FUTURE messages (so new incoming messages get `read` status immediately). `markConversationRead` marks EXISTING unread messages as read.

---

## 7. Edge Cases & Gotchas

### 7.1 Race: Delivered vs Read

When User B connects and immediately opens a conversation:
1. `markMessageAsDelivered` runs (sent -> delivered)
2. `markConversationRead` runs (delivered -> read)

These happen within milliseconds. The sender might see `sent -> read` directly without visible `delivered` state. This is **expected behavior** -- the delivered state existed briefly in the DB but the read event overtook it before the client rendered.

**Client handling**: Don't animate tick transitions. Just apply the latest status.

### 7.2 Chat List Re-renders Wipe Online Dots

Every `getChatList` response triggers a full DOM re-render of the chat list with grey dots. Online status events (`isOnLine`, `isOnlineFromChatList`) update dots, but if `getChatList` runs after them, dots reset to grey.

**Solution**: Cache online user IDs in a local `Set` and re-apply after every chat list render (see [Section 3.3](#33-edge-cases)).

### 7.3 No message_id in Status Updates

`messageStatusUpdate` sends `{ status, conversation_id }` without a `message_id`. This means:
- You cannot update individual message ticks
- You must update ALL outgoing messages in the conversation to the new status
- This is by design: status transitions are conversation-level, not message-level

### 7.4 Status Only Goes Forward

Never downgrade a message status:
```
read -> delivered   WRONG
read -> sent        WRONG
delivered -> sent   WRONG
```

Always check: `newStatus > currentStatus` before applying.

### 7.5 Group Conversations

- **Typing**: All group members see typing indicators (except the typer)
- **Status**: Message status in groups follows the same pattern but tracks per-member
- **Online dots**: Not shown for group conversations (only 1-to-1)

### 7.6 Offline -> Online Transition

When the app reconnects after being offline:
1. Socket `connect` fires
2. Server sends `isOnlineFromChatList` with all online partners
3. Re-fetch chat list to get updated unread counts and last messages
4. Server runs `markMessageAsDelivered` for all unread messages

### 7.7 Multiple Tabs / Devices

The server tracks one socket per user in Redis. If a user opens a second tab:
- The new socket overwrites the old one in Redis
- Events are delivered to the most recent socket only
- When the most recent socket disconnects, the user appears offline even if an older tab is still open

---

## 8. Event Reference Table

### Events the Client EMITS

| Event | Payload | When to Emit |
|-------|---------|--------------|
| `screenRoom` | `{ conversation_id: string }` | Opening a conversation or returning to chat list (`"online"`) |
| `markConversationRead` | `{ conversation_id: string }` | Opening a conversation with unread messages |
| `isTyping` | `{ conversation_id: string }` | User is typing (debounced, max 1/sec) |
| `messageReceived` | `{ conversation_id: string }` | Request messages for a conversation |
| `ChatList` | `{ type: "personal" \| "group" }` | Request chat list |

### Events the Client LISTENS TO

| Event | Payload | Action |
|-------|---------|--------|
| `messageStatusUpdate` | `{ status: string, conversation_id: string }` | Update outgoing message ticks for this conversation |
| `unreadCountCleared` | `{ conversation_id: string }` | Remove unread badge for this conversation |
| `newMessageReceived` | `{ message: MessageObject }` | Render new message or increment badge |
| `isOnLine` | `{ user_id: string, is_online: boolean }` | Update online dot for this user |
| `isOnlineFromChatList` | `Array<{ user_id, is_online }>` | Batch update online dots |
| `isTyping` | `{ conversation_id: string, user_id: string, user: { name } }` | Show typing indicator |
| `userLastSeenList` | `Array<{ conversation_id, last_seen }>` | Show "last seen" timestamps |
| `ChatList` | `{ success: boolean, chatList: Array }` | Render chat list |
| `messageReceived` | `{ messages: Array }` | Render messages for a conversation |

---

## Quick Start Checklist

- [ ] Connect socket with JWT auth
- [ ] Listen to `isOnLine` and `isOnlineFromChatList` -- cache online IDs in a Set
- [ ] Listen to `isTyping` -- show indicator for active conversation, auto-clear after 3s
- [ ] Emit `screenRoom` when opening/leaving conversations
- [ ] Emit `markConversationRead` when opening a conversation
- [ ] Listen to `messageStatusUpdate` -- update ALL outgoing ticks in the conversation
- [ ] Listen to `unreadCountCleared` -- clear badge for that conversation
- [ ] Listen to `newMessageReceived` -- render if active conversation, else increment badge
- [ ] Emit `isTyping` on input with 1s debounce
- [ ] Re-apply online dots after every chat list re-render
