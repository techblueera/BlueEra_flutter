import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_list_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/v2/widgets/lab_category_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Top-level lab category grid shown on the lab profile/tests tab.
class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key, this.labID});

  final String? labID;

  static const List<_LabCategory> _categories = [
    _LabCategory(
      title: 'blood_routine',
      collection: 'Blood & Routine Tests',
      image: 'assets/category/medical/lab_blood_test_img.png',
    ),
    _LabCategory(
      title: 'preventive_wellness',
      collection: 'Preventive & Wellness Checkups',
      image: 'assets/category/medical/lab_wellness_img.png',
    ),
    _LabCategory(
      title: 'women_pregnancy',
      collection: 'Women, Pregnancy & Child Health',
      image: 'assets/category/medical/lab_women_helth_img.png',
    ),
    _LabCategory(
      title: 'diagnostics_imaging',
      collection: 'Diagnostics & Imaging',
      image: 'assets/category/medical/lab_diagnostics_img.png',
    ),
    _LabCategory(
      title: 'organ_system',
      collection: 'Organ & System Health',
      image: 'assets/category/medical/lab_organ_img.png',
    ),
    _LabCategory(
      title: 'infection_immunity',
      collection: 'Infection, Cancer & Immunity',
      image: 'assets/category/medical/lab_infection_img.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomText(
                AppStrings.labUpdateYourTest.tr,
                fontWeight: FontWeight.w700,
              ),
              Spacer(),
              InkWell(
                onTap: () {
                  Get.to(
                    () => LabCategoryScreen(
                      controller: Get.find<LabFullDetailsController>(),
                    ),
                  );
                },
                child: CustomText(
                  AppStrings.viewAll.tr,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          // Explicit zero padding — without it, GridView.builder inherits
          // MediaQuery safe-area padding from an ancestor scroll view and
          // renders a visible gap between the header row and the first
          // tile row.
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: SizeConfig.size12,
              mainAxisSpacing: SizeConfig.size12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) => _buildCategoryTile(_categories[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(_LabCategory category) {
    return InkWell(
      onTap: () => Get.to(
        LabTestListScreen(
          collection: category.collection,
          title: category.title,
          labId: labID,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(category.image, fit: BoxFit.contain),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: CustomText(
                  category.title,
                  fontSize: SizeConfig.size13,
                  fontWeight: FontWeight.w500,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabCategory {
  final String title;
  final String collection;
  final String image;

  const _LabCategory({
    required this.title,
    required this.collection,
    required this.image,
  });
}
