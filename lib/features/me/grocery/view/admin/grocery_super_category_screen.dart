import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_floating_cart.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class GrocerySuperCategoryScreen extends StatefulWidget {
  final bool isAvailBulkUpload;
  const GrocerySuperCategoryScreen({super.key, required this.isAvailBulkUpload});

  @override
  State<GrocerySuperCategoryScreen> createState() => _GrocerySuperCategoryScreenState();
}

class _GrocerySuperCategoryScreenState extends State<GrocerySuperCategoryScreen> {
  final controller = getOrPut(() => GroceryController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.fetchGroceryNestedCategory();
    // TTL-guarded: reuses the loaded showcase list on re-entry within the
    // FetchCache window instead of hitting the network again.
    controller.fetchGroceryCategoryShowcaseIfNeeded();
    _scrollController.addListener(_onScrollListener);
  }

  /// Auto-load the next showcase page as the user nears the bottom.
  void _onScrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !controller.isGroceryShowcaseLoadingMore.value &&
        controller.groceryShowcaseHasMore) {
      controller.fetchGroceryCategoryShowcase(isLoadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.addProducts,
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: CustomBtn(
            height: SizeConfig.size35,
            width: SizeConfig.size70,
            onTap: () {},
            bgColor: AppColors.white,
            borderColor: AppColors.primaryColor,
            radius: 10.0,
            title: AppStrings.groceryViewTutorial.tr,
            textColor: AppColors.primaryColor,
          ),
        ),
      ),
      // Lazy CustomScrollView: the category grid is a SliverMasonryGrid that
      // builds only the cards currently on screen, so the screen can't
      // ANR-crash no matter how many categories the API returns.
      body: SafeArea(
        child: Stack(
          children: [
            _buildScrollBody(),
            // Selecting a Suggested Product's "Add" toggles it into
            // controller.selectedGroceries; this floating cart (hidden while
            // empty) then routes to the Add Grocery Variant screen — same flow
            // as GroceryProductsSelectionScreen.
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GroceryFloatingCart(controller: controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollBody() {
    return Obx(() {
          final resp = controller.fetchNestedGroceryCategoryResponse.value;
          final categories = controller.grocerySuperCategoryList;
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Snap-search suggestion (conditional) ─────────────────
              if (widget.isAvailBulkUpload)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(SizeConfig.size8,
                        SizeConfig.size15, SizeConfig.size8, SizeConfig.paddingXSL),
                    child: CustomFormCard(
                      padding: EdgeInsets.all(SizeConfig.size10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            AppStrings.groceryViewUploadBulkProducts.tr,
                            fontSize: SizeConfig.large,
                            color: AppColors.mainTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                          SizedBox(height: SizeConfig.paddingXSL),
                          _snapSearchSuggestion(
                            onTap: () => Get.toNamed(
                              RouteHelper.getAddGrocerySnapSearchScreenRoute(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // ── Category section (white card: title + lazy grid) ────────
              // DecoratedSliver paints the white background behind the whole
              // group while SliverMainAxisGroup keeps the grid lazy.
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    SizeConfig.size8,
                    widget.isAvailBulkUpload ? 0 : SizeConfig.size15,
                    SizeConfig.size8,
                    0),
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
                          child: CustomText(
                            AppStrings.groceryViewCategory.tr,
                            fontSize: SizeConfig.large,
                            color: AppColors.mainTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // ── Category grid (lazy) / states ──────────────────
                      _categorySliver(resp, categories),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: SizeConfig.size15)),
              // ── Product showcase (title + lazy grid) ────────────────────
              ..._showcaseSlivers(),
              // Extra bottom room so the floating cart doesn't cover the last
              // row's Add button once a Suggested Product is selected.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: controller.selectedGroceries.isEmpty
                      ? SizeConfig.size15
                      : SizeConfig.size80,
                ),
              ),
            ],
          );
        });
  }

  /// Category grid as a LAZY sliver (builds only visible cards) plus the
  /// loading / error / empty states.
  Widget _categorySliver(
      ApiResponse resp, List<GroceryNestedCategoryModel> categories) {
    if (resp.status == Status.INITIAL) {
      return SliverToBoxAdapter(child: buildCategoryGridSkeleton());
    }
    if (resp.status == Status.ERROR) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: CustomText(AppStrings.somethingWentWrong),
          ),
        ),
      );
    }
    if (categories.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(AppStrings.groceryViewNoCategoriesFound.tr),
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
          final category = categories[index];
          return CommonServiceCard<GroceryNestedCategoryModel>(
            service: category,
            getName: (item) => item.name ?? '',
            getIcon: (item) => item.image ?? '',
            iconHeight: SizeConfig.size60,
            boxShadow: const [],
            onTap: (item) {
              Get.toNamed(
                RouteHelper.getGroceryNestedCategoryScreenRoute(),
                arguments: {
                  ApiKeys.argArrGrocerySuperCategory: categories.toList(),
                  ApiKeys.argArrGroceryCatKey: item.key,
                  ApiKeys.argArrGroceryCatName: item.name,
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Product-showcase section: a title + a LAZY masonry grid of product cards.
  /// No wrapping white card — the page bg is already white, so each card
  /// carries its own greyE5 border for separation instead. Returns an empty
  /// list when there is nothing to show and nothing loading, so the section
  /// disappears.
  List<Widget> _showcaseSlivers() {
    final resp = controller.groceryCategoryShowcaseResponse.value;
    final products = controller.groceryCategoryShowcaseList;

    final bool isLoading =
        resp.status == Status.LOADING || resp.status == Status.INITIAL;
    if (products.isEmpty && !isLoading && resp.status != Status.ERROR) {
      return const [];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              SizeConfig.size12,
              SizeConfig.size4,
              SizeConfig.size12,
              SizeConfig.paddingXSL),
          child: CustomText(
            'Suggested Products',
            fontSize: SizeConfig.large,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      _showcaseGridSliver(resp, products),
      // Pagination loader — a full-width sliver so it's centered across the
      // screen, not stuck in the left grid cell.
      if (controller.isGroceryShowcaseLoadingMore.value) _loadMoreSliver(),
    ];
  }

  /// Full-width, horizontally-centered pagination spinner shown below the grid.
  Widget _loadMoreSliver() => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );

  /// The showcase product grid as a LAZY sliver plus its loading / error
  /// states. The "loading more" spinner is a separate full-width sliver (see
  /// [_showcaseSlivers]) so it stays horizontally centered.
  Widget _showcaseGridSliver(
      ApiResponse resp, List<GroceryProductData> products) {
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
      // First-time load → shimmer skeleton (not a bare spinner).
      return SliverToBoxAdapter(child: _buildShowcaseSkeleton());
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
          SizeConfig.size8, 0, SizeConfig.size8, SizeConfig.size12),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childCount: products.length,
        itemBuilder: (context, index) {
          return _showcaseCard(products[index]);
        },
      ),
    );
  }

  /// Shimmer skeleton shown on the FIRST showcase load — mirrors the 2-column
  /// product grid so the transition to real cards is seamless.
  Widget _buildShowcaseSkeleton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          SizeConfig.size8, 0, SizeConfig.size8, SizeConfig.size12),
      child: buildLoadingShimmer(
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 250,
          ),
          itemCount: 4,
          itemBuilder: (_, __) => shimmerContainer(height: 250, radius: 10),
        ),
      ),
    );
  }

  /// Grocery product card, matching the design used on
  /// [GroceryProductsSelectionScreen.groceryCard].
  Widget _showcaseCard(GroceryProductData product) {
    final variant =
        (product.variants?.isNotEmpty ?? false) ? product.variants!.first : null;
    final price = controller.getPriceDetails(variant?.pricing);
    final bool isSelected = controller.selectedGroceries.contains(product);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Container(
              padding: EdgeInsets.only(top: 4.0),
              height: SizeConfig.size140,
              width: double.infinity,
              child: (product.images?.isNotEmpty ?? false)
                  ? CachedNetworkImage(
                      imageUrl: product.images!.first.url ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.cover,
                      ),
                    )
                  : LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.cover,
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 8.0, vertical: SizeConfig.size6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "${product.name}",
                  fontSize: SizeConfig.small,
                  maxLines: 1,
                  color: AppColors.mainTextColor,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    if (variant?.isVegetarian != null) ...[
                      FoodTypeIndicator(
                          isVegetarian: variant?.isVegetarian ?? false),
                      SizedBox(width: SizeConfig.size6),
                    ],
                    Container(
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: AppColors.green00, width: 1),
                          borderRadius: BorderRadius.circular(2)),
                      padding: EdgeInsets.all(3.5),
                      child: Container(
                        height: 7,
                        width: 7,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: AppColors.green00),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(width: 0.5, color: AppColors.greyE5)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: CustomText(
                        '${variant?.quantity ?? ''}',
                        fontSize: 11,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                PriceRow(
                  sellingPrice: "${price.sellingRange}",
                  mrp: "${price.mrpRange}",
                  discount: "${price.discountRange}",
                ),
                SizedBox(height: SizeConfig.size8),
                CustomBtn(
                  height: SizeConfig.size36,
                  onTap: () => controller.toggleSelection(product),
                  title: isSelected
                      ? AppStrings.groceryViewAdded.tr
                      : AppStrings.groceryViewAdd.tr,
                  textColor:
                      isSelected ? AppColors.white : AppColors.primaryColor,
                  bgColor:
                      isSelected ? AppColors.primaryColor : AppColors.white,
                  radius: 6.0,
                  borderColor: AppColors.primaryColor,
                ),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size4),
        ],
      ),
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