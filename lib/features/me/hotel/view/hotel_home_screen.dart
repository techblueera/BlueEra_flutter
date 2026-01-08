import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_service_controller.dart';
import 'package:BlueEra/features/me/hotel/view/ai_hotel_profile_dialoge.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HotelHomeScreen extends StatelessWidget {
  HotelHomeScreen({super.key});

  final controller = Get.put(HotelServiceController());

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.whiteE91.withValues(alpha: 0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LocalAssets(
            imagePath: AppImageAssets.noMeContent,
          ),
          SizedBox(
            height: SizeConfig.size10,
          ),
          CustomText("You Have Not Any Active Profile"),
          InkWell(
            onTap: () {
              controller.clearAiGenerateFiled();

              Get.dialog(
                AIHotelProfileDialog(),
                barrierDismissible: true, // User can click outside to close
              );
            },
            child: CustomText(
              "Kindly Create!",
              color: AppColors.primaryColor,
            ),
          )
        ],
      ),
    );
  }
}
