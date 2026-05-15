import 'package:BlueEra/core/anim/pulse_animation.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../model/sub_category_root_category_response.dart';

Future<void> showCategoryBottomSheet(BuildContext context) async {
  final controller = Get.find<ProductController>();
  controller.searchResults.clear();
  controller.searchController.text = controller.selectedCategory.value??'';
  controller.onSearchChanged(controller.searchController.text);

  await showModalBottomSheet<List<CategoryData>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (_) {
      return Obx(() {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CustomText(
                      AppStrings.category,
                      color: AppColors.mainTextColor,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppConstants.OpenSans,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              CommonHorizontalDivider(
                color: AppColors.whiteE5,
              ),

              // --- Search Bar ---
              Padding(
                padding: EdgeInsets.all(SizeConfig.size12),
                child: CommonTextField(
                  textEditController: controller.searchController,
                  onChange: (value) => controller.onSearchChanged(value),
                  hintText: AppStrings.searchCategories,
                  isValidate: false,
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: SizeConfig.medium,
                    fontFamily: AppConstants.OpenSans,
                  ),
                  pIcon: Icon(
                    Icons.search,
                    color: Colors.grey[500],
                    size: SizeConfig.size20,
                  ),
                  sIcon: controller.isSearchActive.value
                      ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[500],
                      size: SizeConfig.size20,
                    ),
                    onPressed: () => controller.clearSearch(),
                  )
                      : null,
                ),
              ),

              // --- Breadcrumb (only show when not searching) ---
              // if (controller.breadcrumb.isNotEmpty && !controller.isSearchActive.value)
              //   Container(
              //     width: SizeConfig.screenWidth,
              //     padding: EdgeInsets.all(SizeConfig.size12),
              //     margin: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
              //     decoration: BoxDecoration(
              //         color: AppColors.white,
              //         boxShadow: [AppShadows.textFieldShadow],
              //         borderRadius: BorderRadius.circular(10),
              //         border: Border.all(
              //             color: AppColors.greyE5,
              //             width: 1.5
              //         )
              //     ),
              //     child: Wrap(
              //       children: List.generate(
              //         controller.breadcrumb.length,
              //             (i) {
              //           final item = controller.breadcrumb[i];
              //           final isLast = i == controller.breadcrumb.length - 1;
              //
              //           return InkWell(
              //             onTap: () => controller.goToBreadcrumb(i),
              //             child: Row(
              //               mainAxisSize: MainAxisSize.min,
              //               children: [
              //                 CustomText(
              //                   item.name,
              //                   color: isLast ? AppColors.mainTextColor : AppColors.primaryColor,
              //                   fontSize: SizeConfig.medium,
              //                   fontWeight: FontWeight.w600,
              //                   fontFamily: AppConstants.OpenSans,
              //                 ),
              //                 if (!isLast)
              //                   const Icon(Icons.chevron_right, size: 16),
              //               ],
              //             ),
              //           );
              //         },
              //       ),
              //     ),
              //   ),

              const SizedBox(height: 8),


              // --- Categories List ---
              Expanded(
                  child: controller.loading.value
                      ? Center(
                      child:     PulseAnimation( // Using the helper class from the previous step
                        child: CustomText(
                          '${AppStrings.searching.tr}...',
                          fontSize: SizeConfig.extraLarge22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                          )
                      : controller.isSearchActive.value
                      ? _buildSearchResults(controller, context)
                      : _buildSearchIndicationWidget()
                // : controller.isSearchActive.value
                // ? _buildSearchResults(controller, context)
                // : _buildManualCategories(controller, context),
              ),

              // --- Back Button (only show when not searching and breadcrumb exists) ---
              // if (controller.breadcrumb.isNotEmpty && !controller.isSearchActive.value)
              //   Padding(
              //     padding: EdgeInsets.only(
              //       left: SizeConfig.size12,
              //       right: SizeConfig.size12,
              //       top: SizeConfig.size12,
              //       bottom: SizeConfig.size30,
              //     ),
              //     child: PositiveCustomBtn(
              //       onTap: () {
              //         final lastIndex = controller.breadcrumb.length - 2;
              //         if (lastIndex >= 0) {
              //           controller.goToBreadcrumb(lastIndex);
              //         } else {
              //           controller.reset();
              //         }
              //       },
              //       title: 'Back',
              //       bgColor: AppColors.white,
              //       borderColor: AppColors.primaryColor,
              //       textColor: AppColors.primaryColor,
              //       radius: 10.0,
              //     ),
              //   ),

            ],
          ),
        );
      });
    },
  );

}

Widget _buildSearchResults(ProductController controller, BuildContext context) {
  return controller.searchResults.isNotEmpty ? Scrollbar(
    thumbVisibility: true,
    thickness: 6.0,
    radius: const Radius.circular(10),
    child: ListView.separated(
      itemCount: controller.searchResults.length,
      physics: BouncingScrollPhysics(),
      primary: true,
      separatorBuilder: (_, __) => CommonHorizontalDivider(color: AppColors.whiteE5),
      itemBuilder: (_, index) {
        final cat = controller.searchResults[index];
        return ListTile(
          title: CustomText(
            cat.name ?? '',
            color: AppColors.mainTextColor,
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w400,
            fontFamily: AppConstants.OpenSans,
          ),
          trailing: PositiveCustomBtn(
            onTap: () {
              controller.selectedCategoryId.value = cat.sId??'';
              controller.selectedCategory.value = cat.name??'';
              Navigator.pop(context);
              // controller.breadcrumb.add(cat);
              // Navigator.pop(context, controller.breadcrumb);
            },
            title: AppStrings.select,
            width: SizeConfig.size60,
            height: SizeConfig.size30,
            bgColor: AppColors.primaryColor.withValues(alpha: 0.1),
            borderColor: AppColors.primaryColor,
            textColor: AppColors.primaryColor,
            radius: 10.0,
          ),
        );
      },
    ),
  ) : ListTile(
    title: CustomText(
      AppStrings.other,
      color: AppColors.mainTextColor,
      fontSize: SizeConfig.large,
      fontWeight: FontWeight.w400,
      fontFamily: AppConstants.OpenSans,
    ),
    trailing: PositiveCustomBtn(
      onTap: () {
        controller.selectedCategoryId.value = controller.otherCategoryId;
        controller.selectedCategory.value = 'OTHER';
        Navigator.pop(context);
        // controller.breadcrumb.add(cat);
        // Navigator.pop(context, controller.breadcrumb);
      },
      title: AppStrings.select,
      width: SizeConfig.size60,
      height: SizeConfig.size30,
      bgColor: AppColors.primaryColor.withValues(alpha: 0.1),
      borderColor: AppColors.primaryColor,
      textColor: AppColors.primaryColor,
      radius: 10.0,
    ),
  );
}

Widget _buildSearchIndicationWidget() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 140,
          width: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Soft Background Glow
              Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryColor.withValues(alpha: 0.15),
                      AppColors.primaryColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),

              // 2. Animated Background Pulse Rings
              ...List.generate(3, (index) => PulseAnimation(
                child: Container(
                  width: 70.0 * (index + 1),
                  height: 70.0 * (index + 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.15 / (index + 1)),
                      width: 1.5,
                    ),
                  ),
                ),
              )),

              // 3. Central Icon with slight shadow for depth
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.manage_search_rounded,
                  size: 50,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.secondaryTextColor, AppColors.primaryColor],
          ).createShader(bounds),
          child: CustomText(
            AppStrings.pleaseSearchForCategory,
            fontSize: SizeConfig.extraLarge22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}



