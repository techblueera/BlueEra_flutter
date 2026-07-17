import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import 'chat_storage_paths.dart';

/// WhatsApp-style media storage service.
///
/// Downloads chat media into the organised BlueEra folder tree owned by
/// [ChatStoragePaths]:
///
///   Android 10+:  /storage/emulated/0/Android/media/ai.bluecs.app/Media/...
///   Android < 10: /storage/emulated/0/BlueEra/Media/...
///   iOS:          <AppDocuments>/BlueEra/Media/...
///
/// Media/ and Symbols/ are indexed by the gallery; Chat History/ is not. All
/// directory resolution is delegated to [ChatStoragePaths] so the app agrees
/// on one layout.
class ChatMediaStorageService {
  ChatMediaStorageService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  /// Returns the directory for a given message type, creating it if needed.
  static Future<Directory> getMediaDir(String messageType) async {
    return ChatStoragePaths.mediaDir(messageType);
  }

  /// Pre-create all media folders and request necessary permissions.
  /// Call this once at app startup (e.g. from BottomNavigationBar initState).
  static Future<void> initializeMediaFolders() async {
    await ChatStoragePaths.ensureAllDirs();
  }

  /// Request photo library access on iOS (for saving to Camera Roll).
  static Future<bool> requestPhotoLibraryPermission() async {
    if (!Platform.isIOS) return true;
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
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
  ///
  /// Looks in the current `Media/<type>/` folder first, then falls back to the
  /// legacy flat path used by older builds so previously-downloaded files keep
  /// resolving locally after the folder-layout upgrade.
  static Future<File?> findExistingFile({
    required String url,
    required String messageType,
    String? fileName,
  }) async {
    try {
      final name = fileName ?? _fileNameFromUrl(url);

      final dir = await getMediaDir(messageType);
      final file = File(p.join(dir.path, name));
      if (await file.exists()) return file;

      // Legacy fallback: media saved before the `Media/` nesting.
      final legacyDir = await ChatStoragePaths.legacyMediaDir(messageType);
      final legacyFile = File(p.join(legacyDir.path, name));
      if (await legacyFile.exists()) return legacyFile;

      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Symbols ───

  /// Downloads a symbol's photo/video into the dedicated `Symbols/` folder.
  /// [id] is the symbol id, used to build a stable filename so the same symbol
  /// is cached only once. Returns the saved [File] or `null` on failure.
  static Future<File?> downloadAndSaveSymbol({
    required String url,
    required String id,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final dir = await ChatStoragePaths.symbolsDir();
      final target = File(p.join(dir.path, _symbolFileName(url, id)));
      if (await target.exists()) return target;

      await _dio.download(
        url,
        target.path,
        onReceiveProgress: onProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );
      if (Platform.isAndroid) _scanFile(target.path);
      debugPrint('ChatMediaStorageService: saved symbol to ${target.path}');
      return target;
    } catch (e) {
      debugPrint('ChatMediaStorageService symbol download error: $e');
      return null;
    }
  }

  /// Returns the cached symbol file for [id]/[url] if it already exists.
  static Future<File?> findExistingSymbol({
    required String url,
    required String id,
  }) async {
    try {
      final dir = await ChatStoragePaths.symbolsDir();
      final file = File(p.join(dir.path, _symbolFileName(url, id)));
      if (await file.exists()) return file;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Best-effort background download of a batch of symbol photos/videos into
  /// the `Symbols/` folder. Each entry is (id → url); already-cached and
  /// non-http entries are skipped. Runs sequentially so it doesn't hammer the
  /// network. Safe to fire-and-forget from a symbol loader.
  static Future<void> prefetchSymbols(
      Iterable<MapEntry<String, String>> idUrls) async {
    for (final e in idUrls) {
      final id = e.key;
      final url = e.value;
      if (url.isEmpty || !url.startsWith('http')) continue;
      if (await findExistingSymbol(url: url, id: id) != null) continue;
      await downloadAndSaveSymbol(url: url, id: id);
    }
  }

  static String _symbolFileName(String url, String id) {
    final ext = p.extension(Uri.tryParse(url)?.path ?? '');
    final safeId = id.isNotEmpty ? id : url.hashCode.toString();
    return 'symbol_$safeId${ext.isNotEmpty ? ext : '.jpg'}';
  }

  // ─── Delete from device ───

  /// Deletes files associated with media URLs from the device.
  static Future<int> deleteMediaFiles(List<String> urls,
      {String messageType = 'image'}) async {
    int deleted = 0;
    final dir = await getMediaDir(messageType);
    final legacyDir = await ChatStoragePaths.legacyMediaDir(messageType);

    for (final url in urls) {
      try {
        final name = _fileNameFromUrl(url);
        for (final base in [dir.path, legacyDir.path]) {
          final file = File(p.join(base, name));
          if (await file.exists()) {
            await file.delete();
            deleted++;
          }
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
