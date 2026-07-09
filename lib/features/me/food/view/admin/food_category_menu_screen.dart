import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_by_root_category_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/food/view/widget/food_floating_cart.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_select_card.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_variant_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Add-food landing: a bulk-upload (snap-search) card, the Restaurant Special
/// card, then "Quick Upload" rails — one horizontal rail per root category
/// (title + icon + "More"), each showing products from
/// `foodProduct/by-root-category`. Tapping a card opens the variant sheet;
/// selected variants accumulate in the controller and the floating cart routes
/// to Review & Publish.
class FoodCategoryMenuScreen extends StatefulWidget {
  const FoodCategoryMenuScreen({super.key});

  @override
  State<FoodCategoryMenuScreen> createState() => _FoodCategoryMenuScreenState();
}

class _FoodCategoryMenuScreenState extends State<FoodCategoryMenuScreen> {
  final foodServiceController = getOrPut(() => FoodServiceController());

  @override
  void initState() {
    super.initState();
    // Nested category tree drives the "More" navigation args.
    foodServiceController.getFoodNestedCategoryApi();
    // TTL-guarded: reuses the loaded rails on re-entry within the FetchCache
    // window instead of hitting the network again.
    foodServiceController.fetchFoodProductsByRootCategoryIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.foodFoodItemsLabel.tr,
        // "Create Manually" now lives as a top-right action instead of a
        // full-width button in the footer.
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CustomBtn(
            height: SizeConfig.size35,
            width: SizeConfig.size120,
            // Restores the manual add-food entry: opens the "add your own food
            // item" form (name / category / type / cooking method / image) —
            // the same screen the product-selection screen's "Add Own Food
            // Items" action routes to.
            onTap: () => Get.toNamed(
              RouteHelper.getFoodEntryAiScreenRoute(),
              arguments: {ApiKeys.argCreateMissingProductIndex: null},
            ),
            title: AppStrings.foodCreateManually.tr,
            borderColor: AppColors.primaryColor,
            bgColor: AppColors.white,
            textColor: AppColors.primaryColor,
            radius: 10.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _buildScrollBody(),
            // Selecting variants via a product card's sheet accumulates them in
            // the controller; this floating cart routes to Review & Publish.
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: FoodFloatingCart(
                controller: foodServiceController,
                isSnapSearch: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollBody() {
    return Obx(() {
      final resp = foodServiceController.foodRootCategoryResponse.value;
      final sections = foodServiceController.foodRootCategoryList;
      return CustomScrollView(
        slivers: [
          // Snap-search bulk card.
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  SizeConfig.size8, SizeConfig.size15, SizeConfig.size8, 0),
              child: CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(AppStrings.foodUploadBulkProduct.tr),
                    SizedBox(height: SizeConfig.paddingXSL),
                    _snapSearchSuggestion(
                      onTap: () => Get.toNamed(
                        RouteHelper.getAddFoodSnapSearchScreenRoute(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Restaurant special.
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(SizeConfig.size8, SizeConfig.size10,
                  SizeConfig.size8, SizeConfig.size10),
              child: _restaurantSpecialCard(),
            ),
          ),
          // ── "Quick Upload" heading ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(SizeConfig.size12, SizeConfig.size4,
                  SizeConfig.size12, SizeConfig.size8),
              child: _title('Quick Upload'),
            ),
          ),
          // ── Root-category rails / states ────────────────────────────
          _railsSliver(resp, sections),
          // Bottom clearance so the last rail never hides behind the cart.
          SliverToBoxAdapter(
            child: SizedBox(
              height: foodServiceController.selectedVariantsMap.isEmpty
                  ? SizeConfig.size20
                  : FoodFloatingCart.reservedSpace,
            ),
          ),
        ],
      );
    });
  }

  /// The root-category rails as a lazy sliver, plus loading / error / empty
  /// states.
  Widget _railsSliver(ApiResponse resp, List<FoodRootCategorySection> sections) {
    if (sections.isEmpty) {
      if (resp.status == Status.LOADING || resp.status == Status.INITIAL) {
        return SliverToBoxAdapter(child: _buildRailsSkeleton());
      }
      if (resp.status == Status.ERROR) {
        return SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size20),
              child: CustomText(AppStrings.somethingWentWrong),
            ),
          ),
        );
      }
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: CustomText(AppStrings.noDataFound),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _rootCategorySection(sections[index]),
        childCount: sections.length,
      ),
    );
  }

  /// One root-category rail: a white card with a header (icon + title + "More")
  /// over a horizontal list of grocery-style [FoodProductSelectCard]s.
  Widget _rootCategorySection(FoodRootCategorySection section) {
    return Container(
      margin: EdgeInsets.fromLTRB(
          SizeConfig.size8, 0, SizeConfig.size8, SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _railHeader(section),
          // Each fixed-width card sizes to its own content and the Row sizes to
          // the tallest, so the rail height is not hardcoded.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(
                SizeConfig.size12, 0, SizeConfig.size12, SizeConfig.size12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < section.products.length; i++) ...[
                  if (i > 0) SizedBox(width: SizeConfig.size10),
                  FoodProductSelectCard(
                    product: section.products[i],
                    controller: foodServiceController,
                    onShowVariants: (p) => _showVariantSheet(context, p),
                    width: SizeConfig.size160,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Rail header: icon + title on the left, "More" on the right.
  Widget _railHeader(FoodRootCategorySection section) {
    return Padding(
      padding: EdgeInsets.fromLTRB(SizeConfig.size12, SizeConfig.size12,
          SizeConfig.size12, SizeConfig.paddingXSL),
      child: Row(
        children: [
          if (section.image.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: section.image,
                height: SizeConfig.size24,
                width: SizeConfig.size24,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => LocalAssets(
                  imagePath: AppIconAssets.place_holder_image,
                  height: SizeConfig.size24,
                  width: SizeConfig.size24,
                  boxFix: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: SizeConfig.size8),
          ],
          Expanded(
            child: CustomText(
              section.name,
              fontSize: SizeConfig.large,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.w600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          InkWell(
            onTap: () => _openCategory(section),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: CustomText(
                AppStrings.more.tr,
                fontSize: SizeConfig.medium,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "More" → the food product-selection screen for this root category.
  ///
  /// The by-root-category `section.category` is a lightweight stub with NO
  /// `children`, but the selection screen builds its sidebar + sub-category
  /// tabs from `children`. So resolve the FULL tree node (with children) from
  /// the loaded category tree, matching by id (fallback: key), and pass that.
  void _openCategory(FoodRootCategorySection section) {
    GroceryNestedCategoryModel? full;
    for (final c in foodServiceController.foodNestedCateList) {
      final byId = section.category?.sId != null && c.sId == section.category!.sId;
      final byKey = section.key.isNotEmpty && c.key == section.key;
      if (byId || byKey) {
        full = c;
        break;
      }
    }
    final category = full ?? section.category;
    if (category == null) return;

    foodServiceController.selectedFoodTypeID.value = category.sId ?? "";
    Get.toNamed(
      RouteHelper.getFoodProductSelectionScreenRoute(),
      arguments: {ApiKeys.argCategoryData: category},
    );
  }

  /// Opens the variant picker sheet — same sheet the selection screen uses.
  void _showVariantSheet(BuildContext context, CategoryFoodProductData product) {
    Get.bottomSheet(
      ProductVariantBottomSheet(
        product: product,
        controller: foodServiceController,
        isSnapSearch: false,
      ),
      isScrollControlled: true,
    );
  }

  /// First-load shimmer for the rails — two placeholder rails (title bar + a
  /// row of card skeletons).
  Widget _buildRailsSkeleton() {
    return buildLoadingShimmer(
      child: Column(
        children: List.generate(2, (_) {
          return Container(
            margin: EdgeInsets.fromLTRB(
                SizeConfig.size8, 0, SizeConfig.size8, SizeConfig.size12),
            padding: EdgeInsets.all(SizeConfig.size12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                shimmerContainer(height: 18, width: 140, radius: 4),
                SizedBox(height: SizeConfig.size12),
                // Horizontal scroll (non-scrollable) so the fixed-width
                // placeholders can extend past the screen edge without
                // overflowing, mirroring the real rail.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: EdgeInsets.only(right: SizeConfig.size10),
                        child: shimmerContainer(
                            height: 250,
                            width: SizeConfig.size160,
                            radius: 10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _restaurantSpecialCard() {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(AppStrings.foodRestaurantSpecial.tr),
          SizedBox(height: SizeConfig.paddingXSL),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: SizedBox(
              height: SizeConfig.size170,
              width: double.infinity,
              child: Stack(
                children: [
                  LocalAssets(
                    imagePath: AppImageAssets.foodDummyImage,
                    height: SizeConfig.size170,
                    width: double.infinity,
                    boxFix: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: SizeConfig.size80,
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(10.0)),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      alignment: Alignment.center,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 14.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LocalAssets(
                              imagePath:
                                  "${AppConstants.baseFoodAssetsPath}restaurant_special.svg",
                              height: SizeConfig.size22,
                              width: SizeConfig.size22,
                            ),
                            SizedBox(width: SizeConfig.paddingXSL),
                            CustomText(
                              AppStrings.foodCreateRestaurantSpecial.tr,
                              fontSize: SizeConfig.small,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _title(String title) {
    return CustomText(title,
        fontSize: SizeConfig.large,
        color: AppColors.mainTextColor,
        fontWeight: FontWeight.w600);
  }

  Widget _snapSearchSuggestion({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size10,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(SizeConfig.size8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: LocalAssets(
                imagePath: AppIconAssets.cameraAddOutlineIcon,
                height: 18,
                width: 18,
                boxFix: BoxFit.scaleDown,
                imgColor: AppColors.primaryColor,
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    'Search products by photo',
                    fontSize: SizeConfig.small,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  CustomText(
                    'Upload a picture to find products instantly.',
                    fontSize: SizeConfig.extraSmall,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: SizeConfig.size6),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
