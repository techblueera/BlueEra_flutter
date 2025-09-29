import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/product_model.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../model/get_own_product_model.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';


class ProductScreen extends StatefulWidget {
  final InventoryController controller;
  const ProductScreen({super.key, required this.controller});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final InventoryController inventoryController = Get.find<InventoryController>();


  @override
  void initState() {
    inventoryController.loadProducts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        SizedBox(height: SizeConfig.size8),

        Obx(()=> Padding(
          padding: EdgeInsets.all(
              SizeConfig.size8
          ),
          child: HorizontalTabSelector(
            tabs: widget.controller.productTab,
            selectedIndex: widget.controller.selectedProductIndex.value,
            isFilterIconShow: true,
            onTabSelected: (index, value) {
              widget.controller.selectedProductIndex.value = index;
              widget.controller.callApi();
            },
            labelBuilder: (label) => label,
          ),
        )),

       Obx(()=> _buildOwnProductCard())

        // Products Grid

      ],
    );
  }

  Widget _buildOwnProductCard(){
    switch(widget.controller.selectedProductIndex.value){
      case 0:
        return _buildAllProductCard();
        case 1:
        return _buildLiveProductCard();
        case 2:
        return _buildDraftProductCard();

      default:
        return SizedBox();
    }
  }

  Widget _buildAllProductCard(){
    return (widget.controller.isLoading.value) ?
    const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryColor,
      ),
    ) :
    Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = 2;
            final crossSpacing = 6.0;
            final mainSpacing = 6.0;

            final itemWidth =
                (constraints.maxWidth - ((crossAxisCount - 1) * crossSpacing)) /
                    crossAxisCount;

            return MasonryGridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossSpacing,
              mainAxisSpacing: mainSpacing,
              itemCount: widget.controller.allProducts.length,
              itemBuilder: (context, index) {
                final product = widget.controller.allProducts[index];
                return ProductCard(
                  product,
                  widget.controller,
                  width: itemWidth,
                );
              },
            );
          },
        ),
      ),
    );

  }

  Widget _buildLiveProductCard(){
    return (widget.controller.isLoading.value) ?
    const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryColor,
      ),
    ) :
    Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Two columns
            final crossAxisCount = 2;
            final crossSpacing = 6.0;
            final mainSpacing = 6.0;

            final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * crossSpacing))
                / crossAxisCount;

            return MasonryGridView.count(
              itemCount: widget.controller.liveProducts.length,
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossSpacing,
              mainAxisSpacing: mainSpacing,
              itemBuilder: (context, index) {
                final product = widget.controller.liveProducts[index];
                return ProductCard(
                  product,
                  widget.controller,
                  width: itemWidth,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDraftProductCard(){
    return (widget.controller.isLoading.value) ?
    const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryColor,
      ),
    ) :
    Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Two columns
            final crossAxisCount = 2;
            final crossSpacing = 6.0;
            final mainSpacing = 6.0;

            final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * crossSpacing))
                / crossAxisCount;

            return MasonryGridView.count(
              itemCount: widget.controller.filteredProducts.length,
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossSpacing,
              mainAxisSpacing: mainSpacing,
              itemBuilder: (context, index) {
                final product = widget.controller.draftProducts[index];
                return ProductCard(
                  product,
                  widget.controller,
                  width: itemWidth,
                );
              },
            );
          },
        ),
      ),
    );
  }

}

Widget ProductCard(
    OwnProductData product,
    InventoryController controller, {
      required double width,
    }) {
  return GestureDetector(
    onTap: (){
     Get.toNamed(
       RouteHelper.getProductPreviewScreenRoute(),
       arguments: {
         ApiKeys.argProductData: product,
       },
     );
    },
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: width,
        color: AppColors.whiteFE,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            AspectRatio(
              aspectRatio: 1.1, // square-ish image (adjust if needed)
              child: Stack(
                children: [
                  CustomImageSlideshow(
                    isLoading: false,
                    width: double.infinity,
                    height: double.infinity,
                    imagePaths: product.product.details?.media ?? [],
                    borderRadius: BorderRadius.zero,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildIconBox(
                        Icon(Icons.more_vert, color: Colors.white, size: 16)
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildIconBox(
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: CustomText(
                            product.product.sellerClassification?.variants.length.toString(),
                            color: AppColors.white,
                            fontSize: SizeConfig.medium,
                        ),
                      ),
                    )
                  ),
                ],
              ),
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  CustomText(
                    product.product.details?.name,
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.small,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Price Row
                  if (product.product.sellerClassification?.variants.isNotEmpty ?? false) ...[
                    Row(
                      children: [
                        CustomText(
                          '₹${product.product.sellerClassification?.variants[0].sellingPrice}',
                          fontWeight: FontWeight.w700,
                          fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                        ),
                        const SizedBox(width: 8),
                        CustomText(
                          '${calculateDiscount(
                            product.product.sellerClassification?.variants[0].sellingPrice.toString() ?? "0",
                            product.product.sellerClassification?.variants[0].mrp.toString() ?? "0",
                          ).toStringAsFixed(2)}% Off',
                          fontSize: SizeConfig.small11,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w400,
                        ),
                        CustomText(
                          ' ₹${product.product.sellerClassification?.variants[0].mrp}',
                          fontSize: SizeConfig.small11,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Status
                  CustomText(
                    'Active Products',
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.small11,
                    color: AppColors.primaryColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildIconBox(Widget child) {
  return Container(
    height: 25,
    width: 25,
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.5),
      shape: BoxShape.circle,
      boxShadow: [AppShadows.textFieldShadow]
    ),
    alignment: Alignment.center,
    child: child,
  );
}
