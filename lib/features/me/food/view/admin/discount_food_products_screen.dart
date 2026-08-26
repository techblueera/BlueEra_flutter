
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/food/controller/restaurant_controller.dart';
import 'package:BlueEra/features/me/food/view/admin/widget/admin_food_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

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
      backgroundColor: Colors.transparent,
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
                      AdminFoodCard(product: items[index]),
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
