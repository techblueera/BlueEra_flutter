import 'dart:convert';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/personal/auth/repo/languages_repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

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

  /// Loads translations from Hive if present, otherwise fetches from API
  Future<Map<String, String>> loadTranslations(String languageCode) async {
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


class LanguageControllerNew extends GetxController {
  final languages = <LanguageModelNew>[].obs;
  final box = Hive.box('translations');
  final selectedLang = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadLanguages();
  }

  Future<void> loadLanguages() async {
    // Example static or from API
    final savedLangCode = box.get('selectedLanguage', defaultValue: 'en');
    selectedLang.value = savedLangCode;

    final response = await http
        .get(Uri.parse('${baseUrl}language-service/languages'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      languages.value = data.map((e) {
        final code = e['languageCode'];
        final isDownloaded = box.get(code) != null;
        final isSelected = box.get('selectedLanguage') == code;
        return LanguageModelNew(
          name: e['languageName'],
          code: code,
          isDownloaded: code == "en" ? true : isDownloaded,
          isSelected: isSelected,
        );
      }).toList();
    }
  }

  Future<void> downloadLanguage(LanguageModelNew lang) async {
    await LocalizationService().loadTranslations(lang.code);
    await box.put(lang.code, true);
    lang.isDownloaded = true;
    languages.refresh();
  }

  Future<void> changeLanguage(LanguageModelNew lang) async {
    await LocalizationService().updateLanguage(lang.code);
    selectedLang.value = lang.code;

    // Update UI states
    for (final l in languages) {
      l.isSelected = (l.code == lang.code);
    }
    lang.isDownloaded = true;

    languages.refresh();
  }
}

class LanguageModelNew {
  final String name;
  final String code;
  bool isDownloaded;
  bool isSelected;

  LanguageModelNew({
    required this.name,
    required this.code,
    this.isDownloaded = false,
    this.isSelected = false,
  });
}
