import 'package:BlueEra/widgets/global_message_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lazy lookup so this file can be imported by code that runs in Flutter
/// engines where GlobalMessageService isn't registered (e.g. Android's
/// CallActivity engine, which only registers CallController). The previous
/// top-level `final msgController = Get.find<GlobalMessageService>()` threw
/// at first use in those engines, crashing initiateCall's error path.
GlobalMessageService? get _msgController =>
    Get.isRegistered<GlobalMessageService>()
        ? Get.find<GlobalMessageService>()
        : null;

///SHOW SNACK BAR MESSAGES
commonSnackBar({required String message, Color? snackBackgroundColor, bool isFromHomeScreen = false}) async {
  final controller = _msgController;
  if (controller == null) {
    // No global message UI in this engine — surface to logs so the failure
    // path is still observable instead of silently swallowed.
    debugPrint('[commonSnackBar] GlobalMessageService not registered — message dropped: $message');
    return;
  }
  controller.hide();
  controller.show(message, isFromHomeScreen);
}
