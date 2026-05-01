import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/language_localization_service/language_controller_new.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/business_profile_cache.dart';
import 'package:BlueEra/core/services/personal_profile_cache.dart';
import 'package:BlueEra/features/app_maintannace/app_maintenance_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/chat/auth/service/location_update_service.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/languge_list_controller.dart';
import 'package:BlueEra/widgets/global_message_service.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class LogoutHelper {
  LogoutHelper._();

  /// Shows the logout confirmation dialog. On confirm, clears all local
  /// data and navigates to the login screen.
  static Future<void> showLogoutDialog(BuildContext context) async {
    await showCommonDialog(
      context: context,
      text: AppStrings.logoutConfirmationMessage.tr,
      confirmCallback: () async {
        await _performLogout(context);
      },
      cancelCallback: () {
        Navigator.of(context).pop();
      },
      confirmText: AppStrings.yes,
      cancelText: AppStrings.no,
    );
  }

  static Future<void> _performLogout(BuildContext context) async {
    // Close the confirmation dialog up front. The async work below
    // (Hive.deleteFromDisk + recursive directory delete) can take long
    // enough that the screen that owns `context` is torn down — once it
    // deactivates, Navigator.of(context) throws "deactivated widget's
    // ancestor is unsafe". Routing via Get avoids needing a live context.
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    AppLoader.showLogout();
    try {
      // 1. Stop services and clear on-disk persistence while controllers
      // are still alive (clearAllLocalData reads LanguageControllerNew).
      await SharedPreferenceUtils.clearPreference();
      LiveLocationService().stop();
      await clearAllLocalData();

      // 2. Wipe every registered GetX controller in one shot — this is
      // the only place per-user state lives in memory. Doing it
      // surgically (deleting individual controllers) is fragile: any
      // controller a future feature adds silently leaks state across
      // logins. force:true takes care of permanents too.
      Get.deleteAll(force: true);

      // 3. Re-register the bootstrap controllers main() puts up at app
      // start. The login screen and overlay services depend on them
      // being present; everything else lazily re-registers via
      // getOrPut/Get.put when its screen mounts.
      Get.put(AuthController());
      Get.put(NavigationHelperController());
      Get.put(GlobalMessageService());
      Get.put(AppMaintenanceController());
      Get.put(CallController(), permanent: true);
      Get.put(LanguageListController());
    } catch (_) {}
    AppLoader.hide();
    Get.offAllNamed(RouteHelper.getMobileNumberLoginRoute());
  }

  static Future<void> clearAllLocalData() async {
    try {
      // Explicit per-cache clears so the debug log shows what wiped,
      // before the full Hive disk-delete sweeps the rest.
      await BusinessProfileCache.clear();
      await PersonalProfileCache.clear();
    } catch (_) {}
    try {
      await Hive.deleteFromDisk();
      final dir = await getApplicationDocumentsDirectory();
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
    try {
      if (Get.isRegistered<LanguageControllerNew>()) {
        await Get.find<LanguageControllerNew>().reset();
      }
    } catch (_) {}
  }
}
