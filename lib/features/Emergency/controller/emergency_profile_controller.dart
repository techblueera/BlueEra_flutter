import 'package:BlueEra/features/personal/emergency/repo/emergency_service_repo.dart';
import 'package:get/get.dart';
import '../model/emergency_profile_model.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

/// Drives the read-only emergency profile *view* screen
/// ([EmergencyProfileScreen1]).
///
/// Named distinctly from `personal/emergency`'s `EmergencyProfileController`
/// (which backs the QR widget) — GetX keys instances by class name, so two
/// classes sharing a name collide in the registry.
class EmergencyProfileViewController extends GetxController {
  /// When set (e.g. opened from a scanned QR / `emergency.beapp.in/<id>`
  /// deep link), the profile is fetched for this id instead of the logged-in
  /// user's. Null → show the current user's own emergency profile.
  EmergencyProfileViewController({this.profileId});

  final String? profileId;

  Rx<ApiResponse> profileResponse = ApiResponse.initial('Initial').obs;
  Rx<EmergencyProfileModel?> emergencyProfileData =
      Rxn<EmergencyProfileModel>();

  /// The id whose profile this screen shows — the deep-link id when present,
  /// otherwise the logged-in user's id.
  String get _effectiveId =>
      (profileId != null && profileId!.isNotEmpty) ? profileId! : userId;

  /// True when viewing your own profile (no explicit deep-link id) — used by
  /// the screen to decide whether to show edit affordances.
  bool get isOwnProfile => profileId == null || profileId!.isEmpty;

  @override
  void onInit() {
    super.onInit();
    if (_effectiveId.isNotEmpty) {
      getEmergencyProfile1();
    } else {
      profileResponse.value = ApiResponse.error('User ID is empty');
    }
  }

  Future<void> getEmergencyProfile1() async {
    try {
      profileResponse.value = ApiResponse.loading('Fetching data');
      final responseModel =
          await EmergencyServiceRepo().getEmergencyProfileById(_effectiveId);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data['data'];
        if (data != null) {
          emergencyProfileData.value = EmergencyProfileModel.fromJson(data);
          profileResponse.value = ApiResponse.complete(responseModel);
        } else {
          profileResponse.value = ApiResponse.complete(responseModel);
        }
      } else {
        profileResponse.value = ApiResponse.error('Error');
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      profileResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
