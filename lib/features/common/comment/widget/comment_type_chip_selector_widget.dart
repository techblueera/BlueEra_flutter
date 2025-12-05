import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/comment/controller/comment_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommentTypeChipSelector extends StatelessWidget {
  final List<CommentTypeModel> items;
  final RxString selectedType;
  final commentController = Get.find<CommentController>();

   CommentTypeChipSelector({
    Key? key,
    required this.items,
    required this.selectedType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((type) {
            final bool isSelected = selectedType.value == type.sludId;

            return GestureDetector(
              onTap: () {
                selectedType.value = type.sludId;
                // commentController.onSelectionChanged();
                  commentController.expandedTileIndex.value = -1; // Close all after final choose

              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
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
                      imagePath: type.icon,
                      width: 18,
                      height: 18,
                      imgColor: isSelected ? Colors.white : Colors.black,
                    ),
                    SizedBox(width: 6),
                    CustomText(
                      type.name.tr,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                      color: isSelected ? AppColors.white : Colors.black,
                    )
                  ],
                ),
              ),
            );
          }).toList(),
        ));
  }
}
