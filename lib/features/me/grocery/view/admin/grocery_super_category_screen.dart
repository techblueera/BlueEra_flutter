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
import 'package:BlueEra/features/me/grocery/model/grocery_by_root_category_model.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_floating_cart.dart';
import 'package:BlueEra/features/me/kickstart/add_products_kickstart.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_product_select_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Add-grocery landing: an optional bulk-upload card followed by "Quick Upload"
/// rails — one horizontal rail per root category (title + icon + "More"),
/// each showing products from `products/by-root-category`. Tapping a product's
/// "+" toggles it into [GroceryController.selectedGroceries]; the floating cart
/// then routes to the Add Grocery Variant flow.
class GrocerySuperCategoryScreen extends StatefulWidget {
  final bool isAvailBulkUpload;

  /// True when this screen was opened by the app-open kickstart rather than by
  /// the merchant tapping "Add product" — see [showAddProductsKickstartIfNeeded].
  /// It swaps the back arrow for a ✕ (nothing was navigated away from, so there
  /// is nothing to go back to) and explains, above the rails, why it appeared.
  final bool isKickstart;

  const GrocerySuperCategoryScreen({
    super.key,
    required this.isAvailBulkUpload,
    this.isKickstart = false,
  });

  @override
  State<GrocerySuperCategoryScreen> createState() =>
      _GrocerySuperCategoryScreenState();
}

class _GrocerySuperCategoryScreenState
    extends State<GrocerySuperCategoryScreen> {
  final controller = getOrPut(() => GroceryController());

  /// Fixed width of a rail card (the rail's height is derived from the card's
  /// own content — see [_rootCategorySection]).
  static double get _railCardWidth => SizeConfig.size160;

  /// Height of a rail card skeleton only — the real rail sizes itself.
  static const double _railSkeletonHeight = 250.0;

  @override
  void initState() {
    super.initState();
    // Super-category tree drives the "More" navigation args (super list + key).
    controller.fetchGroceryNestedCategory();
    // TTL-guarded: reuses the loaded rails on re-entry within the FetchCache
    // window instead of hitting the network again.
    controller.fetchGroceryProductsByRootCategoryIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.addProducts,
        isLeading: !widget.isKickstart,
        leadingWidget: widget.isKickstart ? const KickstartCloseButton() : null,
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
      body: SafeArea(
        child: Stack(
          children: [
            _buildScrollBody(),

            // Selecting a product's "+" toggles it into
            // controller.selectedGroceries; this floating cart (hidden while
            // empty) then routes to the Add Grocery Variant screen.
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
      final resp = controller.groceryRootCategoryResponse.value;
      final sections = controller.groceryRootCategoryList;
      return CustomScrollView(
        slivers: [
          // Why this page opened, when it opened itself.
          if (widget.isKickstart)
            const SliverToBoxAdapter(child: KickstartIntroBanner()),
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
          // ── "Quick Upload" heading ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  SizeConfig.size12,
                  widget.isAvailBulkUpload ? SizeConfig.size4 : SizeConfig.size15,
                  SizeConfig.size12,
                  SizeConfig.size8),
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
          // Extra bottom room so the floating cart doesn't cover the last rail.
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

  /// The root-category rails as a lazy sliver, plus loading / error / empty
  /// states.
  Widget _railsSliver(
      ApiResponse resp, List<GroceryRootCategorySection> sections) {
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
            child: Text(AppStrings.groceryViewNoCategoriesFound.tr),
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
  /// over a horizontal list of product cards.
  Widget _rootCategorySection(GroceryRootCategorySection section) {
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
          // Header: icon + title on the left, "More" on the right.
          Padding(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
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
          ),
          // Rail: horizontal product cards. The rail height is NOT hardcoded —
          // each fixed-width card sizes to its own content and the Row sizes to
          // the tallest, so there is no wasted space. (No IntrinsicHeight: it
          // would fail on the FittedBox inside PriceRow.)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(
                SizeConfig.size12, 0, SizeConfig.size12, SizeConfig.size12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < section.products.length; i++) ...[
                  if (i > 0) SizedBox(width: SizeConfig.size10),
                  GroceryProductSelectCard(
                    product: section.products[i],
                    controller: controller,
                    width: _railCardWidth,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "More" → the nested-category screen for this root category (same args as
  /// the previous category-tile tap).
  void _openCategory(GroceryRootCategorySection section) {
    Get.toNamed(
      RouteHelper.getGroceryNestedCategoryScreenRoute(),
      arguments: {
        ApiKeys.argArrGrocerySuperCategory:
            controller.grocerySuperCategoryList.toList(),
        ApiKeys.argArrGroceryCatKey: section.key,
        ApiKeys.argArrGroceryCatName: section.name,
      },
    );
  }

  /// Shimmer skeleton shown on the first rails load — two placeholder rails
  /// (title bar + a row of card skeletons) so the transition is seamless.
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
                            height: _railSkeletonHeight,
                            width: _railCardWidth,
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
