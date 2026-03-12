# Voice & Video Call - Flutter Frontend Integration Guide

This document provides complete step-by-step details for implementing in-house WebRTC voice and video calling in the Flutter mobile app. The backend uses Socket.IO for real-time signaling and REST APIs for call lifecycle management.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Required Flutter Packages](#2-required-flutter-packages)
3. [Data Models](#3-data-models)
4. [REST API Endpoints](#4-rest-api-endpoints)
5. [Socket.IO Events Reference](#5-socketio-events-reference)
6. [Call Flow: 1-to-1 Audio/Video Call](#6-call-flow-1-to-1-audiovideo-call)
7. [Call Flow: Group Call](#7-call-flow-group-call)
8. [WebRTC Implementation](#8-webrtc-implementation)
9. [UI Screens Required](#9-ui-screens-required)
10. [Push Notifications for Calls](#10-push-notifications-for-calls)
11. [Edge Cases & Error Handling](#11-edge-cases--error-handling)
12. [Call History UI](#12-call-history-ui)
13. [Screen Sharing](#13-screen-sharing)
14. [Testing Checklist](#14-testing-checklist)

---

## 1. Architecture Overview

The call system is fully in-house WebRTC. Audio/video streams flow **peer-to-peer** between devices. The backend only handles:
- **Signaling** - Relaying SDP offers/answers and ICE candidates via Socket.IO
- **Call state** - Tracking call lifecycle (ringing, connecting, connected, ended) via REST APIs
- **Notifications** - Push notifications via Kafka event pipeline (→ notification microservice → Firebase FCM) for incoming/missed calls when the app is in background/killed
- **Redis state** - Tracking active calls, participants, ringing timeouts (60s TTL), and busy status per user

```
Flutter App A                 Backend (Socket.IO)              Flutter App B
     |                              |                              |
     |-- POST /call/initiate ------>|                              |
     |<-- { room_id, call_id,      |--- socket: call:incoming --->|
     |     ice_servers, message }   |--- kafka -> notif svc ------>| (FCM push)
     |                              |                              |
     |                              |<-- POST /call/accept --------|
     |<-- socket: call:accepted ----|                              |
     |                              |--- socket: call:answered---->| (other devices)
     |                              |        -elsewhere            |
     |                              |                              |
     |-- socket: call:join-room --->|                              |
     |-- socket: call:offer ------->|--- socket: call:offer ------>|
     |                              |<-- socket: call:answer ------|
     |<-- socket: call:answer ------|                              |
     |                              |                              |
     |-- socket: call:ice-candidate -->  (relayed both ways)       |
     |<-- socket: call:ice-candidate --|                           |
     |                              |                              |
     |============ MEDIA FLOWING PEER-TO-PEER =====================|
     |                              |                              |
     |-- POST /call/end ----------->|--- socket: call:ended ------>|
```

**Key points:**
- Media (audio/video) goes directly between devices, NOT through the server
- Server only relays signaling messages (small JSON payloads)
- STUN/TURN servers help with NAT traversal (getting through firewalls)
- TURN credentials are time-limited and generated per-user (HMAC-based)
- Group calls use **full mesh** - each participant connects to every other participant directly (max ~6 participants)
- Redis tracks active calls with keys: `active_call:{roomId}` (1hr TTL), `call_participants:{roomId}` (1hr TTL), `user_active_call:{userId}` (1hr TTL), `call_ringing:{roomId}:{userId}` (60s TTL)
- All calls automatically create a message in the conversation timeline

---

## 2. Required Flutter Packages

```yaml
dependencies:
  # WebRTC - core peer-to-peer media
  flutter_webrtc: ^0.11.0

  # Socket.IO client for signaling
  socket_io_client: ^2.0.3+1

  # HTTP client for REST APIs
  dio: ^5.4.0

  # Firebase for push notifications
  firebase_messaging: ^15.0.0
  firebase_core: ^3.0.0

  # CallKit for native call UI (iOS)
  flutter_callkit_incoming: ^2.0.4

  # Foreground service for Android call
  flutter_foreground_task: ^6.1.3

  # Permissions
  permission_handler: ^11.3.0

  # Audio session management
  audio_session: ^0.1.21

  # Wakelock to keep screen on during call
  wakelock_plus: ^1.2.1
```

---

## 3. Data Models

### 3.1 Call Model

```dart
class CallModel {
  final String id;              // MongoDB _id
  final String conversationId;
  final String initiatedBy;     // user_id who started the call
  final String callType;        // "audio_call" or "video_call"
  final String status;          // "ringing", "connecting", "connected", "ended", "missed", "declined"
  final String? endReason;      // "completed", "missed", "declined", "failed", "busy"
  final String roomId;          // UUID - unique per call
  final String? messageId;
  final bool isGroupCall;
  final int maxParticipants;
  final bool screenSharingEnabled;
  final bool recordingEnabled;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final DateTime createdAt;

  // Parse from JSON response
  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['_id'] ?? json['call_id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      initiatedBy: json['initiated_by'] ?? '',
      callType: json['call_type'] ?? '',
      status: json['status'] ?? '',
      endReason: json['end_reason'],
      roomId: json['room_id'] ?? '',
      messageId: json['message_id'],
      isGroupCall: json['is_group_call'] ?? false,
      maxParticipants: json['max_participants'] ?? 2,
      screenSharingEnabled: json['screen_sharing_enabled'] ?? false,
      recordingEnabled: json['recording_enabled'] ?? false,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      durationSeconds: json['duration_seconds'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
```

### 3.2 Call Participant Model

```dart
class CallParticipant {
  final String id;
  final String callId;
  final String userId;
  final String role;        // "initiator", "receiver", "joiner"
  final String status;      // "ringing", "connecting", "connected", "left", "declined", "missed", "failed"
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final int durationSeconds;
  final bool isVideoEnabled;
  final bool isAudioEnabled;
  final bool isScreenSharing;

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      id: json['_id'] ?? '',
      callId: json['call_id'] ?? '',
      userId: json['user_id'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at']) : null,
      leftAt: json['left_at'] != null ? DateTime.parse(json['left_at']) : null,
      durationSeconds: json['duration_seconds'] ?? 0,
      isVideoEnabled: json['is_video_enabled'] ?? true,
      isAudioEnabled: json['is_audio_enabled'] ?? true,
      isScreenSharing: json['is_screen_sharing'] ?? false,
    );
  }
}
```

### 3.3 ICE Server Config Model

```dart
class IceServerConfig {
  final List<IceServer> iceServers;

  factory IceServerConfig.fromJson(Map<String, dynamic> json) {
    return IceServerConfig(
      iceServers: (json['iceServers'] as List)
          .map((s) => IceServer.fromJson(s))
          .toList(),
    );
  }

  /// Convert to flutter_webrtc format
  Map<String, dynamic> toWebRTCConfig() {
    return {
      'iceServers': iceServers.map((s) => s.toMap()).toList(),
    };
  }
}

class IceServer {
  final String urls;
  final String? username;
  final String? credential;

  factory IceServer.fromJson(Map<String, dynamic> json) {
    return IceServer(
      urls: json['urls'] ?? '',
      username: json['username'],
      credential: json['credential'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'urls': urls};
    if (username != null) map['username'] = username;
    if (credential != null) map['credential'] = credential;
    return map;
  }
}
```

### 3.4 Call State (Client-Side)

The frontend must track the current call state locally. The reference implementation uses these states:

```dart
enum CallState {
  idle,       // No active call
  ringing,    // Incoming call - showing incoming call UI
  accepting,  // User tapped accept - transitioning (prevents call:answered-elsewhere from resetting)
  outgoing,   // Outgoing call - waiting for receiver to accept
  active,     // Call connected - media flowing
}
```

**Client-side state variables:**

```dart
CallState callState = CallState.idle;
Map<String, dynamic>? currentCallData;  // { room_id, call_id, call_type, conversation_id, ... }
String? remoteUserId;                   // Target user for signaling relay
MediaStream? localStream;
RTCPeerConnection? peerConnection;
Timer? callTimerInterval;
DateTime? callStartTime;
bool isMicMuted = false;
bool isCameraOff = false;
bool isSpeakerOff = false;
```

---

## 4. REST API Endpoints

All endpoints require `Authorization: Bearer <jwt_token>` header and `Content-Type: application/json`.

Base URL: `{SERVER_URL}/call`

### 4.1 POST `/call/initiate` - Start a call

**Request body:**
```json
{
  "call_type": "audio_call",           // REQUIRED: "audio_call" or "video_call"
  "conversation_id": "64abc...",       // OPTIONAL: for existing conversations / group calls
  "other_user_id": "64def..."         // OPTIONAL: for 1-to-1 calls when no conversation exists
}
```

**Note:** You must provide either `conversation_id` OR `other_user_id`. For group calls, always use `conversation_id`.

**Success response (200):**
```json
{
  "success": true,
  "room_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "call_id": "64abc123...",
  "conversation_id": "64abc456...",
  "message_id": "64abc789...",
  "message": {
    "_id": "64abc789...",
    "conversation_id": "64abc456...",
    "sender_id": "user123",
    "message_type": "video_call",
    "message": "Calling...",
    "metadata": {
      "call_id": "64abc123...",
      "room_id": "a1b2c3d4-...",
      "other_user_id": "64def...",
      "call_status": "ringing"
    },
    "created_at": "2026-03-06T10:29:55.000Z"
  },
  "ice_servers": {
    "iceServers": [
      { "urls": "stun:stun.l.google.com:19302" },
      {
        "urls": "turn:turn.yourserver.com:3478",
        "username": "1709712000:user123",
        "credential": "base64encodedhmac"
      }
    ]
  },
  "busy_users": []
}
```

**The `busy_users` field** is an array of user_ids who are currently on another call. For 1-to-1 calls, if the receiver is busy the entire call fails with 409. For group calls, busy users are simply excluded from ringing but the call still proceeds for available members.

**Error responses:**
- `400` - Invalid `call_type` (must be "audio_call" or "video_call") or missing both `conversation_id` and `other_user_id`
  ```json
  { "success": false, "message": "call_type must be audio_call or video_call" }
  ```
- `409` - Caller already in a call, or receiver is busy (1-to-1)
  ```json
  { "success": false, "message": "User is on another call", "busy": true }
  ```
  ```json
  { "success": false, "message": "You are already in a call" }
  ```
- `404` - Conversation not found
  ```json
  { "success": false, "message": "Conversation not found" }
  ```
- `500` - Server error

**Side effects:**
- Creates a `Call` document (status: "ringing") and `CallParticipant` documents for all participants
- Creates a message in the conversation (message_type: "video_call" or "audio_call", message text: `"Calling..."`)
- Sets Redis keys: `active_call:{roomId}` (1hr TTL), `call_participants:{roomId}` (1hr TTL), `user_active_call:{userId}` (1hr TTL), `call_ringing:{roomId}:{userId}` (60s TTL)
- Emits `call:incoming` socket event to all receivers
- Publishes `incoming_call` notification via Kafka (`notification.service` topic) — the notification microservice constructs and sends the FCM push

---

### 4.2 POST `/call/accept` - Accept incoming call

**Request body:**
```json
{
  "call_id": "64abc123...",
  "room_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

**Success response (200):**
```json
{
  "success": true,
  "ice_servers": {
    "iceServers": [
      { "urls": "stun:stun.l.google.com:19302" },
      {
        "urls": "turn:turn.yourserver.com:3478",
        "username": "1709712000:user456",
        "credential": "base64encodedhmac"
      }
    ]
  },
  "call": {
    "_id": "64abc123...",
    "conversation_id": "64abc456...",
    "initiated_by": "user123",
    "call_type": "video_call",
    "status": "connecting",
    "room_id": "a1b2c3d4-...",
    "is_group_call": false,
    "max_participants": 2,
    "created_at": "2026-03-06T10:29:55.000Z"
  }
}
```

**Error responses:**
- `400` - Missing `call_id` or `room_id`
  ```json
  { "success": false, "message": "call_id and room_id are required" }
  ```
- `404` - Call not found or no longer ringing (already accepted/cancelled/declined)
  ```json
  { "success": false, "message": "Call not found or no longer ringing" }
  ```

**Side effects:**
- Updates `Call` status to "connecting" (atomic `findOneAndUpdate` to prevent race conditions)
- Updates acceptor's `CallParticipant` status to "connecting" with `joined_at` timestamp
- Sets `user_active_call:{userId}` in Redis
- Emits `call:accepted` to the call initiator: `{ call_id, room_id, accepted_by: userId }`
- Emits `call:answered-elsewhere` to the acceptor's OTHER devices/sockets: `{ call_id, room_id }`
- Updates message: text to `"Call connected"`, metadata: `call_accept: true`, `call_status: "connecting"`

**Important race condition note:** The backend uses atomic `findOneAndUpdate` with a status check (`status: "ringing"`) so that if two users try to accept simultaneously (e.g., multi-device), only the first succeeds. The second gets a 404. Handle this gracefully: dismiss the incoming call UI and show a toast like "Call already answered".

---

### 4.3 POST `/call/decline` - Decline incoming call

**Request body:**
```json
{
  "call_id": "64abc123...",
  "room_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

**Success response (200):**
```json
{
  "success": true,
  "message": "Call declined"
}
```

**Error responses:**
- `400` - Missing `call_id` or `room_id`
- `404` - Call not found or not in ringing state

**Side effects:**
- Updates decliner's `CallParticipant` status to "declined"
- For **1-to-1 calls**: Ends the entire call (status: "ended", end_reason: "declined")
- For **group calls**: Only ends the call if ALL receivers have declined
- Emits `call:declined` to the initiator:
  ```json
  { "call_id": "...", "room_id": "...", "declined_by": "userId", "call_ended": true }
  ```
  - `call_ended` is `true` for 1-to-1 calls, or `true` for group calls only when all receivers declined
- Cleans up Redis ringing key for the decliner
- Updates message: text to `"Call declined"`, metadata: `call_decline: true`, `call_status: "declined"`

---

### 4.4 POST `/call/cancel` - Cancel outgoing call (before anyone answers)

**Only the call initiator can cancel.** The backend verifies `call.initiated_by === user_id`.

**Request body:**
```json
{
  "call_id": "64abc123...",
  "room_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

**Success response (200):**
```json
{
  "success": true,
  "message": "Call cancelled"
}
```

**Error responses:**
- `400` - Missing `call_id` or `room_id`
- `404` - Call not found, not cancellable (someone already accepted), or user is not the initiator

**Side effects:**
- Updates `Call` status to "ended", end_reason to "missed"
- Updates all "ringing" participants to status "missed"
- Emits `call:cancelled` to all receivers: `{ call_id, room_id, cancelled_by: userId }`
- Publishes `missed_call` notification via Kafka (`notification.service` topic) — the notification microservice constructs and sends the FCM push
- Cleans up all Redis keys for this call
- Updates message: text to `"Missed call"`, metadata: `missed_call: true`, `call_status: "missed"`

---

### 4.5 POST `/call/end` - End active call or leave group call

**Request body:**
```json
{
  "call_id": "64abc123...",
  "room_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

**Success response (200):**
```json
{
  "success": true,
  "message": "Call ended"
}
```

**Side effects:**
- Updates the caller's `CallParticipant` status to "left" with `left_at` and `duration_seconds`
- Removes user from Redis `call_participants:{roomId}` and deletes `user_active_call:{userId}`
- **For 1-to-1 calls or when < 2 participants remain:**
  - Ends the entire call (status: "ended", end_reason: "completed")
  - Calculates and stores `duration_seconds` on the Call document
  - Emits `call:ended` to all remaining participants:
    ```json
    { "call_id": "...", "room_id": "...", "duration_seconds": 125, "ended_by": "userId" }
    ```
  - Updates message: text to `"Call ended - MM:SS"` (or `"Call ended - HH:MM:SS"` for calls >= 1 hour), metadata: `call_status: "completed"`, `call_time: "MM:SS"` (or `"HH:MM:SS"`)
- **For group calls with 2+ participants remaining:**
  - Emits `call:participant-left` to remaining participants:
    ```json
    { "call_id": "...", "room_id": "...", "user_id": "userId" }
    ```
  - The call continues for remaining participants

---

### 4.6 POST `/call/join` - Join an ongoing group call

**Request body:**
```json
{
  "call_id": "64abc123...",
  "room_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

**Success response (200):**
```json
{
  "success": true,
  "ice_servers": {
    "iceServers": [
      { "urls": "stun:stun.l.google.com:19302" },
      {
        "urls": "turn:turn.yourserver.com:3478",
        "username": "1709712000:user789",
        "credential": "base64encodedhmac"
      }
    ]
  },
  "existing_participants": ["user123", "user456"],
  "call": {
    "_id": "64abc...",
    "conversation_id": "64def...",
    "call_type": "video_call",
    "status": "connected",
    "room_id": "uuid...",
    "is_group_call": true,
    "max_participants": 10,
    "created_at": "2026-03-06T10:29:55.000Z"
  }
}
```

**Error responses:**
- `403` - Not a member of this conversation
  ```json
  { "success": false, "message": "Not a member of this conversation" }
  ```
- `404` - Group call not found or already ended
  ```json
  { "success": false, "message": "Group call not found or already ended" }
  ```
- `409` - Already in another call
  ```json
  { "success": false, "message": "You are already in a call" }
  ```

**Side effects:**
- Creates or updates `CallParticipant` (role: "joiner", status: "connecting")
- Adds user to Redis `call_participants:{roomId}` and sets `user_active_call:{userId}`
- Emits `call:participant-joined` to all existing participants in the room:
  ```json
  { "call_id": "...", "room_id": "...", "user_id": "newUserId", "existing_participants": ["user123", "user456"] }
  ```

---

### 4.7 POST `/call/add-user` - Add user(s) to an active call

Add one or more users to an ongoing call. Any active participant can add users. 1-to-1 calls are automatically upgraded to group calls.

**Request body:**
```json
{
  "call_id": "64abc123...",
  "room_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "user_ids": ["64user1...", "64user2..."]
}
```

**Success response (200):**
```json
{
  "success": true,
  "message": "2 user(s) added to call",
  "added_users": ["64user1...", "64user2..."],
  "busy_users": [],
  "already_in_call": []
}
```

**Response when no new users could be added (200):**
```json
{
  "success": true,
  "message": "No new users added",
  "busy_users": ["64user1..."],
  "already_in_call": ["64user2..."]
}
```

**Error responses:**
- `400` - Missing or invalid parameters
  ```json
  { "success": false, "message": "call_id, room_id, and user_ids[] required" }
  ```
- `403` - Requester is not an active participant
  ```json
  { "success": false, "message": "You are not an active participant in this call" }
  ```
- `404` - Call not found or already ended
  ```json
  { "success": false, "message": "Call not found or already ended" }
  ```

**Side effects:**
- Automatically upgrades the call to `is_group_call: true` if it was a 1-to-1 call
- Creates `CallParticipant` records (role: "receiver", status: "ringing") for each added user
- Sets ringing state in Redis for each added user
- Emits `call:incoming` socket event to each added user (same payload as a normal incoming call, with `added_by` field)
- Sends push notification (`incoming_call` operation) to added users
- Emits `call:user-added` to all existing participants:
  ```json
  { "call_id": "...", "room_id": "...", "added_users": ["64user1..."], "added_by": "requester_id" }
  ```

**Usage in Flutter:**

```dart
// Add users to an active call
final response = await dio.post('/call/add-user', data: {
  'call_id': currentCallData['call_id'],
  'room_id': currentCallData['room_id'],
  'user_ids': ['userId1', 'userId2'],
});

if (response.data['success']) {
  final addedUsers = List<String>.from(response.data['added_users'] ?? []);
  final busyUsers = List<String>.from(response.data['busy_users'] ?? []);

  // Upgrade local state to group call
  isGroupCall = true;

  if (busyUsers.isNotEmpty) {
    // Show toast: "Some users are on another call"
  }

  // Added users will receive call:incoming and join via the normal accept flow
  // When they accept, you'll get call:accepted / call:participant-joined events
}
```

---

### 4.8 GET `/call/history` - Get call history

**Query parameters:**
- `conversation_id` (optional) - Filter by conversation
- `page` (optional, default: 1)
- `limit` (optional, default: 20)

**Success response (200):**
```json
{
  "success": true,
  "calls": [
    {
      "_id": "64abc...",
      "conversation_id": "64def...",
      "initiated_by": "user123",
      "call_type": "video_call",
      "status": "ended",
      "end_reason": "completed",
      "room_id": "uuid...",
      "is_group_call": false,
      "max_participants": 2,
      "screen_sharing_enabled": false,
      "recording_enabled": false,
      "duration_seconds": 125,
      "started_at": "2026-03-06T10:30:00.000Z",
      "ended_at": "2026-03-06T10:32:05.000Z",
      "created_at": "2026-03-06T10:29:55.000Z",
      "participants": [
        {
          "_id": "64part1...",
          "call_id": "64abc...",
          "user_id": "user123",
          "role": "initiator",
          "status": "left",
          "joined_at": "2026-03-06T10:29:55.000Z",
          "left_at": "2026-03-06T10:32:05.000Z",
          "duration_seconds": 125,
          "is_video_enabled": true,
          "is_audio_enabled": true,
          "is_screen_sharing": false
        },
        {
          "_id": "64part2...",
          "call_id": "64abc...",
          "user_id": "user456",
          "role": "receiver",
          "status": "left",
          "joined_at": "2026-03-06T10:30:00.000Z",
          "left_at": "2026-03-06T10:32:05.000Z",
          "duration_seconds": 125,
          "is_video_enabled": true,
          "is_audio_enabled": true,
          "is_screen_sharing": false
        }
      ]
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "pages": 3
  }
}
```

---

### 4.9 POST `/call/switch-type` - Switch call type (audio ↔ video)

Request to switch an active call between audio and video. **Video → audio** switches immediately (no approval needed). **Audio → video** sends a request to other participants who must accept (since it requires camera permission).

**Request body:**
```json
{
  "call_id": "64abc123...",
  "room_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "new_call_type": "video_call"
}
```

**Success response — immediate switch (video → audio) (200):**
```json
{
  "success": true,
  "message": "Call switched to audio",
  "new_call_type": "audio_call"
}
```

**Success response — pending approval (audio → video) (200):**
```json
{
  "success": true,
  "message": "Switch request sent to participants",
  "new_call_type": "video_call",
  "pending_approval": true
}
```

**Error responses:**
- `400` - Invalid parameters or call is already the requested type
  ```json
  { "success": false, "message": "Call is already a video call" }
  ```
- `403` - Not an active participant
- `404` - Call not found or not active

**Side effects:**
- **Video → audio**: Updates `call_type` and `message_type` immediately. Emits `call:type-switched` to all participants.
- **Audio → video**: Emits `call:switch-type-request` to other participants. No DB changes until someone accepts.

---

### 4.10 POST `/call/switch-type/respond` - Respond to switch request

Accept or decline a request to switch from audio to video call.

**Request body:**
```json
{
  "call_id": "64abc123...",
  "room_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "accepted": true
}
```

**Success response — accepted (200):**
```json
{
  "success": true,
  "message": "Call switched to video",
  "new_call_type": "video_call"
}
```

**Success response — declined (200):**
```json
{
  "success": true,
  "message": "Switch to video declined"
}
```

**Side effects:**
- **Accepted**: Updates `call_type` to `video_call` and `message_type`. Emits `call:type-switched` to all participants.
- **Declined**: Emits `call:switch-type-declined` to other participants.

---

### 4.11 GET `/call/active` - Check if user has an active call

**Success response (200):**
```json
{
  "success": true,
  "active_call": {
    "call_id": "64abc...",
    "conversation_id": "64def...",
    "initiated_by": "user123",
    "call_type": "video_call",
    "status": "connected",
    "is_group_call": false,
    "room_id": "uuid...",
    "participants": ["user123", "user456"]
  }
}
```

Returns `"active_call": null` when no active call exists:
```json
{
  "success": true,
  "active_call": null
}
```

---

### 4.12 GET `/call/ice-servers` - Get STUN/TURN config

**Success response (200):**
```json
{
  "success": true,
  "iceServers": [
    { "urls": "stun:stun.l.google.com:19302" },
    {
      "urls": "turn:turn.yourserver.com:3478",
      "username": "1709712000:user123",
      "credential": "base64encodedhmac"
    }
  ]
}
```

**Note:** TURN credentials are time-limited (HMAC-based, generated per user). They expire after a set period. The ICE servers are also returned in the `/call/initiate`, `/call/accept`, and `/call/join` responses, so you typically don't need to call this endpoint separately unless reconnecting.

---

## 5. Socket.IO Events Reference

Socket connection path: `/socket`

Authentication: `io(serverUrl, { path: '/socket', auth: { token: jwtToken } })`. The handshake also accepts optional `capabilities` (for E2E encryption protocol detection) and `deviceId` fields, though these are not required for call functionality.

### 5.1 Events the CLIENT LISTENS TO (server -> client)

| Event | Payload | When |
|-------|---------|------|
| `call:incoming` | `{ call_id, room_id, conversation_id, call_type, initiated_by, is_group_call, message }` | Someone is calling you |
| `call:accepted` | `{ call_id, room_id, accepted_by }` | Receiver accepted your call |
| `call:declined` | `{ call_id, room_id, declined_by, call_ended }` | Receiver declined your call. `call_ended` is `true` for 1-to-1 or when all group receivers declined |
| `call:cancelled` | `{ call_id, room_id, cancelled_by }` | Caller cancelled before you answered |
| `call:ended` | `{ call_id, room_id, duration_seconds, ended_by, reason? }` | Call has ended (either explicitly via REST or because < 2 participants remain). `reason` values: `"participant_left"` (from socket `call:leave-room` auto-end), `"disconnect"` (from socket disconnect handler). Absent when ended via REST `/call/end` |
| `call:answered-elsewhere` | `{ call_id, room_id }` | You answered on another device, dismiss ringing on this device |
| `call:participant-joined` | `{ call_id, room_id, user_id, existing_participants }` | New participant joined group call. `existing_participants` is an array of user_ids already in the call |
| `call:participant-left` | `{ call_id, room_id, user_id, reason? }` | Participant left group call (but call continues). `reason` is `"disconnect"` when triggered by socket disconnect; absent when leaving via REST `/call/end` |
| `call:offer` | `{ room_id, from_user_id, sdp }` | Incoming WebRTC SDP offer. `sdp` is the full RTCSessionDescription object |
| `call:answer` | `{ room_id, from_user_id, sdp }` | Incoming WebRTC SDP answer. `sdp` is the full RTCSessionDescription object |
| `call:ice-candidate` | `{ room_id, from_user_id, candidate }` | Incoming ICE candidate. `candidate` is the full RTCIceCandidate object |
| `call:media-toggle` | `{ user_id, is_video_enabled, is_audio_enabled }` | Remote user toggled camera/mic. Server also persists the toggle state to the `CallParticipant` DB record (background, non-blocking) |
| `call:screen-share-start` | `{ user_id }` | Remote user started screen sharing |
| `call:screen-share-stop` | `{ user_id }` | Remote user stopped screen sharing |
| `call:user-added` | `{ call_id, room_id, added_users, added_by }` | New user(s) were added to the call by a participant. `added_users` is an array of user_ids. Added users receive `call:incoming` separately |
| `call:switch-type-request` | `{ call_id, room_id, new_call_type, requested_by }` | A participant requests to switch from audio to video. Show accept/decline UI |
| `call:type-switched` | `{ call_id, room_id, new_call_type, switched_by }` | Call type was switched. Update UI, enable/disable camera accordingly |
| `call:switch-type-declined` | `{ call_id, room_id, declined_by }` | Switch to video request was declined by a participant |
| `call:user-joined` | `{ user_id }` | User joined the Socket.IO call room (broadcast when `call:join-room` is emitted) |
| `call:user-left` | `{ user_id }` | User left the Socket.IO call room (broadcast when `call:leave-room` is emitted) |

### 5.2 Events the CLIENT EMITS (client -> server)

| Event | Payload | When |
|-------|---------|------|
| `call:offer` | `{ room_id, target_user_id, sdp }` | Sending SDP offer to a specific user. Server relays as `{ room_id, from_user_id, sdp }` |
| `call:answer` | `{ room_id, target_user_id, sdp }` | Sending SDP answer to a specific user. Server relays as `{ room_id, from_user_id, sdp }` |
| `call:ice-candidate` | `{ room_id, target_user_id, candidate }` | Sending ICE candidate to a specific user. Server relays as `{ room_id, from_user_id, candidate }` |
| `call:join-room` | `{ room_id }` | Join the Socket.IO room for this call. Server broadcasts `call:user-joined` to room |
| `call:leave-room` | `{ room_id, call_id }` | Leave the Socket.IO room. **Both fields are required.** Server broadcasts `call:user-left` to room. If < 2 participants remain, server auto-emits `call:ended` with `reason: "participant_left"` to the room |
| `call:media-toggle` | `{ room_id, is_video_enabled, is_audio_enabled }` | Notify others of camera/mic toggle. Server broadcasts with `user_id` added |
| `call:screen-share-start` | `{ room_id }` | Notify others of screen share start. Server broadcasts with `user_id` added |
| `call:screen-share-stop` | `{ room_id }` | Notify others of screen share stop. Server broadcasts with `user_id` added |

---

## 6. Call Flow: 1-to-1 Audio/Video Call

### Step 1: Caller initiates call

```dart
// 1. Request camera/mic permissions
await [Permission.camera, Permission.microphone].request();

// 2. Get local media stream FIRST (so user sees their preview)
final localStream = await navigator.mediaDevices.getUserMedia({
  'audio': true,
  'video': callType == 'video_call',
});

// Show local video preview if video call
if (callType == 'video_call') {
  localVideoRenderer.srcObject = localStream;
}

// 3. Call the API
final response = await dio.post('/call/initiate', data: {
  'call_type': 'video_call',       // or 'audio_call'
  'conversation_id': conversationId,  // preferred for existing conversations
  // OR 'other_user_id': otherUserId,  // for new 1-to-1 calls
});

if (!response.data['success']) {
  // Stop media on failure
  localStream.getTracks().forEach((track) => track.stop());
  // Show error: response.data['message']
  return;
}

final roomId = response.data['room_id'];
final callId = response.data['call_id'];
final conversationId = response.data['conversation_id'];
final messageId = response.data['message_id'];
final iceServers = response.data['ice_servers']['iceServers'];

// Check for busy users (group calls)
final busyUsers = response.data['busy_users'] ?? [];

// 4. Store call data locally
currentCallData = {
  'room_id': roomId,
  'call_id': callId,
  'conversation_id': conversationId,
  'call_type': callType,
  'message_id': messageId,
};

// 5. Navigate to OutgoingCallScreen
// Show ringing UI with contact info, play ringing sound
callState = CallState.outgoing;

// 6. Join the Socket.IO call room
socket.emit('call:join-room', { 'room_id': roomId });

// 7. Create RTCPeerConnection with ICE servers from response
final peerConnection = await createPeerConnection({
  'iceServers': iceServers.isNotEmpty
    ? iceServers
    : [{ 'urls': 'stun:stun.l.google.com:19302' }],
});

// 8. Add local tracks to peer connection
localStream.getTracks().forEach((track) {
  peerConnection.addTrack(track, localStream);
});

// 9. Create and send SDP offer immediately
// (The receiver may not be ready yet, but the offer will be relayed when they join)
final offer = await peerConnection.createOffer();
await peerConnection.setLocalDescription(offer);

socket.emit('call:offer', {
  'room_id': roomId,
  'target_user_id': remoteUserId,
  'sdp': offer,  // Send the full RTCSessionDescription object
});
```

### Step 2: Receiver gets incoming call

```dart
// Listen for the call:incoming socket event
socket.on('call:incoming', (data) {
  // Ignore if already in a call
  if (callState != CallState.idle) return;

  final callId = data['call_id'];
  final roomId = data['room_id'];
  final callType = data['call_type'];          // "audio_call" or "video_call"
  final initiatedBy = data['initiated_by'];     // caller's user_id
  final isGroupCall = data['is_group_call'];    // boolean
  final conversationId = data['conversation_id'];
  final message = data['message'];              // full message object

  // Resolve caller info from your local conversation list
  // Store as currentCallData for use when accepting/declining

  callState = CallState.ringing;

  // Show IncomingCallScreen with Accept/Decline buttons
  // Play ringtone, vibrate
  // If app is in background, this comes via Firebase push (see Section 10)
});
```

### Step 3: Receiver accepts

```dart
// IMPORTANT: Copy currentCallData to local vars before async work,
// because call:answered-elsewhere may null it mid-flight
final callData = {...currentCallData};
final pendingOffer = callData['pendingOffer'];  // May have been stored from early call:offer

// Immediately transition to 'accepting' state so call:answered-elsewhere
// won't reset our state while we're in the middle of accepting
callState = CallState.accepting;

// 1. Get local media
final localStream = await navigator.mediaDevices.getUserMedia({
  'audio': true,
  'video': callData['call_type'] == 'video_call',
});

// 2. Call the API
final response = await dio.post('/call/accept', data: {
  'call_id': callData['call_id'],
  'room_id': callData['room_id'],
});

if (!response.data['success']) {
  // Accept failed (likely race condition - call already answered elsewhere)
  localStream.getTracks().forEach((track) => track.stop());
  resetCallState();
  // Show toast: "Call already answered" or response.data['message']
  return;
}

final iceServers = response.data['ice_servers']['iceServers'];

// 3. Navigate to ActiveCallScreen
// Stop ringtone

// 4. Join the Socket.IO call room
socket.emit('call:join-room', { 'room_id': callData['room_id'] });

// 5. Create RTCPeerConnection with ICE servers from accept response
final peerConnection = await createPeerConnection({
  'iceServers': iceServers.isNotEmpty
    ? iceServers
    : [{ 'urls': 'stun:stun.l.google.com:19302' }],
});

// 6. Add local tracks
localStream.getTracks().forEach((track) {
  peerConnection.addTrack(track, localStream);
});

// 7. If we already received an SDP offer while ringing, process it now
if (pendingOffer != null) {
  await peerConnection.setRemoteDescription(
    RTCSessionDescription(pendingOffer['sdp'], pendingOffer['type']),
  );
  final answer = await peerConnection.createAnswer();
  await peerConnection.setLocalDescription(answer);
  socket.emit('call:answer', {
    'room_id': callData['room_id'],
    'target_user_id': callData['initiated_by'],  // caller
    'sdp': answer,
  });
}

callState = CallState.active;
```

### Step 4: Caller receives accepted event

```dart
// The CALLER listens for call:accepted
socket.on('call:accepted', (data) async {
  if (callState != CallState.outgoing || currentCallData == null) return;

  // Set remote user if not already set
  remoteUserId ??= data['accepted_by'];

  // Stop ringing sound
  // Navigate to ActiveCallScreen
  callState = CallState.active;

  // If peer connection already has a local description (offer was created),
  // re-send it to make sure the receiver gets it
  if (peerConnection != null && peerConnection.localDescription != null) {
    socket.emit('call:offer', {
      'room_id': currentCallData['room_id'],
      'target_user_id': data['accepted_by'],
      'sdp': peerConnection.localDescription,
    });
  }
});
```

### Step 5: Receiver handles SDP offer and sends answer

```dart
// Handle incoming SDP offers
socket.on('call:offer', (data) async {
  if (callState == CallState.ringing && currentCallData != null) {
    // Store offer for when user actually accepts
    currentCallData['pendingOffer'] = data['sdp'];
    return;
  }

  if (callState == CallState.active && peerConnection != null) {
    // Already in call - handle renegotiation or initial offer after accept
    await peerConnection.setRemoteDescription(
      RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']),
    );
    final answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);
    socket.emit('call:answer', {
      'room_id': data['room_id'],
      'target_user_id': data['from_user_id'],
      'sdp': answer,
    });
  }
});
```

### Step 6: Caller handles SDP answer

```dart
socket.on('call:answer', (data) async {
  // Only set remote description if we're in 'have-local-offer' state
  if (peerConnection != null &&
      peerConnection.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
    await peerConnection.setRemoteDescription(
      RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']),
    );
    // WebRTC will now start ICE negotiation automatically
  }
});
```

### Step 7: Exchange ICE candidates (BOTH sides)

```dart
// Send local ICE candidates to the other peer
peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
  if (remoteUserId != null && currentCallData != null) {
    socket.emit('call:ice-candidate', {
      'room_id': currentCallData['room_id'],
      'target_user_id': remoteUserId,
      'candidate': candidate,  // Send the full RTCIceCandidate object
    });
  }
};

// Receive remote ICE candidates
socket.on('call:ice-candidate', (data) async {
  if (peerConnection != null && data['candidate'] != null) {
    try {
      await peerConnection.addCandidate(
        RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        ),
      );
    } catch (err) {
      print('ICE candidate error: $err');
    }
  }
});
```

### Step 8: Media starts flowing

```dart
// Listen for remote stream
peerConnection.onTrack = (RTCTrackEvent event) {
  if (event.streams.isNotEmpty) {
    // Set the remote stream to a RTCVideoRenderer
    remoteRenderer.srcObject = event.streams[0];
    // Hide the "no video" placeholder for video calls
    if (currentCallData?['call_type'] == 'video_call') {
      // Show remote video, hide avatar placeholder
    }
  }
};

// ICE connection state changes
peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
  switch (state) {
    case RTCIceConnectionState.RTCIceConnectionStateConnected:
    case RTCIceConnectionState.RTCIceConnectionStateCompleted:
      // Call is live! Start call timer
      break;
    case RTCIceConnectionState.RTCIceConnectionStateFailed:
    case RTCIceConnectionState.RTCIceConnectionStateClosed:
      // ICE failed - end the call
      if (callState == CallState.active) {
        endCurrentCall();
      }
      break;
    case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
      // Temporary disconnection - show "Reconnecting..." UI
      // May recover on its own
      break;
    default:
      break;
  }
};
```

### Step 9: End call

```dart
// When user taps hang up button
Future<void> endCurrentCall() async {
  if (currentCallData == null) return;

  // 1. Call the API
  try {
    await dio.post('/call/end', data: {
      'call_id': currentCallData['call_id'],
      'room_id': currentCallData['room_id'],
    });
  } catch (err) {
    print('End call error: $err');
  }

  // 2. Leave socket room
  socket.emit('call:leave-room', {
    'room_id': currentCallData['room_id'],
    'call_id': currentCallData['call_id'],
  });

  // 3. Cleanup
  resetCallState();  // closes peer connection, stops local stream, resets UI
}

// Also listen for the other person ending
socket.on('call:ended', (data) {
  // Clean up and navigate back to chat
  resetCallState();
  // Optionally refresh chat list to update call message bubble
});
```

### Complete resetCallState function

```dart
void resetCallState() {
  callState = CallState.idle;
  currentCallData = null;
  remoteUserId = null;
  isMicMuted = false;
  isCameraOff = false;
  isSpeakerOff = false;

  // Stop call timer
  callTimerInterval?.cancel();
  callTimerInterval = null;
  callStartTime = null;

  // Close all overlays/screens
  // Hide incoming, outgoing, and active call UIs

  // Cleanup WebRTC
  if (localStream != null) {
    localStream!.getTracks().forEach((track) => track.stop());
    localStream = null;
  }
  if (peerConnection != null) {
    peerConnection!.close();
    peerConnection = null;
  }

  // Clear video renderers
  localVideoRenderer.srcObject = null;
  remoteVideoRenderer.srcObject = null;
}
```

---

## 7. Call Flow: Group Call

Group calls use **full mesh topology** - each participant creates a separate RTCPeerConnection with every other participant.

### 7.1 Initiating a group call

Same as 1-to-1 but with `conversation_id` of a group conversation:

```dart
final response = await dio.post('/call/initiate', data: {
  'call_type': 'video_call',
  'conversation_id': groupConversationId,
});

// Response includes busy_users array - users already on another call
final busyUsers = List<String>.from(response.data['busy_users'] ?? []);
// These users won't receive the call:incoming event
// The call still proceeds for all non-busy members
```

### 7.2 Data structure for managing multiple peer connections

```dart
class GroupCallManager {
  final Map<String, RTCPeerConnection> peerConnections = {};  // keyed by user_id
  final Map<String, MediaStream> remoteStreams = {};           // keyed by user_id
  MediaStream? localStream;
  IceServerConfig? iceConfig;
  String? roomId;
  String? callId;
}
```

### 7.3 When a new participant joins

```dart
socket.on('call:participant-joined', (data) async {
  final newUserId = data['user_id'];

  // Create a NEW peer connection for this participant
  final pc = await createPeerConnection(iceConfig!.toWebRTCConfig());

  // Add local tracks to this new connection
  localStream!.getTracks().forEach((track) {
    pc.addTrack(track, localStream!);
  });

  // Listen for remote tracks
  pc.onTrack = (event) {
    if (event.streams.isNotEmpty) {
      remoteStreams[newUserId] = event.streams[0];
      // Update UI to show new participant video
    }
  };

  // Handle ICE candidates for this specific peer
  pc.onIceCandidate = (candidate) {
    socket.emit('call:ice-candidate', {
      'room_id': roomId,
      'target_user_id': newUserId,
      'candidate': candidate,
    });
  };

  peerConnections[newUserId] = pc;

  // The EXISTING participant creates the offer for the NEW participant
  final offer = await pc.createOffer();
  await pc.setLocalDescription(offer);

  socket.emit('call:offer', {
    'room_id': roomId,
    'target_user_id': newUserId,
    'sdp': offer,
  });
});
```

### 7.4 Joining an existing group call

```dart
// 1. Call the join API
final response = await dio.post('/call/join', data: {
  'call_id': callId,
  'room_id': roomId,
});

final iceConfig = IceServerConfig.fromJson(response.data['ice_servers']);
final existingParticipants = List<String>.from(response.data['existing_participants']);

// 2. Join socket room
socket.emit('call:join-room', { 'room_id': roomId });

// 3. Get local media
localStream = await navigator.mediaDevices.getUserMedia({...});

// 4. Wait for existing participants to send you offers
// (They will create offers when they receive call:participant-joined)
// Handle each offer as in Step 5 of the 1-to-1 flow
```

### 7.5 When a participant leaves

```dart
socket.on('call:participant-left', (data) {
  final leftUserId = data['user_id'];

  // Close and remove the peer connection for this user
  peerConnections[leftUserId]?.close();
  peerConnections.remove(leftUserId);
  remoteStreams.remove(leftUserId);

  // Update UI to remove their video tile
});
```

### 7.6 Adding users to an active call

Any participant in an active call can add other users. This works for both 1-to-1 and group calls. A 1-to-1 call is automatically upgraded to a group call when a user is added.

```dart
// Show a contact picker UI, then call the API
Future<void> addUsersToCall(List<String> userIdsToAdd) async {
  if (currentCallData == null) return;

  final response = await dio.post('/call/add-user', data: {
    'call_id': currentCallData['call_id'],
    'room_id': currentCallData['room_id'],
    'user_ids': userIdsToAdd,
  });

  if (response.data['success']) {
    // Upgrade local state to group call
    isGroupCall = true;

    final added = List<String>.from(response.data['added_users'] ?? []);
    final busy = List<String>.from(response.data['busy_users'] ?? []);

    if (busy.isNotEmpty) {
      showToast('${busy.length} user(s) are on another call');
    }
    if (added.isNotEmpty) {
      showToast('${added.length} user(s) added to call');
    }

    // Added users will receive call:incoming and join via the normal accept flow.
    // When they accept, you'll get call:participant-joined events,
    // and peer connections are created in the normal group call handler.
  } else {
    showToast(response.data['message'] ?? 'Failed to add users');
  }
}

// Listen for the call:user-added event (informational for existing participants)
socket.on('call:user-added', (data) {
  final addedUsers = List<String>.from(data['added_users'] ?? []);
  final addedBy = data['added_by'];
  // Optionally show toast: "User X added Y to the call"
  // The actual peer connections are created when added users accept (call:participant-joined)
});
```

**Important notes:**
- When a 1-to-1 call is upgraded, both existing participants must switch to the group call peer connection model (multiple `RTCPeerConnection` instances instead of one)
- The added users go through the standard `call:incoming` → `accept` → `call:accepted` / `call:participant-joined` flow
- The `call:user-added` event is purely informational for existing participants; no action is required

### 7.7 Switching call type (audio ↔ video)

Any active participant can request to switch the call between audio and video.

- **Video → audio**: Switches immediately. All participants receive `call:type-switched` and should disable their cameras.
- **Audio → video**: Requires approval from other participants (camera permission needed). The requester calls `POST /call/switch-type`, other participants see a prompt, and one of them responds via `POST /call/switch-type/respond`.

```dart
// ── Requesting a switch ──

Future<void> switchCallType() async {
  final currentType = currentCallData?['call_type'];
  final newType = currentType == 'audio_call' ? 'video_call' : 'audio_call';

  final response = await dio.post('/call/switch-type', data: {
    'call_id': currentCallData['call_id'],
    'room_id': currentCallData['room_id'],
    'new_call_type': newType,
  });

  if (response.data['success']) {
    if (response.data['pending_approval'] == true) {
      // Audio → video: waiting for other participants to accept
      showToast('Waiting for approval to switch to video...');
    }
    // Video → audio: call:type-switched will fire immediately
  } else {
    showToast(response.data['message'] ?? 'Failed to switch');
  }
}

// ── Receiving a switch request (audio → video) ──

socket.on('call:switch-type-request', (data) {
  // Show a dialog: "User wants to switch to video call"
  // with Accept / Decline buttons
  showSwitchTypeDialog(
    onAccept: () async {
      // Request camera permission first
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        // Decline if no permission
        await dio.post('/call/switch-type/respond', data: {
          'call_id': data['call_id'],
          'room_id': data['room_id'],
          'accepted': false,
        });
        return;
      }

      await dio.post('/call/switch-type/respond', data: {
        'call_id': data['call_id'],
        'room_id': data['room_id'],
        'accepted': true,
      });
    },
    onDecline: () async {
      await dio.post('/call/switch-type/respond', data: {
        'call_id': data['call_id'],
        'room_id': data['room_id'],
        'accepted': false,
      });
    },
  );
});

// ── Handling the actual switch ──

socket.on('call:type-switched', (data) {
  final newType = data['new_call_type'];
  final isVideo = newType == 'video_call';

  // Update local state
  currentCallData['call_type'] = newType;

  // Update UI label
  // Update call screen to show/hide video elements

  if (isVideo) {
    // Enable camera - get video track if not already available
    enableLocalVideo();
  } else {
    // Disable camera
    localStream?.getVideoTracks().forEach((track) => track.enabled = false);
    isCameraOff = true;
  }
});

// ── Switch declined ──

socket.on('call:switch-type-declined', (data) {
  showToast('Switch to video was declined');
});
```

**Important notes:**
- Only one switch request should be active at a time per call
- When switching to video, all participants need camera permission — if someone can't grant it, they should decline
- The switch button UI should show the opposite type (audio call shows video icon, video call shows phone icon)
- For group calls, the first participant to respond determines the outcome

---

## 8. WebRTC Implementation

### 8.1 Creating RTCPeerConnection

```dart
Future<RTCPeerConnection> createPeerConnection(Map<String, dynamic> iceConfig) async {
  final config = {
    'iceServers': iceConfig['iceServers']?.isNotEmpty == true
        ? iceConfig['iceServers']
        : [{ 'urls': 'stun:stun.l.google.com:19302' }],
  };

  final pc = await createPeerConnection(config, {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
  });

  return pc;
}
```

### 8.2 Toggling Camera/Microphone

```dart
// Toggle microphone
void toggleMic() {
  if (localStream == null) return;
  isMicMuted = !isMicMuted;
  localStream!.getAudioTracks().forEach((track) {
    track.enabled = !isMicMuted;
  });

  // Notify other participants via socket
  if (socket != null && currentCallData != null) {
    socket.emit('call:media-toggle', {
      'room_id': currentCallData['room_id'],
      'is_audio_enabled': !isMicMuted,
      // Note: only send the field that changed, or send both
    });
  }
}

// Toggle camera
void toggleCamera() {
  if (localStream == null) return;
  isCameraOff = !isCameraOff;
  localStream!.getVideoTracks().forEach((track) {
    track.enabled = !isCameraOff;
  });

  // Hide/show local video PiP
  // Update UI to reflect camera state

  if (socket != null && currentCallData != null) {
    socket.emit('call:media-toggle', {
      'room_id': currentCallData['room_id'],
      'is_video_enabled': !isCameraOff,
    });
  }
}

// Switch front/back camera
void switchCamera() {
  final videoTrack = localStream?.getVideoTracks().first;
  if (videoTrack != null) {
    Helper.switchCamera(videoTrack);
  }
}

// Listen for remote media toggles
socket.on('call:media-toggle', (data) {
  final userId = data['user_id'];
  final isVideoEnabled = data['is_video_enabled'];
  final isAudioEnabled = data['is_audio_enabled'];
  // Update UI: show avatar if video off, show mute icon if audio off
  // For 1-to-1: toggle the remote-no-video placeholder visibility
  if (isVideoEnabled != null) {
    // Show/hide remote video placeholder based on isVideoEnabled
  }
});
```

### 8.3 Speaker/Earpiece Toggle

```dart
// Toggle between speaker and earpiece
// In the web tester, this simply mutes/unmutes the remote video element
// In Flutter, use the audio_session package or flutter_webrtc helper
void toggleSpeaker() {
  isSpeakerOff = !isSpeakerOff;

  // For flutter_webrtc:
  final audioTrack = localStream?.getAudioTracks().first;
  if (audioTrack != null) {
    audioTrack.enableSpeakerphone(!isSpeakerOff);
  }
}
```

---

## 9. UI Screens Required

### 9.1 Outgoing Call Screen
- Shows when YOU initiate a call (callState = `outgoing`)
- Displays: other user's avatar, name, "Calling..." text, call type icon (phone or video)
- Buttons: Cancel/Hang up (red, calls POST `/call/cancel`)
- Auto-cancel after 60 seconds if no answer (backend also has 60s Redis TTL on ringing state)
- Plays ringing tone
- Transitions to Active Call Screen when `call:accepted` socket event is received
- Transitions back when `call:declined` is received (show "Call declined" briefly)

### 9.2 Incoming Call Screen
- Shows when YOU receive a call via `call:incoming` socket event or Firebase push
- Only show if `callState == idle` (ignore if already in a call)
- Displays: caller's avatar, name, "Incoming video/audio call" text with type icon
- Buttons: Accept (green), Decline (red)
- Accept -> set callState to `accepting` -> POST `/call/accept` -> transition to Active Call Screen
- Decline -> POST `/call/decline` -> dismiss and reset
- Auto-dismiss when `call:cancelled` received (caller hung up)
- Auto-dismiss when `call:answered-elsewhere` received (you answered on another device) - but ONLY if `callState == ringing` (not if `accepting` or `active`)
- Play ringtone, vibrate
- Pulse ring animation around caller avatar

### 9.3 Active Call Screen (1-to-1)
- Shows during connected call (callState = `active`)
- **Video call layout:**
  - Full-screen remote video
  - Small local video preview (draggable PiP, bottom-right, 120x160px)
  - Local video mirrors horizontally (`transform: scaleX(-1)`)
  - When remote camera is off: show avatar + name centered (the "no-video" placeholder)
- **Audio call layout:**
  - Centered avatar of other user
  - Name below avatar
  - No video elements
- **Controls bar** (bottom, gradient overlay):
  - Toggle mic (shows on/off icon, pink background when muted)
  - Toggle camera (shows on/off icon, pink background when off, hides local PiP)
  - End call (larger red button, center)
  - Toggle speaker (shows on/off icon, pink background when off)
  - Screen share button (hidden by default, for future use)
- **Top info bar** (gradient overlay):
  - Green dot + call timer (MM:SS format, starts counting from active state)
  - Call type label ("Video Call" / "Audio Call")
- Timer starts from `callState = active` (when `showActiveCall` is called), not from WebRTC connection

### 9.4 Active Call Screen (Group)
- Grid layout for video tiles (2x2, 3x2 depending on participants)
- Each tile shows: user video (or avatar if camera off), name label, mic mute indicator
- Same control buttons as 1-to-1 plus participant count
- Dynamically adds/removes tiles on `call:participant-joined` / `call:participant-left`

### 9.5 Call History Screen
- List of past calls fetched from GET `/call/history`
- Each item shows: user avatar/name, call type icon (audio/video), call direction (incoming/outgoing/missed), duration, timestamp
- Missed calls highlighted in red
- Tap to call back (initiate new call)
- Filter by conversation or show all

---

## 10. Push Notifications for Calls

When the app is in background or killed, incoming calls arrive via Firebase push notification. **The chat service does not send FCM directly.** Instead, it publishes a Kafka event to the `notification.service` topic, and a separate notification microservice constructs and delivers the FCM push.

### 10.1 Notification architecture

```
Chat Service                    Kafka                      Notification Service         Device
     |                            |                              |                        |
     |-- publish event ---------->|                              |                        |
     |   (notification.service    |-- consume ------------------>|                        |
     |    topic)                  |                              |-- FCM push ----------->|
     |                            |                              |                        |
```

**What the chat service publishes (Kafka event):**

```json
{
  "type": ["push_notification", "notification"],
  "operation": "incoming_call",
  "sender_user": {
    "id": "64a...",
    "name": "John Doe",
    "contact": "+1234567890",
    "profile_image": "https://..."
  },
  "receiver_users": [
    { "id": "64c..." }
  ],
  "data": {
    "message_id": "64d...",
    "conversation_id": "64e...",
    "call_id": "64f...",
    "room_id": "uuid-v4-string",
    "call_type": "audio_call",
    "is_group": false,
    "message": "Incoming voice call"
  }
}
```

The notification service maps `sender_user.name` and `sender_user.profile_image` into the FCM payload fields (e.g., `name`, `profile_image` in the `data` section).

**Two operations:**

| Operation | When | FCM Priority | Android Channel |
|-----------|------|-------------|-----------------|
| `incoming_call` | Call initiated, receiver is offline | High (`android.priority: "high"`) | `incoming_calls` |
| `missed_call` | Caller cancels before anyone answers | Normal | `missed_calls` |

**Expected FCM payload the Flutter client receives** (constructed by the notification service):

```json
{
  "notification": {
    "title": "John Doe is Calling",
    "body": "Voice call"
  },
  "data": {
    "call_type": "audio_call",
    "conversation_id": "64abc...",
    "call_id": "64def...",
    "room_id": "uuid...",
    "message_id": "64ghi...",
    "missed_call": "false",
    "is_group": "false",
    "name": "John Doe",
    "profile_image": "https://...",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channelId": "incoming_calls"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "ringtone.caf",
        "category": "INCOMING_CALL",
        "mutable-content": 1
      }
    }
  }
}
```

> **Note:** The `name` and `profile_image` data fields are derived from the `sender_user` object by the notification service — the chat service does not put them directly in the data payload. See `docs/notification-service-call-operations.md` for the full notification service spec.

**Missed call notifications** are sent when:
- The caller cancels (POST `/call/cancel`)

For missed calls, `missed_call` is `"true"`, `channelId` is `"missed_calls"`, and priority is normal. Title: `"{sender_name}"`, body: `"Missed Voice call"` or `"Missed Video call"`.

### 10.2 Handling incoming call push

> **Note:** All FCM `data` fields arrive as strings. Check `missed_call` and `is_group` with string comparison (`== 'true'`/`== 'false'`), not boolean comparison. The `name` and `profile_image` fields are populated by the notification service from the `sender_user` object.

```dart
// In your Firebase messaging handler
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  if (message.data['call_type'] != null && message.data['missed_call'] != 'true') {
    // Show incoming call UI
    showIncomingCall(
      callId: message.data['call_id'],
      roomId: message.data['room_id'],
      callType: message.data['call_type'],
      callerName: message.data['name'],          // From sender_user.name via notification service
      callerImage: message.data['profile_image'], // From sender_user.profile_image via notification service
      conversationId: message.data['conversation_id'],
      isGroupCall: message.data['is_group'] == 'true',
    );
  }
});

// For background/killed state - use flutter_callkit_incoming
FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  if (message.data['call_type'] != null && message.data['missed_call'] != 'true') {
    // Show native call UI using flutter_callkit_incoming
    await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
      id: message.data['call_id'],
      nameCaller: message.data['name'] ?? 'Unknown',
      avatar: message.data['profile_image'] ?? '',
      type: message.data['call_type'] == 'video_call' ? 1 : 0,
      extra: {
        'room_id': message.data['room_id'],
        'conversation_id': message.data['conversation_id'],
        'call_type': message.data['call_type'],
      },
    ));
  }
}
```

### 10.3 Android notification channels

Create these notification channels in your Android app:

```dart
// incoming_calls channel - HIGH importance for heads-up display
const AndroidNotificationChannel incomingCallsChannel = AndroidNotificationChannel(
  'incoming_calls',
  'Incoming Calls',
  description: 'Notifications for incoming voice and video calls',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('ringtone'),
);

// missed_calls channel
const AndroidNotificationChannel missedCallsChannel = AndroidNotificationChannel(
  'missed_calls',
  'Missed Calls',
  description: 'Notifications for missed calls',
  importance: Importance.high,
);
```

### 10.4 iOS CallKit integration

Use `flutter_callkit_incoming` to show the native iOS call UI:

```dart
// When receiving call:incoming or Firebase push
FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
  id: callId,
  nameCaller: callerName,
  avatar: callerProfileImage,
  handle: callerName,
  type: callType == 'video_call' ? 1 : 0,
  duration: 60000,  // 60 second timeout
  textAccept: 'Accept',
  textDecline: 'Decline',
  extra: { 'room_id': roomId, 'call_id': callId },
));

// Listen for CallKit events
FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
  switch (event?.event) {
    case Event.actionCallAccept:
      // User accepted via CallKit -> call POST /call/accept
      break;
    case Event.actionCallDecline:
      // User declined via CallKit -> call POST /call/decline
      break;
    case Event.actionCallEnded:
      // User ended via CallKit -> call POST /call/end
      break;
    default:
      break;
  }
});
```

---

## 11. Edge Cases & Error Handling

### 11.1 Caller cancels before receiver answers
- Caller taps hang up during ringing -> POST `/call/cancel`
- Also emit `call:leave-room` with `{ room_id, call_id }` to leave the socket room
- Receiver gets `call:cancelled` socket event -> dismiss incoming call UI
- If receiver was showing CallKit, call `FlutterCallkitIncoming.endCall(callId)`
- Backend marks all "ringing" participants as "missed" and publishes `missed_call` notification via Kafka

### 11.2 Receiver declines
- Receiver taps decline -> POST `/call/decline`
- Caller gets `call:declined` socket event with `{ call_ended: true }` -> show "Call declined" and navigate back
- For group calls: `call_ended` may be `false` if other receivers are still ringing

### 11.3 Ringing timeout (60 seconds)
- Start a 60-second timer when initiating a call
- If no `call:accepted` received within 60 seconds -> POST `/call/cancel`
- The backend also has a 60-second TTL on ringing state in Redis (`call_ringing:{roomId}:{userId}`)
- Active call Redis keys (`active_call:{roomId}`, `call_participants:{roomId}`, `user_active_call:{userId}`) have a 3600-second (1 hour) TTL as a safety net
- The backend handles disconnect cleanup automatically

### 11.4 User already in a call (busy)
- Response from `/call/initiate`: `409` with `{ "success": false, "busy": true, "message": "User is on another call" }`
- For 1-to-1 calls: show "User is busy" in the UI and stop local media
- For group calls: the call proceeds, and `busy_users` in the response lists who was excluded

### 11.5 Network disconnection during call
- `RTCIceConnectionState.disconnected` - show "Reconnecting..." UI (may recover automatically)
- If it transitions to `failed` or `closed` - end the call via `endCurrentCall()`
- The backend auto-cleans up when the socket disconnects (calls `handleCallDisconnect` which marks participant as "left" and ends call if < 2 remain)
- On disconnect, the backend emits `call:ended` with `reason: "disconnect"` (if < 2 remain) or `call:participant-left` with `reason: "disconnect"` (if >= 2 remain in a group call). Handle the `reason` field to show appropriate UI (e.g., "Call ended due to connection loss" vs "User disconnected")
- On app reconnect, check GET `/call/active` to see if a call is still active and rejoin

### 11.6 App goes to background during call
- Keep the WebRTC connection alive
- Android: Use foreground service with ongoing notification
- iOS: Use CallKit to keep the audio session alive
- Use `wakelock_plus` to prevent screen timeout during active call

### 11.7 Answered on another device
- Listen for `call:answered-elsewhere` -> dismiss incoming call UI
- **Critical:** Only reset if `callState == ringing`. Do NOT reset if `callState == accepting` or `active` (you're the one who answered)
- This handles the case where user has the app on both phone and tablet

### 11.8 Call already accepted by someone else (race condition)
- POST `/call/accept` returns `404` with `{ "success": false, "message": "Call not found or no longer ringing" }`
- The backend uses atomic `findOneAndUpdate` with status check, so only the first acceptor succeeds
- Dismiss the incoming call UI, stop any local media acquired, and show a toast "Call already answered"

### 11.9 SDP offer arrives before user accepts
- When `call:offer` arrives while `callState == ringing`, store it as `currentCallData.pendingOffer`
- When the user accepts and peer connection is created, process the stored offer immediately
- This avoids a timing issue where the caller sends the offer before the receiver has a peer connection

### 11.10 Signaling state check for SDP answer
- Before calling `setRemoteDescription` with an SDP answer, check `peerConnection.signalingState == 'have-local-offer'`
- This prevents errors from duplicate or late-arriving answers

---

## 12. Call History UI

### 12.1 Determining call direction and status for display

```dart
String getCallDisplayText(CallModel call, String currentUserId) {
  final bool isOutgoing = call.initiatedBy == currentUserId;
  final String direction = isOutgoing ? 'Outgoing' : 'Incoming';

  switch (call.status) {
    case 'ended':
      if (call.endReason == 'missed') {
        return isOutgoing ? 'No answer' : 'Missed call';
      } else if (call.endReason == 'declined') {
        return isOutgoing ? 'Declined' : 'You declined';
      } else {
        return '$direction call - ${formatDuration(call.durationSeconds)}';
      }
    case 'missed':
      return isOutgoing ? 'No answer' : 'Missed call';
    case 'declined':
      return isOutgoing ? 'Declined' : 'You declined';
    default:
      return '$direction call';
  }
}

// Call type icon:
// call.callType == 'video_call' -> Icons.videocam
// call.callType == 'audio_call' -> Icons.call

// Missed call color: Colors.red
// Completed call color: Colors.green (outgoing) or Colors.blue (incoming)
```

### 12.2 Message bubble in chat

When displaying call messages in the chat conversation (message_type == `"video_call"` or `"audio_call"`), use the `metadata` fields from the message object:

```dart
// metadata fields available:
// metadata.call_id: String - links to the full call record
// metadata.room_id: String - the call room UUID
// metadata.other_user_id: String? - the other user (1-to-1 calls)
// metadata.call_status: String - "ringing", "connecting", "completed", "missed", "declined"
// metadata.call_time: String - formatted duration "MM:SS" or "HH:MM:SS" (for calls >= 1 hour), only present for completed calls
// metadata.missed_call: bool - true if call was missed (set by cancel)
// metadata.call_decline: bool - true if call was declined (set by decline)
// metadata.call_accept: bool - true if call was accepted (set by accept)
//
// Message text lifecycle:
//   Initiate:  "Calling..."
//   Accept:    "Call connected"
//   Decline:   "Call declined"
//   Cancel:    "Missed call"
//   End:       "Call ended - MM:SS" (or "Call ended - HH:MM:SS")
```

**Bubble rendering logic (from the reference implementation):**

```dart
Widget buildCallBubble(Message msg) {
  final metadata = msg.metadata ?? {};
  final isVideo = msg.messageType == 'video_call';
  final isMissed = metadata['missed_call'] == true;
  final isDeclined = metadata['call_decline'] == true;

  String statusText = 'Ended';
  Color statusColor = Colors.grey;

  if (isMissed) {
    statusText = 'Missed call';
    statusColor = Colors.orange;
  } else if (isDeclined) {
    statusText = 'Declined';
    statusColor = Colors.pink;
  } else if (metadata['call_time'] != null) {
    // call_time format: "MM:SS" or "HH:MM:SS" (for calls >= 1 hour)
    statusText = 'Duration: ${metadata['call_time']}';
    statusColor = Colors.teal;
  }

  return CallBubbleWidget(
    icon: isVideo ? Icons.videocam : Icons.phone,
    title: isVideo ? 'Video Call' : 'Audio Call',
    statusText: statusText,
    statusColor: statusColor,
    isMissed: isMissed,
  );
}
```

---

## 13. Screen Sharing

### 13.1 Starting screen share

```dart
Future<void> startScreenShare() async {
  // Get screen capture stream
  final screenStream = await navigator.mediaDevices.getDisplayMedia({
    'video': true,
    'audio': true,  // system audio if available
  });

  // Replace video track in peer connection
  final screenTrack = screenStream.getVideoTracks().first;
  final senders = await peerConnection.getSenders();
  final videoSender = senders.firstWhere(
    (s) => s.track?.kind == 'video',
    orElse: () => senders.first,
  );
  await videoSender.replaceTrack(screenTrack);

  // Notify others
  socket.emit('call:screen-share-start', { 'room_id': roomId });

  // Listen for screen share stop (user swipes away from share)
  screenTrack.onEnded = () {
    stopScreenShare();
  };
}
```

### 13.2 Stopping screen share

```dart
Future<void> stopScreenShare() async {
  // Restore camera track
  final cameraTrack = localStream?.getVideoTracks().first;
  if (cameraTrack != null) {
    final senders = await peerConnection.getSenders();
    final videoSender = senders.firstWhere(
      (s) => s.track?.kind == 'video',
      orElse: () => senders.first,
    );
    await videoSender.replaceTrack(cameraTrack);
  }

  socket.emit('call:screen-share-stop', { 'room_id': roomId });
}
```

### 13.3 Receiving screen share

```dart
socket.on('call:screen-share-start', (data) {
  final userId = data['user_id'];
  // Update UI - show screen share indicator
  // The video track on the RTCPeerConnection will automatically switch to screen content
  // Make this user's video tile full screen or larger
});

socket.on('call:screen-share-stop', (data) {
  final userId = data['user_id'];
  // Revert to normal video layout
});
```

**Note:** The screen share button is hidden by default in the reference implementation (`hidden` class on `btn-toggle-screen`). Enable it when ready to support screen sharing.

---

## 14. Testing Checklist

### 1-to-1 Calls
- [ ] Initiate audio call to online user
- [ ] Initiate video call to online user
- [ ] Initiate call to offline user (Firebase push should arrive)
- [ ] Accept incoming call
- [ ] Decline incoming call
- [ ] Cancel outgoing call (hang up before answer)
- [ ] Call auto-cancels after 60 seconds of ringing
- [ ] End active call (both sides)
- [ ] Toggle microphone during call (verify icon changes + remote notification)
- [ ] Toggle camera during call (verify PiP hides/shows + remote sees avatar)
- [ ] Switch front/back camera
- [ ] Toggle speaker/earpiece
- [ ] Network disconnection recovery (ICE reconnection)
- [ ] App background/foreground transitions during call
- [ ] CallKit incoming call UI (iOS)
- [ ] Heads-up notification (Android)
- [ ] Busy user scenario (409 response with `busy: true`)
- [ ] Media permission denied handling (`NotAllowedError`)

### Group Calls
- [ ] Initiate group call from group conversation
- [ ] All non-busy members receive incoming call notification
- [ ] `busy_users` array correctly lists excluded users
- [ ] Multiple members accept and connect
- [ ] New participant joins ongoing call (POST `/call/join`)
- [ ] Participant leaves - call continues with remaining (if >= 2)
- [ ] Last two participants - one leaves - call ends
- [ ] Media toggle works across all participants
- [ ] Video grid dynamically adds/removes tiles

### Switch Call Type
- [ ] Switch video → audio (immediate, no approval needed)
- [ ] Switch audio → video (sends request, receiver sees prompt)
- [ ] Accept switch to video (camera enables on both sides)
- [ ] Decline switch to video (requester gets notification)
- [ ] Switch button icon updates correctly (shows opposite type)
- [ ] UI label updates (Audio Call ↔ Video Call)
- [ ] Camera auto-enables when switching to video
- [ ] Camera auto-disables when switching to audio
- [ ] Cannot switch to same type (already audio/video error)
- [ ] Switch works in group calls (first responder decides)

### Add User to Call
- [ ] Add a single user to an active 1-to-1 call (auto-upgrades to group)
- [ ] Add multiple users at once
- [ ] Busy users reported correctly (not added, no error)
- [ ] Already-in-call users reported correctly
- [ ] Added user receives `call:incoming` and can accept normally
- [ ] Existing participants receive `call:user-added` event
- [ ] After accept, peer connections are established with all existing participants
- [ ] 1-to-1 call properly transitions to group call UI after add

### Call History
- [ ] Fetch call history (all calls)
- [ ] Fetch call history (per conversation)
- [ ] Pagination works correctly
- [ ] Correct call direction display (incoming/outgoing)
- [ ] Correct status display (completed/missed/declined)
- [ ] Tap to call back

### Edge Cases
- [ ] Answered on another device (`call:answered-elsewhere` - only resets if `callState == ringing`)
- [ ] Race condition - two users accept simultaneously (second gets 404, graceful handling)
- [ ] SDP offer arrives before accept (stored as `pendingOffer`, processed after accept)
- [ ] SDP answer arrives with wrong signaling state (check `have-local-offer` before setting)
- [ ] Call with `other_user_id` instead of `conversation_id` (auto-creates conversation)
- [ ] Socket reconnection during ringing
- [ ] Firebase push arriving when app is killed
- [ ] Call message bubbles display correctly in chat (metadata fields)
- [ ] Call state properly resets on logout/disconnect
