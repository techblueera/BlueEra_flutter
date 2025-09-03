import 'dart:io';
import 'package:video_compress/video_compress.dart';

class VideoCompressionService {
  /// Compress video file before upload
  static Future<File?> compressVideo(String videoPath) async {
    try {
      final file = File(videoPath);
      final fileSizeInMB = file.lengthSync() / (1024 * 1024);
// print("fileSizeInMB Before===== ${fileSizeInMB}");
      // 👉 Decide quality based on file size
      VideoQuality quality;
      // if (fileSizeInMB > 50) {
        quality = VideoQuality.LowQuality;
        // print("File > 300MB, compressing with LowQuality...");
    /*  } else {
        quality = VideoQuality.DefaultQuality;
        print("File <= 300MB, compressing with MediumQuality...");
      }*/


      final MediaInfo? compressedVideo = await VideoCompress.compressVideo(
        videoPath,
        quality: quality,
        deleteOrigin: true, // keep original file
        includeAudio: true,
      );

      if (compressedVideo != null && compressedVideo.file != null) {
        // print("Original size: ${fileSizeInMB.toStringAsFixed(2)} MB");
        // print("Compressed size: ${(compressedVideo.filesize! / (1024 * 1024)).toStringAsFixed(2)} MB");
        // print("Compressed path: ${compressedVideo.file!.path}");
        return compressedVideo.file;
      }
      return null;
    } catch (e) {
      print("Video compression error: $e");
      return null;
    }
  }
}
