import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pinenacl/tweetnacl.dart';
import 'package:pinenacl/api.dart';

import '../../../features/chat/auth/model/e2e_models.dart';
import '../../../features/chat/auth/repo/e2e_repo.dart';

/// Handles client-side NaCl secretbox encryption of media files and
/// the presigned S3 upload/download flow for E2E encrypted media.
///
/// Matches the web tester (index.html) exactly:
///   Encrypt: nacl.secretbox(fileBytes, nonce, fileKey)
///   Format:  nonce(24 bytes) + ciphertext
///   Decrypt: nacl.secretbox.open(ciphertext, nonce, fileKey)
class E2EMediaService {
  static final E2EMediaService _instance = E2EMediaService._internal();
  factory E2EMediaService() => _instance;
  E2EMediaService._internal();

  final _repo = E2ERepo();

  // ─── NaCl SecretBox Encryption (matching web tester) ────────────────────────

  /// Encrypt [fileBytes] using NaCl secretbox (XSalsa20-Poly1305).
  /// Returns nonce(24) + ciphertext — same format as web tester.
  static Uint8List encryptFile(Uint8List fileBytes, Uint8List fileKey) {
    assert(fileKey.length == 32, 'NaCl secretbox requires a 32-byte key');

    // Generate random 24-byte nonce (nacl.secretbox.nonceLength)
    final nonce = PineNaClUtils.randombytes(TweetNaCl.nonceLength);

    // Encrypt: nacl.secretbox(msg, nonce, key)
    final encrypted = Uint8List(fileBytes.length + TweetNaCl.macBytes);
    final rc = TweetNaCl.crypto_secretbox(
      encrypted, fileBytes, fileBytes.length, nonce, fileKey,
    );
    if (rc != 0) throw Exception('NaCl secretbox encryption failed');

    // Combine: nonce(24) + encrypted(msg + mac)
    // Note: TweetNaCl.crypto_secretbox prepends 16 zero bytes, strip them
    final ciphertext = encrypted.sublist(TweetNaCl.boxzerobytesLength);

    final result = Uint8List(nonce.length + ciphertext.length);
    result.setRange(0, nonce.length, nonce);
    result.setRange(nonce.length, result.length, ciphertext);
    return result;
  }

  /// Decrypt [encryptedWithNonce] (nonce + ciphertext) using NaCl secretbox.
  /// Returns raw decrypted file bytes.
  static Uint8List? decryptFile(Uint8List encryptedWithNonce, Uint8List fileKey) {
    assert(fileKey.length == 32, 'NaCl secretbox requires a 32-byte key');

    if (encryptedWithNonce.length <= TweetNaCl.nonceLength) return null;

    // Split nonce(24) + ciphertext
    final nonce = encryptedWithNonce.sublist(0, TweetNaCl.nonceLength);
    final ciphertext = encryptedWithNonce.sublist(TweetNaCl.nonceLength);

    // Prepend 16 zero bytes (TweetNaCl.boxzerobytesLength) for crypto_secretbox_open
    final paddedCipher = Uint8List(TweetNaCl.boxzerobytesLength + ciphertext.length);
    paddedCipher.setRange(TweetNaCl.boxzerobytesLength, paddedCipher.length, ciphertext);

    final decrypted = Uint8List(paddedCipher.length);
    final rc = TweetNaCl.crypto_secretbox_open(
      decrypted, paddedCipher, paddedCipher.length, nonce, fileKey,
    );
    if (rc != 0) return null;

    // Strip 32 zero bytes prefix (TweetNaCl.zerobytesLength)
    return decrypted.sublist(TweetNaCl.zerobytesLength);
  }

  // ─── Upload Flow ───────────────────────────────────────────────────────────

  /// Full E2E media upload — matches web tester flow:
  ///  1. Read file bytes
  ///  2. Generate random 32-byte fileKey, encrypt with NaCl secretbox
  ///  3. Get presigned S3 PUT URL (POST /encrypted-media/upload-url)
  ///  4. Upload encrypted blob (nonce + ciphertext) to S3
  ///  5. Return metadata: s3_key + file_key (base64) go inside the E2E message ciphertext
  Future<EncryptedMediaMetadata?> uploadEncryptedMedia({
    required File file,
    required String mimeType,
    String? fileName,
  }) async {
    try {
      if (kDebugMode) print('[E2E-MEDIA] Encrypting file: ${file.path.split('/').last}');

      // Step 1: Read file
      final fileBytes = await file.readAsBytes();

      // Step 2: Generate random key + encrypt with NaCl secretbox
      final fileKey = PineNaClUtils.randombytes(32); // nacl.secretbox.keyLength
      final encryptedBlob = encryptFile(Uint8List.fromList(fileBytes), fileKey);
      if (kDebugMode) print('[E2E-MEDIA] Encrypted: ${fileBytes.length} → ${encryptedBlob.length} bytes');

      // Step 3: Get presigned PUT URL — always use 'application/octet-stream' (matching web)
      final urlResult = await _repo.getEncryptedMediaUploadUrl(
        mimeType: 'application/octet-stream',
      );
      if (urlResult == null) {
        if (kDebugMode) print('[E2E-MEDIA] Failed to get upload URL');
        return null;
      }
      final s3Key     = urlResult['s3_key'] as String;
      final uploadUrl = urlResult['upload_url'] as String;

      // Step 4: PUT encrypted blob to S3
      final uploadResp = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'application/octet-stream'},
        body: encryptedBlob,
      );
      if (uploadResp.statusCode != 200) {
        if (kDebugMode) print('[E2E-MEDIA] S3 upload failed: ${uploadResp.statusCode}');
        return null;
      }
      if (kDebugMode) print('[E2E-MEDIA] ✓ Uploaded to S3: $s3Key');

      // Step 5: Return metadata — file_key goes inside E2E ciphertext (server never sees it)
      // Note: web tester doesn't use 'iv' field — NaCl secretbox nonce is prepended to blob
      return EncryptedMediaMetadata(
        s3Key:    s3Key,
        fileKey:  base64Encode(fileKey),
        iv:       '', // Not used — nonce is prepended to encrypted blob
        mimeType: mimeType,
        fileName: fileName ?? file.path.split('/').last,
        size:     fileBytes.length,
      );
    } catch (e) {
      if (kDebugMode) print('[E2E-MEDIA] uploadEncryptedMedia error: $e');
      return null;
    }
  }

  // ─── Download + Decrypt Flow ───────────────────────────────────────────────

  /// Download and decrypt an encrypted media file.
  /// Matches web tester's decrypt flow:
  ///   1. Get presigned download URL
  ///   2. Download encrypted blob
  ///   3. nacl.secretbox.open(ciphertext, nonce, fileKey)
  Future<Uint8List?> downloadAndDecryptMedia(
    EncryptedMediaMetadata meta,
  ) async {
    try {
      if (kDebugMode) print('[E2E-MEDIA] Downloading: ${meta.s3Key}');

      // Step 1: Get presigned download URL
      final downloadUrl =
          await _repo.getEncryptedMediaDownloadUrl(s3Key: meta.s3Key);
      if (downloadUrl == null) {
        if (kDebugMode) print('[E2E-MEDIA] Failed to get download URL');
        return null;
      }

      // Step 2: Download encrypted blob
      final resp = await http.get(Uri.parse(downloadUrl));
      if (resp.statusCode != 200) {
        if (kDebugMode) print('[E2E-MEDIA] Download failed: ${resp.statusCode}');
        return null;
      }

      // Step 3: Decrypt with NaCl secretbox (nonce is first 24 bytes of blob)
      final fileKey = base64Decode(meta.fileKey);
      final decryptedBytes = decryptFile(
        Uint8List.fromList(resp.bodyBytes),
        Uint8List.fromList(fileKey),
      );

      if (decryptedBytes == null) {
        if (kDebugMode) print('[E2E-MEDIA] File decryption failed');
        return null;
      }

      if (kDebugMode) print('[E2E-MEDIA] ✓ Decrypted: ${decryptedBytes.length} bytes');
      return decryptedBytes;
    } catch (e) {
      if (kDebugMode) print('[E2E-MEDIA] downloadAndDecryptMedia error: $e');
      return null;
    }
  }
}
