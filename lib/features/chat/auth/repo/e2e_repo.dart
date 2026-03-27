import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:flutter/foundation.dart';

import '../model/e2e_models.dart';

/// Repository for all E2E encryption REST API calls.
/// Follows the same pattern as [ChatViewRepo] (extends [BaseService]).
class E2ERepo extends BaseService {
  // ─── Phase 1: Protocol Versioning ──────────────────────────────────────────

  /// GET /protocol/capability/:userId
  /// Returns whether the user supports 'e2e' or 'plain' messaging.
  Future<ProtocolCapability?> getCapability(String userId) async {
    try {
      final response = await ApiBaseHelper().getHTTP(
        e2eCapability(userId),
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );
      if (response.isSuccess && response.data != null) {
        return ProtocolCapability.fromJson(Map<String, dynamic>.from(response.data));
      }
    } catch (e) {
      if (kDebugMode) print('[E2E] getCapability error: $e');
    }
    return null;
  }

  // ─── Phase 2: Key Infrastructure ───────────────────────────────────────────

  /// POST /keys/register
  /// Register device identity key, signed prekey, and initial OPK pool.
  Future<bool> registerKeys({
    required String deviceId,
    required String identityKey,
    required String signedPrekey,
    required String signedPrekeySignature,
    required int signedPrekeyId,
    String? signingVerifyKey,
    required List<OneTimePrekey> oneTimePrekeys,
  }) async {
    try {
      if (kDebugMode) {
        print('[E2E-REG] POST /keys/register deviceId=$deviceId');
        print('[E2E-REG] identityKey=${identityKey.substring(0, 20)}... (${identityKey.length} chars)');
        print('[E2E-REG] signedPrekey=${signedPrekey.substring(0, 20)}... (${signedPrekey.length} chars)');
        print('[E2E-REG] OPK count: ${oneTimePrekeys.length}');
      }
      final params = <String, dynamic>{
          'deviceId':              deviceId,
          'identityKey':           identityKey,
          'signedPrekey':          signedPrekey,
          'signedPrekeySignature': signedPrekeySignature,
          'signedPrekeyId':        signedPrekeyId,
          'oneTimePrekeys':        oneTimePrekeys.map((k) => k.toJson()).toList(),
      };
      if (signingVerifyKey != null) {
        params['signingVerifyKey'] = signingVerifyKey;
      }
      final response = await ApiBaseHelper().postHTTP(
        e2eKeysRegister,
        isMultipart: false,
        showProgress: false,
        params: params,
        onError: (e) { if (kDebugMode) print('[E2E-REG] Server error: $e'); },
        onSuccess: (_) { if (kDebugMode) print('[E2E-REG] Server accepted keys'); },
      );
      if (kDebugMode) print('[E2E-REG] isSuccess: ${response.isSuccess}');
      return response.isSuccess;
    } catch (e) {
      if (kDebugMode) print('[E2E] registerKeys exception: $e');
      return false;
    }
  }

  /// POST /keys/opks
  /// Upload additional one-time prekeys (incremental replenishment).
  Future<bool> uploadOPKs({
    required String deviceId,
    required List<OneTimePrekey> oneTimePrekeys,
  }) async {
    try {
      final response = await ApiBaseHelper().postHTTP(
        e2eKeysOpks,
        isMultipart: false,
        showProgress: false,
        params: {
          'deviceId':       deviceId,
          'oneTimePrekeys': oneTimePrekeys.map((k) => k.toJson()).toList(),
        },
        onError: (e) { if (kDebugMode) print('[E2E] uploadOPKs error: $e'); },
        onSuccess: (_) {},
      );
      return response.isSuccess;
    } catch (e) {
      if (kDebugMode) print('[E2E] uploadOPKs exception: $e');
      return false;
    }
  }

  /// GET /keys/bundle/:userId
  /// Fetch prekey bundles for all active devices of a recipient.
  /// Consuming a bundle uses one OPK per device (irreversible).
  Future<List<PrekeyBundle>> getPrekeyBundles(String recipientUserId) async {
    try {
      final response = await ApiBaseHelper().getHTTP(
        e2eKeysBundle(recipientUserId),
        showProgress: false,
        onError: (e) { if (kDebugMode) print('[E2E] getPrekeyBundles error: $e'); },
        onSuccess: (_) {},
      );
      if (response.isSuccess && response.data != null) {
        final bundles = response.data['bundles'] as List?;
        if (bundles != null) {
          return bundles.map((b) => PrekeyBundle.fromJson(Map<String, dynamic>.from(b))).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('[E2E] getPrekeyBundles exception: $e');
    }
    return [];
  }

  /// DELETE /keys/device/:deviceId
  /// Revoke this device (called on logout).
  Future<bool> revokeDevice(String deviceId) async {
    try {
      final response = await ApiBaseHelper().deleteHTTP(
        e2eKeysDevice(deviceId),
        showProgress: false,
        onError: (e) { if (kDebugMode) print('[E2E] revokeDevice error: $e'); },
        onSuccess: (_) {},
      );
      return response.isSuccess;
    } catch (e) {
      if (kDebugMode) print('[E2E] revokeDevice exception: $e');
      return false;
    }
  }

  // ─── Phase 3: Encrypted Media ───────────────────────────────────────────────

  /// POST /encrypted-media/upload-url
  /// Returns { s3_key, upload_url } for a presigned S3 PUT.
  Future<Map<String, String>?> getEncryptedMediaUploadUrl({
    required String mimeType,
  }) async {
    try {
      final response = await ApiBaseHelper().postHTTP(
        e2eEncryptedMediaUploadUrl,
        isMultipart: false,
        showProgress: false,
        params: {'mime_type': mimeType},
        onError: (e) { if (kDebugMode) print('[E2E] getEncryptedMediaUploadUrl error: $e'); },
        onSuccess: (_) {},
      );
      if (response.isSuccess && response.data != null) {
        final data = response.data;
        return {
          's3_key':     data['s3_key'] as String,
          'upload_url': data['upload_url'] as String,
        };
      }
    } catch (e) {
      if (kDebugMode) print('[E2E] getEncryptedMediaUploadUrl exception: $e');
    }
    return null;
  }

  /// GET presigned download URL for an encrypted media object.
  /// Reuses the existing generateDownloadUrls endpoint, or
  /// falls back to a direct S3 URL construction if the server
  /// exposes a dedicated encrypted media download endpoint.
  Future<String?> getEncryptedMediaDownloadUrl({required String s3Key}) async {
    try {
      final response = await ApiBaseHelper().getHTTP(
        generateDownloadUrls,
        showProgress: false,
        params: {'s3_key': s3Key},
        onError: (e) { if (kDebugMode) print('[E2E] getEncryptedMediaDownloadUrl error: $e'); },
        onSuccess: (_) {},
      );
      if (response.isSuccess && response.data != null) {
        return response.data['download_url'] as String?;
      }
    } catch (e) {
      if (kDebugMode) print('[E2E] getEncryptedMediaDownloadUrl exception: $e');
    }
    return null;
  }

  // ─── Phase 4: Offline Sync ──────────────────────────────────────────────────

  /// GET /sync/messages?conversation_id=X&deviceId=Y&since=Z
  /// Returns up to 200 messages with seq_num > since.
  Future<SyncMessagesResponse?> syncMessages({
    required String conversationId,
    required String deviceId,
    required int since,
  }) async {
    try {
      final response = await ApiBaseHelper().getHTTP(
        e2eSyncMessages,
        showProgress: false,
        params: {
          'conversation_id': conversationId,
          'deviceId':        deviceId,
          'since':           since,
        },
        onError: (e) { if (kDebugMode) print('[E2E] syncMessages error: $e'); },
        onSuccess: (_) {},
      );
      if (response.isSuccess && response.data != null) {
        return SyncMessagesResponse.fromJson(Map<String, dynamic>.from(response.data));
      }
    } catch (e) {
      if (kDebugMode) print('[E2E] syncMessages exception: $e');
    }
    return null;
  }

  /// POST /sync/ack
  /// REST alternative to `message:sync-complete` socket event.
  /// Used as fallback when socket is unavailable.
  Future<bool> syncAck({
    required String conversationId,
    required int seqNum,
    required String deviceId,
  }) async {
    try {
      final response = await ApiBaseHelper().postHTTP(
        e2eSyncAck,
        isMultipart: false,
        showProgress: false,
        params: {
          'conversation_id': conversationId,
          'seq_num':         seqNum,
          'deviceId':        deviceId,
        },
        onError: (e) { if (kDebugMode) print('[E2E] syncAck error: $e'); },
        onSuccess: (_) {},
      );
      return response.isSuccess;
    } catch (e) {
      if (kDebugMode) print('[E2E] syncAck exception: $e');
      return false;
    }
  }
}
