import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/post/controller/poll_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/routes/safe_back.dart';

/// Opened through [RouteHelper.getPollInputScreenRoute], whose PollBinding
/// provides the controller.
class PollInputScreen extends GetView<PollController> {
  const PollInputScreen({super.key});

  void _continue() {
    final error = controller.validateQuestion();
    if (error != null) {
      commonSnackBar(message: error.tr);
      return;
    }
    Get.toNamed(RouteHelper.getPollReviewScreenRoute());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        onBackTap: () => safeBack(),
        title: AppStrings.poll.tr,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonTextField(
                    title: AppStrings.yourQuestion.tr,
                    hintText: AppStrings.exampleQuestion.tr,
                    textEditController: controller.questionController,
                    inputLength: 100,
                    maxLength: 100,
                    validationMessage: AppStrings.required.tr,
                    validationType: null,
                    isCounterVisible: true,
                    readOnly: controller.isEdit,
                  ),
                  const SizedBox(height: 16),

                  Obx(() => Column(
                    children: List.generate(
                      controller.optionControllers.length,
                          (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: CommonTextField(
                                title:
                                "${AppStrings.option.tr} ${index + 1}",
                                hintText: index == 0
                                    ? AppStrings.exampleOption1.tr
                                    : index == 1
                                    ? AppStrings.exampleOption2.tr
                                    : AppStrings.exampleOptionDefault.tr,
                                textEditController:
                                    controller.optionControllers[index],
                                inputLength: 36,
                                maxLength: 36,
                                validationMessage: AppStrings.required.tr,
                                isCounterVisible: true,
                                readOnly: controller.isEdit,
                              ),
                            ),
                            if (controller.canRemoveOption)
                              IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: () =>
                                    controller.removeOption(index),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )),

                  Obx(() {
                    if (!controller.canAddOption) return const SizedBox();
                    return InkWell(
                      onTap: controller.addOption,
                      child: Row(
                        children: [
                          LocalAssets(imagePath: AppIconAssets.addBlueIcon),
                          SizedBox(width: SizeConfig.size10),
                          CustomText(
                            AppStrings.addMoreOption.tr,
                            fontSize: SizeConfig.large,
                            color: AppColors.primaryColor,
                          )
                        ],
                      ),
                    );
                  }),

                  SizedBox(height: SizeConfig.size25),

                  PositiveCustomBtn(
                      onTap: _continue, title: AppStrings.continueTxt.tr),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
