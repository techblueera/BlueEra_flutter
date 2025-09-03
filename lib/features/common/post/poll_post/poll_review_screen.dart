

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/get_current_location.dart';
import 'package:BlueEra/features/common/post/controller/poll_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/progrss_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PollReviewScreen extends StatefulWidget {
  final PostVia? postVia;
  const PollReviewScreen({super.key, this.postVia});

  @override
  State<PollReviewScreen> createState() => _PollReviewScreenState();
}

class _PollReviewScreenState extends State<PollReviewScreen> {
  final pollController = Get.find<PollController>();
  final RxInt selectedIndex = (-1).obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        onBackTap: () => Get.back(),
        title: "Poll",
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
                      "Choose Your Correct Answer",
                         fontWeight: FontWeight.bold, fontSize: SizeConfig.size16),
                     SizedBox(height: SizeConfig.size16),
                    CustomText(
                      pollController.questionController.text.isNotEmpty
                          ? pollController.questionController.text
                          : "No question entered.",
                          fontSize: SizeConfig.size15, fontWeight: FontWeight.w600
                    ),
                     SizedBox(height: SizeConfig.size16),
                    Obx(() => Column(
                          children: pollController.options
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key;
                            final option = entry.value;
                            final label = String.fromCharCode(65 + index);

                            return Container(
                              margin:  EdgeInsets.only(bottom: SizeConfig.size10),
                              padding:
                                   EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: CustomText(
                                      "$label.  $option",
                                    ),
                                  ),
                                  Obx(
                                    () => Radio<int>(
                                      value: index,
                                      groupValue: selectedIndex.value,
                                      onChanged: (val) {
                                        selectedIndex.value = val!;
                                      },
                                      activeColor: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        )),
                     SizedBox(height: SizeConfig.size16),
                    CommonTextField(
                      hintText:
                          "E.g., This helps people understand the question",
                      title: "Add Comment or Description (Optional)",
                      maxLine: 3,
                      maxLength: 180,
                      inputLength: 180,
                      isCounterVisible: true,
                      textEditController: pollController.descriptionController,
                      isValidate: false,
                    ),
                     SizedBox(height: SizeConfig.size20),
                    Row(
                      children: [
                        Expanded(
                            child: PositiveCustomBtn(
                          onTap: () => Get.back(),
                          title: "Back",
                          textColor: AppColors.primaryColor,
                          bgColor: AppColors.white,
                        )),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                            child: PositiveCustomBtn(
                          onTap: () async {
                            try {
                              final position = await getCurrentLocation();
                              final Map<String, dynamic> params;
                              if (pollController.isPollPostEdit) {
                                pollController.isLoading.value = true;
                                params = {
                                  ApiKeys.type: AppConstants.POLL_POST,
                                  ApiKeys.sub_title: pollController
                                          .descriptionController.text
                                          .trim()
                                          .isNotEmpty
                                      ? pollController
                                          .descriptionController.text
                                          .trim()
                                      : "",
                                  if (position?.latitude
                                          .toString()
                                          .isNotEmpty ??
                                      false)
                                    ApiKeys.latitude:
                                        position?.latitude.toString(),
                                  if (position?.longitude
                                          .toString()
                                          .isNotEmpty ??
                                      false)
                                    ApiKeys.longitude:
                                        position?.longitude.toString(),
                                  // ApiKeys.reference_link: pollController
                                  //         .referenceLinkController
                                  //         .text
                                  //         .isNotEmpty
                                  //     ? pollController
                                  //         .referenceLinkController.text
                                  //     : "",
                                };
                              } else {

                                if(selectedIndex==-1){
                                  showCreateChannelDialog();
                                  return;
                                }

                                pollController.isLoading.value = true;
                                pollController.syncOptionsFromControllers();
                                final List<Map<String, dynamic>>
                                    formattedOptions = pollController.options.
                                         asMap().
                                         entries.
                                         map((opt) => {
                                           'text': opt.value,
                                           'isCorrect': (selectedIndex.value == opt.key) ? true : false})
                                           .toList();
                                params = {
                                  ApiKeys.type: AppConstants.POLL_POST,
                                  ApiKeys.postVia: widget.postVia?.name,
                                  ApiKeys.poll: {
                                    ApiKeys.question: pollController
                                            .questionController.text
                                            .trim()
                                            .isNotEmpty
                                        ? pollController.questionController.text
                                            .trim()
                                        : "No Question",
                                    ApiKeys.options: formattedOptions,
                                  },
                                  if (pollController
                                      .descriptionController.text.isNotEmpty)
                                    ApiKeys.sub_title: pollController
                                        .descriptionController.text
                                        .trim(),
                                  if (position?.latitude
                                          .toString()
                                          .isNotEmpty ??
                                      false)
                                    ApiKeys.latitude:
                                        position?.latitude.toString(),
                                  if (position?.longitude
                                          .toString()
                                          .isNotEmpty ??
                                      false)
                                    ApiKeys.longitude:
                                        position?.longitude.toString(),
                                  // if (pollController
                                  //     .referenceLinkController.text.isNotEmpty)
                                  //   ApiKeys.reference_link: pollController
                                  //       .referenceLinkController.text,
                                };
                              }
                              await pollController.createPollPost(params);

                              pollController.isLoading.value = false;
                            } on Exception {
                              // TODO
                              pollController.isLoading.value = false;
                            }
                          },
                          title: "Post Now",
                        )),
                      ],
                    )
                  ],
                ),
                if (pollController.isLoading.value) CircularIndicator(),
              ],
            ),
          ),
        );
      }),
    );
  }

  void showCreateChannelDialog()  {
    Get.dialog(
        Dialog(
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
                  'Please choose correct answer.',
                  fontSize: SizeConfig.large18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainTextColor,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: CustomText(
                      'Ok',
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.medium15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
         )
       );
      }

}
