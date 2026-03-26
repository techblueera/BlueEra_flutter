import 'package:flutter/foundation.dart';

import '../../../features/chat/auth/model/e2e_models.dart';
import '../../../features/chat/auth/repo/e2e_repo.dart';
import '../../../features/chat/auth/socket/chat_socket.dart';
import 'e2e_key_service.dart';
import 'e2e_local_db_service.dart';
import 'e2e_session_service.dart';

/// Offline sync engine — Phase 4 of the E2E integration guide.
///
/// On reconnect (or app resume), pulls all missed encrypted messages from
/// GET /sync/messages using per-device cursors, decrypts them locally,
/// and acknowledges the server via `message:sync-complete`.
class E2ESyncService {
  static final E2ESyncService _instance = E2ESyncService._internal();
  factory E2ESyncService() => _instance;
  E2ESyncService._internal();

  final _db         = E2ELocalDbService();
  final _repo       = E2ERepo();
  final _sessions   = E2ESessionService();
  final _keyService = E2EKeyService();
  final _socket     = ChatSocketService();

  bool _syncInProgress = false;

  // ─── Sync All Conversations ────────────────────────────────────────────────

  /// Triggered on socket reconnect or app resume.
  /// Syncs every conversation this device has ever participated in.
  Future<void> syncAllConversations() async {
    if (_syncInProgress) return;
    _syncInProgress = true;
    try {
      final conversationIds = await _db.getAllTrackedConversationIds();
      for (final convId in conversationIds) {
        await syncConversation(convId);
      }
    } finally {
      _syncInProgress = false;
    }
  }

  // ─── Sync Single Conversation ──────────────────────────────────────────────

  /// Paginated sync loop for one conversation.
  /// After all pages are fetched and decrypted, emits `message:sync-complete`.
  ///
  /// Returns the list of newly decrypted messages (for updating UI).
  Future<List<EncryptedMessageLocal>> syncConversation(
    String conversationId,
  ) async {
    final deviceId      = await _keyService.getOrCreateDeviceId();
    int   since         = await _db.getSyncCursor(conversationId);
    bool  hasMore       = true;
    final newMessages   = <EncryptedMessageLocal>[];

    try {
      while (hasMore) {
        final syncResp = await _repo.syncMessages(
          conversationId: conversationId,
          deviceId: deviceId,
          since: since,
        );

        if (syncResp == null) break;

        for (final msg in syncResp.messages) {
          // Dedup — skip already stored messages
          if (await _db.messageExists(msg.messageId)) continue;

          // Decrypt if ciphertext is present
          EncryptedMessageLocal processed = msg;
          if (msg.ciphertext != null && msg.ciphertext!.isNotEmpty) {
            // Use the sender's device ID from server response (NOT our local deviceId)
            final senderDevice = msg.senderDeviceId ?? msg.senderId;
            final plainJson = await _sessions.decryptMessage(
              senderUserId:    msg.senderId,
              senderDeviceId:  senderDevice,
              ciphertextBase64: msg.ciphertext!,
            );
            if (plainJson != null) {
              final payload = E2EMessagePayload.fromJsonString(plainJson);
              processed = EncryptedMessageLocal(
                messageId:      msg.messageId,
                conversationId: msg.conversationId,
                seqNum:         msg.seqNum,
                senderId:       msg.senderId,
                senderDeviceId: msg.senderDeviceId,
                plaintext:      payload.text,
                ciphertext:     null, // cleared after decrypt
                encryptedMedia: msg.encryptedMedia,
                expiresAt:      msg.expiresAt,
                status:         'device_delivered',
                createdAt:      msg.createdAt,
              );
            }
          }

          await _db.upsertMessage(processed);
          newMessages.add(processed);
        }

        // Advance local cursor
        since = syncResp.nextSeq;
        await _db.advanceSyncCursor(conversationId, since);

        hasMore = syncResp.hasMore;
      }

      // Notify server that sync is complete — server persists cursor
      if (newMessages.isNotEmpty) {
        _socket.sendSyncComplete(
          conversationId: conversationId,
          seqNum:         since,
          deviceId:       deviceId,
        );
      }
    } catch (e) {
      if (kDebugMode) print('[E2E] syncConversation error ($conversationId): $e');
      // Fallback: ack via REST instead of socket
      if (since > 0) {
        await _repo.syncAck(
          conversationId: conversationId,
          seqNum: since,
          deviceId: deviceId,
        );
      }
    }

    return newMessages;
  }

  // ─── Register Conversation for Tracking ───────────────────────────────────

  /// Call this when a new conversation starts so it gets picked up by
  /// [syncAllConversations] on the next reconnect.
  Future<void> trackConversation(String conversationId) async {
    // Ensure a cursor row exists (advances nothing, just creates the row)
    final existing = await _db.getSyncCursor(conversationId);
    if (existing == 0) {
      await _db.advanceSyncCursor(conversationId, 0);
    }
  }

  // ─── Handle Incoming Real-Time Message ────────────────────────────────────

  /// Called from ChatSocketService when `message:new` arrives.
  /// Decrypts, stores locally, and returns the message for UI update.
  /// Never returns null for valid messages — shows placeholder if decryption fails.
  Future<EncryptedMessageLocal?> handleIncomingMessage(
    Map<String, dynamic> data,
  ) async {
    try {
      if (kDebugMode) print('[E2E] handleIncomingMessage data keys: ${data.keys}');

      final msg = EncryptedMessageLocal.fromServerJson(data);
      if (kDebugMode) print('[E2E] Parsed message: id=${msg.messageId}, conv=${msg.conversationId}, sender=${msg.senderId}, hasCipher=${msg.ciphertext != null}');

      // Dedup guard
      if (await _db.messageExists(msg.messageId)) {
        if (kDebugMode) print('[E2E] Message ${msg.messageId} already exists — skipping');
        return null;
      }

      // Advance cursor to track this message
      await _db.advanceSyncCursor(msg.conversationId, msg.seqNum);

      // If no ciphertext, store as-is (e.g. system message or no entry for this device)
      if (msg.ciphertext == null || msg.ciphertext!.isEmpty) {
        if (kDebugMode) print('[E2E] No ciphertext — storing as-is');
        await _db.upsertMessage(msg);
        return msg;
      }

      // Attempt decryption
      String? plaintext;
      try {
        final senderDevice = msg.senderDeviceId ?? msg.senderId;
        final plainJson = await _sessions.decryptMessage(
          senderUserId:     msg.senderId,
          senderDeviceId:   senderDevice,
          ciphertextBase64: msg.ciphertext!,
        );
        if (plainJson != null) {
          plaintext = E2EMessagePayload.fromJsonString(plainJson).text;
        }
        if (kDebugMode) print('[E2E] Decryption ${plaintext != null ? "succeeded" : "returned null"}');
      } catch (e) {
        if (kDebugMode) print('[E2E] Decryption failed: $e');
        // Don't rethrow — store with placeholder text so message still shows in UI
      }

      final result = EncryptedMessageLocal(
        messageId:      msg.messageId,
        conversationId: msg.conversationId,
        seqNum:         msg.seqNum,
        senderId:       msg.senderId,
        senderDeviceId: msg.senderDeviceId,
        plaintext:      plaintext,
        ciphertext:     plaintext != null ? null : msg.ciphertext, // keep cipher if decryption failed
        encryptedMedia: msg.encryptedMedia,
        expiresAt:      msg.expiresAt,
        status:         'device_delivered',
        createdAt:      msg.createdAt,
      );

      await _db.upsertMessage(result);
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[E2E] handleIncomingMessage error: $e');
        print('[E2E] Stack: $stackTrace');
      }
      return null;
    }
  }

  // ─── Handle message:status ─────────────────────────────────────────────────

  Future<void> handleMessageStatus(Map<String, dynamic> data) async {
    final messageId = data['message_id'] as String?;
    final status    = data['status'] as String?;
    if (messageId == null || status == null) return;
    await _db.updateMessageStatus(messageId: messageId, status: status);
  }
}
