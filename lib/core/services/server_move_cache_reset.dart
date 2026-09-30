import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Empties the network-image cache once after the move to the new server
/// (docs/DEVELOPER-TASKS-FRONTEND.md, F6).
///
/// The server team rewrote old media links to the new hosts. Images already
/// cached under the old URLs would otherwise keep showing (or keep failing)
/// until they expired, so the first launch of this build drops them and they
/// download again from the new URLs. The flag makes it a one-off: later
/// launches skip it.
class ServerMoveCacheReset {
  ServerMoveCacheReset._();

  static const doneKey = 'server_move_2026_09_image_cache_cleared';

  /// Clears the cache unless it was already done. Never throws: an old cache
  /// is only cosmetic, so a failure here must not affect startup.
  static Future<void> runOnce({Future<void> Function()? emptyCache}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(doneKey) ?? false) return;
      await (emptyCache ?? DefaultCacheManager().emptyCache)();
      await prefs.setBool(doneKey, true);
    } catch (e) {
      debugPrint('ServerMoveCacheReset failed: $e');
    }
  }
}
