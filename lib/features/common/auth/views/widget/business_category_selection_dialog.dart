import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/views/widget/business_sub_category_selection_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../personal/personal_profile/controller/languge_list_controller.dart';
import '../../model/business_category_response_model.dart';
import '../../model/get_categories_model.dart';

class BusinessCategorySelectionDialog extends StatefulWidget {
  final AuthController authController;
  final BusinessType businessType;

  const BusinessCategorySelectionDialog({
    Key? key,
    required this.authController,
    required this.businessType,
  }) : super(key: key);

  @override
  State<BusinessCategorySelectionDialog> createState() => _BusinessCategorySelectionDialogState();
}

class _BusinessCategorySelectionDialogState extends State<BusinessCategorySelectionDialog> {
  late AuthController _authController;
  final LanguageListController langController =
      Get.find<LanguageListController>();
  BusinessCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _authController = widget.authController;
    _authController.fetchBusinessCategoriesByType(
        businessTpe: widget.businessType
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
      child: Container(
        padding: EdgeInsets.only(
          top: SizeConfig.size8,
          left: SizeConfig.size16,
          right: SizeConfig.size8,
          bottom: SizeConfig.size16,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white, // Use your DialogThemeData().backgroundColor
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    widget.businessType.name,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: SizeConfig.size16,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            SizedBox(height: SizeConfig.size3),

            // CustomText(
            //   '${AppStrings.selectSubCategory.tr} (${widget.categoryName})',
            //   color: AppColors.secondaryTextColor,
            //   fontWeight: FontWeight.w700,
            //   fontSize: SizeConfig.size16,
            // ),
            // SizedBox(height: SizeConfig.size12),

            // Body (Loader vs List)
            Flexible(
              child: _buildBody(),
            ),

            SizedBox(height: SizeConfig.size12),

            // Footer (Buttons)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: SizeConfig.size8),
                child: CustomBtn(
                  onTap: _selectedCategory != null ? () async {

                    final BusinessType businessType = widget.businessType;
                    final String categorySlugId = _selectedCategory?.tagId ?? '';
                    final String categoryName = _selectedCategory?.name ?? '';

                    final SubCategories? selected = await showDialog<SubCategories>(
                      context: context,
                      builder: (context) {
                        return BusinessSubCategorySelectionDialog(
                            authController: _authController,
                            businessType: businessType,
                            categorySlugId: categorySlugId,
                            categoryName: categoryName
                        );
                      },
                    );

                    if (selected != null) {
                      Get.back();
                      Navigator.pushNamed(
                        context,
                        RouteHelper.getGstNumberScreenRoute(),
                        arguments: {
                          ApiKeys.argAccountType: AppConstants.business,
                          ApiKeys.argBusinessType: businessType,
                          ApiKeys.argCategoryId: categorySlugId,
                          ApiKeys.argCategoryName: categoryName,
                          ApiKeys.argSubCategory: selected
                        },
                      );
                    }

                  } : null,
                  title: AppStrings.next,
                  height: SizeConfig.size30,
                  width: SizeConfig.size60,
                  bgColor: _selectedCategory == null ? Colors.grey : AppColors.primaryColor,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- 3. Loader & List UI ---
  Widget _buildBody() {
    return Padding(
      padding: EdgeInsets.only(right: SizeConfig.size8),
      child: Obx((){
        if (_authController.isBusinessCategoriesLoading.value) {
          return Container(
            height: 100,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }

        if (_authController.categoryErrorMessage.value != null) {
          return Container(
            height: 100,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20.0),
            child: CustomText(
                _authController.categoryErrorMessage.value!,
                color: AppColors.red,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600
            ),
          );
        }

        if (_authController.businessCategoriesList.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20.0),
            height: 100,
            alignment: Alignment.center,
            child: CustomText(
              langController.tr("No categories found."),
              fontSize: SizeConfig.medium,
              color: AppColors.secondaryTextColor,
            ),
          );
        }

        List<BusinessCategory> _categories = _authController.businessCategoriesList;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final item = _categories[index];
            final isSelected = _selectedCategory?.tagId == item.tagId;

            return Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                dense: true,
                title: CustomText(
                  item.name ?? AppStrings.unknown,
                  fontWeight: FontWeight.w400,
                  fontSize: SizeConfig.size15,
                ),
                onTap: () {
                  setState(() {
                    _selectedCategory = item;
                  });
                },
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                    : null,
              ),
            );
          },
        );

      }),
    );

  }
}