import 'dart:convert';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/personal/auth/repo/languages_repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class LocalizationService extends Translations {
  static final LocalizationService _instance = LocalizationService._internal();

  factory LocalizationService() => _instance;

  LocalizationService._internal();

  static const String _boxName = 'translations';
  static const String fallbackLanguage = 'en';
  static late Box box; // we’ll open it in init()

  final Map<String, Map<String, String>> _translations = {};

  /// Initialize Hive box before using service
  Future<void> init() async {
    box = await _safeBox();
  }

  /// Returns an open translations box, reopening it if it was closed
  /// (e.g. after logout via Hive.deleteFromDisk()).
  Future<Box> _safeBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      box = Hive.box(_boxName);
      return box;
    }
    box = await Hive.openBox(_boxName);
    return box;
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

      // Step 3: load from Hive (use safe cast for release mode).
      // Re-open the box if it was closed (e.g. after logout via Hive.deleteFromDisk()).
      final safeBox = await _safeBox();
      final stored = safeBox.get(languageCode);
      Map<String, String> localData = {};
      if (stored != null && stored is Map) {
        try {
          localData = Map<String, String>.from(
            stored.map((k, v) => MapEntry(k.toString(), v.toString())),
          );
        } catch (_) {
          localData = {};
        }
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
      final apiData = await _fetchFromApi(languageCode);
      if (apiData.isNotEmpty) {
        final merged = {...assetData, ...apiData};
        _translations[languageCode] = merged;
        try {
          final putBox = await _safeBox();
          await putBox.put(languageCode, merged);
        } catch (_) {}
        return merged;
      }

      if (assetData.isNotEmpty) {
        _translations[languageCode] = assetData;
      }
      return assetData;
    } catch (e, st) {
      print('⚠️ Error loading translations for $languageCode: $e\n$st');
      // Fallback: try the requested language asset, then English asset.
      final assetData = await _loadAssetTranslations(languageCode);
      if (assetData.isNotEmpty) {
        _translations[languageCode] = assetData;
        return assetData;
      }
      final enFallback = await _loadAssetTranslations(fallbackLanguage);
      if (enFallback.isNotEmpty) {
        _translations[fallbackLanguage] = enFallback;
      }
      return enFallback;
    }
  }

  /// Safely parses translation data from API response.
  /// Uses response.data (which extracts the inner 'data' field from the API wrapper).
  Map<String, String> _parseTranslationResponse(ResponseModel response) {
    try {
      // response.data extracts the 'data' field from the wrapped API response
      // e.g. {"data": {"hello": "Hello", ...}, "message": "..."} → {"hello": "Hello", ...}
      final translationData = response.data ?? response.response?.data;
      if (translationData == null) return {};

      Map<String, dynamic> jsonData;
      if (translationData is String) {
        jsonData = Map<String, dynamic>.from(jsonDecode(translationData) as Map);
      } else if (translationData is Map) {
        jsonData = Map<String, dynamic>.from(translationData);
      } else {
        return {};
      }

      return jsonData.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  /// Fetches translations from API with retry
  Future<Map<String, String>> _fetchFromApi(String languageCode) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await LanguageRepo().downloadLanguage(languageCode);
        if (response.statusCode == 200) {
          return _parseTranslationResponse(response);
        }
      } catch (_) {
        if (attempt == 0) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
    return {};
  }

  /// Fetches latest translations from API in the background and updates cache.
  void _refreshFromApiInBackground(String languageCode) {
    Future(() async {
      try {
        final response = await LanguageRepo().downloadLanguage(languageCode);
        if (response.statusCode == 200) {
          final formatted = _parseTranslationResponse(response);
          if (formatted.isEmpty) return;

          final existing = _translations[languageCode] ?? {};
          final merged = {...existing, ...formatted};
          _translations[languageCode] = merged;
          try {
            final putBox = await _safeBox();
            await putBox.put(languageCode, merged);
          } catch (_) {}

          // Update GetX so the UI reflects new translations
          Get.clearTranslations();
          Get.addTranslations(_translations);
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
        final formatted = _parseTranslationResponse(response);
        if (formatted.isNotEmpty) {
          _translations[languageCode] = formatted;
          await box.put(languageCode, formatted);
          return formatted;
        }
      }
    } catch (e, st) {
      print('⚠️ Error loading translations for $languageCode: $e\n$st');
    }

    return {}; // fallback empty map
  }

  /// Dynamically updates app language. If translations cannot be loaded for
  /// [langCode], falls back to English from local assets so the app never
  /// ends up with an empty translation map.
  Future<void> updateLanguage(String langCode) async {
    var data = await loadTranslations(langCode);
    var effectiveLang = langCode;

    if (data.isEmpty) {
      print('⚠️ No translations found for $langCode — falling back to $fallbackLanguage');
      effectiveLang = fallbackLanguage;
      data = await _loadAssetTranslations(fallbackLanguage);
      if (data.isNotEmpty) {
        _translations[fallbackLanguage] = data;
      }
    }

    if (data.isEmpty) return;

    try {
      final putBox = await _safeBox();
      await putBox.put('selectedLanguage', effectiveLang);
    } catch (_) {}

    Get.clearTranslations();
    Get.addTranslations(_translations);
    Get.updateLocale(Locale(effectiveLang));
  }

  /// Load all cached languages at startup (optional)
  Future<void> preloadCachedLanguages() async {
    final safeBox = await _safeBox();
    for (final key in safeBox.keys) {
      if (key == 'selectedLanguage') continue;
      final value = safeBox.get(key);
      if (value is Map) {
        try {
          _translations[key] = Map<String, String>.from(
            (value).map((k, v) => MapEntry(k.toString(), v.toString())),
          );
        } catch (_) {
          // Skip corrupted entries
        }
      }
    }
  }

  @override
  Map<String, Map<String, String>> get keys => _translations;

}