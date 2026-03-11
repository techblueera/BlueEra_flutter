import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/food_snap_search_response.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';

class MissingFoodItemsScreen extends StatelessWidget {
  final FoodServiceController controller;
  final List<MissingFoodProducts> missingProducts;

  const MissingFoodItemsScreen({
    super.key,
    required this.controller,
    required this.missingProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Missing Items",
      ),
      body: missingProducts.isNotEmpty
          ? SingleChildScrollView(
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
                    "Missing Items Name",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainTextColor,
                                    ),
                  ),
                const CommonHorizontalDivider(height: 1.0, color: AppColors.greyE5),
          
                // List of Items
                ListView.separated(
                  itemCount: missingProducts.length,
                  shrinkWrap: true,
                  primary: false,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                    child: CommonHorizontalDivider(height: 0.5, color: AppColors.greyE5),
                  ),
                  itemBuilder: (context, index) {
                    final item = missingProducts[index];
                    return _buildItemRow(item);
                  },
                ),

                SizedBox(height: 20)
              ],
            ),
          ),
        ),
      )
          : const EmptyStateWidget(message: 'No Missing Products'),
    );
  }

  Widget _buildItemRow(MissingFoodProducts item) {
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
          CustomBtn(
            height: 32,
            width: 60,
            onTap: () {  },
            borderColor: AppColors.primaryColor,
            textColor: AppColors.primaryColor,
            bgColor: AppColors.white,
            title: 'Create',
            radius: 6.0,
          ),
        ],
      ),
    );
  }

}