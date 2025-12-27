import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/about_us_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../widgets/custom_text_cm.dart';

class VisionAndMission extends StatefulWidget {
  const VisionAndMission({super.key});

  @override
  State<VisionAndMission> createState() => _VisionAndMissionState();
}

class _VisionAndMissionState extends State<VisionAndMission> {
  final aboutUsController = Get.find<AboutUsController>();

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

                  CommonTextField(
                    title: "Our Vision & Mission",
                    hintText:
                    "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
                    maxLine: 5,
                    maxLength: 1000,
                    isValidate: false,
                    keyBoardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    onChange: (value) {
                      String newVal =
                      value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                      aboutUsController.historyText.value = newVal;
                    },
                  ),
                  SizedBox(height: SizeConfig.size10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Obx(() => CustomText(
                      "${aboutUsController.historyText.value.length}/1000",
                      color: Colors.grey,
                      fontSize: 12,
                    )),
                  ),
                  SizedBox(height: SizeConfig.size10),
                  PositiveCustomBtn(onTap: () {}, title: AppStrings.submit),
                  SizedBox(height: SizeConfig.size10),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
