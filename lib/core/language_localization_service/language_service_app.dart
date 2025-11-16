import 'dart:convert';
import 'package:BlueEra/features/personal/auth/repo/languages_repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class LocalizationService extends Translations {
  static final LocalizationService _instance = LocalizationService._internal();

  factory LocalizationService() => _instance;

  LocalizationService._internal();

  late Box box; // we’ll open it in init()

  final Map<String, Map<String, String>> _translations = {};

  /// Initialize Hive box before using service
  Future<void> init() async {
    box = await Hive.openBox('translations');
  }
  void clearInMemoryTranslations() {
    _translations.clear();
  }
  /// Loads translations from Hive if present, otherwise fetches from API
  Future<Map<String, String>> loadTranslations(String languageCode) async {
    try {
      // Step 1: load from memory first
      if (_translations.containsKey(languageCode)) {
        return _translations[languageCode]!;
      }

      // Step 2: load from Hive
      final stored = box.get(languageCode);
      Map<String, String> localData = {};
      if (stored != null && stored is Map) {
        localData = Map<String, String>.from(stored);
      }

      // Step 3: call API to get latest
      final response = await LanguageRepo().downloadLanguage(languageCode);
      if (response.statusCode == 200) {
        final raw = response.response?.data;
        final Map<String, dynamic> jsonData =
        raw is String ? jsonDecode(raw) : (raw is Map ? raw : {});
        final Map<String, String> formatted =
        jsonData.map((k, v) => MapEntry(k, v.toString()));

        // ✅ Step 4: Merge old + new keys
        final merged = {...localData, ...formatted};

        _translations[languageCode] = merged;

        // Step 5: Save back to Hive
        await box.put(languageCode, merged);
        return merged;
      }

      return localData;
    } catch (e, st) {
      print('⚠️ Error loading translations for $languageCode: $e\n$st');
      return {};
    }
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