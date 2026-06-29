import 'package:BlueEra/core/services/emergency_profile_cache.dart';
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

  /// Loads the emergency profile.
  ///
  /// For the user's OWN profile this is cache-first: it serves from the local
  /// cache when present and only hits the API when the cache is empty (once
  /// after login), writing through to the cache on success. Deep-linked /
  /// scanned profiles of OTHER users are always fetched live (never cached).
  /// Pass [forceRefresh] = true (e.g. after editing) to bypass the cache.
  Future<void> getEmergencyProfile1({bool forceRefresh = false}) async {
    try {
      profileResponse.value = ApiResponse.loading('Fetching data');

      // Own profile → cache-first.
      if (isOwnProfile && !forceRefresh) {
        final cached = await EmergencyProfileCache().get(_effectiveId);
        if (cached != null) {
          emergencyProfileData.value = EmergencyProfileModel.fromJson(cached);
          profileResponse.value = ApiResponse.complete();
          return;
        }
      }

      final responseModel =
          await EmergencyServiceRepo().getEmergencyProfileById(_effectiveId);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data['data'];
        if (data != null) {
          emergencyProfileData.value = EmergencyProfileModel.fromJson(data);
          // Cache only the user's OWN profile, never other users' profiles.
          if (isOwnProfile && data is Map) {
            await EmergencyProfileCache()
                .save(_effectiveId, Map<String, dynamic>.from(data));
          }
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
