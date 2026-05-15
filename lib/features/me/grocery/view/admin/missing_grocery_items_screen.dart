import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_snap_search_response.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MissingGroceryItemsScreen extends StatelessWidget {
  final GroceryController controller;
  final List<MissingProducts> missingProducts;

  const MissingGroceryItemsScreen({
    super.key,
    required this.controller,
    required this.missingProducts
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.groceryViewMissingItemsTitle.tr,
      ),
      body: missingProducts.isNotEmpty
        ? SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size15
        ),
          child: CustomFormCard(
            padding: EdgeInsets.zero,
            child: Column(
            children: [
              // Table Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: CustomText(AppStrings.groceryViewProductName.tr, fontWeight: FontWeight.w600, fontSize: SizeConfig.small, color: AppColors.mainTextColor)),
                    Expanded(child: CustomText(AppStrings.groceryViewBrand.tr, textAlign: TextAlign.center, fontWeight: FontWeight.bold, color: AppColors.mainTextColor)),
                    Expanded(child: CustomText(AppStrings.groceryViewApproxPrice.tr, textAlign: TextAlign.right, fontWeight: FontWeight.bold, color: AppColors.mainTextColor)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const CommonHorizontalDivider(height: 0.5, color: AppColors.greyE5),
              ),
              // List of Items
              ListView.separated(
                itemCount: missingProducts.length,
                shrinkWrap: true,
                primary: false,
                physics: NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: const CommonHorizontalDivider(height: 0.5, color: AppColors.greyE5)
                ),
                itemBuilder: (context, index) {
                  final item = missingProducts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CustomText(
                            '${item.name}: ${item.unit}',
                            fontWeight: FontWeight.w600, fontSize: SizeConfig.small, color: AppColors.secondaryTextColor
                          ),
                        ),
                        Expanded(
                          child: CustomText(
                            item.brand ?? AppStrings.na,
                            textAlign: TextAlign.center,
                            fontWeight: FontWeight.w600, fontSize: SizeConfig.small, color: AppColors.secondaryTextColor
                          ),
                        ),
                        Expanded(
                          child: CustomText(
                            item.approxPrice!=null ? '${item.approxPrice}' : AppStrings.na,
                            textAlign: TextAlign.right,
                            fontWeight: FontWeight.w600, fontSize: SizeConfig.small, color: AppColors.secondaryTextColor
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            ),
          ),
        )
        : EmptyStateWidget(
          message: AppStrings.groceryViewNoMissingProducts.tr
      ),
      bottomNavigationBar: missingProducts.isNotEmpty
          ? Container(
            color: AppColors.white,
            padding: EdgeInsets.all(SizeConfig.size15),
            child: SafeArea(
              child: CustomBtn(
                title: controller.missingProductRequestsLoading.value
                    ? null
                    : AppStrings.groceryViewRequestForMissingItem.tr,
                isLoading: controller.missingProductRequestsLoading.value,
                onTap: () {
                  controller.missingGroceryProductRequestsApi(missingProducts);
                },
                bgColor: AppColors.primaryColor,
              ),
            ),
          )
          : null,
    );
  }
}