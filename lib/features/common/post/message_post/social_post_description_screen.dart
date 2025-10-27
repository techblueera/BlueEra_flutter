import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/reel/controller/reel_upload_details_controller.dart';
import 'package:BlueEra/features/common/reel/models/video_category_response.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialPostDescriptionScreen extends StatelessWidget {
  SocialPostDescriptionScreen({super.key});

  final messageController = Get.find<MessagePostController>();
  final reelUploadDetailsController = Get.find<ReelUploadDetailsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        title: "Ai Generative Description",
      ),
      body: SafeArea(
        child: Obx(() {
          return Padding(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size20, vertical: SizeConfig.size20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: SizeConfig.size10,
                  ),

                  /// Language Dropdown
                  CustomText("Language"),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  CommonDropdownDialog<String>(
                    items: messageController.languages,
                    selectedValue:
                        messageController.selectedLanguage.value.isEmpty
                            ? null
                            : messageController.selectedLanguage.value,
                    title: "Select Language",
                    hintText: "Eg. Gujarati, Hindi...",
                    displayValue: (value) => value,
                    onChanged: (value) {
                      messageController.selectedLanguage.value = value!;
                      messageController.onSelectionChanged();
                    },
                  ),
                  SizedBox(
                    height: SizeConfig.size15,
                  ),

                  /// Emotion Dropdown
                  CustomText("Emotion"),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),

                  CommonDropdownDialog<String>(
                    items: messageController.emotions,
                    selectedValue:
                        messageController.selectedEmotion.value.isEmpty
                            ? null
                            : messageController.selectedEmotion.value,
                    title: "Select Emotion",
                    hintText: "Eg. Motivation, Anger...",
                    displayValue: (value) => value,
                    onChanged: (value) {
                      messageController.selectedEmotion.value = value!;
                      messageController.onSelectionChanged();
                    },
                  ),
                  SizedBox(
                    height: SizeConfig.size15,
                  ),

                  /// Nature of Post Dropdown (Your Existing Data)
                  CommonTextField(
                    title: "Topic describing what the images are about.",
                    hintText: "Eg. Team celebrating project success",
                    maxLength: 50,
                    isValidate: false,
                    textEditController:
                        messageController.imageTopicsTextEditControllar.value,
                    onChange: (text) {
                      messageController.topicDescriptionText.value = text;
                    },
                  ),
                  SizedBox(
                    height: SizeConfig.size30,
                  ),

                  /// Button

                  Obx(
                    () => CustomBtn(
                      title: "Generate Post Description",
                      isValidate: messageController.isFormValid,
                      onTap: messageController.isFormValid
                          ? () async {
                              await messageController
                                  .generateSocialMediaContent();
                            }
                          : null,
                    ),
                  ),

                  Obx(() {
                    if (messageController.suggestions.isEmpty)
                      return SizedBox();
                    final tempSelected =
                        messageController.selectedSuggestion.value.obs;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),
                        CustomText("Suggestions:",
                            fontSize: 16, fontWeight: FontWeight.bold),
                        SizedBox(height: 10),
                        Column(
                          children: messageController.suggestions.map((sugg) {
                            final isSelected = tempSelected.value == sugg;
                            return GestureDetector(
                              onTap: () => messageController
                                  .selectedSuggestion.value = sugg,
                              child: Card(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : Colors.white,
                                elevation: isSelected ? 3 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primaryColor
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: CustomText(
                                          sugg,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                  child: PositiveCustomBtn(
                                onTap: () => Get.back(),
                                title: "Cancel",
                                borderColor: AppColors.primaryColor,
                                bgColor: AppColors.white,
                                textColor: AppColors.primaryColor,
                              )),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomBtn(
                                  title: "Save",
                                  isValidate: tempSelected.value.isNotEmpty,
                                  // Enable/Disable button
                                  onTap: tempSelected.value.isNotEmpty
                                      ? () {
                                          // Save Selected Suggestion
                                          messageController.selectedSuggestion
                                              .value = tempSelected.value;

                                          // Set text to TextField
                                          messageController.descriptionMessage
                                              .value.text = tempSelected.value;
                                          messageController.descriptionMessage
                                                  .value.selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                                offset:
                                                    tempSelected.value.length),
                                          );

                                          messageController.postText.value =
                                              tempSelected.value;

                                          // Set Nature Of Post into text box (if needed)
                                          messageController
                                              .natureOfPostController
                                              .value
                                              .text = messageController
                                                  .selectedNatureOfPost
                                                  .value
                                                  ?.name ??
                                              "";

                                          Get.back();
                                        }
                                      : null, // Disabled if no selection
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    );
                  }),
                  SizedBox(
                    height: SizeConfig.size50,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
