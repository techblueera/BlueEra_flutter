import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/animated_message_box.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GlobalMessageService extends GetxService {
  bool _isFromHomeScreen = false;
  final RxString _message = ''.obs;
  final RxInt currentGarageBottomIndex = 0.obs;

  bool get isFromHomeScreen => _isFromHomeScreen;
  String get message => _message.value;

  bool get isShowing => _message.isNotEmpty;

  void show(String text, bool isFromHomeScreen) {
    _isFromHomeScreen = isFromHomeScreen;
    _message.value = text;
  }

  void hide() => _message.value = '';
}

class GlobalMessage extends GetView<GlobalMessageService> {
  const GlobalMessage();

  @override
  Widget build(BuildContext context) {


    return Obx(() {
      double bottomNavBarHeight = SizeConfig.size30;

      if (controller.isFromHomeScreen) {
        const double kNavBarHeight = kBottomNavigationBarHeight;
        bottomNavBarHeight = kNavBarHeight + bottomNavBarHeight;
      }

      if (!controller.isShowing) return const SizedBox.shrink();

      return Positioned(
        left: 0,
        right: 0,
        bottom: bottomNavBarHeight, // ← float just above / overlap
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size30),
                child: AnimatedMessageBox(controller: controller),
          ),
        ),
      );
    });
  }
}
