import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pinenacl/x25519.dart';

import '../../../features/chat/auth/model/e2e_models.dart';
import '../../../features/chat/auth/repo/e2e_repo.dart';
import 'e2e_key_service.dart';

/// NaCl Box encryption/decryption — matches the web tester (index.html).
///
/// Encrypt: nacl.box(plaintext, nonce, recipientPublicKey, mySecretKey)
/// Format:  base64( nonce_24bytes + ciphertext_with_mac )
///
/// Decrypt: nacl.box.open(ciphertext, nonce, senderPublicKey, mySecretKey)
class E2ESessionService {
  static final E2ESessionService _instance = E2ESessionService._internal();
  factory E2ESessionService() => _instance;
  E2ESessionService._internal();

  final _keyService = E2EKeyService();
  final _repo       = E2ERepo();

  // Short-lived session cache: maps recipientUserId → list of bundles.
  // Used ONLY for encryption (send path). Cleared on invalidateStore().
  final Map<String, List<PrekeyBundle>> _sessionCache = {};

  // Identity key cache for decryption: maps userId → list of known identity keys (base64).
  // Populated from bundle fetches (send) and reused for decrypt to avoid consuming OPKs.
  // OPKs are consumed by GET /keys/bundle/:userId, which is designed for sender key exchange.
  // For decryption we only need the sender's identity public key, not a full bundle.
  final Map<String, List<String>> _identityKeyCache = {};

  // ─── Encrypt ──────────────────────────────────────────────────────────────

  /// Encrypt [plaintextJson] for each active device of [recipientUserId].
  /// Returns one [CiphertextEntry] per device (NaCl box encrypted).
  Future<List<CiphertextEntry>> encryptForRecipient({
    required String recipientUserId,
    required String plaintextJson,
  }) async {
    final entries = <CiphertextEntry>[];

    // Get my private key (raw 32 bytes)
    final myPrivateKey = await _getMyPrivateKey();
    final myPublicKey = await _getMyPublicKey();

    if (kDebugMode) {
      print('[E2E-ENCRYPT] ═══════════════════════════════════════');
      print('[E2E-ENCRYPT] recipientUserId: $recipientUserId');
      print('[E2E-ENCRYPT] plaintext: ${plaintextJson.substring(0, plaintextJson.length.clamp(0, 100))}...');
      print('[E2E-ENCRYPT] myPublicKey: ${base64Encode(myPublicKey)}');
    }

    // Get recipient's bundles (one per device)
    List<PrekeyBundle> bundles;
    if (_sessionCache.containsKey(recipientUserId)) {
      bundles = _sessionCache[recipientUserId]!;
      if (kDebugMode) print('[E2E-ENCRYPT] Using ${bundles.length} CACHED bundles');
    } else {
      bundles = await _repo.getPrekeyBundles(recipientUserId);
      if (bundles.isNotEmpty) {
        _sessionCache[recipientUserId] = bundles;
        // Also cache identity keys for future decryption (avoids OPK-consuming bundle fetch)
        _identityKeyCache[recipientUserId] =
            bundles.map((b) => b.identityKey).toList();
      }
      if (kDebugMode) print('[E2E-ENCRYPT] Fetched ${bundles.length} bundles from server');
    }

    if (bundles.isEmpty) {
      if (kDebugMode) print('[E2E-ENCRYPT] ✘ No bundles for $recipientUserId — cannot encrypt');
      return entries;
    }

    final messageBytes = Uint8List.fromList(utf8.encode(plaintextJson));

    for (int i = 0; i < bundles.length; i++) {
      final bundle = bundles[i];
      try {
        final recipientPubBytes = _decodeKey32(bundle.identityKey);
        if (kDebugMode) {
          print('[E2E-ENCRYPT] Encrypting for bundle[$i]: deviceId=${bundle.deviceId}, pubKey=${bundle.identityKey.substring(0, 20)}... (${recipientPubBytes.length} bytes)');
        }
        final encrypted = _naclBoxEncrypt(
          message: messageBytes,
          theirPublicKey: recipientPubBytes,
          myPrivateKey: myPrivateKey,
        );
        entries.add(CiphertextEntry(
          deviceId: bundle.deviceId,
          body: base64Encode(encrypted),
        ));
        if (kDebugMode) print('[E2E-ENCRYPT]   ✓ Encrypted: ${encrypted.length} bytes (nonce=24 + cipher=${encrypted.length - 24})');
      } catch (e) {
        if (kDebugMode) print('[E2E-ENCRYPT]   ✘ FAILED for device ${bundle.deviceId}: $e');
      }
    }

    // Also encrypt for own devices (so sender can read own messages)
    final myDeviceId = await _keyService.getOrCreateDeviceId();
    try {
      if (kDebugMode) print('[E2E-ENCRYPT] Self-encrypting for own device: $myDeviceId');
      final selfEncrypted = _naclBoxEncrypt(
        message: messageBytes,
        theirPublicKey: myPublicKey,
        myPrivateKey: myPrivateKey,
      );
      entries.add(CiphertextEntry(
        deviceId: myDeviceId,
        body: base64Encode(selfEncrypted),
      ));
      if (kDebugMode) print('[E2E-ENCRYPT]   ✓ Self-encrypted: ${selfEncrypted.length} bytes');
    } catch (e) {
      if (kDebugMode) print('[E2E-ENCRYPT]   ✘ Self-encrypt FAILED: $e');
    }

    if (kDebugMode) {
      print('[E2E-ENCRYPT] Total ciphertext entries: ${entries.length}');
      print('[E2E-ENCRYPT] ═══════════════════════════════════════');
    }
    return entries;
  }

  // ─── Decrypt ──────────────────────────────────────────────────────────────

  /// Decrypt a message received from [senderUserId].
  /// [senderDeviceId] is used for debug logging.
  /// [ciphertextBase64] is base64(nonce_24 + ciphertext_with_mac).
  ///
  /// Decryption strategy (avoids OPK consumption):
  ///  1. Try cached identity keys first (from prior encrypt/decrypt calls)
  ///  2. Fetch fresh bundles from server as last resort (consumes 1 OPK)
  Future<String?> decryptMessage({
    required String senderUserId,
    required String senderDeviceId,
    required String ciphertextBase64,
  }) async {
    try {
      final myPrivateKey = await _getMyPrivateKey();
      final myPublicKey = await _getMyPublicKey();
      final ciphertextFull = base64Decode(ciphertextBase64);

      if (kDebugMode) {
        print('[E2E-DECRYPT] ═══════════════════════════════════════');
        print('[E2E-DECRYPT] senderUserId: $senderUserId');
        print('[E2E-DECRYPT] senderDeviceId: $senderDeviceId');
        print('[E2E-DECRYPT] ciphertext length: ${ciphertextFull.length} bytes');
        print('[E2E-DECRYPT] myPublicKey: ${base64Encode(myPublicKey)}');
      }

      // --- Attempt 1: Try cached identity keys (no network call) ---
      final cachedKeys = _identityKeyCache[senderUserId];
      if (cachedKeys != null && cachedKeys.isNotEmpty) {
        if (kDebugMode) print('[E2E-DECRYPT] Trying ${cachedKeys.length} CACHED identity keys');
        final result = _tryDecryptWithKeys(
          ciphertextFull: ciphertextFull,
          identityKeysBase64: cachedKeys,
          myPrivateKey: myPrivateKey,
          label: 'cached',
        );
        if (result != null) return result;
      }

      // --- Attempt 2: Try identity keys from session cache (already fetched for encryption) ---
      final sessionBundles = _sessionCache[senderUserId];
      if (sessionBundles != null && sessionBundles.isNotEmpty) {
        final sessionKeys = sessionBundles.map((b) => b.identityKey).toList();
        if (kDebugMode) print('[E2E-DECRYPT] Trying ${sessionKeys.length} session-cached keys');
        final result = _tryDecryptWithKeys(
          ciphertextFull: ciphertextFull,
          identityKeysBase64: sessionKeys,
          myPrivateKey: myPrivateKey,
          label: 'session',
        );
        if (result != null) {
          // Update identity key cache
          _identityKeyCache[senderUserId] = sessionKeys;
          return result;
        }
      }

      // --- Attempt 3: Fetch fresh bundles from server (consumes 1 OPK — last resort) ---
      if (kDebugMode) print('[E2E-DECRYPT] All cached keys failed — fetching fresh bundles for $senderUserId');
      _sessionCache.remove(senderUserId);
      _identityKeyCache.remove(senderUserId);

      final freshBundles = await _repo.getPrekeyBundles(senderUserId);
      if (freshBundles.isNotEmpty) {
        _sessionCache[senderUserId] = freshBundles;
        final freshKeys = freshBundles.map((b) => b.identityKey).toList();
        _identityKeyCache[senderUserId] = freshKeys;

        if (kDebugMode) print('[E2E-DECRYPT] Fresh bundles: ${freshBundles.length}');
        final result = _tryDecryptWithKeys(
          ciphertextFull: ciphertextFull,
          identityKeysBase64: freshKeys,
          myPrivateKey: myPrivateKey,
          label: 'fresh',
        );
        if (result != null) return result;
      }

      if (kDebugMode) {
        print('[E2E-DECRYPT] ✘ ALL DECRYPTION ATTEMPTS FAILED');
        print('[E2E-DECRYPT] Possible causes:');
        print('[E2E-DECRYPT]   1. Sender encrypted for a DIFFERENT public key than ours');
        print('[E2E-DECRYPT]   2. Sender used Signal Protocol instead of NaCl box');
        print('[E2E-DECRYPT]   3. Keys were rotated/re-registered after sender cached our bundle');
        print('[E2E-DECRYPT] ═══════════════════════════════════════');
      }
      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[E2E-DECRYPT] FATAL ERROR: $e');
        print('[E2E-DECRYPT] Stack: $stackTrace');
      }
      return null;
    }
  }

  /// Try decryption with a list of candidate identity keys.
  /// Returns the decoded plaintext on success, null on failure.
  String? _tryDecryptWithKeys({
    required Uint8List ciphertextFull,
    required List<String> identityKeysBase64,
    required Uint8List myPrivateKey,
    required String label,
  }) {
    for (int i = 0; i < identityKeysBase64.length; i++) {
      try {
        final senderPubBytes = _decodeKey32(identityKeysBase64[i]);
        if (kDebugMode) {
          print('[E2E-DECRYPT] Trying $label key[$i]: ${identityKeysBase64[i].substring(0, 20)}... (${senderPubBytes.length} bytes)');
        }
        final plaintext = _naclBoxDecrypt(
          encryptedWithNonce: ciphertextFull,
          theirPublicKey: senderPubBytes,
          myPrivateKey: myPrivateKey,
        );
        if (plaintext != null) {
          final decoded = utf8.decode(plaintext);
          if (kDebugMode) print('[E2E-DECRYPT]   SUCCESS! Decrypted ${decoded.length} chars');
          return decoded;
        } else {
          if (kDebugMode) print('[E2E-DECRYPT]   FAILED — nacl.box.open returned null');
        }
      } catch (e) {
        if (kDebugMode) print('[E2E-DECRYPT]   EXCEPTION: $e');
      }
    }
    return null;
  }

  // ─── Session helpers ──────────────────────────────────────────────────────

  Future<bool> hasSessionFor(String recipientUserId) async {
    if (_sessionCache.containsKey(recipientUserId)) return true;
    final bundles = await _repo.getPrekeyBundles(recipientUserId);
    return bundles.isNotEmpty;
  }

  Future<void> ensureSessionsForRecipient(String recipientUserId) async {
    if (!_sessionCache.containsKey(recipientUserId)) {
      final bundles = await _repo.getPrekeyBundles(recipientUserId);
      if (bundles.isNotEmpty) {
        _sessionCache[recipientUserId] = bundles;
      }
    }
  }

  void invalidateStore() {
    _sessionCache.clear();
    _identityKeyCache.clear();
  }

  // ─── NaCl Box primitives ──────────────────────────────────────────────────

  /// NaCl box encrypt: produces nonce(24) + ciphertext(n+16).
  /// Matches: nacl.box(msg, nonce, recipientPub, mySecret) in JS.
  Uint8List _naclBoxEncrypt({
    required Uint8List message,
    required Uint8List theirPublicKey,
    required Uint8List myPrivateKey,
  }) {
    final box = Box(
      myPrivateKey: PrivateKey(myPrivateKey),
      theirPublicKey: PublicKey(theirPublicKey),
    );
    final encrypted = box.encrypt(message);
    // pinenacl's encrypt returns EncryptedMessage = nonce(24) + ciphertext
    // Manually build nonce + cipherText to match web format exactly
    final nonce = encrypted.nonce;
    final cipherText = encrypted.cipherText;
    final result = Uint8List(nonce.length + cipherText.length);
    result.setRange(0, nonce.length, nonce);
    result.setRange(nonce.length, result.length, cipherText);
    return result;
  }

  /// NaCl box decrypt: input is nonce(24) + ciphertext(n+16).
  /// Matches: nacl.box.open(ciphertext, nonce, senderPub, mySecret) in JS.
  Uint8List? _naclBoxDecrypt({
    required Uint8List encryptedWithNonce,
    required Uint8List theirPublicKey,
    required Uint8List myPrivateKey,
  }) {
    // Web format: first 24 bytes = nonce, rest = ciphertext + MAC
    if (encryptedWithNonce.length <= 24) return null;

    final nonce = Uint8List.fromList(encryptedWithNonce.sublist(0, 24));
    final cipherText = Uint8List.fromList(encryptedWithNonce.sublist(24));

    final box = Box(
      myPrivateKey: PrivateKey(myPrivateKey),
      theirPublicKey: PublicKey(theirPublicKey),
    );

    try {
      // Create EncryptedMessage with explicit nonce + cipherText
      final encryptedMsg = EncryptedMessage(
        nonce: nonce,
        cipherText: cipherText,
      );
      final decrypted = box.decrypt(encryptedMsg);
      return Uint8List.fromList(decrypted.toList());
    } catch (e) {
      if (kDebugMode) print('[E2E] NaCl box.open failed: $e');
      return null;
    }
  }

  // ─── Key helpers ──────────────────────────────────────────────────────────

  /// Get my raw 32-byte Curve25519 private key.
  Future<Uint8List> _getMyPrivateKey() async {
    return await _keyService.getPrivateKey();
  }

  /// Get my raw 32-byte Curve25519 public key.
  Future<Uint8List> _getMyPublicKey() async {
    return await _keyService.getPublicKey();
  }

  /// Decode a base64 public key to raw 32 bytes.
  /// Strips 0x05 prefix if present (33 → 32 bytes).
  Uint8List _decodeKey32(String base64Key) {
    final bytes = base64Decode(base64Key);
    if (bytes.length == 33 && bytes[0] == 0x05) {
      return Uint8List.fromList(bytes.sublist(1));
    }
    if (bytes.length != 32) {
      throw ArgumentError('Expected 32-byte key, got ${bytes.length}');
    }
    return Uint8List.fromList(bytes);
  }
}
