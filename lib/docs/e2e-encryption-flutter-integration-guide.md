# E2E Encryption & Offline-First — Flutter Frontend Integration Guide

This document provides complete step-by-step details for integrating end-to-end encrypted messaging, key management, offline sync, and encrypted media into the Flutter mobile app. The backend uses Signal Protocol key infrastructure, Socket.IO for real-time encrypted message relay, and REST APIs for key management and sync.

**Covers all 5 phases:**
1. Protocol Versioning (capability handshake)
2. Key Infrastructure (Signal Protocol key exchange)
3. Encrypted Message Relay (send/receive/media)
4. Sync Engine (offline message recovery)
5. Purge Pipeline (automatic cleanup — no frontend work)

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Backward Compatibility — Before vs After](#2-backward-compatibility--before-vs-after)
3. [Required Flutter Packages](#3-required-flutter-packages)
4. [Data Models](#4-data-models)
5. [Phase 1: Protocol Versioning & Capability Handshake](#5-phase-1-protocol-versioning--capability-handshake)
6. [Phase 2: Key Infrastructure — Signal Protocol](#6-phase-2-key-infrastructure--signal-protocol)
7. [Phase 3: Encrypted Message Relay](#7-phase-3-encrypted-message-relay)
8. [Phase 4: Offline Sync Engine](#8-phase-4-offline-sync-engine)
9. [Phase 5: Purge Pipeline (No Frontend Work)](#9-phase-5-purge-pipeline-no-frontend-work)
10. [REST API Reference](#10-rest-api-reference)
11. [Socket.IO Events Reference](#11-socketio-events-reference)
12. [Complete Message Flow Diagrams](#12-complete-message-flow-diagrams)
13. [FCM Push Notifications](#13-fcm-push-notifications)
14. [Error Handling & Edge Cases](#14-error-handling--edge-cases)
15. [Local Storage Requirements](#15-local-storage-requirements)
16. [Testing Checklist](#16-testing-checklist)

---

## 1. Architecture Overview

The E2E encryption system follows the Signal Protocol model. The server **never sees plaintext** — it stores and relays opaque ciphertext blobs. All encryption/decryption happens client-side.

```
Flutter App A (Sender)              Backend (Relay)                  Flutter App B (Receiver)
     |                                    |                                    |
     |  1. Socket connect with            |                                    |
     |     capabilities.e2e = true        |                                    |
     |  ─────────────────────────────────>|                                    |
     |  <── protocol:resolved {e2e} ─────|                                    |
     |                                    |                                    |
     |  2. POST /keys/register           |                                    |
     |     (identity key + signed prekey  |                                    |
     |      + 100 one-time prekeys)       |                                    |
     |  ─────────────────────────────────>|  Stores keys in MongoDB            |
     |                                    |                                    |
     |  3. GET /keys/bundle/:recipientId  |                                    |
     |  ─────────────────────────────────>|                                    |
     |  <── { bundles: [...per device] } ─|  Vends 1 OPK per device            |
     |                                    |                                    |
     |  4. Client-side: Signal Protocol   |                                    |
     |     session setup + encrypt msg    |                                    |
     |                                    |                                    |
     |  5. socket: message:send           |                                    |
     |     { ciphertext: [{deviceId,      |                                    |
     |       body: base64}] }             |                                    |
     |  ─────────────────────────────────>|  6. Store in MongoDB               |
     |  <── message:status                |     (opaque blob, 30-day TTL)      |
     |      {server_received, seq_num} ──|                                    |
     |                                    |  7. Fan-out per device             |
     |                                    |  ── message:new ──────────────────>|
     |                                    |     {ciphertext: "base64 blob"}    |
     |                                    |                                    |
     |                                    |  <── message:ack ─────────────────|
     |  <── message:status                |      {message_id}                  |
     |      {device_delivered} ──────────|                                    |
     |                                    |                                    |
     |                                    |  8. If offline: FCM data-only push |
     |                                    |  ─── FCM ─────────────────────────>|
     |                                    |                                    |
     |                                    |  9. On reconnect: sync missed msgs |
     |                                    |  <── GET /sync/messages ──────────|
     |                                    |  ── { messages, has_more } ───────>|
```

### Key Design Principles

- **Zero-knowledge server**: Server stores ciphertext blobs, never plaintext
- **Per-device encryption**: Each device receives its own ciphertext entry (multi-device support)
- **Sequence numbers**: Monotonic per conversation, never timestamps — guarantees ordering
- **Idempotent operations**: ACKs, sync cursors, and purge are all safe to retry
- **30-day TTL**: Encrypted messages auto-expire; client must persist locally for long-term storage
- **Backward compatible**: Plain-text clients continue working unchanged

---

## 2. Backward Compatibility — Before vs After

### Socket.IO Connection

| Aspect | Before (Plain) | After (E2E) |
|--------|----------------|-------------|
| **Handshake auth** | `{ token: "jwt..." }` | `{ token: "jwt...", capabilities: { e2e: true }, deviceId: "uuid" }` |
| **socket.protocol** | Not set (undefined) | Set to `"e2e"` or `"plain"` by server |
| **Server event on connect** | None | `protocol:resolved` with `{ version: "e2e" }` |
| **Upgrade nudge** | None | `protocol:upgrade_available` sent to plain clients |

### Sending Messages

| Aspect | Before (Plain) | After (E2E) |
|--------|----------------|-------------|
| **Socket event** | `messageReceived` | `message:send` (new event for E2E) |
| **Payload** | `{ conversation_id, message, message_type, ... }` | `{ conversation_id, ciphertext: [{deviceId, body}], type: "e2e" }` |
| **Server storage** | `messages` collection (plaintext) | `encrypted_messages` collection (ciphertext blobs) |
| **Message ID type** | MongoDB ObjectId | MongoDB ObjectId (same) |
| **Ordering** | `created_at` timestamp | `seq_num` (monotonic integer per conversation) |

### Receiving Messages

| Aspect | Before (Plain) | After (E2E) |
|--------|----------------|-------------|
| **Socket event** | Various (via `receiveMessage`) | `message:new` |
| **Payload** | Full message object with plaintext | `{ message_id, conversation_id, seq_num, sender_id, ciphertext: "base64", expires_at }` |
| **Delivery ACK** | Implicit via `messageViewed` | Explicit `message:ack` event → `message:status` callback |
| **Status tracking** | `sent → delivered → read` | `server_received → device_delivered` |

### Offline Message Recovery

| Aspect | Before (Plain) | After (E2E) |
|--------|----------------|-------------|
| **Endpoint** | `POST /chat/sync-offline-messages` | `GET /sync/messages?conversation_id=...&deviceId=...&since=...` |
| **Cursor type** | Timestamp-based | Sequence number-based (no gaps, no duplicates) |
| **Pagination** | Custom | 200 messages per page with `has_more` flag |
| **Per-device** | No (shared) | Yes (each device has independent cursor) |

### Media Upload

| Aspect | Before (Plain) | After (E2E) |
|--------|----------------|-------------|
| **Endpoint** | `GET /s3/generate-upload-urls` | `POST /encrypted-media/upload-url` |
| **S3 ACL** | `public-read` | **No ACL** (private — presigned URL only) |
| **URL expiry** | 30 minutes | 15 minutes |
| **Content** | Raw media file | Client-encrypted blob |
| **Access** | Public URL | Presigned download URL required |

### What Stays the Same

- JWT authentication token format unchanged
- All existing plain-text endpoints (`/chat/*`, `/connections/*`, `/group/*`, etc.) still work
- `messageReceived` socket event still works for plain clients
- Contact/connection/group management APIs unchanged
- Call system (WebRTC signaling) unchanged
- Typing indicators, online status, message views unchanged

---

## 3. Required Flutter Packages

```yaml
dependencies:
  # Signal Protocol implementation
  libsignal_protocol_dart: ^0.7.0   # Signal Protocol (X3DH + Double Ratchet)

  # Secure local storage for keys
  flutter_secure_storage: ^9.0.0     # Keychain (iOS) / Keystore (Android)

  # Local database for messages
  sqflite: ^2.3.0                    # SQLite for local message persistence
  # OR
  hive: ^2.2.3                       # Hive for fast key-value storage

  # Existing packages (already used)
  socket_io_client: ^2.0.0           # Socket.IO
  http: ^1.0.0                       # HTTP client
  firebase_messaging: ^14.0.0        # FCM push

  # Crypto utilities
  pointycastle: ^3.7.0              # AES-256-GCM for media encryption
  convert: ^3.1.0                    # Base64 encoding
  uuid: ^4.0.0                      # Device ID generation
```

---

## 4. Data Models

### 4.1 Device Identity (Local Storage)

```dart
class DeviceIdentity {
  final String deviceId;           // UUID, persisted across app installs
  final String identityKeyPublic;  // Base64, 32-byte Curve25519 public key
  final String identityKeyPrivate; // Base64, stored in secure storage only
  final String signedPrekeyPublic; // Base64, 32-byte Curve25519
  final String signedPrekeyPrivate;// Base64, stored in secure storage only
  final String signedPrekeySignature; // Base64, Ed25519 signature
  final int signedPrekeyId;        // Integer identifier
}
```

### 4.2 One-Time Prekey (Local + Server)

```dart
class OneTimePrekey {
  final int keyId;        // Integer identifier (locally generated, monotonically increasing)
  final String publicKey; // Base64, 32-byte Curve25519 public key
  // Private key stored only in local secure storage
}
```

### 4.3 Prekey Bundle (Fetched from Server)

```dart
class PrekeyBundle {
  final String deviceId;
  final String identityKey;            // Base64, recipient's identity public key
  final String signedPrekey;           // Base64, recipient's signed prekey
  final String signedPrekeySignature;  // Base64
  final int signedPrekeyId;
  final OneTimePrekey? oneTimePrekey;  // May be null if pool exhausted
}
```

### 4.4 Encrypted Message (Local DB)

```dart
class EncryptedMessageLocal {
  final String messageId;        // MongoDB ObjectId string
  final String conversationId;
  final int seqNum;              // Monotonic sequence number
  final String senderId;
  final String? plaintext;       // Decrypted content (null if not yet decrypted)
  final String? ciphertext;      // Raw ciphertext (can be cleared after decryption)
  final List<EncryptedMedia>? encryptedMedia;
  final DateTime expiresAt;      // Server TTL (30 days from creation)
  final String status;           // server_received | device_delivered
  final DateTime createdAt;
}

class EncryptedMedia {
  final String s3Key;            // Opaque S3 object key
  final String? mimeType;
  final int? size;
}
```

### 4.5 Sync Cursor (Local DB)

```dart
class SyncCursor {
  final String conversationId;
  final int lastSyncedSequence;  // Last seq_num successfully synced
}
```

---

## 5. Phase 1: Protocol Versioning & Capability Handshake

### 5.1 Generate & Persist Device ID

On first app launch, generate a stable device UUID and store it permanently:

```dart
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _secureStorage = FlutterSecureStorage();

Future<String> getOrCreateDeviceId() async {
  String? deviceId = await _secureStorage.read(key: 'device_id');
  if (deviceId == null) {
    deviceId = const Uuid().v4();
    await _secureStorage.write(key: 'device_id', value: deviceId);
  }
  return deviceId;
}
```

### 5.2 Socket.IO Connection with Capabilities

**Before (existing plain client):**
```dart
socket = io(serverUrl, OptionBuilder()
  .setTransports(['websocket'])
  .setAuth({'token': jwtToken})
  .build());
```

**After (E2E client):**
```dart
final deviceId = await getOrCreateDeviceId();

socket = io(serverUrl, OptionBuilder()
  .setTransports(['websocket'])
  .setAuth({
    'token': jwtToken,
    'capabilities': {'e2e': true},
    'deviceId': deviceId,
  })
  .build());
```

### 5.3 Handle Protocol Events

```dart
// Server confirms your protocol version after connection
socket.on('protocol:resolved', (data) {
  // data = { "version": "e2e" }  OR  { "version": "plain" }
  final version = data['version'];
  print('Protocol resolved: $version');
  // Store this — use it to decide message send path
});

// Only received by plain clients — prompt user to upgrade
socket.on('protocol:upgrade_available', (data) {
  // data = { "message": "E2E encryption is available. Upgrade your client to enable it." }
  // Show UI prompt to user
});
```

### 5.4 Check Recipient Capability (Optional)

Before initiating an E2E conversation, you can check if the recipient supports E2E:

**`GET /protocol/capability/:userId`**

```
GET /protocol/capability/64f1a2b3c4d5e6f7a8b9c0d1
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "userId": "64f1a2b3c4d5e6f7a8b9c0d1",
    "protocol": "e2e"
  }
}
```

**Response (200) — plain user:**
```json
{
  "success": true,
  "data": {
    "userId": "64f1a2b3c4d5e6f7a8b9c0d1",
    "protocol": "plain"
  }
}
```

If `protocol` is `"plain"`, fall back to existing plaintext messaging for this recipient.

---

## 6. Phase 2: Key Infrastructure — Signal Protocol

### 6.1 Key Generation (Client-Side)

On first setup (or after device wipe), generate all keys using `libsignal_protocol_dart`:

```dart
// 1. Generate identity key pair (long-lived, one per device)
final identityKeyPair = generateIdentityKeyPair();

// 2. Generate signed prekey (rotate periodically, e.g. weekly)
final signedPrekey = generateSignedPreKey(identityKeyPair, signedPrekeyId);

// 3. Generate batch of one-time prekeys (100 initially)
final oneTimePrekeys = generatePreKeys(startId: 0, count: 100);
```

All keys must be **32-byte Curve25519 public keys** encoded as base64. The server validates `Buffer.from(key, 'base64').length === 32`.

### 6.2 Register Keys with Server

**`POST /keys/register`**

Must be called after first login and after any device key reset.

```
POST /keys/register
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "deviceId": "550e8400-e29b-41d4-a716-446655440000",
  "identityKey": "BQ8Zy2N8xKf7p5dL3mR9vT1wY4oA6cE2gI0kM7nP+sU=",
  "signedPrekey": "A1bC3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA7bC=",
  "signedPrekeySignature": "dGhpcyBpcyBhIHNpZ25hdHVyZSBvZiB0aGUgc2lnbmVkIHByZWtleQ==",
  "signedPrekeyId": 1,
  "oneTimePrekeys": [
    { "keyId": 0, "publicKey": "D4eF6gH8iJ0kL2mN4oP6qR8sT0uV2wX4yZ6aB8cD0eF=" },
    { "keyId": 1, "publicKey": "G7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA7bC3dE5fG7hI=" },
    // ... up to 200 keys max
  ]
}
```

**Response (201) — Success:**
```json
{
  "success": true,
  "message": "Keys registered successfully"
}
```

**Response (400) — Invalid key format:**
```json
{
  "success": false,
  "message": "Invalid identityKey: must be a 32-byte base64 Curve25519 public key"
}
```

**Response (422) — Pool size exceeded:**
```json
{
  "success": false,
  "message": "OPK batch size exceeds maximum pool size of 200"
}
```

> **Important:** Re-registration replaces the entire OPK pool. Use `/keys/opks` for incremental replenishment.

### 6.3 Replenish One-Time Prekeys

**`POST /keys/opks`**

Called when `prekey:low` socket event is received, or proactively when pool is low.

```
POST /keys/opks
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "deviceId": "550e8400-e29b-41d4-a716-446655440000",
  "oneTimePrekeys": [
    { "keyId": 100, "publicKey": "J0kL2mN4oP6qR8sT0uV2wX4yZ6aB8cD0eF6gH8iJ0kL=" },
    { "keyId": 101, "publicKey": "M3nO5pQ7rS9tU1vW3xY5zA7bC3dE5fG7hI9jK1lM3nO=" },
    // Generate enough to bring pool back to ~100-200
  ]
}
```

**Response (200) — Success:**
```json
{
  "success": true,
  "message": "OPKs uploaded",
  "data": {
    "count": 150
  }
}
```

`count` is the **new total** in the server pool after upload.

**Response (422) — Pool would overflow:**
```json
{
  "success": false,
  "message": "OPK pool would exceed maximum size of 200 (current: 180, adding: 50)"
}
```

### 6.4 Listen for Prekey Low Warning

```dart
bool _opkReplenishFailed = false; // Guard against infinite retry loop

socket.on('prekey:low', (data) async {
  // data = { "userId": "your_user_id", "remainingCount": 15 }
  final remaining = data['remainingCount'] as int;
  print('OPK pool low: $remaining remaining');

  // IMPORTANT: Guard against retry loops. If replenish fails (422 — pool overflow),
  // the server keeps emitting prekey:low, which triggers replenish again, infinitely.
  if (_opkReplenishFailed) return;

  try {
    final newKeys = generatePreKeys(startId: nextKeyId, count: 50);
    await uploadOpks(deviceId, newKeys);
    _opkReplenishFailed = false;
  } catch (e) {
    print('OPK replenish failed: $e — disabling retries until next session');
    _opkReplenishFailed = true;
  }
});
```

The server fires `prekey:low` when the pool drops to **20 or fewer** OPKs.

> **WARNING:** If `POST /keys/opks` returns 422 (pool overflow), the server will continue emitting `prekey:low` events, creating an infinite retry loop. Always add a guard flag to stop retries after a failure. Reset the flag on next app launch or successful replenish.

### 6.5 Fetch Recipient's Prekey Bundle

**`GET /keys/bundle/:userId`**

Called before sending the **first message** in a new Signal Protocol session with a recipient.

```
GET /keys/bundle/64f1a2b3c4d5e6f7a8b9c0d1
Authorization: Bearer <jwt_token>
```

**Response (200) — Success:**
```json
{
  "success": true,
  "data": {
    "bundles": [
      {
        "deviceId": "550e8400-e29b-41d4-a716-446655440000",
        "identityKey": "BQ8Zy2N8xKf7p5dL3mR9vT1wY4oA6cE2gI0kM7nP+sU=",
        "signedPrekey": "A1bC3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA7bC=",
        "signedPrekeySignature": "dGhpcyBpcyBhIHNpZ25hdHVyZSBvZiB0aGUgc2lnbmVkIHByZWtleQ==",
        "signedPrekeyId": 1,
        "oneTimePrekey": {
          "keyId": 42,
          "publicKey": "D4eF6gH8iJ0kL2mN4oP6qR8sT0uV2wX4yZ6aB8cD0eF="
        }
      },
      {
        "deviceId": "770e8400-e29b-41d4-a716-446655440002",
        "identityKey": "Xq9Zy2N8xKf7p5dL3mR9vT1wY4oA6cE2gI0kM7nP+ab=",
        "signedPrekey": "K8pC3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA7bC=",
        "signedPrekeySignature": "c2Vjb25kIGRldmljZSBzaWduYXR1cmU=",
        "signedPrekeyId": 1,
        "oneTimePrekey": null
      }
    ]
  }
}
```

**Important notes:**
- Returns one bundle **per active device** of the recipient (multi-device)
- `oneTimePrekey` may be `null` if the device's OPK pool is exhausted — session setup still works without it (no forward secrecy for the first message only)
- Fetching a bundle **consumes** one OPK per device (atomic, irreversible)

> **WARNING — Do NOT cache bundles aggressively.** If the recipient re-registers keys (new device, app reinstall, cleared storage), cached bundles will contain stale identity keys. Messages encrypted with stale keys will be **permanently undecryptable** by the recipient. Instead:
> - Always fetch a fresh bundle before sending if the session is older than ~24 hours
> - On decryption failure, the sender should invalidate cached bundles and re-fetch
> - Short-lived in-memory caching (within a single send operation) is fine; persistent caching across sessions is dangerous

### 6.6 Revoke a Device

**`DELETE /keys/device/:deviceId`**

Called when user logs out from a device or wants to de-register it.

```
DELETE /keys/device/550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Device revoked"
}
```

**What happens server-side:**
- Device gets `revokedAt` timestamp (soft-delete)
- All OPKs for this device are deleted immediately
- Device document is permanently deleted after 7 days (TTL index)
- Future bundle fetches will NOT include this device

---

## 7. Phase 3: Encrypted Message Relay

### 7.1 Sending an Encrypted Message

**Step 1: Encrypt for each recipient device**

Using `libsignal_protocol_dart`, encrypt the plaintext for each recipient's device. If the recipient has 2 devices, you produce 2 ciphertext blobs.

```dart
// For each recipient device (from bundle or existing session):
final ciphertextEntries = <Map<String, String>>[];
for (final device in recipientDevices) {
  final session = getOrCreateSession(recipientUserId, device.deviceId);
  final encrypted = session.encrypt(utf8.encode(plaintext));
  ciphertextEntries.add({
    'deviceId': device.deviceId,
    'body': base64Encode(encrypted.serialize()),
  });
}
```

**Step 2: Send via Socket.IO**

```dart
socket.emit('message:send', {
  'conversation_id': conversationId,
  'type': 'e2e',  // REQUIRED — server rejects if missing or not 'e2e'
  'ciphertext': ciphertextEntries,
  // Optional: encrypted media references (see 7.3)
  'encrypted_media': [
    {
      's3_key': 'encrypted-media/a1b2c3d4-...',
      'mime_type': 'image/jpeg',
      'size': 245000,
    }
  ],
});
```

**Step 3: Handle server acknowledgment**

```dart
socket.on('message:status', (data) {
  // data = {
  //   "message_id": "64f1a2b3c4d5e6f7a8b9c0d1",
  //   "status": "server_received",
  //   "seq_num": 42
  // }
  //
  // OR (when recipient ACKs):
  //
  // data = {
  //   "message_id": "64f1a2b3c4d5e6f7a8b9c0d1",
  //   "status": "device_delivered"
  // }

  final messageId = data['message_id'];
  final status = data['status'];
  final seqNum = data['seq_num']; // Only present on server_received

  if (status == 'server_received') {
    // Message stored on server with this seq_num
    // Save messageId + seqNum to local DB
    // Show single-check mark ✓
  } else if (status == 'device_delivered') {
    // Recipient device received the message
    // Show double-check mark ✓✓
  }
});
```

### 7.2 Receiving an Encrypted Message

```dart
// CRITICAL: Track rendered message IDs to deduplicate.
// The server sends one message:new event PER registered device to the same socket.
// If the user has 2 devices (old + current), you will receive 2 events for the
// same message_id with different ciphertext. Only process the first successful one.
final Set<String> _processedE2EMessageIds = {};

socket.on('message:new', (data) async {
  // data = {
  //   "message_id": "64f1a2b3c4d5e6f7a8b9c0d1",
  //   "conversation_id": "60a1b2c3d4e5f6a7b8c9d0e1",
  //   "seq_num": 42,
  //   "sender_id": "55a1b2c3d4e5f6a7b8c9d0e1",
  //   "ciphertext": "CiQKI...<base64 blob>...==",
  //   "expires_at": "2026-04-09T12:00:00.000Z"
  // }

  final messageId = data['message_id'] as String;

  // Deduplicate: skip if already processed (server sends one event per device)
  if (_processedE2EMessageIds.contains(messageId)) return;

  // Send delivery ACK immediately (before decryption)
  socket.emit('message:ack', {'message_id': messageId});

  final ciphertext = base64Decode(data['ciphertext']);

  // Try decryption — may need to try multiple sender bundles/sessions
  String? plaintext;
  try {
    final session = getSession(data['sender_id']);
    plaintext = utf8.decode(session.decrypt(ciphertext));
  } catch (e) {
    // Decryption failed — sender may have multiple devices with different keys.
    // Fetch fresh bundles and try each identity key.
    try {
      final bundles = await fetchFreshBundles(data['sender_id']);
      for (final bundle in bundles) {
        try {
          final session = createSessionFromBundle(bundle);
          plaintext = utf8.decode(session.decrypt(ciphertext));
          break; // Success — stop trying
        } catch (_) {
          continue; // Try next bundle
        }
      }
    } catch (_) {}
  }

  _processedE2EMessageIds.add(messageId);

  if (plaintext == null) {
    // All decryption attempts failed — show placeholder
    // This happens when keys have rotated (recipient reinstalled, etc.)
    saveUndecryptableMessage(messageId, data);
    return;
  }

  // Store decrypted message in local DB
  saveMessageLocally(
    messageId: messageId,
    conversationId: data['conversation_id'],
    seqNum: data['seq_num'],
    senderId: data['sender_id'],
    plaintext: plaintext,
    expiresAt: DateTime.parse(data['expires_at']),
  );

  // Show message in UI
});
```

**Critical implementation notes:**

1. **Deduplication is required.** The server sends one `message:new` event per registered device to the same socket. If the user has 2 devices, you get 2 events with the same `message_id` but different ciphertext (each encrypted for a different device key). Only ONE will decrypt successfully with your current keys. Track processed `message_id` values and skip duplicates.

2. **Try multiple bundles on failure.** The sender may have multiple devices with different identity keys. If decryption with the cached session fails, fetch fresh bundles and try each.

3. **The `ciphertext` field** contains ONLY this device's ciphertext entry (a base64 string), not the full array. The server projects the matching entry during fan-out.

### 7.3 Encrypted Media Upload

**Step 1: Encrypt the file locally**

```dart
// Generate a random AES-256-GCM key for this file
final fileKey = generateRandomKey(32); // 256-bit
final iv = generateRandomIV(12);       // 96-bit nonce

// Encrypt the raw file bytes
final encryptedBytes = aesGcmEncrypt(fileBytes, fileKey, iv);

// Store fileKey + iv locally — you'll include these in the message ciphertext
// so the recipient can decrypt the file
```

**Step 2: Get presigned upload URL**

**`POST /encrypted-media/upload-url`**

```
POST /encrypted-media/upload-url
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "mime_type": "image/jpeg"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "s3_key": "encrypted-media/a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "upload_url": "https://your-bucket.s3.amazonaws.com/encrypted-media/a1b2c3d4-...?X-Amz-Algorithm=..."
  }
}
```

**Response (400) — missing mime_type:**
```json
{
  "success": false,
  "message": "mime_type is required"
}
```

**Step 3: Upload encrypted blob to S3**

```dart
// PUT the encrypted bytes directly to S3 using the presigned URL
final response = await http.put(
  Uri.parse(uploadUrl),
  headers: {'Content-Type': mimeType},
  body: encryptedBytes,
);
// Response should be 200 OK
```

**Step 4: Include media reference in encrypted message**

The media encryption metadata (file key, IV, original filename) goes **inside the encrypted message ciphertext** so only the recipient can decrypt the file:

```dart
// This is the plaintext that gets encrypted via Signal Protocol
final messagePayload = jsonEncode({
  'text': 'Check out this photo!',
  'media': [
    {
      's3_key': s3Key,
      'file_key': base64Encode(fileKey),  // AES key for the file
      'iv': base64Encode(iv),             // Nonce for AES-GCM
      'mime_type': 'image/jpeg',
      'file_name': 'photo.jpg',
      'size': fileBytes.length,
    }
  ]
});

// Encrypt this payload for each device, then send via message:send
// with encrypted_media array referencing the s3_key
socket.emit('message:send', {
  'conversation_id': conversationId,
  'type': 'e2e',
  'ciphertext': perDeviceCiphertexts,
  'encrypted_media': [
    {
      's3_key': s3Key,
      'mime_type': 'image/jpeg',
      'size': encryptedBytes.length,
    }
  ],
});
```

**Step 5: Recipient downloads and decrypts**

```dart
// 1. Decrypt message ciphertext to get media metadata (file_key, iv, s3_key)
// 2. Download encrypted file from S3 (need presigned download URL or direct access)
// 3. Decrypt file using AES-256-GCM with file_key and iv
// 4. Display decrypted media
```

> **Security note:** The `encrypted_media` array in the socket payload is metadata only (s3_key, mime_type, size). The actual encryption key and IV are embedded **inside** the Signal Protocol ciphertext, so the server never sees them.

### 7.4 Error Handling for Message Send

```dart
socket.on('error', (data) {
  // data = { "success": false, "message": "..." }
  //
  // Possible errors:
  // - "message:send only accepts e2e messages"
  //   → You sent type: "plain" on the message:send event
  //
  // - "Protocol mismatch: client is not registered for E2E encryption."
  //   → Your socket connected without capabilities.e2e = true
  //
  // - "Server requires E2E encryption. Plain messages are rejected."
  //   → ENFORCE_E2E is enabled server-side
  //
  // - "Invalid message type. Must be 'e2e' or 'plain'."
  //   → Sent an invalid type value
  //
  // - "Failed to send encrypted message"
  //   → Server-side error during storage/relay
});
```

---

## 8. Phase 4: Offline Sync Engine

### 8.1 How It Works

Each device maintains a **sync cursor** per conversation — the last `seq_num` it has successfully received. When a device comes back online, it pulls all messages with `seq_num > cursor`.

```
Device goes offline at seq_num 40
↓ 3 messages arrive (seq 41, 42, 43)
Device comes back online
↓
GET /sync/messages?conversation_id=X&deviceId=Y&since=40
↓ Returns messages 41, 42, 43
↓
message:sync-complete { conversation_id: X, seq_num: 43, deviceId: Y }
↓ Server persists cursor at 43
↓
sync:complete { conversation_id: X, seq_num: 43 }
```

### 8.2 Pull Missed Messages

**`GET /sync/messages`**

```
GET /sync/messages?conversation_id=60a1b2c3d4e5f6a7b8c9d0e1&deviceId=550e8400-e29b-41d4-a716-446655440000&since=40
Authorization: Bearer <jwt_token>
```

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `conversation_id` | String (ObjectId) | Yes | The conversation to sync |
| `deviceId` | String (UUID) | Yes | Your device ID |
| `since` | Integer (≥ 0) | Yes | Return messages with `seq_num > since` |

**Response (200) — Messages found:**
```json
{
  "success": true,
  "data": {
    "messages": [
      {
        "message_id": "64f1a2b3c4d5e6f7a8b9c0d1",
        "conversation_id": "60a1b2c3d4e5f6a7b8c9d0e1",
        "seq_num": 41,
        "sender_id": "55a1b2c3d4e5f6a7b8c9d0e1",
        "ciphertext": "CiQKI...<base64>...==",
        "encrypted_media": [],
        "expires_at": "2026-04-09T12:00:00.000Z"
      },
      {
        "message_id": "64f1a2b3c4d5e6f7a8b9c0d2",
        "conversation_id": "60a1b2c3d4e5f6a7b8c9d0e1",
        "seq_num": 42,
        "sender_id": "55a1b2c3d4e5f6a7b8c9d0e1",
        "ciphertext": "DjVLJ...<base64>...==",
        "encrypted_media": [
          {
            "s3_key": "encrypted-media/a1b2c3d4-...",
            "mime_type": "image/jpeg",
            "size": 245000
          }
        ],
        "expires_at": "2026-04-09T12:00:00.000Z"
      },
      {
        "message_id": "64f1a2b3c4d5e6f7a8b9c0d3",
        "conversation_id": "60a1b2c3d4e5f6a7b8c9d0e1",
        "seq_num": 43,
        "sender_id": "77a1b2c3d4e5f6a7b8c9d0e1",
        "ciphertext": null,
        "encrypted_media": [],
        "expires_at": "2026-04-09T13:00:00.000Z"
      }
    ],
    "next_seq": 43,
    "has_more": false
  }
}
```

**Response (200) — No new messages:**
```json
{
  "success": true,
  "data": {
    "messages": [],
    "next_seq": 40,
    "has_more": false
  }
}
```

**Response (400) — Missing/invalid params:**
```json
{
  "success": false,
  "message": "since must be a non-negative integer"
}
```

**Response (403) — Not a member:**
```json
{
  "success": false,
  "message": "Not a member of this conversation"
}
```

**Response (403) — Device not registered:**
```json
{
  "success": false,
  "message": "Device not registered to this user"
}
```

**Key details:**
- Maximum **200 messages** per response
- `has_more: true` means there are more messages — make another request with `since` = `next_seq`
- `ciphertext` is `null` when the message doesn't contain a ciphertext entry for your device (e.g., message was sent before your device was registered)
- Messages are sorted by `seq_num` ascending
- `next_seq` is the `seq_num` of the last message in the page (use for next pagination call)

### 8.3 Paginated Sync Loop

```dart
Future<void> syncConversation(String conversationId, String deviceId) async {
  int since = getLocalCursor(conversationId); // From local DB
  bool hasMore = true;

  while (hasMore) {
    final response = await http.get(
      Uri.parse('$baseUrl/sync/messages'
        '?conversation_id=$conversationId'
        '&deviceId=$deviceId'
        '&since=$since'),
      headers: {'Authorization': 'Bearer $jwtToken'},
    );

    final data = jsonDecode(response.body)['data'];
    final messages = data['messages'] as List;
    hasMore = data['has_more'] as bool;
    since = data['next_seq'] as int;

    // Decrypt and store each message locally
    for (final msg in messages) {
      if (msg['ciphertext'] != null) {
        final plaintext = decryptMessage(msg['sender_id'], msg['ciphertext']);
        saveToLocalDb(msg, plaintext);
      }
    }

    // Update local cursor
    saveLocalCursor(conversationId, since);
  }

  // Notify server that sync is complete — server persists cursor
  socket.emit('message:sync-complete', {
    'conversation_id': conversationId,
    'seq_num': since,
    'deviceId': deviceId,
  });
}
```

### 8.4 Acknowledge Sync Completion

**Via Socket.IO (preferred — real-time):**

```dart
// Client sends:
socket.emit('message:sync-complete', {
  'conversation_id': '60a1b2c3d4e5f6a7b8c9d0e1',
  'seq_num': 43,
  'deviceId': '550e8400-e29b-41d4-a716-446655440000',
});

// Server responds (after cursor is persisted to MongoDB):
socket.on('sync:complete', (data) {
  // data = { "conversation_id": "60a1b2c3d4e5f6a7b8c9d0e1", "seq_num": 43 }
  // Safe to mark sync as complete in UI
  // The server AWAITS cursor write before emitting this event (no race condition)
});
```

**Via REST (alternative — for background sync):**

**`POST /sync/ack`**

```
POST /sync/ack
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "conversation_id": "60a1b2c3d4e5f6a7b8c9d0e1",
  "seq_num": 43,
  "deviceId": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response (200):**
```json
{
  "success": true
}
```

**Response (400):**
```json
{
  "success": false,
  "message": "conversation_id, seq_num, and deviceId are required"
}
```

**Cursor safety:**
- Uses MongoDB `$max` operator — cursor can only advance **forward**
- Sending a lower `seq_num` is a safe no-op (idempotent)
- First ACK creates the cursor document automatically (upsert)

### 8.5 When to Trigger Sync

```dart
// 1. On socket reconnection
socket.on('connect', (_) async {
  // Sync all conversations the user participates in
  final conversations = getLocalConversationIds();
  for (final convId in conversations) {
    await syncConversation(convId, deviceId);
  }
});

// 2. On app resume from background
WidgetsBindingObserver.didChangeAppLifecycleState(state) {
  if (state == AppLifecycleState.resumed) {
    syncAllConversations();
  }
}

// 3. On FCM push received while app was killed
// (see FCM section below)
```

---

## 9. Phase 5: Purge Pipeline (No Frontend Work)

The purge pipeline runs entirely server-side. **No client API calls or socket events are involved.**

### What Happens Automatically

1. **Every 60 seconds**: Server queries for conversations with expired messages (`expires_at < now, purged_at = null`)
2. **For each conversation**: Publishes a `chat.purge.due` Kafka event
3. **Purge consumer**: Deletes S3 media objects first, then stamps `purged_at` on the MongoDB document
4. **7 days after purge**: MongoDB TTL index permanently deletes the document
5. **Every 10 minutes**: Orphan reconciliation retries any failed S3 deletes

### Client Implications

- Messages have a **30-day server-side TTL** (configurable via `expires_at`)
- After 30 days, the message is purged from server storage
- **Client must persist messages locally** for long-term access (local SQLite/Hive DB)
- The `expires_at` field in every message tells the client when server storage will expire
- If a client syncs after 30 days of being offline, some messages may already be purged — client should handle `ciphertext: null` gracefully

---

## 10. REST API Reference

### Authentication

All endpoints (except `/hello`) require a Bearer token:

```
Authorization: Bearer <jwt_token>
```

### Complete E2E API List

| Method | Endpoint | Phase | Description |
|--------|----------|-------|-------------|
| `GET` | `/protocol/capability/:userId` | 1 | Get user's protocol version (e2e/plain) |
| `POST` | `/keys/register` | 2 | Register device identity + signed prekey + OPKs |
| `POST` | `/keys/opks` | 2 | Upload additional one-time prekeys |
| `GET` | `/keys/bundle/:userId` | 2 | Fetch prekey bundles for all active devices |
| `DELETE` | `/keys/device/:deviceId` | 2 | Revoke a device (soft-delete) |
| `POST` | `/encrypted-media/upload-url` | 3 | Get presigned S3 PUT URL for encrypted media |
| `GET` | `/sync/messages` | 4 | Paginated sync of missed encrypted messages |
| `POST` | `/sync/ack` | 4 | Advance device sync cursor |

### Error Response Format

All endpoints return errors in this format:

```json
{
  "success": false,
  "message": "Human-readable error description"
}
```

Common HTTP status codes:
- `400` — Bad request (missing/invalid parameters)
- `403` — Forbidden (not a member, device not registered)
- `422` — Unprocessable entity (pool overflow, validation)
- `500` — Internal server error

---

## 11. Socket.IO Events Reference

### Events Client Sends (Client → Server)

| Event | Payload | Phase | Description |
|-------|---------|-------|-------------|
| `message:send` | `{ conversation_id, type: "e2e", ciphertext: [{deviceId, body}], encrypted_media?: [{s3_key, mime_type, size}] }` | 3 | Send encrypted message |
| `message:ack` | `{ message_id }` | 3 | Acknowledge message delivery |
| `message:sync-complete` | `{ conversation_id, seq_num, deviceId }` | 4 | Confirm sync finished |

### Events Client Receives (Server → Client)

| Event | Payload | Phase | Description |
|-------|---------|-------|-------------|
| `protocol:resolved` | `{ version: "e2e" \| "plain" }` | 1 | Protocol confirmed after connection |
| `protocol:upgrade_available` | `{ message: "..." }` | 1 | Nudge for plain clients to upgrade |
| `prekey:low` | `{ userId, remainingCount }` | 2 | OPK pool running low (≤20) — replenish |
| `message:new` | `{ message_id, conversation_id, seq_num, sender_id, ciphertext, expires_at }` | 3 | New encrypted message (per-device ciphertext) |
| `message:status` | `{ message_id, status, seq_num? }` | 3 | Delivery status update |
| `sync:complete` | `{ conversation_id, seq_num }` | 4 | Cursor write confirmed |
| `error` | `{ success: false, message }` | All | Error notification |

### Connection Auth Payload

```json
{
  "token": "<jwt_token>",
  "capabilities": { "e2e": true },
  "deviceId": "550e8400-e29b-41d4-a716-446655440000"
}
```

---

## 12. Complete Message Flow Diagrams

### 12.1 First-Time Setup Flow

```
App Launch (First Time)
    │
    ├── 1. Generate device UUID → store in secure storage
    │
    ├── 2. Generate Signal Protocol keys:
    │       ├── Identity key pair (long-lived)
    │       ├── Signed prekey pair + signature
    │       └── 100 one-time prekeys
    │
    ├── 3. Store private keys in secure storage
    │
    ├── 4. POST /keys/register
    │       ├── deviceId
    │       ├── identityKey (public, base64)
    │       ├── signedPrekey (public, base64)
    │       ├── signedPrekeySignature (base64)
    │       ├── signedPrekeyId
    │       └── oneTimePrekeys: [{keyId, publicKey}, ...]
    │
    └── 5. Connect Socket.IO with:
            ├── token: jwt
            ├── capabilities: { e2e: true }
            └── deviceId: uuid
```

### 12.2 Send Message Flow (Happy Path)

```
Sender                           Server                          Recipient
  │                                │                                │
  │  (If no session exists)        │                                │
  │  GET /keys/bundle/:recipientId │                                │
  │ ──────────────────────────────>│                                │
  │ <── { bundles: [...] } ────────│  (OPK consumed per device)     │
  │                                │                                │
  │  Signal Protocol: establish    │                                │
  │  session + encrypt plaintext   │                                │
  │                                │                                │
  │  socket: message:send          │                                │
  │  { conversation_id,            │                                │
  │    type: "e2e",                │                                │
  │    ciphertext: [{deviceId,     │                                │
  │      body: "base64..."}] }     │                                │
  │ ──────────────────────────────>│                                │
  │                                │  Store in encrypted_messages   │
  │                                │  Assign seq_num atomically     │
  │                                │                                │
  │ <── message:status ────────────│                                │
  │  { message_id, status:         │                                │
  │    "server_received",          │                                │
  │    seq_num: 42 }               │                                │
  │                                │                                │
  │                                │  Fan out per device:           │
  │                                │  message:new ─────────────────>│
  │                                │  { message_id,                 │
  │                                │    conversation_id,            │
  │                                │    seq_num: 42,                │
  │                                │    sender_id,                  │
  │                                │    ciphertext: "base64...",    │
  │                                │    expires_at }                │
  │                                │                                │
  │                                │                  Decrypt msg   │
  │                                │                  Store locally │
  │                                │                                │
  │                                │ <── message:ack ──────────────│
  │                                │  { message_id }               │
  │                                │                                │
  │ <── message:status ────────────│                                │
  │  { message_id, status:         │                                │
  │    "device_delivered" }        │                                │
```

### 12.3 Offline Sync Flow

```
Device comes online
    │
    ├── Socket reconnects with capabilities + deviceId
    │
    ├── For each conversation:
    │       │
    │       ├── Read local cursor: lastSyncedSeq = 40
    │       │
    │       ├── GET /sync/messages?conversation_id=X&deviceId=Y&since=40
    │       │   └── Response: { messages: [...], next_seq: 55, has_more: true }
    │       │
    │       ├── Decrypt + store messages 41-55 locally
    │       │
    │       ├── GET /sync/messages?conversation_id=X&deviceId=Y&since=55
    │       │   └── Response: { messages: [...], next_seq: 63, has_more: false }
    │       │
    │       ├── Decrypt + store messages 56-63 locally
    │       │
    │       └── socket: message:sync-complete { conversation_id: X, seq_num: 63, deviceId: Y }
    │           └── Server responds: sync:complete { conversation_id: X, seq_num: 63 }
    │
    └── Sync complete — resume real-time message:new events
```

### 12.4 Media Send Flow

```
Sender                           Server/S3                       Recipient
  │                                │                                │
  │  1. Encrypt file locally       │                                │
  │     (AES-256-GCM)              │                                │
  │                                │                                │
  │  POST /encrypted-media/        │                                │
  │    upload-url                  │                                │
  │  { mime_type: "image/jpeg" }   │                                │
  │ ──────────────────────────────>│                                │
  │ <── { s3_key, upload_url } ────│                                │
  │                                │                                │
  │  PUT upload_url                │                                │
  │  (encrypted bytes)             │                                │
  │ ────────────────────────────── S3                               │
  │ <── 200 OK ─────────────────── S3                               │
  │                                │                                │
  │  2. Build plaintext payload:   │                                │
  │     { text, media: [{          │                                │
  │       s3_key, file_key,        │                                │
  │       iv, mime_type }] }       │                                │
  │                                │                                │
  │  3. Encrypt payload per device │                                │
  │     (Signal Protocol)          │                                │
  │                                │                                │
  │  socket: message:send          │                                │
  │  { ciphertext: [...],          │                                │
  │    encrypted_media: [{         │                                │
  │      s3_key, mime_type,        │                                │
  │      size }] }                 │                                │
  │ ──────────────────────────────>│  ── message:new ──────────────>│
  │                                │                                │
  │                                │     4. Decrypt Signal msg      │
  │                                │        → get file_key, iv,     │
  │                                │          s3_key                │
  │                                │                                │
  │                                │     5. Download encrypted      │
  │                                │        file from S3            │
  │                                │                                │
  │                                │     6. Decrypt file with       │
  │                                │        AES-256-GCM             │
  │                                │        (file_key + iv)         │
  │                                │                                │
  │                                │     7. Display media           │
```

---

## 13. FCM Push Notifications

### What the Client Receives

When a message arrives for an **offline** device, the server publishes a notification event via the Kafka notification service (same pipeline used for plain messages). The notification service delivers a push to the device.

The notification payload includes:

```json
{
  "data": {
    "type": "encrypted_message",
    "message_id": "64f1a2b3c4d5e6f7a8b9c0d1",
    "conversation_id": "60a1b2c3d4e5f6a7b8c9d0e1",
    "message_type": "text"
  }
}
```

> **Note:** E2E notifications go through the same Kafka `notification.service` topic as plain message notifications (via `sendNotification` in `sendMessage.controller.js`), NOT through direct Firebase Admin SDK calls. This ensures consistent delivery and avoids credential management issues in the chat service.

**No plaintext content** is included in the notification — this preserves E2E privacy. The client must sync and decrypt locally before showing a preview.

### Platform-Specific Behavior

**Android:**
- `priority: "high"` — wakes the app even if Doze mode is active
- App must create a local notification after decrypting the message

**iOS:**
- `content-available: 1` — wakes the app in background silently
- `apns-push-type: "background"` + `apns-priority: "5"` — Apple-compliant background push
- App gets ~30 seconds of background execution time to sync and decrypt
- App must create a local notification using `UNUserNotificationCenter`

### Client Handling

```dart
FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  final data = message.data;

  if (data['type'] == 'encrypted_message') {
    final messageId = data['message_id'];
    final conversationId = data['conversation_id'];

    // 1. Sync the conversation to get the actual message
    await syncConversation(conversationId, deviceId);

    // 2. Decrypt the message
    final decrypted = await decryptLatestMessage(conversationId);

    // 3. Show local notification with decrypted preview
    await showLocalNotification(
      title: getSenderName(decrypted.senderId),
      body: decrypted.plaintext.substring(0, 100),
      conversationId: conversationId,
    );
  }
}
```

---

## 14. Error Handling & Edge Cases

### 14.1 Key Exhaustion

When a device's OPK pool is empty, `fetchBundle` returns `oneTimePrekey: null` for that device. The Signal Protocol session can still be established but **without forward secrecy for the first message**. Client should:
- Still proceed with session setup
- Replenish OPKs as soon as possible

### 14.2 Device Revocation

When a user revokes a device:
- The device's keys are deleted
- Future bundle fetches exclude the revoked device
- Existing sessions to the revoked device will fail — sender should re-fetch bundle
- The revoked device can still decrypt messages already received (local keys persist)

### 14.3 Session Not Found

If the client receives a `message:new` but doesn't have a Signal Protocol session for the sender:
- This can happen on a new device or after clearing app data
- The message `ciphertext` contains a `PreKeySignalMessage` that establishes a new session
- `libsignal_protocol_dart` handles this automatically if the local identity/signed prekey are available

### 14.4 Message Expired on Server

If a device is offline for >30 days:
- Some messages may have been purged from the server
- `GET /sync/messages` will return only non-purged messages
- There may be gaps in `seq_num` — client should not treat gaps as errors
- Client should show "Some messages may have expired" UI for conversations with seq_num gaps

### 14.5 Multi-Device Considerations

- Each device maintains its **own sync cursor** per conversation
- Each device receives its **own ciphertext** (encrypted specifically for that device)
- Sender must encrypt the message for **all active devices** of the recipient
- If the sender doesn't have a ciphertext entry for a device (e.g., new device registered after send), that device will see `ciphertext: null` in sync results

### 14.6 Network Errors During Sync

- Sync is safe to retry — cursor only advances forward via `$max`
- Duplicate messages won't be created (use `message_id` as dedup key in local DB)
- If `message:sync-complete` socket event fails, use `POST /sync/ack` REST endpoint as fallback

### 14.7 Concurrent Sends

- `seq_num` is assigned atomically via MongoDB `$inc` — no conflicts
- Multiple devices sending to the same conversation simultaneously are safe
- Messages always arrive in `seq_num` order during sync

### 14.8 Block Enforcement for E2E Messages

When User A blocks User B in a 1:1 conversation, the server enforces the block at the E2E relay level:

- **Blocked sender sends `message:send`**: The server returns a fake `message:status { status: "server_received" }` ACK but does NOT store, fan-out, or deliver the message. The blocked sender's client sees the message as "sent" — they are not aware they are blocked.
- **No decryption impact**: Since the message is never stored, it never appears in sync results. The block is transparent to the sender's client.
- **See also**: `docs/report-block-integration-guide.md` for the full block/report feature integration guide.

### 14.9 Undecryptable Messages (Key Rotation)

When a user reinstalls the app, clears storage, or re-registers keys, their identity key pair changes. Old messages encrypted for the previous keys become permanently undecryptable. The client should:

- Show a distinct UI for undecryptable messages (e.g., "Encrypted with different keys" or "Sent from another device")
- NOT show error states — this is expected behavior, not a bug
- Old messages from the user's own previous device sessions will have no ciphertext for the current deviceId (`ciphertext: null` in sync results)

---

## 15. Local Storage Requirements

### 15.1 Secure Storage (Keychain/Keystore)

Store these using `flutter_secure_storage`:

| Key | Value | When Written |
|-----|-------|--------------|
| `device_id` | UUID string | First app launch |
| `identity_key_private` | Base64, 32 bytes | First key generation |
| `identity_key_public` | Base64, 32 bytes | First key generation |
| `signed_prekey_private` | Base64, 32 bytes | Key generation/rotation |
| `signed_prekey_id` | Integer | Key generation/rotation |
| `next_opk_id` | Integer | After each OPK batch generation |

### 15.2 Local Database (SQLite/Hive)

**Messages Table:**

| Column | Type | Description |
|--------|------|-------------|
| `message_id` | TEXT PRIMARY KEY | MongoDB ObjectId |
| `conversation_id` | TEXT | Conversation reference |
| `seq_num` | INTEGER | Monotonic sequence number |
| `sender_id` | TEXT | Sender user ID |
| `plaintext` | TEXT | Decrypted message content |
| `encrypted_media` | TEXT (JSON) | Media metadata array |
| `expires_at` | TEXT (ISO8601) | Server expiry timestamp |
| `status` | TEXT | server_received / device_delivered |
| `created_at` | TEXT (ISO8601) | When received |

**Sync Cursors Table:**

| Column | Type | Description |
|--------|------|-------------|
| `conversation_id` | TEXT PRIMARY KEY | Conversation reference |
| `last_synced_seq` | INTEGER | Last synced sequence number |

**Signal Sessions Table:**

| Column | Type | Description |
|--------|------|-------------|
| `address` | TEXT PRIMARY KEY | `{userId}:{deviceId}` |
| `session_data` | BLOB | Serialized Signal Protocol session |

**OPK Tracking Table:**

| Column | Type | Description |
|--------|------|-------------|
| `key_id` | INTEGER PRIMARY KEY | OPK key ID |
| `public_key` | TEXT | Base64 public key |
| `private_key` | TEXT | Base64 private key (encrypted at rest) |
| `uploaded` | INTEGER | 1 if uploaded to server |

---

## 16. Testing Checklist

### Phase 1: Protocol Versioning
- [ ] Socket connects with `capabilities: { e2e: true }` and `deviceId`
- [ ] `protocol:resolved` event received with `version: "e2e"`
- [ ] Plain client still connects and works normally
- [ ] Plain client receives `protocol:upgrade_available` event
- [ ] `GET /protocol/capability/:userId` returns correct protocol

### Phase 2: Key Infrastructure
- [ ] Device generates valid 32-byte Curve25519 keys
- [ ] `POST /keys/register` succeeds with 201
- [ ] `POST /keys/register` rejects invalid key format (400)
- [ ] `POST /keys/opks` adds to pool (not replaces)
- [ ] `POST /keys/opks` rejects pool overflow >200 (422)
- [ ] `GET /keys/bundle/:userId` returns per-device bundles
- [ ] OPK is consumed (removed) after bundle fetch
- [ ] `prekey:low` socket event fires when pool ≤ 20
- [ ] `DELETE /keys/device/:deviceId` soft-deletes device
- [ ] Revoked device excluded from future bundle fetches

### Phase 3: Encrypted Messaging
- [ ] `message:send` with per-device ciphertext succeeds
- [ ] `message:status` with `server_received` + `seq_num` received
- [ ] `message:new` received by recipient with correct per-device ciphertext
- [ ] `message:ack` triggers `message:status` with `device_delivered` to sender
- [ ] Duplicate `message:ack` is no-op (idempotent)
- [ ] Plain message rejected on `message:send` event
- [ ] `POST /encrypted-media/upload-url` returns presigned URL
- [ ] Encrypted file uploads to S3 via presigned URL
- [ ] Offline recipient receives FCM data-only push
- [ ] FCM push contains no notification block (privacy)

### Phase 4: Offline Sync
- [ ] `GET /sync/messages` returns messages since cursor
- [ ] Pagination works with `has_more` and `next_seq`
- [ ] Maximum 200 messages per page
- [ ] Returns only requesting device's ciphertext
- [ ] `ciphertext: null` for messages without entry for this device
- [ ] 403 if not conversation member
- [ ] 403 if device not registered to user
- [ ] `message:sync-complete` persists cursor to MongoDB
- [ ] `sync:complete` event confirms cursor is durable
- [ ] `POST /sync/ack` works as REST alternative
- [ ] Lower seq_num ACK is no-op (monotonic cursor)
- [ ] Multiple devices sync independently

### Phase 5: Purge (Server-Side Only)
- [ ] Verify `expires_at` field is set on all encrypted messages (30 days)
- [ ] After expiry, messages no longer returned by sync endpoint
- [ ] Client handles `ciphertext: null` gracefully for expired messages

### End-to-End
- [ ] Full send → receive → ACK cycle works
- [ ] Full offline → sync → decrypt cycle works
- [ ] Media send → upload → receive → download → decrypt works
- [ ] Multi-device: both devices receive separate ciphertext
- [ ] New device syncs all missed messages after key registration
- [ ] Key rotation (re-register) doesn't break existing sessions
