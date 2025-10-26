import 'dart:convert';

import 'package:BlueEra/core/constants/snackbar_helper.dart';
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
      LanguageModel(code: "ta", name: "Tamil"),
      LanguageModel(code: "te", name: "Telugu"),
      LanguageModel(code: "ml", name: "Malayalam"),
    ];

    fetchLanguages();
  }

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

  Future<void> fetchLanguages() async {
    try {
      final response = await _repo.getLanguagesRaw();
      if (response.isSuccess && response.response?.data != null) {
        final rawData = response.response?.data;
        List<dynamic> dataList;

        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          dataList = rawData['data'];
        } else {
          return;
        }

        languages.value = dataList.map((json) => LanguageModel.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error fetching languages: $e");
    }
  }

  void selectLanguage(String code) {
    selectedCode.value = code;
    final selectedLang = languages.firstWhereOrNull((lang) => lang.code == code);
    if (selectedLang != null) {
      selectedLanguageName.value = selectedLang.name;

      languageBox.put('selected_language_code', code);
      languageBox.put('selected_language_name', selectedLang.name);
    }
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