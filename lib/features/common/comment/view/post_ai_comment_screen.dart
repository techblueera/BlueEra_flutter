import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/comment/controller/comment_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostAiCommentScreen extends StatelessWidget {
  PostAiCommentScreen({super.key, required this.dataId, required this.commentType});

  final String dataId;
  final String commentType;
  final commentController = Get.find<CommentController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        title:AppStrings.aiGenerativeComment,onBackTap: (){
          Navigator.of(context).pop();
      },
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
                  CustomText(AppStrings.language),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  CommonDropdownDialog<String>(
                    items: commentController.languages,
                    selectedValue:
                        commentController.selectedLanguage.value.isEmpty
                            ? null
                            : commentController.selectedLanguage.value,
                    title: AppStrings.selectLanguage.tr,
                    hintText: AppStrings.languageHint.tr,
                    displayValue: (value) => value,
                    onChanged: (value) {
                      commentController.selectedLanguage.value = value!;
                      commentController.onSelectionChanged();
                    },
                  ),
                  SizedBox(
                    height: SizeConfig.size15,
                  ),

                  /// Emotion Dropdown
                  CustomText(AppStrings.emotion),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  CommonDropdownDialog<CommentTypeModel>(
                    items: emotionList,
                    selectedValue: commentController.selectedEmotion.value.isEmpty
                        ? null
                        : emotionList.firstWhere(
                          (e) => e.name == commentController.selectedEmotion.value,
                      orElse: () => emotionList.first,
                    ),
                    title: AppStrings.selectEmotion.tr,
                    hintText: AppStrings.emotionHint.tr,
                    displayValue: (value) => value.name, // <-- use the emotion name
                    onChanged: (value) {
                      commentController.selectedEmotion.value = value?.sludId??"";
                      commentController.onSelectionChanged();
                    },
                  ),

                  SizedBox(
                    height: SizeConfig.size15,
                  ),
                  CustomText(AppStrings.commentType),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  CommonDropdownDialog<CommentTypeModel>(
                    items: commentTypes,
                    selectedValue: commentController.selectedCommentType.value.isEmpty
                        ? null
                        : commentTypes.firstWhere(
                          (e) => e.name == commentController.selectedCommentType.value,
                      orElse: () => commentTypes.first,
                    ),
                    title: AppStrings.selectCommentType,
                    hintText: "Eg. Shock...",
                    displayValue: (value) => value.name,
                    onChanged: (value) {
                      if (value != null) {
                        commentController.selectedCommentType.value = value.sludId;
                        commentController.onSelectionChanged();
                      }
                    },
                  ),

                  SizedBox(
                    height: SizeConfig.size30,
                  ),

                  /// Button

                  Obx(
                    () => CustomBtn(
                      title:AppStrings.generateComment,
                      isValidate: commentController.isFormValid,
                      onTap: commentController.isFormValid
                          ? () async {
                        if(commentType=="comment"){
                          await commentController
                              .generateAiPostCommentController(postID: dataId);
                        }
                        else if(commentType=="comment_reply"){
                          await commentController
                              .generateAiPostCommentReplyController(commentID: dataId);
                        }

                            }
                          : null,
                    ),
                  ),

                  Obx(() {
                    if (commentController.suggestions.isEmpty)
                      return SizedBox();
                    final tempSelected =
                        commentController.selectedSuggestion.value.obs;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),
                        CustomText("${AppStrings.suggestions.tr}:",
                            fontSize: 16, fontWeight: FontWeight.bold),
                        SizedBox(height: 10),
                        Column(
                          children: commentController.suggestions.map((sugg) {
                            final isSelected = tempSelected.value == sugg;
                            return GestureDetector(
                              onTap: () => commentController
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
                                title: AppStrings.cancel,
                                borderColor: AppColors.primaryColor,
                                bgColor: AppColors.white,
                                textColor: AppColors.primaryColor,
                              )),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomBtn(
                                  title: AppStrings.save,
                                  isValidate: tempSelected.value.isNotEmpty,
                                  // Enable/Disable button
                                  onTap: tempSelected.value.isNotEmpty
                                      ? () {
                                          // Save Selected Suggestion
                                          commentController.selectedSuggestion
                                              .value = tempSelected.value;
                                          // Set text to TextField
                                          commentController
                                              .sendMessageController
                                              .text = tempSelected.value;
                                          commentController
                                                  .sendMessageController
                                                  .selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                                offset:
                                                    tempSelected.value.length),
                                          );

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
