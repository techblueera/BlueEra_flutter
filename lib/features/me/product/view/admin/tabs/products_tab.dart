import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/model/product_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/product/view/admin/admin_all_top_selling_products_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/admin_product_card.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:BlueEra/widgets/products_tab_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// **Products** tab of the product-store merchant home: the "Add Product"
/// masthead, the top-selling rail and the category rail. This dedicated lane
/// is what makes catalog management the primary action of the screen — the
/// Overview tab carries none of it.
///
/// Content-only — the host wraps this in the shared refreshable scroll view
/// (padded `left: 20`, nothing on the right), so the sections here own their
/// trailing inset and the rails deliberately bleed off the right edge. The
/// chrome comes from `widgets/products_tab_widgets.dart`, which the other
/// me-section merchant homes render too.
class ProductsTab extends StatelessWidget {
  /// The add-product flow. Owned by the host because publishing also jumps the
  /// TabBarView back to this tab.
  final VoidCallback onAddProduct;

  const ProductsTab({super.key, required this.onAddProduct});

  /// Width [AdminProductCard.gridCardHeight] is measured against.
  static const double _topSellingCardWidth = 168;

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => InventoryController());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Same deck the Order tab carries. Its catalog card runs the host's
        // real add-product flow here — the "switch to Products" callback the
        // Order tab passes would be a no-op on this tab.
        Padding(
          padding: EdgeInsets.only(right: productsTabTrailingInset),
          child: OrderActionsCarousel(
            onAddCatalog: onAddProduct,
            catalogIcon: Icons.inventory_2_rounded,
            catalogTitle: AppStrings.addProduct.tr,
            catalogSubtitle: AppStrings.listItemsCustomersCanOrder.tr,
          ),
        ),
        SizedBox(height: SizeConfig.size16),
        ProductsTabBanner(
          title: AppStrings.productsTab.tr,
          subtitle: AppStrings.manageYourStoreProducts.tr,
          ctaLabel: AppStrings.addProduct.tr,
          onAdd: onAddProduct,
          gradient: ProductsBannerGradient.product,
        ),
        SizedBox(height: SizeConfig.size20),
        _topSellingSection(controller),
        SizedBox(height: SizeConfig.size20),
        _categorySection(controller),
        SizedBox(height: SizeConfig.size16),
      ],
    );
  }

  // TOP SELLING â€” the merchant's own catalog preview. No white shell: the
  // cards are the surface, sitting directly on the page background so the rail
  // reads as one shelf. Collapses entirely when nothing is published yet.
  Widget _topSellingSection(InventoryController controller) {
    return Obx(() {
      final isLoading =
          controller.ownDraftAndPublicProductResponse.value.status ==
              Status.INITIAL;
      if (!isLoading && controller.allProducts.isEmpty) {
        return const SizedBox.shrink();
      }
      final previewCount = controller.allProducts.length >
              InventoryController.ownProductsPreviewLimit
          ? InventoryController.ownProductsPreviewLimit
          : controller.allProducts.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductsSectionHeader(
            title: AppStrings.topSelling.tr,
            subtitle: AppStrings.customersFavoritesThisMonth.tr,
            action: ProductsViewAllPill(
              onTap: () =>
                  Get.to(() => const AdminAllTopSellingProductsScreen()),
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          if (isLoading)
            ProductsRailLoader(
              height: AdminProductCard.gridCardHeight,
              cardWidth: _topSellingCardWidth,
            )
          else
            ProductsRail(
              height: AdminProductCard.gridCardHeight,
              itemCount: previewCount,
              spacing: SizeConfig.size12,
              itemBuilder: (_, index) => SizedBox(
                width: _topSellingCardWidth,
                child: AdminProductCard(
                  product: controller.allProducts[index],
                  deleteProductApi: () {},
                  width: _topSellingCardWidth,
                  isGridShow: true,
                ),
              ),
            ),
        ],
      );
    });
  }

  // CATEGORIES â€” a rail rather than a grid: categories are a lane you scan
  // across, and the block grid pushed the rest of the tab below the fold.
  Widget _categorySection(InventoryController controller) {
    return Obx(() {
      final isLoading = controller.fetchProductCategoryResponse.value.status ==
          Status.INITIAL;
      final List<ProductCategoryWithInventoryModel> categoryList =
          controller.productNestedCategoryList;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title only — no helper line, matching the reference.
          ProductsSectionHeader(
            title: AppStrings.manageViaCategories.tr,
          ),
          SizedBox(height: SizeConfig.size12),
          if (isLoading)
            const ProductCategoryRailSkeleton()
          else if (categoryList.isEmpty)
            Padding(
              padding: EdgeInsets.only(
                right: SizeConfig.size20,
                top: SizeConfig.size10,
                bottom: SizeConfig.size10,
              ),
              child: EmptyStateWidget(
                message: AppStrings.noProductYetCreateOne.tr,
              ),
            )
          else
            ProductsRail(
              height: ProductCategoryTile.railHeight,
              itemCount: categoryList.length,
              spacing: SizeConfig.size8,
              itemBuilder: (_, i) =>
                  _categoryTile(categoryList[i], categoryList),
            ),
        ],
      );
    });
  }

  Widget _categoryTile(
    ProductCategoryWithInventoryModel item,
    List<ProductCategoryWithInventoryModel> categoryList,
  ) {
    return ProductCategoryTile(
      image: (item.image ?? '').toString(),
      name: item.name,
      onTap: () => Get.toNamed(
        RouteHelper.getProductNestedCategoryWithInventoryScreenRoute(),
        arguments: {
          ApiKeys.userId: businessId,
          ApiKeys.argProductCategoryWithInventory: categoryList.toList(),
          ApiKeys.argProductCatKey: item.key ?? '',
          ApiKeys.argProductCatName: item.name ?? '',
        },
      ),
    );
  }
}
