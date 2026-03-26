import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';

import '../../../features/chat/auth/model/e2e_models.dart';
import '../../../features/chat/auth/repo/e2e_repo.dart';

/// Handles client-side AES-256-GCM encryption of media files and
/// the presigned S3 upload/download flow for E2E encrypted media.
class E2EMediaService {
  static final E2EMediaService _instance = E2EMediaService._internal();
  factory E2EMediaService() => _instance;
  E2EMediaService._internal();

  final _repo = E2ERepo();

  // ─── Cryptographic Primitives ──────────────────────────────────────────────

  /// Generate a cryptographically random byte array of [length] bytes.
  /// Uses FortunaRandom seeded from dart:math secure random.
  static Uint8List _randomBytes(int length) {
    final secureRandom = FortunaRandom();
    final rng   = math.Random.secure();
    final seeds = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      seeds[i] = rng.nextInt(256);
    }
    secureRandom.seed(KeyParameter(seeds));
    return secureRandom.nextBytes(length);
  }

  /// Generate a cryptographically random 256-bit AES key.
  static Uint8List generateFileKey() => _randomBytes(32);

  /// Generate a cryptographically random 96-bit GCM nonce.
  static Uint8List generateIV() => _randomBytes(12);

  /// Encrypt [fileBytes] using AES-256-GCM with [key] and [iv].
  /// Returns ciphertext + 16-byte GCM authentication tag appended.
  static Uint8List encryptFile(
    Uint8List fileBytes,
    Uint8List key,
    Uint8List iv,
  ) {
    assert(key.length == 32, 'AES-256 requires a 32-byte key');
    assert(iv.length == 12, 'GCM nonce must be 12 bytes');

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      true, // encrypt
      AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)),
    );
    return cipher.process(fileBytes);
  }

  /// Decrypt [encryptedBytes] (ciphertext + GCM tag) using [key] and [iv].
  static Uint8List decryptFile(
    Uint8List encryptedBytes,
    Uint8List key,
    Uint8List iv,
  ) {
    assert(key.length == 32, 'AES-256 requires a 32-byte key');
    assert(iv.length == 12, 'GCM nonce must be 12 bytes');

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      false, // decrypt
      AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)),
    );
    return cipher.process(encryptedBytes);
  }

  // ─── Upload Flow ───────────────────────────────────────────────────────────

  /// Full E2E media upload:
  ///  1. Read + encrypt [file] with AES-256-GCM
  ///  2. Get presigned S3 PUT URL from server (POST /encrypted-media/upload-url)
  ///  3. Upload the encrypted blob to S3
  ///  4. Return [EncryptedMediaMetadata] for embedding inside Signal Protocol ciphertext.
  ///     The fileKey + iv are NEVER sent to the server in plaintext.
  Future<EncryptedMediaMetadata?> uploadEncryptedMedia({
    required File file,
    required String mimeType,
    String? fileName,
  }) async {
    try {
      // Step 1: Encrypt
      final fileBytes      = await file.readAsBytes();
      final fileKey        = generateFileKey();
      final iv             = generateIV();
      final encryptedBytes = encryptFile(fileBytes, fileKey, iv);

      // Step 2: Get presigned PUT URL
      final urlResult = await _repo.getEncryptedMediaUploadUrl(mimeType: mimeType);
      if (urlResult == null) {
        if (kDebugMode) print('[E2E] Failed to get encrypted media upload URL');
        return null;
      }
      final s3Key     = urlResult['s3_key'] as String;
      final uploadUrl = urlResult['upload_url'] as String;

      // Step 3: PUT encrypted bytes to S3
      final uploadResp = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': mimeType},
        body: encryptedBytes,
      );
      if (uploadResp.statusCode != 200) {
        if (kDebugMode) print('[E2E] S3 upload failed: ${uploadResp.statusCode}');
        return null;
      }

      // Step 4: Return metadata (goes inside Signal Protocol ciphertext only)
      return EncryptedMediaMetadata(
        s3Key:    s3Key,
        fileKey:  base64Encode(fileKey),
        iv:       base64Encode(iv),
        mimeType: mimeType,
        fileName: fileName ?? file.path.split('/').last,
        size:     fileBytes.length,
      );
    } catch (e) {
      if (kDebugMode) print('[E2E] uploadEncryptedMedia error: $e');
      return null;
    }
  }

  // ─── Download + Decrypt Flow ───────────────────────────────────────────────

  /// Download and decrypt an encrypted media file.
  ///
  /// [meta] is extracted from the decrypted Signal Protocol message payload.
  /// Returns raw decrypted file bytes, or null on failure.
  Future<Uint8List?> downloadAndDecryptMedia(
    EncryptedMediaMetadata meta,
  ) async {
    try {
      // Get presigned download URL
      final downloadUrl =
          await _repo.getEncryptedMediaDownloadUrl(s3Key: meta.s3Key);
      if (downloadUrl == null) {
        if (kDebugMode) {
          print('[E2E] Failed to get download URL for ${meta.s3Key}');
        }
        return null;
      }

      // Download encrypted blob
      final resp = await http.get(Uri.parse(downloadUrl));
      if (resp.statusCode != 200) {
        if (kDebugMode) print('[E2E] Download failed: ${resp.statusCode}');
        return null;
      }

      // Decrypt
      final fileKey        = base64Decode(meta.fileKey);
      final iv             = base64Decode(meta.iv);
      final decryptedBytes = decryptFile(resp.bodyBytes, fileKey, iv);

      return decryptedBytes;
    } catch (e) {
      if (kDebugMode) print('[E2E] downloadAndDecryptMedia error: $e');
      return null;
    }
  }
}
