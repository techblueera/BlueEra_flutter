import 'dart:convert';

// ─────────────────────────────────────────────
// Phase 1: Protocol
// ─────────────────────────────────────────────

enum E2EProtocol { e2e, plain }

class ProtocolCapability {
  final String userId;
  final E2EProtocol protocol;

  ProtocolCapability({required this.userId, required this.protocol});

  factory ProtocolCapability.fromJson(Map<String, dynamic> json) {
    return ProtocolCapability(
      userId: json['userId'],
      protocol: json['protocol'] == 'e2e' ? E2EProtocol.e2e : E2EProtocol.plain,
    );
  }
}

// ─────────────────────────────────────────────
// Phase 2: Key Infrastructure
// ─────────────────────────────────────────────

/// Local representation of this device's identity (public parts only).
/// Private keys are stored in FlutterSecureStorage.
class DeviceIdentity {
  final String deviceId;
  final String identityKeyPublic;   // Base64 Curve25519 public key
  final String signedPrekeyPublic;  // Base64 Curve25519 public key
  final String signedPrekeySignature; // Base64 Ed25519 signature
  final int signedPrekeyId;

  const DeviceIdentity({
    required this.deviceId,
    required this.identityKeyPublic,
    required this.signedPrekeyPublic,
    required this.signedPrekeySignature,
    required this.signedPrekeyId,
  });
}

/// A one-time prekey (public part only; private stored in SQLite/SecureStorage).
class OneTimePrekey {
  final int keyId;
  final String publicKey; // Base64 Curve25519

  const OneTimePrekey({required this.keyId, required this.publicKey});

  Map<String, dynamic> toJson() => {'keyId': keyId, 'publicKey': publicKey};

  factory OneTimePrekey.fromJson(Map<String, dynamic> json) =>
      OneTimePrekey(keyId: json['keyId'], publicKey: json['publicKey']);
}

/// Prekey bundle received from server for a recipient device.
class PrekeyBundle {
  final String deviceId;
  final String identityKey;           // Base64
  final String signedPrekey;          // Base64
  final String signedPrekeySignature; // Base64
  final int signedPrekeyId;
  final OneTimePrekey? oneTimePrekey; // null if OPK pool exhausted

  const PrekeyBundle({
    required this.deviceId,
    required this.identityKey,
    required this.signedPrekey,
    required this.signedPrekeySignature,
    required this.signedPrekeyId,
    this.oneTimePrekey,
  });

  factory PrekeyBundle.fromJson(Map<String, dynamic> json) {
    return PrekeyBundle(
      deviceId: json['deviceId'],
      identityKey: json['identityKey'],
      signedPrekey: json['signedPrekey'],
      signedPrekeySignature: json['signedPrekeySignature'],
      signedPrekeyId: json['signedPrekeyId'],
      oneTimePrekey: json['oneTimePrekey'] != null
          ? OneTimePrekey.fromJson(json['oneTimePrekey'])
          : null,
    );
  }
}

// ─────────────────────────────────────────────
// Phase 3: Encrypted Message Relay
// ─────────────────────────────────────────────

/// Per-device ciphertext entry sent in message:send payload.
class CiphertextEntry {
  final String deviceId;
  final String body; // Base64 serialized Signal Protocol ciphertext

  const CiphertextEntry({required this.deviceId, required this.body});

  Map<String, dynamic> toJson() => {'deviceId': deviceId, 'body': body};
}

/// Encrypted media reference included in message:send socket payload.
/// The actual encryption key/IV goes inside the Signal Protocol ciphertext.
class EncryptedMediaRef {
  final String s3Key;
  final String? mimeType;
  final int? size;

  const EncryptedMediaRef({required this.s3Key, this.mimeType, this.size});

  Map<String, dynamic> toJson() => {
        's3_key': s3Key,
        if (mimeType != null) 'mime_type': mimeType,
        if (size != null) 'size': size,
      };

  factory EncryptedMediaRef.fromJson(Map<String, dynamic> json) =>
      EncryptedMediaRef(
        s3Key: json['s3_key'],
        mimeType: json['mime_type'],
        size: json['size'],
      );
}

/// Metadata embedded INSIDE the NaCl box ciphertext for a media message.
/// Only the recipient can decrypt this (server never sees file_key).
/// Matches web tester format: { s3_key, file_key, mime_type, name, size }
class EncryptedMediaMetadata {
  final String s3Key;
  final String fileKey; // Base64, 32-byte NaCl secretbox key
  final String iv;      // Unused for NaCl (nonce is prepended to blob), kept for compat
  final String mimeType;
  final String? fileName;
  final int? size;

  const EncryptedMediaMetadata({
    required this.s3Key,
    required this.fileKey,
    this.iv = '',
    required this.mimeType,
    this.fileName,
    this.size,
  });

  Map<String, dynamic> toJson() => {
        's3_key': s3Key,
        'file_key': fileKey,
        'mime_type': mimeType,
        if (fileName != null) 'name': fileName,
        if (size != null) 'size': size,
      };

  factory EncryptedMediaMetadata.fromJson(Map<String, dynamic> json) =>
      EncryptedMediaMetadata(
        s3Key: json['s3_key'] ?? '',
        fileKey: json['file_key'] ?? '',
        iv: json['iv'] ?? '',
        mimeType: json['mime_type'] ?? 'application/octet-stream',
        fileName: json['name'] ?? json['file_name'],
        size: json['size'],
      );
}

/// Plaintext payload structure (JSON-encoded then encrypted via Signal Protocol).
class E2EMessagePayload {
  final String? text;
  final List<EncryptedMediaMetadata>? media;

  const E2EMessagePayload({this.text, this.media});

  Map<String, dynamic> toJson() => {
        if (text != null) 'text': text,
        if (media != null)
          'media': media!.map((m) => m.toJson()).toList(),
      };

  factory E2EMessagePayload.fromJson(Map<String, dynamic> json) =>
      E2EMessagePayload(
        text: json['text'],
        media: (json['media'] as List?)
            ?.map((m) => EncryptedMediaMetadata.fromJson(m))
            .toList(),
      );

  String toJsonString() => jsonEncode(toJson());

  factory E2EMessagePayload.fromJsonString(String s) =>
      E2EMessagePayload.fromJson(jsonDecode(s));
}

// ─────────────────────────────────────────────
// Phase 4: Sync Engine
// ─────────────────────────────────────────────

/// A locally stored decrypted (or pending-decryption) E2E message.
class EncryptedMessageLocal {
  final String messageId;
  final String conversationId;
  final int seqNum;
  final String senderId;
  final String? senderDeviceId;  // Sender's device UUID (needed for Signal Protocol decryption)
  final String? plaintext;       // Decrypted text content
  final String? ciphertext;      // Raw ciphertext (cleared after decrypt)
  final List<EncryptedMediaRef>? encryptedMedia;
  final DateTime expiresAt;
  final String status;           // server_received | device_delivered
  final DateTime createdAt;

  const EncryptedMessageLocal({
    required this.messageId,
    required this.conversationId,
    required this.seqNum,
    required this.senderId,
    this.senderDeviceId,
    this.plaintext,
    this.ciphertext,
    this.encryptedMedia,
    required this.expiresAt,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'message_id': messageId,
        'conversation_id': conversationId,
        'seq_num': seqNum,
        'sender_id': senderId,
        'sender_device_id': senderDeviceId,
        'plaintext': plaintext,
        'ciphertext': ciphertext,
        'encrypted_media': encryptedMedia != null
            ? jsonEncode(encryptedMedia!.map((e) => e.toJson()).toList())
            : null,
        'expires_at': expiresAt.toIso8601String(),
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  factory EncryptedMessageLocal.fromMap(Map<String, dynamic> m) =>
      EncryptedMessageLocal(
        messageId: m['message_id'],
        conversationId: m['conversation_id'],
        seqNum: m['seq_num'],
        senderId: m['sender_id'],
        senderDeviceId: m['sender_device_id'],
        plaintext: m['plaintext'],
        ciphertext: m['ciphertext'],
        encryptedMedia: m['encrypted_media'] != null
            ? (jsonDecode(m['encrypted_media']) as List)
                .map((e) => EncryptedMediaRef.fromJson(e))
                .toList()
            : null,
        expiresAt: DateTime.parse(m['expires_at']),
        status: m['status'],
        createdAt: DateTime.parse(m['created_at']),
      );

  /// Build from the server's message:new / sync response format.
  factory EncryptedMessageLocal.fromServerJson(Map<String, dynamic> json) =>
      EncryptedMessageLocal(
        messageId: json['message_id'],
        conversationId: json['conversation_id'],
        seqNum: json['seq_num'],
        senderId: json['sender_id'],
        senderDeviceId: json['sender_device_id'],
        ciphertext: json['ciphertext'],
        encryptedMedia: (json['encrypted_media'] as List?)
            ?.map((e) => EncryptedMediaRef.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        expiresAt: DateTime.parse(json['expires_at']),
        status: 'server_received',
        createdAt: DateTime.now(),
      );
}

/// Tracks the last synced seq_num per conversation per device.
class SyncCursor {
  final String conversationId;
  final int lastSyncedSequence;

  const SyncCursor({
    required this.conversationId,
    required this.lastSyncedSequence,
  });
}

/// Response from GET /sync/messages
class SyncMessagesResponse {
  final List<EncryptedMessageLocal> messages;
  final int nextSeq;
  final bool hasMore;

  const SyncMessagesResponse({
    required this.messages,
    required this.nextSeq,
    required this.hasMore,
  });

  factory SyncMessagesResponse.fromJson(Map<String, dynamic> data) =>
      SyncMessagesResponse(
        messages: (data['messages'] as List)
            .map((m) => EncryptedMessageLocal.fromServerJson(m))
            .toList(),
        nextSeq: data['next_seq'],
        hasMore: data['has_more'],
      );
}

// ─────────────────────────────────────────────
// OPK local record (persisted to SQLite)
// ─────────────────────────────────────────────

class OPKRecord {
  final int keyId;
  final String publicKeyBase64;
  final String privateKeyBase64;
  final bool uploaded;

  const OPKRecord({
    required this.keyId,
    required this.publicKeyBase64,
    required this.privateKeyBase64,
    required this.uploaded,
  });

  Map<String, dynamic> toMap() => {
        'key_id': keyId,
        'public_key': publicKeyBase64,
        'private_key': privateKeyBase64,
        'uploaded': uploaded ? 1 : 0,
      };

  factory OPKRecord.fromMap(Map<String, dynamic> m) => OPKRecord(
        keyId: m['key_id'],
        publicKeyBase64: m['public_key'],
        privateKeyBase64: m['private_key'],
        uploaded: m['uploaded'] == 1,
      );
}
