import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/poll_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PollInputScreen extends StatefulWidget {
  final Post? post;
  final bool isEdit;
  final PostVia? postVia;

  PollInputScreen({super.key, this.post, required this.isEdit, this.postVia});

  @override
  State<PollInputScreen> createState() => _PollInputScreenState();
}

class _PollInputScreenState extends State<PollInputScreen> {
  final pollController = Get.put(PollController());

  @override
  void initState() {
    // TODO: implement initState
    pollController.isPollPostEdit = widget.isEdit;

    if (widget.isEdit) {
      pollController.postId = widget.post?.id ?? "";

      pollController.descriptionController.text = widget.post?.subTitle ?? "";
      pollController.questionController.text =
          widget.post?.poll?.question ?? "";

      ///ADD OPTION IN POLL
      widget.post?.poll?.options.forEach((data) {
        pollController.optionControllers
            .add(TextEditingController(text: data.text));
      });
    } else {
      pollController.addOption();
      pollController.addOption();
    }
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    deleteIfRegistered<PollController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        onBackTap: () => Get.back(),
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
                    textEditController: pollController.questionController,
                    inputLength: 100,
                    maxLength: 100,
                    validationMessage: AppStrings.required.tr,
                    validationType: null,
                    isCounterVisible: true,
                    readOnly: (pollController.isPollPostEdit),
                  ),
                  const SizedBox(height: 16),

                  Obx(() => Column(
                    children: List.generate(
                      pollController.optionControllers.length,
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
                                textEditController: pollController
                                    .optionControllers[index],
                                inputLength: 36,
                                maxLength: 36,
                                validationMessage: AppStrings.required.tr,
                                isCounterVisible: true,
                                readOnly: (pollController.isPollPostEdit),
                              ),
                            ),
                            if ((pollController.optionControllers.length > 2) &&
                                (!pollController.isPollPostEdit))
                              IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: () =>
                                    pollController.removeOption(index),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )),

                  if ((!pollController.isPollPostEdit))
                    Obx(() {
                      if (pollController.optionControllers.length < 4)
                        return InkWell(
                          onTap: pollController.optionControllers.length < 4
                              ? pollController.addOption
                              : null,
                          child: Row(
                            children: [
                              LocalAssets(
                                  imagePath: AppIconAssets.addBlueIcon),
                              SizedBox(width: SizeConfig.size10),
                              CustomText(
                                AppStrings.addMoreOption.tr,
                                fontSize: SizeConfig.large,
                                color: AppColors.primaryColor,
                              )
                            ],
                          ),
                        );
                      return SizedBox();
                    }),

                  SizedBox(height: SizeConfig.size25),

                  PositiveCustomBtn(
                      onTap: () {
                        pollController.syncOptionsFromControllers();

                        if (pollController.questionController.text
                            .trim()
                            .isEmpty) {
                          commonSnackBar(
                            message: AppStrings.fillQuestion.tr,
                          );
                          return;
                        } else if (pollController.options.length >= 2) {
                          Get.toNamed(
                              RouteHelper.getPollReviewScreenRoute(),
                              arguments: {
                                ApiKeys.argPostVia: widget.postVia
                              });
                        } else {
                          commonSnackBar(
                            message: AppStrings.fillTwoOptions.tr,
                          );
                          return;
                        }
                      },
                      title: AppStrings.continueTxt.tr),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
