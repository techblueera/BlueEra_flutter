// lib/controller/app_controller.dart
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:get/get.dart';

class AppMaintenanceController extends GetxController {

  var isLoading = true.obs;
  final isInMaintenance = RxnBool();

  var message = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkMaintenance();
  }

  Future<void> checkMaintenance() async {
    try {
      isLoading.value = true;

      final response = await AuthRepo().getAppMaintenanceRepo();
      final data = response.response?.data;

      if (data != null && data['isInMaintainance'] == true) {
        isInMaintenance.value = true;
        message.value = data['message'] ?? 'App under maintenance.';
      } else {
        isInMaintenance.value = false;
      }
    } catch (e) {
      logs("ERROR maintenance ${e}");
      message.value = 'Error checking maintenance: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
