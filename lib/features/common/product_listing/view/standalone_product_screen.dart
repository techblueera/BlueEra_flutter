import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../widgets/product_card_business.dart';

class StandaloneProductScreen extends StatelessWidget {
  final String businessId;
  final bool isGrid;
  final BusinessProfileDetails? businessData;

  StandaloneProductScreen({
    Key? key,
    required this.businessId,
     this.businessData,

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

        child: SizedBox(
          width: Get.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                  "Products",
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.medium15,
                  color: AppColors.secondaryTextColor),
              SizedBox(height: SizeConfig.size8),
              isGrid
                  ? Expanded(child: _buildGridView(controller))
                  : _buildHorizontalView(controller),
            ],
          ),
        ),
      );
    });
  }

  // Grid view (2x2)
  Widget _buildGridView(ViewBusinessDetailsController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        const crossSpacing = 10.0;
        const mainSpacing = 10.0;

        final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * crossSpacing)) / crossAxisCount;

        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossSpacing,
          mainAxisSpacing: mainSpacing,
          itemCount: controller.products.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // let parent scroll handle it
          padding: const EdgeInsets.only(bottom: 20),
          itemBuilder: (context, index) {
            final product = controller.products[index];

            return ProductCardBusiness(
              productData: product,
              businessData: businessData,
              width: itemWidth,
              isShowKM: true
            );
          },
        );
      },
    );
  }

  // Horizontal list view
  Widget _buildHorizontalView(ViewBusinessDetailsController controller) {
    return SizedBox(
      height: 322,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        itemCount: controller.products.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: SizeConfig.size10),
            child: ProductCardBusiness(
              productData: controller.products[index],
              businessData: businessData,
              width: SizeConfig.screenWidth * 0.4,
                isShowKM: true
            ),
          );
        },
      ),
    );
  }
}
