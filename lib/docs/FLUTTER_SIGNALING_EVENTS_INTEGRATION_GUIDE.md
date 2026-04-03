# Signaling Service — Flutter App Integration Guide

This guide explains how real-time signaling events (online status, typing indicators, message delivery status, and unread counts) work in the BlueEra Flutter app, and what the signaling service migration means for the app.

---

## TL;DR — What Changes for the App?

**Nothing.** The signaling service is completely transparent to the Flutter app. You do NOT need to:
- Change any socket connection URLs
- Change any event names
- Change any event payloads
- Add any new dependencies or API clients

The socket connection stays at `wss://chat.blueera.ai/socket`. All events flow through the same socket. The chat service transparently relays signaling events to/from the signaling service via Redis.

However, this guide documents all the signaling events for reference, and highlights **improvements** that the app can take advantage of (like the typing indicator fix).

---

## Table of Contents

1. [Socket Connection (No Changes)](#1-socket-connection-no-changes)
2. [Online/Presence Events](#2-onlinepresence-events)
3. [Typing Indicators](#3-typing-indicators)
4. [Message Status Events](#4-message-status-events)
5. [Screen Room Tracking](#5-screen-room-tracking)
6. [Event Constants Reference](#6-event-constants-reference)
7. [Complete Data Flow Diagrams](#7-complete-data-flow-diagrams)
8. [What Changed Under the Hood](#8-what-changed-under-the-hood)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Socket Connection (No Changes)

The app connects to the chat service socket exactly as before. No URL, path, or auth changes.

```dart
// File: lib/features/chat/auth/socket/chat_socket.dart
// This code is UNCHANGED

_socket = IO.io(chatSocketUrl,
  IO.OptionBuilder()
      .setTransports(['websocket'])
      .setPath('/socket')
      .enableForceNew()
      .setAuth({'token': '$authTokenGlobal'})
      .build(),
);
```

On connect, the app emits the same initial events:

```dart
// File: lib/features/chat/auth/socket/chat_socket.dart (line 68-70)
// These are UNCHANGED

_socket!.emit(ChatEmitEvents.screenRoom, {ApiKeys.conversation_id: "online"});
_socket!.emit(ChatEmitEvents.isOnlineFromChatList, {});
_socket!.emit(ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.personal_Chat_Type});
```

---

## 2. Online/Presence Events

### How Online Status Works

When any user connects or disconnects, the signaling service computes who needs to know and sends targeted updates through the chat service socket.

### Event: `isOnLine` (Listen)

Fired when **any** user's online status changes. The app currently has this listener commented out but it is still emitted by the server.

**Payload:**
```json
{
  "user_id": "64abc123def456",
  "is_online": true
}
```

**How to use in Flutter:**
```dart
// Listen for individual user status changes
chatSocket.listenEvent('isOnLine', (data) {
  final userId = data['user_id'] as String;
  final isOnline = data['is_online'] as bool;

  // Update UI for this specific user
  // e.g., show green dot on their avatar in chat list
  if (userId == userOpenUserId.value) {
    userOnlineStatus.value = isOnline ? "Online" : "Offline";
  }
});
```

### Event: `isOnlineFromChatList` (Listen)

Fired when a user's conversation partner connects/disconnects. Sends a targeted update with only the changed user's status (not the full list anymore).

**Payload:**
```json
[
  {
    "user_id": "64abc123def456",
    "is_online": true
  }
]
```

**Current Flutter usage:**
```dart
// File: lib/features/chat/auth/controller/chat_view_controller.dart (line 848-859)

chatSocket.listenEvent(ChatEmitEvents.isOnlineFromChatList, (data) {
  final List<Map<String, dynamic>> datas =
      List<Map<String, dynamic>>.from(data);

  // Find the user you're currently chatting with
  final Map<String, dynamic> user = datas.firstWhere(
    (e) => e['user_id'] == userOpenUserId.value,
    orElse: () => {},
  );

  userOnlineStatus.value =
      user['is_online'] == true ? "Online" : "Offline";
});
```

**Improvement opportunity:** The signaling service now sends incremental updates (only the user whose status changed) rather than the full list. The app's current code handles this correctly since it uses `firstWhere` to find the relevant user.

To also update the chat list indicators (green dots), you could extend this:

```dart
chatSocket.listenEvent(ChatEmitEvents.isOnlineFromChatList, (data) {
  final List<Map<String, dynamic>> updates =
      List<Map<String, dynamic>>.from(data);

  for (final update in updates) {
    final userId = update['user_id'] as String;
    final isOnline = update['is_online'] as bool;

    // Update the active chat screen
    if (userId == userOpenUserId.value) {
      userOnlineStatus.value = isOnline ? "Online" : "Offline";
    }

    // Update chat list online indicators
    // (Add your chat list update logic here)
  }
});
```

---

## 3. Typing Indicators

### What Changed (Improvement)

Previously, typing events were broadcast to **ALL** connected users using `io.emit()`. This was wasteful — if 1000 users were online, every keystroke sent 1000 socket emissions.

The signaling service now sends typing events **only to members of the conversation**. This means:
- Less battery drain on mobile devices (fewer socket events to process)
- Less bandwidth usage
- More accurate — users only see typing from conversations they're in

### Event: `isTyping` (Emit)

Emit this when the user starts typing in a conversation.

**Payload to send:**
```json
{
  "conversation_id": "64abc123def456"
}
```

**How to emit in Flutter:**
```dart
// Call this when the user starts typing
void onUserTyping(String conversationId) {
  chatSocket.emitEvent('isTyping', {
    ApiKeys.conversation_id: conversationId,
  });
}

// Example: Attach to a TextField's onChanged
TextField(
  onChanged: (text) {
    if (text.isNotEmpty) {
      onUserTyping(conversationId);
    }
  },
)
```

**Recommended: Debounce typing events** to avoid flooding the server with every keystroke:

```dart
Timer? _typingTimer;

void onUserTyping(String conversationId) {
  // Only emit once every 2 seconds
  if (_typingTimer?.isActive ?? false) return;

  chatSocket.emitEvent('isTyping', {
    ApiKeys.conversation_id: conversationId,
  });

  _typingTimer = Timer(const Duration(seconds: 2), () {});
}
```

### Event: `isTyping` (Listen)

Receive this when another user is typing in a conversation you're viewing.

**Payload received:**
```json
{
  "conversation_id": "64abc123def456",
  "user_id": "64xyz789ghi012",
  "user": {
    "_id": "64xyz789ghi012",
    "name": "John Doe",
    "profile_image": "https://...",
    "contact_no": "9876543210"
  }
}
```

**How to use in Flutter:**
```dart
// In your chat controller's connectSocket() method
chatSocket.listenEvent('isTyping', (data) {
  final conversationId = data['conversation_id'] as String;
  final typingUserId = data['user_id'] as String;
  final typingUser = data['user'];

  // Only show typing indicator if we're viewing this conversation
  if (conversationId == userOpenConversationId.value) {
    // Show "John is typing..." in the chat header
    showTypingIndicator(typingUser?['name'] ?? 'Someone');

    // Auto-hide after 3 seconds (in case stop-typing event is missed)
    Future.delayed(const Duration(seconds: 3), () {
      hideTypingIndicator();
    });
  }
});
```

**For group chats**, you might want to show multiple typing users:

```dart
final Map<String, String> _typingUsers = {}; // userId -> name
final Map<String, Timer> _typingTimers = {};

chatSocket.listenEvent('isTyping', (data) {
  final conversationId = data['conversation_id'] as String;
  final typingUserId = data['user_id'] as String;
  final name = data['user']?['name'] ?? 'Someone';

  if (conversationId != userOpenConversationId.value) return;

  _typingUsers[typingUserId] = name;
  _typingTimers[typingUserId]?.cancel();
  _typingTimers[typingUserId] = Timer(const Duration(seconds: 3), () {
    _typingUsers.remove(typingUserId);
    _updateTypingText();
  });

  _updateTypingText();
});

void _updateTypingText() {
  if (_typingUsers.isEmpty) {
    typingText.value = '';
  } else if (_typingUsers.length == 1) {
    typingText.value = '${_typingUsers.values.first} is typing...';
  } else {
    typingText.value = '${_typingUsers.length} people are typing...';
  }
}
```

---

## 4. Message Status Events

### Event: `messageStatusUpdate` (Listen)

Fired when your message's delivery status changes. There are three statuses:

| Status | Meaning | Visual |
|--------|---------|--------|
| `sent` | Server received the message | Single grey tick |
| `delivered` | Recipient's device received it | Double grey ticks |
| `read` | Recipient opened the conversation | Double blue ticks |

**Payload:**
```json
{
  "status": "read",
  "conversation_id": "64abc123def456"
}
```

**Current Flutter usage:**
```dart
// File: lib/features/chat/auth/controller/chat_view_controller.dart (line 861-865)

chatSocket.listenEvent(ChatEmitEvents.messageStatusUpdate, (data) {
  if (data['conversation_id'] == userOpenConversationId.value) {
    readMessageStatus.value = data['status'];
  }
});
```

This code is correct and needs no changes. When you receive `status: "read"`, update the tick marks to blue for all messages in that conversation.

### Event: `unreadCountCleared` (Listen)

Fired when the unread count for a conversation should be reset to zero (because the user opened/read the conversation).

**Payload:**
```json
{
  "conversation_id": "64abc123def456"
}
```

**How to use in Flutter:**
```dart
chatSocket.listenEvent('unreadCountCleared', (data) {
  final conversationId = data['conversation_id'] as String;

  // Reset unread badge in chat list for this conversation
  updateChatListUnreadCount(conversationId, 0);
});
```

### Event: `markConversationRead` (Emit)

Emit this when the user opens a conversation to mark all messages as read. This is a lightweight alternative to the full `messageReceived` flow.

**Payload to send:**
```json
{
  "conversation_id": "64abc123def456"
}
```

**How to emit in Flutter:**
```dart
void openConversation(String conversationId) {
  chatSocket.emitEvent('markConversationRead', {
    ApiKeys.conversation_id: conversationId,
  });
}
```

---

## 5. Screen Room Tracking

### Event: `screenRoom` (Emit)

This tells the server which conversation the user is currently viewing. It's used to determine message delivery status — if a user is viewing the conversation, new messages are immediately marked as "read" instead of "delivered".

**When to emit:**
- On socket connect: `{ conversation_id: "online" }` (user is on home/chat list screen)
- When opening a chat: `{ conversation_id: "<actual_id>" }` (user is viewing this conversation)
- When leaving a chat: `{ conversation_id: "online" }` (user went back to chat list)

**Current Flutter usage:**
```dart
// File: lib/features/chat/auth/controller/chat_view_controller.dart (line 1058-1064)

void listenUserNewMessages({required String conversationId, required String userId}) {
  userOpenConversationId.value = conversationId;
  userOpenUserId.value = userId;
  // Tell server which conversation we're viewing
  emitEvent(ChatEmitEvents.screenRoom,
      {ApiKeys.conversation_id: "${conversationId}"});
  addConversationOnce(conversationId);
}

// And when leaving the chat (line 1286):
chatSocket.emitEvent(ChatEmitEvents.screenRoom, {ApiKeys.conversation_id: "online"});
```

This code is correct and needs no changes.

---

## 6. Event Constants Reference

Here's the complete reference of all signaling-related event constants used in the app:

```dart
// File: lib/core/constants/app_constant.dart (line 2065-2075)

class ChatEmitEvents {
  static const ChatList = "ChatList";
  static const screenRoom = "screenRoom";              // Emit: tell server which screen you're on
  static const messageReceived = "messageReceived";
  static const messageViewed = "messageViewed";
  static const isOnlineFromChatList = "isOnlineFromChatList"; // Listen: online status updates
  static const newMessageReceived = "newMessageReceived";
  static const isOnLine = "isOnLine";                  // Listen: single user online/offline
  static const messageStatusUpdate = "messageStatusUpdate";   // Listen: sent/delivered/read
  static const update_data = "update_data";
}

// Additional signaling events (not in ChatEmitEvents yet):
// "isTyping"             — Emit & Listen: typing indicator
// "markConversationRead" — Emit: mark conversation as read
// "unreadCountCleared"   — Listen: unread badge reset
// "userLastSeenList"     — Listen: last-seen timestamps
```

### Quick Reference Table

| Event Name | Direction | When to Use | Payload |
|------------|-----------|-------------|---------|
| `screenRoom` | Emit | User opens/leaves a chat | `{ conversation_id: "..." }` |
| `isTyping` | Emit | User starts typing | `{ conversation_id: "..." }` |
| `isTyping` | Listen | Another user is typing | `{ conversation_id, user_id, user }` |
| `markConversationRead` | Emit | User opens a conversation | `{ conversation_id: "..." }` |
| `isOnLine` | Listen | Any user's status changes | `{ user_id, is_online }` |
| `isOnlineFromChatList` | Listen | Conversation partner status changes | `[{ user_id, is_online }]` |
| `messageStatusUpdate` | Listen | Message delivery status changes | `{ status, conversation_id }` |
| `unreadCountCleared` | Listen | Unread count reset | `{ conversation_id }` |
| `userLastSeenList` | Listen | Last-seen timestamps | `{ lastSeenUserList: [...] }` |

---

## 7. Complete Data Flow Diagrams

### Online Status Flow (User Goes Online)

```
Flutter App                     Chat Service                  Signaling Service
    |                               |                               |
    |-- socket.connect() ---------> |                               |
    |                               |-- Redis: signaling:user:connected -->|
    |                               |                               |
    |                               |                      [Compute partners via gRPC]
    |                               |                      [Check which partners are online]
    |                               |                               |
    |                               |<-- Redis: signaling:socket:emit --|
    |                               |    (isOnlineFromChatList)     |
    |                               |                               |
    |<-- isOnlineFromChatList ------|                               |
    |   [{user_id: "abc", is_online: true}]                        |
```

### Typing Flow

```
Flutter App (User A)            Chat Service                  Signaling Service
    |                               |                               |
    |-- emit("isTyping") --------> |                               |
    |   {conversation_id: "xyz"}   |-- Redis: signaling:socket:recv -->|
    |                               |                               |
    |                               |                   [Get conversation members via gRPC]
    |                               |                   [Filter out User A]
    |                               |                   [Result: User B, User C]
    |                               |                               |
    |                               |<-- Redis: signaling:socket:emit --|
    |                               |    (isTyping to User B, C)    |
    |                               |                               |

Flutter App (User B)            Chat Service
    |                               |
    |<-- "isTyping" event ----------|
    |   {conversation_id, user_id: "A", user: {...}}
    |
    |   [Show "User A is typing..." in chat header]
```

### Message Status Flow

```
Flutter App (Sender)            Chat Service                  Signaling Service
    |                               |                               |
    | (sends message via REST/socket)                               |
    |                               |                               |

Flutter App (Receiver)          Chat Service                  Signaling Service
    |                               |                               |
    |-- socket reconnects -------> |                               |
    |                               |-- Redis: signaling:user:connected -->|
    |                               |                               |
    |                               |                   [Call MarkMessagesDelivered gRPC]
    |                               |                   [DB updates: sent -> delivered]
    |                               |                               |
    |                               |<-- Redis: signaling:socket:emit --|
    |                               |    (messageStatusUpdate to Sender)
    |                               |                               |

Flutter App (Sender)            Chat Service
    |                               |
    |<-- "messageStatusUpdate" ----|
    |   {status: "delivered", conversation_id: "xyz"}
    |
    |   [Update tick marks: grey single -> grey double]
```

---

## 8. What Changed Under the Hood

For the curious developer, here's what actually changed server-side:

| Before (Chat Service Only) | After (Chat + Signaling Service) |
|---------------------------|----------------------------------|
| `io.emit("isTyping", ...)` broadcasts to ALL 1000+ connected users | Typing events sent only to 2-20 conversation members |
| `broadcastChatListOnlineStatus()` runs 200+ MongoDB queries on every connect/disconnect | Signaling service handles presence with gRPC caching, chat service CPU freed |
| `markMessageAsDelivered()` blocks the socket connect flow with N DB writes | Handled asynchronously by signaling service after connect |
| Online status computation mixed with message handling code | Clean separation — signaling is its own service |

### Performance Benefits for the App

1. **Fewer junk socket events** — Your app no longer receives typing events from conversations you're not in. Less CPU/battery usage on the device.
2. **Faster socket connects** — The heavy `markMessageAsDelivered` and `broadcastChatListOnlineStatus` no longer block the connection. You get your `ChatList` faster.
3. **More accurate online indicators** — Presence computation is now a dedicated concern, not a side-effect of other operations.

---

## 9. Troubleshooting

### "Online status not updating"

1. Make sure you emit `screenRoom` with `{ conversation_id: "online" }` on socket connect
2. Verify you're listening to `isOnlineFromChatList` event
3. The signaling service sends incremental updates (array with 1 item), not the full list

### "Typing indicator not showing"

1. Make sure you emit `isTyping` with the `conversation_id`
2. Listen for `isTyping` event and check `data['conversation_id']` matches the open conversation
3. Add a 3-second auto-hide timer — there's no explicit "stopped typing" event

### "Message ticks not updating"

1. Listen for `messageStatusUpdate` event
2. Check `data['conversation_id']` matches the conversation you're displaying
3. Update ALL messages in that conversation to the new status (not just one)

### "Unread badge not clearing"

1. Emit `markConversationRead` when opening a conversation
2. Listen for `unreadCountCleared` to reset the badge
3. Also emit `screenRoom` with the conversation ID to get real-time read receipts

---

## Summary

| What | Change Required? | Details |
|------|:----------------:|---------|
| Socket URL | No | Same `wss://chat.blueera.ai/socket` |
| Event names | No | All identical |
| Event payloads | No | All identical |
| Auth/tokens | No | Same JWT token |
| New constants | No | All existing constants work |
| New API calls | No | No REST endpoints for signaling |
| Dependencies | No | No new packages needed |

**The signaling service is invisible to the app.** It runs behind the chat service and handles all the presence/typing/status heavy-lifting via Redis, making the chat service leaner and the overall system more scalable.
