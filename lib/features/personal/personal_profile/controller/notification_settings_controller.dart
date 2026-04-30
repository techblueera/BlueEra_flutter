import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/model/notification_settings_model.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:get/get.dart';

class NotificationSettingsController extends GetxController {
  final Rx<ApiResponse> getResponse = ApiResponse.initial('Initial').obs;
  final RxBool isUpdating = false.obs;

  final RxMap<String, NotificationChannelPrefs> preferences =
      <String, NotificationChannelPrefs>{}.obs;

  Map<String, NotificationChannelPrefs> _original = {};

  @override
  void onInit() {
    super.onInit();
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    try {
      getResponse.value = ApiResponse.loading('Loading');
      final ResponseModel response =
          await UserRepo().getNotificationSettingsRepo();
      if (response.isSuccess && response.response?.data != null) {
        final model =
            NotificationSettingsModel.fromJson(response.response?.data);
        preferences
          ..clear()
          ..addAll(model.preferences);
        _original = model.copy().preferences;
        getResponse.value = ApiResponse.complete(response);
      } else {
        getResponse.value =
            ApiResponse.error(response.message ?? AppStrings.somethingWentWrong);
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getResponse.value = ApiResponse.error('Error: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  void togglePush(String key, bool value) {
    final pref = preferences[key];
    if (pref == null) return;
    pref.push = value;
    preferences.refresh();
  }

  void toggleInApp(String key, bool value) {
    final pref = preferences[key];
    if (pref == null) return;
    pref.inApp = value;
    preferences.refresh();
  }

  bool get hasChanges {
    if (_original.length != preferences.length) return true;
    for (final entry in preferences.entries) {
      final orig = _original[entry.key];
      if (orig == null) return true;
      if (orig.push != entry.value.push || orig.inApp != entry.value.inApp) {
        return true;
      }
    }
    return false;
  }

  String? validate() {
    if (preferences.isEmpty) {
      return AppStrings.somethingWentWrong;
    }
    if (!hasChanges) {
      return 'No changes to save';
    }
    return null;
  }

  Future<void> submit() async {
    final error = validate();
    if (error != null) {
      commonSnackBar(message: error);
      return;
    }
    try {
      isUpdating.value = true;
      final body = NotificationSettingsModel(preferences: preferences)
          .toRequestBody();
      final ResponseModel response =
          await UserRepo().updateNotificationSettingsRepo(body: body);
      if (response.isSuccess) {
        _original = {
          for (final e in preferences.entries) e.key: e.value.copy(),
        };
        commonSnackBar(message: response.message ?? AppStrings.success);
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (_) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isUpdating.value = false;
    }
  }
}
