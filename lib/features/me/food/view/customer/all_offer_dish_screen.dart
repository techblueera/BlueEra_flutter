import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/food/controller/food_selfpickup_controller.dart';
import 'package:BlueEra/features/me/food/controller/restaurant_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/customer_food_self_pickup_cart.dart';
import 'package:BlueEra/features/me/food/view/widget/food_offer_dish_tile.dart';
import 'package:BlueEra/features/me/food/view/widget/food_self_pickup_variants_sheet.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class AllOfferDishScreen extends StatefulWidget {
  final String businessId;

  const AllOfferDishScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<AllOfferDishScreen> createState() => _AllOfferDishScreenState();
}

class _AllOfferDishScreenState extends State<AllOfferDishScreen> {
  final controller = getOrPut(() => RestaurantController());
  final foodCartController =
      getOrPut<FoodSelfPickupController>(() => FoodSelfPickupController());
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchDiscountFoodProducts(businessId: widget.businessId);
    });
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
    await controller.fetchDiscountFoodProducts(
        businessId: widget.businessId);
  }

  void _onTapItem(CategoryFoodProductData product) {
    final details =
        viewBusinessDetailsController.visitedBusinessProfileDetails?.data;

    showFoodSelfPickupVariantsSheet(
      context,
      args: FoodSelfPickupSheetArgs.fromCategoryProduct(
        product,
        visitBusinessId: widget.businessId,
        visitBusinessName: details?.businessName,
        visitBusinessLogo: details?.logo,
        visitBusinessAddress: details?.address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        appBarColor: AppColors.white,
        title: AppStrings.foodOfferDishDiscount.tr,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Obx(() {
            final items = controller.discountFoodItems;
            final isLoading = controller.isDiscountProductsLoading.value;
            final isLoadingMore =
                controller.isDiscountProductsLoadingMore.value;

            if (isLoading && items.isEmpty) {
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
                    const SizedBox(height: 80),
                    EmptyStateWidget(
                      message: AppStrings.noDataFound.tr,
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
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childCount: items.length,
                      itemBuilder: (context, index) =>
                          _OfferDishTile(
                        item: items[index],
                        onTap: () => _onTapItem(items[index]),
                      ),
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
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
              ),
            );
          }),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: CustomerFoodSelfPickupCart(controller: foodCartController),
          ),
        ],
      ),
    );
  }
}

class _OfferDishTile extends StatelessWidget {
  final CategoryFoodProductData item;
  final VoidCallback onTap;

  const _OfferDishTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasVariants =
        item.variants != null && item.variants!.isNotEmpty;
    final sellingPrice =
        hasVariants ? item.variants![0].baseSellingPrice : null;
    final mrp = hasVariants ? item.variants![0].mrp : null;

    final int discountPercent =
        (mrp != null && sellingPrice != null && mrp > sellingPrice)
            ? (((mrp - sellingPrice) / mrp) * 100).round()
            : 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: item.images?.firstOrNull ?? "",
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) => Container(
                      height: 140,
                      color: Colors.grey.shade200,
                      child:
                          const Icon(Icons.fastfood, color: Colors.grey),
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
                        filter:
                            ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
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
                              color: AppColors.white
                                  .withValues(alpha: 0.2),
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
                        item.dietaryType?.toLowerCase() == "veg",
                    size: 8,
                  ),
                ),
              ],
            ),
            FoodOfferDishInfoSection(item: item),
          ],
        ),
      ),
    );
  }
}
