// lib/controller/app_controller.dart
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:flutter/foundation.dart';
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
    // Debug builds always bypass the maintenance gate so developers can
    // boot into the app even when the maintenance endpoint is degraded or
    // intentionally returning `isInMaintainance: true` on a staging server.
    // Release builds fall through to the production check below — the
    // `kDebugMode` branch is a compile-time constant, so the dead arm is
    // tree-shaken out of release artifacts.
    if (kDebugMode) {
      isInMaintenance.value = false;
      message.value = '';
      isLoading.value = false;
      return;
    }

    try {
      isLoading.value = true;

      final response = await AuthRepo().getAppMaintenanceRepo();
      final data = response.response?.data;

      // Only treat the app as healthy when the server explicitly says
      // isInMaintainance == false. Anything else (true, missing field,
      // null payload) is treated as maintenance so users never land on
      // a broken app while the backend is degraded.
      if (data != null && data['isInMaintainance'] == false) {
        isInMaintenance.value = false;
        message.value = '';
      } else {
        isInMaintenance.value = true;
        message.value = (data is Map && data['message'] is String)
            ? data['message']
            : 'App under maintenance.';
      }
    } catch (e) {
      logs("ERROR maintenance ${e}");
      // On any failure (network down, timeout, bad payload, server 5xx)
      // fall back to the maintenance screen rather than letting the app
      // boot into an unknown state. Leave `message` empty so the screen
      // renders its computed end-of-day default instead of surfacing a
      // raw error string to the user.
      isInMaintenance.value = true;
      message.value = '';
    } finally {
      isLoading.value = false;
    }
  }
}
