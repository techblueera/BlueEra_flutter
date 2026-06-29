import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/emergency_profile_cache.dart';
import 'package:BlueEra/features/personal/emergency/repo/emergency_service_repo.dart';
import 'package:BlueEra/features/personal/emergency/view/emergency_basic_info_screen.dart';
import 'package:get/get.dart';

class EmergencyProfileController extends GetxController {
  final EmergencyServiceRepo _repo = EmergencyServiceRepo();
  final isLoading = false.obs;
  final hasEmergencyData = false.obs;
  final fullName = "".obs;

  @override
  void onInit() {
    super.onInit();
    fetchEmergencyProfile();
  }

  /// Cache-first: serves the own emergency profile from the local cache and
  /// only hits the API when the cache is empty (i.e. once after login). The
  /// cache is invalidated on any successful emergency-data edit (in
  /// `EmergencyServiceRepo`) and wiped on logout, so it refreshes when needed.
  /// Pass [forceRefresh] = true to bypass the cache.
  Future<void> fetchEmergencyProfile({bool forceRefresh = false}) async {
    try {
      isLoading.value = true;

      if (!forceRefresh) {
        final cached = await EmergencyProfileCache().get(userId);
        if (cached != null) {
          _applyProfile(cached);
          return;
        }
      }

      final res = await _repo.getEmergencyProfile();
      if (res.isSuccess) {
        final data = res.data;
        if (data is Map) {
          await EmergencyProfileCache()
              .save(userId, Map<String, dynamic>.from(data));
        }
        _applyProfile(data);
      } else {
        hasEmergencyData.value = false;
      }
    } catch (e) {
      hasEmergencyData.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Applies a raw emergency-profile data map (from cache or API) to the
  /// observable UI state.
  void _applyProfile(dynamic data) {
    final hasBasicInfo = data is Map && data['basicInfo'] != null;
    hasEmergencyData.value = hasBasicInfo;
    if (hasBasicInfo) {
      fullName.value = data['basicInfo']['fullName'] ?? '';
    }
  }

  void navigateToCreateProfile() {
    Get.to(() => const EmergencyBasicInfoScreen())?.then((_) {
      // The edit may have changed the profile — bypass the cache so the QR
      // widget reflects the latest data (the save also cleared the cache).
      fetchEmergencyProfile(forceRefresh: true);
    });
  }
}
