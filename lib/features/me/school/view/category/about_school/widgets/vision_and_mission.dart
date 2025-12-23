import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../widgets/custom_text_cm.dart';
class VisionAndMission extends StatefulWidget {
  const VisionAndMission({super.key});

  @override
  State<VisionAndMission> createState() => _VisionAndMissionState();
}
class _VisionAndMissionState extends State<VisionAndMission> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Vision & Mission",
        isShadowShow: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// Course Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.whiteE5),

              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomText(
                        "Our Vision & Mission",
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size10),
                  /// Apply Button
                  CommonTextField(
                    maxLine: 4,
                    hintText: "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
                  ),
                  SizedBox(height: SizeConfig.size10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: (){}, // disabled like screenshot
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: CustomText(
                        "Continue",
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

}
