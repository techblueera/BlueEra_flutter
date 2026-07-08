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
import 'package:BlueEra/features/me/automotive_products/controller/automotive_product_controller.dart';
import 'package:BlueEra/features/me/automotive_products/model/automotive_product_by_root_category_model.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/widget/automotive_create_own_product_via_ai_widget.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/widget/automotive_product_selection_product_card.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/widget/automotive_product_selection_variant_sheet.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/widget/automotive_product_floating_cart.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Add-automotive-product landing: an "Add Products" snap card followed by
/// "Quick Upload" rails — one horizontal rail per root category (title + icon +
/// "More"), each showing products from `automotive-service/.../by-root-category`.
/// Tapping a card opens the variant picker sheet; selected variants accumulate
/// in the controller and the floating cart routes to the Add Product Variant
/// screen.
class AutomotiveProductSuperCategoryScreen extends StatefulWidget {
  final String? ownerID;
  final ProviderType? providerType;

  const AutomotiveProductSuperCategoryScreen({
    super.key,
    this.ownerID,
    this.providerType,
  });

  @override
  State<AutomotiveProductSuperCategoryScreen> createState() =>
      _AutomotiveProductSuperCategoryScreenState();
}

class _AutomotiveProductSuperCategoryScreenState
    extends State<AutomotiveProductSuperCategoryScreen> {
  final controller = getOrPut(() => AutomotiveProductController());

  /// Fixed width of a rail card (grid-style card; the rail height follows the
  /// card's own content — see [_rootCategorySection]).
  static double get _railCardWidth => SizeConfig.size160;

  @override
  void initState() {
    super.initState();
    // Fetch ONCE on entry — not in build(). build() re-runs on every keyboard
    // open/close, and an unguarded call there hammered the endpoint on each
    // toggle.
    if (widget.ownerID != null) controller.ownerID = widget.ownerID;
    if (widget.providerType != null) {
      controller.ownerProviderType = widget.providerType;
    }
    // Nested category tree drives the "More" navigation args (super list).
    controller.fetchProductsNestedCategory();
    // TTL-guarded: reuses the loaded rails on re-entry within the FetchCache
    // window instead of hitting the network again.
    controller.fetchProductsByRootCategoryIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.addProducts,
        buildCustomActionWidget: () => AutomotiveCreateOwnProductViaAiWidget(
          providerType: ProviderType.business,
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _buildScrollBody(),
            // Selecting variants via a card's sheet accumulates them in the
            // controller; this floating cart routes to the Add Product Variant
            // screen.
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Obx(() => AutomotiveProductFloatingCart(
                      selectedProducts: controller.selectedProducts.toList(),
                      onTap: () => Get.toNamed(RouteHelper
                          .getAutomotiveAddProductVariantScreenRoute()),
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
      final resp = controller.rootCategoryResponse.value;
      final sections = controller.rootCategoryList;
      return CustomScrollView(
        slivers: [
          // ── Snap-search suggestion ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(SizeConfig.size8, SizeConfig.size15,
                  SizeConfig.size8, SizeConfig.paddingXSL),
              child: CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Add AutomotiveProducts',
                      fontSize: SizeConfig.large,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: SizeConfig.paddingXSL),
                    _snapSearchSuggestion(
                      onTap: () => Get.toNamed(
                        RouteHelper.getAutomotiveAddProductTextOrSnapScreenRoute(),
                        arguments: {
                          ApiKeys.id: controller.ownerID,
                          ApiKeys.providerType: controller.ownerProviderType,
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── "Quick Upload" heading ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(SizeConfig.size12, SizeConfig.size4,
                  SizeConfig.size12, SizeConfig.size8),
              child: CustomText(
                'Quick Upload',
                fontSize: SizeConfig.large,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // ── Root-category rails / states ────────────────────────────
          _railsSliver(resp, sections),
          // Bottom clearance so the last rail never hides behind the cart.
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

  /// The root-category rails as a lazy sliver, plus loading / error / empty
  /// states.
  Widget _railsSliver(
      ApiResponse resp, List<AutomotiveProductRootCategorySection> sections) {
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
            child: CustomText('No categories found.'),
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
  /// over a horizontal list of [AutomotiveProductSelectionProductCard]s.
  Widget _rootCategorySection(AutomotiveProductRootCategorySection section) {
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
                  SizedBox(
                    width: _railCardWidth,
                    child: AutomotiveProductSelectionProductCard(
                      product: section.products[i],
                      controller: controller,
                      onShowVariants: (p) =>
                          AutomotiveProductSelectionVariantSheet.show(
                        product: p,
                        controller: controller,
                      ),
                    ),
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
  Widget _railHeader(AutomotiveProductRootCategorySection section) {
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

  /// "More" → the nested-category screen for this root category (same args as
  /// the previous category-tile tap).
  void _openCategory(AutomotiveProductRootCategorySection section) {
    Get.toNamed(
      RouteHelper.getAutomotiveProductNestedCategoryScreenRoute(),
      arguments: {
        ApiKeys.argArrProductSuperCategory:
            controller.productsNestedCategoryList.toList(),
        ApiKeys.argArrProductCatId: section.category?.sId,
        ApiKeys.argArrProductCatName: section.category?.name,
      },
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
                // Horizontal scroll (non-scrollable) so fixed-width placeholders
                // can extend past the screen edge without overflowing.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: EdgeInsets.only(right: SizeConfig.size10),
                        child: shimmerContainer(
                            height: 250, width: _railCardWidth, radius: 10),
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
