import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppLoader {
  AppLoader._();

  static void show() {
    Get.dialog(
      Center(
        child: Container(
          width: SizeConfig.size90,
          height: SizeConfig.size90,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white,
          ),
          child: staggeredDotsWaveLoading(
            color: AppColors.primaryColor,
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void hide() {
    if (Get.isDialogOpen ?? false) Get.back();
  }
}