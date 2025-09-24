import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/inventory_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/product_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';


class ProductListView extends StatelessWidget {
  final InventoryController controller;
  const ProductListView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        SizedBox(height: SizeConfig.size8),

        Padding(
          padding: EdgeInsets.all(
              SizeConfig.size8
          ),
          child: HorizontalTabSelector(
            tabs: controller.productTab,
            selectedIndex: controller.selectedProductIndex.value,
            isFilterIconShow: true,
            onTabSelected: (index, value) {
              controller.selectedProductIndex.value = index;
            },
            labelBuilder: (label) => label,
          ),
        ),

        // Products Grid
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Two columns
                final crossAxisCount = 2;
                final crossSpacing = 6.0;
                final mainSpacing = 6.0;

                final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * crossSpacing)) / crossAxisCount;

                final imageHeight = itemWidth * 0.75; // You can tweak ratio if needed
                final detailsHeight = imageHeight * 0.9; // Approximate details section height
                final itemHeight = imageHeight + detailsHeight;

                final childAspectRatio = itemWidth / itemHeight;

                return GridView.builder(
                  itemCount: controller.filteredProducts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: crossSpacing,
                    mainAxisSpacing: mainSpacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final product = controller.filteredProducts[index];
                    return ProductCard(
                      product,
                      controller,
                      width: itemWidth,
                      height: itemHeight,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}


Widget ProductCard(
    ProductModel product,
    InventoryController controller, {
      required double width,
      required double height,
    }) {
  final imageHeight = height * 0.55; // Image ~55% of card height

  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    clipBehavior: Clip.antiAlias, // Ensures image respects card border
    child: Container(
      width: width,
      height: height,
      color: AppColors.whiteFE,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          SizedBox(
            width: double.infinity,
            height: imageHeight,
            child: Stack(
              children: [
                CustomImageSlideshow(
                  isLoading: false,
                  width: double.infinity,
                  height: imageHeight,
                  imagePaths: product.multipleImageUrl!,
                  isLocal: true,
                  borderRadius: BorderRadius.zero,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Details
          Flexible(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  CustomText(
                    product.name,
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.small,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),

                  // Price Row
                  Row(
                    children: [
                      CustomText(
                        '₹${product.currentPrice}',
                        fontWeight: FontWeight.w700,
                        fontSize: SizeConfig.small,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(width: 8),
                      CustomText(
                        '${product.discountPercentage}% Off',
                         fontSize:  SizeConfig.small11,
                         color: Colors.green[600],
                        fontWeight: FontWeight.w400,
                      ),
                      CustomText(
                        ' ₹${product.originalPrice}',
                        fontSize:  SizeConfig.small11,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ],
                  ),
                  SizedBox(height: 6),

                  // Status
                  CustomText(
                    'Active Products',
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.small11,
                    color: AppColors.primaryColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),

                  // Colors Row
                  Row(
                    children: product.colors.take(4).map((color) {
                      return Container(
                        width: 12,
                        height: 12,
                        margin: EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.whiteE5, width: 0.5),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 6),

                  // Sizes scrollable
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Row(
                          children: product.sizes.map((size) {
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                size,
                                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                              ),
                            );
                          }).toList(),
                        ),
                        if (product.sizes.length > 4)
                          Text('+${product.sizes.length - 4}',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


