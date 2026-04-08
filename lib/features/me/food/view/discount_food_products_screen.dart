import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/food/controller/home_food_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_variant_sheet.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/widgets/RatingBadge.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

/// Paginated MasonryGridView of all discount food products for a business.
///
/// Opened from the "View All" action on the "Offer Dish (Discount)" section
/// of [RestaurantHomeScreen]. Shares [RestaurantController] state so the
/// home preview and this screen stay in sync.
class DiscountFoodProductsScreen extends StatefulWidget {
  final String businessId;

  const DiscountFoodProductsScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<DiscountFoodProductsScreen> createState() =>
      _DiscountFoodProductsScreenState();
}

class _DiscountFoodProductsScreenState
    extends State<DiscountFoodProductsScreen> {
  final controller = getOrPut(() => RestaurantController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Reset & re-fetch from page 1 so the user always lands on fresh data
    // regardless of what's currently cached from the home preview.
    controller.fetchDiscountFoodProducts(businessId: widget.businessId);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      controller.fetchDiscountFoodProducts(
        businessId: widget.businessId,
        isLoadMore: true,
      );
    }
  }

  Future<void> _onRefresh() async {
    await controller.fetchDiscountFoodProducts(businessId: widget.businessId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        appBarColor: AppColors.white,
        title: AppStrings.foodOfferDishDiscount.tr,
      ),
      body: Obx(() {
        final items = controller.discountFoodItems;
        final isInitialLoading =
            controller.isDiscountProductsLoading.value && items.isEmpty;
        final isLoadingMore = controller.isDiscountProductsLoadingMore.value;

        if (isInitialLoading) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 80),
                EmptyStateWidget(
                  message: AppStrings.foodNoDiscountProducts.tr,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(SizeConfig.size10),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childCount: items.length,
                  itemBuilder: (context, index) =>
                      _DiscountProductTile(item: items[index]),
                ),
              ),
              if (isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      }),
    );
  }
}

class _DiscountProductTile extends StatelessWidget {
  final CategoryFoodProductData item;

  const _DiscountProductTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final bool hasVariants =
        item.variants != null && item.variants!.isNotEmpty;
    final int variantCount = item.variants?.length ?? 0;
    final bool isMultiVariant = variantCount > 1;

    final sellingPrice = hasVariants ? item.variants![0].baseSellingPrice : null;
    final mrp = hasVariants ? item.variants![0].mrp : null;

    final int discountPercent =
        (mrp != null && sellingPrice != null && mrp > sellingPrice)
            ? (((mrp - sellingPrice) / mrp) * 100).round()
            : 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showFoodProductVariantSheet(context, product: item),
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image + discount/veg badges ──
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: CachedNetworkImage(
                    imageUrl: item.images?.firstOrNull ?? '',
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
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
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFFFD7845),
                              Color(0xFFFA5568),
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: CustomText(
                          '$discountPercent% OFF',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: FoodTypeIndicator(
                  isVegetarian:
                      item.dietaryType?.toLowerCase() == 'veg',
                  size: 8,
                ),
              ),
            ],
          ),

          // ── Details ──
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  item.name ?? '',
                  fontWeight: FontWeight.w600,
                  maxLines: 2,
                  fontSize: 13,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    RatingBadge(rating: '4.5'),
                    const SizedBox(width: 4),
                    Flexible(
                      child: CustomText(
                        AppStrings.foodReviewsSample.tr,
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CustomText(
                      "${AppConstants.rupeeSymbol}${sellingPrice ?? 0}",
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    if (mrp != null &&
                        sellingPrice != null &&
                        mrp >= sellingPrice) ...[
                      const SizedBox(width: 6),
                      CustomText(
                        "${AppConstants.rupeeSymbol}$mrp",
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.secondaryTextColor,
                      ),
                    ],
                  ],
                ),
                // if (isMultiVariant)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: CustomText(
                        isMultiVariant ?
                        "+${variantCount - 1} ${AppStrings.foodMoreVariant.tr}"
                            : '${variantCount} ${AppStrings.foodVariantSingular.tr}',
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
}
