import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:get/get.dart';

import '../../auth/repo/languages_repo.dart';
import '../../model/language_model.dart';

class LanguageListController extends GetxController {
  RxList<LanguageModel> languages = <LanguageModel>[].obs;
  RxString selectedCode = ''.obs;
  RxString selectedLanguageName = ''.obs; 
  RxSet<String> downloadingLanguages = <String>{}.obs;
  RxSet<String> downloadedLanguages = <String>{}.obs;

  final LanguageRepo _repo = LanguageRepo();

  @override
  void onInit() {
    super.onInit();

    languages.value = [
      LanguageModel(code: "en", name: "English"),
      LanguageModel(code: "hi", name: "Hindi"),
      LanguageModel(code: "ta", name: "Tamil"),
      LanguageModel(code: "te", name: "Telugu"),
      LanguageModel(code: "ml", name: "Malayalam"),
    ];

    selectedCode.value = "en";
    selectedLanguageName.value = "English"; 
    fetchLanguages();
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

        languages.value = dataList.map((json) {
          return LanguageModel.fromJson(json as Map<String, dynamic>);
        }).toList();
      }
    } catch (e) {
      print("Error fetching languages: $e");
    }
  }

  void selectLanguage(String code) {
    selectedCode.value = code;

    
    final selectedLang = languages.firstWhereOrNull((lang) => lang.code == code);
    if (selectedLang != null) {
      selectedLanguageName.value = selectedLang.name ?? '';
    }
  }

  Future<void> downloadLanguage(String languageCode) async {
    if (downloadingLanguages.contains(languageCode)) {
      return;
    }

    try {
      downloadingLanguages.add(languageCode);
      final response = await _repo.downloadLanguage(languageCode);

      if (response.isSuccess) {
        downloadedLanguages.add(languageCode);
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

  bool isLanguageDownloading(String code) {
    return downloadingLanguages.contains(code);
  }

  bool isLanguageDownloaded(String code) {
    return downloadedLanguages.contains(code);
  }
}
