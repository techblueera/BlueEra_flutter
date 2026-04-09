import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/guest_model_response.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/language_localization_service/language_model_new.dart';
import 'package:BlueEra/core/language_localization_service/language_service_app.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/auth/repo/personal_profile_repo.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class LanguageControllerNew extends GetxController {
  static const String _boxName = 'translations';
  static const String _fallbackLang = 'en';

  final languages = <LanguageModelNew>[].obs;
  Box? _box;
  final selectedLang = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initBox();
  }

  /// Returns an open translations box, reopening it if it was closed
  /// (e.g. after logout via Hive.deleteFromDisk()).
  Future<Box> _safeBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
    return _box!;
  }

  Future<void> _initBox() async {
    await _safeBox();
    await loadLanguages();
  }

  /// Resets the controller state. Call this after logout/login so the
  /// previously cached box reference and in-memory selection are dropped.
  Future<void> reset() async {
    _box = null;
    selectedLang.value = '';
    languages.clear();
    LocalizationService().clearInMemoryTranslations();
    await _safeBox();
    await loadLanguages();
  }

  Future<void> loadLanguages() async {
    try {
      final box = await _safeBox();
      final savedLangCode =
          box.get('selectedLanguage', defaultValue: _fallbackLang) as String;
      selectedLang.value = savedLangCode;

      final response =
          await http.get(Uri.parse('${baseUrl}language-service/languages/names?languages=en%2Chi'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final freshBox = await _safeBox();

        languages.value = data.map((e) {
          final code = e['languageCode'];
          final isDownloaded = freshBox.get(code) != null;
          final isSelected = freshBox.get('selectedLanguage') == code;
          return LanguageModelNew(
            name: e['languageName'],
            code: code,
            isDownloaded: code == _fallbackLang ? true : isDownloaded,
            isSelected: isSelected,
          );
        }).toList();
      }
    } catch (e) {
      print('⚠️ loadLanguages failed: $e');
      selectedLang.value = _fallbackLang;
    }
  }

  Future<void> downloadLanguage(LanguageModelNew lang) async {
    await LocalizationService().loadTranslations(lang.code);
    lang.isDownloaded = true;
    languages.refresh();
  }

  Future<void> changeLanguage(LanguageModelNew lang) async {
    await LocalizationService().updateLanguage(lang.code);

    // Read the language that was actually applied (LocalizationService may
    // have fallen back to English if the selected language failed to load).
    String appliedCode = lang.code;
    try {
      final box = await _safeBox();
      appliedCode =
          (box.get('selectedLanguage', defaultValue: lang.code) as String);
    } catch (_) {}

    selectedLang.value = appliedCode;

    // Update UI states
    for (final l in languages) {
      l.isSelected = (l.code == appliedCode);
    }
    if (appliedCode == lang.code) {
      lang.isDownloaded = true;
    }

    languages.refresh();

    // Sync the selected language to the server (only if logged in).
    _syncLanguageWithServer(appliedCode);
  }

  /// Pushes the user's language preference to the backend via the user
  /// profile update PUT API. Silently no-ops if the user isn't logged in
  /// or the call fails — local state is the source of truth for the UI.
  Future<void> _syncLanguageWithServer(String langCode) async {
    final token = authTokenGlobal;
    if (token == null || token.isEmpty) return;
    try {
      ResponseModel responseModel =  await PersonalProfileRepo().updateUser(
        formData: {ApiKeys.language: langCode},
        showProgress: false,
      );


      // ResponseModel responseModel = await PersonalProfileRepo().updateUser(
      //     formData: params,
      //     showProgress: showProgress
      // );

      if (responseModel.isSuccess) {
        GuestUserResModel guestUserResModel =
        GuestUserResModel.fromJson(responseModel.response?.data);
        await Get.find<ViewPersonalDetailsController>().viewPersonalProfile();

        await SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.authToken, guestUserResModel.token);
        await getUserAuthToken();
      }
    } catch (e) {
      log('⚠️ Failed to sync language preference to server: $e');
    }
  }
}
