import 'dart:convert';

import 'package:BlueEra/core/language_localization_service/language_model_new.dart';
import 'package:BlueEra/core/language_localization_service/language_service_app.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

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
