import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/language_localization_service/language_controller_new.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/location_update_service.dart';
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
    AppLoader.showLogout();
    try {
      deleteIfRegistered<ChatViewController>();
      await SharedPreferenceUtils.clearPreference();
      LiveLocationService().stop();
      await clearAllLocalData();
    } catch (_) {}
    AppLoader.hide();
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteHelper.getMobileNumberLoginRoute(),
      (Route<dynamic> route) => false,
    );
  }

  static Future<void> clearAllLocalData() async {
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
