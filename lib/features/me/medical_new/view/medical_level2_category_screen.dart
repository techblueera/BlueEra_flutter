import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_nested_category_model.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_subcategory_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MedicalLevel2CategoryScreen extends StatelessWidget {
  final String title;
  final List<MedicalNestedCategoryModel> level2Categories;

  const MedicalLevel2CategoryScreen({
    super.key,
    required this.title,
    required this.level2Categories,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(title: title),
      body: level2Categories.isEmpty
          ? Center(
              child: CustomText(
                'No subcategories available',
                color: AppColors.secondaryTextColor,
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(SizeConfig.size12),
              itemCount: level2Categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: SizeConfig.size10,
                mainAxisSpacing: SizeConfig.size10,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final category = level2Categories[index];
                return _buildSubCategoryCard(category);
              },
            ),
    );
  }

  Widget _buildSubCategoryCard(MedicalNestedCategoryModel category) {
    final childCount = category.children?.length ?? 0;

    return InkWell(
      onTap: () {
        final level3Children = category.children ?? [];
        if (level3Children.isNotEmpty) {
          Get.to(() => MedicalSubCategoryScreen(
                arrLevel3Category: level3Children,
              ));
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: (category.image != null && category.image!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: category.image!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey.shade100,
                          child: Center(
                            child: LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              width: 60,
                              height: 60,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: Center(
                            child: LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              width: 60,
                              height: 60,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: Center(
                          child: LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            width: 60,
                            height: 60,
                          ),
                        ),
                      ),
              ),
            ),

            // Name + Count
            Padding(
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    category.name ?? '',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: 2),
                  CustomText(
                    '$childCount Category',
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
