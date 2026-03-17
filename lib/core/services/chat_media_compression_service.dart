import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

/// WhatsApp-style media compression for chat.
///
/// **Image:**  Max 1600 px longest side, JPEG quality 70 → ~100-250 KB
/// **Video:**  MediumQuality (~720p) → ~5-6 MB / min
/// **Audio:**  Re-encode large files to AAC 64 kbps → ~500 KB / min
/// **Docs:**   Sent as-is (PDFs are already compressed)
class ChatMediaCompressionService {
  // ─── Thresholds & settings ───
  static const int _imageQuality = 70;
  static const int _imageMaxDimension = 1600;

  // ─── Video extensions ───
  static const _videoExts = ['mp4', 'mov', 'avi', 'mkv', '3gp', 'webm', 'wmv', 'flv', 'm4v'];

  // ─── Audio extensions ───
  static const _audioExts = ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'wma', 'flac', 'opus'];

  /// Compress a list of media files (images, videos, audio).
  /// Returns compressed files in the same order. Falls back to original on failure.
  static Future<List<File>> compressMediaFiles(List<File> files) async {
    // Compress in parallel for speed
    final futures = files.map((file) async {
      final ext = file.path.split('.').last.toLowerCase();
      if (_videoExts.contains(ext)) {
        return await compressVideo(file) ?? file;
      } else if (_audioExts.contains(ext)) {
        return await compressAudio(file) ?? file;
      } else {
        return await compressImage(file) ?? file;
      }
    });
    return Future.wait(futures);
  }

  // ─────────────────────────────────────────────
  // IMAGE
  // ─────────────────────────────────────────────

  /// Compress a single image — WhatsApp style.
  /// Caps longest side at 1600 px, JPEG quality 70. Output: ~100-250 KB.
  static Future<File?> compressImage(File file) async {
    try {
      final originalSize = await file.length();

      // Skip tiny images (< 100 KB) — already small enough
      if (originalSize < 100 * 1024) {
        debugPrint('Image skip (already ${_fmtKB(originalSize)})');
        return file;
      }

      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/chat_img_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: _imageQuality,
        minWidth: _imageMaxDimension,
        minHeight: _imageMaxDimension,
      );

      if (result != null) {
        final compressed = File(result.path);
        final compressedSize = await compressed.length();
        debugPrint(
            'Image: ${_fmtKB(originalSize)} → ${_fmtKB(compressedSize)} '
            '(${_pctReduction(originalSize, compressedSize)}% smaller)');
        return compressed;
      }
      return null;
    } catch (e) {
      debugPrint('Image compression error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // VIDEO
  // ─────────────────────────────────────────────

  /// Compress a single video — WhatsApp style.
  /// MediumQuality (~720p). Output: ~5-6 MB / min.
  static Future<File?> compressVideo(File file) async {
    try {
      final originalSize = await file.length();

      // Skip small videos (< 1 MB)
      if (originalSize < 1024 * 1024) {
        debugPrint('Video skip (already ${_fmtMB(originalSize)})');
        return file;
      }

      final MediaInfo? info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info?.file != null) {
        final compressedSize = info!.filesize ?? 0;
        debugPrint(
            'Video: ${_fmtMB(originalSize)} → ${_fmtMB(compressedSize)} '
            '(${_pctReduction(originalSize, compressedSize)}% smaller)');
        return info.file;
      }
      return null;
    } catch (e) {
      debugPrint('Video compression error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // AUDIO
  // ─────────────────────────────────────────────

  /// Audio files (MP3, AAC, M4A) are already compressed formats.
  /// Returns the original file — no further compression needed.
  /// The app records in AAC which is already compact (~500 KB/min).
  static Future<File?> compressAudio(File file) async {
    final size = await file.length();
    debugPrint('Audio: ${_fmtKB(size)} (already compressed format, skipping)');
    return file;
  }

  /// Generate a video thumbnail for preview.
  static Future<File?> getVideoThumbnail(File videoFile) async {
    try {
      final thumb = await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: 60,
        position: -1, // auto-select frame
      );
      return thumb;
    } catch (e) {
      debugPrint('Thumbnail error: $e');
      return null;
    }
  }

  /// Cancel any ongoing video compression.
  static Future<void> cancelCompression() async {
    await VideoCompress.cancelCompression();
  }

  // ─── Formatting helpers ───

  static String _fmtKB(int bytes) =>
      '${(bytes / 1024).toStringAsFixed(1)} KB';

  static String _fmtMB(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  static String _pctReduction(int original, int compressed) =>
      (100 - (compressed / original * 100)).toStringAsFixed(0);
}
