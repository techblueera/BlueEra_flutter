import 'dart:convert';

import 'package:hive/hive.dart';

/// Local cache for the logged-in user's OWN emergency profile.
///
/// The own emergency profile is fetched once after login and then served from
/// this cache, so `emergency-service/emergency-profile/{id}` is not called
/// again on subsequent screen opens. The cache is keyed by user id and is
/// wiped on logout (the box is deleted by `Hive.deleteFromDisk()` in
/// `LogoutHelper.clearAllLocalData()`), so a re-login refetches exactly once.
/// It is also cleared whenever the user mutates their emergency data (see
/// `EmergencyServiceRepo`), so the next fetch refreshes.
///
/// Deep-linked / scanned profiles of OTHER users are never cached here — only
/// the owner's own profile (id == userId) is.
class EmergencyProfileCache {
  static const String _boxName = 'emergency_profile_box';

  static final EmergencyProfileCache _instance =
      EmergencyProfileCache._internal();

  factory EmergencyProfileCache() => _instance;

  EmergencyProfileCache._internal();

  /// Returns an open box, reopening it if it was closed (e.g. after logout
  /// via `Hive.deleteFromDisk()`), so callers never touch a closed box.
  Future<Box> _safeBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return await Hive.openBox(_boxName);
  }

  /// Caches the raw emergency-profile data object (the inner `data` map with
  /// basicInfo / emergencyContacts / privacyAlert) for [userId].
  Future<void> save(String userId, Map<String, dynamic> data) async {
    if (userId.isEmpty) return;
    try {
      final box = await _safeBox();
      await box.put(userId, jsonEncode(data));
    } catch (_) {}
  }

  /// Returns the cached emergency-profile data for [userId], or null on miss.
  Future<Map<String, dynamic>?> get(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final box = await _safeBox();
      final raw = box.get(userId);
      if (raw is! String) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Clears all cached emergency profiles — called after a successful mutation
  /// (so the next fetch refreshes) and is a no-op safety net on logout.
  Future<void> clear() async {
    try {
      final box = await _safeBox();
      await box.clear();
    } catch (_) {}
  }
}
