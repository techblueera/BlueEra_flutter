import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Single confirmation flow used on onboarding screens that a guest user
/// can reach (Complete Guest Profile / Choose / Create account type).
///
/// Always prompts "Are you sure you want to exit the app?".
///   • Yes  → log out the user, reset all locally-stored data, route to
///            the fresh login screen so the next session starts clean.
///   • No   → close the dialog and pop the current screen so the user
///            never gets stuck on the same page (which previously
///            produced a black screen for guests).
class GuestExitHandler {
  static void handleBack(BuildContext context, {VoidCallback? onPlainPop}) {
    commonConformationDialog(
      context: context,
      text: AppStrings.areYouSureYouWantToExitTheApp.tr,
      confirmCallback: () async {
        Navigator.of(context, rootNavigator: true).pop();
        await _logoutAndGoToLogin();
      },
      cancelCallback: () {
        Navigator.of(context, rootNavigator: true).pop();
        if (onPlainPop != null) {
          onPlainPop();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  static Future<void> _logoutAndGoToLogin() async {
    try {
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().clearAllData();
      }
    } catch (_) {}

    await SharedPreferenceUtils.clearPreference();

    Get.offAllNamed(RouteHelper.getMobileNumberLoginRoute());
  }
}
