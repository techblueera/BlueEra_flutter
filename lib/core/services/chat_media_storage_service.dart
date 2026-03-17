import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// WhatsApp-style media storage service.
///
/// Saves chat media into organised sub-folders that appear in the phone gallery:
///
///   Android 10+ (API 29+):
///     /storage/emulated/0/Android/media/ai.bluecs.app/BlueEra Images/
///     /storage/emulated/0/Android/media/ai.bluecs.app/BlueEra Video/
///     /storage/emulated/0/Android/media/ai.bluecs.app/BlueEra Audio/
///     /storage/emulated/0/Android/media/ai.bluecs.app/BlueEra Documents/
///     → No permissions needed. MediaStore indexes these → shows in Gallery.
///
///   Android < 10:
///     /storage/emulated/0/BlueEra/Media/...
///     → Requires storage permission.
///
///   iOS:
///     Documents/BlueEra/Media/...
///     → Visible in the iOS Files app.
class ChatMediaStorageService {
  ChatMediaStorageService._();

  static const _packageName = 'ai.bluecs.app';

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  // Cache SDK version to avoid repeated lookups
  static int? _cachedSdk;

  static Future<int> _androidSdk() async {
    if (_cachedSdk != null) return _cachedSdk!;
    if (!Platform.isAndroid) return _cachedSdk = 0;
    final info = await DeviceInfoPlugin().androidInfo;
    return _cachedSdk = info.version.sdkInt;
  }

  // ─── Sub-folder names (like WhatsApp) ───
  static String _subFolder(String messageType) {
    switch (messageType.toLowerCase()) {
      case 'image':
        return 'BlueEra Images';
      case 'video':
        return 'BlueEra Video';
      case 'audio':
        return 'BlueEra Audio';
      case 'document':
        return 'BlueEra Documents';
      default:
        return 'BlueEra Documents';
    }
  }

  // ─── Root media directory ───
  static Future<Directory> _mediaRoot(String messageType) async {
    if (Platform.isAndroid) {
      final sdk = await _androidSdk();

      if (sdk >= 29) {
        // Android 10+ : Use Android/media/<package>/<subfolder>
        // This path is:
        //   ✅ Writable without any permission
        //   ✅ Indexed by MediaStore → appears in Gallery
        //   ✅ Visible in file manager
        // Same approach WhatsApp uses (Android/media/com.whatsapp/...)
        final dir = Directory(
            '/storage/emulated/0/Android/media/$_packageName/${_subFolder(messageType)}');
        return dir;
      } else {
        // Android 9 and below: public storage with permission
        await _requestLegacyStoragePermission();
        return Directory(
            '/storage/emulated/0/BlueEra/Media/${_subFolder(messageType)}');
      }
    } else {
      // iOS: app documents folder (visible in Files app)
      final docs = await getApplicationDocumentsDirectory();
      return Directory(
          '${docs.path}/BlueEra/Media/${_subFolder(messageType)}');
    }
  }

  /// Returns the directory for a given message type, creating it if needed.
  static Future<Directory> getMediaDir(String messageType) async {
    final dir = await _mediaRoot(messageType);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // ─── Permissions ───

  /// Request legacy storage permission for Android < 10.
  static Future<bool> _requestLegacyStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // ─── Download & Save ───

  /// Downloads a file from [url] and saves it into the appropriate BlueEra
  /// media folder based on [messageType].
  ///
  /// Returns the saved [File] or `null` on failure.
  static Future<File?> downloadAndSave({
    required String url,
    required String messageType,
    String? fileName,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final dir = await getMediaDir(messageType);
      final name = fileName ?? _fileNameFromUrl(url);
      final target = await _uniqueFile(File(p.join(dir.path, name)));

      await _dio.download(
        url,
        target.path,
        onReceiveProgress: onProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      // Make file visible in device gallery
      if (Platform.isAndroid) {
        _scanFile(target.path);
      } else if (Platform.isIOS) {
        await _saveToiOSPhotos(target, messageType);
      }

      debugPrint('ChatMediaStorageService: saved to ${target.path}');
      return target;
    } catch (e) {
      debugPrint('ChatMediaStorageService download error: $e');
      return null;
    }
  }

  /// Checks if a file from [url] already exists in the BlueEra media folder.
  static Future<File?> findExistingFile({
    required String url,
    required String messageType,
    String? fileName,
  }) async {
    try {
      final dir = await getMediaDir(messageType);
      final name = fileName ?? _fileNameFromUrl(url);
      final file = File(p.join(dir.path, name));
      if (await file.exists()) return file;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Delete from device ───

  /// Deletes files associated with media URLs from the device.
  static Future<int> deleteMediaFiles(List<String> urls,
      {String messageType = 'image'}) async {
    int deleted = 0;
    final dir = await getMediaDir(messageType);

    for (final url in urls) {
      try {
        final name = _fileNameFromUrl(url);
        final file = File(p.join(dir.path, name));
        if (await file.exists()) {
          await file.delete();
          deleted++;
        }
      } catch (_) {}
    }
    return deleted;
  }

  /// Deletes a single file by its full path.
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ─── Helpers ───

  static String _fileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final name = p.basename(uri.path);
      if (name.isNotEmpty && name.contains('.')) return name;
      return 'BlueEra_${url.hashCode}';
    } catch (_) {
      return 'BlueEra_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  static Future<File> _uniqueFile(File original) async {
    if (!await original.exists()) return original;

    final dir = original.parent.path;
    final base = p.basenameWithoutExtension(original.path);
    final ext = p.extension(original.path);
    int counter = 1;

    File candidate;
    do {
      candidate = File(p.join(dir, '$base ($counter)$ext'));
      counter++;
    } while (await candidate.exists());
    return candidate;
  }

  /// Save image/video to iOS Photos library so it appears in the Camera Roll.
  /// Audio and documents are skipped (not supported by Photos).
  static Future<void> _saveToiOSPhotos(File file, String messageType) async {
    try {
      final type = messageType.toLowerCase();
      if (type == 'image') {
        await Gal.putImage(file.path, album: 'BlueEra');
        debugPrint('ChatMediaStorageService: saved image to iOS Photos');
      } else if (type == 'video') {
        await Gal.putVideo(file.path, album: 'BlueEra');
        debugPrint('ChatMediaStorageService: saved video to iOS Photos');
      }
      // audio & document — no-op, not gallery media
    } catch (e) {
      debugPrint('ChatMediaStorageService: iOS Photos save error: $e');
    }
  }

  /// Trigger Android MediaStore scan so files appear in Gallery immediately.
  /// Uses the media scanner broadcast intent.
  static void _scanFile(String path) {
    if (!Platform.isAndroid) return;
    try {
      // Method channel approach for reliable media scanning
      const channel = MethodChannel('ai.bluecs.app/media_scanner');
      channel.invokeMethod('scanFile', {'path': path}).catchError((_) {
        // Fallback: use am broadcast
        Process.run('am', [
          'broadcast',
          '-a',
          'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
          '-d',
          'file://$path',
        ]).catchError((_) => ProcessResult(0, 0, '', ''));
      });
    } catch (_) {
      // Silent fail — file is saved, just might not appear in gallery immediately
    }
  }
}
