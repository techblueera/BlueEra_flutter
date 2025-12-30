import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../model/lab_content_list_view_model.dart';
class CategorySectionWidget extends StatelessWidget {
  final LabContentListViewModel category;

  const CategorySectionWidget({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size10),

          CustomText(
            category.name ?? "",
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),

          SizedBox(height: SizeConfig.size16),

          GridView.builder(
            padding: EdgeInsets.only(bottom: SizeConfig.size10),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: category.children!.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final child = category.children![index];

              return Column(
                children: [
                  // ICON
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xffEAF2FF),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      "assets/category/foods/all_food_category/${child.key}.png",
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.medical_information),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // LABEL
                  CustomText(
                    child.name ?? "",
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
