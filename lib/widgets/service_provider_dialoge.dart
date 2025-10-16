import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showEnableServiceDialog() async {
  final viewProfileController = Get.put(ViewPersonalDetailsController());

  if (serviceProviderStatusGlobal.toString().toUpperCase() ==
          AppConstants.CLOSED.toUpperCase() &&
      (userProfessionGlobal.toUpperCase() == "SELF_EMPLOYED")) {
    Get.defaultDialog(
      title: "",titleStyle: TextStyle(fontSize: 0),
      radius: 16,titlePadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: SizeConfig.size10),

          LocalAssets(imagePath: AppIconAssets.location_track),
          SizedBox(height: SizeConfig.size20),
          CustomText(
            "Update Location",
            fontWeight: FontWeight.bold,
            fontSize: SizeConfig.size20,
          ),
          SizedBox(height: SizeConfig.size10),
          CustomText(
            "To get batter order , kindly live your Location",
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
            child: Row(
              children: [
                Expanded(
                  child: PositiveCustomBtn(
                    onTap: () {
                      Get.back();
                    },
                    title: "Cancel",
                    bgColor: AppColors.white,
                    borderColor: AppColors.primaryColor,
                    textColor: AppColors.primaryColor,
                  ),
                ),
                SizedBox(
                  width: SizeConfig.size10,
                ),
                Expanded(
                    child: PositiveCustomBtn(onTap: () {
                      viewProfileController.toggleShopOnlyStatus(isActive: true);
                    }, title: "Active")),
              ],
            ),
          )
        ],
      ),
    );
  }
  else if(serviceProviderStatusGlobal.toString().toUpperCase() ==
      AppConstants.OPEN.toUpperCase()&&(userProfessionGlobal.toUpperCase() == "SELF_EMPLOYED")){
    await viewProfileController.callLocationAPI();

  }
}
