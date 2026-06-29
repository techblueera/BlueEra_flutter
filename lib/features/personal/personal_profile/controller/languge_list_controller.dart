import 'dart:convert';

import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/language_localization_service/language_service_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../auth/repo/languages_repo.dart';
import '../../model/language.dart';
import '../../model/language_model.dart';

class LanguageListController extends GetxController {
  late Box languageBox;
  late Box localizationBox;

  RxList<LanguageModel> languages = <LanguageModel>[].obs;
  RxString selectedCode = ''.obs;
  RxString selectedLanguageName = ''.obs;
  RxSet<String> downloadingLanguages = <String>{}.obs;
  RxSet<String> downloadedLanguages = <String>{}.obs;
  RxMap<String, LocalizationModel> localizationData = <String, LocalizationModel>{}.obs;

  final LanguageRepo _repo = LanguageRepo();

  @override
  void onInit() {
    super.onInit();
    languageBox = Hive.box('languageBox');
    localizationBox = Hive.box('localizationBox');

    _loadSavedLanguage();

    // Default available languages
    languages.value = [
      LanguageModel(code: "en", name: "English"),
      LanguageModel(code: "hi", name: "Hindi"),
      // LanguageModel(code: "ta", name: "Tamil"),
      // LanguageModel(code: "te", name: "Telugu"),
      // LanguageModel(code: "ml", name: "Malayalam"),
    ];

    // Cache-first: rebuild from the locally cached list and only hit the
    // network when nothing is cached yet. This controller is registered on
    // every launch, so it must not call the languages API each time.
    fetchLanguages();
  }

  /// Hive key under which the raw available-languages list is cached so the
  /// names endpoint isn't called on every launch.
  static const String _availableLanguagesKey = 'available_languages';

  void _loadSavedLanguage() {
    final savedCode = languageBox.get('selected_language_code', defaultValue: 'en');
    final savedName = languageBox.get('selected_language_name', defaultValue: 'English');

    selectedCode.value = savedCode;
    selectedLanguageName.value = savedName;

    final savedLocalizationJson = localizationBox.get(savedCode);
    if (savedLocalizationJson != null) {
      final decoded = jsonDecode(savedLocalizationJson);
      localizationData[savedCode] = LocalizationModel.fromJson(decoded);
      downloadedLanguages.add(savedCode);
    }
  }

  Future<void> fetchLanguages({bool forceRefresh = false}) async {
    try {
      // Cache-first: rebuild from the cached list and skip the network unless
      // an explicit refresh is requested or nothing is cached yet.
      if (!forceRefresh) {
        final cached = languageBox.get(_availableLanguagesKey);
        if (cached is List && cached.isNotEmpty) {
          languages.value =
              cached.map((json) => LanguageModel.fromJson(json)).toList();
          return;
        }
      }

      final response = await _repo.getLanguagesRaw();


      if (response.isSuccess && response.response?.data != null) {
        final rawData = response.response?.data;
        logs("response====fffff ${rawData}");

        List<dynamic> dataList;

        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          dataList = rawData['data'];
        } else {
          return;
        }

        languages.value = dataList.map((json) => LanguageModel.fromJson(json)).toList();

        // Persist the raw list so future launches skip the network.
        try {
          await languageBox.put(_availableLanguagesKey, dataList);
        } catch (_) {}
      }
    } catch (e) {
      print("Error fetching languages: $e");
    }
  }
///OLD ONE...
  void selectLanguage_(String code) {
    selectedCode.value = code;
    final selectedLang = languages.firstWhereOrNull((lang) => lang.code == code);
    if (selectedLang != null) {
      selectedLanguageName.value = selectedLang.name;
      logs("lang.code 1 ${code} lang.name ${selectedLang.name}");
      Get.updateLocale( Locale("hi"));

      languageBox.put('selected_language_code', code);
      languageBox.put('selected_language_name', selectedLang.name);
    }
  }
  Future<void> selectLanguage(String code) async {

    selectedCode.value = code;
    await LocalizationService().updateLanguage(code);
    downloadedLanguages.add(code);

  }

  Future<void> downloadLanguage(String languageCode) async {
    if (downloadingLanguages.contains(languageCode)) return;

    try {
      downloadingLanguages.add(languageCode);
      final response = await _repo.downloadLanguage(languageCode);

      if (response.isSuccess && response.response?.data != null) {
        dynamic rawData = response.response?.data;
        if (rawData is String) rawData = jsonDecode(rawData);

        final model = LocalizationModel.fromJson(rawData);
        localizationData[languageCode] = model;
        downloadedLanguages.add(languageCode);

        // Save localization in Hive
        localizationBox.put(languageCode, jsonEncode(rawData));

        commonSnackBar(message: response.message ?? 'Language downloaded successfully');
      } else {
        commonSnackBar(message: response.message ?? 'Failed to download language');
      }
    } catch (e) {
      print('Error downloading language: $e');
      commonSnackBar(message: 'Failed to download language');
    } finally {
      downloadingLanguages.remove(languageCode);
    }
  }

  bool isLanguageDownloading(String code) => downloadingLanguages.contains(code);
  bool isLanguageDownloaded(String code) => downloadedLanguages.contains(code);

  String tr(String key) {
    final current = localizationData[selectedCode.value];
    return current?.getText(key) ?? key;
  }

  LocalizationModel? get currentLocalization => localizationData[selectedCode.value];
}