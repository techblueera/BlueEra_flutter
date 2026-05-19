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

  /// Hits the maintenance endpoint and updates [isInMaintenance].
  ///
  /// [treatErrorsAsMaintenance] controls how transport/parse failures
  /// are handled:
  ///   • `false` (default, fail-open): only an explicit
  ///     `isInMaintainance: true` from the server flips the app into
  ///     maintenance. Network errors, timeouts, missing fields, or
  ///     null payloads are treated as healthy — the app boots normally.
  ///   • `true` (fail-closed): any error OR `isInMaintainance: true`
  ///     shows the maintenance screen. Use this when you'd rather
  ///     gate the app behind a known-good signal than risk booting
  ///     against a degraded backend.
  Future<void> checkMaintenance({
    bool treatErrorsAsMaintenance = false,
  }) async {
    // Debug builds always bypass the maintenance gate so developers can
    // boot into the app even when the maintenance endpoint is degraded or
    // intentionally returning `isInMaintainance: true` on a staging server.
    // Release builds fall through to the production check below — the
    // `kDebugMode` branch is a compile-time constant, so the dead arm is
    // tree-shaken out of release artifacts.
    // if (kDebugMode) {
    //   isInMaintenance.value = false;
    //   message.value = '';
    //   isLoading.value = false;
    //   return;
    // }

    try {
      isLoading.value = true;

      final response = await AuthRepo().getAppMaintenanceRepo();
      final data = response.response?.data;

      if (data is Map && data['isInMaintainance'] == true) {
        isInMaintenance.value = true;
        message.value = data['message'] is String
            ? data['message']
            : 'App under maintenance.';
      } else if (treatErrorsAsMaintenance &&
          !(data is Map && data['isInMaintainance'] == false)) {
        // Strict mode + server didn't explicitly clear us → maintenance.
        isInMaintenance.value = true;
        message.value = '';
      } else {
        isInMaintenance.value = false;
        message.value = '';
      }
    } catch (e) {
      logs("ERROR maintenance ${e}");
      // Fail-open by default — a degraded maintenance endpoint shouldn't
      // block the whole app. Caller can opt into fail-closed by passing
      // `treatErrorsAsMaintenance: true`. Leave `message` empty so the
      // screen renders its computed end-of-day default instead of
      // surfacing a raw error string to the user.
      isInMaintenance.value = treatErrorsAsMaintenance;
      message.value = '';
    } finally {
      isLoading.value = false;
    }
  }
}
