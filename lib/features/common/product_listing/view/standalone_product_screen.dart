import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/product_card.dart';

class StandaloneProductScreen extends StatelessWidget {
  final String businessId;

  final bool isGrid;

  StandaloneProductScreen({
    Key? key,
    required this.businessId,

    required this.isGrid,
  }) : super(key: key);
  final controller = Get.find<ViewBusinessDetailsController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.products.isEmpty) {
        return const Center(child: CustomText('No products found'));
      }

      // Show either grid view or horizontal list based on selection
      return CommonCardWidget(
        // padding: zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText("Products",
                fontWeight: FontWeight.w600,
                fontSize: SizeConfig.medium15,
                color: AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size8),
            isGrid
                ? Expanded(child: _buildGridView(controller))
                : _buildHorizontalView(controller),
          ],
        ),
      );
    });
  }

  // Grid view (2x2)
  Widget _buildGridView(ViewBusinessDetailsController controller) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: controller.products.length,
      itemBuilder: (context, index) {
        return ProductCardBusiness(
          productData: controller.products[index],
          isGridView: true,
        );
      },
    );
  }

  // Horizontal list view
  Widget _buildHorizontalView(ViewBusinessDetailsController controller) {
    return SizedBox(
      height: 310,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        itemCount: controller.products.length,
        itemBuilder: (context, index) {
          return ProductCardBusiness(
            productData: controller.products[index],
            isGridView: false,
          );
        },
      ),
    );
  }
}
