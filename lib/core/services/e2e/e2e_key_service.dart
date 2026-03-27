import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pinenacl/ed25519.dart';
import 'package:pinenacl/x25519.dart';
import 'package:uuid/uuid.dart';

import '../../../features/chat/auth/model/e2e_models.dart';
import '../../../features/chat/auth/repo/e2e_repo.dart';
import 'e2e_local_db_service.dart';

/// Secure storage keys
const _kDeviceId          = 'e2e_device_id';
const _kIdentityPub       = 'e2e_identity_key_public';  // 32-byte Curve25519 (base64)
const _kIdentityPriv      = 'e2e_identity_key_private'; // 32-byte Curve25519 (base64)
const _kSignedPrekeyPub   = 'e2e_signed_prekey_public';
const _kSignedPrekeyPriv  = 'e2e_signed_prekey_private';
const _kSignedPrekeyId    = 'e2e_signed_prekey_id';
const _kKeysVersion       = 'e2e_keys_version'; // Track key format version

/// Manages NaCl Curve25519 key lifecycle for E2E encryption.
/// Uses pinenacl (TweetNaCl) — same library as the web tester (index.html).
///
/// Key format: raw 32-byte Curve25519 keys (no Signal 0x05 prefix).
class E2EKeyService {
  static final E2EKeyService _instance = E2EKeyService._internal();
  factory E2EKeyService() => _instance;
  E2EKeyService._internal();

  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final _db   = E2ELocalDbService();
  final _repo = E2ERepo();

  // Cached in-memory
  Uint8List? _publicKey;   // 32 bytes
  Uint8List? _privateKey;  // 32 bytes
  String?    _deviceId;

  // ─── Device ID ─────────────────────────────────────────────────────────────

  Future<String> getOrCreateDeviceId() async {
    _deviceId ??= await _secure.read(key: _kDeviceId);
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await _secure.write(key: _kDeviceId, value: _deviceId!);
    }
    return _deviceId!;
  }

  // ─── Identity Key Pair (NaCl Curve25519) ────────────────────────────────────

  /// Get or generate the identity key pair using pinenacl (nacl.box.keyPair).
  /// Returns raw 32-byte public key.
  Future<Uint8List> getPublicKey() async {
    if (_publicKey != null) return _publicKey!;
    await _loadOrGenerateKeys();
    return _publicKey!;
  }

  /// Get raw 32-byte private key.
  Future<Uint8List> getPrivateKey() async {
    if (_privateKey != null) return _privateKey!;
    await _loadOrGenerateKeys();
    return _privateKey!;
  }

  Future<void> _loadOrGenerateKeys() async {
    final pubB64  = await _secure.read(key: _kIdentityPub);
    final privB64 = await _secure.read(key: _kIdentityPriv);
    final version = await _secure.read(key: _kKeysVersion);

    // Check if keys exist AND are NaCl format (version 2)
    if (pubB64 != null && privB64 != null && version == '2') {
      _publicKey  = Uint8List.fromList(base64Decode(pubB64));
      _privateKey = Uint8List.fromList(base64Decode(privB64));

      if (_publicKey!.length == 32 && _privateKey!.length == 32) {
        if (kDebugMode) print('[E2E] Loaded existing NaCl keys (v2)');
        return;
      }
    }

    // Generate fresh NaCl key pair in background isolate — matches nacl.box.keyPair() in JS
    if (kDebugMode) print('[E2E] Generating fresh NaCl Curve25519 key pair');
    final keys = await compute(_generateKeyPairInIsolate, null);
    _privateKey = keys[0];
    _publicKey  = keys[1];

    await Future.wait([
      _secure.write(key: _kIdentityPub,  value: base64Encode(_publicKey!)),
      _secure.write(key: _kIdentityPriv, value: base64Encode(_privateKey!)),
      _secure.write(key: _kKeysVersion,  value: '2'), // Mark as NaCl format
    ]);
    if (kDebugMode) print('[E2E] Generated & stored NaCl keys: pub=${base64Encode(_publicKey!)}');
  }

  // ─── Signed Prekey (NaCl format) ────────────────────────────────────────────

  Future<Map<String, String>> _getOrCreateSignedPrekey() async {
    final pubB64  = await _secure.read(key: _kSignedPrekeyPub);
    final privB64 = await _secure.read(key: _kSignedPrekeyPriv);
    final idStr   = await _secure.read(key: _kSignedPrekeyId);

    if (pubB64 != null && privB64 != null && idStr != null) {
      final pubBytes = base64Decode(pubB64);
      if (pubBytes.length == 32) {
        return {'pub': pubB64, 'priv': privB64, 'id': idStr};
      }
    }

    // Generate using pinenacl in background isolate
    final keys = await compute(_generateKeyPairInIsolate, null);
    final pub  = base64Encode(keys[1]);
    final priv = base64Encode(keys[0]);
    const id   = '1';

    await Future.wait([
      _secure.write(key: _kSignedPrekeyPub,  value: pub),
      _secure.write(key: _kSignedPrekeyPriv, value: priv),
      _secure.write(key: _kSignedPrekeyId,   value: id),
    ]);
    return {'pub': pub, 'priv': priv, 'id': id};
  }

  // ─── One-Time Prekeys (OPKs) ───────────────────────────────────────────────

  /// Generate [count] OPKs using pinenacl, persist to SQLite.
  /// Key generation runs in a background isolate to avoid ANR on the main thread.
  Future<List<OPKRecord>> generateAndStoreOPKs({
    required int startId,
    int count = 100,
  }) async {
    final rawKeys = await compute(
      _generateOPKsInIsolate,
      _OPKGenParams(startId: startId, count: count),
    );
    final records = rawKeys
        .map((r) => OPKRecord(
              keyId: r.keyId,
              publicKeyBase64: r.publicKeyBase64,
              privateKeyBase64: r.privateKeyBase64,
              uploaded: false,
            ))
        .toList();
    await _db.insertOPKs(records);
    return records;
  }

  // ─── Full Key Registration ─────────────────────────────────────────────────

  Future<bool> registerKeys() async {
    try {
      final deviceId   = await getOrCreateDeviceId();
      final pubKey     = await getPublicKey();
      final spk        = await _getOrCreateSignedPrekey();

      // Generate 100 OPKs
      final startId = await _db.getNextOPKId();
      final opks    = await generateAndStoreOPKs(startId: startId, count: 100);

      final identityKeyPub  = base64Encode(pubKey);
      final signedPrekeyPub = spk['pub']!;

      // Sign the signed prekey public key with identity private key (Ed25519).
      // Use the SAME seed for both the X25519 key pair and the Ed25519 signing key.
      // The X25519 private key IS the seed from PrivateKey.generate(), so
      // SigningKey(seed:) derives a consistent Ed25519 key pair from it.
      // We also send the Ed25519 verify key so the server can validate the signature
      // without needing to convert between X25519 and Ed25519 key spaces.
      final identityPrivKey = await getPrivateKey();
      final signingKey = SigningKey(seed: identityPrivKey);
      final signedMsg = signingKey.sign(base64Decode(signedPrekeyPub));
      final signedPrekeySig = base64Encode(signedMsg.signature.asTypedList);
      // Ed25519 verify key derived from the same seed — included for server-side verification
      final signingVerifyKey = base64Encode(Uint8List.fromList(signingKey.verifyKey.asTypedList));

      if (kDebugMode) {
        print('[E2E-REG] Registering keys:');
        print('[E2E-REG]   deviceId: $deviceId');
        print('[E2E-REG]   identityKey: ${identityKeyPub.substring(0, 20)}... (${base64Decode(identityKeyPub).length} bytes)');
        print('[E2E-REG]   signedPrekey: ${signedPrekeyPub.substring(0, 20)}... (${base64Decode(signedPrekeyPub).length} bytes)');
        print('[E2E-REG]   signingVerifyKey: ${signingVerifyKey.substring(0, 20)}... (${base64Decode(signingVerifyKey).length} bytes)');
        print('[E2E-REG]   OPKs: ${opks.length}, first keyId: ${opks.first.keyId}');
      }

      final success = await _repo.registerKeys(
        deviceId:               deviceId,
        identityKey:            identityKeyPub,
        signedPrekey:           signedPrekeyPub,
        signedPrekeySignature:  signedPrekeySig,
        signedPrekeyId:         int.parse(spk['id']!),
        signingVerifyKey:       signingVerifyKey,
        oneTimePrekeys:         opks
            .map((o) => OneTimePrekey(keyId: o.keyId, publicKey: o.publicKeyBase64))
            .toList(),
      );

      if (success) {
        await _db.markOPKsUploaded(opks.map((o) => o.keyId).toList());
        if (kDebugMode) print('[E2E-REG] ✓ Keys registered successfully');
      } else {
        if (kDebugMode) print('[E2E-REG] ✘ Server rejected key registration');
      }
      return success;
    } catch (e) {
      if (kDebugMode) print('[E2E-REG] ✘ registerKeys error: $e');
      return false;
    }
  }

  // ─── OPK Replenishment ─────────────────────────────────────────────────────

  Future<bool> replenishOPKs({int count = 20}) async {
    if (count <= 0) return true;
    try {
      final deviceId = await getOrCreateDeviceId();
      final startId  = await _db.getNextOPKId();
      final opks     = await generateAndStoreOPKs(startId: startId, count: count);

      final success = await _repo.uploadOPKs(
        deviceId: deviceId,
        oneTimePrekeys: opks
            .map((o) => OneTimePrekey(keyId: o.keyId, publicKey: o.publicKeyBase64))
            .toList(),
      );

      if (success) {
        await _db.markOPKsUploaded(opks.map((o) => o.keyId).toList());
        if (kDebugMode) print('[E2E] OPKs replenished ($count keys)');
        return true;
      } else {
        if (kDebugMode) print('[E2E] OPK upload rejected (pool full) — stop retrying');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('[E2E] replenishOPKs error: $e');
      return false;
    }
  }

  // ─── Device Revocation ─────────────────────────────────────────────────────

  Future<void> revokeDevice() async {
    try {
      final deviceId = await getOrCreateDeviceId();
      await _repo.revokeDevice(deviceId);
      await _clearLocalKeys();
    } catch (e) {
      if (kDebugMode) print('[E2E] revokeDevice error: $e');
    }
  }

  Future<void> _clearLocalKeys() async {
    await Future.wait([
      _secure.delete(key: _kDeviceId),
      _secure.delete(key: _kIdentityPub),
      _secure.delete(key: _kIdentityPriv),
      _secure.delete(key: _kSignedPrekeyPub),
      _secure.delete(key: _kSignedPrekeyPriv),
      _secure.delete(key: _kSignedPrekeyId),
      _secure.delete(key: _kKeysVersion),
    ]);
    _publicKey  = null;
    _privateKey = null;
    _deviceId   = null;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Returns true if valid NaCl v2 keys exist locally.
  Future<bool> isRegistered() async {
    final pub     = await _secure.read(key: _kIdentityPub);
    final version = await _secure.read(key: _kKeysVersion);
    if (pub == null || version != '2') return false;

    // Verify key is 32 bytes
    try {
      final bytes = base64Decode(pub);
      return bytes.length == 32;
    } catch (_) {
      return false;
    }
  }

  // ── Compatibility shim: getIdentityKeyPair (used by session service) ──
  // This is a bridge — session service now uses getPublicKey/getPrivateKey directly,
  // but keeping this for any remaining references.
  Future<_NaclKeyPair> getIdentityKeyPair() async {
    final pub  = await getPublicKey();
    final priv = await getPrivateKey();
    return _NaclKeyPair(publicKey: pub, privateKey: priv);
  }
}

/// Simple key pair holder (replaces libsignal's IdentityKeyPair).
class _NaclKeyPair {
  final Uint8List publicKey;
  final Uint8List privateKey;
  const _NaclKeyPair({required this.publicKey, required this.privateKey});
}

// ─── Background isolate helpers for OPK generation ─────────────────────────

class _OPKGenParams {
  final int startId;
  final int count;
  const _OPKGenParams({required this.startId, required this.count});
}

class _OPKGenResult {
  final int keyId;
  final String publicKeyBase64;
  final String privateKeyBase64;
  const _OPKGenResult({
    required this.keyId,
    required this.publicKeyBase64,
    required this.privateKeyBase64,
  });
}

/// Top-level function for compute() — generates a single NaCl key pair off the main thread.
/// Returns [privateKey, publicKey] as raw 32-byte Uint8Lists.
List<Uint8List> _generateKeyPairInIsolate(void _) {
  final kp = PrivateKey.generate();
  return [
    Uint8List.fromList(kp.asTypedList),
    Uint8List.fromList(kp.publicKey.asTypedList),
  ];
}

/// Top-level function for compute() — runs batch NaCl key generation off the main thread.
List<_OPKGenResult> _generateOPKsInIsolate(_OPKGenParams params) {
  final results = <_OPKGenResult>[];
  for (int i = 0; i < params.count; i++) {
    final kp = PrivateKey.generate();
    results.add(_OPKGenResult(
      keyId: params.startId + i,
      publicKeyBase64: base64Encode(Uint8List.fromList(kp.publicKey.asTypedList)),
      privateKeyBase64: base64Encode(Uint8List.fromList(kp.asTypedList)),
    ));
  }
  return results;
}
