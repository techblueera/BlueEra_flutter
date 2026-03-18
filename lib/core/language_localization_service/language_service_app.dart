import 'dart:convert';

import 'package:BlueEra/features/personal/auth/repo/languages_repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class LocalizationService extends Translations {
  static final LocalizationService _instance = LocalizationService._internal();

  factory LocalizationService() => _instance;

  LocalizationService._internal();

  static late Box box; // we’ll open it in init()

  final Map<String, Map<String, String>> _translations = {};

  /// Initialize Hive box before using service
  Future<void> init() async {
    box = await Hive.openBox('translations');
  }
  void clearInMemoryTranslations() {
    _translations.clear();
  }
  /// Loads local asset translations as a base fallback
  Future<Map<String, String>> _loadAssetTranslations(String languageCode) async {
    try {
      final jsonStr = await rootBundle.loadString('assets/translations/$languageCode.json');
      final Map<String, dynamic> jsonData = jsonDecode(jsonStr);
      return jsonData.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  /// Loads translations — returns cached data instantly, fetches API in background.
  /// This avoids blocking the UI on network calls during language switch.
  Future<Map<String, String>> loadTranslations(String languageCode) async {
    try {
      // Step 1: return from memory instantly
      if (_translations.containsKey(languageCode)) {
        // Still refresh from API in background for next time
        _refreshFromApiInBackground(languageCode);
        return _translations[languageCode]!;
      }

      // Step 2: load local asset JSON as base
      final assetData = await _loadAssetTranslations(languageCode);

      // Step 3: load from Hive
      final stored = box.get(languageCode);
      Map<String, String> localData = {};
      if (stored != null && stored is Map) {
        localData = Map<String, String>.from(stored);
      }

      // Step 4: If we have local data (asset + hive), use it immediately
      //         and fetch API in background for freshness
      final localMerged = {...assetData, ...localData};
      if (localMerged.isNotEmpty) {
        _translations[languageCode] = localMerged;
        _refreshFromApiInBackground(languageCode);
        return localMerged;
      }

      // Step 5: No local data at all — must fetch from API (first-time only)
      final response = await LanguageRepo().downloadLanguage(languageCode);
      if (response.statusCode == 200) {
        final raw = response.response?.data;
        final Map<String, dynamic> jsonData =
        raw is String ? jsonDecode(raw) : (raw is Map ? raw : {});
        final Map<String, String> formatted =
        jsonData.map((k, v) => MapEntry(k, v.toString()));

        final merged = {...assetData, ...formatted};
        _translations[languageCode] = merged;
        await box.put(languageCode, merged);
        return merged;
      }

      return assetData;
    } catch (e, st) {
      print('⚠️ Error loading translations for $languageCode: $e\n$st');
      return {};
    }
  }

  /// Fetches latest translations from API in the background and updates cache.
  void _refreshFromApiInBackground(String languageCode) {
    Future(() async {
      try {
        final response = await LanguageRepo().downloadLanguage(languageCode);
        if (response.statusCode == 200) {
          final raw = response.response?.data;
          final Map<String, dynamic> jsonData =
          raw is String ? jsonDecode(raw) : (raw is Map ? raw : {});
          final Map<String, String> formatted =
          jsonData.map((k, v) => MapEntry(k, v.toString()));

          final existing = _translations[languageCode] ?? {};
          final merged = {...existing, ...formatted};
          _translations[languageCode] = merged;
          await box.put(languageCode, merged);
        }
      } catch (_) {
        // Silent — background refresh, don't block UI
      }
    });
  }

  Future<Map<String, String>> loadTranslations_(String languageCode) async {
    try {
      // 1️⃣ If translations already in memory → return directly
      if (_translations.containsKey(languageCode)) {
        return _translations[languageCode]!;
      }

      // 2️⃣ If saved in Hive → use that
      final stored = box.get(languageCode);
      if (stored != null && stored is Map) {
        final localData = Map<String, String>.from(stored);
        _translations[languageCode] = localData;
        return localData;
      }

      // 3️⃣ Otherwise → download from API
      final response = await LanguageRepo().downloadLanguage(languageCode);
      if (response.statusCode == 200) {
        final raw = response.response?.data;

        // Handle both string & map responses safely
        final Map<String, dynamic> jsonData = raw is String
            ? jsonDecode(raw)
            : (raw is Map ? raw : <String, dynamic>{});

        final Map<String, String> formatted =
            jsonData.map((k, v) => MapEntry(k, v.toString()));

        _translations[languageCode] = formatted;

        await box.put(languageCode, formatted);
        return formatted;
      }
    } catch (e, st) {
      print('⚠️ Error loading translations for $languageCode: $e\n$st');
    }

    return {}; // fallback empty map
  }

  /// Dynamically updates app language
  Future<void> updateLanguage(String langCode) async {
    final data = await loadTranslations(langCode);

    if (data.isNotEmpty) {
      await box.put('selectedLanguage', langCode);

      Get.clearTranslations();
      Get.addTranslations(_translations);
      Get.updateLocale(Locale(langCode));
    } else {
      print('⚠️ No translations found for $langCode');
    }
  }

  /// Load all cached languages at startup (optional)
  Future<void> preloadCachedLanguages() async {
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        _translations[key] = Map<String, String>.from(value);
      }
    }
  }

  @override
  Map<String, Map<String, String>> get keys => _translations;

}