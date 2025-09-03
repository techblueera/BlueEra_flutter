import 'package:BlueEra/widgets/global_message_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///SHOW SNACK BAR MESSAGES
final msgController = Get.find<GlobalMessageService>();

commonSnackBar({required String message, Color? snackBackgroundColor, bool isFromHomeScreen = false}) async {
  msgController.hide();
  msgController.show(message, isFromHomeScreen);
}
