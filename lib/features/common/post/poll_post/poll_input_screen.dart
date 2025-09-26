import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
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
      widget.post?.poll?.options?.forEach((data) {
        pollController.optionControllers
            .add(TextEditingController(text: data.text));
      });

      // if (widget.post?.referenceLink?.isNotEmpty ?? false) {
      //   pollController.isAddLink.value = true;
      //   pollController.referenceLinkController.text =
      //       widget.post?.referenceLink ?? "";
      // }
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
    Get.delete<PollController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        onBackTap: () => Get.back(),
        title: "Poll",
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
                    title: "Your Question",
                    hintText: "E.g., How do you commute to work?",
                    textEditController: pollController.questionController,
                    inputLength: 100,
                    maxLength: 100,
                    validationMessage: AppStrings.required,
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
                                    title: "Option ${index + 1}",
                                    hintText: index == 0
                                        ? "E.g., Public transportation"
                                        : index == 1
                                            ? "E.g., Drive myself"
                                            : "E.g., Your option here",
                                    textEditController:
                                        pollController.optionControllers[index],
                                    inputLength: 36,
                                    maxLength: 36,
                                    validationMessage: AppStrings.required,
                                    isCounterVisible: true,
                                    readOnly: (pollController.isPollPostEdit),
                                  ),
                                ),
                                if ((pollController.optionControllers.length >
                                        2) &&
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
                              LocalAssets(imagePath: AppIconAssets.addBlueIcon),
                              SizedBox(width: SizeConfig.size10),
                              CustomText(
                                "Add More Option",
                                fontSize: SizeConfig.large,
                                color: AppColors.primaryColor,
                              )
                            ],
                          ),
                        );
                      return SizedBox();
                    }),
                  // Obx(() {
                  //   if (!pollController.isAddLink.value) {
                  //     return Padding(
                  //       padding: EdgeInsets.only(top: SizeConfig.size15),
                  //       child: InkWell(
                  //         onTap: () {
                  //           pollController.isAddLink.value = true;
                  //         },
                  //         child: Row(
                  //           children: [
                  //             LocalAssets(imagePath: AppIconAssets.addBlueIcon),
                  //             SizedBox(width: SizeConfig.size10),
                  //             CustomText(
                  //               'Add Link (Reference / Website)',
                  //               fontSize: SizeConfig.large,
                  //               color: AppColors.primaryColor,
                  //             )
                  //           ],
                  //         ),
                  //       ),
                  //     );
                  //   }
                  //   if (pollController.isAddLink.value) {
                  //     return Padding(
                  //       padding: EdgeInsets.only(top: SizeConfig.size15),
                  //       child: Column(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         crossAxisAlignment: CrossAxisAlignment.center,
                  //         children: [
                  //           Row(
                  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //             children: [
                  //               CustomText("Reference link"),
                  //               InkWell(
                  //                 onTap: () {
                  //                   pollController.referenceLinkController
                  //                       .clear();
                  //                   pollController.isAddLink.value = false;
                  //                 },
                  //                 child: CustomText(
                  //                   "Remove",
                  //                   color: AppColors.red,
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //           SizedBox(
                  //             height: SizeConfig.size10,
                  //           ),
                  //           HttpsTextField(
                  //               controller:
                  //                   pollController.referenceLinkController,
                  //               hintText: "Add website link"),
                  //         ],
                  //       ),
                  //     );
                  //   }
                  //   return SizedBox();
                  // }),
                  SizedBox(height: SizeConfig.size25),
                  PositiveCustomBtn(
                      onTap: () {
                        pollController.syncOptionsFromControllers();
                        if (pollController.questionController.text
                            .trim()
                            .isEmpty) {
                          commonSnackBar(
                            message: "Please fill question",
                          );
                          return;
                        } else if (pollController.options.length >= 2) {
                          Get.toNamed(RouteHelper.getPollReviewScreenRoute(), arguments: {ApiKeys.argPostVia : widget.postVia});
                        } else {
                          commonSnackBar(
                            message: "Please fill at least 2 options",
                          );
                          return;
                        }
                      },
                      title: "Continue"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
