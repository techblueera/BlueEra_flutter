import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
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

  Future<void> fetchEmergencyProfile() async {
    try {
      isLoading.value = true;
      final res = await _repo.getEmergencyProfile();
      if (res.isSuccess) {
        final data = res.data;
        hasEmergencyData.value = data != null && data['basicInfo'] != null;
        if (data != null && data['basicInfo'] != null) {
          fullName.value = data['basicInfo']['fullName'];
        }
      } else {
        hasEmergencyData.value = false;
      }
    } catch (e) {
      hasEmergencyData.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  void navigateToCreateProfile() {
    Get.to(() => const EmergencyBasicInfoScreen())?.then((_) {
      fetchEmergencyProfile();
    });
  }
}
