import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

/// Compresses images and videos before sending in chat.
/// Target: ~80% size reduction from original.
class ChatMediaCompressionService {
  /// Compress a list of media files (images and videos).
  /// Returns compressed files in the same order.
  static Future<List<File>> compressMediaFiles(List<File> files) async {
    final List<File> compressed = [];
    for (final file in files) {
      final ext = file.path.split('.').last.toLowerCase();
      if (['mp4', 'mov', 'avi', 'mkv', '3gp'].contains(ext)) {
        final result = await compressVideo(file);
        compressed.add(result ?? file);
      } else {
        final result = await compressImage(file);
        compressed.add(result ?? file);
      }
    }
    return compressed;
  }

  /// Compress a single image to ~20% of original quality.
  /// Uses quality=20 for ~80% reduction.
  static Future<File?> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/chat_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 20,
        minWidth: 1280,
        minHeight: 720,
      );

      if (result != null) {
        final compressed = File(result.path);
        final originalSize = await file.length();
        final compressedSize = await compressed.length();
        print(
            'Image compressed: ${(originalSize / 1024).toStringAsFixed(1)}KB -> ${(compressedSize / 1024).toStringAsFixed(1)}KB '
            '(${(100 - (compressedSize / originalSize * 100)).toStringAsFixed(0)}% reduction)');
        return compressed;
      }
      return null;
    } catch (e) {
      print('Image compression error: $e');
      return null;
    }
  }

  /// Compress a single video targeting ~80% size reduction.
  /// Uses LowQuality preset for significant compression.
  static Future<File?> compressVideo(File file) async {
    try {
      final MediaInfo? compressedVideo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (compressedVideo != null && compressedVideo.file != null) {
        final originalSize = await file.length();
        final compressedSize = compressedVideo.filesize ?? 0;
        print(
            'Video compressed: ${(originalSize / (1024 * 1024)).toStringAsFixed(1)}MB -> ${(compressedSize / (1024 * 1024)).toStringAsFixed(1)}MB '
            '(${(100 - (compressedSize / originalSize * 100)).toStringAsFixed(0)}% reduction)');
        return compressedVideo.file;
      }
      return null;
    } catch (e) {
      print('Video compression error: $e');
      return null;
    }
  }

  /// Cancel any ongoing video compression.
  static Future<void> cancelCompression() async {
    await VideoCompress.cancelCompression();
  }
}
