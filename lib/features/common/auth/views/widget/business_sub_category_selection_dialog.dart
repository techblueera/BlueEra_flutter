import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/get_categories_model.dart';

class BusinessSubCategorySelectionDialog extends StatefulWidget {
  final AuthController authController;
  final BusinessType businessType;
  final String categorySlugId;
  final String categoryName;

  const BusinessSubCategorySelectionDialog({
    Key? key,
    required this.authController,
    required this.businessType,
    required this.categorySlugId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<BusinessSubCategorySelectionDialog> createState() => _BusinessSubCategorySelectionDialogState();
}

class _BusinessSubCategorySelectionDialogState extends State<BusinessSubCategorySelectionDialog> {
  late AuthController _authController;
  SubCategories? _selectedSubCat;

  @override
  void initState() {
    super.initState();
    _authController = widget.authController;
    _authController.fetchBusinessSubCategories(
        categorySlugId: widget.categorySlugId
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
          color: Colors.white,
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
                    widget.categoryName.replaceAll('\n', ' '),
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
                  onTap: _selectedSubCat != null ? (){
                    // Only close if something is selected or just cancel
                    Navigator.of(context).pop(_selectedSubCat);
                  } : null,
                  title: AppStrings.next,
                  height: SizeConfig.size30,
                  width: SizeConfig.size60,
                  bgColor: _selectedSubCat == null ? Colors.grey : AppColors.primaryColor,
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
        if (_authController.isBusinessSubCategoriesLoading.value) {
          return Container(
            height: 100,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }

        if (_authController.subCategoryErrorMessage.value != null) {
          return Container(
            height: 100,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20.0),
            child: CustomText(
              _authController.subCategoryErrorMessage.value!,
              color: AppColors.red,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600
            ),
          );
        }

        if (_authController.businessSubCategoriesList.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20.0),
            height: 100,
            alignment: Alignment.center,
            child: CustomText(
              "No sub-categories found.",
              fontSize: SizeConfig.medium,
              color: AppColors.secondaryTextColor,
            ),
          );
        }

        List<SubCategories> _subCategories = _authController.businessSubCategoriesList;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: _subCategories.length,
          itemBuilder: (context, index) {
            final item = _subCategories[index];
            final isSelected = _selectedSubCat?.sId == item.sId;

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
                    _selectedSubCat = item;
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