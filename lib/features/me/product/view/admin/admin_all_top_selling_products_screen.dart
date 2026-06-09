import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/admin_product_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class AdminAllTopSellingProductsScreen extends StatefulWidget {
  const AdminAllTopSellingProductsScreen({super.key});

  @override
  State<AdminAllTopSellingProductsScreen> createState() =>
      _AdminAllTopSellingProductsScreenState();
}

class _AdminAllTopSellingProductsScreenState
    extends State<AdminAllTopSellingProductsScreen> {
  final InventoryController controller =
      getOrPut<InventoryController>(() => InventoryController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Defer the fetch until after the first frame so the controller's
    // observable mutations don't re-enter an in-flight build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchBusinessProducts(isDiscountedProducts: true);
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
      controller.fetchBusinessProducts(
          isDiscountedProducts: true, isLoadMore: true);
    }
  }

  Future<void> _onRefresh() async {
    await controller.fetchBusinessProducts(isDiscountedProducts: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        appBarColor: AppColors.white,
        title: 'Top Selling Products',
      ),
      body: Obx(() {
        final items = controller.allProducts;
        final status =
            controller.ownDraftAndPublicProductResponse.value.status;
        final isInitialLoading = status == Status.INITIAL && items.isEmpty;
        final isLoadingMore = controller.isAllProductsLoadingMore.value;

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
              children: const [
                SizedBox(height: 80),
                EmptyStateWidget(
                  message: 'No top selling products yet.',
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
                  itemBuilder: (context, index) => AdminProductCard(
                    product: items[index],
                    deleteProductApi: () {},
                    isGridShow: true,
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
                child: SizedBox(height: 24),
              ),
            ],
          ),
        );
      }),
    );
  }
}
