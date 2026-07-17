import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Single source of truth for BlueEra's on-device chat storage tree.
///
/// WhatsApp-style layout: one app folder holding separate sub-folders for the
/// chat-history database, media files, and symbols.
///
///   Android 10+ (API 29+):
///     /storage/emulated/0/Android/media/ai.bluecs.app/
///       ├─ Chat History/     (Hive box files + `.nomedia`)
///       ├─ Media/
///       │    ├─ BlueEra Images/
///       │    ├─ BlueEra Video/
///       │    ├─ BlueEra Audio/
///       │    └─ BlueEra Documents/
///       └─ Symbols/
///     → Writable without any permission, indexed by MediaStore (Media/ and
///       Symbols/ show in the gallery; Chat History/ carries a `.nomedia`).
///
///   Android < 10:
///     /storage/emulated/0/BlueEra/...   (requires storage permission)
///
///   iOS:
///     <AppDocuments>/BlueEra/...        (visible in the Files app)
///
/// [ChatMediaStorageService] and [LocalStorageHelper] both build their paths
/// on top of this class so the whole app agrees on one folder tree.
class ChatStoragePaths {
  ChatStoragePaths._();

  static const String packageName = 'ai.bluecs.app';

  // Top-level sub-folder names under the app root.
  static const String historyFolder = 'Chat History';
  static const String mediaFolder = 'Media';
  static const String symbolsFolder = 'Symbols';

  // Cache the resolved SDK version and app root so we don't hit the platform
  // channel / plugin on every media save.
  static int? _cachedSdk;
  static Directory? _cachedRoot;

  static Future<int> androidSdk() async {
    if (_cachedSdk != null) return _cachedSdk!;
    if (!Platform.isAndroid) return _cachedSdk = 0;
    final info = await DeviceInfoPlugin().androidInfo;
    return _cachedSdk = info.version.sdkInt;
  }

  /// The BlueEra app root that all sub-folders hang off of. Does NOT create it.
  static Future<Directory> root() async {
    if (_cachedRoot != null) return _cachedRoot!;
    if (Platform.isAndroid) {
      final sdk = await androidSdk();
      if (sdk >= 29) {
        // App-specific external media dir — no permission required, survives
        // until uninstall, and is browsable in a file manager.
        return _cachedRoot =
            Directory('/storage/emulated/0/Android/media/$packageName');
      }
      // Legacy public storage (needs permission, requested lazily).
      return _cachedRoot = Directory('/storage/emulated/0/BlueEra');
    }
    // iOS: app documents folder (visible in Files app).
    final docs = await getApplicationDocumentsDirectory();
    return _cachedRoot = Directory(p.join(docs.path, 'BlueEra'));
  }

  // ── Sub-folder resolution ──────────────────────────────────────────────

  /// WhatsApp-style per-type media sub-folder name.
  static String mediaSubFolder(String messageType) {
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

  static Future<Directory> _sub(String name, {bool ensure = true}) async {
    final r = await root();
    final dir = Directory(p.join(r.path, name));
    if (ensure && !await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Chat-history directory (holds Hive box files). Guarded with a `.nomedia`
  /// on Android so the media scanner never indexes the database files.
  static Future<Directory> historyDir() async {
    if (Platform.isAndroid && await androidSdk() < 29) {
      await _requestLegacyStoragePermission();
    }
    final dir = await _sub(historyFolder);
    if (Platform.isAndroid) {
      final noMedia = File(p.join(dir.path, '.nomedia'));
      if (!await noMedia.exists()) {
        try {
          await noMedia.create();
        } catch (_) {}
      }
    }
    return dir;
  }

  /// Media directory for a given [messageType] (nested under `Media/`).
  static Future<Directory> mediaDir(String messageType) async {
    if (Platform.isAndroid && await androidSdk() < 29) {
      await _requestLegacyStoragePermission();
    }
    return _sub(p.join(mediaFolder, mediaSubFolder(messageType)));
  }

  /// Symbols directory (cached symbol photos/videos).
  static Future<Directory> symbolsDir() async {
    if (Platform.isAndroid && await androidSdk() < 29) {
      await _requestLegacyStoragePermission();
    }
    return _sub(symbolsFolder);
  }

  // ── Legacy media path (pre-`Media/` nesting) ───────────────────────────
  //
  // Older builds saved media flat under the app root (…/ai.bluecs.app/BlueEra
  // Images) instead of under a `Media/` folder. Reads fall back to this path so
  // already-downloaded files still resolve after the upgrade.
  static Future<Directory> legacyMediaDir(String messageType) async {
    return _sub(mediaSubFolder(messageType), ensure: false);
  }

  // ── Bulk init & teardown ───────────────────────────────────────────────

  /// Pre-create the whole folder tree and request any needed permission.
  /// Call once at app startup.
  static Future<void> ensureAllDirs() async {
    try {
      if (Platform.isAndroid && await androidSdk() < 29) {
        await _requestLegacyStoragePermission();
      }
      await historyDir();
      const types = ['image', 'video', 'audio', 'document'];
      for (final type in types) {
        await mediaDir(type);
      }
      await symbolsDir();
      debugPrint('ChatStoragePaths: folder tree ready at ${(await root()).path}');
    } catch (e) {
      debugPrint('ChatStoragePaths: init error: $e');
    }
  }

  /// Wipe the chat-history folder (Hive box files). Used on logout — the
  /// history lives outside the default Hive dir, so `Hive.deleteFromDisk()`
  /// alone would leave the previous user's cached chats behind.
  static Future<void> clearHistory() async {
    try {
      final dir = await _sub(historyFolder, ensure: false);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('ChatStoragePaths: clearHistory error: $e');
    }
  }

  static Future<bool> _requestLegacyStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }
}
