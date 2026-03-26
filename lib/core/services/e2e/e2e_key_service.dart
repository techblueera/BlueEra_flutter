import 'dart:convert';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:uuid/uuid.dart';

import '../../../features/chat/auth/model/e2e_models.dart';
import '../../../features/chat/auth/repo/e2e_repo.dart';
import 'e2e_local_db_service.dart';

/// Secure storage keys
const _kDeviceId          = 'e2e_device_id';
const _kIdentityPub       = 'e2e_identity_key_public';
const _kIdentityPriv      = 'e2e_identity_key_private';
const _kSignedPrekeyPub   = 'e2e_signed_prekey_public';
const _kSignedPrekeyPriv  = 'e2e_signed_prekey_private';
const _kSignedPrekeyId    = 'e2e_signed_prekey_id';
const _kRegistrationId    = 'e2e_registration_id';

/// Manages device identity and Signal Protocol key lifecycle:
///  - Generates a stable device UUID on first launch
///  - Generates identity key pair, signed prekey, one-time prekeys
///  - Persists private keys in FlutterSecureStorage (Keychain/Keystore)
///  - Registers public keys with the server (POST /keys/register)
///  - Replenishes OPKs when the pool is low (POST /keys/opks)
class E2EKeyService {
  static final E2EKeyService _instance = E2EKeyService._internal();
  factory E2EKeyService() => _instance;
  E2EKeyService._internal();

  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final _db   = E2ELocalDbService();
  final _repo = E2ERepo();

  // Cached in-memory after first read
  IdentityKeyPair? _identityKeyPair;
  int?             _registrationId;
  String?          _deviceId;

  // ─── Device ID ─────────────────────────────────────────────────────────────

  /// Returns (or creates) the stable device UUID for this installation.
  Future<String> getOrCreateDeviceId() async {
    _deviceId ??= await _secure.read(key: _kDeviceId);
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await _secure.write(key: _kDeviceId, value: _deviceId!);
    }
    return _deviceId!;
  }

  // ─── Identity Key Pair ─────────────────────────────────────────────────────

  Future<IdentityKeyPair> getIdentityKeyPair() async {
    if (_identityKeyPair != null) return _identityKeyPair!;

    final pubB64  = await _secure.read(key: _kIdentityPub);
    final privB64 = await _secure.read(key: _kIdentityPriv);

    if (pubB64 != null && privB64 != null) {
      final pubBytes  = base64Decode(pubB64);
      final privBytes = base64Decode(privB64);
      final ecPub  = Curve.decodePoint(pubBytes, 0);
      final ecPriv = Curve.decodePrivatePoint(privBytes);
      _identityKeyPair = IdentityKeyPair(IdentityKey(ecPub), ecPriv);
    } else {
      _identityKeyPair = generateIdentityKeyPair();
      await _persistIdentityKeyPair(_identityKeyPair!);
    }
    return _identityKeyPair!;
  }

  Future<void> _persistIdentityKeyPair(IdentityKeyPair kp) async {
    final pub  = kp.getPublicKey().publicKey.serialize();
    final priv = kp.getPrivateKey().serialize();
    await Future.wait([
      _secure.write(key: _kIdentityPub,  value: base64Encode(pub)),
      _secure.write(key: _kIdentityPriv, value: base64Encode(priv)),
    ]);
  }

  // ─── Registration ID ───────────────────────────────────────────────────────

  Future<int> getOrCreateRegistrationId() async {
    if (_registrationId != null) return _registrationId!;
    final stored = await _secure.read(key: _kRegistrationId);
    if (stored != null) {
      _registrationId = int.parse(stored);
    } else {
      _registrationId = generateRegistrationId(false);
      await _secure.write(key: _kRegistrationId, value: '$_registrationId');
    }
    return _registrationId!;
  }

  // ─── Signed Prekey ─────────────────────────────────────────────────────────

  Future<SignedPreKeyRecord> getOrCreateSignedPrekey() async {
    final pubB64  = await _secure.read(key: _kSignedPrekeyPub);
    final privB64 = await _secure.read(key: _kSignedPrekeyPriv);
    final idStr   = await _secure.read(key: _kSignedPrekeyId);

    if (pubB64 != null && privB64 != null && idStr != null) {
      final pub  = Curve.decodePoint(base64Decode(pubB64), 0);
      final priv = Curve.decodePrivatePoint(base64Decode(privB64));
      final kp   = ECKeyPair(pub, priv);
      final ikp  = await getIdentityKeyPair();
      // Re-sign with identity key to reconstruct signature
      final sig  = Curve.calculateSignature(
        ikp.getPrivateKey(),
        pub.serialize(),
      );
      return SignedPreKeyRecord(
        int.parse(idStr),
        Int64(DateTime.now().millisecondsSinceEpoch),
        kp,
        sig,
      );
    } else {
      final ikp = await getIdentityKeyPair();
      final spk = generateSignedPreKey(ikp, 1);
      await _persistSignedPrekey(spk);
      return spk;
    }
  }

  Future<void> _persistSignedPrekey(SignedPreKeyRecord spk) async {
    await Future.wait([
      _secure.write(key: _kSignedPrekeyPub,  value: base64Encode(spk.getKeyPair().publicKey.serialize())),
      _secure.write(key: _kSignedPrekeyPriv, value: base64Encode(spk.getKeyPair().privateKey.serialize())),
      _secure.write(key: _kSignedPrekeyId,   value: '${spk.id}'),
    ]);
  }

  // ─── One-Time Prekeys (OPKs) ───────────────────────────────────────────────

  /// Generate [count] OPKs starting at [startId], persist to SQLite.
  Future<List<OPKRecord>> generateAndStoreOPKs({
    required int startId,
    int count = 100,
  }) async {
    final records = <OPKRecord>[];
    final preKeys = generatePreKeys(startId, count);
    for (final pk in preKeys) {
      final opk = OPKRecord(
        keyId:           pk.id,
        publicKeyBase64:  encodePublicKeyForServer(pk.getKeyPair().publicKey),
        privateKeyBase64: base64Encode(pk.getKeyPair().privateKey.serialize()),
        uploaded: false,
      );
      records.add(opk);
    }
    await _db.insertOPKs(records);
    return records;
  }

  // ─── Full Key Registration ─────────────────────────────────────────────────

  /// First-time or re-registration: generate all keys and POST /keys/register.
  Future<bool> registerKeys() async {
    try {
      final deviceId = await getOrCreateDeviceId();
      final ikp      = await getIdentityKeyPair();
      final spk      = await getOrCreateSignedPrekey();

      // Generate 100 OPKs
      final startId = await _db.getNextOPKId();
      final opks    = await generateAndStoreOPKs(startId: startId, count: 100);

      final identityKeyPub      = encodePublicKeyForServer(ikp.getPublicKey().publicKey);
      final signedPrekeyPub     = encodePublicKeyForServer(spk.getKeyPair().publicKey);
      final signedPrekeySig     = base64Encode(spk.signature);

      final success = await _repo.registerKeys(
        deviceId:               deviceId,
        identityKey:            identityKeyPub,
        signedPrekey:           signedPrekeyPub,
        signedPrekeySignature:  signedPrekeySig,
        signedPrekeyId:         spk.id,
        oneTimePrekeys:         opks
            .map((o) => OneTimePrekey(keyId: o.keyId, publicKey: o.publicKeyBase64))
            .toList(),
      );

      if (success) {
        await _db.markOPKsUploaded(opks.map((o) => o.keyId).toList());
        if (kDebugMode) print('[E2E] Keys registered successfully');
      }
      return success;
    } catch (e) {
      if (kDebugMode) print('[E2E] registerKeys error: $e');
      return false;
    }
  }

  // ─── OPK Replenishment ─────────────────────────────────────────────────────

  /// Called when `prekey:low` socket event is received.
  /// [count] should be pre-calculated to not exceed the 200 server limit.
  /// Returns true if upload succeeded, false if rejected or failed.
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
        // 422 = pool would overflow — stop retrying
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
      _secure.delete(key: _kRegistrationId),
    ]);
    _identityKeyPair = null;
    _registrationId  = null;
    _deviceId        = null;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Returns true if this device has already uploaded valid keys to the server.
  /// Forces re-registration if previously uploaded keys were 33-byte (invalid).
  Future<bool> isRegistered() async {
    final pub = await _secure.read(key: _kIdentityPub);
    if (pub == null) return false;

    // Check if existing OPKs have correct 32-byte key size.
    // If they have 33-byte keys (old bug with Signal 0x05 prefix),
    // return false to trigger fresh re-registration.
    try {
      final nextId = await _db.getNextOPKId();
      if (nextId > 0) {
        final opk = await _db.loadOPK(nextId - 1);
        if (opk != null) {
          final keyBytes = base64Decode(opk.publicKeyBase64);
          if (keyBytes.length != 32) {
            if (kDebugMode) print('[E2E] Detected ${keyBytes.length}-byte OPKs — forcing re-registration');
            return false;
          }
        }
      }
    } catch (_) {
      // DB not initialized yet or empty — needs registration
      return false;
    }
    return true;
  }

  /// Encode a public key to base64 for server upload.
  /// Strips the Signal Protocol 0x05 type prefix to produce a raw 32-byte key,
  /// which is what the server expects: Buffer.from(key, 'base64').length === 32.
  static String encodePublicKeyForServer(ECPublicKey key) {
    final bytes = key.serialize();
    // serialize() returns 33 bytes: [0x05, ...32 raw bytes]
    if (bytes.length == 33 && bytes[0] == 0x05) {
      return base64Encode(bytes.sublist(1));
    }
    return base64Encode(bytes);
  }

  /// Decode a server-supplied base64 public key into an ECPublicKey.
  /// Handles both 32-byte (raw Curve25519) and 33-byte (Signal type-prefixed) keys.
  static ECPublicKey decodePublicKey(String base64Key) {
    final bytes = base64Decode(base64Key);
    if (bytes.length == 32) {
      // Prepend Signal type byte 0x05
      final prefixed = Uint8List(33);
      prefixed[0] = 0x05;
      prefixed.setRange(1, 33, bytes);
      return Curve.decodePoint(prefixed, 0);
    }
    return Curve.decodePoint(bytes, 0);
  }

  /// Convert a UUID string to a stable positive int (for SignalProtocolAddress.deviceId).
  static int uuidToDeviceId(String uuid) {
    final hex = uuid.replaceAll('-', '');
    return int.parse(hex.substring(0, 7), radix: 16) & 0x7FFFFFFF;
  }
}
