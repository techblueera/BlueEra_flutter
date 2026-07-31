import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/individual_user_response_model.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/language_localization_service/language_model_new.dart';
import 'package:BlueEra/core/language_localization_service/language_service_app.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/auth/repo/personal_profile_repo.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class LanguageControllerNew extends GetxController {
  static const String _boxName = 'translations';
  static const String _fallbackLang = 'en';

  /// Hive key under which the raw `.../languages/names` response is cached so
  /// the names endpoint is only hit once per login (or on explicit refresh)
  /// instead of on every screen open / launch.
  static const String _namesCacheKey = 'languageNames';
  static const List<String> _supportedLangCodes = [
    'en',
    'hi',
    'kn',
    'gu',
    'mr'
  ];

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

  /// Loads the available-languages list.
  ///
  /// Cache-first: builds the list from the Hive-cached names response and does
  /// NOT hit the network on normal launches / screen opens. The
  /// `.../languages/names` endpoint is only called when [forceRefresh] is true
  /// (the once-per-login refresh) or when no cached names exist yet.
  Future<void> loadLanguages({bool forceRefresh = false}) async {
    try {
      final box = await _safeBox();
      final savedLangCode =
          box.get('selectedLanguage', defaultValue: _fallbackLang) as String;
      selectedLang.value = savedLangCode;

      List? data;

      // Use the cached names list unless an explicit refresh is requested.
      if (!forceRefresh) {
        final cached = box.get(_namesCacheKey);
        if (cached is List) data = cached;
      }

      // Fetch from the network only when forced or when nothing is cached.
      if (data == null) {
        final langsParam = _supportedLangCodes.join(',');
        final uri = Uri.parse('${baseUrl}language-service/languages/names')
            .replace(queryParameters: {'languages': langsParam});
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          data = jsonDecode(response.body) as List;
          // Persist the raw list so future launches skip the network.
          try {
            await box.put(_namesCacheKey, data);
          } catch (_) {}
        }
      }

      if (data == null) return;

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
    } catch (e) {
      print('⚠️ loadLanguages failed: $e');
      selectedLang.value = _fallbackLang;
    }
  }

  /// Refreshes the available-languages list + the current language's
  /// translations from the server exactly **once per login lifecycle**.
  ///
  /// The language API is otherwise never called on launch — translations are
  /// served from the local Hive cache. This single refresh keeps them fresh
  /// after each login. The gate flag lives in the `translations` box, which is
  /// wiped on logout (`LogoutHelper.clearAllLocalData()`), so the next login
  /// triggers one fresh refresh again.
  ///
  /// Safe to call on every launch: it no-ops when logged out or when the gate
  /// is already satisfied. [assumeLoggedIn] skips the in-memory login check —
  /// pass it from the OTP login-success path, where the just-issued token
  /// proves the user is logged in but `isUserLoginGlobal` may not have been
  /// refreshed yet this session.
  Future<void> refreshAfterLoginOnce({bool assumeLoggedIn = false}) async {
    if (!assumeLoggedIn && isUserLoginGlobal != "true") return;

    final localizationService = LocalizationService();
    if (!await localizationService.needsLoginRefresh()) return;

    try {
      await loadLanguages(forceRefresh: true);
      await localizationService.refreshCurrentLanguageFromApi();
      await localizationService.markLoginRefreshDone();
    } catch (e) {
      // Network/parse failure — leave the gate unset so the next launch or
      // login retries. Local cache continues to serve translations meanwhile.
      log('refreshAfterLoginOnce failed: $e');
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
      ResponseModel responseModel = await PersonalProfileRepo().updateUser(
        formData: {
          ApiKeys.language: langCode,
          "account_type": accountTypeGlobal.toUpperCase()
        },
        showProgress: false,
      );
      if (responseModel.isSuccess) {
        // `updateIndividualAccountUser` re-issues the JWT on every successful
        // update — its payload embeds the user snapshot, so the token we hold
        // goes stale the moment the profile changes. Persist the new one
        // before the profile refreshes below, since `ApiBaseHelper` reads
        // `authTokenGlobal` live on each request.
        await _persistRefreshedToken(responseModel);

        if (accountTypeGlobal.toUpperCase() == "INDIVIDUAL") {
          await Get.find<ViewPersonalDetailsController>()
              .viewPersonalProfile(forceRefresh: true);
        }
        if (accountTypeGlobal.toUpperCase() == "BUSINESS") {
          final viewProfileController =
              getOrPut(() => ViewBusinessDetailsController(), permanent: true);
          await viewProfileController.viewBusinessProfile();
        }
      }
    } catch (e) {
      log('Failed to sync language preference to server: $e');
    }
  }

  /// Stores the JWT that `updateIndividualAccountUser` returns alongside
  /// `{status, message, user}` into secure storage and [authTokenGlobal].
  ///
  /// No-ops when the body carries no token. A 2xx without one is a partial
  /// response, and writing an empty value would sign the user out of a
  /// background language sync they never asked to be logged out by — the
  /// previous token stays valid in that case.
  Future<void> _persistRefreshedToken(ResponseModel responseModel) async {
    final upgraded = IndividualUserResponseModel.fromJson(
        (responseModel.response?.data is Map)
            ? Map<String, dynamic>.from(responseModel.response!.data as Map)
            : <String, dynamic>{});

    final refreshedToken = upgraded.token;
    if (refreshedToken == null || refreshedToken.isEmpty) return;
    if (refreshedToken == authTokenGlobal) return;

    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.authToken, refreshedToken);
    // Set the global straight from the response rather than re-reading the key
    // we just wrote — flutter_secure_storage round-trips are the slow part of
    // this path, and the written value is what the read would return anyway.
    authTokenGlobal = refreshedToken;
  }
}
