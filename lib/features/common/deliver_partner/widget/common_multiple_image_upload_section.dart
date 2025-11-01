import 'dart:io';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';

class CommonMultipleImageUploadSection extends StatelessWidget {
  final String title;
  final List<File>? images;
  final int? minImages;
  final int maxImages;
  final VoidCallback onAddImage;
  final Function(int) onRemoveImage;

  const CommonMultipleImageUploadSection({
    super.key,
    required this.title,
    required this.images,
    this.minImages,
    required this.maxImages,
    required this.onAddImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final imageList = images ?? [];

    return CustomFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  title,
                  fontSize: SizeConfig.small,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if(minImages!=null)
                Padding(
                  padding: EdgeInsets.only(left: SizeConfig.size8),
                  child: CustomText("Min-$minImages Images/Max-${maxImages}Images",
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w400
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final spacing = SizeConfig.size6;

              // 4 items with equal width and gaps
              final itemWidth = (availableWidth - (spacing * 5)) / 4;

              return SizedBox(
                height: itemWidth, // square images
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: maxImages,
                  separatorBuilder: (_, __) => SizedBox(width: spacing),
                  itemBuilder: (context, index) {
                    final hasImage = index < imageList.length;

                    return GestureDetector(
                      onTap: () {
                        if (!hasImage) onAddImage();
                      },
                      child: Container(
                        width: itemWidth,
                        height: itemWidth,
                        decoration: BoxDecoration(
                          color: AppColors.whiteFE,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.greyE5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (hasImage)
                              Image.file(imageList[index], fit: BoxFit.cover)
                            else
                              const Center(
                                child: Icon(Icons.photo_outlined,
                                    color: Colors.grey, size: 28),
                              ),
                            if (hasImage)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => onRemoveImage(index),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
