import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/language_localization_service/language_controller_new.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/business_profile_cache.dart';
import 'package:BlueEra/core/services/personal_profile_cache.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/location_update_service.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
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
        await _performLogout();
      },
      cancelCallback: () {
        Navigator.of(context).pop();
      },
      confirmText: AppStrings.yes,
      cancelText: AppStrings.no,
    );
  }

  /// Two-phase logout: phase 1 wipes data while the source screen is still
  /// mounted under the loader (no Rx writes → no Obx rebuilds → no orphan
  /// controller re-creations via getOrPut). Phase 2 runs after navigation
  /// when reactive writes are safe.
  static Future<void> _performLogout() async {
    if (Get.isDialogOpen ?? false) Get.back();
    AppLoader.showLogout();

    // Phase 1 — non-reactive bulk wipe.
    try {
      await SharedPreferenceUtils.clearPreferenceDataOnly();
      LiveLocationService().stop();
      await clearAllLocalData();
    } catch (_) {}

    Get.offAllNamed(RouteHelper.getMobileNumberLoginRoute());
    await WidgetsBinding.instance.endOfFrame;

    // Phase 2 — reactive cleanup.
    try {
      _resetSessionControllers();
      await SharedPreferenceUtils.clearPreferenceReactive();
      if (Get.isRegistered<LanguageControllerNew>()) {
        await Get.find<LanguageControllerNew>().reset();
      }
    } catch (_) {}
  }

  /// Force-deletes the controllers that survive `Get.offAllNamed` and
  /// would otherwise leak the previous session's `.obs` data:
  /// - `ViewPersonalDetailsController`: registered `permanent:true`.
  /// - `ViewBusinessDetailsController`: not flagged permanent, but several
  ///   `Get.put` calls happen from non-route contexts (AuthController,
  ///   drawer), so smart-management never auto-disposes them.
  /// - `ChatViewController`: owns chat sockets/listeners.
  static void _resetSessionControllers() {
    deleteIfRegistered<ChatViewController>();
    deleteIfRegistered<ViewPersonalDetailsController>();
    deleteIfRegistered<ViewBusinessDetailsController>();
  }

  /// Wipes Hive (all boxes), per-feature caches, and the app docs dir.
  /// Public so the API 401 handler can reuse it. Non-reactive.
  static Future<void> clearAllLocalData() async {
    try {
      await BusinessProfileCache.clear();
      await PersonalProfileCache.clear();
    } catch (_) {}
    try {
      await Hive.deleteFromDisk();
      final dir = await getApplicationDocumentsDirectory();
      if (dir.existsSync()) await dir.delete(recursive: true);
    } catch (_) {}
  }
}
