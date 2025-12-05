import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/comment/controller/comment_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmotionChipSelector extends StatelessWidget {
  final List<CommentTypeModel> emotionList;
  final RxString selectedEmotion;

  EmotionChipSelector({
    required this.emotionList,
    required this.selectedEmotion,
  });
  final commentController = Get.find<CommentController>();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: emotionList.map((emotion) {
          final bool isSelected = selectedEmotion.value == emotion.sludId;

          return GestureDetector(
            // onTap: () => selectedEmotion.value = emotion.sludId,
              onTap: () {
                selectedEmotion.value = emotion.sludId;
                commentController.expandedTileIndex.value = 2; // Open Comment Type tile
              },

              child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.grey.shade400,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LocalAssets(
                    imagePath: emotion.icon,
                    width: 20,
                    height: 20,
                    imgColor: isSelected ? AppColors.white : Colors.black,
                  ),
                  SizedBox(width: 6),
                  CustomText(
                    emotion.name.tr,
                    fontWeight:
                        isSelected ? FontWeight.w500 : FontWeight.normal,
                    color: isSelected ? AppColors.white : Colors.black,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
