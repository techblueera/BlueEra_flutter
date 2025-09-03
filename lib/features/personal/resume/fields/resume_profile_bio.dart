import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/fields/edit_personal_details_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_edit_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResumeProfileBio extends StatelessWidget {
  const ResumeProfileBio({super.key});

  @override
  Widget build(BuildContext context) {
    // final controller = Get.put(ProfileBioController());

    final controller = Get.find<ProfilePicController>();

    // Fetch bio when widget loads
    // controller.fetchBio();

    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      return CommonCardWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    controller.getResumeData.value.name ?? "(No Name)",
                    color: AppColors.black28,
                    fontSize: SizeConfig.large18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                CommonEditWidget(
                  imgColor: AppColors.grey72,
                  voidCallback: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditPersonalDetailsScreen()),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            Row(
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.email,
                  height: SizeConfig.size20,
                  width: SizeConfig.size20,
                  imgColor: AppColors.black28,
                ),
                SizedBox(width: 8), // Adjust spacing as needed
                Expanded(
                  child: CustomText(
                    controller.getResumeData.value.email ?? "(No Email)",
                    color: AppColors.black28,
                    fontSize: SizeConfig.large,
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            Row(
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.phone_outline,
                  height: SizeConfig.size20,
                  width: SizeConfig.size20,
                  imgColor: AppColors.black28,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomText(
                    controller.getResumeData.value.phone ?? "N/A",
                    color: AppColors.black28,
                    fontSize: SizeConfig.large,
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            Row(
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.location_outline,
                  height: SizeConfig.size20,
                  width: SizeConfig.size20,
                  imgColor: AppColors.black28,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomText(
                    controller.getResumeData.value.location ?? "(No location)",
                    color: AppColors.black28,
                    fontSize: SizeConfig.large,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
