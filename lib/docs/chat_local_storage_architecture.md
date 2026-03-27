# BlueEra Chat — Local Storage & Message Sync Architecture

> This document explains how the Flutter app stores chat data locally, syncs with the backend, and handles offline scenarios. Intended for backend developers to understand the client-side flow.

> **E2E Encryption:** This document covers the plain-text chat local storage architecture only. For E2E encrypted chat, see **[Section 15: Local Storage Requirements](./e2e-encryption-flutter-integration-guide.md#15-local-storage-requirements)** in the Flutter E2E Integration Guide — it covers the SQLite/Hive schemas for encrypted messages, sync cursors, Signal sessions, and OPK tracking, as well as the `flutter_secure_storage` keys for private keys.

---

## Table of Contents

1. [Storage Technologies](#1-storage-technologies)
2. [Chat List (Conversations) Local Storage](#2-chat-list-conversations-local-storage)
3. [Chat Messages Local Storage](#3-chat-messages-local-storage)
4. [Offline Message Queue & Sync](#4-offline-message-queue--sync)
5. [Media Files Local Storage](#5-media-files-local-storage)
6. [Socket Events That Update Local Storage](#6-socket-events-that-update-local-storage)
7. [Message Lifecycle — Send Flow](#7-message-lifecycle--send-flow)
8. [Message Lifecycle — Receive Flow](#8-message-lifecycle--receive-flow)
9. [Chat History Loading Strategy](#9-chat-history-loading-strategy)
10. [Read/Unread Tracking](#10-readunread-tracking)
11. [Media Compression Before Upload](#11-media-compression-before-upload)
12. [Hive Models & Type IDs](#12-hive-models--type-ids)
13. [Key File Locations](#13-key-file-locations)

---

## 1. Storage Technologies

| Technology | Purpose |
|---|---|
| **Hive** (NoSQL boxes) | Structured message & chat list caching |
| **SharedPreferences** | Auth tokens, user IDs, global settings |
| **File System** | Downloaded media files (images, videos, audio, documents) |

### Hive Boxes Used

| Box Name | Content |
|---|---|
| `messagesBox` | Serialized messages per conversation (key = `conversationId`) |
| `chatListJsonBox` | Chat list metadata per type (key = `{type}_chat_list`) |
| `conversationBox` | List of opened conversation IDs |
| `userImages` | Cached profile images (local file paths) |
| `aiChatBox` | AI conversation IDs |
| `walletChatBox` | Wallet self-conversation storage |

---

## 2. Chat List (Conversations) Local Storage

### Save Flow

```
API/Socket returns chat list
  → saveChatList(chats, type)
    → Download sender profile images to device
    → Replace remote image URLs with local paths
    → JSON-encode and store in chatListJsonBox
    → Key: "{type}_chat_list"
```

### Chat Types

| Type Key | Description |
|---|---|
| `PERSONAL_CHAT` | 1-to-1 conversations |
| `BUSINESS_CHAT` | Business conversations |
| `GROUP` | Group conversations |

### Stored Schema

```json
{
  "conversation_id": "64abc...",
  "is_group": false,
  "last_message": "Hey!",
  "last_message_type": "text",
  "created_at": "2025-03-17T10:00:00.000Z",
  "updated_at": "2025-03-17T10:05:00.000Z",
  "unread_count": 3,
  "public_group": false,
  "sender": {
    "_id": "senderId",
    "name": "John",
    "profile_image": "/local/path/to/image.jpg"
  },
  "tagged": [],
  "symbolData": []
}
```

### Retrieval

```
getChatListFromLocal(type)        → List<ChatList> for one type
getAllChatListsFromLocal()         → Map<String, List<ChatList>> for all 3 types
```

---

## 3. Chat Messages Local Storage

### Save Flow

```
saveMessagesByConversationId(conversationId, List<Messages>)
  → For each message:
    → Download media files to device (if any)
    → Replace remote URLs with local file paths
  → JSON-encode full message list
  → Store in messagesBox (key = conversationId)
```

### Single Message Append

```
saveSingleMessageToConversationId(conversationId, message, sendStatus)
  → Load existing messages from box
  → Append new message
  → Download media → replace URLs
  → Save back to box
```

### Stored Message Schema

```json
{
  "_id": "msg_64abc...",
  "message": "Hello!",
  "message_type": "text",
  "sender_id": "user123",
  "conversation_id": "conv456",
  "my_message": true,
  "created_at": "2025-03-17T10:05:00.000Z",
  "message_read": 0,
  "sendStatus": "",
  "url": [
    {
      "url": "/local/path/to/image.jpg",
      "type": "image",
      "name": "photo.jpg",
      "size": 204800,
      "mimetype": "image/jpeg",
      "_id": "url_id"
    }
  ],
  "reply_message": null,
  "tagged_users": [],
  "reactions": []
}
```

### Key Fields for Backend

| Field | Values | Notes |
|---|---|---|
| `sendStatus` | `""` (sent), `"pending"` (queued offline) | Backend only sees messages after they leave pending |
| `my_message` | `true`/`false` | Set client-side by comparing `sender_id` with local `userId` |
| `message_type` | `text`, `image`, `video`, `audio`, `document`, `contact`, `location`, `live_location` | Determines media handling |
| `pendingFilePaths` | `["/path/to/file"]` | Local file paths for retry (only on pending messages) |

---

## 4. Offline Message Queue & Sync

### How Pending Messages Work

```
User sends message while offline
  → Message saved to Hive with sendStatus = "pending"
  → sendPendingMsgParams saved alongside (original API payload)
  → pendingFilePaths saved for media messages
  → Message shown in UI immediately (optimistic update)
```

### Sync on Reconnection

```
sendOfflineMessage(conversationId)
  → getUnsentMessages(conversationId)  // filter sendStatus == "pending"
  → For each pending message (reverse order):
    → If text/document/contact/location:
        sendOfflineMessageToServer(sendPendingMsgParams, messageId)
    → If image/video:
        Re-upload via generateUploadUrlsApi(isPendingMessage: true)
  → On success:
    → markMessageAsSent(conversationId, messageId)
    → Update sendStatus: "pending" → "sent"
    → Replace temp _id with server-assigned _id
```

### Pending Message Payload (saved locally)

```json
{
  "_id": "2025-03-17T10:00:00.000Z_conv456",
  "sendStatus": "pending",
  "sendPendingMsgParams": {
    "conversation_id": "conv456",
    "message": "Hello!",
    "message_type": "text"
  },
  "pendingFilePaths": ["/path/to/file1.jpg"]
}
```

### Important for Backend

- Pending messages have a **temporary `_id`** (timestamp + conversationId format)
- After server ACK, the `_id` is **replaced** with the server-assigned ID
- Backend should return the new `_id` in the send message response
- No automatic background sync — retry is triggered when user opens the chat

---

## 5. Media Files Local Storage

### Storage Paths

**Android 10+ (API 29+) — No permissions needed:**
```
/storage/emulated/0/Android/media/ai.bluecs.app/
  ├── BlueEra Images/
  ├── BlueEra Video/
  ├── BlueEra Audio/
  └── BlueEra Documents/
```

**Android < 10 — Requires storage permission:**
```
/storage/emulated/0/BlueEra/Media/
  ├── BlueEra Images/
  ├── BlueEra Video/
  ├── BlueEra Audio/
  └── BlueEra Documents/
```

**iOS — Visible in Files app + Photos library:**
```
Documents/BlueEra/Media/
  ├── BlueEra Images/   → also saved to iOS Photos (Camera Roll)
  ├── BlueEra Video/    → also saved to iOS Photos (Camera Roll)
  ├── BlueEra Audio/
  └── BlueEra Documents/
```

### Media Download Flow (on receive)

```
Message received with media URL
  → ChatMediaStorageService.downloadAndSave(url, messageType)
    → Download from S3 URL
    → Save to device folder based on messageType
    → Android: trigger MediaStore scan (appears in gallery)
    → iOS: save to Photos library via Gal package
    → Return local file path
  → Replace remote URL with local path in Hive
```

### Media Caching

```
ChatMediaStorageService.findExistingFile(url, messageType)
  → Check if file already downloaded
  → If exists: return local path (skip download)
  → If not: return null (trigger download)
```

---

## 6. Socket Events That Update Local Storage

| Socket Event | Direction | Local Storage Action |
|---|---|---|
| `ChatList` | Server → Client | `saveChatList()` — updates conversation list |
| `messageReceived` | Server → Client | `saveMessagesByConversationId()` — bulk save page of messages |
| `newMessageReceived` | Server → Client | `saveSingleMessageToConversationId()` — append single message |
| `messageStatusUpdate` | Server → Client | Updates `readMessageStatus` (UI only, not persisted) |
| `messageViewed` | Server → Client | UI update only |
| `update_data` | Server → Client | Triggers re-emit of `messageReceived` to refresh |
| `screenRoom` | Client → Server | Room subscription (no local storage) |
| `isOnlineFromChatList` | Server → Client | Online status (UI only) |

### Socket Payload — `messageReceived` (Server → Client)

```json
{
  "conversation_id": "conv456",
  "messages": [
    {
      "_id": "msg_001",
      "message": "Hello",
      "message_type": "text",
      "sender_id": "user123",
      "created_at": "2025-03-17T10:05:00.000Z",
      "url": [],
      "reactions": [],
      "tagged_users": []
    }
  ],
  "page": 1,
  "total_pages": 5
}
```

### Socket Payload — `newMessageReceived` (Server → Client)

```json
{
  "_id": "msg_002",
  "message": "Hi there!",
  "message_type": "text",
  "sender_id": "user789",
  "conversation_id": "conv456",
  "created_at": "2025-03-17T10:06:00.000Z",
  "url": [],
  "sender": {
    "_id": "user789",
    "name": "Jane",
    "profile_image": "https://s3.../profile.jpg"
  }
}
```

---

## 7. Message Lifecycle — Send Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User taps Send                                           │
│    └─ Compress media (if image/video)                       │
│                                                             │
│ 2. Save to local storage (sendStatus = "pending")           │
│    └─ Message appears in UI immediately                     │
│                                                             │
│ 3. Upload media to S3 (if media message)                    │
│    ├─ generateUploadUrlsApi() → get pre-signed URLs         │
│    ├─ uploadFileToS3() → PUT file to S3                     │
│    └─ Progress tracked via onProgress callback              │
│                                                             │
│ 4. Send message to backend                                  │
│    ├─ Small files: multipart POST to /sendMessage           │
│    ├─ Large files: POST with S3 public URLs                 │
│    └─ Socket emit for real-time delivery                    │
│                                                             │
│ 5. On success                                               │
│    ├─ markMessageAsSent() → sendStatus = "sent"             │
│    ├─ Replace temp _id with server _id                      │
│    └─ Update UI (remove pending indicator)                  │
│                                                             │
│ 6. On failure (offline)                                     │
│    ├─ Message stays sendStatus = "pending"                  │
│    ├─ sendPendingMsgParams saved for retry                  │
│    └─ Retried when sendOfflineMessage() called              │
└─────────────────────────────────────────────────────────────┘
```

---

## 8. Message Lifecycle — Receive Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Socket receives newMessageReceived event                 │
│                                                             │
│ 2. Parse message JSON → Messages model                      │
│    └─ Set my_message flag (compare sender_id with userId)   │
│                                                             │
│ 3. Save to local storage                                    │
│    ├─ saveSingleMessageToConversationId()                   │
│    ├─ Download media files to device                        │
│    └─ Replace remote URLs with local paths                  │
│                                                             │
│ 4. Update UI                                                │
│    ├─ Add message to getListOfMessageData                   │
│    ├─ Scroll to bottom                                      │
│    └─ Play notification sound (if not in same chat)         │
│                                                             │
│ 5. Refresh chat list                                        │
│    └─ Emit ChatList event to update last_message            │
└─────────────────────────────────────────────────────────────┘
```

---

## 9. Chat History Loading Strategy

```
User opens a conversation
  │
  ├─ Step 1: Load from local cache (INSTANT)
  │    └─ getMessagesByConversationId(conversationId)
  │       → Display cached messages immediately
  │
  ├─ Step 2: Fetch from server (ASYNC)
  │    └─ Socket emit: messageReceived {
  │         conversation_id,
  │         page: 1,
  │         per_page_message: 30,
  │         is_online_user: userId
  │       }
  │
  ├─ Step 3: Server responds with fresh messages
  │    └─ saveMessagesByConversationId() → REPLACES cache
  │       → UI updated with server data
  │
  └─ Step 4: Sync offline messages
       └─ sendOfflineMessage(conversationId)
          → Send any pending messages to server
```

### Pagination

- **Server-side pagination**: `page` + `per_page_message` (30 per page)
- **Local cache**: stores ALL loaded messages (no local pagination)
- **Scroll-up loading**: emits `messageReceived` with incremented `page`

---

## 10. Read/Unread Tracking

| Level | Storage | Mechanism |
|---|---|---|
| **Conversation-level** | `unread_count` in chat list | Decremented when user opens chat |
| **Message-level** | `message_read` field (0/1) | Updated via `messageStatusUpdate` socket event |
| **Read receipt** | Not persisted locally | Real-time via socket, UI-only |

### Backend Should

- Send `messageStatusUpdate` event when recipient reads messages
- Include `message_read: 1` in message responses for read messages
- Track `unread_count` per conversation and include in chat list response

---

## 11. Media Compression Before Upload

All media is compressed client-side before upload to reduce bandwidth:

| Media Type | Compression | Typical Output |
|---|---|---|
| **Image** | JPEG quality 70, max 1600px | ~100-250 KB |
| **Video** | 720p, medium bitrate | ~5-6 MB/min |
| **Audio** | Already AAC format | ~500 KB/min |
| **Document** | No compression (PDF) | As-is |

### Upload Strategy

| File Size | Method |
|---|---|
| **Small (camera shots)** | Direct multipart POST to `/sendMessage` |
| **Large (gallery picks)** | Pre-signed S3 URL → PUT to S3 → send message with public URLs |

### Pre-signed URL Flow

```
Client                          Backend                         S3
  │                               │                              │
  ├─ GET /generateUploadUrls ────►│                              │
  │  {fileName, fileType}         │                              │
  │                               │                              │
  │◄── {uploadUrl, publicUrl} ────┤                              │
  │                               │                              │
  ├─ PUT compressed file ─────────┼─────────────────────────────►│
  │  (to pre-signed uploadUrl)    │                              │
  │                               │                              │
  ├─ POST /sendMessage ──────────►│                              │
  │  {url: [{url: publicUrl}]}    │                              │
  │                               │                              │
```

---

## 12. Hive Models & Type IDs

| TypeId | Model | Fields |
|---|---|---|
| 12 | `HiveChatList` | conversationId, isGroup, lastMessage, lastMessageType, createdAt, updatedAt, unreadCount, sender |
| 13 | `HiveSender` | id, name, profileImage |
| 14 | `HiveMessage` | id, message, messageType, senderId, conversationId, createdAt, url, sendStatus, myMessage |

---

## 13. Key File Locations

| Component | Path |
|---|---|
| Local Storage Helper | `lib/core/services/local_strorage_helper.dart` |
| Media Storage Service | `lib/core/services/chat_media_storage_service.dart` |
| Media Compression | `lib/core/services/chat_media_compression_service.dart` |
| Chat Controller | `lib/features/chat/auth/controller/chat_view_controller.dart` |
| Chat Repository | `lib/features/chat/auth/repo/chat_view_repo.dart` |
| Chat Socket Service | `lib/features/chat/auth/socket/chat_socket.dart` |
| Hive Models | `lib/features/chat/auth/hive_models/` |
| Message Models | `lib/features/chat/auth/model/GetListOfMessageData.dart` |
| API Keys & Events | `lib/core/api/apiService/api_keys.dart` |
| SharedPreferences | `lib/core/constants/shared_preference_utils.dart` |

---

## Architecture Notes for Backend

1. **Offline-first**: Messages are displayed from local cache instantly, then refreshed from server
2. **Optimistic sends**: Messages appear in UI before server confirms — backend must return the assigned `_id` quickly
3. **No background sync**: Pending messages are retried only when user opens the chat — backend should not assume real-time delivery
4. **Media URL replacement**: Client downloads media and stores locally — backend URLs are only used for initial download
5. **Conversation-keyed storage**: All messages stored under `conversationId` — backend pagination is server-side only
6. **Socket-driven updates**: All real-time updates flow through socket events — REST API is used only for initial load and file uploads
7. **Compressed uploads**: All images/videos are compressed before upload — backend receives smaller files than the original
