import 'dart:convert';
import 'dart:typed_data';

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
  // Cleared on invalidateStore() or when decryption fails.
  final Map<String, List<PrekeyBundle>> _sessionCache = {};

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

    // Get recipient's bundles (one per device)
    List<PrekeyBundle> bundles;
    if (_sessionCache.containsKey(recipientUserId)) {
      bundles = _sessionCache[recipientUserId]!;
    } else {
      bundles = await _repo.getPrekeyBundles(recipientUserId);
      if (bundles.isNotEmpty) {
        _sessionCache[recipientUserId] = bundles;
      }
    }

    if (bundles.isEmpty) {
      if (kDebugMode) print('[E2E] No bundles for $recipientUserId');
      return entries;
    }

    final messageBytes = Uint8List.fromList(utf8.encode(plaintextJson));

    for (final bundle in bundles) {
      try {
        // Recipient's identity public key (raw 32 bytes)
        final recipientPubBytes = _decodeKey32(bundle.identityKey);
        final encrypted = _naclBoxEncrypt(
          message: messageBytes,
          theirPublicKey: recipientPubBytes,
          myPrivateKey: myPrivateKey,
        );
        entries.add(CiphertextEntry(
          deviceId: bundle.deviceId,
          body: base64Encode(encrypted),
        ));
      } catch (e) {
        if (kDebugMode) print('[E2E] encrypt error for device ${bundle.deviceId}: $e');
      }
    }

    // Also encrypt for own devices (so sender can read own messages)
    final myDeviceId = await _keyService.getOrCreateDeviceId();
    final myPublicKey = await _getMyPublicKey();
    try {
      final selfEncrypted = _naclBoxEncrypt(
        message: messageBytes,
        theirPublicKey: myPublicKey,
        myPrivateKey: myPrivateKey,
      );
      entries.add(CiphertextEntry(
        deviceId: myDeviceId,
        body: base64Encode(selfEncrypted),
      ));
    } catch (e) {
      if (kDebugMode) print('[E2E] self-encrypt error: $e');
    }

    return entries;
  }

  // ─── Decrypt ──────────────────────────────────────────────────────────────

  /// Decrypt a message received from [senderUserId].
  /// [senderDeviceId] is used to find the sender's identity key from bundles.
  /// [ciphertextBase64] is base64(nonce_24 + ciphertext_with_mac).
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
        print('[E2E-DECRYPT] ciphertext preview: ${ciphertextBase64.substring(0, ciphertextBase64.length.clamp(0, 60))}...');
        print('[E2E-DECRYPT] myPublicKey: ${base64Encode(myPublicKey)}');
        print('[E2E-DECRYPT] myPrivateKey length: ${myPrivateKey.length}');
      }

      // Try decryption using sender's bundles (try all bundles)
      List<PrekeyBundle> senderBundles;
      if (_sessionCache.containsKey(senderUserId)) {
        senderBundles = _sessionCache[senderUserId]!;
        if (kDebugMode) print('[E2E-DECRYPT] Using ${senderBundles.length} CACHED bundles');
      } else {
        senderBundles = await _repo.getPrekeyBundles(senderUserId);
        if (senderBundles.isNotEmpty) {
          _sessionCache[senderUserId] = senderBundles;
        }
        if (kDebugMode) print('[E2E-DECRYPT] Fetched ${senderBundles.length} bundles from server');
      }

      // Try each bundle's identity key for decryption
      for (int i = 0; i < senderBundles.length; i++) {
        final bundle = senderBundles[i];
        if (kDebugMode) {
          print('[E2E-DECRYPT] Trying bundle[$i]: deviceId=${bundle.deviceId}, identityKey=${bundle.identityKey.substring(0, 20)}...');
        }
        try {
          final senderPubBytes = _decodeKey32(bundle.identityKey);
          if (kDebugMode) print('[E2E-DECRYPT]   senderPubKey decoded: ${senderPubBytes.length} bytes');
          final plaintext = _naclBoxDecrypt(
            encryptedWithNonce: ciphertextFull,
            theirPublicKey: senderPubBytes,
            myPrivateKey: myPrivateKey,
          );
          if (plaintext != null) {
            final decoded = utf8.decode(plaintext);
            if (kDebugMode) print('[E2E-DECRYPT]   SUCCESS! Decrypted ${decoded.length} chars: ${decoded.substring(0, decoded.length.clamp(0, 100))}');
            return decoded;
          } else {
            if (kDebugMode) print('[E2E-DECRYPT]   FAILED — nacl.box.open returned null');
          }
        } catch (e) {
          if (kDebugMode) print('[E2E-DECRYPT]   EXCEPTION: $e');
        }
      }

      // If no bundle worked, try with fresh bundles
      if (kDebugMode) print('[E2E-DECRYPT] All cached bundles failed — fetching fresh for $senderUserId');
      _sessionCache.remove(senderUserId);
      final freshBundles = await _repo.getPrekeyBundles(senderUserId);
      if (freshBundles.isNotEmpty) {
        _sessionCache[senderUserId] = freshBundles;
      }
      if (kDebugMode) print('[E2E-DECRYPT] Fresh bundles: ${freshBundles.length}');

      for (int i = 0; i < freshBundles.length; i++) {
        final bundle = freshBundles[i];
        if (kDebugMode) {
          print('[E2E-DECRYPT] Trying fresh bundle[$i]: deviceId=${bundle.deviceId}, identityKey=${bundle.identityKey.substring(0, 20)}...');
        }
        try {
          final senderPubBytes = _decodeKey32(bundle.identityKey);
          final plaintext = _naclBoxDecrypt(
            encryptedWithNonce: ciphertextFull,
            theirPublicKey: senderPubBytes,
            myPrivateKey: myPrivateKey,
          );
          if (plaintext != null) {
            final decoded = utf8.decode(plaintext);
            if (kDebugMode) print('[E2E-DECRYPT]   SUCCESS! Decrypted: ${decoded.substring(0, decoded.length.clamp(0, 100))}');
            return decoded;
          } else {
            if (kDebugMode) print('[E2E-DECRYPT]   FAILED — nacl.box.open returned null');
          }
        } catch (e) {
          if (kDebugMode) print('[E2E-DECRYPT]   EXCEPTION: $e');
        }
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

  /// Get my raw 32-byte Curve25519 private key from secure storage.
  Future<Uint8List> _getMyPrivateKey() async {
    final ikp = await _keyService.getIdentityKeyPair();
    return Uint8List.fromList(ikp.getPrivateKey().serialize());
  }

  /// Get my raw 32-byte Curve25519 public key.
  Future<Uint8List> _getMyPublicKey() async {
    final ikp = await _keyService.getIdentityKeyPair();
    final serialized = ikp.getPublicKey().publicKey.serialize();
    // Strip 0x05 Signal prefix if present
    if (serialized.length == 33 && serialized[0] == 0x05) {
      return Uint8List.fromList(serialized.sublist(1));
    }
    return Uint8List.fromList(serialized);
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
