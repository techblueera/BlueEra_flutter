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
import 'package:BlueEra/features/me/food/view/widget/food_floating_cart.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_card.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_variant_bottom_sheet.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class FoodCategoryMenuScreen extends StatefulWidget {
  const FoodCategoryMenuScreen({super.key});

  @override
  State<FoodCategoryMenuScreen> createState() => _FoodCategoryMenuScreenState();
}

class _FoodCategoryMenuScreenState extends State<FoodCategoryMenuScreen> {
  // List mapped to your specific local assets
  final foodServiceController = getOrPut(() => FoodServiceController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    foodServiceController.getFoodNestedCategoryApi();
    // TTL-guarded: reuses the loaded showcase list on re-entry within the
    // FetchCache window instead of hitting the network again.
    foodServiceController.fetchFoodCategoryShowcaseIfNeeded();
    _scrollController.addListener(_onShowcaseScroll);
    super.initState();
  }

  /// Auto-load the next "Suggested Products" page near the bottom.
  void _onShowcaseScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !foodServiceController.isFoodShowcaseLoadingMore.value &&
        foodServiceController.foodShowcaseHasMore) {
      foodServiceController.fetchFoodCategoryShowcase(isLoadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onShowcaseScroll);
    _scrollController.dispose();
    super.dispose();
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
            onTap: () {},
            title: AppStrings.foodCreateManually.tr,
            borderColor: AppColors.primaryColor,
            bgColor: AppColors.white,
            textColor: AppColors.primaryColor,
            radius: 10.0,
          ),
        ),
      ),
      // Lazy CustomScrollView: the category grid is a SliverMasonryGrid that
      // builds ONLY the cards currently on screen. This makes the screen
      // crash-proof regardless of how many categories the API returns (the
      // food `categories/tree` endpoint can return ~1.7k roots of bad data).
      body: SafeArea(
        child: Stack(
          children: [
            _buildScrollBody(),
            // Selecting variants via a product card's sheet accumulates them in
            // the controller; this floating cart routes to Review & Publish —
            // same flow as FoodProductSelectionScreen.
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
          final status =
              foodServiceController.getFoodCategoryResponse.value.status;
          final categories = foodServiceController.foodNestedCateList;
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Snap-search card
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(SizeConfig.size8,
                      SizeConfig.size15, SizeConfig.size8, 0),
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
              // Category section — white card (title + lazy grid). DecoratedSliver
              // paints the white background behind the whole group while
              // SliverMainAxisGroup keeps the grid lazy.
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    SizeConfig.size8, SizeConfig.size12, SizeConfig.size8, 0),
                sliver: DecoratedSliver(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(SizeConfig.size12),
                  ),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              SizeConfig.size12,
                              SizeConfig.size12,
                              SizeConfig.size12,
                              SizeConfig.paddingXSL),
                          child: _title(AppStrings.category.tr),
                        ),
                      ),
                      // Category grid (lazy) / states
                      _categorySliver(status, categories),
                    ],
                  ),
                ),
              ),
              // Restaurant special
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(SizeConfig.size8,
                      SizeConfig.size10, SizeConfig.size8, SizeConfig.size10),
                  child: _restaurantSpecialCard(),
                ),
              ),
              // Suggested Products showcase (lazy list of FoodProductCard).
              ..._showcaseSlivers(),
              // Bottom clearance so the last card never hides behind the
              // floating cart once variants are selected.
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

  /// "Suggested Products" section: a title + a LAZY list of [FoodProductCard]s
  /// (same card + variant-sheet flow as [FoodProductSelectionScreen]). Returns
  /// an empty list when there's nothing to show and nothing loading.
  List<Widget> _showcaseSlivers() {
    final resp = foodServiceController.foodShowcaseResponse.value;
    final products = foodServiceController.foodShowcaseList;

    final bool isLoading =
        resp.status == Status.LOADING || resp.status == Status.INITIAL;
    if (products.isEmpty && !isLoading && resp.status != Status.ERROR) {
      return const [];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(SizeConfig.size8, SizeConfig.size4,
              SizeConfig.size8, SizeConfig.paddingXSL),
          child: _title('Suggested Products'),
        ),
      ),
      _showcaseListSliver(resp, products),
      // Pagination loader — a full-width sliver so it's centered across the
      // screen.
      if (foodServiceController.isFoodShowcaseLoadingMore.value)
        _loadMoreSliver(),
    ];
  }

  /// Full-width, horizontally-centered pagination spinner shown below the list.
  Widget _loadMoreSliver() => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );

  /// Showcase list as a LAZY sliver plus loading / error states. The "loading
  /// more" spinner is a separate full-width sliver (see [_showcaseSlivers]).
  Widget _showcaseListSliver(
      ApiResponse resp, List<CategoryFoodProductData> products) {
    if (products.isEmpty) {
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
      return SliverToBoxAdapter(child: _buildFoodShowcaseSkeleton());
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
      sliver: SliverList.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return FoodProductCard(
            product: product,
            onShowVariants: (p) => _showVariantSheet(context, p),
          );
        },
      ),
    );
  }

  /// First-load shimmer for the showcase — mirrors the full-width food cards.
  Widget _buildFoodShowcaseSkeleton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
      child: buildLoadingShimmer(
        child: Column(
          children: List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: shimmerContainer(height: 110, radius: 12),
            ),
          ),
        ),
      ),
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

  /// Category grid as a LAZY sliver (builds only visible cards) plus the
  /// loading / error / empty states.
  Widget _categorySliver(
      Status? status, List<GroceryNestedCategoryModel> categories) {
    if (status == Status.COMPLETE) {
      if (categories.isEmpty) {
        return SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: CustomText(AppStrings.noDataFound),
            ),
          ),
        );
      }
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(
            SizeConfig.size8, 0, SizeConfig.size8, SizeConfig.size12),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childCount: categories.length,
          itemBuilder: (context, index) {
            final item = categories[index];
            return CommonServiceCard<GroceryNestedCategoryModel>(
              service: item,
              getName: (item) => item.name ?? '',
              getIcon: (item) => item.image ?? '',
              iconHeight: SizeConfig.size60,
              boxShadow: const [],
              onTap: (item) {
                foodServiceController.selectedFoodTypeID.value =
                    item.sId ?? "";
                Get.toNamed(
                  RouteHelper.getProductSelectionScreenRoute(),
                  arguments: {ApiKeys.argCategoryData: item},
                );
              },
            );
          },
        ),
      );
    } else if (status == Status.ERROR) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CustomText(AppStrings.somethingWentWrong),
          ),
        ),
      );
    }
    return SliverToBoxAdapter(child: buildCategoryGridSkeleton());
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

  Widget _title(String title){
    return CustomText(
        title,
        fontSize: SizeConfig.large,
        color: AppColors.mainTextColor,
        fontWeight: FontWeight.w600
    );
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
