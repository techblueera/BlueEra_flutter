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
10. [Firebase Push Notifications for Calls](#10-firebase-push-notifications-for-calls)
11. [Edge Cases & Error Handling](#11-edge-cases--error-handling)
12. [Call History UI](#12-call-history-ui)
13. [Screen Sharing](#13-screen-sharing)
14. [Testing Checklist](#14-testing-checklist)

---

## 1. Architecture Overview

The call system is fully in-house WebRTC. Audio/video streams flow **peer-to-peer** between devices. The backend only handles:
- **Signaling** - Relaying SDP offers/answers and ICE candidates via Socket.IO
- **Call state** - Tracking call lifecycle (ringing, connecting, connected, ended) via REST APIs
- **Notifications** - Firebase push for incoming calls when the app is in background/killed

```
Flutter App A                 Backend (Socket.IO)              Flutter App B
     |                              |                              |
     |-- POST /call/initiate ------>|                              |
     |<-- { room_id, ice_servers }  |--- socket: call:incoming --->|
     |                              |--- firebase push ----------->|
     |                              |                              |
     |                              |<-- POST /call/accept --------|
     |<-- socket: call:accepted ----|                              |
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
- Group calls use **full mesh** - each participant connects to every other participant directly (max ~6 participants)

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

---

## 4. REST API Endpoints

All endpoints require `Authorization: Bearer <jwt_token>` header.

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
  "message": { /* full message object */ },
  "ice_servers": {
    "iceServers": [
      { "urls": "stun:stun.l.google.com:19302" },
      { "urls": "turn:turn.yourserver.com:3478", "username": "1709712000:user123", "credential": "base64hash" }
    ]
  },
  "busy_users": []                    // list of user_ids who are on another call (group calls only)
}
```

**Error responses:**
- `400` - Invalid call_type or missing both conversation_id and other_user_id
- `409` - Caller already in a call, or receiver is busy (1-to-1)
- `404` - Conversation not found
- `500` - Server error

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
    "iceServers": [...]
  },
  "call": { /* full call object */ }
}
```

**Error responses:**
- `400` - Missing call_id or room_id
- `404` - Call not found or no longer ringing (already accepted/cancelled/declined)

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

### 4.4 POST `/call/cancel` - Cancel outgoing call (before anyone answers)

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

**Error:** `404` if call not found or not cancellable (someone already accepted).

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
  "ice_servers": { "iceServers": [...] },
  "existing_participants": ["user_id_1", "user_id_2"],
  "call": { /* full call object */ }
}
```

**Error responses:**
- `403` - Not a member of this conversation
- `404` - Group call not found or already ended
- `409` - Already in another call

### 4.7 GET `/call/history` - Get call history

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
      "duration_seconds": 125,
      "started_at": "2026-03-06T10:30:00.000Z",
      "ended_at": "2026-03-06T10:32:05.000Z",
      "created_at": "2026-03-06T10:29:55.000Z",
      "participants": [
        {
          "user_id": "user123",
          "role": "initiator",
          "status": "left",
          "duration_seconds": 125
        },
        {
          "user_id": "user456",
          "role": "receiver",
          "status": "left",
          "duration_seconds": 125
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

### 4.8 GET `/call/active` - Check if user has an active call

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
    "room_id": "uuid...",
    "participants": ["user123", "user456"]
  }
}
```

Returns `"active_call": null` when no active call exists.

### 4.9 GET `/call/ice-servers` - Get STUN/TURN config

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

---

## 5. Socket.IO Events Reference

Socket connection path: `/socket`

### 5.1 Events the CLIENT LISTENS TO (server -> client)

| Event | Payload | When |
|-------|---------|------|
| `call:incoming` | `{ call_id, room_id, conversation_id, call_type, initiated_by, is_group_call, message }` | Someone is calling you |
| `call:accepted` | `{ call_id, room_id, accepted_by }` | Receiver accepted your call |
| `call:declined` | `{ call_id, room_id, declined_by, call_ended }` | Receiver declined your call |
| `call:cancelled` | `{ call_id, room_id, cancelled_by }` | Caller cancelled before you answered |
| `call:ended` | `{ call_id, room_id, duration_seconds, ended_by, reason? }` | Call has ended |
| `call:answered-elsewhere` | `{ call_id, room_id }` | You answered on another device, dismiss ringing |
| `call:participant-joined` | `{ call_id, room_id, user_id, existing_participants }` | New participant joined group call |
| `call:participant-left` | `{ call_id, room_id, user_id, reason? }` | Participant left group call |
| `call:offer` | `{ room_id, from_user_id, sdp }` | Incoming WebRTC SDP offer |
| `call:answer` | `{ room_id, from_user_id, sdp }` | Incoming WebRTC SDP answer |
| `call:ice-candidate` | `{ room_id, from_user_id, candidate }` | Incoming ICE candidate |
| `call:media-toggle` | `{ user_id, is_video_enabled, is_audio_enabled }` | Remote user toggled camera/mic |
| `call:screen-share-start` | `{ user_id }` | Remote user started screen sharing |
| `call:screen-share-stop` | `{ user_id }` | Remote user stopped screen sharing |
| `call:user-joined` | `{ user_id }` | User joined the Socket.IO call room |
| `call:user-left` | `{ user_id }` | User left the Socket.IO call room |

### 5.2 Events the CLIENT EMITS (client -> server)

| Event | Payload | When |
|-------|---------|------|
| `call:offer` | `{ room_id, target_user_id, sdp }` | Sending SDP offer to a specific user |
| `call:answer` | `{ room_id, target_user_id, sdp }` | Sending SDP answer to a specific user |
| `call:ice-candidate` | `{ room_id, target_user_id, candidate }` | Sending ICE candidate to a specific user |
| `call:join-room` | `{ room_id }` | Join the Socket.IO room for this call |
| `call:leave-room` | `{ room_id, call_id }` | Leave the Socket.IO room |
| `call:media-toggle` | `{ room_id, is_video_enabled, is_audio_enabled }` | Notify others of camera/mic toggle |
| `call:screen-share-start` | `{ room_id }` | Notify others of screen share start |
| `call:screen-share-stop` | `{ room_id }` | Notify others of screen share stop |

---

## 6. Call Flow: 1-to-1 Audio/Video Call

### Step 1: Caller initiates call

```dart
// 1. Request camera/mic permissions
await [Permission.camera, Permission.microphone].request();

// 2. Call the API
final response = await dio.post('/call/initiate', data: {
  'call_type': 'video_call',       // or 'audio_call'
  'other_user_id': otherUserId,    // or 'conversation_id': conversationId
});

final roomId = response.data['room_id'];
final callId = response.data['call_id'];
final iceServers = IceServerConfig.fromJson(response.data['ice_servers']);
final conversationId = response.data['conversation_id'];

// 3. Navigate to OutgoingCallScreen
// Show ringing UI with caller info, play ringing sound
// Start a 60-second timer - if no answer, call POST /call/cancel

// 4. Join the Socket.IO call room
socket.emit('call:join-room', { 'room_id': roomId });

// 5. Create RTCPeerConnection with ICE servers (but DON'T create offer yet)
final peerConnection = await createPeerConnection(iceServers.toWebRTCConfig());

// 6. Get local media stream and add tracks
final localStream = await navigator.mediaDevices.getUserMedia({
  'audio': true,
  'video': callType == 'video_call',
});
localStream.getTracks().forEach((track) {
  peerConnection.addTrack(track, localStream);
});
```

### Step 2: Receiver gets incoming call

```dart
// Listen for the call:incoming socket event
socket.on('call:incoming', (data) {
  final callId = data['call_id'];
  final roomId = data['room_id'];
  final callType = data['call_type'];
  final initiatedBy = data['initiated_by'];
  final isGroupCall = data['is_group_call'];
  final conversationId = data['conversation_id'];

  // Show IncomingCallScreen with Accept/Decline buttons
  // Play ringtone
  // If app is in background, this comes via Firebase push (see Section 10)
});
```

### Step 3: Receiver accepts

```dart
// 1. Call the API
final response = await dio.post('/call/accept', data: {
  'call_id': callId,
  'room_id': roomId,
});

final iceServers = IceServerConfig.fromJson(response.data['ice_servers']);

// 2. Navigate to ActiveCallScreen
// Stop ringtone

// 3. Join the Socket.IO call room
socket.emit('call:join-room', { 'room_id': roomId });

// 4. Create RTCPeerConnection
final peerConnection = await createPeerConnection(iceServers.toWebRTCConfig());

// 5. Get local media stream and add tracks
final localStream = await navigator.mediaDevices.getUserMedia({
  'audio': true,
  'video': callType == 'video_call',
});
localStream.getTracks().forEach((track) {
  peerConnection.addTrack(track, localStream);
});

// 6. Wait for the caller to send the SDP offer (see Step 4)
```

### Step 4: Caller receives accepted event and begins WebRTC negotiation

```dart
// The CALLER listens for call:accepted
socket.on('call:accepted', (data) async {
  // Stop ringing sound
  // Navigate to ActiveCallScreen

  // Create and send SDP offer
  final offer = await peerConnection.createOffer();
  await peerConnection.setLocalDescription(offer);

  socket.emit('call:offer', {
    'room_id': roomId,
    'target_user_id': data['accepted_by'],
    'sdp': offer.toMap(),
  });
});
```

### Step 5: Receiver handles SDP offer and sends answer

```dart
socket.on('call:offer', (data) async {
  final sdp = RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);
  await peerConnection.setRemoteDescription(sdp);

  // Create and send SDP answer
  final answer = await peerConnection.createAnswer();
  await peerConnection.setLocalDescription(answer);

  socket.emit('call:answer', {
    'room_id': roomId,
    'target_user_id': data['from_user_id'],
    'sdp': answer.toMap(),
  });
});
```

### Step 6: Caller handles SDP answer

```dart
socket.on('call:answer', (data) async {
  final sdp = RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);
  await peerConnection.setRemoteDescription(sdp);
  // WebRTC will now start ICE negotiation automatically
});
```

### Step 7: Exchange ICE candidates (BOTH sides)

```dart
// Send local ICE candidates to the other peer
peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
  socket.emit('call:ice-candidate', {
    'room_id': roomId,
    'target_user_id': remoteUserId,
    'candidate': candidate.toMap(),
  });
};

// Receive remote ICE candidates
socket.on('call:ice-candidate', (data) async {
  final candidate = RTCIceCandidate(
    data['candidate']['candidate'],
    data['candidate']['sdpMid'],
    data['candidate']['sdpMLineIndex'],
  );
  await peerConnection.addCandidate(candidate);
});
```

### Step 8: Media starts flowing

```dart
// Listen for remote stream
peerConnection.onTrack = (RTCTrackEvent event) {
  if (event.streams.isNotEmpty) {
    // Set the remote stream to a RTCVideoRenderer
    remoteRenderer.srcObject = event.streams[0];
  }
};

// Connection state changes
peerConnection.onConnectionState = (RTCPeerConnectionState state) {
  switch (state) {
    case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
      // Call is live! Start call timer
      break;
    case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
      // ICE failed - end call
      break;
    case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      // Temporary disconnection - show reconnecting UI
      break;
    default:
      break;
  }
};
```

### Step 9: End call

```dart
// When user taps hang up button
Future<void> endCall() async {
  // 1. Call the API
  await dio.post('/call/end', data: {
    'call_id': callId,
    'room_id': roomId,
  });

  // 2. Leave socket room
  socket.emit('call:leave-room', { 'room_id': roomId, 'call_id': callId });

  // 3. Close WebRTC
  localStream?.getTracks().forEach((track) => track.stop());
  await peerConnection?.close();

  // 4. Navigate back to chat
}

// Also listen for the other person ending
socket.on('call:ended', (data) {
  // Same cleanup as above, then navigate back
});
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
// Response includes busy_users array
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
      'candidate': candidate.toMap(),
    });
  };

  peerConnections[newUserId] = pc;

  // The EXISTING participant creates the offer for the NEW participant
  final offer = await pc.createOffer();
  await pc.setLocalDescription(offer);

  socket.emit('call:offer', {
    'room_id': roomId,
    'target_user_id': newUserId,
    'sdp': offer.toMap(),
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

---

## 8. WebRTC Implementation

### 8.1 Creating RTCPeerConnection

```dart
Future<RTCPeerConnection> createPeerConnection(Map<String, dynamic> iceConfig) async {
  final pc = await createPeerConnection(iceConfig, {
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
  final audioTrack = localStream?.getAudioTracks().first;
  if (audioTrack != null) {
    audioTrack.enabled = !audioTrack.enabled;
    isMicEnabled = audioTrack.enabled;

    // Notify other participants
    socket.emit('call:media-toggle', {
      'room_id': roomId,
      'is_audio_enabled': isMicEnabled,
      'is_video_enabled': isCameraEnabled,
    });
  }
}

// Toggle camera
void toggleCamera() {
  final videoTrack = localStream?.getVideoTracks().first;
  if (videoTrack != null) {
    videoTrack.enabled = !videoTrack.enabled;
    isCameraEnabled = videoTrack.enabled;

    socket.emit('call:media-toggle', {
      'room_id': roomId,
      'is_video_enabled': isCameraEnabled,
      'is_audio_enabled': isMicEnabled,
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
  // Update UI for this participant (show avatar if video off, show mute icon, etc.)
});
```

### 8.3 Speaker/Earpiece Toggle

```dart
// Toggle between speaker and earpiece
void toggleSpeaker() {
  final audioTrack = localStream?.getAudioTracks().first;
  if (audioTrack != null) {
    // For flutter_webrtc:
    audioTrack.enableSpeakerphone(!isSpeakerOn);
    isSpeakerOn = !isSpeakerOn;
  }
}
```

---

## 9. UI Screens Required

### 9.1 Outgoing Call Screen
- Shows when YOU initiate a call
- Displays: other user's avatar, name, "Calling..." text, call type (audio/video)
- Buttons: Hang up (red, calls POST /call/cancel)
- Auto-cancel after 60 seconds if no answer
- Plays ringing tone
- Transitions to Active Call Screen when `call:accepted` is received

### 9.2 Incoming Call Screen
- Shows when YOU receive a call via `call:incoming` socket event or Firebase push
- Displays: caller's avatar, name, "Incoming video/audio call" text
- Buttons: Accept (green), Decline (red)
- Accept -> POST /call/accept -> transition to Active Call Screen
- Decline -> POST /call/decline -> dismiss
- Auto-dismiss when `call:cancelled` received (caller hung up)
- Play ringtone, vibrate

### 9.3 Active Call Screen (1-to-1)
- Shows during connected call
- Video call: full-screen remote video, small local video preview (draggable PiP)
- Audio call: centered avatar of other user, call duration timer
- Buttons: Mute mic, Toggle camera (video call), Switch camera (video call), Speaker toggle, Hang up
- Call duration timer starts when `RTCPeerConnectionState.connected`
- Transitions to ended state when `call:ended` received

### 9.4 Active Call Screen (Group)
- Grid layout for video tiles (2x2, 3x2 depending on participants)
- Each tile shows: user video (or avatar if camera off), name label, mic mute indicator
- Same control buttons as 1-to-1 plus participant count
- Dynamically adds/removes tiles on `call:participant-joined` / `call:participant-left`

### 9.5 Call History Screen
- List of past calls fetched from GET /call/history
- Each item shows: user avatar/name, call type icon (audio/video), call direction (incoming/outgoing/missed), duration, timestamp
- Missed calls highlighted in red
- Tap to call back (initiate new call)
- Filter by conversation or show all

---

## 10. Firebase Push Notifications for Calls

When the app is in background or killed, incoming calls arrive via Firebase push notification.

### 10.1 Notification payload structure

The backend sends Firebase notifications with this data:

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
      "channelId": "incoming_calls"     // or "missed_calls"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "ringtone.caf",
        "category": "INCOMING_CALL"
      }
    }
  }
}
```

### 10.2 Handling incoming call push

```dart
// In your Firebase messaging handler
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  if (message.data['call_type'] != null && message.data['missed_call'] == 'false') {
    // Show incoming call UI
    showIncomingCall(
      callId: message.data['call_id'],
      roomId: message.data['room_id'],
      callType: message.data['call_type'],
      callerName: message.data['name'],
      callerImage: message.data['profile_image'],
      conversationId: message.data['conversation_id'],
      isGroupCall: message.data['is_group'] == 'true',
    );
  }
});

// For background/killed state - use flutter_callkit_incoming
FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  if (message.data['call_type'] != null && message.data['missed_call'] == 'false') {
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
- Caller taps hang up during ringing -> POST /call/cancel
- Receiver gets `call:cancelled` socket event -> dismiss incoming call UI
- If receiver was showing CallKit, call `FlutterCallkitIncoming.endCall(callId)`

### 11.2 Receiver declines
- Receiver taps decline -> POST /call/decline
- Caller gets `call:declined` socket event -> show "Call declined" and navigate back

### 11.3 Ringing timeout (60 seconds)
- Start a 60-second timer when initiating a call
- If no `call:accepted` received within 60 seconds -> POST /call/cancel
- The backend also has a 60-second TTL on ringing state in Redis

### 11.4 User already in a call (busy)
- Response from /call/initiate: `409` with `{ "busy": true, "message": "User is on another call" }`
- Show "User is busy" in the UI

### 11.5 Network disconnection during call
- `RTCPeerConnectionState.disconnected` - show "Reconnecting..." UI
- If it transitions to `failed` - end the call
- The backend auto-cleans up when the socket disconnects (calls `handleCallDisconnect`)
- On reconnect, check GET /call/active to see if a call is still active and rejoin

### 11.6 App goes to background during call
- Keep the WebRTC connection alive
- Android: Use foreground service with ongoing notification
- iOS: Use CallKit to keep the audio session alive
- Use `wakelock_plus` to prevent screen timeout during active call

### 11.7 Answered on another device
- Listen for `call:answered-elsewhere` -> dismiss incoming call UI
- This handles the case where user has the app on both phone and tablet

### 11.8 Call already accepted by someone else (race condition)
- POST /call/accept returns `404` with "Call not found or no longer ringing"
- Dismiss the incoming call UI and show a toast "Call already answered"

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

When displaying call messages in the chat conversation (message_type == "video_call" or "audio_call"), use the `metadata` fields:

```dart
// metadata.call_status: "completed", "missed", "declined", "ringing"
// metadata.call_time: "02:05" (duration string, only for completed calls)
// metadata.missed_call: true/false
// metadata.call_decline: true/false
// metadata.call_id: links to the full call record
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
- [ ] Toggle microphone during call
- [ ] Toggle camera during call (video)
- [ ] Switch front/back camera
- [ ] Toggle speaker/earpiece
- [ ] Network disconnection recovery
- [ ] App background/foreground transitions during call
- [ ] CallKit incoming call UI (iOS)
- [ ] Heads-up notification (Android)
- [ ] Busy user scenario (409 response)

### Group Calls
- [ ] Initiate group call from group conversation
- [ ] All members receive incoming call notification
- [ ] Multiple members accept and connect
- [ ] New participant joins ongoing call (POST /call/join)
- [ ] Participant leaves - call continues with remaining
- [ ] Last two participants - one leaves - call ends
- [ ] Media toggle works across all participants
- [ ] Video grid dynamically adds/removes tiles

### Call History
- [ ] Fetch call history (all calls)
- [ ] Fetch call history (per conversation)
- [ ] Pagination works correctly
- [ ] Correct call direction display (incoming/outgoing)
- [ ] Correct status display (completed/missed/declined)
- [ ] Tap to call back

### Edge Cases
- [ ] Answered on another device (call:answered-elsewhere)
- [ ] Race condition - two users accept simultaneously (404 for second)
- [ ] Call with no conversation_id (auto-creates personal/business conversation)
- [ ] Socket reconnection during ringing
- [ ] Firebase push arriving when app is killed
