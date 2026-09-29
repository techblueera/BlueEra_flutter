import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/post/controller/poll_controller.dart';
import 'package:BlueEra/features/common/post/widget/return_to_feed.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/progrss_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/routes/safe_back.dart';

/// Pushed on top of PollInputScreen and uses the controller its route owns.
class PollReviewScreen extends GetView<PollController> {
  const PollReviewScreen({super.key});

  Future<void> _postNow(BuildContext context) async {
    if (controller.needsCorrectAnswer) {
      _showChooseAnswerDialog(context);
      return;
    }
    if (await controller.submit()) returnToFeedAfterPosting();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        onBackTap: () => safeBack(),
        title: AppStrings.poll.tr,
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: SizeConfig.size10,
          ),
          child: Container(
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.chooseCorrectAnswer.tr,
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.size16,
                    ),
                    SizedBox(height: SizeConfig.size16),
                    CustomText(
                      controller.questionController.text.isNotEmpty
                          ? controller.questionController.text
                          : AppStrings.noQuestionEntered.tr,
                      fontSize: SizeConfig.size15,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: SizeConfig.size16),
                    Obx(() => RadioGroup<int>(
                          groupValue: controller.correctAnswerIndex.value,
                          onChanged: (val) {
                            if (val != null) {
                              controller.correctAnswerIndex.value = val;
                            }
                          },
                          child: Column(
                            children: controller.options
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final option = entry.value;
                              final label = String.fromCharCode(65 + index);

                              return Container(
                                margin:
                                    EdgeInsets.only(bottom: SizeConfig.size10),
                                padding: EdgeInsets.symmetric(
                                    horizontal: SizeConfig.size12),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: CustomText("$label.  $option"),
                                    ),
                                    Radio<int>(
                                      value: index,
                                      activeColor: AppColors.primaryColor,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        )),
                    SizedBox(height: SizeConfig.size16),
                    CommonTextField(
                      hintText: AppStrings.addCommentHint.tr,
                      title: AppStrings.addCommentOrDescription.tr,
                      maxLine: 3,
                      maxLength: 180,
                      inputLength: 180,
                      isCounterVisible: true,
                      textEditController: controller.descriptionController,
                      isValidate: false,
                    ),
                    SizedBox(height: SizeConfig.size20),
                    Row(
                      children: [
                        Expanded(
                          child: PositiveCustomBtn(
                            onTap: () => safeBack(),
                            title: AppStrings.back.tr,
                            textColor: AppColors.primaryColor,
                            bgColor: AppColors.white,
                          ),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: PositiveCustomBtn(
                            onTap: controller.isLoading.value
                                ? null
                                : () => _postNow(context),
                            title: AppStrings.postNow.tr,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (controller.isLoading.value) CircularIndicator(),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showChooseAnswerDialog(BuildContext context) {
    Get.dialog(Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              AppStrings.pleaseChooseCorrectAnswer.tr,
              fontSize: SizeConfig.large18,
              fontWeight: FontWeight.bold,
              color: AppColors.mainTextColor,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => safeBack(),
                child: CustomText(
                  AppStrings.ok.tr,
                  color: AppColors.primaryColor,
                  fontSize: SizeConfig.medium15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
