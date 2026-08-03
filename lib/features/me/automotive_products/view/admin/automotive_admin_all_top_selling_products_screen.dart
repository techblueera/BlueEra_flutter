import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_inventory_controller.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/widget/automotive_admin_product_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class AutomotiveAdminAllTopSellingProductsScreen extends StatefulWidget {
  const AutomotiveAdminAllTopSellingProductsScreen({super.key});

  @override
  State<AutomotiveAdminAllTopSellingProductsScreen> createState() =>
      _AutomotiveAdminAllTopSellingProductsScreenState();
}

class _AutomotiveAdminAllTopSellingProductsScreenState
    extends State<AutomotiveAdminAllTopSellingProductsScreen> {
  final AutomotiveInventoryController controller =
      getOrPut<AutomotiveInventoryController>(() => AutomotiveInventoryController());
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
      backgroundColor: Colors.transparent,
      appBar: CommonBackAppBar(
        appBarColor: AppColors.white,
        title: AppStrings.automotiveTopSellingProducts,
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
                  message: AppStrings.automotiveNoTopSellingYet,
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
                  itemBuilder: (context, index) => AutomotiveAdminProductCard(
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
