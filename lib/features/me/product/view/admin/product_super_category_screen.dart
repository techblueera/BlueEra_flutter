import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/model/product_catalog_response.dart';
// The catalog `Product` is the showcase list type; the nested-category
// response declares its own `Product`, so hide it to keep `Product`
// unambiguous (matches ProductController's import).
import 'package:BlueEra/features/me/product/model/product_nested_category_response.dart'
    hide Product;
import 'package:BlueEra/features/me/product/view/admin/widget/create_own_product_via_ai_widget.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_selection_product_card.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_selection_variant_sheet.dart';
import 'package:BlueEra/features/me/product/view/customer/widget/product_floating_cart.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class ProductSuperCategoryScreen extends StatefulWidget {
  final String? ownerID;
  final ProviderType? providerType;

  const ProductSuperCategoryScreen({
    super.key,
    this.ownerID,
    this.providerType,
  });

  @override
  State<ProductSuperCategoryScreen> createState() =>
      _ProductSuperCategoryScreenState();
}

class _ProductSuperCategoryScreenState
    extends State<ProductSuperCategoryScreen> {
  final controller = getOrPut(() => ProductController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch ONCE on entry — not in build(). build() re-runs on every
    // keyboard open/close (the root MediaQuery viewInsets change rebuilds
    // every mounted route, including this one when it sits under the
    // add-variant dialog), and an unguarded call here hammered
    // `categories/nested` on each toggle.
    if (widget.ownerID != null) controller.ownerID = widget.ownerID;
    if (widget.providerType != null) {
      controller.ownerProviderType = widget.providerType;
    }
    controller.fetchProductsNestedCategory();
    // TTL-guarded: reuses the loaded showcase list on re-entry within the
    // FetchCache window instead of hitting the network again.
    controller.fetchProductCategoryShowcaseIfNeeded();
    _scrollController.addListener(_onShowcaseScroll);
  }

  /// Auto-load the next "Suggested Products" page near the bottom.
  void _onShowcaseScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !controller.isProductShowcaseLoadingMore.value &&
        controller.productShowcaseHasMore) {
      controller.fetchProductCategoryShowcase(isLoadMore: true);
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
        title: AppStrings.addProducts,
        buildCustomActionWidget: () => CreateOwnProductViaAiWidget(
          providerType: ProviderType.business,
        ),
      ),
      // Lazy CustomScrollView: the category grid is a SliverMasonryGrid that
      // builds only the cards currently on screen, so the screen can't
      // ANR-crash no matter how many categories the API returns.
      body: SafeArea(
        child: Stack(
          children: [
            _buildScrollBody(),
            // Selecting variants via a card's sheet accumulates them in the
            // controller; this floating cart routes to the Add Product Variant
            // screen — same flow as ProductSelectionScreen.
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Obx(() => ProductFloatingCart(
                      selectedProducts: controller.selectedProducts.toList(),
                      onTap: () => Get.toNamed(
                          RouteHelper.getAddProductVariantScreenRoute()),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollBody() {
    return Obx(() {
          final resp = controller.nestedProductCategoryResponse.value;
          final categories = controller.productsNestedCategoryList;
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Snap-search suggestion ─────────────────────────────
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
                          'Add Products',
                          fontSize: SizeConfig.large,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(height: SizeConfig.paddingXSL),
                        _snapSearchSuggestion(
                          onTap: () => Get.toNamed(
                            RouteHelper.getAddProductTextOrSnapScreenRoute(),
                            arguments: {
                              ApiKeys.id: controller.ownerID,
                              ApiKeys.providerType:
                                  controller.ownerProviderType,
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Category card — title + grid on a white surface,
              // matching the "Add Products" card above so it reads as a
              // distinct section against the app background. The category
              // set is bounded, so a shrink-wrapped grid is fine here.
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(SizeConfig.size8, 0,
                      SizeConfig.size8, SizeConfig.size15),
                  child: CustomFormCard(
                    padding: EdgeInsets.all(SizeConfig.size10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          'Category',
                          fontSize: SizeConfig.large,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(height: SizeConfig.paddingXSL),
                        _categoryContent(resp, categories),
                      ],
                    ),
                  ),
                ),
              ),
              // Suggested Products showcase (lazy 2-col grid of cards).
              ..._showcaseSlivers(),
              // Bottom clearance so the last card never hides behind the
              // floating cart once products are selected.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: controller.selectedProducts.isEmpty
                      ? SizeConfig.size15
                      : SizeConfig.size80,
                ),
              ),
            ],
          );
        });
  }

  /// "Suggested Products" section: a title + a LAZY 2-column masonry grid of
  /// [ProductSelectionProductCard]s (same card + variant-sheet flow as
  /// [ProductSelectionScreen]). Returns an empty list when there's nothing to
  /// show and nothing loading.
  List<Widget> _showcaseSlivers() {
    final resp = controller.productShowcaseResponse.value;
    final products = controller.productShowcaseList;

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
      if (controller.isProductShowcaseLoadingMore.value) _loadMoreSliver(),
    ];
  }

  /// Full-width, horizontally-centered pagination spinner shown below the grid.
  Widget _loadMoreSliver() => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );

  /// Showcase grid as a LAZY sliver plus loading / error states. The "loading
  /// more" spinner is a separate full-width sliver (see [_showcaseSlivers]) so
  /// it stays horizontally centered.
  Widget _showcaseGridSliver(ApiResponse resp, List<Product> products) {
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
      return SliverToBoxAdapter(child: _buildProductShowcaseSkeleton());
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
          final product = products[index];
          return ProductSelectionProductCard(
            product: product,
            controller: controller,
            onShowVariants: (p) => ProductSelectionVariantSheet.show(
              product: p,
              controller: controller,
            ),
          );
        },
      ),
    );
  }

  /// First-load shimmer for the showcase — mirrors the 2-column product grid.
  Widget _buildProductShowcaseSkeleton() {
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

  /// Category grid + error / empty / loading states, as a plain (box)
  /// widget so it can live inside the white [CustomFormCard]. Shrink-wrapped
  /// and non-scrollable — the outer [CustomScrollView] owns the scroll.
  Widget _categoryContent(
      ApiResponse resp, List<ProductNestedCategoryResponse> categories) {
    if (categories.isNotEmpty) {
      return MasonryGridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return CommonServiceCard<ProductNestedCategoryResponse>(
            service: category,
            getName: (item) => item.name ?? '',
            getIcon: (item) => item.image ?? '',
            iconHeight: SizeConfig.size60,
            boxShadow: const [],
            onTap: (item) {
              // Navigate immediately and let the nested screen fetch this
              // category's subtree with its own in-place shimmer — no blocking
              // loader here. The flat level-0 list is forwarded so the nested
              // screen's top-level switcher can drill elsewhere.
              Get.toNamed(
                RouteHelper.getProductNestedCategoryScreenRoute(),
                arguments: {
                  ApiKeys.argArrProductSuperCategory: categories.toList(),
                  ApiKeys.argArrProductCatId: item.sId,
                  ApiKeys.argArrProductCatName: item.name,
                },
              );
            },
          );
        },
      );
    } else if (resp.status == Status.ERROR) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CustomText(AppStrings.somethingWentWrong),
        ),
      );
    } else if (resp.status == Status.COMPLETE) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: CustomText('No categories found.'),
        ),
      );
    }
    return buildCategoryGridSkeleton();
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
