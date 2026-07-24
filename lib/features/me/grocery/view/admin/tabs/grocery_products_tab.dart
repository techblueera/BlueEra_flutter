import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/view/all_top_selling_grocery_products_screen.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_top_selling_product_card.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_variants_sheet.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/products_tab_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// **Products** tab of the grocery merchant home: the "Add Grocery" masthead,
/// the top-selling rail and the category rail.
///
/// Content-only — the host wraps this in the shared refreshable scroll view
/// (padded `left: 20`, nothing on the right), so the sections here own their
/// trailing inset and the rails deliberately bleed off the right edge. The
/// chrome comes from `widgets/products_tab_widgets.dart`, which the other
/// me-section merchant homes render too.
class GroceryProductsTab extends StatelessWidget {
  /// Store whose catalog is being managed — also the argument the category
  /// and view-all screens are opened with.
  final String businessId;

  const GroceryProductsTab({super.key, required this.businessId});

  /// Height of the top-selling rail — tall enough for
  /// [GroceryTopSellingProductCard] at [_topSellingCardWidth].
  static const double _topSellingRailHeight = 232;
  static const double _topSellingCardWidth = 152;

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => GroceryController());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductsTabBanner(
          title: AppStrings.productsTab.tr,
          subtitle: AppStrings.manageYourStoreProducts.tr,
          ctaLabel: AppStrings.addGrocery.tr,
          onAdd: () => _onAddMoreProducts(controller),
          gradient: ProductsBannerGradient.grocery,
        ),
        SizedBox(height: SizeConfig.size20),
        _topSellingSection(controller),
        SizedBox(height: SizeConfig.size20),
        _categorySection(controller),
        SizedBox(height: SizeConfig.size16),
      ],
    );
  }

  /// Bulk-upload entry point. On the way back, reload the tab if the merchant
  /// actually published something.
  Future<void> _onAddMoreProducts(GroceryController controller) async {
    await Get.toNamed(
      RouteHelper.getGrocerySuperCategoryScreenRoute(),
      arguments: {ApiKeys.argBulkUpload: true},
    );
    if (controller.groceryDataNeedsRefresh) {
      controller.groceryDataNeedsRefresh = false;
      controller.fetchAllGroceryData(businessId, otherStore: false);
    }
  }

  // TOP-SELLING PRODUCTS â€” editorial-style horizontal scroller. No white
  // shell: the cards are the surface, sitting directly on the page background
  // so the rail reads as one shelf. Collapses when the store has nothing.
  Widget _topSellingSection(GroceryController controller) {
    return Obx(() {
      final isLoading =
          controller.fetchGroceryBusinessProductsResponse.value.status ==
              Status.INITIAL;
      final products = controller.groceryBusinessProductsList;
      if (!isLoading && products.isEmpty) return const SizedBox.shrink();

      // The business-products list can carry one row per variant (so the same
      // product repeats). Group by product → one card per product; tapping a
      // card opens a sheet listing that product's variants.
      final grouped = groupBusinessProductsByProduct(products.toList());
      final previewGroups =
          grouped.length > GroceryController.businessProductsPreviewLimit
              ? grouped
                  .take(GroceryController.businessProductsPreviewLimit)
                  .toList()
              : grouped;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductsSectionHeader(
            title: AppStrings.highDiscountProducts.tr,
            subtitle: AppStrings.customersFavoritesThisMonth.tr,
            action: ProductsViewAllPill(
              label: AppStrings.groceryViewViewAll.tr,
              onTap: () => Get.to(() => AllTopSellingGroceryProductsScreen(
                    userId: businessId,
                    otherStore: false,
                  )),
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          if (isLoading)
            const ProductsRailLoader(
              height: _topSellingRailHeight,
              cardWidth: _topSellingCardWidth,
            )
          else
            ProductsRail(
              height: _topSellingRailHeight,
              itemCount: previewGroups.length,
              spacing: 12,
              itemBuilder: (context, index) =>
                  _topSellingCard(context, previewGroups[index]),
            ),
        ],
      );
    });
  }

  Widget _topSellingCard(
      BuildContext context, GroceryProductVariantGroup group) {
    // Align stops the horizontal ListView's tight cross-axis (height)
    // constraint from stretching the card — it sizes to its content instead of
    // filling the rail height.
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: _topSellingCardWidth,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showGroceryVariantsSheet(
            context: context,
            productName: group.product.product?.name ?? '',
            productImageUrl: group.product.productImageUrlOnly,
            variants: group.variants,
          ),
          child: GroceryTopSellingProductCard(
            product: group.product,
            variants: group.variants,
          ),
        ),
      ),
    );
  }

  // CATEGORIES WITH INVENTORY â€” a rail rather than a grid: categories are a
  // lane you scan across, and the block grid pushed the rest of the tab far
  // below the fold.
  Widget _categorySection(GroceryController controller) {
    return Obx(() {
      final categories = List<GroceryCategoryWithInventoryModel>.from(
          controller.groceryCategoryList);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title only — no helper line, matching the reference.
          ProductsSectionHeader(
            title: AppStrings.manageViaCategories.tr,
          ),
          SizedBox(height: SizeConfig.size12),
          if (categories.isEmpty)
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
              itemCount: categories.length,
              spacing: SizeConfig.size8,
              itemBuilder: (_, i) => _categoryTile(categories[i], categories),
            ),
        ],
      );
    });
  }

  Widget _categoryTile(
    GroceryCategoryWithInventoryModel item,
    List<GroceryCategoryWithInventoryModel> all,
  ) {
    return ProductCategoryTile(
      image: item.image,
      name: item.name,
      onTap: () => Get.toNamed(
        RouteHelper.getGroceryNestedCategoryWithInventoryScreenRoute(),
        arguments: {
          ApiKeys.userId: businessId,
          ApiKeys.argGroceryCategoryWithInventory: all,
          ApiKeys.argArrGroceryCatKey: item.key,
          ApiKeys.argArrGroceryCatName: item.name,
        },
      ),
    );
  }
}
