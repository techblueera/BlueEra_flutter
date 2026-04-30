import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_home_response_model.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_inventory_product_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// ss11 — Shows level 1 children of a selected category
class MedicalInventoryCategoryScreen extends StatelessWidget {
  final String title;
  final List<CategoryWithProducts> children;

  const MedicalInventoryCategoryScreen({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: title),
      body: children.isEmpty
          ? Center(
              child: CustomText(
                AppStrings.medicalNoSubcategoriesFound,
                color: AppColors.secondaryTextColor,
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(SizeConfig.size12),
              itemCount: children.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: SizeConfig.size10,
                mainAxisSpacing: SizeConfig.size10,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final child = children[index];
                return _categoryCard(child);
              },
            ),
    );
  }

  Widget _categoryCard(CategoryWithProducts category) {
    final subCategoryCount = _countLeafCategories(category);
    final productCount = category.getAllProducts().length;

    return InkWell(
      onTap: () {
        // Collect leaf categories (level 2/3) that have products
        final leafCategories = _collectLeafCategories(category);
        if (leafCategories.isEmpty) {
          commonSnackBar(message: 'NA');
          return;
        }
        Get.to(() => MedicalInventoryProductScreen(
              title: category.name ?? '',
              leafCategories: leafCategories,
            ));
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder image area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
              ),
            ),
            // Name + counts
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
                  SizedBox(height: 4),
                  Row(
                    children: [
                      _countChip('$subCategoryCount ${AppStrings.medicalCategorySuffix.tr}'),
                      SizedBox(width: 6),
                      _countChip('$productCount ${AppStrings.medicalProductSuffix.tr}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomText(
        text,
        fontSize: 10,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  /// Count leaf categories (categories with products or no children)
  int _countLeafCategories(CategoryWithProducts cat) {
    if (cat.children == null || cat.children!.isEmpty) return 1;
    int count = 0;
    for (final child in cat.children!) {
      count += _countLeafCategories(child);
    }
    return count;
  }

  /// Collect leaf categories that have products for the sidebar
  List<CategoryWithProducts> _collectLeafCategories(CategoryWithProducts cat) {
    List<CategoryWithProducts> result = [];
    if (cat.products != null && cat.products!.isNotEmpty) {
      result.add(cat);
    }
    if (cat.children != null) {
      for (final child in cat.children!) {
        result.addAll(_collectLeafCategories(child));
      }
    }
    return result;
  }
}
