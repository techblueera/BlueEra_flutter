import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/product_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product_preview_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/own_product_card.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/get_product_model.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
 
class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late final InventoryController inventoryController;

  @override
  void initState() {
    if(Get.isRegistered<InventoryController>()){
      inventoryController = Get.find<InventoryController>();
    } else {
      inventoryController = Get.put(InventoryController());
    }
    inventoryController.fetchProducts();
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
            tabs: inventoryController.productTab,
            selectedIndex: inventoryController.selectedProductIndex.value,
            isFilterIconShow: true,
            onTabSelected: (index, value) {
              inventoryController.selectedProductIndex.value = index;
              inventoryController.callApi();
            },
            labelBuilder: (label) => label,
          ),
        )),

        Obx(()=> _buildOwnProductCard())

      ],
    );
  }

  Widget _buildOwnProductCard(){
    switch(inventoryController.selectedProductIndex.value){
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
    return (inventoryController.isLoading.value) ?
    const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryColor,
      ),
    ) :
    Expanded(
      child: inventoryController.allProducts.isNotEmpty ? Padding(
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
              itemCount: inventoryController.allProducts.length,
              // reverse: true,
              padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 40),
              itemBuilder: (context, index) {
                final product = inventoryController.allProducts[index];
                return OwnProductCard(
                  deleteProductApi: (){
                    inventoryController.deleteProduct();
                  },
                  width: itemWidth,
                  product: product,
                );
              },
            );
          },
        ),
      ) : Center(child: EmptyStateWidget(message: 'Product is empty\nCreate your own product')),
    );

  }

  Widget _buildLiveProductCard(){
    return (inventoryController.isLoading.value) ?
    const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryColor,
      ),
    ) :
    Expanded(
      child: inventoryController.liveProducts.isNotEmpty ? Padding(
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
              itemCount: inventoryController.liveProducts.length,
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossSpacing,
              mainAxisSpacing: mainSpacing,
              padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 40),
              itemBuilder: (context, index) {
                final product = inventoryController.liveProducts[index];
                return OwnProductCard(
                  deleteProductApi: (){
                      inventoryController.deleteProduct();
                  },
                  product: product,
                  width: itemWidth
                );
              },
            );
          },
        ),
      )
            : Center(child: EmptyStateWidget(message: 'Product is empty\nCreate your own product')),
    );
  }

  Widget _buildDraftProductCard(){
    return (inventoryController.isLoading.value) ?
    const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryColor,
      ),
    ) :
    Expanded(
      child: inventoryController.draftProducts.isNotEmpty ?
      Padding(
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
              itemCount: inventoryController.filteredProducts.length,
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossSpacing,
              mainAxisSpacing: mainSpacing,
              padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 40),
              itemBuilder: (context, index) {
                final product = inventoryController.draftProducts[index];
                return OwnProductCard(
                  deleteProductApi: (){
                    inventoryController.deleteProduct();
                  },
                  product: product,
                  width: itemWidth
                );
              },
            );
          },
        ),
      )
          : Center(child: EmptyStateWidget(message: 'Product is empty\nCreate your own product'))
    );
  }

  ProductPreviewArgs mapProductDataToPreviewArgs(GetProductData productData) {
    final product = productData.product;
    final details = product.details;

    List<ProductListing> listedProducts = [];
    final variants = product.sellerClassification?.variants ?? [];
    if (variants.isNotEmpty) {
      listedProducts = variants.map((variant) {
        final variantName = '${details?.name ?? ''} ' +
            variant.attributes.entries.map((entry) {
              final key = entry.key.toLowerCase();
              final value = entry.value;

              if (key == 'color' && value is Map<String, dynamic>) {
                return value['color_name'] ?? '';
              } else if (value != null) {
                return value.toString();
              } else {
                return '';
              }
            }).where((attr) => attr.isNotEmpty).join(', ');

        return ProductListing(id: variant.id,
          image: variant.mediaRelatedToVariant,
          name: variantName,
          selectedVariants: variant.attributes,
          price: variant.sellingPrice.toString(),
          mrp: variant.mrp.toString(),
          discount: variant.mrp > 0
              ? (((variant.mrp - variant.sellingPrice) / variant.mrp) * 100)
              .toStringAsFixed(2)
              : null,
        );
      }).toList();
    }

    return ProductPreviewArgs(
      productId: details?.id ?? '',
      media: details?.media ?? [],
      name: details?.name ?? '',
      description: details?.description ?? '',
      tags: details?.tags ?? [],
      features: details?.addProductFeatures.map((f) => f.title).toList() ?? [],
      details: details?.addMoreDetails
          .map((d) => DetailPair(d.title, d.details))
          .toList(),
      warranty: details?.productWarranty ?? '',
      // linkOrReferralUrl: details?.linkOrReferralUrl ?? '',
      // expiry: details?.expiry ?? '',
      // userGuide: details?.userGuide ?? [],
      listedProducts: listedProducts,
    );
  }

}


