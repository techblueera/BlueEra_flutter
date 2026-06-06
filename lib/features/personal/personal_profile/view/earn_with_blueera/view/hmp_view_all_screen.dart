import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/admin_product_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeMadeProductsViewAllScreen extends StatefulWidget {
  const HomeMadeProductsViewAllScreen({super.key});

  @override
  State<HomeMadeProductsViewAllScreen> createState() =>
      _HomeMadeProductsViewAllScreenState();
}

class _HomeMadeProductsViewAllScreenState
    extends State<HomeMadeProductsViewAllScreen> {
  final earnServiceController = getOrPut(() => EarnServiceController());
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      earnServiceController.fetchOwnProducts();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      earnServiceController.fetchOwnProducts(isLoadMore: true);
    }
  }

  Future<void> _onRefresh() => earnServiceController.fetchOwnProducts();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.homeMadeProductSection),
      body: Obx(() {
        if (earnServiceController.isOwnProductDataFirstLoading.value &&
            earnServiceController.ownProductDataList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = earnServiceController.ownProductDataList;
        if (products.isEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                EmptyStateWidget(message: AppStrings.noProductFound),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 2;
              const spacing = 10.0;
              final itemWidth =
                  (constraints.maxWidth - spacing - (2 * SizeConfig.size8)) /
                      crossAxisCount;
              // Cell height tracks the card's own content so every card is the
              // same height regardless of name length (see gridCardHeight).
              final childAspectRatio =
                  itemWidth / AdminProductCard.gridCardHeight;

              return GridView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: products.length +
                    (earnServiceController.isOwnProductDataLoadingMore.value
                        ? 1
                        : 0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8,
                  vertical: SizeConfig.size8,
                ),
                itemBuilder: (context, index) {
                  if (index >= products.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return AdminProductCard(
                    product: products[index],
                    deleteProductApi: () {},
                    width: itemWidth,
                    isGridShow: true,

                  );
                },
              );
            },
          ),
        );
      }),
    );
  }
}
