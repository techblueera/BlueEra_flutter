import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/comment/controller/comment_controller.dart';
import 'package:BlueEra/features/common/comment/widget/comment_type_chip_selector_widget.dart';
import 'package:BlueEra/features/common/comment/widget/emotion_chip_selector_widget.dart';
import 'package:BlueEra/features/common/comment/widget/language_chip_selector_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostAiCommentScreen extends StatefulWidget {
  PostAiCommentScreen(
      {super.key, required this.dataId, required this.commentType});

  final String dataId;
  final String commentType;

  @override
  State<PostAiCommentScreen> createState() => _PostAiCommentScreenState();
}

class _PostAiCommentScreenState extends State<PostAiCommentScreen> {
  final commentController = Get.find<CommentController>();

  @override
  void initState() {
    // TODO: implement initState
    commentController.expandedTileIndex.value = -1;
    logs("commentController.expandedTileIndex.value= ${commentController.expandedTileIndex.value}");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        title: AppStrings.aiGenerativeComment,
        onBackTap: () {
          Navigator.of(context).pop();
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size20, vertical: SizeConfig.size20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: SizeConfig.size10,
                ),
                // Language tile (index 0)
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: Obx(() => ExpansionTile(
                        key: ValueKey(
                            'language_tile_${commentController.expandedTileIndex.value == 0}'),
                        initiallyExpanded:
                            commentController.expandedTileIndex.value == 0,
                        tilePadding: EdgeInsets.zero,
                        // remove default title padding
                        childrenPadding: EdgeInsets.zero,
                        // remove default children padding
                        shape: RoundedRectangleBorder(),
                        // remove default underline border
                        collapsedShape: RoundedRectangleBorder(),
                        // when collapsed
                        visualDensity: VisualDensity(vertical: -4),
                        // remove vertical padding
                        minTileHeight: 0,
                        // remove tile height

                        title: CustomText(
                          AppStrings.selectLanguage,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.bold,
                        ),
                        onExpansionChanged: (expanded) {
                          commentController.expandedTileIndex.value =
                              expanded ? 0 : -1;
                        },
                        children: [
                          LanguageChipSelector(
                            languages: SUPPORTED_LANGUAGES,
                            selectedLanguage:
                                commentController.selectedLanguage,
                          ),
                        ],
                      )),
                ),

                SizedBox(height: SizeConfig.size10),

                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: Obx(() => ExpansionTile(
                        key: ValueKey(
                            'emotion_tile_${commentController.expandedTileIndex.value == 1}'),
                        initiallyExpanded:
                            commentController.expandedTileIndex.value == 1,
                        tilePadding: EdgeInsets.zero,
                        // Remove default tile padding
                        childrenPadding: EdgeInsets.zero,
                        // Remove children padding
                        shape: RoundedRectangleBorder(),
                        // Remove expansion underline
                        collapsedShape: RoundedRectangleBorder(),
                        // Remove underline when collapsed
                        visualDensity: VisualDensity(vertical: -4),
                        // remove vertical padding
                        minTileHeight: 0,
                        // remove tile height

                        title: CustomText(
                          AppStrings.selectEmotion,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.bold,
                        ),

                        onExpansionChanged: (expanded) {
                          commentController.expandedTileIndex.value =
                              expanded ? 1 : -1;
                        },

                        children: [
                          EmotionChipSelector(
                            emotionList: emotionList,
                            selectedEmotion: commentController.selectedEmotion,
                          ),
                        ],
                      )),
                ),

                SizedBox(
                  height: SizeConfig.size15,
                ),
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: Obx(() => ExpansionTile(
                        key: ValueKey(
                            'comment_type_tile_${commentController.expandedTileIndex.value == 2}'),
                        initiallyExpanded:
                            commentController.expandedTileIndex.value == 2,
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(),
                        collapsedShape: RoundedRectangleBorder(),
                        visualDensity: VisualDensity(vertical: -4),
                        minTileHeight: 0,
                        title: CustomText(
                          AppStrings.selectCommentType,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.bold,
                        ),
                        onExpansionChanged: (expanded) {
                          commentController.expandedTileIndex.value =
                              expanded ? 2 : -1;
                        },
                        children: [
                          CommentTypeChipSelector(
                            items: commentTypes,
                            selectedType: commentController.selectedCommentType,
                          ),
                        ],
                      )),
                ),

                SizedBox(
                  height: SizeConfig.size30,
                ),

                /// Button

                Obx(
                  () => CustomBtn(
                    title: AppStrings.generateComment,
                    isValidate: commentController.isFormValid,
                    onTap: commentController.isFormValid
                        ? () async {
                            if (widget.commentType == "comment") {
                              await commentController
                                  .generateAiPostCommentController(
                                      postID: widget.dataId);
                            } else if (widget.commentType == "comment_reply") {
                              await commentController
                                  .generateAiPostCommentReplyController(
                                      commentID: widget.dataId);
                            }
                          }
                        : null,
                  ),
                ),

                Obx(() {
                  if (commentController.suggestions.isEmpty) return SizedBox();
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        commentController.sendMessageController
                                            .text = tempSelected.value;
                                        commentController.sendMessageController
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
        ),
      ),
    );
  }
}
