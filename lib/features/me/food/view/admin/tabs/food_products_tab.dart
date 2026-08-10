import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/food/controller/restaurant_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/admin/discount_food_products_screen.dart';
import 'package:BlueEra/features/me/food/view/admin/food_category_menu_screen.dart';
import 'package:BlueEra/features/me/food/view/admin/my_food_product_screen.dart';
import 'package:BlueEra/features/me/food/view/widget/show_food_product_variant_sheet.dart';
import 'package:BlueEra/widgets/reserved_text_lines.dart';
import 'package:BlueEra/widgets/stock_status_pill.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/widgets/RatingBadge.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:BlueEra/widgets/products_tab_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// **Products** tab of the restaurant merchant home: the "Add Food" masthead,
/// the popular-dishes rail and the menu-category rail.
///
/// Content-only — the host wraps this in the shared refreshable scroll view
/// (padded `left: 20`, nothing on the right), so the sections here own their
/// trailing inset and the rails deliberately bleed off the right edge. The
/// chrome comes from `widgets/products_tab_widgets.dart`, which the other
/// me-section merchant homes render too; only the data and the routing below
/// it are food's own.
class FoodProductsTab extends StatelessWidget {
  const FoodProductsTab({super.key});

  /// Cap on the discount rail — the "View All" pill leads to the rest.
  static const int _discountPreviewLimit = 20;

  /// Height of the popular-dishes rail — sized for [_popularDishCard] at
  /// [_dishCardWidth].
  static const double _popularDishRailHeight = 240;
  static const double _dishCardWidth = 170;

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => RestaurantController());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          ctaLabel: AppStrings.addFood.tr,
          onAdd: () => _onAddFood(controller),
          gradient: ProductsBannerGradient.food,
        ),
        SizedBox(height: SizeConfig.size20),
        _popularDishesSection(controller),
        SizedBox(height: SizeConfig.size20),
        _menuSection(controller),
        SizedBox(height: SizeConfig.size16),
      ],
    );
  }

  /// Opens the add-dish flow and, if the merchant published something, pulls
  /// the menu again so the new dish is on screen when they come back.
  Future<void> _onAddFood(RestaurantController controller) async {
    await Get.to(() => FoodCategoryMenuScreen());
    _refreshIfDirty(controller);
  }

  Future<void> _openCategory(
      RestaurantController controller, GroceryNestedCategoryModel item) async {
    if ((item.name ?? '').isEmpty) {
      commonSnackBar(message: AppStrings.invalidCategory.tr);
      return;
    }
    await Get.to(() => MyFoodProductScreen(foodMenu: item));
    _refreshIfDirty(controller);
  }

  /// Force-refreshes both rails after the merchant published something.
  ///
  /// Deliberately the UNGUARDED fetches: the host's tab dispatcher uses
  /// `fetchHomeAndDiscountIfNeeded`, so without an explicit reload here a
  /// newly published dish would sit invisible until the freshness TTL lapsed.
  /// The discount call matters as much as the menu one — a dish published with
  /// an offer belongs in the Offer Dish rail immediately.
  void _refreshIfDirty(RestaurantController controller) {
    if (controller.foodDataNeedsRefresh) {
      controller.foodDataNeedsRefresh = false;
      controller.fetchHomeData(businessId: businessId);
      controller.fetchDiscountFoodProducts(businessId: businessId);
    }
  }

  // POPULAR DISHES (discount foods, horizontal)
  //
  // No white shell — the cards are the surface, sitting directly on the page
  // background so the rail reads as one shelf.
  Widget _popularDishesSection(RestaurantController controller) {
    return Obx(() {
      final isInitialLoading = controller.isDiscountProductsLoading.value &&
          controller.discountFoodItems.isEmpty;
      final hasItems = controller.discountFoodItems.isNotEmpty;
      if (!isInitialLoading && !hasItems) {
        return const SizedBox.shrink();
      }

      final items = controller.discountFoodItems.length > _discountPreviewLimit
          ? controller.discountFoodItems.take(_discountPreviewLimit).toList()
          : controller.discountFoodItems.toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductsSectionHeader(
            title: AppStrings.foodOfferDishDiscount.tr,
            subtitle: AppStrings.customersFavoritesThisMonth.tr,
            action: ProductsViewAllPill(
              onTap: () => Get.to(
                  () => DiscountFoodProductsScreen(businessId: businessId)),
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          if (isInitialLoading)
            const ProductsRailLoader(
              height: _popularDishRailHeight,
              cardWidth: _dishCardWidth,
            )
          else
            ProductsRail(
              // Sized to the tallest card: the stock pill made the dish card
              // taller than the 240 the loader reserves, and a rail's height
              // is TIGHT — the cards would have been clipped. Capped preview
              // list, so building them all up front is fine.
              sizeToContent: true,
              height: _popularDishRailHeight,
              itemCount: items.length,
              spacing: SizeConfig.size12,
              itemBuilder: (context, i) => _popularDishCard(context, items[i]),
            ),
        ],
      );
    });
  }

  Widget _popularDishCard(BuildContext context, CategoryFoodProductData item) {
    final hasVariants = item.variants != null && item.variants!.isNotEmpty;
    final variantCount = item.variants?.length ?? 0;
    final isMultiVariant = variantCount > 1;
    final sellingPrice = hasVariants ? item.variants![0].baseSellingPrice : null;
    final mrp = hasVariants ? item.variants![0].mrp : null;
    final discountPercent =
        (mrp != null && sellingPrice != null && mrp > sellingPrice)
            ? (((mrp - sellingPrice) / mrp) * 100).round()
            : 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showFoodProductVariantSheet(context, product: item),
      child: Container(
        width: _dishCardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: item.images?.firstOrNull ?? '',
                    height: 130,
                    width: _dishCardWidth,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) => Container(
                      height: 130,
                      width: _dishCardWidth,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
                  ),
                ),
                if (discountPercent > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFFFD7845), Color(0xFFFA5568)],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: CustomText(
                          AppStrings.discountOffFmt
                              .trParams({'percent': '$discountPercent'}),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: FoodTypeIndicator(
                    isVegetarian:
                        item.dietaryType?.toLowerCase() == AppConstants.veg,
                    size: 8,
                  ),
                ),
                // Stock state on the photo, where the eye lands first when
                // scanning the rail. Bottom-LEFT: the top corners already carry
                // the discount ribbon and the veg/non-veg mark.
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: StockStatusPill(
                    inStock: !isFoodProductOutOfStock(item),
                    onImage: true,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Always two lines' worth of space, so a short dish name
                  // leaves blank at the bottom instead of pulling the rating
                  // and price up and misaligning neighbouring cards.
                  ReservedTextLines(
                    fontSize: 13,
                    child: CustomText(
                      item.name ?? '',
                      fontWeight: FontWeight.w600,
                      maxLines: 2,
                      height: 1.3,
                      fontSize: 13,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RatingBadge(rating: '4.5'),
                      const SizedBox(width: 4),
                      Flexible(
                        child: CustomText(
                          AppStrings.reviewsKMock.tr,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          color: AppColors.secondaryTextColor,
                          fontSize: 11,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CustomText(
                        '${AppConstants.rupeeSymbol}${sellingPrice ?? 0}',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      if (mrp != null &&
                          sellingPrice != null &&
                          mrp >= sellingPrice) ...[
                        const SizedBox(width: 6),
                        CustomText(
                          '${AppConstants.rupeeSymbol}$mrp',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.secondaryTextColor,
                        ),
                      ],
                    ],
                  ),
                  if (variantCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomText(
                          isMultiVariant
                              ? AppStrings.variantsMoreFmt
                                  .trParams({'count': '${variantCount - 1}'})
                              : AppStrings.variantSingularFmt
                                  .trParams({'count': '$variantCount'}),
                          fontSize: 10,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MENU CATEGORIES â€” a rail rather than a grid: categories are a lane you
  // scan across, and the block grid pushed the rest of the tab below the fold.
  Widget _menuSection(RestaurantController controller) {
    return Obx(() {
      final List<GroceryNestedCategoryModel> menus =
          List<GroceryNestedCategoryModel>.from(
              controller.foodMenuNestedCategory);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title only — no helper line, matching the reference.
          ProductsSectionHeader(
            title: AppStrings.manageViaCategories.tr,
          ),
          SizedBox(height: SizeConfig.size12),
          if (menus.isEmpty)
            Padding(
              padding: EdgeInsets.only(
                right: SizeConfig.size20,
                top: SizeConfig.size10,
                bottom: SizeConfig.size10,
              ),
              child: EmptyStateWidget(
                message: AppStrings.foodNoProductCreate.tr,
              ),
            )
          else
            ProductsRail(
              height: ProductCategoryTile.railHeight,
              itemCount: menus.length,
              spacing: SizeConfig.size8,
              itemBuilder: (_, i) => ProductCategoryTile(
                image: menus[i].image,
                name: menus[i].name,
                onTap: () => _openCategory(controller, menus[i]),
              ),
            ),
        ],
      );
    });
  }
}
