import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Hive-backed cache for the user's own personal profile JSON.
/// Keyed by `userId` so the cache survives between launches and is
/// scoped per-user. Best-effort: any read/write failure just falls
/// through to the network call.
class PersonalProfileCache {
  static const String _boxName = 'personalProfileCache';

  static Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return await Hive.openBox<String>(_boxName);
  }

  static Future<Map<String, dynamic>?> read(String key) async {
    if (key.isEmpty) return null;
    try {
      final box = await _openBox();
      final raw = box.get(key);
      if (raw == null || raw.isEmpty) {
        debugPrint('[PersonalProfileCache] miss for key=$key');
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        debugPrint('[PersonalProfileCache] hit for key=$key');
        return decoded;
      }
      return null;
    } catch (e) {
      debugPrint('[PersonalProfileCache] read error: $e');
      return null;
    }
  }

  static Future<void> write(String key, Map<String, dynamic> data) async {
    if (key.isEmpty) return;
    try {
      final box = await _openBox();
      await box.put(key, jsonEncode(data));
      debugPrint('[PersonalProfileCache] saved key=$key');
    } catch (e) {
      debugPrint('[PersonalProfileCache] write error: $e');
    }
  }

  static Future<void> clear() async {
    try {
      final box = await _openBox();
      await box.clear();
      debugPrint('[PersonalProfileCache] cleared');
    } catch (e) {
      debugPrint('[PersonalProfileCache] clear error: $e');
    }
  }
}
