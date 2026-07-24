import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_inventory_controller.dart';
import 'package:BlueEra/features/me/automotive_products/model/automotive_product_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_admin_all_top_selling_products_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/widget/automotive_admin_product_card.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/products_tab_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// **Products** tab of the auto-parts merchant home: the "Add Product"
/// masthead, the top-selling rail and the category rail. This dedicated lane
/// is what makes catalog management the primary action of the screen — the
/// Overview tab carries none of it.
///
/// Content-only — the host wraps this in the shared refreshable scroll view
/// (padded `left: 20`, nothing on the right), so the sections here own their
/// trailing inset and the rails deliberately bleed off the right edge. The
/// chrome comes from `widgets/products_tab_widgets.dart`, which the other
/// me-section merchant homes render too.
class AutomotiveProductsTab extends StatelessWidget {
  /// The add-product flow. Owned by the host because publishing also jumps the
  /// TabBarView back to this tab.
  final VoidCallback onAddProduct;

  const AutomotiveProductsTab({super.key, required this.onAddProduct});

  /// Width [AutomotiveAdminProductCard.gridCardHeight] is measured against.
  static const double _topSellingCardWidth = 168;

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => AutomotiveInventoryController());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductsTabBanner(
          title: AppStrings.productsTab.tr,
          subtitle: AppStrings.manageYourStoreProducts.tr,
          ctaLabel: AppStrings.addProduct.tr,
          onAdd: onAddProduct,
          gradient: ProductsBannerGradient.automotive,
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
  Widget _topSellingSection(AutomotiveInventoryController controller) {
    return Obx(() {
      final isLoading =
          controller.ownDraftAndPublicProductResponse.value.status ==
              Status.INITIAL;
      if (!isLoading && controller.allProducts.isEmpty) {
        return const SizedBox.shrink();
      }
      final previewCount = controller.allProducts.length >
              AutomotiveInventoryController.ownProductsPreviewLimit
          ? AutomotiveInventoryController.ownProductsPreviewLimit
          : controller.allProducts.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductsSectionHeader(
            title: AppStrings.topSelling.tr,
            subtitle: AppStrings.customersFavoritesThisMonth.tr,
            action: ProductsViewAllPill(
              onTap: () => Get.to(
                  () => const AutomotiveAdminAllTopSellingProductsScreen()),
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          if (isLoading)
            ProductsRailLoader(
              height: AutomotiveAdminProductCard.gridCardHeight,
              cardWidth: _topSellingCardWidth,
            )
          else
            ProductsRail(
              height: AutomotiveAdminProductCard.gridCardHeight,
              itemCount: previewCount,
              spacing: SizeConfig.size12,
              itemBuilder: (_, index) => SizedBox(
                width: _topSellingCardWidth,
                child: AutomotiveAdminProductCard(
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
  Widget _categorySection(AutomotiveInventoryController controller) {
    return Obx(() {
      final isLoading = controller.fetchProductCategoryResponse.value.status ==
          Status.INITIAL;
      final List<AutomotiveProductCategoryWithInventoryModel> categoryList =
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
    AutomotiveProductCategoryWithInventoryModel item,
    List<AutomotiveProductCategoryWithInventoryModel> categoryList,
  ) {
    return ProductCategoryTile(
      image: (item.image ?? '').toString(),
      name: item.name,
      onTap: () => Get.toNamed(
        RouteHelper.getAutomotiveProductNestedCategoryWithInventoryScreenRoute(),
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
