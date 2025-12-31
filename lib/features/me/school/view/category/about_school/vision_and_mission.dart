import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/school_about_us_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
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
  final schoolAboutUsController = Get.find<SchoolAboutUsController>();
  final visionMissionEditController = TextEditingController();

  // 1. Add a variable to store the original value
  String initialText = "";

  @override
  void initState() {
    super.initState();
    // 1. Call the API (it will handle its own "already loaded" check)
    schoolAboutUsController.getSchoolAboutUsController();
    // 2. Setup a listener: When aboutUsData changes, update the text field
    // We use 'once' so it only auto-fills the FIRST time the data arrives
    once(schoolAboutUsController.aboutUsData!, (AboutUsData? data) {
      if (data != null && data.visionAndMission != null) {
        String value = data.visionAndMission!;

        // Update the UI elements
        visionMissionEditController.text = value;
        initialText = value;
        schoolAboutUsController.visionMissionText.value = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Vision & Mission",
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        isShadowShow: false,
      ),
      body: Obx(() {
        final status =
            schoolAboutUsController.getAboutUsSchoolResponse.value.status;

        if (status == Status.COMPLETE) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
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
                        textEditController: visionMissionEditController,
                        title: "Our Vision & Mission",
                        hintText: "Enter your vision and mission...",
                        maxLine: 5,
                        maxLength: 1000,
                        isValidate: false,
                        keyBoardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        onChange: (value) {
                          String newVal =
                              value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                          schoolAboutUsController.visionMissionText.value =
                              newVal;
                          // setState is called here so the Obx/build detects the change
                          // between current text and initialText
                        },
                      ),
                      SizedBox(height: SizeConfig.size10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Obx(() => CustomText(
                              "${schoolAboutUsController.visionMissionText.value.length}/1000",
                              color: Colors.grey,
                              fontSize: 12,
                            )),
                      ),
                      SizedBox(height: SizeConfig.size10),

                      // 3. Updated Button Logic
// The Button Logic
                      Obx(() {
                        final currentText = schoolAboutUsController
                            .visionMissionText.value
                            .trim();
                        final original = initialText.trim();

                        // Condition: Not empty AND different from what we started with
                        bool isChanged = currentText != original;
                        bool isNotEmpty = currentText.isNotEmpty;
                        bool isEnabled = isNotEmpty && isChanged;

                        return CustomBtn(
                          onTap: isEnabled
                              ? () async {
                                  ///UPDATE THE VISION AND MISSION....
                                  await schoolAboutUsController
                                      .updateVisionMissionController(
                                          visionMissionText: currentText);
                                  // 2. IMPORTANT: After the controller refreshes the data,
                                  // sync your local initialText so the button disables again.
                                  setState(() {
                                    visionMissionEditController.text = currentText;
                                  });
                                }
                              : null,
                          title: AppStrings.submit,
                          isValidate: isEnabled,
                        );
                      }),
                      SizedBox(height: SizeConfig.size10),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        if (status == Status.ERROR) {
          return Center(child: CustomText("Error loading data"));
        }
        return Center(child: CustomText(AppStrings.somethingWentWrong));
      }),
    );
  }
}
