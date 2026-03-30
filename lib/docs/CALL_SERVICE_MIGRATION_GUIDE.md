# Call Service Migration Guide

Complete integration guide for migrating call functionality from `be_chat_service` to the independent `be_call_service`.

**GitHub Repo:** https://github.com/techblueera/be_call_service

---

## Architecture Overview

```
Frontend (App/HTML Testers)
    |
    |--- Socket.IO (/socket) ---> be_chat_service (unchanged)
    |                               |
    |                               |--- WebRTC signaling relay (call:offer/answer/ice-candidate)
    |                               |--- Redis Pub/Sub subscriber (call:socket:emit)
    |                               |--- Redis Pub/Sub publisher (call:user:disconnected)
    |                               |--- CallChatBridge gRPC service (message/conversation ops)
    |
    |--- REST (call endpoints) ---> be_call_service (NEW)
                                      |
                                      |--- Redis Pub/Sub publisher (call:socket:emit)
                                      |--- Redis Pub/Sub subscriber (call:user:disconnected)
                                      |--- gRPC client (CallChatBridge -> chat service)
                                      |--- Kafka producer (notification.service topic)
                                      |--- Own MongoDB (calls, call_participants)
```

---

## Endpoint URL Changes

### REST API Endpoints That Moved to Call Service

All 14 call endpoints now live at `be_call_service`. The paths are **identical** — only the base URL changes.

| Method | Path | Old Base URL | New Base URL |
|--------|------|-------------|-------------|
| POST | `/call/initiate` | `https://chat.blueera.ai/` | `https://call.blueera.ai/` |
| POST | `/call/accept` | `https://chat.blueera.ai/` | `https://call.blueera.ai/` |
| POST | `/call/decline` | `https://chat.blueera.ai/` | `https://call.blueera.ai/` |
| POST | `/call/cancel` | `https://chat.blueera.ai/` | `https://call.blueera.ai/` |
| POST | `/call/end` | `https://chat.blueera.ai/` | `https://call.blueera.ai/` |
| POST | `/call/join` | `https://chat.blueera.ai/` | `https://call.blueera.ai/` |
| POST | `/call/add-user` | `https://chat.blueera.ai/` | `https://call.blueera.ai/` |
| POST | `/call/switch-type` | `https://chat.blueera.ai/` | `https://call.blueera.ai/` |
| POST | `/call/switch-type/respond` | `https://chat.blueera.ai/` | `https://call.blueera.ai/` |
| POST | `/call/screen-share/start` | `https://chat.blueera.ai/` | `https://call.blueera.ai/` |
| POST | `/call/screen-share/stop` | `https://chat.blueera.ai/` | `https://call.blueera.ai/` |
| GET | `/call/history` | `https://chat.blueera.ai/` | `https://call.blueera.ai/` |
| GET | `/call/active` | `https://chat.blueera.ai/` | `https://call.blueera.ai/` |
| GET | `/call/ice-servers` | `https://chat.blueera.ai/` | `https://call.blueera.ai/` |

### What Does NOT Change

| Component | URL | Status |
|-----------|-----|--------|
| Socket.IO connection | `wss://chat.blueera.ai/socket` | **No change** — single socket |
| All socket events | Same event names, same payloads | **No change** |
| Chat REST endpoints | `https://chat.blueera.ai/chat/*` | **No change** |
| Group endpoints | `https://chat.blueera.ai/group/*` | **No change** |
| Block endpoints | `https://chat.blueera.ai/block/*` | **No change** |
| S3/media endpoints | `https://chat.blueera.ai/s3/*` | **No change** |
| All other endpoints | `https://chat.blueera.ai/*` | **No change** |

---

## Flutter App Changes

### File: `flutter_app/lib/core/util/constants.dart`

Add a new constant for the call service base URL:

```dart
// Existing
static const String chatBaseUrl = 'https://chat.blueera.ai/';
static const String authBaseUrl = 'https://be.blueera.ai/';

// NEW - Add this
static const String callBaseUrl = 'https://call.blueera.ai/';
```

### File: `flutter_app/lib/features/calls/data/call_api.dart`

Update the API client to use the new base URL for all call endpoints:

```dart
// Change from:
final response = await _apiClient.post('call/initiate', data: body);

// To (using call-specific base URL):
final response = await _callApiClient.post('call/initiate', data: body);
```

You'll need either:
- A second `ApiClient` instance configured with `callBaseUrl`, or
- A parameter in the existing `ApiClient` to override the base URL per-request

### Socket Events — NO CHANGES

All socket events continue to flow through the single chat service socket connection:

**Inbound (listen for):**
- `call:incoming` — Incoming call notification
- `call:accepted` — Call accepted
- `call:answered-elsewhere` — Answered on another device
- `call:declined` — Call declined
- `call:cancelled` — Call cancelled by initiator
- `call:ended` — Call terminated
- `call:participant-joined` — User joined group call
- `call:participant-left` — User left group call
- `call:user-added` — Users added to active call
- `call:offer` / `call:answer` / `call:ice-candidate` — WebRTC signaling
- `call:user-joined` / `call:user-left` — Socket room join/leave
- `call:media-toggle` — Audio/video toggle
- `call:screen-share-start` / `call:screen-share-stop` — Screen sharing
- `call:switch-type-request` / `call:type-switched` / `call:switch-type-declined` — Call type switching

**Outbound (emit):**
- `call:offer` / `call:answer` / `call:ice-candidate` — WebRTC signaling (stays direct)
- `call:join-room` / `call:leave-room` — Room management (stays direct)
- `call:media-toggle` — Toggle audio/video (stays direct)
- `call:screen-share-start` / `call:screen-share-stop` — Screen share (stays direct)

---

## HTML Tester Changes (Already Done)

Both `public/index.html` and `public/e2e-chat.html` have been updated:

1. Added `CALL_API_BASE_URL = 'https://call.blueera.ai/'`
2. Added `callApiCall()` function that routes to the call service
3. All `apiCall('call/...')` calls changed to `callApiCall('call/...')`
4. Socket connection and events remain unchanged

---

## What Was Added to be_chat_service

### New Files

| File | Purpose |
|------|---------|
| `src/grpc/services/callChatBridgeService.js` | gRPC service with 5 RPCs for call service to interact with chat data |
| `src/grpc/protos/callChatBridge.proto` | Proto definition for the bridge service |
| `src/utils/callSocketBridge.js` | Redis Pub/Sub bridge — subscribes to `call:socket:emit`, publishes `call:user:disconnected` |

### Modified Files

| File | Change |
|------|--------|
| `src/grpc/services/index.js` | Added `callChatBridgeServiceDefinition` to gRPC server |
| `src/utils/socket.js` | Added `notifyCallServiceDisconnect(user_id)` on socket disconnect |
| `index.js` | Added `initCallSocketBridge(io)` initialization after Socket.IO setup |
| `public/index.html` | Added `CALL_API_BASE_URL`, `callApiCall()`, updated call fetch calls |
| `public/e2e-chat.html` | Same as index.html |

### gRPC Bridge Methods (CallChatBridge)

The chat service now exposes these RPCs on the existing gRPC server (port 50051):

| RPC Method | What It Does |
|------------|-------------|
| `CreateCallMessage` | Creates a message in the conversation timeline when a call is initiated |
| `UpdateCallMessage` | Updates message metadata (accept, decline, cancel, end, missed) |
| `UpdateConversationLastMessage` | Updates the conversation's last_message field |
| `GetConversationMembers` | Returns user IDs in a conversation (for group call member lookup) |
| `FindOrCreateConversation` | Finds or creates a 1-to-1 conversation (for direct calls) |

### Redis Pub/Sub Channels

| Channel | Publisher | Subscriber | Purpose |
|---------|-----------|------------|---------|
| `call:socket:emit` | Call service | Chat service | Call service sends socket events; chat service emits to frontend |
| `call:user:disconnected` | Chat service | Call service | Chat service notifies when a user's socket disconnects |
| `call:socket:recv` | Chat service | Call service | (Reserved for future) Chat service forwards inbound call socket events |

---

## Deployment Order

### Step 1: Configure Environment

1. Add new env keys to AWS Secrets Manager (see `be_call_service/ENV_SETUP.md`):
   - `MONGO_URI_CALL_SERVICE` (required)
   - `GRPC_CHAT_SERVICE_ADDRESS` already exists as `chat.beapp.grpc:50051` — no action needed
2. Create MongoDB database for call service

### Step 2: Deploy Chat Service First

Deploy the updated `be_chat_service` with:
- CallChatBridge gRPC service
- Redis Pub/Sub bridge (callSocketBridge.js)
- Socket disconnect notification

This is **backwards compatible** — the old call endpoints still work in the chat service during the migration. The new gRPC service and Redis bridge are idle until the call service connects.

### Step 3: Deploy Call Service

Deploy `be_call_service` alongside the chat service:
- It connects to the same Redis instance
- It connects to the same Kafka brokers
- It calls the chat service's gRPC server for message/conversation operations
- It publishes socket events via Redis for the chat service to emit

### Step 4: Update Frontend

1. Update Flutter `constants.dart` with `callBaseUrl`
2. Route call API calls to the new service
3. No socket changes needed

### Step 5: Verify

1. Test a 1-to-1 audio call end-to-end
2. Test a 1-to-1 video call with camera toggle
3. Test a group call with add-user
4. Test call decline and cancel flows
5. Test disconnect handling (kill app mid-call)
6. Test screen sharing
7. Verify call history loads correctly
8. Verify missed call notifications arrive

### Step 6: Remove Old Call Code from Chat Service (Optional, Later)

Once the call service is stable and handling all traffic:
1. Remove `call.controller.js`, `call.route.js` from chat service
2. Remove `call.schema.js`, `callParticipant.schema.js` from chat service
3. Remove `callStateManager.js`, `iceServers.js` from chat service
4. Remove `firebaseCallNotification.js` (already unused/legacy)
5. Remove call-related imports from `socket.js` (keep signaling relay + bridge)
6. Clean `handleCallDisconnect` import — bridge handles it

---

## Rollback Plan

If the call service has issues:
1. Revert Flutter `callBaseUrl` to `https://chat.blueera.ai/`
2. Revert HTML testers' `CALL_API_BASE_URL` to `https://chat.blueera.ai/`
3. The chat service's call endpoints are still active during the parallel-run phase

The chat service's existing call controller remains functional until explicitly removed in Step 6.

---

## Infrastructure Requirements

| Resource | Details |
|----------|---------|
| **Compute** | 1 instance/container for `be_call_service` (Express on port 3000) |
| **MongoDB** | New database or shared cluster with `calls` + `call_participants` collections |
| **Redis** | Shared with chat service (same `REDIS_HOST_CHAT_SERVICE`) |
| **Kafka** | Shared brokers (same `KAFKA_BROKERS`), publishes to existing `notification.service` topic |
| **gRPC** | Connects to chat service gRPC on port 50051 |
| **DNS** | `call.blueera.ai` pointing to the call service load balancer |
| **ALB/NLB** | Route `/call/*` to call service, health check on `GET /` |
