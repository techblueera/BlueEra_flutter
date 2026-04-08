import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/food_snap_search_response.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MissingFoodItemsScreen extends StatefulWidget {
  final FoodServiceController controller;
  final List<MissingFoodProducts> missingProducts;

  const MissingFoodItemsScreen({
    super.key,
    required this.controller,
    required this.missingProducts,
  });

  @override
  State<MissingFoodItemsScreen> createState() => _MissingFoodItemsScreenState();
}

class _MissingFoodItemsScreenState extends State<MissingFoodItemsScreen> {
  var controller = Get.find<FoodServiceController>();

  @override
  initState(){
    super.initState();
    controller.missingProducts.assignAll(widget.missingProducts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CommonBackAppBar(
          title: AppStrings.foodMissingItemsLabel.tr,
        ),
        body: Obx(() {
          if (controller.missingProducts.isEmpty) {
            return EmptyStateWidget(message: AppStrings.foodNoMissingProducts.tr);
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            child: SafeArea(
              child: CustomFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Yellow Highlight
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: CustomText(
                        AppStrings.foodMissingItemsName.tr,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                    const CommonHorizontalDivider(
                        height: 1.0, color: AppColors.greyE5),

                    // List of Items
                    ListView.separated(
                      itemCount: controller.missingProducts.length,
                      shrinkWrap: true,
                      primary: false,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (context, index) =>
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.0),
                        child: CommonHorizontalDivider(
                            height: 0.5, color: AppColors.greyE5),
                      ),
                      itemBuilder: (context, index) {
                        final item = controller.missingProducts[index];
                        return _buildItemRow(item, index);
                      },
                    ),

                    SizedBox(height: 20)
                  ],
                ),
              ),
            ),
          );
        })
    );
  }

  Widget _buildItemRow(MissingFoodProducts item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
      child: Row(
        children: [
          // Placeholder Image Box
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 24),
            ),
          ),
          const SizedBox(width: 10),

          // Name and Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  item.name ?? AppStrings.na,
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.medium,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                CustomText(
                  item.approxPrice != null ? '₹${item.approxPrice}' : AppStrings.na,
                  fontWeight: FontWeight.w400,
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),

          // Create Button
          const SizedBox(width: 8),
          _buildActionButton(item, index),

        ],
      ),
    );
  }

  Widget _buildActionButton(MissingFoodProducts item, int index) {
    // SCENARIO 3: Inventory Created (Complete)
    if (item.inventoryId != null && item.inventoryId!.isNotEmpty) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 28);
    }

    // SCENARIO 2: Product Created, but not in Inventory
    if (item.productId != null && item.productId!.isNotEmpty) {
      return CustomBtn(
        height: 28,
        width: 85,
        title: AppStrings.foodAddStockLabel.tr,
        bgColor: AppColors.primaryColor,
        onTap: () {
          Get.toNamed(
            RouteHelper.getAddSingleProductScreenRoute(),
            arguments: {
              ApiKeys.productId: item.productId,
              ApiKeys.argCreateMissingProductIndex: index,
            },
          );
        },
      );
    }

    // SCENARIO 1: Product Not Created (Initial)
    return CustomBtn(
      height: 28,
      width: 60,
      title: AppStrings.create.tr,
      textColor: AppColors.primaryColor,
      radius: 10,
      bgColor: AppColors.white,
      borderColor: AppColors.primaryColor,
      onTap: () {
        Get.toNamed(RouteHelper.getFoodEntryAiScreenRoute(),
            arguments: {
              ApiKeys.argCreateMissingProductIndex: index,
            });
      },
    );
  }

}