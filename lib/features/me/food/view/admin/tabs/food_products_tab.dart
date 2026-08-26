import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/food/controller/restaurant_controller.dart';
import 'package:BlueEra/features/me/food/view/admin/discount_food_products_screen.dart';
import 'package:BlueEra/features/me/food/view/admin/food_category_menu_screen.dart';
import 'package:BlueEra/features/me/food/view/admin/my_food_product_screen.dart';
import 'package:BlueEra/features/me/food/view/admin/widget/admin_food_card.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:BlueEra/widgets/products_tab_widgets.dart';
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

  /// Height the popular-dishes rail RESERVES while loading. The rail itself
  /// sizes to its tallest [AdminFoodCard]; this only has to be close enough
  /// that the skeleton does not jump when the real cards land.
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
          padding: EdgeInsets.only(
              top: 8,
              right: productsTabTrailingInset),
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
        _catalogue(controller),
        SizedBox(height: SizeConfig.size16),
      ],
    );
  }

  /// The two catalogue sections — or, when the restaurant has published
  /// nothing at all, ONE empty state in place of both.
  ///
  /// A brand-new restaurant used to land on a "Manage via categories" heading
  /// over an inline empty box: a section header for a section that does not
  /// exist yet, which reads as something failing to load rather than as a shop
  /// with no menu. With no dishes and no categories there is nothing to manage,
  /// so the tab says exactly that and offers the one action that changes it.
  ///
  /// Only when the menu fetch has RESOLVED. While it is still in flight the
  /// lists are empty for the same reason a slow network is, and the sections
  /// below render their own loaders instead.
  Widget _catalogue(RestaurantController controller) {
    return Obx(() {
      final status = controller.foodHomeDataResponse.value.status;
      final menuResolved = status == Status.COMPLETE || status == Status.ERROR;
      final discountLoading = controller.isDiscountProductsLoading.value;
      final nothingPublished = controller.discountFoodItems.isEmpty &&
          controller.foodMenuNestedCategory.isEmpty &&
          controller.restaurantSpecials.isEmpty;

      if (menuResolved && !discountLoading && nothingPublished) {
        return Padding(
          padding: EdgeInsets.only(
            right: productsTabTrailingInset,
            top: SizeConfig.size24,
            bottom: SizeConfig.size24,
          ),
          child: EmptyStateWidget(
            message: AppStrings.foodNoProductCreate.tr,
            actionText: AppStrings.addFood.tr,
            actionCallback: () => _onAddFood(controller),
            actionHighlight: true,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _popularDishesSection(controller),
          SizedBox(height: SizeConfig.size20),
          _menuSection(controller, menuResolved: menuResolved),
        ],
      );
    });
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

  /// Reloads the rails after the merchant published something.
  ///
  /// `IfNeeded`, not a forced fetch: publishing already ran
  /// [RestaurantController.markMenuChanged], which dropped the saved snapshot
  /// and started the refetch. Forcing a second full reload here would duplicate
  /// those requests; the guarded call either finds that work already done or
  /// does it once.
  void _refreshIfDirty(RestaurantController controller) {
    if (controller.foodDataNeedsRefresh) {
      controller.foodDataNeedsRefresh = false;
      controller.fetchHomeAndDiscountIfNeeded(businessId: businessId);
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
              itemBuilder: (context, i) => AdminFoodCard(
                product: items[i],
                width: _dishCardWidth,
                // The rail sizes to its tallest card, so a short name has to
                // spend its spare line at the card's bottom or the rail reads
                // ragged. The Offer Dish grid is masonry and does NOT want this.
                equaliseHeight: true,
              ),
            ),
        ],
      );
    });
  }


  // MENU CATEGORIES â€” a rail rather than a grid: categories are a lane you
  // scan across, and the block grid pushed the rest of the tab below the fold.
  ///
  /// [menuResolved] is false while the menu fetch is still in flight — an empty
  /// list then means "not loaded", so it shows the rail skeleton rather than
  /// telling the merchant they have no categories.
  Widget _menuSection(
    RestaurantController controller, {
    required bool menuResolved,
  }) {
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
          if (menus.isEmpty && !menuResolved)
            const ProductCategoryRailSkeleton()
          else if (menus.isEmpty)
            Padding(
              padding: EdgeInsets.only(
                right: SizeConfig.size20,
                top: SizeConfig.size10,
                bottom: SizeConfig.size10,
              ),
              child: EmptyStateWidget(
                message: AppStrings.foodNoProductCreate.tr,
                actionText: AppStrings.addFood.tr,
                actionCallback: () => _onAddFood(controller),
                actionHighlight: true,
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
