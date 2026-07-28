import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
// The medical business-products endpoint ships grocery's exact response shape
// (docs/backend/MEDICAL_TOP_SELLING_BACKEND_GUIDE.md), so the Top Selling rail
// reuses grocery's grouping helper, card and variants sheet.
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_top_selling_product_card.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_variants_sheet.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical/model/my_medical_super_category_model.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:BlueEra/widgets/products_tab_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// **Products** tab of the medical merchant home: the "Add Product" masthead,
/// the Top Selling rail and the category rail.
///
/// Same shape as [GroceryProductsTab] — same masthead, section headers, rails
/// and category tiles from `widgets/products_tab_widgets.dart` — so the two
/// merchant homes read as one product. Only the data sources and routing below
/// the chrome are medical's own.
///
/// Content-only: the host wraps this in the shared scroll view.
class MedicalProductsTab extends StatelessWidget {
  /// Pharmacy whose catalog is being managed.
  final String businessId;

  const MedicalProductsTab({super.key, required this.businessId});

  /// Height of the Top Selling rail — tall enough for
  /// [GroceryTopSellingProductCard] at [_topSellingCardWidth]. Same numbers as
  /// grocery, which renders the same card.
  static const double _topSellingRailHeight = 232;
  static const double _topSellingCardWidth = 152;

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => MedicalController());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size10),
        // Contribution / Bank / Refer deck. No catalog card here: this tab IS
        // the add surface and carries its own add masthead, so a card pointing
        // at the screen you are already on would be noise.
        Padding(
          padding: EdgeInsets.only(right: productsTabTrailingInset),
          child: OrderActionsCarousel(),
        ),
        SizedBox(height: SizeConfig.size16),
        ProductsTabBanner(
          title: AppStrings.productsTab.tr,
          subtitle: AppStrings.manageYourStoreProducts.tr,
          ctaLabel: AppStrings.addProduct.tr,
          onAdd: _onAddProduct,
          gradient: ProductsBannerGradient.medical,
        ),
        SizedBox(height: SizeConfig.size20),
        _topSellingSection(controller),
        SizedBox(height: SizeConfig.size20),
        _categorySection(controller),
        SizedBox(height: SizeConfig.size16),
      ],
    );
  }

  void _onAddProduct() =>
      Get.toNamed(RouteHelper.getAddMedicalSnapSearchScreenRoute());

  /// Top Selling rail — store-wide products from
  /// `medical-service/inventory/business-products`.
  ///
  /// Hides entirely when the list is empty — no empty state, matching grocery
  /// and what the backend guide's §3 tells the server to expect.
  ///
  /// No "View All" action: medical has no all-top-selling screen yet (grocery's
  /// pill opens `AllTopSellingGroceryProductsScreen`), so the rail caps at the
  /// controller's preview limit.
  Widget _topSellingSection(MedicalController controller) {
    return Obx(() {
      final isLoading =
          controller.fetchMedicalBusinessProductsResponse.value.status ==
              Status.INITIAL;
      final products = controller.medicalBusinessProductsList;
      if (!isLoading && products.isEmpty) return const SizedBox.shrink();

      // One row per variant comes back, so the same product repeats — group by
      // product id: one card each, tapping opens its variants sheet.
      final grouped = groupBusinessProductsByProduct(products.toList());
      final previewGroups = grouped.length >
              MedicalController.medicalBusinessProductsPreviewLimit
          ? grouped
              .take(MedicalController.medicalBusinessProductsPreviewLimit)
              .toList()
          : grouped;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductsSectionHeader(
            title: AppStrings.topSelling.tr,
            subtitle: AppStrings.customersFavoritesThisMonth.tr,
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
  //
  // Shows exactly what the with-inventory endpoint returns — no level
  // filtering, same as grocery. (The response is already the merchant's
  // inventory categories; here they come back as level 0, and filtering those
  // out left the rail empty.)
  Widget _categorySection(MedicalController controller) {
    return Obx(() {
      final isLoading = controller.myMedicalCategoryLoading.value;
      final categories = List<MyMedicalSuperCategoryModel>.from(
          controller.myMedicalCategoryList);

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
          else if (categories.isEmpty)
            // Categories keep their empty state (grocery does the same) —
            // unlike Top Selling, an empty catalog is the merchant's cue to
            // add stock, so hiding the section would hide the prompt with it.
            Padding(
              // Symmetric horizontal padding: EmptyStateWidget is a Center, so
              // the old right-only inset pushed it visibly left of true centre.
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size20,
                vertical: SizeConfig.size10,
              ),
              child: SizedBox(
                width: double.infinity,
                child: EmptyStateWidget(
                  message: AppStrings.medicalHaveNotPostedProducts.tr,
                  actionText: AppStrings.medicalAddProductsNow.tr,
                  actionCallback: _onAddProduct,
                ),
              ),
            )
          else
            ProductsRail(
              height: ProductCategoryTile.railHeight,
              itemCount: categories.length,
              spacing: SizeConfig.size8,
              itemBuilder: (_, i) => _categoryTile(categories[i]),
            ),
        ],
      );
    });
  }

  /// Tapping goes straight to the variant screen for this category — no
  /// products list in between. That screen fetches the category's products and
  /// flattens every variant into one grid.
  Widget _categoryTile(MyMedicalSuperCategoryModel item) {
    // The API's own `image` is the only source now — the bundled per-key art
    // this used to prefer is gone, so the rail can't drift from whatever the
    // backend serves. ProductCategoryTile renders the placeholder when empty.
    return ProductCategoryTile(
      image: item.image,
      name: item.name,
      onTap: () => Get.toNamed(
        RouteHelper.getMyMedicalVariantScreenRoute(),
        arguments: {
          ApiKeys.argCategoryId: item.sId,
          ApiKeys.argCategoryName: item.name,
          ApiKeys.argIsShowInGrid: true,
        },
      ),
    );
  }
}
