  import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:get/get.dart';

  class LanguagesController extends GetxController {
    final ResumeRepo _repo = ResumeRepo();

    final languages = <String>[].obs;
    final speakLanguages = <LanguageType>[].obs;
    final writeLanguages = <LanguageType>[].obs;

    final selectedSpeakLanguage = Rxn<LanguageType>();
    final selectedWriteLanguage = Rxn<LanguageType>();
    final isLoading = false.obs;
    final isFirstTime = true.obs;

    @override
    void onInit() {
      getLanguagesApi();
      super.onInit();
    }

    @override
    void onClose() {
      super.onClose();
    }

    Future<void> getLanguagesApi() async {
      try {
        isLoading(true);
        final response = await _repo.getLanguages();
        isLoading(false);

        if (response.isSuccess) {
          final data = response.response?.data['languages']?[0];

          final speakList = List<String>.from(data?['speakAndUnderstand'] ?? []);
          final writeList = List<String>.from(data?['write'] ?? []);

          speakLanguages.value = speakList
              .map((e) => LanguageType.values.firstWhere((l) => l.label == e))
              .toList();

          writeLanguages.value = writeList
              .map((e) => LanguageType.values.firstWhere((l) => l.label == e))
              .toList();

          // flag update
          isFirstTime.value = speakLanguages.isEmpty && writeLanguages.isEmpty;
        }
      } catch (e) {
        isLoading(false);
      }
    }


    void _populateLanguageTypesFromStrings() {
      speakLanguages.clear();
      writeLanguages.clear();

      for (String lang in languages) {
        LanguageType? langType = LanguageType.values.firstWhereOrNull((l) => l.label == lang);
        if (langType != null) {
          speakLanguages.add(langType);
        }
      }
    }



  Future<void> saveLanguages() async {
    final speakList = speakLanguages.map((e) => e.label).toList();
    final writeList = writeLanguages.map((e) => e.label).toList();

    if (speakList.isEmpty && writeList.isEmpty) {
      commonSnackBar(message: "Please add at least one language");
      return;
    }

    final params = {
      "speakAndUnderstand": speakList,
      "write": writeList,
    };

    print("Saving languages with payload: $params"); // For debug

    try {
      isLoading.value = true;
      final response = await _repo.addLanguages(params: params);

      if (response.isSuccess) {
        commonSnackBar(message: response.response?.data['message'] ?? "Success");
        await getLanguagesApi();
        Get.back();
      } else {
        commonSnackBar(message: response.response?.data['message'] ?? "Something went wrong");
      }
    } catch (e) {
      commonSnackBar(message: "Something went wrong");
    } finally {
      isLoading.value = false;
    }
  }


    void addSpeakLanguage(LanguageType language) {
      if (!speakLanguages.contains(language)) {
        speakLanguages.add(language);
        selectedSpeakLanguage.value = null;
      }
    }

    void removeSpeakLanguage(LanguageType language) {
      speakLanguages.remove(language);
    }

    void addWriteLanguage(LanguageType language) {
      if (!writeLanguages.contains(language)) {
        writeLanguages.add(language);
        selectedWriteLanguage.value = null;
      }
    }

    void removeWriteLanguage(LanguageType language) {
      writeLanguages.remove(language);
    }



  Future<void> deleteLanguageApi({
    required String language,
    required String category,
  }) async {
    try {
      isLoading.value = true;

      final response = await _repo.deleteLanguage(category: category, language: language);

      if (response.isSuccess) {
        final responseData = response.response?.data;
        if (responseData != null && responseData['languages'] != null) {
          languages.value = List<String>.from(responseData['languages']);
          _populateLanguageTypesFromStrings();
        }

        commonSnackBar(message: "${response.response?.data['message'] ?? AppStrings.success}");
        await getLanguagesApi(); // refresh after delete
      } else {
        commonSnackBar(message: "${response.response?.data['message'] ?? AppStrings.somethingWentWrong}");
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

    String extractLanguageName(Map<String, dynamic> data) {
      final sortedKeys = data.keys.where((k) => int.tryParse(k) != null).toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      return sortedKeys.map((k) => data[k]).join();
    }

    bool get isFormValid => speakLanguages.isNotEmpty || writeLanguages.isNotEmpty;

    void removeLanguageByCategory(LanguageType language, String category) {
    if (category == 'speakAndUnderstand') {
      removeSpeakLanguage(language);
    } else if (category == 'write') {
      removeWriteLanguage(language);
    }
    // Also call API delete method here or from UI after confirmation.
    deleteLanguageApi(language: language.label, category: category);
  }

  }